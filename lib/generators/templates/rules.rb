# This is an examble, modify it as well
Acu::Rules.define do
  # anyone makes a request could be count as everyone!
  whois :everyone { true }

  # whois :admin, args: [:user] { |c| c and c.user_type.symbol == :ADMIN.to_s }
  # whois :client, args: [:user] { |c| c and c.user_type.symbol == :PUBLIC.to_s }

  # admin can access anywhere
  # allow :admin

  # # the default namespace
  # namespace do  
  #   # assume anyone can access, your default namespace
  #   allow :everyone
  #
  #   controller :home, :shop do
  #     allow :admin, :client, on: [:some_secret_action1, :some_secret_action2]
  #     # OR
  #     # action :some_secret_action1, :some_secret_action2 do
  #     #  allow :admin, :client
  #     # end
  #   end
  # end

  # # allow every get access to public controller in 3 [default(the `nil`), admin, emplyee]
  # namespace nil, :admin, :emplyee do
  #   controller :public do
  #     allow :everyone
  #   end
  # end

  # # the admin namespace
  # namespace :admin do

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