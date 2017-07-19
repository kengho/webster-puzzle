class CreateRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :records do |t|
      t.integer :dictionary_id
      t.string :word
      t.json :linked_definitions
    end
  end
end
