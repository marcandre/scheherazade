module Scheherazade

  # A subclass of Hash, with automatic lookup up
  # the story chain and ability to restore the characters
  #
  class CurrentHash < Hash
    def initialize(story)
      @restore = []
      super() do |h, k|
        if (char = story.to_character!(k))
          h[char]
        else
          if up = story.parent
            h[k] = remember(up.current[k])
          end
        end
      end
    end

    # restore all characters borrowed to parent stories
    # to their original state.
    #
    def restore
      @restore.each_slice(3) do |obj, instance_variable_names, values|
        instance_variable_names.zip(values) do |iv, val|
          obj.instance_variable_set(iv, val)
        end
      end
      self
    end

    protected

    # Implementation note: the reason why we remember the object
    # and then reset it, instead of attempting to clone it is
    # that active record doesn't implement a meaningful clone
    # and dup creates a different object altogether.
    #
    # Attempting to clone an AR object, including it's loaded relations
    # would require playing too close to the metal and would be too brittle
    #
    def remember(object)
      return object unless object
      ivs = object.instance_variables
      @restore << object << ivs << ivs.map do |iv|
        v = object.instance_variable_get(iv)
        v = v.clone if v.duplicable?
        v
      end
      object
    end

  end

end