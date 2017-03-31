Acu.setup do |config|
  # name it to the Base Application Controller that your project
  # is going to use as a base of all of your controllers.
  config.base_controller = :ApplicationController

  # to tighten the security this is enabled by default
  # i.e if it checked to be true, then if a request didn't match to any of rules, it will get passed through
  # otherwise the requests which don't fit into any of rules, we be denied by default
  config.allow_by_default = false

  # the audit log file, to log how the requests handles, good for production
  # leave it black for nil to disable the logging
  config.audit_log_file   = ""

  # cache the rules to make your site faster
  # it's not recommanded to use it in developement/test evn.
  config.use_cache = false
end