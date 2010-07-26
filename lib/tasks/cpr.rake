# -*- coding: utf-8 -*-
namespace :cpr do

  desc "Populates Streets table from CPR data."
  task :import => :environment do
    file_name = ENV['infile'] || "#{RAILS_ROOT}/tmp/A370715.txt"
    ActiveRecord::Base.transaction do
      reader = Cpr::Reader.new(file_name)
      reader.run(Cpr::Writer.new)
    end
  end

  namespace :yaml do

    desc "Populates Streets table from YAML dump"
    task :import => :environment do
      file_name = ENV['infile'] || "#{RAILS_ROOT}/tmp/streets.yml"
      ActiveRecord::Base.transaction do
        data = YAML.load_file(file_name)
        data.each do |yaml|
          Street.create yaml.ivars["attributes"]
        end
      end
    end

    desc "Dump Streets table to YAML"
    task :export => :environment do
      file_name = ENV['outfile'] || "#{RAILS_ROOT}/tmp/streets.yml"
      File.open(file_name, 'w') do |file|
        YAML::dump(Street.all, file)
      end
    end

  end

end
