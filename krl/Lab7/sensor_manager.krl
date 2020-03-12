// click on a ruleset name to see its source here
ruleset manage_sensors{
  
  meta{

    name "Manager Sensors Ruleset"
    description <<L>>
    author "Levi Del Rio"
    
    
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subscription  
    
    shares __testing, showChildren, sensors, temperatures
    
  } 
  
  global{
    
    //return a list of all the sensors it manages. 
    showChildren = function(){
        wrangler:children()
    }

    temperatures = function() {
      // LAB 6
      // result = ent:sensors.map(function(v,k){
      //     wrangler:skyQuery(v{"eci"}, "temperature_store", "temperatures", "");
      // });
      // result


      //Lab 7
      result = sensors().map(function(x){
          {
            "name": wrangler:skyQuery(x{"Tx"}, "io.picolabs.wrangler", "name", "" ),
            "temperatures" : wrangler:skyQuery(x{"Tx"}, "temperature_store", "temperatures", "");
          }
      });
      result

      }

    sensors = function(){
        // ent:sensors // Lab 6
        //Lab 7 
      establishedArray = subscription:established("Tx_role", "Sensor") ;
      establishedArray    

    }

    nameFromID = function (sensor_id){
        "Sensor " + sensor_id + " Pico"
    }
    
    
    __testing = {"queries": [{"name": "showChildren"},
                              {"name": "sensors"},
                              {"name": "temperatures"}], 
                  "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] },
                                {"domain": "collection", "type": "empty"},
                                {"domain": "sensor", "type" : "unneeded_sensor", "attrs": ["sensor_id"]},
                                {"domain": "create", "type": "subscription_children"}
                            ] 
      
    }




  }
  
    
  
  
  /*
  Creates a new pico to represent the sensor
  installs the temperature_store, wovyn_base and sensor_profule rulesets in the sensor
  stores the value of an event attribute giving the sensro's name and the new sensors pico's ECI in an entity
  */
  rule create_sensor{
    select when sensor new_sensor

    pre{
        sensor_id = event:attr("sensor_id")
        exist = ent:sensors >< sensor_id
    }        

    if not exist then 
        noop()    
    fired{
        raise wrangler event "child_creation"
        attributes{ "name": nameFromID(sensor_id),
                    "color": "#b30162",
                    "sensor_id": sensor_id,
                    "rids": ["temperature_store",
                            "wovyn_base",
                            "sensor_profile",
                            ]}
    }

  }

  rule sensor_exit{
    select when sensor new_sensor
    pre{
        sensor_id = event:attr("sensor_id").defaultsTo("NO_NAME")
        exist = ent:sensors >< sensor_id
    }        
    if exist then
        send_directive("Sensor Exist", {"sensor_id": sensor_id})
  }



  rule store_new_sensor{
    select when wrangler child_initialized
    pre{
          the_sensor = {"id": event:attr("id"), "eci": event:attr("eci")}
          sensor_id = event:attr("sensor_id")
    }
    if sensor_id.klog("found sensor_id")
    then
    every{
     event:send(
        {"eci": the_sensor{"eci"}, "eid": "updateProfileInfo", 
        "domain": "sensor", "type": "profile_update",
        "attrs": {
            "name": the_sensor{"id"},
            "location": "Pico Labs Inc",
            "threshold_violation": 90.01,
            "num_to_notify": 18013006353
            }
        }
    ) 
    event:send(
      {"eci": the_sensor{"eci"}, "eid": "createSubscription", 
        "domain": "create", "type": "subscription_parent",
      }
    )  
    }
    
    fired{
        ent:sensors:= ent:sensors.defaultsTo({});
        ent:sensors{[sensor_id]} := the_sensor 
    }
  }



  rule collection_empty{
      select when collection empty
      always{
          ent:sensors := {}
      }
  }

  /*
  Deletes the appropriate sensor pico 
  removes the mapping in the entity variable for this sensor
  */
  rule delete_sensor{
      select when sensor unneeded_sensor

      pre{
        sensor_id = event:attr("sensor_id")
        exist = ent:sensors >< sensor_id
        child_to_delete = nameFromID(sensor_id)
      }
      if exist then
        send_directive("deleting_sensor", {"sensor_id" : sensor_id})
    
      fired{
          raise wrangler event "child_deletion"
          attributes{
              "name": child_to_delete};
          clear ent:sensors{[sensor_id]}
      }
  
  
    }

    //creates a subscription to one child in specific, just change the wellKnown_Tx to the 
    //pico eci you want to create the subscription
    rule create_subscription{
      select when create subscription_children
      always{
          raise wrangler event "subscription" attributes {
              "name" : "self_subscription",
              "wellKnown_Tx": "<ECI FOR THE CHILD GOES HERE>"
          }
      } 
    }


//accepts any subscription
  rule autoAccetSubscriptions{
      select when wrangler inbound_pending_subscription_added
      pre{
        Rx_role = event:attr("Rx_role").klog("This is the RX_ROLE they are giving me")
      }
      if Rx_role then 
        noop() 
      fired{
          raise wrangler event "pending_subscription_approval" attributes event:attrs
      }
  }

  //if not rx_role given
 rule autoAcceptSubscriptionNotSensor{
  select when wrangler inbound_pending_subscription_added
      pre{
        Rx_role = event:attr("Rx_role")
      }
      if Rx_role then 
        noop() 
      notfired{
          raise wrangler event "pending_subscription_approval" attributes event:attrs
      }
 } 
  



  //accepts any subscriptions that have a role and sets it up tp 
  // rule acceptSubscriptionWithSensorRole{
  //     select when wrangler inbound_pending_subscription_added
  //     pre{
  //       Rx_role = event:attr("Rx_role").klog("this is the rx_role that was given")
  //       // (event:attr("Rx_role") == "Sensor") => "Sensor" | "Other"
  //     }
  //     if Rx_role then
  //       noop()
  //     fired{
  //         raise wrangler event "pending_subscription_approval" attributes {
  //           "Rx_role" : Rx_role
  //         }
  //     }
  // }
  
  
  
}



