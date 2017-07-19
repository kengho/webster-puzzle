namespace :puzzles do
  # rake puzzles:populate[100]
  desc 'Populates appropriate db with puzles.'
  task :populate, [:number] => [:environment] do |_, args|
    DEFAULT_NUMBER = 100
    number =
      if args[:number]
        args[:number].to_i
      else
        DEFAULT_NUMBER
      end

    Puzzle.populate!(Dictionary.last, number, true)
  end
end
