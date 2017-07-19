class CreatePuzzles < ActiveRecord::Migration[5.0]
  def change
    create_table :puzzles do |t|
      t.integer :dictionary_id
      t.string :beginning
      t.string :destination
      t.integer :path_size
    end
  end
end
