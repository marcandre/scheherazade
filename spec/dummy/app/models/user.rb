class User < ActiveRecord::Base
  has_many :comments
  has_many :websites
  validates_presence_of :first_name, :last_name

  class Royalty < ActiveRecord::Base
    has_many :castles, class_name: 'Website::Castle', foreign_key: :user_id
    self.table_name = :users
    validates_length_of :first_name, minimum: 100
  end
end
