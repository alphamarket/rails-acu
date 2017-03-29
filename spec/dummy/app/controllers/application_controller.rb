class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action { Acu::Monitor.gaurd request, :current_user => current_user }
end
