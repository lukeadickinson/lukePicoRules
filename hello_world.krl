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
                
              "events": [ { "domain": "echo", "type": "hello" , "attrs": [ "attr_name" ]},
                          { "domain": "save", "type": "name" , "attrs": [ "attr_name" ]} 
                        ]
    }

  }
  
  rule hello_world {
    select when echo hello
    pre{
        passed_name = event:attr("attr_name").defaultsTo(ent:myName,"use stored name")
    }
    send_directive("say") with
      something = "Hello World " + passed_name
  }

 rule store_name {
    select when save name
    pre{
        passed_name = event:attr("attr_name").klog("our passed in name: ")
    }
    send_directive("store_name") with
        options_name = passed_name
    always{
        ent:myName := passed_name
    }
  }
}
