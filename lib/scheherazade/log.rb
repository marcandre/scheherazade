module Scheherazade
  class Logger
    EVENTS = [:saving, :building, :fixing_errors, :final_value, :setting_assocation, :setting, :additional_character].to_set.freeze

    def off
      @events = []
    end

    def on
      only
    end

    def only *events_and_characters
      events_and_characters = events_and_characters.to_set
      @events = (EVENTS & events_and_characters).presence || EVENTS
      @characters = (events_and_characters - @events).to_set.presence
    end

    def log(event, character, *rest)
      if @events && @events.include?(event) && (@characters.nil? || @characters.include?(character))
        puts "#{character}: #{rest.unshift(event).join(' | ')}"
      end
    end
  end

  def self.logger
    Thread.current[:scheherazade_logger] ||= Logger.new
  end

  def self.log(*args)
    logger.log(*args)
  end
end
