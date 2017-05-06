require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe Admin::Booking::ListsController, type: :controller do

  before(:each) {
    # reset rules
    Acu::Rules.reset
    # reset configs
    Acu.setup do |config|
      config.allow_by_default = false
      config.audit_log_file   = '/tmp/acu-rspec.log'
    end

    Acu::Rules.define do
      whois :admin, args: [:c] { |c| c == :admin }
      whois :client, args: [:c] { |c| c == :client }
    end
  }

  def as e, &block
    Acu::Monitor.args c: e
    block.call()
    Acu::Monitor.args c: nil
  end

  def as_admin &block
    as :admin, &block
  end

  def as_client &block
    as :client, &block
  end

  it "should work with top-level namespace rules" do
    Acu::Rules.define do
      namespace :admin do
        allow :admin
        controller :lists, only: [:show] do
          allow :client
        end
      end
    end
    as_admin do 
      get :index
      expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["index"\].*as `:admin`/
    end
    as_client do
      expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
      expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["index"\].*\[autherized by :allow_by_default\]/
    end

    [:client, :admin].each do |cc|
      as cc do 
        get :show 
      end
    end
  end


  it "should work with nested namespace rules" do
    Acu::Rules.define do
      namespace :admin do
        allow :admin
        namespace :booking do
          controller :lists, only: [:show] do
            allow :client
          end
        end
      end
    end
    as_admin do 
      get :index
      expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["index"\].*as `:admin`/
    end
    as_client do
      expect {get :index}.to raise_error(Acu::Errors::AccessDenied)
      expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["index"\].*\[autherized by :allow_by_default\]/
    end

    [:client, :admin].each do |cc|
      as cc do 
        get :show 
      end
    end
  end

  context "nested namespace only/expect tags" do
    it 'should not allow nested `only` tags' do
      expect {
        Acu::Rules.define do
          namespace :admin, only: [:index] do
            allow :admin
            namespace :booking, only: [:show] do
              allow :client
            end
          end
        end 
      }.to raise_error(Acu::Errors::AmbiguousRule)
    end
    it 'should not allow nested `except` tags' do
      expect {
        Acu::Rules.define do
          namespace :admin, except: [:index] do
            allow :admin
            namespace :booking, except: [:show] do
              allow :client
            end
          end
        end 
      }.to raise_error(Acu::Errors::AmbiguousRule)
    end
    it 'should not allow nested `except/only` tags' do
      expect {
        Acu::Rules.define do
          namespace :admin, except: [:index] do
            allow :admin
            namespace :booking, only: [:show] do
              allow :client
            end
          end
        end 
      }.to raise_error(Acu::Errors::AmbiguousRule)
      expect {
        Acu::Rules.define do
          namespace :admin, except: [:index], only: [:show] do
            allow :admin
            namespace :booking do
              allow :client
            end
          end
        end 
      }.to raise_error(Acu::Errors::AmbiguousRule)
    end

    it "nested namespaces should work with `only` tags" do
      Acu::Rules.define do
        namespace :admin, only: [:lists] do
          allow :admin
          namespace :booking do
            allow :client
          end
        end
      end
      [:admin, :client].each do |_as|
        as _as do 
          [:index, :show].each do |a|
            get a
            expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["#{a.to_s}"\].*as `:#{_as.to_s}`/
          end
        end
      end
    end

    it "nested namespaces should work with `expect` tags [1/2]" do
      Acu::Rules.define do
        namespace :admin do
          allow :admin
          namespace :booking, except: [:lists] do
            allow :client
          end
        end
      end
      as_admin do 
        [:index, :show].each do |a|
          get a
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access GRANTED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["#{a.to_s}"\].*as `:admin`/
        end
      end
      as_client do 
        [:index, :show].each do |a|
          expect {get a}.to raise_error(Acu::Errors::AccessDenied)
          expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["#{a.to_s}"\].*\[autherized by :allow_by_default\]/
        end
      end
    end

    it "nested namespaces should work with `expect` tags [2/2]" do
      Acu::Rules.define do
        namespace :admin, except: [:lists] do
          allow :admin
          namespace :booking do
            allow :client
          end
        end
      end
      [:admin, :client].each do |_as|
        as _as do 
          [:index, :show].each do |a|
            expect {get a}.to raise_error(Acu::Errors::AccessDenied)
            expect(`tail -n 1 #{Acu::Configs.get :audit_log_file}`).to match /access DENIED to.*namespace=\["admin", "booking"\].*controller=\["lists"\].*action=\["#{a.to_s}"\].*\[autherized by :allow_by_default\]/
          end
        end
      end
    end
  end

end
