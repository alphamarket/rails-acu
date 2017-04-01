require 'rails_helper'

RSpec.describe Admin::ManageController, type: :controller do

  before(:each) {
    # reset rules
    Acu::Rules.reset
    # reset configs
    Acu.setup do |config|
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
  it '[local-global & args]' do
    Acu::Rules.define do
      whois :admin, args: [:c] { |c| c == :admin }
      whois :client, args: [:c] { |c| c == :client }
      namespace :admin do
        allow :admin
        controller :manage, only: [:show] do
          allow :client
        end
      end
    end
    Acu::Monitor.args c: :admin
    get :index
    expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:admin`/
    Acu::Monitor.args c: :client
    expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
    expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/

    [:client, :admin].each do |cc|
      Acu::Monitor.args c: cc
      get :show
    end
  end
end
