ruleset manage_sensors {
  meta {
    name "Sensor Manager"
    description <<
    Ruleset that manages sensors by creating
    additional child picos to handle new sensors
    >>
    author "Austen Arts"
    shares sensors, sensor_temperatures, get_temperatures, get_reports
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias Subscriptions
  }
  
  global {
    namePico = function(name) {
      name + "_Sensor"
    }
    
    sensors = function() {
      return ent:sensors
    }

    sensor_temperatures = function() {
      host = "http://localhost:8080"
      a = ent:sensors.map(function(value, key) {
        url = host + "/sky/cloud/" + value + "/wovyn_base/current_temp?"
        response = http:get(url, "")
        answer = response{"content"}.decode().klog("answer: ")
        answer
      })
      return a
    }
    
    get_temperatures = function() {
      host = "http://localhost:8080"
      a = Subscriptions:established().filter(function(x) {
        x{"Tx_role"} == "temperature sensor"
      }).map(function(x) {
        url = host + "/sky/cloud/" + x{"Tx"} + "/wovyn_base/current_temp?"
        response = http:get(url, "")
        answer = response{"content"}.decode().klog("answer: ")
        answer
      })
      return a
    }
    
    default_threshold = 69
    
    get_reports = function() {
      end = ent:report_ID - 5
      a = ent:reports.filter(function(x) {
        b = x.as("Number")
        b > end
      })
      return a
    }
  }
  
  rule identify_sensor {
    select when sensor identify
    pre {
      sensors = wrangler:children.map(function(x){
        x{"eci"}
      }).filter(function(x){
        ent:sensors{x} != null
      }).log("sensors")
    }
  }
  
  rule sensor_subscription {
    select when sensor subscription
    foreach ent:sensors setting(sensor, index)
      event:send(
        {
          "eci": meta:eci,
          "eid": "subscription",
          "domain": "wrangler",
          "type": "subscription",
          "attrs": {"name": index.klog("index: "),
            "Rx_role": "manager",
            "Tx_role": "temperature sensor",
            "channel_type": "subscription",
            "wellKnown_Tx": sensor.klog("sensor: ")
          }
        })
  }
  
  rule create_subscription {
    select when sensor new_sub
    pre {
      name = event:attr("name")
      wellKnown_Tx = event:attr("wellKnown_Tx")
    }
    event:send({
      "eci": meta:eci,
      "eid": "subscription",
      "domain": "wrangler",
      "type": "subscription",
      "attrs": {
        "name": name,
        "Rx_role": "manager",
        "Tx_role": "temperature sensor",
        "channel_type": "subscription",
        "wellKnown_Tx": wellKnown_Tx
      }
    })
  }
  
  rule sensor_exists {
    select when sensor new_sensor
    pre {
      sensor_name = event:attr("name")
      exists = ent:sensors.get(sensor_name) != null
    }
    if exists.klog("exists: ") then
      send_directive("name_taken", {"name": sensor_name})
  }
  
  rule add_sensor {
    select when sensor new_sensor
    pre {
      sensor_name = event:attr("name")
      sensor_ECI = meta:eci
      exists = ent:sensors.get(namePico(sensor_name)) != null
    }
    if not exists then
      send_directive("creating_child", {"name": sensor_name})
    fired {
      raise wrangler event "child_creation"
        attributes { 
          "name": namePico(sensor_name),
          "color": "#9DFF8E", 
          "sensor_type": "Wovyn",
          "rids": ["wovyn_base", "temperature_store", "sensor_profile"]
        }
    }
  }

  rule child_profile {
    select when wrangler child_initialized where event:attr("sensor_type")
    // select when wrangler ruleset_added where event:attr("sensor_type")
    pre {
      //http://192.168.1.204:8080/sky/event/787RXuWe35WneQegiagbpW/none/sensor/profile_updated?name=Austen&location=here&phone=xxx-xxx-xxxx&threshold=75
      name = event:attr("name").klog("name: ")
      location = "living_room"
      phone = "801-111-0100"
      threshold = default_threshold
      ECI = event:attr("eci").klog("****ECI****(event:attr(\"eci\"): ")
      args = {
        "name": name,
        "location": location,
        "phone": phone,
        "threshold": threshold
      }
      host = "http://localhost:8080"
      url = host + "/sky/event/" + ECI + "/none/sensor/profile_updated"
      response = http:get(url, args)
      answer = response{"content"}.decode()
    }
    if response{"status_code"} == 200 then send_directive("child_profile", {"message": "profile updated!"})
    always {
      ent:sensors{name} := ECI
    }
  }
  
  rule delete_sensor {
    select when sensor unneeded_sensor
    pre {
      sensor_name = event:attr("sensor_name")
      exists = ent:sensors.get(sensor_name) != null
      child_to_delete = sensor_name
    }
    if exists then
      send_directive("deleting_sensor", {"sensor_name": sensor_name})
    fired {
      raise wrangler event "child_deletion"
        attributes {"name": child_to_delete};
      clear ent:sensors{sensor_name}
    }
    
  }
  
  rule sensor_threshold_violation {
    select when sensor threshold_violation
    fired {
    raise sms_service event "new_message"
      attributes {
        "message": "threshold violation!"
      }
    }
  }
  
  /* Lab 08: Step 1 */
  rule request_reports {
    select when report request
    foreach Subscriptions:established("Tx_role", "temperature sensor") setting (subscription)
      pre {
        sensor_subs = subscription.klog("subs")
      }
      event:send({
        "eci": subscription{"Tx"},
        "eid": "report",
        "domain": "sensor",
        "type": "request_report",
        "attrs": {
          "response_eci": meta:eci
        }
      })
  }
  
  rule collect_reports {
    select when sensor report
      pre {
        temps = event:attr("temperatures").klog("temperatures: ")
        sensor_id = event:attr("Rx")
        reported = ent:num_reported + 1.klog("num_reported: ")
        done = reported >= ent:sensors.length().klog("done: ")
      }
      fired {
        ent:temperatures{sensor_id} := temps
        ent:num_reported := (ent:num_reported != null) => ent:num_reported + 1 | 1
        raise report event "finished" if done
      }
  }
  
  rule create_report {
    select when report finished
    pre {
      report = {
        "temperature_sensors": ent:sensors.length(),
        "responding": ent:num_reported,
        "temperatures": ent:temperatures
      }
    }
    fired {
      ent:report_ID := (ent:report_ID.isnull()) => 0 | ent:report_ID + 1
      ent:reports{ent:report_ID} := report
      ent:num_reported := 0
      ent:temperatures := {}
    }
  }
}
