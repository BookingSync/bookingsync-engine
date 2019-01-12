class AddCredentialsFieldsToApplications < ActiveRecord::Migration[5.2]
  def change
    add_column :applications, :host, :string, null: false
    add_index :applications, :host, unique: true
    add_column :applications, :client_id, :text, null: false
    add_index :applications, :client_id, unique: true
    add_column :applications, :client_secret, :text, null: false
    add_index :applications, :client_secret, unique: true
  end
end
