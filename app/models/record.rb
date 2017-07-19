class Record < ActiveRecord::Base
  belongs_to :dictionary
  validates :word, uniqueness: true, presence: true
end
