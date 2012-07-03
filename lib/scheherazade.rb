require_relative "scheherazade/bare"

# Scheherazade publishes a method imagine for characters:
ActiveRecord::Base.extend Scheherazade::Extension # models
Symbol.send :include, Scheherazade::Extension     # and symbols

# as well as a global shortcut to get the current story.
def story
  Scheherazade::Story.current
end

# Require directly "scheherazade/bare" if you don't want these.
