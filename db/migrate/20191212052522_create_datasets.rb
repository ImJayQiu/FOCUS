class CreateDatasets < ActiveRecord::Migration[6.0]
  def change
    create_table :datasets do |t|
      t.string :name
      t.string :fname
      t.string :dtype
      t.string :dpath
      t.string :active
      t.string :remark

      t.timestamps
    end
  end
end
