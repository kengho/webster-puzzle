namespace :dictionary do
  # rake dictionary:prepare_json
  desc 'Loads JSON dictionary, fixes typos and exports'
  task :prepare_json do
    dict_json = DictionaryJSON.new(
      Rails.root.join('app', 'lib', 'dictionary', 'dictionary.json')
    )
    dict_json.fix_typos!(
      Rails.root.join('app', 'lib', 'dictionary', 'known_typos.json')
    )
    dict_json.export(
      Rails.root.join(
        'app', 'lib', 'dictionary', 'dictionary_with_known_typos_fixed.json'
      )
    )
  end

  # rake dictionary:prepare[1]
  desc 'Loads dictionary, collects links and edges'
  task :prepare, [:dict_percentage] => [:environment] do |_, args|
    DEFAULT_DICT_PERCENTAGE = 100
    dict_percentage =
      if args[:dict_percentage]
        args[:dict_percentage].to_f
      else
        DEFAULT_DICT_PERCENTAGE
      end

    dict = Dictionary.import!(
      Rails.root.join(
        'app', 'lib', 'dictionary', 'dictionary_with_known_typos_fixed.json'
      ),
      dict_percentage,
      true
    )

    dict.collect_all_data(true)
    dict.linkify_all(true)
  end
end
