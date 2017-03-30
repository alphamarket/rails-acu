require 'rails'
require 'active_support'

module Acu

  def self.register *files, under: 'acu/', global: false
    command = 'autoload'
    command = "Acu.#{command}" if not global
    files.each { |f| eval "#{command} :#{f.humanize.to_sym}, '#{under}#{f}'" }
  end

  register 'engine', 'rules', 'monitor', 'listeners', 'injectors', 'configs'

  # Default way to set up Acu. Run rails generate devise_install to create
  # a fresh initializer with all configuration values.
  def self.setup
    yield Acu::Configs
  end

  # include listeners
  include Listeners
  # include Injector operations
  include Injectors
end