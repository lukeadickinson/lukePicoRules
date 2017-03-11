ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Luke Dickinson"
    logging on
    shares hello, functionName, __testing
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
                           { "name": "__testing" } ],
              "events": [ { "domain": "echo", "type": "hello" , "attrs": [ "attName" ]} ]
    }

  }
  
  rule hello_world {
    select when echo hello
    pre{
        localName = event:attr("attName").defaultsTo(ent:entity_name,"use stored name")
    }
    send_directive("say") with
      something = "Hello World" + localName
  }

  rule store_name {
    select when hello functionName
    pre{
        localName = event:attr("attName").klog("our passed in name: ")
    }
    send_directive("store_name") with
        optionsName = localName
    always{
        ent:entityName := localName
    }
  }
}