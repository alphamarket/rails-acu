require 'rails'
require 'active_support'

module Acu
  [
    'engine',
    'config',
    'rules',
    'monitor'
  ].each do |file|
    Acu.autoload file.humanize.to_sym, "acu/#{file}"
  end

  # reset the configs
  Config.reset
end
