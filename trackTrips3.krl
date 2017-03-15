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
        allTrips = ent:trip;
        longTrips = ent:longTrip;
        shortTrips = {};
        shortTripskeys = allTrips.keys().difference(longTrips.keys());
        shortTrips = allTrips.filter(function(v,k){
            shortTripskeys.any(function(shortKey){
                k.as("Number")== shortKey.as("Number")
                })
           });
        //foreach shortTripskeys setting (shortKey){
        //    shortTrips{[shortKey, "mileage"]} := allTrips{[shortKey, "mileage"]};
        //    shortTrips{[shortKey, "time"]} := allTrips{[shortKey, "time"]};
        //}
            
        shortTrips
    }

    blank_Trip = {}
    blank_Long_Trip = {}
    blank_Trip_Counter = {"tripCount": 0 }

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
    }
    send_directive("say") with
        mileage = messageInput
        currentTime = timeStamp
    always{
        ent:tripCounter := ent:tripCounter.defaultsTo(blank_Trip_Counter,"initialization was needed");
        ent:trip := ent:trip.defaultsTo(blank_Trip,"initialization was needed");
        currentTripCount = ent:tripCounter{["tripCount"]};
        ent:tripCounter{["tripCount"]} := currentTripCount + 1;
        currentNewTripCount = ent:tripCounter{["tripCount"]};

        ent:trip{[currentNewTripCount, "mileage"]} := messageInput;
        ent:trip{[currentNewTripCount, "time"]} := timeStamp
    }
}

    rule found_long_trips{
        select when explicit found_long_trip
        pre{
            messageInput = event:attr("mileage").klog("our passed in input: ")
            timeStamp = time:now()
            }
        send_directive("say") with
            mileage = messageInput
            currentTime = timeStamp
        always{
            ent:tripCounter := ent:tripCounter.defaultsTo(blank_Trip_Counter,"initialization was needed");
            ent:longTrip := ent:longTrip.defaultsTo(blank_Long_Trip,"initialization was needed");
            currentTripCount = ent:tripCounter{["tripCount"]};

            ent:longTrip{[currentTripCount, "mileage"]} := messageInput;
            ent:longTrip{[currentTripCount, "time"]} := timeStamp
        }
    }

    rule clear_trips {
    select when car trip_reset
        always {
            ent:trip := blank_Trip;
            ent:longTrip := blank_Long_Trip;
            ent:tripCounter := blank_Trip_Counter
        }
    }

}