class Street < ActiveRecord::Base
  def self.autocomplete(query)
    return nil if query.match /[0-9]{4}/ # Assume zip code is part of query, and don't try to complete it
    q = query.to_s.downcase.strip
    match = q.match /^([^0-9,]+)([,0-9]+).*$/
    if match
      q = match[1].strip
    end
    streets = self.find(:all,
                        :conditions => ["LOWER(street_name) LIKE ?", "%#{q}%"],
                        :order => "street_name ASC",
                        :limit => 10)
    if match
      streets.map{|street| "#{street.street_name} #{match[2].strip}, #{street.zip_code} #{street.city_name}" }
    else
      streets.map{|street| street.street_name }
    end.uniq
  end
end
