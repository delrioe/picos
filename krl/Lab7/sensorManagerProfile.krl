ruleset sensorManagerProfile{

    meta{

        use module twilio_module alias twilio
        use module io.picolabs.subscription alias subscription  
        shares __testing, sendSMS, get_eciRx
    }


    global{
        from_number = 14143765911
        to_number = 18013006353
        __testing = {"queries": [{"name": "__testing"},
                                 {"name": "get_eciRx" }]
        }

        // send = defaction (to, from, message
        sendSMS = defaction(message){
            twilio:send(to_number, from_number, message)
        }

        get_eciRx = function(){
            subscription:established("Tx_role", "Sensor")
        }
        

    }

    rule thresholdViolation{
        select when notification threshold_violation
        pre{
            to_num = event:attr("to: ").defaultsTo(to_number)
            from_num = event:attr("from: ").defaultsTo(from_number)
            message = event:attr("message").defaultsTo("There was a violation ")
            sensor = event:attr("sensor").defaultsTo("No sensor ID given")
            temp = event:attr("temp").defaultsTo("No temp given")
        }
        sendSMS(to_num, from_num, message + ": " + sensor + " temp: " + temp) 

    }



}
