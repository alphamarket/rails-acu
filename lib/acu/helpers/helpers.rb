def acu_is? symbol
  flag = false
  [symbol].flatten.each { |s| flag |= Acu::Monitor.valid_for? s }
  flag
end

def acu_as symbol
  yield if acu_is? symbol
end

def acu_except symbol
  yield if not acu_is? symbol
end