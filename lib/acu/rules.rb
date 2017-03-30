require_relative 'utilities'

module Acu
  class Rules

    @rules = { }
    @entities = { }

    class << self

      protected :new
      attr_reader :rules
      attr_reader :entities

      include Utilities

      def initialize
        reset
      end

      def reset
        @rules = { }
        @entities = { }
      end

      def allow_by_default
        Config.set true, :default, :allow?
      end

      # only: only the defined `controllers` in the `namespace`
      # except: except the defined `controllers` in the `namespace`
      def namespace name = nil, except: nil, only: nil
        only = nil if only and not (only.kind_of?(Array) or only.length == 0)
        except = nil if except and not (except.kind_of?(Array) or except.length == 0)
        raise Errors::AmbiguousRule.new('cannot have both `only` and `except` options at the same time for namespace `%s`' %name) if only and except
        pass namespace: { name: name ? name.downcase : name, except: except, only: only } do
          yield
        end
      end

      # only: only the defined `actions` in the `controller`
      # except: except the defined `actions` in the `controller`
      def controller name, except: nil, only: nil
        only = nil if only and not (only.kind_of?(Array) or only.length == 0)
        except = nil if except and not (except.kind_of?(Array) or except.length == 0)
        raise Errors::AmbiguousRule.new("there is already an `except` or `only` constraints defined in container namespace `#{@_params[:namespace][:name]}`") if @_params[:namespace] and (@_params[:namespace][:except] || @_params[:namespace][:only])
        raise Errors::AmbiguousRule.new('cannot have both `only` and `except` options at the same time for controller `%s`' %name) if only and except
        pass controller: { name: name.downcase, except: except, only: only } do
          yield
        end
      end

      def action name
        raise Errors::AmbiguousRule.new("at least one of the parent `controller` or `namespace` needs to be defined for the this action") if not (@_params[:namespace] || @_params[:controller])
        raise Errors::AmbiguousRule.new("there is already an `except` or `only` constraints defined in container controller `#{@_params[:controller][:name]}`") if @_params[:controller] and (@_params[:controller][:except] || @_params[:controller][:only])
        pass action: { name: name.downcase } do
          yield
        end
      end

      def define(&block)
        helper_initialize
        self.instance_eval(&block)
      end

      # locks the rules to be read-only
      def lock
        self.freeze
      end

      def whois(symbol, args: nil, &block)
        @entities[symbol] = {
          args: [args || []].flatten,
          callback: block
        }
      end

      #################### the ops ######################
      # at this point we assign the class varible rules #
      ###################################################

      def allow symbol, on: []
        op symbol, :allow, on
      end

      def deny symbol, on: []
        op symbol, :deny, on
      end

      ################### end of ops ####################

      protected

      def op symbol, opr, on
        raise Errors::InvalidData.new("invalid argument") if symbol.to_s.blank? or opr.to_s.blank?
        raise Errors::AmbiguousRule.new("cannot have `on` argument inside the action `#{@_params[:action][:name]}`") if not on.empty? and @_params[:action]
        raise Errors::InvalidData.new("the symbol `#{symbol}` is not defined by `whois`") if not @entities.include? symbol
        return if on.empty? and build_rule({"#{symbol}": opr})
        # for each action in the `on` create a new rule
        on.each do |a|
          action a do
            build_rule({"#{symbol}": opr})
          end
        end
      end

      def build_rule rule
        @rules[@_params.clone] ||= {}
        @rules[@_params.clone] = rules[@_params.clone].merge(rule);
      end

      def build_rule_entry
        n = @_params[:namespace]
        c = @_params[:controller]
        a = @_params[:action]
        raise Errors::AmbiguousRule.new('invalid input') if not ( n or c or a )
        raise Errors::AmbiguousRule.new('cannot have rule for controller `%s` inside the namespace `%s` that `except`ed it!' %[c[:name], n[:name]]) if n and n[:except] and c and n[:except].include? c[:name]
        raise Errors::AmbiguousRule.new('cannot have rule for action `%s` inside the controler `%s` that `except`ed it!' %[a[:name], c[:name]]) if c and c[:except] and a and c[:except].include? a[:name]
        raise Errors::AmbiguousRule.new('cannot have rule for controller `%s` inside the namespace `%s` that has bounded to `only` some other controllers!' %[c[:name], n[:name]]) if n and n[:only] and c and not(n[:only].include? c[:name])
        raise Errors::AmbiguousRule.new('cannot have rule for action `%s` inside the controller `%s` that has bounded to `only` some other actions!' %[a[:name], c[:name]]) if c and c[:only] and a and not(c[:only].include? a[:name])

        entries = [];

        entries << :namespace if n
        entries << :controller if c
        entries << :action if a

        return entries
      end
    end
  end
end