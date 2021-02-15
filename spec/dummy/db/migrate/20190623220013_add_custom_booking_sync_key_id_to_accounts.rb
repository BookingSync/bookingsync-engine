class AddCustomBookingSyncKeyIdToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :customized_key, :integer
  end
end
