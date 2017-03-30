require 'rails_helper'

RSpec.describe HomeController, type: :controller do

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
    context "[globals]" do
      it "[single rule]" do
        Acu::Rules.define do
          whois :everyone { true }
          allow :everyone
        end
        get :index
      end
      it "[multiple rules]" do
        Acu::Rules.define do
          whois :everyone { true }
          whois :client { true }
          allow :everyone
          allow :client
        end
        expect(Acu::Rules.rules.length).to be 1
        expect(Acu::Rules.rules[{}].length).to be 2
        get :index
        expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone, :client`/
      end
      it "{ one of rules failed = AccessDenied }" do
        Acu::Rules.define do
          whois :everyone { true }
          whois :client { true }
          # every request is :everyone
          allow :everyone
          # every reqyest is also :client
          deny :client
        end
        expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
        expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:client`/

        Acu::Rules.define do
          whois :client { false }
          # every reqyest is also :client
          deny :client
        end
        get :index
        expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/
      end
    end
    context "[levels]" do
      context "[namespace]" do
        it "[default]" do
          Acu::Rules.define do
            whois :everyone { true }
            whois :client { false }
            namespace do
              allow :everyone
            end
          end
          get :index
          Acu::Rules.define do
            namespace do
              deny :everyone
            end
          end
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
          Acu::Rules.define do
            namespace do
              allow :everyone
            end
            namespace :FooBar do
              deny :everyone
            end
          end
          get :index
        end
        it "[default & global]" do
          Acu::Rules.define do
            whois :everyone { true }
            whois :client { false }

            namespace do
              allow :everyone
            end

            deny :everyone
          end
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
        end
      end

      context "[controller]" do
        it "[solo]" do
          Acu::Rules.define do
            whois :everyone { true }
            controller :home do
            end
          end
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)

          Acu::Rules.define do
            controller :home do
              allow :everyone
            end
          end
          get :index
        end
        it "[with actions]" do
          Acu::Rules.define do
            whois :everyone { true }
            controller :home do
            end
          end
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/

          Acu::Rules.define do
            controller :home do
              action :contact { allow :everyone }
            end
          end
          get :contact
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/

          Acu::Rules.define do
            controller :home do
              action :index { allow :everyone }
              action :contact { deny :everyone }
            end
          end
          get :index
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
        end
        it "[with only]" do
          Acu::Rules.define do
            whois :everyone { true }
            controller :home, only: [:contact] do
            end
          end
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="contact".*\[autherized by :allow_by_default\]/

          Acu::Rules.define do
            controller :home, only: [:contact] do
              allow :everyone
            end
          end
          get :contact
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/

          # the rules won't override with above, this will give us the needed flexibility for multi-dimentional rules
          Acu::Rules.define do
            controller :home, only: [:index] do
              allow :everyone
            end
          end
          get :index
          get :contact
          Acu::Rules.define do
            controller :home, only: [:index] do
              deny :everyone
            end
          end
          get :contact
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
        end
        it "[with except]" do
          Acu::Rules.define do
            whois :everyone { true }
            controller :home, except: [:contact] do
            end
          end
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)

          Acu::Rules.define do
            controller :home, except: [:contact] do
              allow :everyone
            end
          end
          get :index
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)

          # this will override the previous excepts
          Acu::Rules.define do
            controller :home, only: [:index] do
              deny :everyone
            end
          end
          # we have rule for this
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
          # and this is by detailt
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="contact".*\[autherized by :allow_by_default\]/
        end
      end


    end
  end
end
