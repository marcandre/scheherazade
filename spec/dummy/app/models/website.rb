class Website < ActiveRecord::Base
  has_many :pages
  belongs_to :user

  validates_presence_of :user

  class Castle < ActiveRecord::Base
    self.table_name = :websites
    belongs_to :king, class_name: "User::Royalty", foreign_key: :user_id
    validates_presence_of :king
  end
end
