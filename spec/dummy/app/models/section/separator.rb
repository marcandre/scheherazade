class Section::Post < Section
  has_many :comments, :as => :commentable
end
