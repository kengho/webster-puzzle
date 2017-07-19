# Usage:
#   Production:
#     dict = Dictionary.import!(Rails.root.join('app', 'lib', 'dictionary', 'dictionary_with_known_typos_fixed.json'))
#     dict.collect_all_data(true)
#     dict.linkify_all(true)
#     Puzzle.populate!(dict, 100000)
#   Development:
#     dict = Dictionary.import!(Rails.root.join('app', 'lib', 'dictionary', 'dictionary_with_known_typos_fixed.json'), 0.01)
#     dict.collect_all_data(true)
#     dict.linkify_all(true)
#     Puzzle.populate!(dict, 10)

require 'lingua/stemmer'
require 'rgl/adjacency'
require 'rgl/dijkstra'

class Dictionary < ActiveRecord::Base
  has_many :puzzles, dependent: :destroy
  has_many :records, dependent: :destroy
  validates :content, presence: true

  MIN_PROCESSABLE_WORD_SIZE = 3
  MAX_PROCESSABLE_DEFINITIONS_SIZE = 200

  WORD_IS_PROCESSABLE = lambda do |word|
    case ENV['RAILS_ENV']
    when 'production'
      word.size >= MIN_PROCESSABLE_WORD_SIZE
    else
      true
    end
  end.freeze

  RECORD_IS_PROCESSABLE = lambda do |record|
    case ENV['RAILS_ENV']
    when 'production'
      Dictionary.definitions_size(record) <= MAX_PROCESSABLE_DEFINITIONS_SIZE
    else
      true
    end
  end.freeze

  def self.import!(dict_path, percentage = 100, progress = true)
    destroy_all
    dict_json = DictionaryJSON.new(dict_path)
    chop!(dict_json.content, percentage, progress)

    Dictionary.create!(content: dict_json.content, edges: [], links: {})
  end

  # NOTE: loading everything into Redis may significantly speed up the process.
  def collect_all_data(progress = false)
    content_size = content.size
    content.each_with_index do |(word, record), index|
      collect_links_and_edges(word, record)
      next unless progress

      # rubocop:disable Rails/Output
      print("Collecting all data: #{index + 1}/#{content_size}.\r")
      # rubocop:enable Rails/Output
      $stdout.flush
    end
    puts if progress

    save!
    links.size
  end

  def collect_links_and_edges(current_word, record)
    record['definitions'].each do |definition_record|
      definition = definition_record['definition']
      definition_words = Words.split_sentence(definition)
      definition_words.each do |definition_word|
        next unless WORD_IS_PROCESSABLE.call(definition_word)

        match = find(definition_word)
        next unless match

        match_word = match.keys.first
        next unless WORD_IS_PROCESSABLE.call(match_word)
        next if match == definition_word

        links[definition_word] = match_word
        edges.push([current_word, match_word])
      end
    end

    edges.sort!.uniq!
  end

  def find(search_word)
    # test 02
    return { search_word => content[search_word] } if content[search_word]

    record = ->(word) { { word => content[word] } }

    # Use "cache" for consecutive linked_definitions() to work faster.
    cached_link = links[search_word]
    return record.call(cached_link) if cached_link

    return if search_word =~ /^[^[:alnum:]]$/ # test -01

    # downcase() for test -01a
    content_key = find_matched_content_key(search_rules, search_word.downcase)
    return unless content_key # test 11

    # Save result to "cache".
    links[search_word] = content_key

    record.call(content_key)
  end

  def linkify_all(progress = false)
    Record.where(dictionary: self).destroy_all

    content_size = content.size
    content.each_with_index do |(word, record), index|
      record['definitions'].each do |definition|
        definition_words = Words.split_sentence(definition['definition'])
        linked_definition, links = linked_definition(definition_words)
        definition['linked_definition'] = linked_definition
        definition['links'] = links
      end

      Record.create!(
        word: word,
        linked_definitions: linked_definitions(word),
        dictionary: self
      )

      next unless progress

      # rubocop:disable Rails/Output
      print("Linkifying all definitions: #{index + 1}/#{content_size}.\r")
      # rubocop:enable Rails/Output
      $stdout.flush
    end
    puts if progress

    save!
  end

  def linked_definition(splitted_sentence)
    definition = []
    links = []
    current_text = { type: :text, text: '' }
    splitted_sentence.each do |definition_word|
      found_record = find(definition_word.downcase)

      if found_record
        unless current_text[:text].empty?
          definition.push(current_text)
          current_text = { type: :text, text: '' }
        end

        word = found_record.keys.first
        links.push(word)
        definition
          .push(
            type: :link,
            text: definition_word,
            to: word
          )
      else
        current_text[:text] << definition_word
      end
    end

    definition.push(current_text) unless current_text[:text].empty?
    links.sort!.uniq!

    [definition, links]
  end

  def puzzle
    dag = RGL::DirectedAdjacencyGraph[*edges.flatten]

    loop do
      beginning = content.keys.sample
      destination = (content.keys - [beginning]).sample

      begin
        path = dag.dijkstra_shortest_path(
          Hash.new(1), beginning, destination
        )
      rescue => e
        Rails.logger.info("Error while generating puzzle: '#{e}'")
        next
      end

      if path
        return {
          beginning: beginning,
          destination: destination,
          path_size: path.size,
        }
      end
    end
  end

  def linked_definitions(word)
    return unless word

    clean_definition = lambda do |definition|
      definition.keep_if { |key| %w(linked_definition links).include?(key) }
    end

    definitions = content[word] ? content[word]['definitions'] : []
    definitions.each { |definition| clean_definition.call(definition) }

    definitions
  end

  def self.definitions_size(record)
    record['definitions'].each.inject(0) do |sum, definition|
      sum + definition['definition'].size
    end
  end

  def self.chop!(json, percentage, progress = true)
    json_keys_size_before = json.keys.size
    chopped_json_keys_count =
      (json.keys.size * Float(percentage) / 100).ceil

    Rails.logger
      .info(
        "#{chopped_json_keys_count}/#{json.keys.size}
          keys remaining after percentage chopping.".squish
      )

    chopped_json_keys = json.keys[0..chopped_json_keys_count - 1]

    index = 0
    json.keep_if do |word, record|
      if progress
        # rubocop:disable Rails/Output
        print(
          'Removing unprocessable keys: '\
          "#{index + 1}/#{json_keys_size_before}.\r"
        )
        # rubocop:enable Rails/Output
        $stdout.flush
        index += 1
      end

      chopped_json_keys.include?(word) &&
        WORD_IS_PROCESSABLE.call(word) &&
        RECORD_IS_PROCESSABLE.call(record) &&
        true
    end
    puts if progress
    json_keys_size_after = json.keys.size
    Rails.logger.info("#{json_keys_size_after} keys left.")

    json_keys_size_before - json_keys_size_after
  end

  private

    def find_matched_content_key(rules, search_word)
      rules.each do |rule|
        search_word_modifier, comparator = rule
        search_word_gotten = search_word_modifier.call(search_word)
        content.each do |content_word, _|
          if comparator.call(search_word_gotten, content_word)
            return content_word
          end
        end
      end

      nil
    end

    def search_rules
      known_exceptions_path =
        Rails.root.join(
          'app', 'lib', 'dictionary', 'known_search_exceptions.json'
        )
      known_exceptions = Utils.read_json_file(known_exceptions_path)

      stemmer = Lingua::Stemmer.new(language: 'en')

      # What to search (search word modifiers).
      # Lambdas are ~10% faster than values' precalculating on my machine.
      stem = ->(word) { stemmer.stem(word) }
      nop = ->(word) { word }
      singularize = ->(word) { word.singularize }
      chop = ->(word) { Words.chop_suffix(word) }
      chop_twice = ->(word) { Words.chop_suffix(word, 2) }
      singularize_and_chop = ->(word) { Words.chop_suffix(word.singularize) }
      stem_and_chop = ->(word) { Words.chop_suffix(stemmer.stem(word), 2) }

      # How to search (comparators).
      exceptions_at_x_equal_y = ->(x, y) { known_exceptions[x] == y }
      x_equal_y = ->(x, y) { x == y }
      y_include_x = ->(x, y) { y.include?(x) }

      # DictionaryFindTest test 00
      y_include_x_with_size = ->(x, y) { x.size >= 3 && y.include?(x) }

      [
        # [search_word_modifier, comparator, name]
        [nop, exceptions_at_x_equal_y, :test_01],

        [singularize, x_equal_y, :test_03],

        [chop, y_include_x_with_size, :test_04],
        [singularize_and_chop, y_include_x_with_size, :test_05],
        [chop_twice, y_include_x_with_size, :test_06],

        [stem, x_equal_y, :test_07],
        [nop, y_include_x, :test_08],
        [chop, y_include_x, :test_09],

        [stem_and_chop, y_include_x_with_size, :test_10],
      ]
    end
end
