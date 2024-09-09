# app/controllers/location_controller.rb
class LocationController < ApplicationController
  def index
		@user_entry = params[:location]

		if @user_entry.present?
			# Check if it starts with a number, if so, treat it like a zip code
			@locations = @user_entry.match?(/\A\d/) ? fetch_locations_by_zip(@user_entry) : fetch_locations_by_name(@user_entry)
			if (@locations.is_a?(Array) && @locations.empty?) || (@locations.is_a?(Hash) && @locations["message"] == "not found")
				redirect_to "/", alert: "Invalid location, please try again."
				return
			end

			if @locations.is_a?(Hash)
        redirect_to weather_path(lat: @locations["lat"], lng: @locations["lon"])
      elsif @locations.is_a?(Array) && @locations.size == 1
				redirect_to weather_path(lat: @locations[0]["lat"], lng: @locations[0]["lon"])
			end
		end
	end

	private

	def fetch_locations_by_name(user_entry)
    api_key = ENV["OPENWEATHER_API_KEY"]
    uri = URI("http://api.openweathermap.org/geo/1.0/direct?q=#{user_entry}&limit=10&appid=#{api_key}")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

	def fetch_locations_by_zip(user_entry)
    api_key = ENV["OPENWEATHER_API_KEY"]
    uri = URI("http://api.openweathermap.org/geo/1.0/zip?zip=#{user_entry}&appid=#{api_key}")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
