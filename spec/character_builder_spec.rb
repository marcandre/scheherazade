require 'spec_helper'

module Scheherazade
  describe CharacterBuilder do
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
  end
end
