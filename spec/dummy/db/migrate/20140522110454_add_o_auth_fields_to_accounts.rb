class AddOAuthFieldsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :provider, :string
    add_column :accounts, :synced_id, :integer
    add_index :accounts, :synced_id
    add_column :accounts, :name, :string
    add_column :accounts, :oauth_access_token, :string
    add_column :accounts, :oauth_refresh_token, :string
    add_column :accounts, :oauth_expires_at, :string
  end
end
