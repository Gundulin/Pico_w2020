ruleset wovyn_base {
    meta {
        name "Wovyn Base"
        description <<
        "Wovyn sensor ruleset"
        >>
        author "Austen Arts"
    }
    global {

    }

    rule process_heartbeat {
        select when wovyn heartbeat
        send_directive("say", {"something": "temp"})
    }
    
}
