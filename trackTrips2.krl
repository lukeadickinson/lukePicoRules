ruleset track_trips2{
  meta {
    name "track_trips2"
    author "Luke Dickinson"
    shares returnMessage, __testing
  }
  
  global {
    returnMessage = function(message) {
        message
    }

    __testing = { "queries": [ { "name": "returnMessage", "args": [ "message" ] },
                           { "name": "__testing" } ],
                
              "events": [ { "domain": "echo", "type": "message" , "attrs": [ "mileage"]}
                        ]
    }
  }


    rule process_trip{
    select when car new_trip
    pre{
        messageInput = event:attr("mileage").klog("our passed in input: ")
    }
    send_directive("say") with
        trip_length = returnMessage(messageInput)
    }

}