# app/controllers/location_controller.rb
require 'net/http'

class LocationController < ApplicationController
  def index
    @user_entry = params[:location]

    if @user_entry.present?
      # Check if it starts with a number, if so, treat it like a zip code
      @locations = @user_entry.match?(/\A\d/) ? fetch_locations_by_zip(@user_entry) : fetch_locations_by_name(@user_entry)
      if (@locations.is_a?(Array) && @locations.empty?) || (@locations.is_a?(Hash) && @locations["message"] == "not found")
        redirect_to "/", alert: "No results found for #{@user_entry}, please try again."
        return
      end

      if @locations.is_a?(Hash)
        redirect_to weather_path(lat: @locations["lat"], lng: @locations["lon"])
      elsif @locations.is_a?(Array) && @locations.size == 1
        redirect_to weather_path(lat: @locations[0]["lat"], lng: @locations[0]["lon"])
      end
    end
  end

	def search
    search = params[:q]
    if search.present?
			# Check if it starts with a number, if so, treat it like a zip code
			locations = search.match?(/\A\d/) ? fetch_locations_by_zip(search) : fetch_locations_by_name(search)
			if locations.is_a?(Hash)
				render json: {results: 
												[{ id: locations['name'], 
													 text: locations["state"].present? ? "#{locations['name']}, #{locations['state']}, #{locations['country']}" : "#{locations['name']}, #{locations['country']}",
													 url: weather_path(lat: locations['lat'], lng: locations['lon'])
													}]}
			else
				render json: {results:
												locations.map { |loc| { id: loc['name'],
																								text: loc["state"].present? ? "#{loc['name']}, #{loc['state']}, #{loc['country']}" : "#{loc['name']}, #{loc['country']}",
																								url: weather_path(lat: loc['lat'], lng: loc['lon'])
																							} }}
			end
    else
      render json: {results: []}
    end
  end

  private

	def fetch_locations_by_name(search)
    api_key = ENV["OPENWEATHER_API_KEY"]
    uri = URI("http://api.openweathermap.org/geo/1.0/direct?q=#{search}&limit=10&appid=#{api_key}")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
	end

  def fetch_locations_by_zip(search)
    api_key = ENV["OPENWEATHER_API_KEY"]
    uri = URI("http://api.openweathermap.org/geo/1.0/zip?zip=#{search}&appid=#{api_key}")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
