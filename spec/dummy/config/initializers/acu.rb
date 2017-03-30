Acu::Rules.define do
  whois :everyone { true }
  whois :admin, args: [:user] { |c| c and c.user_type.symbol == :ADMIN.to_s }
  whois :client, args: [:user] { |c| c and c.user_type.symbol == :PUBLIC.to_s }

  controller :home do
    allow :admin
  end
end
