class Section::Post < Section
  has_many :comments, :as => :commentable
  validates_presence_of :content
end
