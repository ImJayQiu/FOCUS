class CreateRmethods < ActiveRecord::Migration[6.0]
  def change
    create_table :rmethods do |t|
      t.string :name
      t.string :fname
      t.string :remark

      t.timestamps
    end
  end
end
