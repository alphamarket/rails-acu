# This is an examble, modify it as well
Acu::Rules.define do
  # anyone make a request could be count as everyone!
  whois :everyone { true }

  # whois :admin, args: [:user] { |c| c and c.user_type.symbol == :ADMIN.to_s }
  # whois :client, args: [:user] { |c| c and c.user_type.symbol == :PUBLIC.to_s }

  # assume anyone can access
  # this has security leak of overrideing the `allow_by_default` config
  # allow :everyone

  # the default namespace
  # namespace do
  #   controller :home do
  #     allow [:admin, :client], on: [:some_secret_action]
  #   end
  # end

  # the admin namespace
  # namespace :admin do
  #   allow :admin

  #   controller :contact, only: [:send_message] do
  #     allow :everyone
  #   end

  #   controller :contact do
  #     action :support {
  #       allow :client
  #     }
  #   end
  # end
end