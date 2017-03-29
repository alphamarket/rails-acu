require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  context 'database' do
    it 'validate database' do
      expect(User.count).to be 10
      expect(UserType.count).to be 10
      User.all.each do |u|
        expect(u.user_type).not_to be_nil
        expect(u.user_type.id == u.id).to be true
      end
    end
  end
end
