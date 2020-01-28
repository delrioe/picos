// click on a ruleset name to see its source here
// USAGE : http://localhost:8080/sky/event/KA1Q7G6Wi2d57mbkgJUTbX/2222/send/new_message?from=14143765911&message=hellofromlevi 
// you can include the to ... if you don't want to be default like so:  to:18013006353

ruleset twilio_module{
  meta {
    
    name "Twilio_Module"
    description << Twilio keys >>
    author "Levi Del Rio"
    
    logging on
    use module keys_Twilio alias access
    shares hello, __testing, monkey, send_sms, messages, send
    provides send, messages
  }

  global {
    
    my_sid = keys:levi_keys{"sid_key"}.klog("Sid")
    my_auth = keys:levi_keys{"auth_key"}.klog("Auth")
    base_url = <<https://#{my_sid}:#{my_auth}@api.twilio.com/2010-04-01/Accounts/#{my_sid}/Messages.json>>

    default_to = 18013006353
    
    __testing = { "queries": [ { "name": "__testing" }],
                  "events": [ { "domain": "twilio", "type": "access"}]
    }
    
    
    messages = function(to, from, pagination){
      my_sid = keys:levi_keys{"sid_key"}.klog("Sid");
      my_auth = keys:levi_keys{"auth_key"}.klog("Auth");
      base_url = <<https://#{my_sid}:#{my_auth}@api.twilio.com/2010-04-01/Accounts/#{my_sid}/Messages.json>>;
  
      to.klog("to");
      from.klog("from");
      pagination.klog("pagination");
        
      content = (to.isnull() && from.isnull()) => http:get(base_url){"content"}.decode() | 
                (from.isnull()) => http:get(base_url + "?To="+ to).decode() | http:get(base_url + "?From=" + from).decode();
                
      // If pagination is a number then do the after => () which is to take the content and decode it and then take the messages and decode it
      // content = (pagination.isnull() == false) => (content{"content"}.decode()){"messages"}.decode() | pagination.klog("somethiasdfadfasdf");

      content = content{"messages"}.decode();
      // content = "messages";
      
      content = pagination.isnull() => content | content.slice(0, pagination);

      content
      
      // To get messages with the criteria to. 
      // url_content = http:get(base_url+"?To=8018223413"){"content"}.decode();
      // url_content
      
    }
    
    send = defaction (to, from, message){
        
      http:post(base_url, form = 
        {"From": from,
          "To": to,
          "Body": message
        });
        
      }

  // send_sms = defaction(to, from, message, account_sid, auth_token){
  //   base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json>>
  //   // base_url = "https://api.twilio.com/2010-04-01/Accounts/"
  //   http:post(base_url, form = 
  //     {"From":from,
  //       "To":to,
  //       "Body":message
  //     })
  // }    

  }


  rule twilio_rule{
      select when twilio access
      
    pre{
      my_key = keys:levi_keys{"sid_key"}.klog("sid")
    }
  
  }
  
  rule send_sms{
    select when send new_message
    pre{
      to = event:attr("to").defaultsTo(default_to).klog("to:")
      from = event:attr("from").klog("from:")
      message = event:attr("message").defaultsTo("no Message sent")
    }

    
    // send_directive("say", {"something": "Hello" + name})
    send(to, from, message)   
  
    // fired{
    //   send_directive("say", {"something": "Message sent to " + to + "from " + from})
    // }  
          
  }
  
  
}
