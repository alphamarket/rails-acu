require_relative 'controllers/helpers'

module Acu
  module Injectors
    class << self

      ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |**args|
        eval((Acu::Configs.get :base_controller).to_s).class_eval do
          include Acu::Controllers::Helpers
          before_action { Monitor::gaurd }
        end
      end

    end
  end
end