class Puzzle < ActiveRecord::Base
  belongs_to :dictionary
  validates :dictionary, presence: true
  validates :beginning, uniqueness: { scope: :destination }, presence: true
  validates :destination, uniqueness: { scope: :beginning }, presence: true
  validates :path_size, presence: true

  def self.populate!(dict, number, progress = true)
    puzzles_to_delete = Puzzle.where(dictionary: dict)
    puzzles_to_delete.destroy_all if puzzles_to_delete

    Rails.logger.info('Generating puzzles...')
    number.times do |index|
      puzzle = dict.puzzle
      create(puzzle.merge(dictionary: dict))
      next unless progress

      # rubocop:disable Rails/Output
      print("#{index + 1}/#{number}.\r")
      # rubocop:enable Rails/Output
      $stdout.flush
    end
    puts if progress
  end
end
