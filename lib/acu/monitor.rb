require_relative 'errors'

module Acu

  class Monitor

    @kwargs = { }

    class << self

      protected :new
      attr_reader :kwargs

      def by kwargs
        @kwargs = @kwargs.merge(kwargs)
      end

      def clear_args
        @kwargs = { }
      end

      def gaurd
        # fetch the request & process it
        _info = process Acu::Listeners.data[:request]

        # return if we hit the cache
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
              # current entity is granted to have the access?
              if is_allowed? action
                # grant the access if already not denied
                _granted = 1 if _granted == -1
              else
                # deny it, period!
                _granted = 0
              end
            end
          end
        end
        # if the access is granted? i.e if all the rules are satisfied with the request
        return if _granted == 1 and access_granted _info, _entitled_entities
        # if the access is denied? i.e at least one of rules are NOT satisfied with the request
        return if _granted == 0 and access_denied  _info, _entitled_entities
        # if we reached here it measn that have found no rule to deny/allow the request and we have to fallback to the defaults
        access_denied  _info, [:__ACU_BY_DEFAULT__], by_default: true if not Configs.get :allow_by_default
        access_granted _info, [:__ACU_BY_DEFAULT__], by_default: true
      end

      def valid_for? entity
        # check for existance
        raise Errors::MissingEntity.new("whois :#{entity}?") if not Rules.entities[entity]
        # fetch the entity's identity
        e = Rules.entities[entity]
        # fetch the related args to the entity from the `kwargs`
        kwargs = @kwargs.reject { |x| !e[:args].include?(x) }
        # if fetched args and pre-defined arg didn't match?
        raise Errors::MissingData.new("at least one of arguments for `whois :#{entity}` is not provided!") if kwargs.length != e[:args].length
        # send varibles in order the have defined
        e[:callback].call(*e[:args].map { |i| kwargs[i] })
      end

      def clear_cache
        return if not Configs.get :use_cache
        Rails.cache.clear namespace: (Configs.get :cache_namespace)
      end

      protected

      def hit_cache _info
        # return [didn't hit] if not allowed to use cache
        return false if not Configs.get :use_cache
        # fetch the relative entities to this request
        _entitled_entities = Rules.entities.select { |name, _| valid_for? name }
        # fetch the cache-name
        cname = cache_name _info, _entitled_entities
        # return [didn't hit] if not found in cache
        return false if not Rails.cache.exist? cname, cache_options
        # check if the request is allowed in cache?
        if is_allowed?(Rails.cache.read(cname, cache_options).to_s.to_sym)
          # grant the access
          access_granted _info, _entitled_entities.keys, from_cache: true
        else
          # deny the access
          access_denied _info, _entitled_entities.keys, from_cache: true
        end
        # hit the cache
        return true
      end

      def cache_name _info, entities
        "%s-%s" %[_info.to_a.join('::'), (entities.kind_of?(Array) ? entities : entities.keys).join("-")]
      end

      def is_allowed? action
        case action
        when Rules.GRANT_SYMBOL
          return true
        when Rules.DENY_SYMBOL
          return false
        else
          log_audit "> access DENIED to undefined action as `:#{action}`"
          raise Exception.new("action `#{action}` is undefined!")
        end
      end

      def cache_options
        out = { }
        # fetch cache options from config
        [:namespace, :expires_in, :race_condition_ttl].each { |k| out[k] = Configs.get "cache_#{k}".to_sym }
        return out
      end

      def log_audit log
        # fetch the log file from configuration
        file = Configs.get :audit_log_file
        # log if allowed?
        Logger.new(Configs.get :audit_log_file).info(log) if file and not file.blank?
      end

      def access_granted _info, entities, by_default: false, from_cache: false
        # log the event
        log_audit ("[-]" + (from_cache ? '[c]' : '') + " access GRANTED to `#{_info}` as `:#{entities.uniq.join(", :")}`" + (by_default ? " [autherized by :allow_by_default]" : ""))
        # cache the event if not already from cache
        Rails.cache.write(cache_name(_info, entities), Rules.GRANT_SYMBOL, cache_options) if not from_cache and Configs.get :use_cache
        # grant the access
        true
      end

      def access_denied _info, entities, by_default: false, from_cache: false
        # log the event
        log_audit ("[x]" + (from_cache ? '[c]' : '') + " access DENIED to `#{_info}` as `:#{entities.uniq.join(", :")}`" + (by_default ? " [autherized by :allow_by_default]" : ""))
        # cache the event if not already from cache
        Rails.cache.write(cache_name(_info, entities), Rules.DENY_SYMBOL, cache_options) if not from_cache and Configs.get :use_cache
        # deny the access
        raise Errors::AccessDenied.new("you don't have the enough access for process this request!")
      end

      def process request
        # validate the request parameters
        raise Errors::InvalidData.new("the request object needs to provided!") if not(request and request[:parameters])
        # fetch the params
        p = request[:parameters]
        # try find the namespace/controller set
        nc = p["controller"].split('/');

        n = nc.length > 1 ? nc.first : nil
        c = nc.length > 1 ? nc.second : nc.first
        a = p["action"]

        # return it with structure
        Struct.new(:namespace, :controller, :action).new(n, c, a)
      end

    end # /class << self
  end # /class Monitor

end # /module Acu