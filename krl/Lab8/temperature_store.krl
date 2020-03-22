// click on a ruleset name to see its source here
ruleset temperature_store {
  
  
    meta{
      
      //provides = for modules 
      provides temperatures, threshold_violations, inrange_temperatures, current_temperature
      
      use module io.picolabs.wrangler alias wrangler
      use module io.picolabs.subscription alias subscription  
  
  
      //Outside the pico engine
      shares __testing, temperatures, threshold_violations, inrange_temperatures, current_temperature,
      findRxFromSubscription
      
    }
    
    global{
      // functions
      //return an array of temps -> ea/ temp is a timestamp and temp in degrees
      
        clear_temperatures = { "temp": "0", "timestamp": "0"}
        thresholdViolation = 90.00
  
      
      
      __testing = {"queries": [{"name": "__testing"},
                                {"name": "temperatures"},
                                {"name": "threshold_violations"},
                                {"name": "inrange_temperatures"},
                                {"name": "findRxFromSubscription", "args":["eci"] }],
                    "events": [{"domain": "wovyn", "type": "new_temperature_reading",
                                "attrs": ["temp", "timestamp"]},
                                {"domain": "sensor", "type": "reading_reset"},
                                {"domain": "wovyn", "type": "threshold_violation"}]
      }
      
      
      temperatures = function (){
        ent:temperatures.defaultsTo({})
  
      }
      
      threshold_violations = function() {
        ent:high_temperatures
      }
      
      inrange_temperatures = function(){
        ent:temperatures.difference(ent:high_temperatures)
      }
      
      current_temperature = function(){
        ent:curr_temp
      }
      
      //Returns the Tx for the the Rx given in the subscriptions.
      findRxFromSubscription = function( eci) {
          sensorManager = subscription:established("Tx", eci).head(){"Rx"};
          sensorManager
      }
      
      
    }
    
    
    
    
    rule collect_temperatures{
      select when wovyn new_temperature_reading
      
      pre{
        passed_temp = event:attr("temp").klog("our passed Temperature: ")
        passed_timestamp = event:attr("timestamp").klog("our passed Timestamp: ")
        map = {"temp": passed_temp, "timestamp": passed_timestamp}
      }
   
      send_directive("store_temp", {
        "temp" : passed_temp,
        "timestamp" : passed_timestamp
      })
    
      always{
        ent:temperatures := ent:temperatures.defaultsTo([]).append(map);
        ent:curr_temp := map
      }
    
      
      
    }
    
    rule collect_threshold_violations{
      select when wovyn threshold_violation
      
      pre{
        highTemp = event:attr("temp").klog("violation passed: ")
        highTimestamp = event:attr("timestamp").klog("violation timestamp: ")
        map1 = {"temp": highTemp, "timestamp": highTimestamp}
      }  
       send_directive("store_high_temp", {
        "temp" : highTemp,
        "timestamp" : highTimestamp
      })
      
      always{
        ent: high_temperatures := ent:high_temperatures.defaultsTo([]).append(map1)
      }
      
    }
    
    
    
    rule clear_temperatures{
      select when sensor reading_reset
      pre{
        note = "done.".klog("Sensored info cleared: ")
      }
      send_directive("Cleared send")
      
      always {
        clear ent:temperatures;
        clear ent:high_temperatures;
        clear ent:curr_temp;
      }
    }
      
    
    rule initialize_data{
      select when sensor initialize
      always{
        ent:temperatures:= {};
        ent:hight_temperatures:={};
        ent:curr_temp:= {}
      }
    }
    
      
    rule requestReport{
      select when request report
      pre{
        reportID = event:attr("reportID").klog("reportId Number: ")
        requester = event:attr("requester").klog("This is the requester of report: ")
        tx_of_senderChannel = findRxFromSubscription(requester) 
      }
      // send_directive("I was called RequestReport", {"Something":reportID})
      // always{
        event:send({
          "eci": requester,
          "domain":"received",
          "type":"report",
          "attrs":{
            "reportID" : reportID,
            "sender": tx_of_senderChannel,
            "nameSender": wrangler:name(),
            "temperatures" : temperatures()
          }
          
        })
      // }
    }
    
      
      
  } 
    
  