//click on a ruleset name to see its source here
ruleset temperature_store {
  
  
  meta{
    
    //provides = for modules 
    provides temperatures, threshold_violations, inrange_temperatures
    
    //Outside the pico engine
    shares __testing, temperatures, threshold_violations, inrange_temperatures
  }
  
  global{
    // functions
    //return an array of temps -> ea/ temp is a timestamp and temp in degrees
    
      clear_temperatures = { "temp": "0", "timestamp": "0"}
      thresholdViolation = 80.50

    
    
    __testing = {"queries": [{"name": "__testing"},
                              {"name": "temperatures"},
                              {"name": "threshold_violations"},
                              {"name": "inrange_temperatures"}],
                  "events": [{"domain": "wovyn", "type": "new_temperature_reading",
                              "attrs": ["temp", "timestamp"]},
                              {"domain": "sensor", "type": "reading_reset"},
                              {"domain": "wovyn", "type": "threshold_violation"}]
    }
    
    
    temperatures = function (){
      ent:temperatures

    }
    
    threshold_violations = function() {
      ent:high_temperatures
    }
    
    inrange_temperatures = function(){
      ent:temperatures.difference(ent:high_temperatures)
    }
    
    
  }
  
  
  
  
  rule collect_temperaturess{
    select when wovyn new_temperature_reading
    
    
    pre{
      passed_temp = event:attr("temperature").klog("our passed Temperature: ")
      passed_timestamp = event:attr("timestamp").klog("our passed Timestamp: ")
      map = {"temp": passed_temp, "timestamp": passed_timestamp}
    }
 
    send_directive("store_temp", {
      "temp" : passed_temp,
      "timestamp" : passed_timestamp
    })
  
  always{
    ent:temperatures := ent:temperatures.defaultsTo([]).append(map);
    
      raise wovyn event "threshold_violation" attributes {
        "temperature" : passed_temp,
        "timestamp" : passed_timestamp
      }

    }
  
    
    
}
  
  rule collect_threshold_violations{
    select when wovyn threshold_violation where event:attr("temperature") > thresholdViolation
    
    pre{
      highTemp = event:attr("temperature").klog("violation passed: ")
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
    }
  }
    
    
    
} 
  
