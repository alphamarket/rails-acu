class CreateAdminUserTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :user_types do |t|
      t.string :name
      t.text :comment
      t.string :symbol
      t.integer :auth_level

      t.timestamps

      t.index :name, unique: true
      t.index :symbol, unique: true
    end
  end
end
