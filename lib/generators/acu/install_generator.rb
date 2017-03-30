require 'rails/generators/base'

module Acu
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates an Acu initializer and copy locale files to your application."

      def copy_setup
        template 'setup.rb', "config/initializers/acu_setup.rb"
      end

      def copy_rule
        template 'rules.rb', "config/initializers/acu_rules.rb"
      end

    end
  end
end