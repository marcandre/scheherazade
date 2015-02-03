module Scheherazade
  class RedefinitionError < Exception
  end

  class Story < Hash
    attr_reader :fill_attributes, :characters, :counter, :current, :parent

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
        current.send :rollback, opts && opts[:rollback]
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

      def to_character(character_or_model)
        case character_or_model
        when Class
          character_or_model.name.underscore.to_sym
        when Symbol
          character_or_model
        else
          raise ArgumentError, "expected character or Model, got #{character_or_model.ancestors}"
        end
      end

      def to_character!(character_or_model)
        to_character(character_or_model) unless character_or_model.is_a?(Symbol)
      end

      # Returns a Model or nil
      def to_model(character)
        character.to_s.camelize.safe_constantize
      end
    end
    extend ClassMethods
    delegate :begin, :end, :tell, :to_character, :to_character!, :to_model, :to => 'self.class'


    def initialize(parent = self.class.current)
      super(){|h, k| parent[k] if parent }
      @scribe = Scribe.new
      @parent = parent
      @current = Hash.new do |h, k|
        if (char = to_character!(k))
          h[char]
        else
          h[k] = borrow(parent.current[k]) if parent
        end
      end

      @fill_attributes = Hash.new{|h, k| parent.fill_attributes[k] if parent }
      @characters = Hash.new {|h, k| parent.characters[k] if parent }
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
    def imagine(character_or_model, attributes = nil)
      character = to_character(character_or_model)
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
    def with(temp_current)
      keys = temp_current.keys.map{|k| to_character(k)}
      previous_values = current.values_at(*keys)
      current.merge!(Hash[keys.zip(temp_current.values)])
      yield
    ensure
      current.merge!(Hash[keys.zip(previous_values)])
    end

    def fill(character_or_model, *with)
      char = to_character(character_or_model)
      raise RedefinitionError, "#{char} already defined for this story" if fill_attributes.has_key? char
      fill_attributes[char] = with
      @characters[char] = current_fill unless to_model(char)
      begin
        @filling.push(char)
        yield
      ensure
        @filling.pop
      end if block_given?
    end

    def after_imagine(&block)
      raise NotImplementedError unless model = to_model(current_fill)
      @after_imagine[model] = block
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

    def borrow(ar_instance)
      @scribe.memorize(ar_instance)
      ar_instance
    end

    def rollback(hard)
      @scribe.restore_all
      @built.each(&:destroy) if hard
    end

    def building(ar)
      @building << ar if @building # Condition needed in case we use CharacterBuilder outside of call to `imagine`
    end
  end
end
