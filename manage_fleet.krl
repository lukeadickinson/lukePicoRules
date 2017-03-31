ruleset manage_fleet{
  meta {
    name "manage_fleet"
    author "Luke Dickinson"
    logging on
    use module io.picolabs.pico alias wrangler
    use module Subscriptions
    shares getLast5Reports, createReportTrips, getVehicleSubscriptions, __testing
  }
  
  global {

    cloud = function(eci, mod, func, params) {
        cloud_url = "http://localhost:8080/sky/cloud/"+eci+"/trip_store/trips";
        response = http:get(cloud_url, (params || {}));
        status = response{"status_code"};
        response_content = response{"content"}.decode();

        // if HTTP status was OK & the response was not null and there were no errors...
        (status == 200) => response_content | status
    }



    returnMessage = function(message) {
        message
    }
    nameFromID = function(id) {
        "Vehicle " + id + " Pico"
    }
    childFromID = function(id) {
        ent:vehicles{[id]}
    }
    createReportTrips = function()
    {
        tripData = gatherReportData();
        magicObj = {"vehicles":ent:vehicles.length(), "responding": tripData.length(), "trips":tripData}
    }
    gatherReportData = function()
    {
        tripData = ent:vehicles.map(function (v,k)
        {
            v = cloud(v.eci, "trip_store", "trips", "")
        }
        )
    }
    getLast5Reports = function()
    {
        
        ent:reportDatabase
    }
    getVehicleSubscriptions = function()
    {
        Subscriptions:getSubscriptions()
    }

     __testing = { "queries": [ { "name": "getVehicleSubscriptions", "args": [] },
                                { "name": "createReportTrips", "args": [] },
                                { "name": "getLast5Reports", "args": [] }
                              ],
                          "events":  [ 
                                 { "domain": "car", "type": "new_vehicle", "attrs": [] },
                                 { "domain": "car", "type": "reset" , "attrs": []},
                                 { "domain": "car", "type": "unneeded_vehicle" , "attrs": ["car_id"]},
                                 { "domain": "car", "type": "createReport" , "attrs": []}
                             ] 
    }

  }

rule create_vehicle {
    select when car new_vehicle
    pre {
        car_id = ent:vehiclesCreatedEver.defaultsTo(0) + 1
        eci = meta:eci
    }
    //create new pico
    //create subscription
    //install rules in new vehicle
        always {
            ent:vehiclesCreatedEver := ent:vehiclesCreatedEver.defaultsTo(0) + 1;
            raise pico event "new_child_request"
            attributes { "dname": nameFromID(car_id), "color": "#2269B4", "car_id": car_id }
        }
    }

rule pico_child_initialized {
  select when pico child_initialized
  pre {
    the_car = event:attr("new_child")
    car_id = event:attr("rs_attrs"){"car_id"}
  }
  
    event:send(
    { "eci": the_car.eci, "eid": "install-ruleset",
     "domain": "pico", "type": "new_ruleset",
     "attrs": { "rid": "manage_vehicle", "car_id": car_id } } )

    event:send(
    { "eci": the_car.eci, "eid": "install-ruleset",
     "domain": "pico", "type": "new_ruleset",
     "attrs": { "rid": "track_trips2", "car_id": car_id } } )

    event:send(
    { "eci": the_car.eci, "eid": "install-ruleset",
     "domain": "pico", "type": "new_ruleset",
     "attrs": { "rid": "trip_store", "car_id": car_id } } )

    event:send(
    { "eci": the_car.eci, "eid": "install-ruleset",
     "domain": "pico", "type": "new_ruleset",
     "attrs": { "rid": "Subscriptions", "car_id": car_id } } )
  
  fired {
    ent:vehicles := ent:vehicles.defaultsTo({});
    ent:vehicles{[car_id]} := the_car;
    
    raise wrangler event "subscription"
    with name = car_id
         name_space = "car"
         my_role = "fleet"
         subscriber_role = "vehicle"
         channel_type = "subscription"
         subscriber_eci = the_car.eci
  }
}

rule delete_vehicle {
    select when car unneeded_vehicle
    pre{
        car_id = event:attr("car_id")
        exists = ent:vehicles >< car_id
        child_to_delete = childFromID(car_id)
    }
    if exists then
    send_directive("vehicle_deleted")
      with car_id = car_id
  fired {

    raise wrangler event "subscription_cancellation"
        with subscription_name = "car:"+car_id;

    raise pico event "delete_child_request"
      attributes child_to_delete;
    ent:vehicles{[car_id]} := null


  }
}

rule createReportSG {
    select when car createReport
        pre{
            eci = meta:eci.klog("mooo")
            reportID = ent:reportID.defaultsTo(0) + 1
            fiveMinusReportID = reportID - 5
        }
        event:send(
            { "eci": eci, "eid": "createReportSG",
            "domain": "car", "type": "createReport_private",
            "attrs": { "rid": "trip_store", "reportID": reportID} } )
        always{
            ent:reportID := reportID;
            ent:reportDatabase := ent:reportDatabase.defaultsTo({});
            ent:reportDatabase := ent:reportDatabase.delete(["ID"+fiveMinusReportID]);

            ent:reportDatabase{["ID" +reportID]} := ent:reportDatabase{["ID" +reportID]}.defaultsTo({});
            ent:reportDatabase{["ID" +reportID,"vehicles"]} := ent:vehicles.length();
            ent:reportDatabase{["ID" +reportID,"responding"]} := ent:reportDatabase{["ID" +reportID,"responding"]}.defaultsTo(0)
        }
    }

rule createReportSG_Private {
    select when car createReport_private
        foreach ent:vehicles setting (the_car)
        pre{
            eci = meta:eci.klog("mooo")
            reportIDString = "ID" + event:attr("reportID")
        }
        event:send(
            { "eci": the_car.eci, "eid": "createReport",
            "domain": "car", "type": "requestReport",
            "attrs": { "rid": "trip_store", "myEci": eci, "myID":the_car.id, "reportID": reportIDString} } )

    }

rule gatherReportPiece {
    select when car responseReport
        pre{
            eci = meta:eci.klog("IT WORKED")
            tripData = event:attr("tripData")
            myID = event:attr("myID")
            reportID = event:attr("reportID")
        }
        always {
            ent:reportDatabase := ent:reportDatabase.defaultsTo({});
            ent:reportDatabase{[reportID]} := ent:reportDatabase{[reportID]}.defaultsTo({});
            ent:reportDatabase{[reportID,myID]} := ent:reportDatabase{[reportID,myID]}.defaultsTo({});
            ent:reportDatabase{[reportID,myID]} := tripData;
            ent:reportDatabase{[reportID,"responding"]} := ent:reportDatabase{[reportID,"responding"]} + 1;

            ent:responseCount := ent:responseCount.defaultsTo(0);
            ent:responseCount := ent:responseCount + 1
        }
    }

rule create_vehicle {
    select when car new_vehicle
    pre {
        car_id = ent:vehiclesCreatedEver.defaultsTo(0) + 1
        eci = meta:eci
    }
    //create new pico
    //create subscription
    //install rules in new vehicle
        always {
            ent:vehiclesCreatedEver := ent:vehiclesCreatedEver.defaultsTo(0) + 1;
            raise pico event "new_child_request"
            attributes { "dname": nameFromID(car_id), "color": "#2269B4", "car_id": car_id }
        }
    }

rule clear_ent_data {
    select when car reset
        always {
            ent:vehicles := {};
            ent:vehiclesCreatedEver := 0;
            ent:reportDatabase := {};
            ent:reportID := 0;
            ent:responseCount := 0
        }
    }
}

//rule pico_ruleset_added {
//  select when pico ruleset_added
//  pre {
//  }
//  always {
//  }
//}