require 'rails_helper'

RSpec.describe Admin::ManageController, type: :controller do

  before(:each) {
    # reset rules
    Acu::Rules.reset
    # reset configs
    Acu.setup do |config|
      config.base_controller  = :ApplicationController
      config.allow_by_default = false
      config.audit_log_file   = '/tmp/acu-rspec.log'
    end
  }

  it "should work with namespaces" do
    Acu::Rules.define do
      whois :everyone { true }
      allow :everyone
    end
    get :index

    Acu::Rules.define do
      namespace do
        controller :home do
          deny :everyone, on: [:index, :contact]
        end
      end
    end
    # we filtered the default namespace not this
    get :index
    expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/

    Acu::Rules.define do
      namespace :admin, except: [:posts] do
        deny :everyone, on: [:show, :list]
      end
      namespace :admin, only: [:manage] do
        deny :everyone, on: [:index]
      end
    end
    expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
    expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
    expect {get :show}.to raise_error(Acu::Errors::AccessDenied)
    expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="show".*as `:everyone`/
    expect {get :list}.to raise_error(Acu::Errors::AccessDenied)
    expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="list".*as `:everyone`/
  end
end
