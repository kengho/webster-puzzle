class CreateDictionaries < ActiveRecord::Migration[5.0]
  def change
    create_table :dictionaries do |t|
      t.json :content
      t.json :edges
      t.json :links
    end
  end
end
