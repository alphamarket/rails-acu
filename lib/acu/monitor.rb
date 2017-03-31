require_relative 'errors'

module Acu

  class Monitor

    @kwargs = { }

    class << self

      protected :new
      attr_reader :kwargs

      def by kwargs
        @kwargs = kwargs
      end

      def gaurd
        # fetch the request & process it
        _info = process Acu::Listeners.data[:request]

        return if hit_cache _info

        rules = Rules.rules.select do |cond, _|
          flag = true;

          # check if this is a global rule!
          next true if cond.empty?

          {namespace: nil, controller: :namespace, action: :controller}.each do |current, parent|
            t = -1
            # either mentioned explicitly
            if cond[current]
              t = (cond[current][:name].to_s == eval("_info.#{current}").to_s) ? 1 : 0
            # or in `only|except` tags
            elsif parent and cond[parent]
              # if nothing mentioned in parent, assume for all
              t = 1 if not(cond[parent][:only] or cond[parent][:except])
              # flag true if it checked in namespace's only tag
              {only: {on_true: 1, on_false: 0} , except: {on_true: 0, on_false: 1}}.each do |tag, val|
                if cond[parent][tag]
                  case cond[parent][tag].include? eval("_info.#{current}").to_sym
                  when true
                    t = val[:on_true]
                    break
                  when false
                    t = val[:on_false]
                  end
                end
              end
            end
            flag &= (t == 1) if t.between? 0, 1;
            break if not flag
          end
          flag
        end
        # flag so we can process all the related rule and it all passed this should be false
        # if any failed, and exception will be raised
        _granted = -1
        _entitled_entities = [];
        # for each mached rule
        rules.each do |_, rule|
          # for each entity and it's actions in the rule
          rule.each do |entity, action|
            # check it the current request can relay to the entity?
            if valid_for? entity
              _entitled_entities << entity.to_s

              if is_allowed? action
                _granted = 1 if _granted == -1
              else
                _granted = 0
              end
            end
          end
        end
        # if the access is granted? i.e if all the rules are satisfied with the request
        return if _granted == 1 and access_granted _info, _entitled_entities.uniq.join(", :")
        return if _granted == 0 and access_denied  _info, _entitled_entities.uniq.join(", :")
        # if we reached here it measn that have found no rule to deny/allow the request and we have to fallback to the defaults
        access_denied  _info, :__ACU_BY_DEFAULT__, by_default: true if not Configs.get :allow_by_default
        access_granted _info, :__ACU_BY_DEFAULT__, by_default: true
      end

      def valid_for? entity
        # check for existance
        raise Errors::MissingEntity.new("whois :#{entity}?") if not Rules.entities[entity]
        # fetch the entity's identity
        e = Rules.entities[entity]
        # fetch the related args to the entity from the `kwargs`
        kwargs = @kwargs.reject { |x| !e[:args].include?(x) }
        # if fetched args and pre-defined arg didn't match?
        raise Errors::MissingData.new("at least one of arguments for `whois :#{entity}` in `#{_info.to_s}` is not provided!") if kwargs.length != e[:args].length
        # send varibles in order the have defined
        e[:callback].call(*e[:args].map { |i| kwargs[i] })
      end

      protected

      def hit_cache _info
        cname = cache_name _info, Rules.entities.select { |name, _| valid_for? name }
        false
      end

      def cache_name _info, entities
        "acu-" + _info.to_a.join('::') + '-' + entities.keys.join("-")
      end

      def is_allowed? action
        case action
        when :allow
          return true
        when :deny
          return false
        else
          log_audit "> access DENIED to undefined entity as `:#{entity}` to `#{_info.to_s}`"
          raise Exception.new("action `#{action}` for access `#{_info.to_s}` undefined!")
        end
      end

      def log_audit log
        file = Configs.get :audit_log_file
        Logger.new(Configs.get :audit_log_file).info(log) if file and not file.blank?
      end

      def access_granted _info, entity, by_default: false
        log_audit ("[-] access GRANTED to `#{_info.to_s}` as `:#{entity}`" + (by_default ? " [autherized by :allow_by_default]" : ""))
        true
      end

      def access_denied _info, entity, by_default: false
        log_audit ("[x] access DENIED to `#{_info.to_s}` as `:#{entity}`" + (by_default ? " [autherized by :allow_by_default]" : ""))
        raise Errors::AccessDenied.new("you don't have the enough access for process this request!")
      end

      def process request
        raise Errors::InvalidData.new("the request object needs to provided!") if not(request and request[:parameters])
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