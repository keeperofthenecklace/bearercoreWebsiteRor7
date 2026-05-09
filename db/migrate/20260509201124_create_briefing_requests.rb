class CreateBriefingRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :briefing_requests do |t|
      t.string :name
      t.string :title
      t.string :institution
      t.string :email
      t.string :status

      t.timestamps
    end
  end
end
