require_relative 'errors'

module Acu

  class Monitor

    @kwargs = { }

    class << self

      protected :new
      attr_reader :kwargs

      def on kwargs
        @kwargs = kwargs
      end

      def gaurd
        _info = process Acu::Listeners.data[:request]
        rules = Rules.rules.select do |cond, _|
          flag = true;

          {namespace: nil, controller: :namespace, action: :controller}.each do |current, parent|
            if eval("_info.#{current}")
              t = false
              # either mentioned explicitly
              if cond[current]
                t |= cond[current][:name] == eval("_info.#{current}").to_sym
              # or in `only|except` tags
              elsif parent
                # if nothing mentioned in parent, assume for all
                t |= not(cond[parent][:only] and cond[parent][:except])
                # flag true if it checked in namespace's only tag
                t |= (cond[parent][:only] and cond[parent][:only].include? eval("_info.#{current}").to_sym)
                # flag false if it checked in namespace's except tag
                t &= not(cond[parent][:expect] and cond[parent][:except].include? eval("_info.#{current}").to_sym)
              end
              flag &= t;
            end
          end

          flag
        end
        # flag so we can process all the related rule and it all passed this should be false
        # if any failed, and exception will be raised
        _granted = false
        # for each mached rule
        rules.each do |_, rule|
          # for each entity and it's actions in the rule
          rule.each do |entity, action|
            # fetch the entity's identity
            e = Rules.entities[entity]
            # fetch the related args to the entity from the `kwargs`
            kwargs = @kwargs.reject { |x| !e[:args].include?(x) }
            # if fetched args and pre-defined arg didn't match?
            raise Acu::MissingData.new("at least one of arguments for `whois :#{entity}` in `#{_info.to_s}` is not provided!") if kwargs.length != e[:args].length
            # check it the current request can relay to the entity?
            # send varibles in order the have defined
            if e[:callback].call(*e[:args].map { |i| kwargs[i] })
              case action
              when :allow
                access_granted _info, entity
                _granted = true;
              when :deny
                access_denied  _info, entity
              else
                Config.audit_log "> access DENIED to undefined entity as `:#{entity}` to `#{_info.to_s}`"
                raise Exception.new("action `#{action}` for access `#{_info.to_s}` undefined!")
              end
            end
          end
        end
        # if the access is granted? i.e if all the rules are satisfied with the request
        return if _granted
        # if we reached here it measn that have found no rule to deny/allow the request and we have to fallback to the defaults
        access_granted _info, :__ACU_BY_DEFAULT__ and return if Config.get :default, :allow?
        access_denied  _info, :__ACU_BY_DEFAULT__
      end

      protected

      def access_granted _info, entity
        Config.audit_log "[-] access GRANTED to `#{_info.to_s}` as `:#{entity}`"
      end

      def access_denied _info, entity
        Config.audit_log "[x] access DENIED to `#{_info.to_s}` as `:#{entity}`"
        raise AccessDenied.new("you don't have the enough access for process this request!")
      end

      def process request
        raise InvalidData.new("the request object needs to provided!") if not(request and request[:parameters])
        p = request[:parameters]
        nc = p["controller"].split('/');
        n = nc.length > 1 ? nc.first : nil
        c = nc.length > 1 ? nc.second : nc.first
        a = p["action"]
        Struct.new(:namespace, :controller, :action).new(n, c, a)
      end

    end # /class << self
  end # /class Monitor

end # /module Acu