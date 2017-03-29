Acu::Rules.define do
  whois :everyone { true }
  whois :admin, args: [:current_user] { |c| c.user_type.symbol == :ADMIN.to_s }
  whois :client, args: [:current_user] { |c| c.user_type.symbol == :PUBLIC.to_s }

  controller :home do
    allow :everyone
  end
end
