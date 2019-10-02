[![Build Status](https://travis-ci.org/alphamarket/rails-acu.svg?branch=rails-5)](https://travis-ci.org/alphamarket/rails-acu)

# ACU
ACU is the acronym for **A**ccess **C**ontrol **U**nit, and it's designed to give the 100% control over permissions on multiple levels of rails application's structure.
The software engineering of this gem tends to make it much faster and simple. All you have to do is to define the **entities** of your authentications (i.e `what is who?`)
and write the rules for them based on `allow`/`deny` binary logic, and everything else will be done automatically.

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
$ rails generate acu:install
```

## Usage
After installation using `rails generate acu:install`  two files will be created:

```bash
create  config/initializers/acu_setup.rb
create  config/initializers/acu_rules.rb
```
The file `acu_setup.rb` is the configuration of ACU gem, you can leave it alone and use the default configurations or customize it as desired,
we will talk about the configuration later.

The other hand the `acu_rules.rb` is where you put your access rules there, access rules are binary, _either an entity can access a resource or not_ -
in this gem, resource means any of `namespace`, `controller` and `action`. here as an example `acu_rules.rb` and we explain its components in the following:

```ruby
# config/initializers/acu_rules.rb
Acu::Rules.define do
  # anyone makes a request could be count as everyone!
  whois :everyone { true }

  whois :admin, args: [:user] { |c| c and c.user_type == :ADMIN.to_s }

  whois :client, args: [:user] { |c| c and c.user_type == :PUBLIC.to_s }

  # admin can access to everywhere
  allow :admin

  # the default namespace
  namespace do  
    # assume anyone can access, your default namespace
    allow :everyone
    controller :home, :shop do
      allow :admin, :client, on: [:some_secret_action1, :some_secret_action2]
      # OR
      # action :some_secret_action1, :some_secret_action2 do
      #  allow :admin, :client
      # end
    end
  end

  # allow every get access to public controller in 3 [default(the `nil`), admin]
  namespace nil, :admin do
    controller :public do
      allow :everyone
    end
  end

  # the admin namespace
  namespace :admin do

    controller :contact, only: [:send_message] do
      allow :everyone
    end

    controller :contact do
      action :support {
        allow :client
      }
    end
  end

  # nested namespace (since v3.0.0)
  namespace :admin do 
    namespace :chat do
      allow :client
    end
  end

  # negated entities (since v3.0.4)
  namespace do
    controller :profile do
      # only owners can edit the profile page
      deny :not_owner, on: [:edit]
    end
  end
end
```

As we define our rules at the first line, we have to say who are the entities? _to whom we call who?_ for this purpose I have come up with a simple entity definition `whois`, it takes three arguments (1 of them is optional: `args`), first the label of the entity, in this example they are `:everyone, :admin` and `:client`, the second argument (which is optional) is the variables that are going to be used to determining if the current request has been initiated by the entity or not, and the final argument is a block which its job is to determine who is the defined entity!

Once we defined our entities we can set their binary access permissions at namespace/controller/action levels using `allow` and `deny` helpers. **that is it, we are done tutorialing; from now on is just tiny details. :)**

> **Scenario:** We have a *public* site which serves to its client's; we have 2 namespaces on this site, one is the _default_ namespace with _home_ controller in it, and the second namespace belongs to the _admin_ of site which has many controllers and also a _contact_ controller.<br />
We want to grant access to everyone for all of _home_ controller actions in _default_ namespace **except** the `some_secret_action1` and `some_secret_action2`; but these `some_secret_action*` can be accessed via the `:admin` and `:client` entities. By default only `:admin` can access to everywhere, but in namespace `admin` we made an exception for 2 actions in the `Admin::ContactController` which everyone can `send_message` to the admin and only clients can ask for `support`. Finally we want to grant access to everyone for _public_ controllers in our 2 namespaces _the default_ and _admin_. Also clients can access to everything in namespace _chat_.<br />
If you back trace it in the above example you can easily find this scenario in the rules, plain and simple.

### Gaurding the requests
For gaurding you application using ACU, you to need to call it in `before_action` callbacks (preferably in you **base controller**). And also occasionally there is some situation that you need to pass the some argument in the entities to be able to determine the entity (i.e you cannot get it from `session`, `global variables/function` or directly from `database`) for such situations you can pass the arguments as you are calling `Acu::Monitor.gaurd` in your `before_action` as below:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action { Acu::Monitor.gaurd by: { user: some_way_to_fetch_it } }
end
```
The method `Acu::Monitor.gaurd` accepts a hashed list of agruments named `by`, please note that the keys should be identical to the entities' `args` argument.

### Some handy helpers
Although you can define a binary allow/deny access rule in the `acu_rules.rb` file but there will be some gray area that neither you can allow _full access_ to the resource nor _no access_.<br />
For those situations you allow the entities to get access but limits their operations in the action/view/layout with the `acu_is?`, `acu_as` and `acu_except` helpers, here is some usage example of them:

```ruby
# return true if the entity `:admin`'s block in `whois :admin` return true, otherwise false
acu_is? :admin
# returns true if any of the given entity's block return true; if none of the was valid, returns false.
acu_is? [:admin, :client]

# executes the block if current user identified as an admin by `whois :admin`
acu_as :admin do
  puts 'You are identified as an `admin`'
end
# executes the block if current user identified as either `:admin` or `:client`
acu_as [:admin, :client] do
  puts 'You are either `admin` or `client`'
end

# DO NOT execute the block if current user identified as `:guest`
acu_except [:guest] do 
  puts 'Except `:guest`s anyone else can execute this code'
end
```

### Configurations
One of the files that `acu:install` command will generate is `acu_setup.rb` which contains the configuration for the gem, the default configurations are as following:

```ruby
Acu.setup do |config|
  # to tighten the security this is enabled by default
  # i.e if it checked to be true, then if a request didn't match to any of rules, it will get passed through
  # otherwise the requests which don't fit into any of rules, the request is denied by default
  config.allow_by_default = false

  # the audit log file, to log how the requests handles, good for production
  # leave it black for nil to disable the logging
  config.audit_log_file   = ""

  # cache the rules to make rule matching much faster
  # it's not recommended to use it in developement/test evn.
  config.use_cache = false

  # the caching namespace
  config.cache_namespace = 'acu'

  # define the expiration of cached entries
  config.cache_expires_in = nil

  # the race condition ttl
  config.cache_race_condition_ttl = nil

  # more details about cache options:
  # http://guides.rubyonrails.org/caching_with_rails.html
end
```

Here are the details of the configurations:

| Name | Default | Description |
| ----- |-------| ------ |
| allow_by_default | `false` | Set it `true` if you want to grant access to requests that doesn't fit to any rules you have defined (**Warning:** please be advised, setting it `true` may cause a security hole in your website if you don't cover the rules perfectly!). |
| audit_log_file |  | The audit log file, useful for rules debugging! |
| use_cache | `false` | ACU can utilize the `Rails.cache` to make the rules matching much faster by caching them, but if caching is enabled and you change the please make user you have cleared the ACU caches by `Acu::Monitor.clear_cache`. |
| cache_* | 'acu' or `nil` | See rails [caching options](http://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-store) for details. |

### API
Here are the list of APIs that didn't mentioned above:

| API | Arguments | Alias | Description |
| ----- | :-------: | :------: | ---- |
| `Acu::Configs.get` | `name` | N/A | Get the value of the `name`ed config |
| `Acu::Monitor.args` | `kwargs` | N/A | Set the arguments demaned by blocks in `whois` |
| `Acu::Monitor.clear_cache` | None | N/A | Clears the ACU's rule matching cache |
| `Acu::Monitor.clear_args` | None | N/A | Clears the argument set by `Acu::Monitor.args` and `Acu::Monitor.gaurd` |
| `Acu::Monitor.valid_for?` | `entity` | `acu_is?` | Check if the current request is come from the entity or not |
| `Acu::Monitor.gaurd` | `by` | N/A | Validates the current request, considering the arguments demaned by blocks in `whois` |
| `Acu::Rules.define` | `&block` | N/A | Get a block of rules, **Note** that there could be mutliple `Acu::Rules.define` in your project, the rules will all merge together as a one, so you can have mutliple `acu_rule*.rb` file in your `config/initialize` and they will merge together |
| `Acu::Rules.reset` | None | N/A | Resets everything in the `Acu::Rules` |
| `Acu::Rule.lock` | None | N/A | Freezes the rules, you can set it at the _end of the last_ `acu_rule*.rb` file. |


### Exceptions
Here are the list of exceptions defined in ACU gem:

```ruby
class Acu::Errors::AccessDenied < StandardError

class Acu::Errors::UncheckedPermissions < StandardError

class Acu::Errors::InvalidSyntax < StandardError

class Acu::Errors::AmbiguousRule < StandardError

class Acu::Errors::InvalidData < StandardError

class Acu::Errors::MissingData < InvalidData

class Acu::Errors::MissingEntity < MissingData

class Acu::Errors::MissingUser < MissingData

class Acu::Errors::MissingAction < MissingData

class Acu::Errors::MissingController < MissingData

class Acu::Errors::MissingNamespace < MissingData
```

## Known contributions subjects to work on 

### Implementing to overriding the rules in inner loops:
Consider we have to give the everyone to access the default namespace except `:profile` controller which will only allow by signed in users, although there are tools provided
for this purpose, such as `except` and `only` tags on `controller` and `namespace` but it would be nice if there are such a command like `override` which its skeleton has been
defined in the `Acu::Rules.override` which enables the previously defined rule to be overrided, the following pseudo-example removes the `allow :everyone` rule from the controller
`profile`:

```ruby
  # config/initializers/acu_rules.rb
  [...]
  namespace do
    allow :everyone
    controller :profiles do
      override :everyone
      allow :signed_in
    end
  end
  [...]
```

## Change Logs

### v3.0.0
* Nested namespace support

### Before `v3.0.0`
* Core functionalities implemented and stabilized


## Contributing
In order contributing to this project:
1. Fork
2. Make changes/upgrades/fixes etc
3. Write a through tests
4. Make a pull request to the `develop` branch

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).