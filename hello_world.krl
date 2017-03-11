ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Luke Dickinson"
    logging on
    shares hello, __testing, function_name
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                           { "name": "__testing" } ],
              "events": [ { "domain": "echo", "type": "hello" , "attrs": [ "att_name" ]} ]
    }

  }
  
  rule hello_world {
    select when echo hello
    pre{
        local_name = event:attr("att_name").defaultsTo(ent:entity_name,"use stored name")
    }
    send_directive("say") with
      something = "Hello World" + local_name
  }

  rule store_name {
    select when hello function_name
    pre{
        local_name = event:attr("att_name").klog("our passed in name: ")
    }
    send_directive("store_name") with
        options_name = local_name
    always{
        ent:entity_name := local_name
    }
  }
}