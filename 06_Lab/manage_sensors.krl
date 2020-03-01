ruleset manage_sensors {
  meta {
    name "Sensor Manager"
    description <<
    Ruleset that manages sensors by creating
    additional child picos to handle new sensors
    >>
    author "Austen Arts"
    shares sensors, sensor_temperatures
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
    
    default_threshold = 69
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
}
