class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :user
      t.string :password_hash
    end
    add_index :users, :user
  end

  def down
    drop_table :users
  end
end
