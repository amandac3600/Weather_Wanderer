require "net/http"
class GameController < ApplicationController
  LOCATIONS = [
    { name: "New York", country: "USA", latitude: 40.7128, longitude: -74.0060 },
    { name: "London", country: "UK", latitude: 51.5074, longitude: -0.1278 },
    { name: "Tokyo", country: "Japan", latitude: 35.6895, longitude: 139.6917 },
    { name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522 },
    { name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093 },
    { name: "Toronto", country: "Canada", latitude: 43.6532, longitude: -79.3832 },
    { name: "Berlin", country: "Germany", latitude: 52.5200, longitude: 13.4050 },
    { name: "Dubai", country: "UAE", latitude: 25.276987, longitude: 55.296249 },
    { name: "Moscow", country: "Russia", latitude: 55.7558, longitude: 37.6173 },
    { name: "Mumbai", country: "India", latitude: 19.0760, longitude: 72.8777 },
    { name: "Beijing", country: "China", latitude: 39.9042, longitude: 116.4074 },
    { name: "São Paulo", country: "Brazil", latitude: -23.5505, longitude: -46.6333 },
    { name: "Mexico City", country: "Mexico", latitude: 19.4326, longitude: -99.1332 },
    { name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357 },
    { name: "Los Angeles", country: "USA", latitude: 34.0522, longitude: -118.2437 },
    { name: "Bangkok", country: "Thailand", latitude: 13.7563, longitude: 100.5018 },
    { name: "Buenos Aires", country: "Argentina", latitude: -34.6037, longitude: -58.3816 },
    { name: "Rome", country: "Italy", latitude: 41.9028, longitude: 12.4964 },
    { name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784 },
    { name: "Lagos", country: "Nigeria", latitude: 6.5244, longitude: 3.3792 },
    { name: "Hong Kong", country: "China", latitude: 22.3193, longitude: 114.1694 },
    { name: "Lima", country: "Peru", latitude: -12.0464, longitude: -77.0428 },
    { name: "Jakarta", country: "Indonesia", latitude: -6.2088, longitude: 106.8456 },
    { name: "Madrid", country: "Spain", latitude: 40.4168, longitude: -3.7038 },
    { name: "Karachi", country: "Pakistan", latitude: 24.8607, longitude: 67.0011 },
    { name: "Nairobi", country: "Kenya", latitude: -1.286389, longitude: 36.817223 },
    { name: "Seoul", country: "South Korea", latitude: 37.5665, longitude: 126.9780 },
    { name: "Johannesburg", country: "South Africa", latitude: -26.2041, longitude: 28.0473 },
    { name: "Melbourne", country: "Australia", latitude: -37.8136, longitude: 144.9631 },
    { name: "Riyadh", country: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753 },
    { name: "Singapore", country: "Singapore", latitude: 1.3521, longitude: 103.8198 },
    { name: "Kuala Lumpur", country: "Malaysia", latitude: 3.1390, longitude: 101.6869 },
    { name: "Casablanca", country: "Morocco", latitude: 33.5731, longitude: -7.5898 },
    { name: "Hanoi", country: "Vietnam", latitude: 21.0285, longitude: 105.8542 },
    { name: "Cape Town", country: "South Africa", latitude: -33.9249, longitude: 18.4241 },
    { name: "Barcelona", country: "Spain", latitude: 41.3851, longitude: 2.1734 },
    { name: "Athens", country: "Greece", latitude: 37.9838, longitude: 23.7275 },
    { name: "Manila", country: "Philippines", latitude: 14.5995, longitude: 120.9842 },
    { name: "Budapest", country: "Hungary", latitude: 47.4979, longitude: 19.0402 },
    { name: "Tehran", country: "Iran", latitude: 35.6892, longitude: 51.3890 },
    { name: "Baghdad", country: "Iraq", latitude: 33.3152, longitude: 44.3661 },
    { name: "Warsaw", country: "Poland", latitude: 52.2297, longitude: 21.0122 },
    { name: "Kabul", country: "Afghanistan", latitude: 34.5553, longitude: 69.2075 },
    { name: "Vienna", country: "Austria", latitude: 48.2082, longitude: 16.3738 },
    { name: "Stockholm", country: "Sweden", latitude: 59.3293, longitude: 18.0686 },
    { name: "Brussels", country: "Belgium", latitude: 50.8503, longitude: 4.3517 },
    { name: "Santiago", country: "Chile", latitude: -33.4489, longitude: -70.6693 },
    { name: "Porto", country: "Portugal", latitude: 41.1579, longitude: -8.6291 },
    { name: "Prague", country: "Czech Republic", latitude: 50.0755, longitude: 14.4378 }
  ]

	def home
	end

	def play
		if session[:location_name].nil?
      random_weather = fetch_weather_for_location(LOCATIONS.sample)
      random_forecast = fetch_forecast_for_location(LOCATIONS.sample)
    else
      random_weather = fetch_weather(session[:latitude], session[:longitude])
      random_forecast = fetch_forecast(session[:latitude], session[:longitude])
    end

		@location_name = random_weather["name"]
		@weather = random_weather["weather"][0]
		@description = @weather["description"].capitalize
		calculate_location_time_and_name(random_weather)
		current_date = Time.now.strftime("%Y-%m-%d")
		# TODO: get this based off location's timezone
    calculate_daily_min_max(random_forecast, current_date)
		calculate_sun_rise_and_set(random_weather)
		calculate_temperature(random_weather)
		calculate_extra_data(random_weather)
	end

	def result
		guessed_lat = params[:lat].to_f
		guessed_lng = params[:lng].to_f
		@latitude = session[:latitude]
		@longitude = session[:longitude]
		@location_name = session[:location_name]
    @country = session[:country]

		@distance = haversine_distance_miles(guessed_lat, guessed_lng, @latitude, @longitude)

    session.delete(:location_name)

    respond_to do |format|
        format.json { render json: { location_name: @location_name, distance: @distance, country: @country } }
    end
	end

	private

	def fetch_weather_for_location(location)
    @latitude = location[:latitude]
    @longitude = location[:longitude]
    weather = fetch_weather(@latitude, @longitude)

		session[:latitude] = @latitude
		session[:longitude] = @longitude
		session[:location_name] = location[:name]
    session[:country] = location[:country]

    weather
	end

  def fetch_forecast_for_location(location)
    @latitude = location[:latitude]
    @longitude = location[:longitude]
    forecast = fetch_forecast(@latitude, @longitude)

    forecast
  end

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
    daily_temperatures = forecast_data["list"].select do |data_point|
      Time.at(data_point["dt"]).strftime("%Y-%m-%d") == date
    end.map { |data_point| data_point["main"]["temp"] }

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

	# Haversine formula to find distance between 2 locations, which accounts for the curvature of the Earth
	def haversine_distance_miles(lat1, lon1, lat2, lon2)
		# Radius of the Earth in miles
		earth_radius_miles = 3959.0
	
		# Convert latitude and longitude from degrees to radians
		lat1_rad = lat1 * Math::PI / 180
		lon1_rad = lon1 * Math::PI / 180
		lat2_rad = lat2 * Math::PI / 180
		lon2_rad = lon2 * Math::PI / 180
	
		# Differences in coordinates
		delta_lat = lat2_rad - lat1_rad
		delta_lon = lon2_rad - lon1_rad
	
		# Haversine formula
		a = Math.sin(delta_lat / 2)**2 +
				Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(delta_lon / 2)**2
		c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
	
		# Distance in miles
		distance = earth_radius_miles * c
	
		distance.round(2)
	end

end
