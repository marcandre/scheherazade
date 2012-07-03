class Page < ActiveRecord::Base
  belongs_to :website
  has_many :sections

  validates_presence_of :website
end
