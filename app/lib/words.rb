module Words
  def split_sentence(sentence)
    sentence_with_replacements = sentence
      .gsub('n\'t', 'nAPOSTROPHEt')
      .gsub(/(\w+)\-(\W+|$)/, '\1HYPHEN\2')

    splitted_sentence = sentence_with_replacements
      .split(/([^[:alnum:]])/)
      .flatten
      .reject(&:empty?)
      .map do |word|
        word
          .sub('APOSTROPHE', '\'')
          .sub('HYPHEN', '-')
      end

    splitted_sentence
  end

  def nearest_words_index(words_array, from_index, direction = :right, skip = 0)
    words_counter = skip
    if direction == :right
      start_index = from_index + 1
      end_index = words_array.size - 1
      enumerator = start_index.upto(end_index)
    elsif direction == :left
      start_index = from_index - 1
      end_index = 0
      enumerator = start_index.downto(end_index)
    end

    enumerator.each do |index|
      word = words_array[index]

      next if word !~ /[[:alpha:]]+/
      if word =~ /[[:alpha:]]+/ && words_counter > 0
        words_counter -= 1
        next
      end

      return index
    end

    nil
  end

  FIX_TYPO_RULES = [
    ->(text, typo_what, typo_to) { text.gsub(typo_what, typo_to) },
    lambda do |text, typo_what, typo_to|
      text.gsub(typo_what.capitalize, typo_to.capitalize)
    end,
  ].freeze

  def fix_typo!(text, typo_what, typo_to)
    match = false
    FIX_TYPO_RULES.index do |rule|
      text_after_rule = rule.call(text, typo_what, typo_to)
      match = (!text_after_rule.nil? && text_after_rule != text)
      text.replace(text_after_rule) if match
    end

    match
  end

  # https://www.learnthat.org/pages/view/suffix.html
  # Additional:
  # iety => corporiety
  # ium => criterium
  # ized => crystallised
  # n\'t => couldn't # not a suffux technically
  # ry => rocketry
  # ster => gangster
  # ual => contractual
  # up => cleanup # not a suffux technically
  # TODO: find all complex suffixes
  # --acity --ical (complex)
  # --tion (deletion => dele, -ion is better)
  SUFFIXES = %w(
    able ac acity ade age aholic al algia an ance ant ar ard arian arium ary
    ate ation ative cide cracy crat cule cy cycle dom dox ectomy ed ee eer
    emia en ence ency ent er ern escence ese esque ess est etic ette ful fy
    gam gamy gon gonic hood ial ian ian iasis iatric ible ic ile ily ine
    ing ion ious ish ism ist ite itis ity ive ization ize less let like ling
    log loger logist ly ment ness ocity oholic oid ology oma onym opia opsy
    or orium ory osis ostomy otomy ous path pathy phile phobia phone phyte
    plegia plegic pnea scope scopy scribe script sect ship sion some sophic
    sophy th tome tomy trophy tude ty ular uous ure ward ware wise y
  ) + %w(iety ium ized n't ry ster ual up)

  def chop_suffix(word, times = 1)
    SUFFIXES.sort_by(&:size).reverse.each do |suffix|
      next unless word[-suffix.size..-1] == suffix

      word_with_chopped_suffix = word[0...-suffix.size]
      return word_with_chopped_suffix if times == 1
      return chop_suffix(word_with_chopped_suffix, times - 1)
    end

    word
  end

  module_function(
    :split_sentence, :nearest_words_index,
    :fix_typo!, :chop_suffix
  )
end
