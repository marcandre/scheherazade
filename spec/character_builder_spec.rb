require 'spec_helper'

describe Scheherazade::CharacterBuilder do
  it 'supports lambdas' do
  end

  context 'when filling associations' do
    it 'respects the :as option' do
      post = Section::Post.imagine [:comments]
      post.comments.map(&:commentable).should == [post]
    end
  end
end
