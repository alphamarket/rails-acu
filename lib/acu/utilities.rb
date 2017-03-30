module Acu
  module Utilities
    protected
    def helper_initialize
      instance_variable_set("@_params", {}) if not instance_variable_defined?("@_params")
    end
    def pass args = {}
      helper_initialize
      args.each { |k, v| @_params[k] = v }
      yield
      args.each { |k, _| @_params.delete k }
    end
  end
end