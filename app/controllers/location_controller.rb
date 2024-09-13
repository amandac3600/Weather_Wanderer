# app/controllers/location_controller.rb
require "net/http"

class LocationController < ApplicationController
  def search
    search = params[:q]
    if search.present?
      # Check if it starts with a number, if so, treat it like a zip code
      locations = search.match?(/\A\d/) ? fetch_locations_by_zip(search) : fetch_locations_by_name(search)
      if locations.is_a?(Hash)
        render json: { results:
                        [ { id: locations["name"],
                           text: locations["state"].present? ? "#{locations["name"]}, #{locations["state"]}, #{locations["country"]}" : "#{locations["name"]}, #{locations["country"]}",
                           url: weather_path(lat: locations["lat"], lng: locations["lon"])
                        } ]
                     }
      else
        render json: { results:
                       locations.map { |loc| { id: loc["name"],
                                               text: loc["state"].present? ? "#{loc["name"]}, #{loc["state"]}, #{loc["country"]}" : "#{loc["name"]}, #{loc["country"]}",
                                               url: weather_path(lat: loc["lat"], lng: loc["lon"])
                                             }
                                     }
                     }
      end
    else
      render json: { results: [] }
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
