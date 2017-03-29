module Acu
  class Config

    @configs = { }

    class << self

      protected :new
      attr_reader :configs

      def reset
        @configs = {
          defaults: {
            allow: false
          }
        }
      end

      def audit_log log
      end

      def get *args
        @configs.dig *args
      end

      def set val, *args
        @configs = args.reverse.inject(val) { |k, v| {k => v} }
      end
    end
  end
end