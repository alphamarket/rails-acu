require 'rails'
require 'active_support'

module Acu
  [
    'engine',
    'rules'
  ].each do |file|
    autoload file.humanize.to_sym, "acu/#{file}"
  end
end
