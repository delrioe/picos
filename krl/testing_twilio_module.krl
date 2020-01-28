// click on a ruleset name to see its source here
ruleset using_twilio_module{
    meta {
    name "Test Twilio Module"
    author "Levi Del Rio"
  
    use module twilio_module alias twilio

  
    shares testing_twilio_module, __testing, test
  }
  
  global{
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "hello", "args": [ "obj" ] } ],
                  "events": [ { "domain": "test", "type": "twilio",
                                "attrs": [ "to", "from", "message"]
                  }]
    }
  }
  
  rule testing_twilio_module{
    select when test twilio
    
    pre{
      to = event:attr("to").defaultsTo(18013006353).klog("to")
      from = event:attr("from").defaultsTo(14143765911).klog("from")
      message = event:attr("message").defaultsTo("no content").klog("message")
    }
    twilio:send(to, from, message);
  }

  
}