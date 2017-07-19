class Api::V1::PuzzlesController < Api::V1::BaseController
  DIFFICULTY_PATH_SIZE_MAP = {
    'EASY' => 3,
    'MEDIUM' => 4..5,
    'HARD' => 6..7,
    'ANY' => 0..Float::INFINITY,
  }.freeze

  def index
    throw_error('internal', 'No puzzles left.') and return unless Puzzle.any?

    difficulty = params[:difficulty]
    if difficulty && !DIFFICULTY_PATH_SIZE_MAP.keys.include?(difficulty.upcase)
      throw_error(
        'external',
        "Difficulty should be in
          '#{DIFFICULTY_PATH_SIZE_MAP.keys.map(&:upcase)}'.".squish
      ) and return
    end

    effective_puzzles =
      if difficulty
        Puzzle.where(path_size: DIFFICULTY_PATH_SIZE_MAP[difficulty.upcase])
      else
        Puzzle.all
      end

    random_offset = rand(effective_puzzles.size)
    puzzle = effective_puzzles.offset(random_offset).first
    throw_error('internal', 'Unable to get puzzle.') and return unless puzzle

    record = Record.find_by(word: puzzle.beginning)
    unless record
      throw_error(
        'internal',
        "No record found for word '#{puzzle.beginning}'."
      ) and return
    end
    beginning_definitions = record ? record.linked_definitions : []

    response = {
      data: {
        beginning: puzzle.beginning,
        destination: puzzle.destination,
        beginning_definitions: beginning_definitions,
      },
    }

    render json: response
  end
end
