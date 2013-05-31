class AddApprovalFlag < ActiveRecord::Migration
  def up
    add_column :users, :approved, :boolean
  end

  def down
    remove_column :users, :approved
  end
end
