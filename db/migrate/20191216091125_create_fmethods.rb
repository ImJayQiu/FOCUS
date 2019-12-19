class CreateFmethods < ActiveRecord::Migration[6.0]
  def change
    create_table :fmethods do |t|
      t.string :name
      t.string :file_name
      t.string :remark1
      t.string :remark2

      t.timestamps
    end
  end
end
