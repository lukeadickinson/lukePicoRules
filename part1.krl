ruleset echo_server {
  meta {
    name "Echo server"
    author "Luke Dickinson"
    shares returnMessage, __testing
  }
  
  global {
    returnMessage = function(message) {
        message
    }

    __testing = { "queries": [ { "name": "returnMessage", "args": [ "message" ] },
                           { "name": "__testing" } ],
                
              "events": [ { "domain": "echo", "type": "hello"},
                          { "domain": "echo", "type": "message" , "attrs": [ "input"]}
                        ]
    }
  }


    rule hello_world{
    select when echo hello
    send_directive("say") with
        something = returnMessage("Hello World")
    }
    
    rule echo{
    select when echo message
    pre{
        messageInput = event:attr("input").klog("our passed in input: ")
    }
    send_directive("say") with
        something = returnMessage(messageInput)
    }

}