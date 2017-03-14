ruleset trip_store{
  meta {
    name "trip_store"
    author "Luke Dickinson"
    logging on
    shares returnMessage,trips,long_trips,short_trips, __testing
  }
  
  global {
    returnMessage = function(message) {
        message
    }

    trips = function()
    {
        ent:trip
    }

    long_trips = function()
    {
        ent:longTrip
    }

    short_trips = function()
    {

    }
    blank_Trip = {}
    blank_Long_Trip = {}
    blank_Trip_Counter = {"tripCount": "0" }
    blank_Long_Trip_Counter = {"tripCount": "0" }

    __testing = { "queries": [ { "name": "returnMessage", "args": [ "message" ] },
                            { "name": "trips", "args": [] },
                            { "name": "long_trips", "args": [] },
                            { "name": "short_trips", "args": [] },
                           { "name": "__testing" } ],
                
              "events": [ { "domain": "explicit", "type": "trip_processed" , "attrs": [ "mileage"]},
                          { "domain": "explicit", "type": "found_long_trip" , "attrs": [ "mileage"]},
                          { "domain": "car", "type": "trip_reset" , "attrs": []}
                        ]
    }
  }

rule collect_trips{
    select when explicit trip_processed
    pre{
        messageInput = event:attr("mileage").klog("our passed in input: ")
        timeStamp = time:now()
        currentTripCount = ent:tripCounter{["tripCount"]}        
}
    send_directive("say") with
        mileage = messageInput
        currentTime = timeStamp
    always{
        ent:tripCounter := ent:tripCounter.defaultsTo(blank_Trip_Counter,"initialization was needed");
        ent:trip := ent:trip.defaultsTo(blank_Trip,"initialization was needed");
        ent:trip{[currentTripCount,"trip", "mileage"]} := messageInput;
        ent:trip{[currentTripCount,"trip", "time"]} := timeStamp;
        ent:tripCounter{["tripCount"]} := currentTripCount + 1
    }
}

    rule found_long_trips{
        select when explicit found_long_trip
        pre{
            messageInput = event:attr("mileage").klog("our passed in input: ")
            timeStamp = time:now()
            currentLongTripCount = ent:longTripCounter{["tripCount"]}

            }
        send_directive("say") with
            mileage = messageInput
            currentTime = timeStamp
        always{
            ent:longTripCounter := ent:longTripCounter.defaultsTo(blank_Long_Trip_Counter,"initialization was needed");
            ent:longTrip := ent:longTrip.defaultsTo(blank_Long_Trip,"initialization was needed");


            ent:longTrip{[currentLongTripCount,"trip", "mileage"]} := messageInput;
            ent:longTrip{[currentLongTripCount,"trip", "time"]} := timeStamp;
            ent:longTripCounter{["tripCount"]} := currentLongTripCount + 1
        }
    }

    rule clear_trips {
    select when car trip_reset
        always {
            ent:trip := blank_Trip;
            ent:longTrip := blank_Long_Trip;
            ent:tripCounter := blank_Trip_Counter;
            ent:longTripCounter := blank_Long_Trip_Counter
        }
    }

}