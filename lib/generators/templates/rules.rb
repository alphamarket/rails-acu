# This is an examble, modify it as well
Acu::Rules.define do
  # anyone make a request could be count as everyone!
  whois :everyone { true }

  # assume anyone can access
  # this has security leak of overrideing the `allow_by_default` config
  # allow :everyone

  # define who is admin?
  # whois :admin, args: [:user] { |c| c and c.user_type  == :ADMIN.to_s }

  # define who is client?
  # whois :client, args: [:user] { |c| c and c.user_type == :CLIENT.to_s }

  # default namespace, it is good practice for being clear
  # namespace do
  #   controller :home, except: [:some_secret_action] do
  #     allow :everyone
  #   end
  # end

  # controller :contact, only: [:send_message] do
  #   action :send do
  #     allow :everyone
  #   end
  #   action :view { allow [:admin, :client] }
  #   allow [:admin], on: [:approval]
  # end

  # namespace :admin do
  #   controller :post do
  #     allow :admin
  #     allow :client, on: [:show, :comment]
  #   end
  # end
end