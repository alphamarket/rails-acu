require_relative 'utilities'

module Acu
  class Rules

    @rules = { }
    @entities = { }

    @GRANT_SYMBOL = :allow
    @DENY_SYMBOL  = :deny

    class << self

      protected :new
      attr_reader :rules
      attr_reader :entities
      attr_reader :GRANT_SYMBOL
      attr_reader :DENY_SYMBOL

      include Utilities

      def initialize
        reset
      end

      def reset
        @rules = { }
        @_params = { }
        @entities = { }
      end

      # only: only the defined `controllers` in the `namespace`
      # except: except the defined `controllers` in the `namespace`
      def namespace *names, except: nil, only: nil
        names = [nil] if names.empty?
        only = nil if only and not (only.kind_of?(Array) or only.length == 0)
        except = nil if except and not (except.kind_of?(Array) or except.length == 0)
        raise Errors::AmbiguousRule.new("there is already an `except` or `only` constraints defined in container namespace `#{@_params[:namespace].map { |i| i[:name] }.join('::')}`") if (except or only) and @_params[:namespace] and @_params[:namespace].find { |n| n[:except] or n[:only] }
        raise Errors::AmbiguousRule.new('cannot have both `only` and `except` options at the same time for namespace(s) `%s`' %names.join(', ')) if only and except
        names.each do |name|
          pass namespace: { name: name ? name.downcase : name, except: except, only: only } do
            yield
          end
        end
      end

      # only: only the defined `actions` in the `controller`
      # except: except the defined `actions` in the `controller`
      def controller *names, except: nil, only: nil
        names = [names].flatten if name
        only = nil if only and not (only.kind_of?(Array) or only.length == 0)
        except = nil if except and not (except.kind_of?(Array) or except.length == 0)
        raise Errors::InvalidSyntax.new("nested controllers are not allowed!") if @_params[:controller] and not @_params[:controller].empty?
        raise Errors::AmbiguousRule.new("there is already an `except` or `only` constraints defined in container namespace `#{@_params[:namespace].map { |i| i[:name] }.join('::')}`") if @_params[:namespace] and @_params[:namespace].find { |n| n[:except] or n[:only] }
        raise Errors::AmbiguousRule.new('cannot have both `only` and `except` options at the same time for controller(s) `%s`' %names.join(', ')) if only and except
        names.each do |name|
          pass controller: { name: name.downcase, except: except, only: only } do
            yield
          end
        end
      end

      def action *names
        names = [names].flatten if name
        raise Errors::InvalidSyntax.new("nested actions are not allowed!") if @_params[:action] and not @_params[:action].empty?
        raise Errors::AmbiguousRule.new("at least one of the parent `controller` or `namespace` needs to be defined for the this action") if not (@_params[:namespace] || @_params[:controller])
        raise Errors::AmbiguousRule.new("there is already an `except` or `only` constraints defined in container controller(s) `#{@_params[:controller].map { |i| i[:name] }.join('::')}`") if @_params[:controller] and @_params[:controller].find { |n| n[:except] or n[:only] }
        names.each do |name|
          pass action: { name: name.downcase } do
            yield
          end
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

      def allow *symbol, on: []
        op *symbol, @GRANT_SYMBOL, on
      end

      def deny *symbol, on: []
        op *symbol, @DENY_SYMBOL, on
      end

      def override *symbol, with:, on: []
        raise Exception.new('not implemented!');
      end

      ################### end of ops ####################

      protected

      def op *symbol, opr, on
        symbol = symbol.flatten
        process_symbol *symbol
        raise Errors::InvalidData.new("invalid argument") if not symbol or symbol.to_s.blank? or opr.to_s.blank?
        raise Errors::AmbiguousRule.new("cannot have `on` argument inside the action `#{@_params[:action][:name]}`") if not on.empty? and (@_params[:action] and not @_params[:action].empty?)
        raise Errors::InvalidData.new("the symbol `#{symbol}` is not defined by `whois`") if not symbol.all? { |s| @entities.include? s }
        return if on.empty? and symbol.each { |s| build_rule({"#{s}": opr}) }
        # for each action in the `on` create a new rule
        on.each do |a|
          action a do
            symbol.each { |s| build_rule({"#{s}": opr}) }
          end
        end
      end

      def process_symbol *symbols
      	symbols.each do |symbol|
      		# check if negated symbol used?
      		if symbol.to_s.downcase =~ /\Anot_/ and not @entities.include?(symbol)
      			# remove the not symbol
      			not_symbol = (symbol.to_s.gsub /\Anot_/, "").to_sym
    				# add the negated symbol
      			whois(symbol, args: @entities[not_symbol][:args]) { |*args| not @entities[not_symbol][:callback].call(*args) }
      		end
      	end
      end

      def build_rule *_rules
        @rules[@_params.deep_dup] ||= {}
        _rules.each do |rule|
        	@rules[@_params.deep_dup] = @rules[@_params.clone].merge(rule);
        end
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