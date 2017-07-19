require 'test_helper'

class DictionaryFindTest < ActionController::TestCase
  setup do
    @dict = Dictionary.import!(
      Rails.root.join('test', 'unit', 'dictionary_find.json')
    )
  end

  # -01
  test 'shouldn\'t find non-word characters' do
    assert_nil @dict.find('.')
  end

  # -01a
  test 'should downcase words first' do
    assert_equal(['G'], @dict.find('g').keys)
  end

  # 00
  test 'shouldn\'t delete too much leaving less than 3 symbols' do
    assert_equal(['delete'], @dict.find('deletions').keys)
  end

  # 01
  test 'should find word by substring using exceptions' do
    assert_equal(['adjective'], @dict.find('adj').keys)
  end

  # 02
  test 'should find word by exact match' do
    assert_equal(['rotiform'], @dict.find('rotiform').keys)
  end

  # 03
  test 'should find word by singularizing and exact match' do
    assert_equal(['abdicate'], @dict.find('abdicates').keys)
  end

  # 04
  test 'should find word by chopping off suffix and searching substringing' do
    assert_equal(['accept'], @dict.find('accepted').keys)
  end

  # 05
  test 'should find word by substring by singularizing, '\
    'chopping off suffix and searching substring' do
    assert_equal(['criterion'], @dict.find('criteria').keys)
    assert_equal(['allergy'], @dict.find('allergens').keys)
  end

  # 06
  test 'should find word by substring by chopping off '\
    'suffix 2 times and searching substring' do
    assert_equal(['artistic'], @dict.find('artistically').keys)
  end

  # 07
  test 'should find word by stemming and exact match' do
    assert_equal(['acquit'], @dict.find('acquitted').keys)
  end

  # 08
  test 'should find word by substring' do
    assert_equal(['rotiform'], @dict.find('rotifor').keys)
  end

  # 09
  test 'should find word by chopping suffixed for words '\
    'more than 2 letters long if not matched before' do
    assert_equal(['are'], @dict.find('aren\'t').keys)
  end

  # 10
  test 'should find word by substring by stemming '\
    'and chopping off suffixes' do
    assert_equal(['allergenic'], @dict.find('allergenicity').keys)
  end

  # 11
  test 'find should return nil if nothing found' do
    assert_nil @dict.find('not found')
  end

  # 12
  test 'should find shortest words first while searching by substring' do
    assert_equal(['list'], @dict.find('lis').keys)
  end

  test 'should find all words by substring' do
    assert_equal(%w(rondel rotiform).sort, @dict.find_all('ro').keys.sort)
  end

  test 'find_all should return nil if nothing found' do
    assert_nil @dict.find_all('not found')
  end
end
