ruleset wovyn_base {
    meta {
        name "Wovyn Base"
        description <<
        "Wovyn sensor ruleset"
        >>
        author "Austen Arts"
        shares current_temp
    }
    global {
        temperature_threshold = 60
        current_temp = function() {
          return (ent:current_temp != null) => ent:current_temp | 7734
        }
    }

    rule process_heartbeat {
        select when wovyn heartbeat where event:attr("genericThing")
        pre {
          temp = event:attr("genericThing").get(["data", "temperature"])
          t_value = temp[0].get(["temperatureF"])
        }
        send_directive("say", {"something": "heartbeat processed"})
        fired {
          // temp = event:attr("genericThing").get(["data", "temperature"])
          // t_value = temp[0].get(["temperatureF"])
          raise wovyn event "new_temperature_reading"
            attributes {
              "temperature": t_value,
              "timestamp": time:now()
            }
        } finally {
          ent:current_temp := t_value
        }
    }
    
    rule find_high_temps {
      select when wovyn new_temperature_reading
      pre {
          t_value = event:attr("temperature")
          time = event:attr("timestamp")
          // msg = (t_value > temperature_threshold) => "temperature violation!"
          //   | "keeping it cool"
          problem = t_value > ent:temperature_threshold
      }
      send_directive("temperature_update", {"message": msg})
      fired {
        raise wovyn event "threshold_violation"
          attributes {
            "temperature": t_value,
            "timestamp": time
          }
        if problem
      }

    }
    
    rule threshold_notification {
      select when wovyn threshold_violation
      send_directive("temperature_notification", {"notification": "high temp = bad!"})
    }
    
    rule update_threshold {
      select when sensor profile_updated
      pre {
        threshold = event:attr("threshold").klog("passed in new threshold: ")
      }
      always {
        ent:temperature_threshold := threshold.as("Number").klog("updated threshold: ")
      }
    }
    
    rule auto_accept {
      select when wrangler inbound_pending_subscription_added
      pre {
        attributes = event:attrs.klog("subcription:")
      }
      always {
        raise wrangler event "pending_subscription_approval"
          attributes attributes
      }
    }
}
