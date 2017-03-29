module Acu
  class Config

    @configs = { }

    class << self

      protected :new
      attr_reader :configs

      def initialize
        reset
      end

      def reset
        @options = {
          defaults: {
            allow: false
          }
        }
      end

      def audit_log log
      end

      class_eval <<-METHODS, __FILE__, __LINE__ + 1

        def #{key}_by_#{root} val
          @configs[root][key] = val
        end

        def #{key}_by_#{root}?
          @configs[root][key]
        end

        def #{key}_#{root} val
          @configs[root][key] = val
        end

        def #{key}_#{root}?
          @configs[root][key]
        end

        def #{key} val
          @configs[key] = val
        end

        def #{key}?
          @configs[key]
        end

      METHODS
    end
  end
end