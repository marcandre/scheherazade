class Page < ActiveRecord::Base
  belongs_to :website
  has_many :sections, inverse_of: :page

  validates_presence_of :website
end
