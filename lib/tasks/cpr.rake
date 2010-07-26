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
        data.each do |fixture|
          Street.new(:street_name => fixture.street_name, :zip_code => fixture.zip_code, :city_name => fixture.city_name, :uuid => fixture.uuid).save!
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

  namespace :xml do

    desc "Dump Streets table to XML"
    task :export => :environment do
      file_name = ENV['outfile'] || "#{RAILS_ROOT}/tmp/streets.xml"
      File.open(file_name, 'w') do |file|
        file.write '<?xml version="1.0" encoding="UTF-8"?>'
        file.write '<streets>'
        Street.all.each do |street|
          xml = '<street>'
          xml << '<street_name>' + CGI::escapeHTML(street.street_name) + '</street_name>'
          xml << '<zip_code>' + CGI::escapeHTML(street.zip_code) + '</zip_code>'
          xml << '<city_name>' + CGI::escapeHTML(street.city_name) + '</city_name>'
          xml << '<uuid>' + CGI::escapeHTML(street.uuid.to_s) + '</uuid>'
          xml << '</street>'
          file.write xml
        end
        file.write '</streets>'
      end
    end

    desc "Populates Streets table from XML dump. Reads from a URL."
    task :import => :environment do
      url = ENV['inurl'] || "http://github.com/troelskn/cpr-street-data/raw/master/tmp/streets.xml"
      require 'eventmachine'
      require 'em-http'
      require 'nokogiri'

      class SAXHandler < Nokogiri::XML::SAX::Document
        def initialize
          super
          @street = {}
          @current_tag = nil
        end

        def start_element(name, attrs=[])
          if name == "street"
            @street = {}
          end
          @current_tag = name.to_sym
        end

        def characters(text)
          @street[@current_tag] = "" unless @street[@current_tag]
          @street[@current_tag] << text
        end

        def end_element(name)
          if name == "street"
            begin
              puts ">>> Processing #{street.to_json}"
              unless Street.first(:conditions => {:uuid => @street.uuid}).any?
                Street.new(@street).save!
              end
            rescue Error => err
              p err
            end
          end
        end

      end

      ActiveRecord::Base.transaction do
        handler = SAXHandler.new
        EventMachine.run do
          io_read, io_write = IO.pipe
          EventMachine.defer(proc {
                               parser = Nokogiri::XML::SAX::Parser.new(handler)
                               parser.parse_io(io_read)
                             })
          http = EventMachine::HttpRequest.new(url).get
          http.stream { |chunk| io_write << chunk }
          http.callback { EventMachine.stop }
        end
      end

    end

  end

end
