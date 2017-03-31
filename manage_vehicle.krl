ruleset manage_vehicle {
  meta {
    name "manage_vehicle"
    author "Luke Dickinson"
    logging on
    use module io.picolabs.pico alias wrangler
    use module Subscriptions
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ] }
  }
  
  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subcription:")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
}