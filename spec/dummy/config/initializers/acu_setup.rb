Acu.setup do |config|
  # to tighten the security this is enabled by default
  # i.e if it checked to be true, then if a request didn't match to any of rules, it will get passed through
  # otherwise the requests which don't fit into any of rules, we be denied by default
  config.allow_by_default = false

  # the audit log file, to log how the requests handles, good for production
  # leave it black for nil to disable the logging
  config.audit_log_file   = ""
end