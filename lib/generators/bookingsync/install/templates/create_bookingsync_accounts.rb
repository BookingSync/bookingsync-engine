class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :provider
      t.integer :uid
      t.string :name
      t.string :oauth_access_token
      t.string :oauth_refresh_token
      t.string :oauth_expires_at

      t.timestamps
    end
  end
end
