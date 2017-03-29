require 'rails'
require 'active_support'

module Acu
  [
    'engine',
    'config',
    'rules',
  ].each do |file|
    autoload file.humanize.to_sym, "acu/#{file}"
  end

  [
    'errors',
    'monitor'
  ].each do |file|
    require_relative "acu/#{file}"
  end
end
