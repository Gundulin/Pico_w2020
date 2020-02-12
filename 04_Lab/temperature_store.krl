ruleset temperature_store {
    meta {
        name "Temperature Store"
        description <<
        "temperature_store ruleset"
        >>
        author "Austen Arts"
        
        provides temperatures, threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
    }
    global {
      temp_collection = []
      violation_collection = []
      clear_collection = []
      
      /* Functions */
      temperatures = function() {
        return ent:temp_collection
      }
      
      threshold_violations = function() {
        return ent:violation_collection
      }
      
      inrange_temperatures = function() {
        new_array = new_array.append(ent:temp_collection.filter(function(x){
          ent:violation_collection.any(function(y){
            x != y
          })
        }))
        return new_array
      }
      
    }
    
    /** Rules */
    rule collect_temperatures {
      select when wovyn new_temperature_reading
      pre {
        passed_temp = event:attr("temperature").klog("our passed in temp: ")
        passed_time = event:attr("timestamp").klog("our passed in time: ")
      }
      always {
        ent:temp_collection := ent:temp_collection.append({"temperature": passed_temp, "timestamp": passed_time})
      }
    }
    
    rule collect_threshold_violations {
      select when wovyn threshold_violation
      pre {
        passed_temp = event:attr("temperature").klog("threshold violation temp: ")
        passed_time = event:attr("timestamp").klog("threshold violation time: ")
      }
      always {
        ent:violation_collection := ent:violation_collection.append({"temperature": passed_temp, "timestamp": passed_time})
      }
    }
    
    rule clear_temperatures {
      select when sensor reading_reset
      always {
        ent:temp_collection := clear_collection
        ent:violation_collection := clear_collection
      }
    }
}
