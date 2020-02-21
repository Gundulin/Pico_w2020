ruleset sms_service {
  meta {
    name "SMS Service"
    description <<
sends an SMS to a person
>>
    author "Austen Arts"
    logging on
    shares send_sms
  }
   
  global {
      
    send_sms = defaction(to, from, message, account_sid, auth_token){
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
        http:post(base_url + "Messages.json", form =
                      {
                        "From":from,
                        "To":to,
                        "Body":message
                      })
      }

    
  }

  rule test_send_sms {
    select when test new_message
    send_sms(event:attr(ent:phone),
             event:attr("2017482153"),
             event:attr("I'm testing my lab"),
             event:attr("AC8453662a2cc758889aeb51289e48e343"),
             event:attr("6311137882d7425bf7ad30c6c5230ffc"))
  }
  
  rule new_number_who_dis {
    select when sensor profile_updated
    pre {
      phone = event:attr("phone").klog("new number who dis: ")
    }
    always {
      ent:phone := phone
    }
  }
}
