require 'rails'
require 'active_support'

module Acu

  def self.register *files, under: 'acu/', global: false
    command = 'autoload'
    command = "Acu.#{command}" if not global
    files.each { |f| eval "#{command} :#{f.humanize.to_sym}, '#{under}#{f}'" }
  end

  register 'engine', 'config', 'rules', 'monitor', 'listeners', 'injectors'

  # reset the configs
  Config.reset
  # include listeners
  include Listeners
  # include Injector operations
  include Injectors
end