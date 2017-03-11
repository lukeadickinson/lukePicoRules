ruleset track_trips{
  meta {
    name "track_trips"
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
    select when echo message
    pre{
        messageInput = event:attr("input").klog("our passed in input: ")
    }
    send_directive("say") with
        trip_length = returnMessage(messageInput)
    }

}