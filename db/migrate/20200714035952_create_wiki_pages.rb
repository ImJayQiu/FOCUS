class CreateWikiPages < ActiveRecord::Migration[6.0]
  def change
    create_table :wiki_pages do |t|
      t.integer :chapter
      t.integer :heading1
      t.integer :heading2
      t.integer :heading3
      t.string :title
      t.text :content
      t.string :image1
      t.string :image2

      t.timestamps
    end
  end
end
