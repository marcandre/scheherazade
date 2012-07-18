module Scheherazade
  class CharacterBuilder < Struct.new(:character)
    AUTO = 'Auto'  # Note: must be equal? to AUTO (i.e. same object), not just ==

    def initialize(character)
      super
      @chain = [character]
      while (c = story.characters[@chain.first])
        @chain.unshift c
      end
      @model = Story.to_model(@chain.first)
      story.send :building, @ar = @model.new
      @chain.each{|c| story.current[c] = @ar }
    end

    # builds a character, filling required attributes,
    # default attributes for this type of character and
    # the attributes given.
    #
    # If the built object is invalid, the attributes with
    # errors will also be filled.
    #
    # An invalid object may be returned. In particular, it is
    # possible that it is only invalid because an associated
    # model is not yet valid.
    #
    def build(attribute_list = nil)
      @seq = (story.counter[@model] += 1)
      lists = [required_attributes, *default_attribute_lists, attribute_list]
      attribute_list = lists.map{|al| canonical(al)}.inject(:merge)
      log(:building, attribute_list)
      set_attributes(attribute_list)
      unless @ar.valid?
        attribute_list = canonical(@ar.errors.map{|attr, _| attr})
        log(:fixing_errors, attribute_list)
        set_attributes(attribute_list)
      end
      yield @ar if block_given?
      log(:final_value, @ar)
      @ar
    end

  private
    def log(action, *args)
      Scheherazade.log(action, @model, *args)
    end

    def required_attributes
      @model.validators.select{|v| v.is_a?(ActiveModel::Validations::PresenceValidator) && v.options.empty?}
            .flat_map(&:attributes)
    end

    def default_attribute_lists
      story.fill_attributes.values_at(*@chain)
    end

    def set_attributes(attributes)
      attributes.each do |attr, value|
        set_attribute(attr, value)
      end
    end

    def set_attribute(attribute, value = AUTO)
      if assoc = @model.reflect_on_association(attribute)
        # It's possible that build records are not yet valid, so we
        # can expect errors on associations. At least for these reasons:
        return if @ar.send(attribute).present?

        value = assoc.klass.name.underscore.to_sym if value == AUTO
        value = value_for_association(assoc, value)
      elsif value.equal?(AUTO)
        value = automatic_value_for_basic_attribute(attribute)
      end
      log :setting, attribute, value
      @ar.send("#{attribute}=", value)
    end

    def value_for_association(assoc, associated_character)
      log(:setting_assocation, associated_character)
      key = assoc.options[:as] || assoc.active_record.name.underscore.to_sym
      opts = {key => @ar} if [:has_many, :has_one].include? assoc.macro
      ar =  if associated_character.is_a?(Symbol)
              story.current[associated_character] || self.class.new(associated_character).build(opts)
            else
              associated_character
            end
      case assoc.macro
      when :belongs_to
        ar
      when :has_and_belongs_to_many
        [ar]
      when :has_one
        ar
      when :has_many
        if ar && ar.persisted?
          if ar.send(assoc.active_record.name.underscore) != @ar
            log :additional_character, assoc.name
            [self.class.new(associated_character).build(opts)]
          else
            [ar]
          end
        else
          [*ar]
        end
      end
    end

    def automatic_value_for_basic_attribute(attribute)
      seq_string = " {#{@seq}}" if @seq > 1
      case @model.columns_hash[attribute.to_s].try(:type)
      when :integer  then @seq
      when :float    then @seq
      when :decimal  then "#{@seq}.99"
      when :datetime then Time.now - 1.day + @seq
      when :date     then Date.today - 1.year + @seq
      when :string   then
        case attribute
        when :email
          "joe#{@seq}@example.com"
        when :name, :title
          "Example #{@model.name.humanize}#{seq_string}"
        else "Some #{attribute}#{seq_string}"
        end
      when :text     then "Some #{attribute} text#{seq_string}"
      when :boolean  then false
      else
        if enum = @model.enum_definitions[attribute]
          @model.send(attribute.to_s.pluralize).keys.first
        else
          puts "Unknown type for #{@model}##{attribute}"
          nil
        end
      end
    end

    # Converts an attribute_list to a single Hash;
    # some of the values may be set to AUTO.
    #
    #   canonical [:foo, {:bar => 42}]
    #    # => {:foo => AUTO, :bar => 42}
    #
    def canonical(attribute_list)
      case attribute_list
      when nil then {}
      when Hash then attribute_list
      when Array
        attribute_list.map do |attributes|
          case attributes
          when Symbol
            {attributes => AUTO}
          when Hash
            attributes
          else
            raise "Unexpected attributes #{attributes}"
          end
        end
        .inject({}, :merge)
      else
        raise "Unexpected attribute_list #{attribute_list}"
      end
    end

    def story
      Story.current
    end
  end
end
