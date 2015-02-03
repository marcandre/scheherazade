require 'active_record'

%w[scribe log story character_builder extension].each do |lib|
  require_relative lib
end
