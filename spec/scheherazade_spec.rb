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
end
