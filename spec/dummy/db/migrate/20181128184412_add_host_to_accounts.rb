class AddHostToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :host, :string
  end
end
