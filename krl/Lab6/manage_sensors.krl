// click on a ruleset name to see its source here
ruleset manage_sensors{
  
    meta{
  
      name "Manager Sensors Ruleset"
      description <<L>>
      author "Levi Del Rio"
      
      
      use module io.picolabs.wrangler alias wrangler
  
      shares __testing, showChildren, sensors, temperatures
      
    } 
    
    global{
      
      //return a list of all the sensors it manages. 
      showChildren = function(){
          wrangler:children()
      }
  
      temperatures = function() {
          // ent:sensors{[sensor_id]} := the_sensor 
  
          //answer = wrangler:skyQuery("eci", "my.ruleset.id","myfunction", args);
        
        result = ent:sensors.map(function(v,k){
            wrangler:skyQuery(v{"eci"}, "temperature_store", "temperatures", "");
        });
        result
        }
  
      sensors = function(){
          ent:sensors
      }
  
      nameFromID = function (sensor_id){
          "Sensor " + sensor_id + " Pico"
      }
      
      
      __testing = {"queries": [{"name": "showChildren"},
                                {"name": "sensors"},
                                {"name": "temperatures"}], 
                    "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] },
                                  {"domain": "collection", "type": "empty"},
                                  {"domain": "sensor", "type" : "unneeded_sensor", "attrs": ["sensor_id"]}
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
          sensor_id = event:attr("sensor_id")
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
  
  
  
  
  
  
    
  }
  
  
  
 