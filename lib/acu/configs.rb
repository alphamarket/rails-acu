module Acu
  module Configs

    mattr_accessor :base_controller
    @@base_controller = 'ApplicationController'

    mattr_accessor :allow_by_default
    @@allow_by_default = false

    mattr_accessor :audit_log_file
    @@audit_log_file = nil

    # for getting options
    def self.get name
      eval("@@#{name}")
    end
  end
end