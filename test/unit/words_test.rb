require 'test_helper'

class WordsTest < ActionController::TestCase
  setup do
    @cowl_sentence = 'A chimney cap; a cowl'
    @splited_cowl_sentence = [
      'A', ' ', 'chimney', ' ', 'cap', ';', ' ', 'a', ' ', 'cowl'
    ]
  end

  test 'should split regular sentence' do
    assert_equal(@splited_cowl_sentence, Words.split_sentence(@cowl_sentence))
  end

  test 'should split sentence with diacritics' do
    sentence = 'José is Joseph'
    splitted_sentence = ['José', ' ', 'is', ' ', 'Joseph']

    assert_equal(splitted_sentence, Words.split_sentence(sentence))
  end

  test 'should split sentence with \' *not redutions' do
    sentence = 'Can\'t: contraction of cannot'
    splitted_sentence = [
      'Can\'t', ':', ' ', 'contraction', ' ', 'of', ' ', 'cannot'
    ]

    assert_equal(splitted_sentence, Words.split_sentence(sentence))
  end

  test 'should split sentence with hyphenated words' do
    sentence = 'under the name eka-aluminium'
    splitted_sentence = [
      'under', ' ', 'the', ' ', 'name', ' ', 'eka', '-', 'aluminium'
    ]

    assert_equal(splitted_sentence, Words.split_sentence(sentence))
  end

  test 'should split sentence with ending with hyphens words' do
    sentence = 'See Ect-'
    splitted_sentence = ['See', ' ', 'Ect-']

    assert_equal(splitted_sentence, Words.split_sentence(sentence))
  end

  test 'should split sentence with words with numbers' do
    sentence = '3d pers. sing.'
    splitted_sentence = ['3d', ' ', 'pers', '.', ' ', 'sing', '.']

    assert_equal(splitted_sentence, Words.split_sentence(sentence))
  end

  test 'should find nearest word\'s index in array (right, OK)' do
    assert_equal(
      @splited_cowl_sentence.index('a'),
      Words.nearest_words_index(
        @splited_cowl_sentence,
        @splited_cowl_sentence.index('chimney'),
        :right, 1
      )
    )
  end

  test 'should find nearest word\'s index in array (right, default params)' do
    assert_equal(
      Words.nearest_words_index(
        @splited_cowl_sentence,
        @splited_cowl_sentence.index('chimney'),
        :right, 0
      ),
      Words.nearest_words_index(
        @splited_cowl_sentence,
        @splited_cowl_sentence.index('chimney')
      )
    )
  end

  test 'should find nearest word\'s index in array (right, not found)' do
    assert_nil Words.nearest_words_index(
      @splited_cowl_sentence,
      @splited_cowl_sentence.index('chimney'),
      :right, 3
    )
  end

  test 'should find nearest word\'s index in array (left, OK)' do
    assert_equal(
      @splited_cowl_sentence.index('cap'),
      Words.nearest_words_index(
        @splited_cowl_sentence,
        @splited_cowl_sentence.index('cowl'),
        :left, 1
      )
    )
  end

  test 'should find nearest word\'s index in array (left, not found)' do
    assert_nil Words.nearest_words_index(
      @splited_cowl_sentence,
      @splited_cowl_sentence.index('cowl'),
      :left, 4
    )
  end

  test 'should fix typo (gsub)' do
    typo_where = 'Adapted for cutting. See attachmenti. e.'
    typo_what = 'attachmenti. e.'
    typo_to = 'attachment i. e.'
    typo_where_fixed = 'Adapted for cutting. See attachment i. e.'

    assert_equal(true, Words.fix_typo!(typo_where, typo_what, typo_to))
    assert_equal(typo_where_fixed, typo_where)
  end

  test 'should fix typo (not catched)' do
    typo_where = 'Adapted for cutting. See attachmenti. e.'
    typo_what = 'not found'
    typo_to = 'attachment i. e.'

    typo_where_before = typo_where
    assert_equal(false, Words.fix_typo!(typo_where, typo_what, typo_to))
    assert_equal(typo_where_before, typo_where)
  end

  test 'should fix typo (capitalized word)' do
    typo_where = 'See Diruption.'
    typo_what = 'diruption'
    typo_to = 'disruption'
    typo_where_fixed = 'See Disruption.'

    assert_equal(true, Words.fix_typo!(typo_where, typo_what, typo_to))
    assert_equal(typo_where_fixed, typo_where)
  end

  test 'should chop off suffix from word' do
    assert_equal('drug', Words.chop_suffix('drugless'))
  end

  test 'should chop off suffix from word (suffix not found)' do
    assert_equal('achieves', Words.chop_suffix('achieves'))
  end

  test 'should chop off suffix from word (x2)' do
    assert_equal('artistic', Words.chop_suffix('artistically', 2))
  end
end
