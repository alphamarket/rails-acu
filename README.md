[![Build Status](https://travis-ci.org/noise2/rails-acu.svg?branch=master)](https://travis-ci.org/noise2/rails-acu)

# ACU
ACU is acronym for **A**ccess **C**ontrol **U**nit, and designed to give the rails application 100% control over permisions on multiple levels of app's structure.
The software enginering of this gem is tent to make it fast and simple. All you have to do is to define the **entities** of your authentications (i.e what is who?)
and write the rules for them based on `allow`/`deny` one-zero logic, everything else will be automatic.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'rails-acu'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install rails-acu
```

Then install it in you app using:

```bash
rails generate acu:install
```

## Usage
After installing it using `rails generate acu:install`  two files will be created:

```bash
create  config/initializers/acu_setup.rb
create  config/initializers/acu_rules.rb
```
The file `acu_setup.rb` is the configuration of ACU gem, you can leave it alone and use the default configuration or customise it as desired,
we will talk about the configuration later.

The other hand the `acu_rules.rb` is were you put your access rules there, access rules are binary, _either an entity can access a reource or not_ -
in this gem resource means any of `namespace`, `controller` and `action`. here as an example `acu_rules.rb` and we explain its components in the following:

```ruby
# config/initializers/acu_rules.rb
Acu::Rules.define do
  # anyone make a request could be count as everyone!
  whois :everyone { true }

  whois :admin, args: [:user] { |c| c and c.user_type == :ADMIN.to_s }

  whois :client, args: [:user] { |c| c and c.user_type == :CLIENT.to_s }

  # the default namespace
  namespace do
    controller :home, except: [:some_secret_action] do
      allow :everyone
    end
    controller :home do
      allow [:admin, :client], on: [:some_secret_action]
    end
  end

  # the admin namespace
  namespace :admin do
    allow :admin

    controller :contact, only: [:send_message] do
      allow :everyone
    end

    controller :contact do
      action :support {
        allow :client
      }
    end
  end
end
```

As we define our rules at the first line, we have to say who are the entities? _to whom we call who?_ for this purpose I have come up with a simple entity definition `whois`, it takes three arguments (1 of them is optional: `args`), first the label of the entity, in this example they are `:everyone, :admin` and `:client`, the second argument (which is optional) is the varibles that are going to be used to determining if the current request has been intiate from the entity or not, an the final argument is a block which its job is determine who is the defined entity!

Once we defined our entities we can set their binary access permisions at namespace/controller/action levels using `allow` and `deny` helpers. **that is it, we done tutorialing; from now on is just tiny details. :)**


> **Senaio:** We have *public* site which serves to its client's; we have 2 namespace in this site, one is the _default_ namespace with _home_ controller in it, and the second namespace belongs to the _admin_ of site which has many controllers and also a _contact_ controller.<br />
We want to grant access to everyone for all of _home_ controller actions in _default_ namespace **except** the `some_secret_action`; but this `some_secret_action` can be accessed via the `:admin` and `:client` entities.<br />
By default only `:admin` can access to the _admin_ namespace, but we made an exception for 2 actions in the `Admin::ContactController` which everyone can `send_message` to the admin and only clients can ask for `support`.<br />
If you back trace it in the above example you can easliy find this senario in the rules, plain and simple.


## Contributing
In order contributing to this project:
1. Fork
2. Make changes/upgrades/fixes etc
3. Write a through tests
4. Make a pull request to the `develop` branch

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
