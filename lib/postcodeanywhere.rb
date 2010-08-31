require 'HTTParty'

module PostcodeAnywhere
  
  ADDRESS_LOOKUP = "http://services.postcodeanywhere.co.uk/xml.aspx"
  ADDRESS_FETCH = "http://services.postcodeanywhere.co.uk/dataset.aspx?action=fetch"
  
  class Request
    def self.account_code
      @@account_code
    end
    def self.account_code=(account_code)
      @@account_code = account_code
    end
    def self.license_code
      @@license_code
    end
    def self.license_code=(license_code)
      @@license_code = license_code
    end
  end
  
  class PostcodeSearch < Request
  
  	include HTTParty
  	format :xml

  	attr_accessor :postcode, :country_name, :fetch_id

    def initialize(args={})
      self.postcode = args[:postcode]
      self.country_name = args[:country_name]
    end

  	def lookup
  		data = PostcodeSearch.get self.lookup_url
  		formatted_data = []
  		unless data["PostcodeAnywhere"]["Schema"]["Field"][0]["Name"] == "error_number"
  		  formatted_data = data["PostcodeAnywhere"]["Data"]["Item"]
  		end
  		formatted_data
  	end
	
  	def fetch
  		data = PostcodeSearch.get self.fetch_url
  		formatted_data = data["NewDataSet"]["Data"]
  		@address_lookup = AddressLookup.new
      if @postcode_search.country.name == 'United Kingdom'
        @address_lookup.postcode = formatted_data["postcode"]
        @address_lookup.address_line_1 = formatted_data["line1"]
        @address_lookup.address_line_2 = formatted_data["line2"]
        @address_lookup.address_line_3 = formatted_data["line3"]
        @address_lookup.post_town = formatted_data["post_town"]
        @address_lookup.county = formatted_data["county"].blank? ? formatted_data["post_town"] : formatted_data["county"]
      elsif @postcode_search.country.name == 'United States'
        @address_lookup.postcode = formatted_data["zip4"].blank? ? @postcode_search.postcode : formatted_data["zip4"]
        @address_lookup.address_line_1 = formatted_data["line1"]
        @address_lookup.address_line_2 = formatted_data["line2"]
        @address_lookup.address_line_3 = formatted_data["line3"]
        @address_lookup.post_town = formatted_data["city"]
        @address_lookup.county = formatted_data["county_name"]+", "+formatted_data["state"]
      else

      end
      @address_lookup
  	end

  	def lookup_url
  		ADDRESS_LOOKUP+"?"+self.lookup_type+"&"+self.postcode_with_no_spaces+"&"+self.country_code+"&"+self.license_information
  	end

  	def fetch_url
  		ADDRESS_FETCH+"&"+self.address_fetch_id+"&"+self.country_code+"&"+self.license_information
  	end
	
  	def country
  	  Country.find_by_name(self.country_name)
  	end

  	def address_fetch_id
  		"id="+self.fetch_id
  	end

  	def lookup_type
  		if self.country.name == "United Kingdom"
  			"action=lookup&type=by_postcode"
  		elsif self.country.name == "United States"
  			"action=lookup&type=by_zip"
  		else
  			"action=international&type=fetch_streets"
  		end
  	end

  	def country_code
  		"country="+self.country.code
  	end

  	def postcode_with_no_spaces
  		(self.country.name=="United States" ? "zip=" : "postcode=")+self.postcode.gsub(/\s/, '')
  	end

  	def license_information
  		"account_code="+self.account_code+"&license_code="+self.license_code
  	end
  
  end

  class AddressLookup
  
    attr_accessor :postcode, :address_line_1, :address_line_2, :address_line_3, :post_town, :county
    attr_accessor :city, :county_name, :zip4, :state
    
  end
end