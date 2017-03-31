module Acu
  module Configs

    mattr_accessor :base_controller
    @@base_controller = 'ApplicationController'

    mattr_accessor :allow_by_default
    @@allow_by_default = false

    mattr_accessor :audit_log_file
    @@audit_log_file = nil

    mattr_accessor :use_cache
    @@use_cache = false

    mattr_accessor :cache_namespace
    @@cache_namespace = nil

    mattr_accessor :cache_expires_in
    @@cache_expires_in = nil

    mattr_accessor :cache_race_condition_ttl
    @@cache_race_condition_ttl = nil

    # for getting options
    def self.get name
      eval("@@#{name}")
    end
  end
end