require "net/http"
require "uri"
require "json"
require "active_support/time"

class WeatherController < ApplicationController
  def show
    @latitude = params[:lat]
    @longitude = params[:lng]

    if @latitude.present? && @longitude.present?
      @weather_data = fetch_weather(@latitude, @longitude)
      @forecast_data = fetch_forecast(@latitude, @longitude)
			if @weather_data["message"] == "wrong longitude"
				# TODO: toast message for alert
				redirect_to map_path, alert: "Invalid location."
				return
			end
			@weather = @weather_data["weather"][0]
      @description = @weather["description"].capitalize
      @temperature_in_f = "#{@weather_data["main"]["temp"].round(0)}°F"
      @temperature_in_c = "#{((@weather_data["main"]["temp"] - 32) * 9/5).round(0)}°C"
      @feels_like_in_f = "#{@weather_data["main"]["feels_like"].round(0)}°F"
      @feels_like_in_c = "#{((@weather_data["main"]["feels_like"] - 32) * 9/5).round(0)}°C"
			@location = @weather_data["name"].blank? ? "Unknown Location" : "#{@weather_data["name"]}, #{@weather_data["sys"]["country"]}"

      # TODO: create helper method for timezone
      timezone_offset_seconds = @weather_data["timezone"]
      offset_hours = timezone_offset_seconds / 3600
      offset_minutes = (timezone_offset_seconds % 3600) / 60
      formatted_offset = sprintf("%+03d:%02d", offset_hours, offset_minutes)
      timezone_string = ActiveSupport::TimeZone.all.find { |zone| zone.formatted_offset == formatted_offset }
      @sunrise = Time.at(@weather_data["sys"]["sunrise"]).utc.in_time_zone(timezone_string).strftime("%I:%M %p %Z")
      @sunset = Time.at(@weather_data["sys"]["sunset"]).utc.in_time_zone(timezone_string).strftime("%I:%M %p %Z")
      @max_in_f = "#{@weather_data["main"]["temp_max"].round(0)}°F"
      @max_in_c = "#{((@weather_data["main"]["temp_max"] - 32) * 9/5).round(0)}°C"
      @min_in_f = "#{@weather_data["main"]["temp_min"].round(0)}°F"
      @min_in_c = "#{((@weather_data["main"]["temp_min"] - 32) * 9/5).round(0)}°C"

      @five_day_forecast = @forecast_data["list"].group_by { |entry| entry["dt_txt"].split(" ").first }

      # @five_day_forecast.delete(@forecast_data["list"][0]["dt_txt"].split(" ").first)
      @five_day_forecast.each_with_index do |(date, entries), i|
        day_data = { 
          date: Date.parse(date).strftime("%a %-m/%-d"),
          temp_max: "#{entries.map { |entry| entry['main']['temp_max'] }.max.round(0)}°F",
          temp_min: "#{entries.map { |entry| entry['main']['temp_min'] }.min.round(0)}°F",
          description: (entries.map { |entry| entry["weather"].map { |weather| weather["description"]}}.group_by { |ele| ele }.max_by { |ele, occurrences| occurrences.size }.first).first,
          # This will return the icon for the most common weather description for the day
          icon: (entries.map { |entry| entry["weather"].map { |weather| weather["icon"]}}.group_by { |ele| ele }.max_by { |ele, occurrences| occurrences.size }.first).first,
        }
        instance_variable_set("@day_#{i + 1}", day_data)
      end
    else
      redirect_to map_path, alert: "Invalid location."
    end
  end

  private

  def fetch_weather(lat, lng)
    # TODO: make this secret later
    api_key = "3bc195e34264aed920aed88f03df7554"
    uri = URI("https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lng}&appid=#{api_key}&units=imperial&lang=en")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  def fetch_forecast(lat, lng)
    # TODO: make this secret later
    api_key = "3bc195e34264aed920aed88f03df7554"
    # uri = URI("https://api.openweathermap.org/data/2.5/onecall?lat=#{lat}&lon=#{lng}&appid=#{api_key}")
    uri = URI("https://api.openweathermap.org/data/2.5/forecast?lat=#{lat}&lon=#{lng}&appid=#{api_key}&units=imperial&lang=en")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end
