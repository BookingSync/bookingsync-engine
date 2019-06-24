class AddCustomBookingSyncKeyIdToMultiApplicationsAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :multi_applications_accounts, :customized_key, :integer
  end
end
