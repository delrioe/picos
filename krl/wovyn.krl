// click on a ruleset name to see its source here
ruleset wovyn_base {
  meta {
    name "Wpvyn Base"
    author "Levi Del Rio"
  
    use module keys_Twilio alias access
    use module twilio_module alias twilio

  
    shares wovyn, __testing, heartbeat, process_heartbeat
  }
  
  global {
    
    
    myNumber = 18013006353
    
    // get_tempThres = function(k){
    //   ent:tempThres{k}
    // }

  
  temperature_threshold = 76.50

    
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "hello", "args": [ "obj" ] } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                                "attrs": [ "temp", "baro"]
                  }]
    }
    

  }
  
  rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing")

    pre{
      book = event:attrs.klog("attrs").decode()
      genericThing = event:attr("genericThing")
      data = genericThing{"data"}
      temperature = data{"temperature"}
      temperatureF = temperature[0]{"temperatureF"}.klog("temperatureF")
      
    }
    send_directive("say", {"something": "I am the sensor from wovyn heartbeat"})
    
    fired{
      raise wovyn event "new_temperature_reading" attributes {
        "temperature" : temperatureF,
        "timestamp" : time:now()
      }
    }
  }

  rule find_high_temps{
    select when wovyn new_temperature_reading
    
    pre{
      temperature = event:attr("temperature").klog("temperature")
      time = event:attr("timestamp").klog("timestamp")
      message =  (temperature > temperature_threshold)  => "Violation" | "Everything Good"
    }
    
    send_directive("say", {"something": message})
    
    fired{
      raise wovyn event "threshold_violation" attributes {
        "highTemp" : temperature,
        "time" : time
      }
      if (temperature > temperature_threshold)
  
    }
    
    
    
    
  }
  
  rule violation{
    select when wovyn threshold_violation
    
    pre{
      temp = event:attr("highTemp")
      time = event:attr("time")
    }
    
    //If this line below is enable, messages will be sent to my phone number. .... 
    twilio:send( myNumber, 14143765911, "There was a violation on the temp: " + temp);
    
    // send_directive("Violation", {"Temp Violation" : "There was a violation on the temp: " + temp + "at " + time})  
    
  }
  
  // rule threshold_notification{
  //   select when 
  // }
  
}
// TO TEST IT WITH CURL
//curl -X POST -H "Content-Type: application/json" -d '{"version":2,"eventDomain":"wovyn.emitter","eventName":"sensorHeartbeat","emitterGUID":"5CCF7FD53F8B","genericThing":{"typeId":"2.1.2","typeName":"generic.simple.temperature","healthPercent":82.33,"heartbeatSeconds":20,"data":{"temperature":[{"name":"enclosure temperature","transducerGUID":"28A85A230A000059","units":"degrees","temperatureF":77.31,"temperatureC":24.06}]}},"specificThing":{"make":"Wovyn ESProto","model":"Temp2000","typeId":"1.1.2.2.2000","typeName":"enterprise.wovyn.esproto.temp.2000","thingGUID":"5CCF7FD53F8B.1","firmwareVersion":"Wovyn-Temp2000-1.1-DEV","transducer":[{"name":"Maxim DS18B20 Digital Thermometer","transducerGUID":"28A85A230A000059","transducerType":"Maxim Integrated.DS18B20","units":"degrees","temperatureC":24.06}],"battery":{"maximumVoltage":3.6,"minimumVoltage":2.7,"currentVoltage":3.44}},"property":{"name":"Wovyn_D53F8B","description":"Wovyn ESProto Temp2000","location":{"description":"Timbuktu","imageURL":"http://www.wovyn.com/assets/img/wovyn-logo-small.png","latitude":"16.77078","longitude":"-3.00819"}},"_headers":{"host":"192.168.50.253","accept":"application/json","content-type":"application/json","content-length":"1242"}}' http://localhost:8080/sky/event/JgjBbVYcfXgydkuev76oKU/2222/wovyn/heartbeat