class AddOAuthFieldsToMultiApplicationsAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :multi_applications_accounts, :provider, :string
    add_column :multi_applications_accounts, :synced_id, :integer
    add_index :multi_applications_accounts, :synced_id
    add_column :multi_applications_accounts, :name, :string
    add_column :multi_applications_accounts, :oauth_access_token, :string
    add_column :multi_applications_accounts, :oauth_refresh_token, :string
    add_column :multi_applications_accounts, :oauth_expires_at, :string
    add_column :multi_applications_accounts, :host, :string, null: false
    add_index :multi_applications_accounts, :host
    add_index :multi_applications_accounts, [:host, :synced_id], unique: true
  end
end
