class Section < ActiveRecord::Base
  belongs_to :page, inverse_of: :sections

  validates_presence_of :header, :page
end
