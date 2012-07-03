class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user

  validates_presence_of :commentable
  validates_presence_of :email, :unless => :user
  validates_presence_of :name, :unless => :user
end
