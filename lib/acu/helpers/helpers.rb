def acu_is? symbol
  flag = false
  [symbol].flatten.each { |s| flag |= Acu::Monitor.valide_for? s }
  flag
end

def acu_as symbol
  yield if acu_is? symbol
end