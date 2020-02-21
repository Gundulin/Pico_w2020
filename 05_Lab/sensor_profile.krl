ruleset sensor_profile {
  meta {
    name "Sensor Profile"
    author "Austen Arts"
    description <<
    "sensor profile ruleset" >>
    shares getProfile
  }
  global {
    getProfile = function() {
      return {
        "name": ent:name, 
        "phone": ent:phone, 
        "location": ent:location,
        "threshold": ent:threshold
      }
    }
  }
  
  rule update_profile {
    select when sensor profile_updated
    pre {
      name = event:attr("name").klog("passed name: ")
      phone = event:attr("phone").klog("passed phone: ")
      location = event:attr("location").klog("passed location: ")
      threshold = event:attr("threshold").klog("passed threshold: ")
    }
    always {
      ent:name := name
      ent:phone := phone
      ent:location := location
      ent:threshold := threshold
    }
  }
}
