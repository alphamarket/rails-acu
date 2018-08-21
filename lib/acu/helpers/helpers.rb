def acu_is? *symbol
  flag = false
  [symbol].flatten.each do |s| 
  	if s.to_s =~ /\Anot_/
			flag |= not(Acu::Monitor.valid_for?(s.to_s.gsub(/\Anot_/, "").to_sym))
		else
			flag |= Acu::Monitor.valid_for? s 
		end
  end
  flag
end

def acu_as *symbol
  yield if acu_is? symbol
end

def acu_except *symbol
  yield if not acu_is? symbol
end