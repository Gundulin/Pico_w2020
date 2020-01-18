ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares hello, monkey
  }
   
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
    monkey = function(name) {
      // msg = "Hello " + name.defaultsTo("Monkey").klog("the passed in name was:")
      msg = (name != null) => "Hello " + name | "Hello Monkey";
      msg
    
    }
    
  }
   
  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }
  
  rule hello_monkey {
    select when echo monkey
    send_directive("say", {"something": "Hello Monkey"})
  }
   
}
