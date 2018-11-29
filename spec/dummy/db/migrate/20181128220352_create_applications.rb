class CreateApplications < ActiveRecord::Migration[5.1]
  def change
    create_table :applications do |t|
      t.string :host
      t.text :client_id
      t.text :client_secret
    end
  end
end
