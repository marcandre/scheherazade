class User < ActiveRecord::Base
  has_many :comments
  has_many :websites
  validates_presence_of :first_name, :last_name
end
