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
        
        fired{
            raise explicit event "trip_processed"
            attributes event:attr()
        }
    }
    rule find_long_trips{
        select when explicit trip_processed
        pre{
            messageInput = event:attr("mileage").klog("our passed in input: ")
            longTrip = 10
            messageAsNumber = messageInput.as("Number")
        }
        if messageAsNumber > longTrip then
            noop()

        fired{
            raise explicit event "found_long_trip"
            attributes event:attr()
        }
    }
}