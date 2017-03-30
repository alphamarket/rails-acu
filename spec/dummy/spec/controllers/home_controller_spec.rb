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
        it "[with only]" do
          Acu::Rules.define do
            whois :everyone { true }
            namespace only: [:home] do
              allow :everyone
            end
          end
          get :index
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/

          Acu::Rules.define do
            whois :everyone { true }
            # override previous one
            namespace only: [:home] do
              deny :everyone
            end
            namespace only: [:foobar] do
              allow :everyone
            end
          end
          # by override
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
        end
        it "[with except]" do
          Acu::Rules.define do
            whois :everyone { true }
            namespace except: [:home] do
              allow :everyone
            end
          end
          # by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to .* \[autherized by :allow_by_default\]/

          Acu::Rules.define do
            whois :everyone { true }
            namespace except: [:foobar] do
              allow :everyone
            end
          end
          get :index
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/
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

      context "[action]" do
        it "[parent: namespace]" do
          Acu::Rules.define do
            whois :everyone { true }
            namespace do
              action :index   { allow :everyone }
              action :contact { allow :everyone }
            end
          end
          get :index
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/
          get :contact
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="contact".*as `:everyone`/

          Acu::Rules.define do
            namespace do
              action :index   { allow :everyone }
              action :contact { deny :everyone }
            end
          end
          get :index
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="contact".*as `:everyone`/

        end

        it "[parent: controller]" do
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

        it "[parent: namespace, controller]" do
          Acu::Rules.define do
            whois :everyone { true }
            namespace do
              controller :home do
              end
            end
          end
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/

          Acu::Rules.define do
            namespace do
              controller :home do
                action :contact { allow :everyone }
              end
            end
          end
          get :contact
          # deny by default
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/

          Acu::Rules.define do
            namespace do
              controller :home do
                action :index { allow :everyone }
                action :contact { deny :everyone }
              end
            end
          end
          get :index
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)

          # reset to change namespace
          Acu::Rules.reset
          Acu::Rules.define do
            whois :everyone { true }
            namespace :foobar do
              controller :home do
                action :index { allow :everyone }
                action :contact { deny :everyone }
              end
            end
          end
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="contact".*\[autherized by :allow_by_default\]/
        end
      end

      context "[allow/deny]" do
        it "[allow]" do
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*\[autherized by :allow_by_default\]/
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="contact".*\[autherized by :allow_by_default\]/

          Acu::Rules.define do
            whois :everyone { true }
            namespace do
              controller :home do
                allow :everyone, on: [:index, :contact]
              end
            end
          end
          get :index
          get :contact
        end
        it "[deny]" do
          Acu::Rules.define do
            whois :everyone { true }
            allow :everyone
          end
          get :index
          get :contact

          Acu::Rules.define do
            whois :everyone { true }
            namespace do
              controller :home do
                deny :everyone, on: [:index, :contact]
              end
            end
          end
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
          expect {get :contact}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="contact".*as `:everyone`/
        end
        it "[bulk settings]" do
          Acu::Rules.define do
            whois :everyone { true }
            whois :client { false }
            namespace do
              controller :home do
                allow [:everyone, :client], on: [:index, :contact]
              end
            end
          end
          get :index
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone`/
          get :contact
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="contact".*as `:everyone`/
          Acu::Rules.define { whois :client { true } }
          get :index
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="index".*as `:everyone, :client`/
          get :contact
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="contact".*as `:everyone, :client`/
          Acu::Rules.define do
            namespace do
              controller :home do
                action :index { deny [:everyone, :client] }
              end
            end
          end
          expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
          # the first rule that failed is going to mention
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*action="index".*as `:everyone`/
          get :contact
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*action="contact".*as `:everyone, :client`/
        end
      end
    end
  end
  context "Acu::Helpers" do
    it "acu_is?" do
      Acu::Rules.define do
        whois :everyone { true }
        whois :client { false }
      end
      expect(acu_is? :everyone).to be true
      expect(acu_is? :client).to be false
    end
    it "acu_do" do
      Acu::Rules.define do
        whois :everyone { true }
        whois :client { false }
      end
      acu_as :everyone do
        # a valid syntax
        expect(false).not_to be true
      end
      acu_as :client do
        # an invalid syntax, this should never run
        expect(true).to be false
      end
      # the :everyone should get true
      acu_as [:client, :everyone] do
        expect(acu_is? :everyone).to be true
      end
    end
  end
end
