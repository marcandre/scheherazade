require 'spec_helper'

module Scheherazade
  describe Scribe do
    let(:scribe) { Scribe.new }
    let(:object) { Website.new }
    let(:memorize) { scribe.memorize(object) }
    let(:restore) { scribe.restore_all }

    it 'can restore an AR record' do
      object.name = 'google'
      memorize
      object.name = 'facebook'
      restore
      object.name.should == 'google'
    end

    it "can restore an AR record's association" do
      memorize
      object.user = User.new
      restore
      object.user.should == nil
    end

    it "can restore an AR record's association" do
      object.pages.build
      memorize
      object.pages.build
      object.pages.build
      object.pages.size.should == 3
      restore
      object.pages.size.should == 1
    end

  end
end
