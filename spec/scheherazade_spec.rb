require 'spec_helper'

describe Scheherazade do
  context 'when creating a simple post' do
    let(:params) { {} }
    let(:post) { Section::Post.imagine(params) }
    subject { post }
    it { should be_a Section::Post }
    its(:content)  { should_not be_blank }
    its(:header)   { should_not be_blank }
    its(:comments) { should be_empty }
    its(:page)     { should_not be_nil }

    context 'and given a value for header' do
      let(:params) { {:header => 'My Header'} }
      its(:header) { should == 'My Header' }
    end

    describe 'sharing' do
      its(:page) { should == Section::Post.imagine.page }
      its(:page) { should_not == Section::Post.imagine(:page => Page.imagine).page }
      its(:page) { should_not == (:page.imagine; Section::Post.imagine.page) }
    end
  end

  describe Scheherazade::Story do
    describe 'tell' do
      let(:tell) do
        story.tell(options) do
          page = Page.imagine
          story.current[Page].should == page
          page
        end
      end

      let(:wont_change_the_story) do
        tell
        story.current[Page].should be_nil
        story.current[Website].should be_nil
      end

      context 'without rollback' do
        let(:options) { {:rollback => false} }

        it { wont_change_the_story }

        it "will keep created records around" do
          p = tell
          Page.find_by_id(p.id).should == p
          Website.all.should == [p.website]
        end
      end

      context 'with rollback' do
        let(:options) { {:rollback => true} }

        it { wont_change_the_story }

        it "destroys created records" do
          p = tell
          Page.find_by_id(p.id).should be_nil
          Website.all.should be_empty
        end
      end
    end
  end
end
