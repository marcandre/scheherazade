require 'spec_helper'

module Scheherazade
  describe CharacterBuilder do
    around { |example| story.tell { example.run } }

    it 'supports lambdas' do
    end

    context 'when filling associations' do
      it 'respects the :as option' do
        post = CharacterBuilder.new(Section::Post).build [:comments]
        post.comments.map(&:commentable).should == [post]
      end
    end

    it 'keeps my arguments intact' do
      lambda {
        CharacterBuilder.new(Page).build([].freeze)
        CharacterBuilder.new(Page).build({}.freeze)
      }.should_not raise_error
    end

    it 'generates different values by default' do
      attributes = [:title, :dob, :zip, :phone, :email]
      users = 10.times.map{ CharacterBuilder.new(User).build(attributes) }
      attributes << :created_at
      not_unique = attributes.select{|a| users.map(&a).uniq! }
      not_unique.should == []
    end
  end
end
