ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>> 
    author "Luke Dickinson"
    logging on
    shares hello, __testing
  }
  
  global {
    helloFake = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    __testing = { "queries": [ { "name": "helloFake", "args": [ "obj" ] },
                           { "name": "__testing" } ],
                
              "events": [ { "domain": "echo", "type": "hello" , "attrs": [ "id" ]},
                          { "domain": "save", "type": "name" , "attrs": [ "id", "first_name", "last_name" ]},
                          { "domain": "clear", "type" : "names" } 
                        ]
    }
    clear_name = { "_0": { "name": { "first": "GlaDOS", "last": "" } } }

    name = function(id){
    all_users = users();
    nameObj = id => all_users{[id,"name"]}
                    | { "first": "HAL", "last": "9000" };
    first = nameObj{"first"};
    last = nameObj{"last"};
    first + " " + last
    }
    
    users = function(){
        ent:myName
    }
  }
  
  rule hello_world {
    select when echo hello
    pre{
        id = event:attr("id").defaultsTo("_0")
        passed_name = name(id)
        visits = ent:myName{[id,"visits"]}
    }
    send_directive("say") with
      something = "Hello World " + passed_name
    
    fired {
    ent:myName{[id,"visits"]} := visits + 1
    }
  }

 rule store_name {
    select when save name
    pre{
        passed_id = event:attr("id").klog("our passed in id: ")
        passed_first_name = event:attr("first_name").klog("our passed in first_name: ")
        passed_last_name = event:attr("last_name").klog("our passed in last_name: ")
        }
    send_directive("store_name") with
        id = passed_id
        first_name = passed_first_name
        last_name = passed_last_name
    always{
        ent:myName := ent:myName.defaultsTo(clear_name,"initialization was needed");
        ent:myName{[passed_id,"name","first"]} := passed_first_name;
        ent:myName{[passed_id,"name","last"]} := passed_last_name
    }
  }

    rule clear_names {
    select when clear names
        always {
            ent:myName := clear_name
        }
    }

}
