module Scheherazade
  class Story < Hash
    attr_reader :fill_attributes, :characters, :counter, :current

    module ClassMethods
      def current
        (Thread.current[:scheherazade_stories] ||= []).last || TOP
      end

      # Begins a story within the current story.
      # Should be balanced with a call to +end+
      #
      def begin
        (Thread.current[:scheherazade_stories] ||= []).push Story.new
        current
      end

      # Ends the current substory and comes back
      # to the previous current story
      #
      def end(opts = nil)
        current.send :rollback if opts && opts[:rollback]
        Thread.current[:scheherazade_stories].pop
        current
      end

      # Begins a substory, yields, and ends the story
      #
      def tell(opts = nil)
        yield self.begin
      ensure
        self.end(opts)
      end
    end
    extend ClassMethods
    delegate :begin, :end, :tell, :to => 'self.class'


    def initialize(parent = self.class.current)
      super(){|h, k| parent[k] if parent }
      @parent = parent
      @current = Hash.new{|h, k| parent.current[k] if parent}
      @fill_attributes = Hash.new{|h, k| parent.fill_attributes[k] if parent }
      @characters = Hash.new do |h, k|
        if parent
          parent.characters[k]
        elsif k.is_a?(Symbol)
          k.to_s.camelize.constantize
        end
      end
      @counter = parent ? parent.counter.dup : Hash.new(0)
      @filling = []
      @after_imagine = {}
      @built = []
    end

    TOP = new(nil)

    # Creates a character with the given attributes
    #
    # A character can be designated either by the model (e.g. `User`), the corresponding
    # symbol (`:user`) or the symbol for a specialized type of character, defined using +fill+
    # (e.g. `:admin`).
    #
    # The attributes can be nil, a list of symbols, a hash or a combination of both
    # These, along with attributes passed to +fill+ for the current stories
    # and the mandatory attributes for the model will be provided.
    #
    # If some fields generate validation errors, they will be provided also.
    #
    # For associations, the values can also be a character (Symbol or Model),
    # integers (meaning the default Model * that integer) or arrays of characters.
    #
    #    imagine(:user, :account, :company => :fortune_500_company, :emails => 3)
    #
    # Similarly:
    #
    #    User.imagine(...)
    #    :user.imagine(...)
    #
    # This record (and any other imagined through associations) will become the
    # current character in the current story:
    #
    #    story.current[User] # => nil
    #    story.tell do
    #      :admin.imagine # => A User record
    #      story.current[:admin] # => same
    #      story.current[User]   # => same
    #    end
    #    story.current[User] # => nil
    #
    def imagine(character, attributes = nil)
      prev, @building = @building, [] # because method might be re-entrant
      CharacterBuilder.new(character).build(attributes) do |ar|
        ar.save!
        # While errors on records associated with :has_many will prevent records
        # from being saved, they won't for :belongs_to, so:
        @building.each do |ar|
          ar.valid? and raise ActiveRecord::RecordInvalid, ar.errors unless ar.persisted?
        end
        Scheherazade.log(:saving, character, ar)
        handle_callbacks(@building)
      end
    ensure
      @built.concat(@building)
      @building = prev
    end

    def get(character)
      current[character] || imagine(character)
    end

    # Allows one to temporarily override the current characters while
    # the given block executes
    #
    def with(temp_current, &block)
      old = current.slice(*temp_current.keys)
      current.merge!(temp_current)
      instance_eval(&block)
    ensure
      current.merge!(old)
    end

    def fill(character_or_model, *with)
      fill_attributes[character_or_model] = with
      @characters[character_or_model] = current_fill if character_or_model.is_a? Symbol
      begin
        @filling.push(character_or_model)
        yield
      ensure
        @filling.pop
      end if block_given?
    end

    def after_imagine(&block)
      raise NotImplementedError if current_fill.is_a?(Symbol)
      @after_imagine[current_fill] = block
    end

    alias_method :==, :equal?
    alias_method :eql?, :equal?

    protected
    def current_fill
      @filling.last or raise "Expected to be inside a story.fill"
    end

    def handle_callbacks(on)
      @parent.handle_callbacks(on) if @parent
      on.each do |char|
        if (ai = @after_imagine[char.class])
          ai.yield(char)
        end
      end
    end

    def rollback
      @built.each(&:destroy)
    end

    attr_reader :building
    private :building

  end
end
