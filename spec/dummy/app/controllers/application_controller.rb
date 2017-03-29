class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action { Acu::Monitor.new request }
end
