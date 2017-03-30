require 'rails_helper'

RSpec.describe HomeController, type: :controller do

  before(:each) {
    # reset rules
    Acu::Rules.reset
    # reset configs
    Acu.setup do |config|
      config.base_controller  = :ApplicationController
      config.allow_by_default = false
      config.audit_log_file   = ""
    end
  }

  def setup **kwargs
    kwargs.each do |k, v|
      Acu.setup { |c| eval("c.#{k} = #{v}") }
    end
  end

  context 'Acu::Config' do
    it '.base_controller' do
      setup base_controller: ":FooBarController"
      expect {get :index}.to raise_error(NameError)
    end

    it '.allow_by_default = false' do
      expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
    end

    it '.allow_by_default = true' do
      begin
        setup allow_by_default: true
        get :index
      rescue Acu::Errors::AccessDenied
        fail "didn't expect to get Acu::Errors::AccessDenied, but got one!"
      end
    end
    it '.audit_log_file' do
      setup audit_log_file: "'/tmp/acu-rspec.log'"
      expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
      expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to .* \[autherized by :allow_by_default\]/
      setup allow_by_default: true
      get :index
      expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to .* \[autherized by :allow_by_default\]/
    end
  end

  context "Acu::Rules" do
    it "+ global rules" do
      Acu::Rules.define do
        whois :everyone { true }
        allow :everyone
      end
      begin
        get :index
      rescue Acu::Errors::AccessDenied
        fail "didn't expect to get Acu::Errors::AccessDenied, but got one!"
      end
    end
  end
end
