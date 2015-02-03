class Scribe
  # A Scribe can make copies of active_record objects
  # so that they can be later restored to their previous state
  # including their attributes and associations.

  class Memo
    def initialize(object)
      @object = object
      memorize
    end

    def restore
      @clone.association_cache.each do |k, v|
        copy_instance_var(@clone.association_cache[k], @object.association_cache[k])
        # Now that we have overwritten the object's association, reuse the exact same object
        @clone.association_cache[k] = @object.association_cache[k]
      end
      @object.association_cache.replace(@clone.association_cache)
      copy_instance_var(@clone, @object)
    end

    private

    def memorize
      @clone = @object
      clone_instance_var(self, :@clone)
      clone_instance_var(@clone, :@attributes)
      if cache = clone_instance_var(@clone, :@association_cache)
        cache.each do |k, v|
          cache[k] = v.clone
          clone_instance_var(cache[k], :@target)
        end
      end
    end

    def copy_instance_var(source, dest, ivars = source.instance_variables)
      [*ivars].each do |ivar|
        dest.instance_variable_set(ivar, source.instance_variable_get(ivar))
      end
    end

    def clone_instance_var(source, ivar)
      value = source.instance_variable_get(ivar)
      if value.duplicable?
        value = value.clone
        source.instance_variable_set(ivar, value)
      end
      value
    end
  end

  def initialize
    @memos = {}
  end

  def memorize(ar_instance)
    return if ar_instance.nil? || @memos[ar_instance.object_id]
    @memos[ar_instance.object_id] = Memo.new(ar_instance)
    ar_instance.class.reflections.each do |name, info|
      if assoc = ar_instance.send(:association_instance_get, name)
        if assoc.loaded?
          loaded = ar_instance.send(name)
          if info.collection?
            loaded.each { |r| memorize(r) }
          else
            memorize(loaded)
          end
        end
      end
    end

    ar_instance
  end

  def restore_all
    @memos.values.each(&:restore)
  end
end
