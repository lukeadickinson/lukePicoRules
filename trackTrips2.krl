ruleset track_trips2{
  meta {
    name "track_trips2"
    author "Luke Dickinson"
    logging on
    shares returnMessage, __testing
  }
  
  global {
    returnMessage = function(message) {
        message
    }

    __testing = { "queries": [ { "name": "returnMessage", "args": [ "message" ] },
                           { "name": "__testing" } ],
                
              "events": [ { "domain": "echo", "type": "message" , "attrs": [ "mileage"]},
                          { "domain": "explicit", "type": "trip_processed" , "attrs": [ "mileage"]}
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
            attributes {"mileage":messageInput}
        }
    }
    rule find_long_trips{
        select when explicit trip_processed
        pre{
            messageInput = event:attr("mileage").klog("our passed in input: ")
            longTrip = 10
            messageAsNumber = messageInput.as("Number")
        }
        send_directive("say") with
            message = returnMessage("find_long_trips")

        fired{
                raise explicit event "found_long_trip"
                attributes {"mileage":messageInput}
                if messageAsNumber > longTrip
            }
    }


}