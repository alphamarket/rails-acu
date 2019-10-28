def acu_is? *symbol, **args
  flag = false
  [symbol].flatten.each do |s|
  	if s.to_s =~ /\Anot_/
			flag |= not(Acu::Monitor.valid_for?(s.to_s.gsub(/\Anot_/, "").to_sym, args))
		else
			flag |= Acu::Monitor.valid_for? s, args
		end
  end
  flag
end

def acu_as *symbol, **args
  yield if acu_is? symbol, args
end

def acu_except *symbol, **args
  yield if not acu_is? symbol, args
end
