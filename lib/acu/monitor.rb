require_relative './errors'

module Acu

  class << self

    def monitor request, **kwargs
      _info = prepare request
      rules = Rules.rules.select do |cond, _|
        # if the controller
        flag = true; #Struct.new(:n, :c, :a, :t).new(not _info.namespace, false, false, false)

        {namespace: [:n, nil], controller: [:c, :namespace], action: [:a, :controller]}.each do |current, parent|
          if eval("_info.#{current}")
            t = false
            # either mentioned explicitly
            if cond[current]
              t |= cond[current][:name] == eval("_info.#{current}").to_sym
            # or in `only|except` tags
            elsif parent[1]
              # if nothing mentioned in parent, assume for all
              t |= not(cond[parent[1]][:only] and cond[parent[1]][:except])
              # flag true if it checked in namespace's only tag
              t |= (cond[parent[1]][:only] and cond[parent[1]][:only].include? eval("_info.#{current}").to_sym)
              # flag false if it checked in namespace's except tag
              t &= not(cond[parent[1]][:expect] and cond[parent[1]][:except].include? eval("_info.#{current}").to_sym)
            end
            flag &= t;
          end
        end
        flag
      end
      # for each mached rule
      rules.each do |_, rule|
        # for each entity and it's actions in the rule
        rule.each do |entity, action|
          # fetch the entity's identity
          e = Rules.entities[entity]
          # fetch the related args to the entity from the `kwargs`
          args = kwargs.reject { |x| !e[:args].include?(x) }
          # if fetched args and pre-defined arg didn't match?
          raise Exception.new("at least one of arguments for `whois :#{entity}` in `#{_info.to_s}` is not provided!") if args.length != e[:args].length
          # check it the current request can relay to the entity?
          if e[:callback].call(**args)
            case action
            when :allow:
              Config.audit_log "[-] access GRANTED to `#{_info.to_s}` as `:#{entity}`"
              return
            when :deny:
              Config.audit_log "[x] access DENIED to `#{_info.to_s}` as `:#{entity}`"
              raise AccessDenied.new("you don't have the enough access for process this request!")
            else
              Config.audit_log "> access DENIED to undefined entity as `:#{entity}` to `#{_info.to_s}`"
              raise Exception.new("action `#{action}` for access `#{_info.to_s}` undefined!")
            end
          end
        end
      end
      # if we reached here it measn that we
    end

    def prepare request
      raise InvalidData.new("the request object needs to provided!") if not request and request.parameters
      p = request.parameters
      nc = p[:controller].split('/');
      n = nc.length > 1 ? nc.first : nil
      c = nc.length > 1 ? nc.second : nc.first
      a = p[:action]
      Struct.new(:namespace, :controller, :action).new(n, c, a)
    end
  end
end