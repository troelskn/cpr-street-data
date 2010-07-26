require 'fileutils'

puts "* Installing cpr-street-data"
plugin_root = File.dirname(__FILE__)
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'
puts "* Copying migrations"

FileUtils.mkdir_p "#{ENV['RAILS_ROOT']}/db/migrate"
FileUtils.cp "#{plugin_root}/db/migrate/20100725121650_create_streets.rb", "#{ENV['RAILS_ROOT']}/db/migrate/20100725121650_create_streets.rb"

