class Section < ActiveRecord::Base
  belongs_to :page

  validates_presence_of :header, :page
end
