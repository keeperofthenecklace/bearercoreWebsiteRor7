class CreateSoftwareLicenses < ActiveRecord::Migration[7.1]
  def change
    create_table :software_licenses do |t|
      t.string :name
      t.string :email
      t.string :ip_address
      t.string :status
      t.boolean :active
      t.date :duration
      t.string :centralbank
      t.string :swiftcode
      t.string :licenseid
      t.string :licensekey
      t.string :uri
      t.string :license_type
      t.string :bankID

      t.timestamps
    end
  end
end
