ruleset wovyn_base {
    meta {
        name "Wovyn Base"
        description <<
        "Wovyn sensor ruleset"
        >>
        author "Austen Arts"
    }
    global {
        temperature_threshold = 70
    }

    rule process_heartbeat {
        select when wovyn heartbeat where event:attr("genericThing")
        send_directive("say", {"something": "heartbeat processed"})
        fired {
          temp = event:attr("genericThing").get(["data", "temperature"])
          t_value = temp[0].get(["temperatureF"])
          raise wovyn event "new_temperature_reading"
            attributes {
              "temperature": t_value,
              "timestamp": time:now()
            }
        }
    }
    
    rule find_high_temps {
      select when wovyn new_temperature_reading
      pre {
          t_value = event:attr("temperature")
          msg = (t_value > temperature_threshold) => "temperature violation!"
            | "keeping it cool"
          problem = t_value > temperature_threshold
      }
      send_directive("temperature_update", {"message": msg})
      fired {
        raise wovyn event "threshold_violation"
          attributes {
            "message": msg
          }
        if problem
      }

    }
    
    rule threshold_notification {
      select when wovyn threshold_violation
      send_directive("temperature_notification", {"notification": "high temp = bad!"})
    }
    
}
