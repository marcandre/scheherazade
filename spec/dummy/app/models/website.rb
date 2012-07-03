class Website < ActiveRecord::Base
  has_many :pages
  belongs_to :user

  validates_presence_of :user
end
