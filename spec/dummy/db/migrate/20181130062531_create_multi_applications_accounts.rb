class CreateMultiApplicationsAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :multi_applications_accounts do |t|

      t.timestamps
    end
  end
end
