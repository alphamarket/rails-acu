class CreateAdminBookingChats < ActiveRecord::Migration[5.0]
  def change
    create_table :admin_booking_chats do |t|
      t.string :name

      t.timestamps
    end
  end
end
