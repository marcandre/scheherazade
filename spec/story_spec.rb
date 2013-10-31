require 'spec_helper'

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

    it "won't affect modified and unsaved records" do
      original = User.imagine
      original.last_name = 'modified but not persisted'
      story.tell do
        inner = story.current[User]
        inner.should == original
        inner.last_name = 'modified in the inner story'
      end
      story.current[User].should equal original
      original.last_name.should == 'modified but not persisted'
    end

    it 'is thread-safe' do
      cur = story
      s = nil
      t = Thread.new do
        cur.should_not == story
        story.tell do
          s = story
          sleep
        end
      end
      story.tell do
        t.join(0.01) until s
        s.should_not == cur
        s.should_not == cur
      end
      t.kill
    end
  end

  describe 'fill' do
    before do
      story.fill User, :state do
        story.fill :montrealer, :city => 'Montreal'
      end
    end
    context 'with additional fields to fill' do
      it { User.imagine.state.should be_present }
      it { User.imagine.city.should be_blank }
      it { :montrealer.imagine.city.should == 'Montreal' }
      it { :montrealer.imagine.state.should be_present }
    end

    it "doesn't allows overriding a model" do
      lambda {
        story.fill User
      }.should raise_error(Scheherazade::RedefinitionError)
    end
  end

  describe 'after_imagine' do
    it "raises an error outside of a fill" do
      expect{ story.after_imagine {} }.to raise_error
    end

    it "works inside a fill" do
      called_on = []
      story.fill User do
        story.after_imagine {|c| called_on << c }
        story.fill :montrealer
      end
      objects = [:user, User, :montrealer].map{|com| com.imagine}
      called_on.should == objects
    end
  end

  describe 'fill' do
    it 'is a convenient way to set a different current object' do
      p3, p2, p1 = 3.times.map{ Page.imagine }
      story.current[Page].should == p1
      story.tell do
        story.current[Page].should == p1
        story.with :page => p2 do
          story.current[Page].should == p2
          other = Page.imagine
          story.current[Page].should == other
          story.with :page => p3 do
            story.current[Page].should == p3
          end
          story.current[Page].should == other
        end
        story.current[Page].should == p1
      end
      story.current[Page].should == p1
    end
  end

  describe '==' do
    it 'is true only for the same story object' do
      story.should == story
      Scheherazade::Story.new.should_not == Scheherazade::Story.new
      Scheherazade::Story.new.should_not eql Scheherazade::Story.new
    end
  end

  [[Page, :page], [:page, Page]].each do |char, equiv|
    it "does not distinguish between #{char} and #{equiv}" do
      p = story.imagine(char)
      p.should == story.current[equiv]
      p.should == story.get(equiv)
      end
  end

  describe 'imagine' do
    it { expect { story.imagine :non_existing_character }.to raise_error(NameError, "Character not defined: non_existing_character")}
  end
end
