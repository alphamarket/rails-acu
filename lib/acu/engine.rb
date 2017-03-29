module Acu
  class Engine < ::Rails::Engine
    isolate_namespace Acu

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
