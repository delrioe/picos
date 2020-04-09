
ruleset gossip{

    meta {
    
        name "Gossip"
        author "Levi Del Rio"
        
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription  
        use module temperature_store alias temper

        shares __testing, test, getPeer, prepareMessage, update, send, existInRumors, getMessagesNeeded, existInMessage, transformAllSeen, transformChismes, getRummorFromRummors, getRummorWith, getRumorWithSubscriber, getSubscriber
      }

      global {



        test = function(){
                meta:picoID
        }
        
        random_peer = function(){
          k = "random_peer called".klog("");
          peer = subscription:established("Rx_role", "Peer");
          limit = peer.length();
          rand = random:integer(upper = limit-1, lower = 0);
          peer[rand]{"Tx"}

        }
        
        __testing = {"queries" : [{"name":"test"},
                                    {"name" : "prepareMessage", "args" : ["state","subscriber"]},
                                    {"name" : "existInRumors", "args": ["messageID"]},
                                    {"name" : "existInMessage", "args": ["key", "message"]},
                                    {"name" : "getMessagesNeeded", "args" : ["key", "startingValue"]},
                                    {"name" : "getPeer"},
                                    {"name" : "transformChismes"},
                                    {"name" : "transformAllSeen"},
                                    {"name" : "getRummorFromRummors", "args" : ["messageID"]},
                                    {"name" : "getRummorWith", "args" : ["list"]},
                                    {"name" : "getRumorWithSubscriber", "args" :["subscriber"]},
                                    {"name" : "getSubscriber"}
             
                                ],
                      "events": [
                                // {"domain" : "add", "type" : "addMessage", "attrs":["message"]},
                                 {"domain" : "gossip", "type" : "seen", "attrs" : ["message"]},
                                 {"domain" : "gossip", "type" : "rumor"},
                                 {"domain" : "gossip", "type" : "stop_heartbeat", "attrs" : ["status"]}
//                                 {"domain" : "add", "type" : "addRumor", "attrs" : []}
                                // {"domain" : "add", "type" : "seenMessage", "attrs" : ["originID", "num"]},
                               //  {"domain" : "add", "type" : "addRumor", "attrs" : ["message"]}
                                ]

                    }
        //transfomr chismes from {"address":{"a":1}} to [{"address"}:[{"a":1}]]
        transformChismes = function(){

            k = "transformChismes called".klog("");
            other = ent:chismes;
            otherKeys = other.keys(); // ["some", "node", "node2"]

            
            otherArray = otherKeys.map(function(x){
                value = other.values(x); //[1, 2]
                keyss = other.keys(x);  // ["a", "b"]
                y = keyss.map(function(a){
                    m = {}.put(a, other{[x, a]});
                    m
                });
                {}.put(x, y);
            });
             
            otherArray
 
        }

        transformAllSeen = function(){
            k="transformAllSeen called".klog("");
            myseen = ent:allSeen;
            myseenKeys = myseen.keys(); // ["a", "b"]

            y = myseenKeys.map(function(a){
                m = {}.put(a, myseen{a});
                m;
            });
                y          
 
        }

        getPicoId = function(id) {
            splitted = id.split(re#:#);
            splitted[0]
        }

        getSequenceNum = function(id) {
            splitted = id.split(re#:#);
            splitted[splitted.length() - 1].as("Number")
        }

        getNextSequence = function(picoId){
            filtered = ent:allSeen.filter(function(a) {
                id = getPicoId(a{"MessageID"});
                id == picoId
            }).map(function(a){getSequenceNum(a{"MessageID"})}).klog("filtered");

            sorted = filtered.sort(function(a_seq, b_seq){
                a_seq < b_seq  => -1 |
                a_seq == b_seq =>  0 |
                1
            });
        
            sorted.reduce(function(a_seq, b_seq) {
                b_seq == a_seq + 1 => b_seq | a_seq
            }, -1);
        }
        
        getUniqueId = function() {
            sequenceNumber = ent:sequence;
            <<#{meta:picoId}:#{sequenceNumber}>>
        } 
        
        createNewMessage = function(temp, time) {
            {
                "MessageID": getUniqueId(),
                "SensorID": meta:picoId,
                "Temperature": temp,
                "Timestamp": time
            }
        } 
        
        
        
        getSubscriber = function(){
            k="getSubscriber called".klog("");
        // ["b:2", "a:1"]
        // [{"a": 1}, {"b": 2}]
            //chismes \/
            // other = [{"some":[{"a": 0}, {"b": 0}]}, {"node": [{ "a": 0}, {"b": 0}]}, {"node2": [{ "a": 0}, {"b": 1}]}];
            // other = [{"something":[]}];
            // myseen = [{"a":0}, {"b":0}];

            other = transformChismes().klog("other");
            myseen = transformAllSeen().klog("myseen");

            //startNode = other[0].klog("startNode");
            mostDifferent = other.reduce(function(a,b){
              first = myseen.filter(function(k){
                // key = k.klog("k").keys()[0].klog("keys"); //"a"
                key = k.keys()[0];
                bval = b.values()[0].filter(function(x){ x.keys()[0] == key })[0];
                myseenval = myseen.filter(function(x){ x.keys()[0] == key })[0];
                (bval{key} != null && bval{key}.as("Number") < myseenval{key}.as("Number")) => true | false
                
              });
              
              second = myseen.filter(function(k){
                key = k.keys()[0];
                aval = a.klog("a").values()[0].filter(function(x){ x.keys()[0] == key })[0];
                myseenval = myseen.filter(function(x){ x.keys()[0] == key })[0];
                (aval{key} != null && aval{key}.as("Number") < myseenval{key}.as("Number")) => true | false
                
              });
              
              (first.length() > second.length()) => b | a
              
            }, []);
            
            result = mostDifferent == [] =>  random_peer() | mostDifferent.keys()[0];
            result.klog("Result from getSubcriber")
            
        }


        getPeer = function(state){
            k="getPeer called".klog("");
            list = subscription:established("Rx_role", "Peer").klog("Subscriptions ");
            chismes = ent:chismes.klog("Chismes");
            
            s = list.filter(function(a){
                exist = ent:chismes{a{"Tx"}}.klog("What is this? ");
                x = (exist == null || exist == {})   => a{"Tx"} | getSubscriber(); //TODO: // If one of the peers is empty or null then choose that one else, check with chismes to get the one that needs something from you.
                x
            }).klog("This is the list to choose from ") ;
            rand = random:integer(s.length()-1);
            s[rand]{"Tx"}
            
        }

        getRandomRummorFromRummors = function(){ 
            k="getRandomRummorFromRummors called".klog("");
            list = ent:rummors;
            rand = random:integer(upper = 0, lower = list.length()-1);
            list[rand]
        }
        
        getRummorFromRummors = function(messageID){
            k="getRummorFromRummors called".klog("");
            listMessage = ent:rummors.filter(function(a){
                a{"MessageID"} == messageID.klog("THIS IS THE MESSAGE ID TO LOOK FOR");
            });
            listMessage[0]
        }
        
        getRummorWith = function(list){
            k="getRummorWith called".klog("");
            rand = random:integer(lower = 0, upper = list.length()-1).klog("Rand number");
            tosearch = list[rand].keys()[0].klog("toSearch ");
            messageID = tosearch + ":" + list[rand].values()[0].klog("messageID From GetRummorsWith");
            message = getRummorFromRummors(messageID);
            message
        }


        getRumorWithSubscriber = function(subscriber){
            k="getRummorWithSubscriber called".klog("");
            other = transformChismes().klog("other"); // [{"a":[{"a":1}, {"b": 0}]}]
            myseen = transformAllSeen().klog("myseen"); // [{"a":1}, {"b": 1}]
            diff = myseen.difference(other[0]{eci}); // return the things I have he does not. [{"b": 1}]
            rumor = (diff) == 0 => getRandomRummorFromRummors() | getRummorWith(diff);
            rumor
            
        }

        getSeenMessage = function(){
            k="getSeenMessage called".klog("");
            ent:allSeen
        }
        
        prepareMessage = function(state, subscriber){
            k="prepareMessage called".klog("");
            rand = random:integer(1);
            message = (rand == 0) => getSeenMessage() | getRumorWithSubscriber(subscriber);     
            message
        }
        
        send = defaction(subscriber, message){
            k="send called".klog("");
            sendMap = {}.put("cid", subscriber);
            event:send({"eci" : subscriber, "domain":"gossip", "type":"seen", "attrs":{
               "message":message.klog("send Message defaction"),
            //    "sender" : meta:pidoId
                "sender": subscription:established("Rx_role", "Peer").filter(function(a){
                    a{"Tx"} == subscriber;
                }).head(){"Rx"}.klog("sender...............") 
            }}); 
        }

        update = function(state){
            x = 1;
            x
        }
        
        //returns an array with one element: the message to send
        getRumor = function(key, value){
            k="getRumor called".klog("");
            //find the message to send by incrementing the sender number plus 1
            messageID = key + ":" + (value.as("Number")+1);
            s = messageID.klog("what? ");
            x = ent:rummors.filter(function(a) {a{"MessageID"}.klog("a---------------") == messageID});
            message = x.head();
            message


        }

        existInRumors = function(messageID){
            k="existInRumor called".klog("");
            i = "existInRumorsFunction".klog("ExistInRumors called"); 
            x = ent:rummors.defaultsTo([]).filter(function(a){
                a{"MessageID"}.klog("messageID: ") == messageID
            });
            y = x.head();
            y
        }


        getMessagesNeeded = function(key, startingValue){
            k="getMessagesNeeded called".klog("");
            x = ent:rummors.filter(function(a){
                messageID = a{"MessageID"}.klog("MessageID in geMessagesNeeded: ");
                // seq = messageID.substr(messageID.length()-1,messageID.length());
                // origin = messageID.substr(0,messageID.length()-2); 
                origin = getPicoId(messageID);
                seq = getSequenceNum(messageID);
                key.klog("This is the key to compare") == origin.klog("This is the origin") && seq.as("Number").klog("seq") >= startingValue.klog("startingValue = ")
            });

            x.klog("List OF MESSAGES TO BE SEND")
        }

        //return the number of sequence ex. on "ASD-ASD-ASDF:3" returns 3; returns null otherwise
        existInMessage = function (key, message){
            k="existInMessage called".klog("");
            y = key.klog("ExistInMessage key: ");
            y = message.klog("ExistInMessage message: ");
            x = message{key}.klog("existInMessage");
            x
        }

    }




    rule updateChisme{
        select when update chisme
        pre{
            update = event:attr("update")
            mapa = message.decode()
            sender = event:attr("sender").klog("Sender from UPDATEWHATEVERYONEHASSEEN")
        }
        always{
            k = ent:chismes.klog("CHISMES BEFORE UPDATE");
            ent:chismes := ent:chismes.defaultsTo({});
            ent:chismes{sender} := update;
            k = ent:chismes.klog("CHISMES AFTER UPDATE")
        }
    }
   
    //whent the ruleset is added set the scheduler
    rule ruleset_added {
        select when wrangler ruleset_added where rids >< meta:rid
        always {
            ent:period := 10;
            ent:sequence := 0;
            ent:allSeen := {};
            ent:chismes := {};
            ent:status := "on";
            ent:temperature := 0;
            ent:timestamp := 0;
            ent:rummors  := [];
            raise gossip event "heartbeat" attributes {"period": ent:period};
        }
    }

    rule gossip_heartbeat_schedule {
        select when gossip heartbeat
        pre {
            period = ent:period
        }
         always {
            schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": period}) 
         }
    }


    rule gossipHeartbeat{
        select when gossip heartbeat where ent:status == "on"
        pre{
            subscriber = getPeer(ent:allSeen).klog("this is the subrscriber ")         
            message = prepareMessage(ent:allSeen, subscriber).klog("This is the message")
            type = message{"MessageID"}.klog("this is the type")
        }
        if( type == null) then // send a seen
            send(subscriber, message) 
        notfired{ // send a rumor
            raise send event "rumor" attributes{
                "messages" : [].append(message),
                "sendTo" : subscriber,
                "sender" : subscription:established("Rx_role", "Peer").filter(function(a){
                    a{"Tx"} == subscriber;
                }).head(){"Rx"}.klog("sender...............")
            } 
        }
    }



   rule wovynheartbeat{
       select when wovyn new_temperature_reading
       pre{
        temperature = event:attr("temp").klog("temperature")
        time = event:attr("timestamp").klog("timestamp")
        message = createNewMessage(temperature, time).klog("Message wovyn")
      }
      send_directive("say", {"something": message})
      always {
        ent:temperature := temperature;
        ent:timestamp := time;
        ent:allSeen{meta:picoId} := ent:sequence.klog("allSeen");
        // ent:chismes{meta:picoId} := ent:allSeen.klog("chismes"); 
        ent:sequence := ent:sequence + 1;
        ent:rummors := ent:rummors.append(message);
        
    }
   }

   rule stopHearBeat{
       select when gossip stop_heartbeat
       pre{
           status = event:attr("status")
       }
       always{
           ent:status := status
       }
   }


    rule sendRumorMessage{
        select when send rumor
        pre{
            messages = event:attr("messages").head()
            sender = event:attr("sender")
            sendTo = event:attr("sendTo")
        }
        if(messages != null) then
            event:send({"eci":sendTo.klog("send to:::::"), "domain":"gossip", "type":"rumor",
                     "attrs": {
                         "message" : message.klog("This is the message"),
                         "update" : ent:allSeen,
                         "sender" : subscription:established("Tx", sender).head(){"Rx"}.klog("The sender of the update")
                     }
                 })
    }

   
    rule rumor_message{ 
        select when gossip rumor 
           pre{
               messageRec = event:attr("message")
               messageID = messageRec{"MessageID"} // event:attr("MessageID")
               sensorID = messageRec{"SensorID"} //event:attr("SensorID")
               temp = messageRec{"Temperature"} // event:attr("Temperature")
               time = messageRec{"Timestamp"} //event:attr("Timestamp")
                message = {}.put("MessageID", messageID).put("SensorID", sensorID).put("Temperature", temp).put("Timestamp", time)
               seq = messageID.substr(messageID.length()-1,messageID.length()).klog("Seq: ") 
               origin = messageID.substr(0,messageID.length()-2).klog("OriginID: ") 
               exist = ent:allSeen.get(origin).klog("exist: ")
            }
            // If it exist on ent:allSeen && 
            // if the number in allSeen + 1 is the same as the seq, this makes sure that 
            if (exist  != null ) then
                send_directive("rumor_message", {"exist " : "checking to add"})
            
           fired{
                raise add event "addRumor"
                attributes{
                    "message": message
                };
                raise update event "allSeen"
                attributes{
                    "originID": origin,
                    "sequence": seq
                } if((exist.as("Number") + 1) == seq.as("Number"));
           }
    }

    rule rumor_message_nonexistent{
        select when gossip rumor
        pre{
               messageRec = event:attr("message")
               messageID = messageRec{"MessageID"} // event:attr("MessageID")
               sensorID = messageRec{"SensorID"} //event:attr("SensorID")
               temp = messageRec{"Temperature"} // event:attr("Temperature")
               time = messageRec{"Timestamp"} //event:attr("Timestamp")
                message = {}.put("MessageID", messageID).put("SensorID", sensorID).put("Temperature", temp).put("Timestamp", time)
               seq = messageID.substr(messageID.length()-1,messageID.length()).klog("Seq: ") 
               origin = messageID.substr(0,messageID.length()-2).klog("OriginID: ") 
               exist = ent:allSeen.get(origin).klog("exist: ")
      }
        if (exist == null) then 
            send_directive("rumor_message", {"doesnt_exist" : "adding"})
        fired{
                raise add event "addRumor"
                attributes{
                    "message": message
                };
                raise update event "allSeen"
                attributes{
                    "originID": origin,
                    "sequence": seq
                } if(seq.as("Number") == 0);
        }
 
    }


    rule addMessageToRummor{
        select when add addRumor
        pre{
            message = event:attr("message")
            mapa = message.decode().klog("addMessageToRummor message: ")
            exist = existInRumors(mapa{"MessageID"}).klog("addMessageToRummor exist: ")
            x = ent:rummors.klog("rumors before adding")
        }
        if( exist == null) then
            send_directive("exist")
        fired{
            ent:rummors := ent:rummors.defaultsTo([]).klog("should be empty: ");
            ent:rummors := ent:rummors.append(mapa).klog("shoudl have something");
        }
    }

    rule updateAllSeen{
        select when update allSeen
        pre{
            origin = event:attr("originID") 
            seq = event:attr("sequence")    
        }
        always{
            ent:allSeen := ent:allSeen.defaultsTo({});
            ent:allSeen{origin} := seq
        }
    }



        rule updateChismes{
            select when gossip seen
            pre{
                message = event:attr("message")
                mapa = message.decode()
                sender = event:attr("sender").klog("senderin updateSeen: ")
            }
            always{
                k = ent:chismes.klog("CHISMES BEFORE UPDATE");
                ent:chismes := ent:chismes.defaultsTo({});
                ent:chismes{sender} := message;
                k = ent:chismes.klog("CHISMES AFTER UPDATE")
            }
        }

       rule seen_messageUpdate{
            select when gossip seen
            foreach ent:allSeen.defaultsTo({}) setting (value,key)
                pre{
                    message = event:attr("message").klog("Message To update")
                    mapa = message.decode()
                    sender = event:attr("sender").klog("From Sender")
                    seq = existInMessage(key, message) //returs the number of seq in which the message item is
                }
                if( seq != null) then // if there is a match messages seen 
                    send_directive("seen element exist in my seen", {"element" : key} )
                fired{
                    raise send event "messages" attributes{
                        "messages" : getMessagesNeeded(key, seq.as("Number") + 1).klog("ListMessage: "),
                        "sender" : sender
                    } if( value.as("Number") > seq.as("Number")); // || value.as("Number") == 0);
                }
       }

       rule seen_messagesUpdate_nonExistent{
           select when gossip seen
            foreach ent:allSeen.defaultsTo({}) setting (value,key)
                pre{
                    message = event:attr("message")
                    mapa = message.decode()
                    sender = event:attr("sender") 
                    seq = existInMessage(key, message) //returs the number of seq in which the message item is
                }
                if( seq == null) then // if there is a match messages seen 
                    send_directive("seen element does not exist in allSeen", {"element" : key} )
                fired{
                    //listMessages = getMessagesNeeded(key, 0).klog("ListMessage nonExistent: ");
                    raise send event "messages" attributes{
                        "messages" : getMessagesNeeded(key, 0).klog("ListMessage nonExistent: "),
                        "sender" : sender
                    } if( value.as("Number") > seq.as("Number") || value.as("Number") == 0);
                }
       }

       rule sendMessages{
           select when send messages
            foreach event:attr("messages") setting (message)
            pre{
                sender = event:attr("sender").klog("Send messages rule called. ->")
            }
            if(sender != null) then
                event:send({"eci":sender.klog("sender::::::"), "domain":"gossip", "type":"rumor",
                     "attrs": {
                         "message" : message.klog("This is the message"),
                         "update" : ent:allSeen,
                         "sender" : subscription:established("Tx", sender).head(){"Rx"}.klog("The sender of the update")
                     }
                 })
            fired{
                x = "Event was fired".klog("The event was fired to send the mssage.........")
            }
        }
