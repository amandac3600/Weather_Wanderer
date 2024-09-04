require "net/http"
require "uri"
require "json"

class WeatherController < ApplicationController
  def show
    @latitude = params[:lat]
    @longitude = params[:lng]

    if @latitude.present? && @longitude.present?
      @weather = fetch_weather(@latitude, @longitude)
    else
      redirect_to map_path, alert: "Invalid location."
    end
  end

  private

  def fetch_weather(lat, lng)
    # TODO: make this secret later
    api_key = "3bc195e34264aed920aed88f03df7554"
    uri = URI("https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lng}&appid=#{api_key}&units=metric&lang=en")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
