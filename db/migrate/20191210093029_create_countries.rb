class CreateCountries < ActiveRecord::Migration[6.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso
      t.float :slon
      t.float :elon
      t.float :slat
      t.float :elat
      t.text :remark

      t.timestamps
    end
  end
end
