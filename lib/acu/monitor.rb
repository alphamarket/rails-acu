require_relative 'errors'

module Acu

  class Monitor

    @kwargs = { }

    class << self

      protected :new
      attr_reader :kwargs

      def args kwargs
        @kwargs = @kwargs.merge(kwargs)
      end

      def clear_args
        @kwargs = { }
      end

      def gaurd by: { }
        # assign the args in class scope
        args by

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
            if cond[current] and not cond[current].empty?
              # hierarchical match `_info[current]` with `cond[current]` to support nested namespace (since v3.0.0)
              cond[current].map { |c| c[:name].to_s }.each.with_index do |c, index|
                t = (c == eval("_info.#{current}")[index].to_s) ? 1 : 0
                break if t == 0
              end
            # or in `only|except` tags
            elsif parent and cond[parent] and not cond[parent].empty?
              # if nothing mentioned in parent, assume for all
              t = 1 if not cond[parent].map { |c| c[:only] or c[:except] }.all?
              # flag true if it checked in namespace's only tag
              {only: {on_true: 1, on_false: 0} , except: {on_true: 0, on_false: 1}}.each do |tag, val|
                # fetch all `tag` names
                tag_list = cond[parent].map { |c| c[tag] }.flatten - [nil]
                # if any tag is present?
                if not tag_list.empty? and tag_list.any?
                  # if `current` is mentioned in `tag_list`?
                  case not (tag_list.map(&:to_s) & eval("_info.#{current}").map(&:to_s)).empty?
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
                # cache the permision for the entity
                cache_access _info, _entitled_entities[-1], Rules.GRANT_SYMBOL
                # grant the access if already not denied
                _granted = 1 if _granted == -1
              else
                # cache the permision for the entity
                cache_access _info, _entitled_entities[-1], Rules.DENY_SYMBOL
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

      def valid_for? entity, **args
        # check for existance
        raise Errors::MissingEntity.new("whois(:#{entity})?") if not Rules.entities[entity]
        # fetch the entity's identity
        e = Rules.entities[entity]
        # set default argument set
        wargs = @kwargs
        # set externals if any argument is provided from outside?
        wargs = args unless args.blank?
        # fetch the related args to the entity from the `kwargs`
        kwargs = wargs.reject { |x| !e[:args].include?(x) }
        # if fetched args and pre-defined arg didn't match?
        raise Errors::MissingData.new("at least one of arguments for `whois(:#{entity})` is not provided!") if kwargs.length != e[:args].length
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
        # fetched cached data for current info
        cached_data = Rails.cache.read cache_name(_info), cache_options
        # return not hit if no cached data found
        return false if not cached_data
        # fetch the relative entities to this request
        _entitled_entities = Rules.entities.select { |name, _| valid_for? name }.keys.map(&:to_sym)
        # check if any of entities is among the should-denied ones?
        denied = cached_data[Rules.DENY_SYMBOL] & _entitled_entities
        # check if any of entities is among the should-grant ones?
        granted = cached_data[Rules.GRANT_SYMBOL] & _entitled_entities
        # check if we have any resons to deny the access?
        return true if not denied.empty? and access_denied _info, denied, from_cache: true
        # o.w. grant the access if any explicit rule
        return true if not granted.empty? and access_granted _info, granted, from_cache: true
        # if not granted nor denied by cache, discard the cache data & proceed
        return false
      end

      def cache_name _info, entities = []
        ("%s-%s" %[_info.to_a.join('::'), (entities.kind_of?(Array) ? entities : entities.keys).sort.join("-")]).gsub(/-+$/, "")
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

      def cache_access _info, entities, symbol
        if not Rails.cache.exist?(cache_name(_info), cache_options)
          Rails.cache.write(cache_name(_info), {
            Rules.DENY_SYMBOL => [],
            Rules.GRANT_SYMBOL => []
          }, cache_options)
        end
        cache_data = Rails.cache.read cache_name(_info), cache_options
        cache_data[symbol] += [entities].flatten.map(&:to_sym)
        cache_data[symbol] = cache_data[symbol].flatten.uniq
        Rails.cache.write cache_name(_info), cache_data, cache_options
      end

      def access_granted _info, entities, by_default: false, from_cache: false
        # log the event
        log_audit ("[-]" + (from_cache ? '[c]' : '') + " access GRANTED to `#{_info}` as `:#{entities.uniq.sort.join(", :")}`" + (by_default ? " [autherized by :allow_by_default]" : ""))
        # grant the access
        true
      end

      def access_denied _info, entities, by_default: false, from_cache: false
        # log the event
        log_audit ("[x]" + (from_cache ? '[c]' : '') + " access DENIED to `#{_info}` as `:#{entities.uniq.sort.join(", :")}`" + (by_default ? " [autherized by :allow_by_default]" : ""))
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
        # considering multi layer namespaces
        n = nc.length > 1 ? nc[0..-2] : nil
        c = nc.length > 1 ? nc.last : nc.first
        a = p["action"]

        # return it with structure
        Struct.new(:namespace, :controller, :action).new([n].flatten, [c].flatten, [a].flatten)
      end

    end # /class << self
  end # /class Monitor

end # /module Acu
