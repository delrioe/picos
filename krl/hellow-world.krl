// click on a ruleset name to see its source here
ruleset hello_world {
  meta {
    
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares hello, __testing, monkey
    }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "hello", "args": [ "obj" ] } ],
                  "events": [ { "domain": "echo", "type": "hello",
                                  "attrs": [ "name"]}, 
                                  { "domain": "echo", "type": "monkey",
                                  "attrs": [ "name"]}]
      
    }
  }
  
  rule hello_world {
    select when echo hello
    
    pre{
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("say", {"something": "Hello" + name})
  }
  
  rule monkey{
    select when echo monkey
    pre{
      // WAY 1
      // name = event:attr("name").defaultsTo("Monkey").klog("our passed in name: ")
      // WAY 2
      // name = event:attr("name").klog("our passed in name: ")
      //WAY 3
      name = event:attr("name") == "" => " Monkey" | event:attr("name").defaultsTo(" Monkey").klog("our passed in name: ")
      
    }
    
    // WAY 2
    // if( name.isNull()) then noop()
    // fired {
    //   send_directive("say", {"something": "Hello " + name})
    // }
    // else {
    //   send_directive
    // }
    
    // WAY 3
    send_directive("say", {"someting": "Hello" + name})
  }
}
