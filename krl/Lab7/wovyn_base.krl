// click on a ruleset name to see its source here
ruleset wovyn_base {
  meta {
    name "Wovyn Base"
    author "Levi Del Rio"
  
    use module keys_Twilio alias access
    use module twilio_module alias twilio
    use module io.picolabs.subscription alias subscription  
    use module io.picolabs.wrangler alias wrangler

  
    shares wovyn, __testing, heartbeat, process_heartbeat
  }
  
  global {
    
    myNumber = 18013006353
    temperature_threshold = 90.00

    
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "hello", "args": [ "obj" ] } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                                "attrs": [ "temp", "baro"]},
                                {"domain": "wovyn", "type": "new_temperature_reading",
                                "attrs" : ["temp", "timestamp"]},
                                {"domain": "wovyn", "type": "threshold_change",
                                "attrs": ["threshold"]}
                            ]
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
        "temp" : temperatureF,
        "timestamp" : time:now()
      }
    }
  }

  rule find_high_temps{
    select when wovyn new_temperature_reading 
    
    pre{
      temperature = event:attr("temp").klog("temperature")
      time = event:attr("timestamp").klog("timestamp")
      message =  (temperature > ent:threshold)  => "Violation" | "Everything Good"
    }
    
    send_directive("say", {"something": message})
    
    fired{
      raise wovyn event "threshold_violation" attributes {
        "temp" : temperature,
        "timestamp" : time
      } if (temperature > ent:threshold)
      
  
    }
  }
  
  rule violation{
    select when wovyn threshold_violation //where event:attr("highTemp") > temperature_threshold
    foreach subscription:established("Tx_role", "Manager").map(function(x){ x{"Tx"}}) setting (sub)
    pre{
      temp = event:attr("temp")
      time = event:attr("timestamp")
      // managerECI = (subscription:established("Tx_role", "Manager").map(function(x){ x{"Tx"}}))   //.head(){"Tx"}.klog("this is the Event ECI: ")
      
    }
    
    
    // map(function(x){ x{“Tx”}})
    //If this line below is enable, messages will be sent to my phone number. .... 
    //---------->twilio:send( ent:numForNotifications, 14143765911, "There was a violation on the temp: " + temp);
    // send_directive("Violation", {"Temp Violation" : "There was a violation on the temp: " + temp + "at " + time})  
    event:send({"eci":sub, "domain":"notification", "type":"threshold_violation",
    "attrs":{
      "sensor": wrangler:name(),
      "temp" : temp
      }
    })
    

  }
  
  
  
  
  //Change some settings -------------------------------------------------------------------------
  rule set_threshold{
    select when wovyn threshold_change
    
    pre{
      lim = event:attr("threshold").klog("Set threshold temp limit to: ")
      limit = (lim == "") => 99.99 | lim
    }
    send_directive("say", {"Setting temperatures threshold to": limit})
    always{
      ent:threshold := limit
    }    
  }
  
  //Change some settigns
  rule set_notifications_number{
    select when wovyn notifications_send_to 
    
    pre{
      num = event:attr("number").klog("Number to send notifications is: ")
      to_num = (num == "") => 18013006353 | num
    }
    send_directive("say", {"setting number to send notificatoins to ": to_num})
    always{
      ent:numForNotifications := to_num
    }
    
    
  }
  
  
  
 rule autoAcceptSubscriptions {
  select when wrangler inbound_pending_subscription_added
  always {
    raise wrangler event "pending_subscription_approval" attributes event:attrs; 
  }
}
  
  
  
  
  
}

