module Acu
  class ApplicationController < ::ApplicationController
    before_action { monitor }
  end
end
