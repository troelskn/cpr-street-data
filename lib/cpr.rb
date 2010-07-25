# -*- coding: utf-8 -*-
require 'iconv'

# Cpr parser
module Cpr

  # Parser that reads CPR's fixed-width format
  # and emits records to a writer
  class Reader

    def initialize(file_name)
      @file_name = file_name
    end

    def clean_hash(hash)
      hash.inject({}) { |h,(k,v)|
        h[k] = if v.kind_of? String
                 Iconv.conv("UTF8", "LATIN1", v.strip)
               else
                 v
               end
        h
      }
    end

    def run(writer)
      File.open(@file_name, "r") do |infile|
        while (line = infile.gets)
          case line.slice(0, 3)
          when "001"
            line.gsub! /\r\n$/, ""
            record = {
              :type => :street,
              :municipality_id => line.slice(3, 4).to_i,
              :street_id => line.slice(7, 4).to_i,
              :timestamp => line.slice(11, 12),
              :to_municipality_id => line.slice(23, 4).to_i,
              :to_street_id => line.slice(27, 4).to_i,
              :from_municipality_id => line.slice(31, 4).to_i,
              :from_street_id => line.slice(36, 4).to_i,
              :haenstart => line.slice(39, 12),
              :name => line.slice(71, 40)
            }
            record[:unique_id] = (record[:municipality_id] * 10000) + record[:street_id]
            writer.handle_street(clean_hash(record))
          when "004"
            line.gsub! /\r\n$/, ""
            record = {
              :type => :zip,
              :municipality_id => line.slice(3, 4).to_i,
              :street_id => line.slice(7, 4).to_i,
              :number_from => line.slice(11, 4),
              :number_to => line.slice(15, 4),
              :even => line.slice(19, 1) == "L",
              :timestamp => line.slice(20, 12),
              :zip_code => line.slice(32, 4),
              :name => line.slice(36, 20),
            }
            record[:unique_id] = (record[:municipality_id] * 10000) + record[:street_id]
            writer.handle_zip(clean_hash(record))
          end
        end
      end
      writer.finalize!
    end
  end

  # ActiveRecord-writer
  # Creates Street entries
  class Writer
    def handle_street(row)
      record = Street.find(:first, :conditions => { :uuid => row[:unique_id] })
      record ||= Street.new(:uuid => row[:unique_id])
      record.street_name = row[:name]
      record.save!
    end

    def handle_zip(row)
      record = Street.find(:first, :conditions => { :uuid => row[:unique_id] })
      record ||= Street.new(:uuid => row[:unique_id])
      record.zip_code = row[:zip_code]
      record.city_name = row[:name]
      record.save!
    end

    # Deletes duplicate entries and removes bogus records (zip=9999)
    def finalize!
      Street.connection.execute "DELETE FROM streets WHERE zip_code = '9999'"
      streets = Street.find_by_sql "SELECT MIN(id) AS id, street_name, zip_code FROM streets GROUP BY street_name, zip_code HAVING COUNT(*) > 1"
      streets.each do |street|
        sql = sprintf(
                      "DELETE FROM streets WHERE street_name = '%s' AND zip_code = '%s' AND id != %d",
                      Street.connection.quote_string(street.street_name),
                      Street.connection.quote_string(street.zip_code),
                      street.id)
        Street.connection.execute sql
      end
    end
  end

end

