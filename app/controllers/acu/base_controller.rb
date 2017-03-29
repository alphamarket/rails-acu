module Acu
  class BaseController < ActionController::Base
    before_action { monitor }
    def index

    end
  end
end
