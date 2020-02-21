// click on a ruleset name to see its source here

ruleset sensor_profile{
  
  meta{
    
    use module twilio_module alias twilio
    use module wovyn_base alias wovyn_base

    
    shares __testing, getInfo
    
  }
  
  
  global{
    getInfo = function (){
      "Name: " +ent:name + 
      "<br> Location: " +ent:location +
      "<br> Threshold Violation Limit: " +ent:threshold +
      "<br> Number to send Notifications: " + ent:num_to_notify 
    }
    
    
        
    __testing = {"queries": [{"name": "__testing"}],
                  "events": [{"domain": "sensor", "type": "profile_update",
                              "attrs": ["name", "location", "threshold", "num_to_notify"]}]
    }
    
    
  }
  
  
  rule profile{
    select when sensor profile_update
    pre{
      name = event:attr("name").klog("Name given for the pico: ").defaultsTo(ent:name)
      location = event:attr("location").klog("Location given: ").defaultsTo(ent:location)
      threshold_violation = ((event:attr("threshold") =="") => 98.99 | event:attr("threshold")).defaultsTo(98.98).klog("The threshold given is: ")
      num_to_notify = ((event:attr("toNotify") == "") => 18013006353 | event:attr("toNotify")).defaultsTo(18013006353).klog("To notify number: ")
      
      
      
    }
    
    send_directive("profile_updated", {
      "name" : name,
      "location" : location,
      "threshold" : threshold_violation,
      "num_to_notity": num_to_notify,
    })    
    
    
    always{
      ent:name := name;
      ent:location := location;
      ent:threshold := threshold_violation;
      ent:num_to_notify := num_to_notify;
      raise wovyn event "threshold_change" attributes{
        "threshold":threshold_violation
      };
      raise wovyn event "notifications_send_to" attributes{
        "number": num_to_notify
      }
    }
    

    
    
  }
  
  
  
  
  
  
}