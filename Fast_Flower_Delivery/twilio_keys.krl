ruleset twilio_keys {
    meta {
        key twilio {
            "account_sid": "<your twilio account sid>",
            "auth_token": "<your twilio auth token>",
            "phone_number_from": "<your twilio phone number>" //remember to include the '+' at the beginning!
        }
        provides keys twilio to twilio
    }
}
