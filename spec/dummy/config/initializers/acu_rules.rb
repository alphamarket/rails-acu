# This is an examble, modify it as well
Acu::Rules.define do
  # anyone make a request could be count as everyone!
  whois :everyone { true }

  allow :everyone

  # define how is admin?
  # whois :admin, args: [:user] { |c| c and c.user_type  == :ADMIN.to_s }

  # define how is client?
  # whois :client, args: [:user] { |c| c and c.user_type == :CLIENT.to_s }

  # controller :home, except: [:some_secret_action] do
  #   allow :everyone
  # end

  # controller :admin, only: [:send_message] do
  #   allow :everyone
  # end

  # controller :admin, except: [:send_message] do
  #   allow :admin
  # end
end