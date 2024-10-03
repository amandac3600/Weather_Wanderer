require "net/http"
require "uri"
require "json"
require "active_support/time"

class WeatherController < ApplicationController
  def show
    @latitude = params[:lat]
    @longitude = params[:lng]
    @from_map = params[:from_map]

    if @latitude.present? && @longitude.present?
      @weather_data = fetch_weather(@latitude, @longitude)
      @forecast_data = fetch_forecast(@latitude, @longitude)

      if @weather_data["message"] == "wrong longitude" || @weather_data["message"] == "wrong latitude"
        redirect_to map_path, alert: "Invalid location, please try again."
        return
      end

      @weather = @weather_data["weather"][0]
      @description = @weather["description"].capitalize

      calculate_location_time_and_name(@weather_data)
      current_date = Time.now.strftime("%Y-%m-%d")
      # TODO: get this based off location's timezone
      calculate_daily_min_max(@forecast_data, current_date)
      calculate_sun_rise_and_set(@weather_data)
      calculate_temperature(@weather_data)
      calculate_extra_data(@weather_data)
      five_day_forecast(@forecast_data)
    else
      redirect_to map_path, alert: "Invalid location, please try again."
    end
  end

  private

  def fetch_weather(lat, lng)
    api_key = ENV["OPENWEATHER_API_KEY"]
    uri = URI("https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lng}&appid=#{api_key}&units=imperial&lang=en")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  def fetch_forecast(lat, lng)
    api_key = ENV["OPENWEATHER_API_KEY"]
    uri = URI("https://api.openweathermap.org/data/2.5/forecast?lat=#{lat}&lon=#{lng}&appid=#{api_key}&units=imperial&lang=en")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  def get_location_local_time(timezone_offset)
    utc_time = Time.now.utc
    local_time = utc_time + timezone_offset
    local_time.strftime("%I:%M %p, %b %d") # E.g., "02:30 PM, Sep 05"
  end

  def calculate_location_time_and_name(weather_data)
    timezone_offset = weather_data["timezone"]
    @location_local_time = get_location_local_time(timezone_offset)

    # TODO: add state to location
    @location_name = weather_data["name"].blank? ? "Unknown Location" : "#{weather_data["name"]}, #{weather_data["sys"]["country"]}"
  end

  def calculate_temperature(weather_data)
    @temperature_in_f = "#{weather_data["main"]["temp"].round(0)}°F"
    @temperature_in_c = "#{((weather_data["main"]["temp"] - 32) * 9/5).round(0)}°C"
    @feels_like_in_f = "#{weather_data["main"]["feels_like"].round(0)}°F"
    @feels_like_in_c = "#{((weather_data["main"]["feels_like"] - 32) * 9/5).round(0)}°C"
  end

  def calculate_daily_min_max(forecast_data, date)
    # TODO: dry this up
    daily_temperatures = forecast_data["list"].select do |data_point|
      Time.at(data_point["dt"]).strftime("%Y-%m-%d") == date
    end.map { |data_point| data_point["main"]["temp"] }

    if daily_temperatures.length == 0
      daily_temperatures = forecast_data["list"].select do |data_point|
        Time.at(data_point["dt"]).strftime("%Y-%m-%d") == (Time.now + 1.day).strftime("%Y-%m-%d")
      end.map { |data_point| data_point["main"]["temp"] }
    end

    @max_in_f = daily_temperatures.length > 0 ? "#{daily_temperatures.max.round(0)}°F" : @temperature_in_f
    @max_in_c = daily_temperatures.length > 0 ? "#{((daily_temperatures.max.round(0) - 32) * 9/5).round(0)}°C" : @temperature_in_c
    @min_in_f = daily_temperatures.length > 0 ? "#{daily_temperatures.min.round(0)}°F" : @temperature_in_f
    @min_in_c = daily_temperatures.length > 0 ? "#{((daily_temperatures.min.round(0)- 32) * 9/5).round(0)}°C" : @temperature_in_c
  end

  def calculate_sun_rise_and_set(weather_data)
    timezone_offset_seconds = weather_data["timezone"]
    offset_hours = timezone_offset_seconds / 3600
    offset_minutes = (timezone_offset_seconds % 3600) / 60
    formatted_offset = sprintf("%+03d:%02d", offset_hours, offset_minutes)
    timezone_string = ActiveSupport::TimeZone.all.find { |zone| zone.formatted_offset == formatted_offset }

    @sunrise = Time.at(weather_data["sys"]["sunrise"]).utc.in_time_zone(timezone_string).strftime("%I:%M %p")
    @sunset = Time.at(weather_data["sys"]["sunset"]).utc.in_time_zone(timezone_string).strftime("%I:%M %p")
  end

  def calculate_extra_data(weather_data)
    @humidity = "#{weather_data["main"]["humidity"]}%"
    @pressure = "#{(weather_data["main"]["pressure"]* 0.02953).round(2)} inHg" # convert hPa to inHg
    @visibility = "#{(weather_data["visibility"] * 0.000621371).round(1)} mi" # convert meters to miles
    @wind_direction = wind_direction(weather_data["wind"]["deg"])
    @wind_speed = "#{weather_data["wind"]["speed"]} mph"
  end

  def five_day_forecast(forecast_data)
    @five_day_forecast = forecast_data["list"].group_by { |entry| entry["dt_txt"].split(" ").first }

    @five_day_forecast.each_with_index do |(date, entries), i|
      icon = (entries.map { |entry| entry["weather"].map { |weather| weather["icon"] } }.group_by { |ele| ele }.max_by { |ele, occurrences| occurrences.size }.first).first
      day_data = {
        date: Date.parse(date).strftime("%a %-m/%-d"),
        temp_max: "#{entries.map { |entry| entry['main']['temp_max'] }.max.round(0)}°F",
        temp_min: "#{entries.map { |entry| entry['main']['temp_min'] }.min.round(0)}°F",
        description: (entries.map { |entry| entry["weather"].map { |weather| weather["description"] } }.group_by { |ele| ele }.max_by { |ele, occurrences| occurrences.size }.first).first,
        # This will return the icon for the most common weather description for the day, making sure to show the day icon instead of the night icon
        icon: icon.gsub("n", "d")
      }
      instance_variable_set("@day_#{i + 1}", day_data)
    end
  end

  def wind_direction(deg)
    case deg
    when 0..22.5, 337.5..360
      "N"
    when 22.5..67.5
      "NE"
    when 67.5..112.5
      "E"
    when 112.5..157.5
      "SE"
    when 157.5..202.5
      "S"
    when 202.5..247.5
      "SW"
    when 247.5..292.5
      "W"
    when 292.5..337.5
      "NW"
    else
      "Unknown direction"
    end
  end
end
