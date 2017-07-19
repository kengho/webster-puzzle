# Usage:
#   Fix typos and export:
#   dict_json = DictionaryJSON.new(Rails.root.join('app', 'lib', 'dictionary', 'dictionary.json'))
#   dict_json.fix_typos!(Rails.root.join('app', 'lib', 'dictionary', 'known_typos.json'))
#   dict_json.export(Rails.root.join('app', 'lib', 'dictionary', 'dictionary_with_known_typos_fixed.json'))
class DictionaryJSON
  @@props = [:content]
  attr_accessor(*@@props)
  delegate :[], to: :content

  def initialize(dict_path)
    dict_json = Utils.read_json_file(dict_path)

    @content =
      if dict_json
        length_sort(dict_json) if dict_json
      else
        {}
      end
  end

  def fix_typos!(
    typos_path = Rails.root.join('app', 'lib', 'dictionary', 'known_typos.json')
  )
    typos = Utils.read_json_file(typos_path)
    return unless typos

    definitions_typos = fix_definitions_typos!(typos['definitions'])
    words_typos = fix_words_typos!(typos['words'])

    definitions_typos.compact + words_typos.compact
  end

  def export(where, what = :content)
    case where
    when String, Pathname
      path = where
      file = File.open(path, 'w')
      return unless file

      case what
      when :content
        file.write(JSON.pretty_generate(content))
      end

      file.close
    end
  end

  private

    def fix_definitions_typos!(definitions_typos)
      flat_definitions_typos = flatten_definitions_typos(definitions_typos)
      flat_definitions_typos.map! do |definition_typo|
        typo_what, typo_to, typo_where = definition_typo
        typo_matches = fix_typos_in_definition!(typo_where, typo_what, typo_to)

        typo_matches ? nil : definition_typo
      end

      flat_definitions_typos
    end

    def fix_words_typos!(words_typos)
      words_typos.map! do |word_typo|
        typo_what,
        typo_to,
        original_cased_word,
        transliterated_word = word_typo

        typo_matches =
          if content[typo_what]
            content[typo_to] = content[typo_what]
            content[typo_to]['original_cased_word'] = original_cased_word
            content[typo_to]['transliterated_word'] = transliterated_word
            content.delete(typo_what)

            content[typo_what] ? false : true
          else
            false
          end

        typo_matches ? nil : word_typo
      end

      words_typos
    end

    def length_sort(hash)
      sorted_array = hash.sort do |x, y|
        if x[0].size != y[0].size
          x[0].size <=> y[0].size
        else
          x[0] <=> y[0]
        end
      end

      sorted_array.to_h
    end

    def fix_typos_in_definition!(typo_where, typo_what, typo_to)
      dict_entry = content[typo_where]
      return false unless dict_entry

      typo_matches = false

      # Cannot use find_definition() because typo may be not in form of word.
      dict_entry['definitions'].each do |definition|
        match = Words.fix_typo!(definition['definition'], typo_what, typo_to)

        # Don't assign using fix_typo() because that may overwrite true by false later.
        # Don't return if typo_matches because typo may be in several definitions.
        # and we want to fix them all.
        typo_matches = true if match
      end

      typo_matches
    end

    # [
    #   ["cappture", "capture", "nab"],
    #   ["diruption", "disruption", ["disruption", "nab", "sectorial"]]
    # ]
    # =>
    # [
    #   ["cappture", "capture", "nab"],
    #   ["diruption", "disruption", "disruption"],
    #   ["diruption", "disruption", "nab"],
    #   ["diruption", "disruption", "sectorial"]
    # ]
    def flatten_definitions_typos(definitions_typos)
      flatten_definitions_typos = []
      definitions_typos.each do |definitions_typo|
        typo_what_to_json = definitions_typo[0..1].to_json
        typo_where_array = Array(definitions_typo[2])

        flatten_typo = Array(typo_what_to_json).product(typo_where_array)
          .map { |typo| [JSON.parse(typo[0]), typo[1]].flatten }

        flatten_definitions_typos.push(*flatten_typo)
      end

      flatten_definitions_typos
    end
end
