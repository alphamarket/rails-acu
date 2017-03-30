require 'rails'
require 'active_support'

module Acu

  def self.register *files, under: 'acu/'
    files.each { |f| Acu.autoload f.humanize.to_sym, "#{under}#{f}" }
  end

  register 'engine', 'config', 'rules', 'monitor', 'listeners'

  module Controller
    Acu.register 'helper', under: 'acu/controller/'
  end

  # reset the configs
  Config.reset
  # include listeners
  include Listeners
end