module Acu
  module Listeners

    @@collective_data = { }

    class << self

      attr_reader :collective_data

      ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |**args|
        # collects the request parameters for the given [controller, action to be used in Monitor]
        @@collective_data = @@collective_data.merge([:request, :parameters].reverse.inject(args[:params] || { }) { |v, k| {k => v}})
      end
      # get access to collected data
      def data; @@collective_data end
    end
  end
end