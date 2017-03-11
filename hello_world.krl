ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>> 
    author "Luke Dickinson"
    logging on
    shares hello, name, __testing
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                           { "name": "__testing" } ],
              "events": [ { "domain": "echo", "type": "hello" , "attrs": [ "name" ]} ]
    }

  }
  
  rule hello_world {
    select when echo hello
    pre{
        name = event:attr("name").defaultsTo(ent:name,"use stored name")
    }
    send_directive("say") with
      something = "Hello World" + name
  }

 rule store_name {
    select when hello name
    pre{
        name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("store_name") with
        name = name
    always{
        ent:name := name
    }
  }
}