# frozen_string_literal: true
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'consts'
require 'singleton'

class Stations
  include Singleton

  def initialize
    @map = {}
    @cache_file = "stations_cached.json"

    @url_stations = URI("https://flixbus.p.rapidapi.com/v1/stations")
    @url_timetable = "https://flixbus2.p.rapidapi.com/schedule"

    if File.file? @cache_file
      open_cache
    else
      setup
    end

  end

  def get_city(city_name)
    puts "=== Get city stage ==="

    list_of_stations = []
    @map.each do |id, station|
      if station["city_name"].include?(city_name.downcase) ||
        station["slugs"].include?(city_name.downcase) ||
        station["aliases"].include?(city_name.downcase)
        list_of_stations.append({ "id" => id, "station" => station })
      end
    end

    list_of_stations
  end

  def get_departures(city, date)
    url = URI("#{@url_timetable}?station_id=#{city["id"]}&date=#{date}")

    station_departures = JSON.parse get_from(url, HEADERS_SCHEDULES)
    station_departures = station_departures["schedule"]["departures"]
    result = []

    station_departures.each do |departure|
      departure["stops"].each do |stop|
        unless result.include?(stop["direction"])
          result.append(
            {
              "station" => stop["name"],
              "country" => get_country(stop["uuid"])
            }
          )
        end
      end
    end
    {"from" => city["station"]["station_name"], "id" => city["id"], "date" => date, "direct_to" => result}

  end

  private

  def retrieve
    puts "=== retrieve =="
    @all = JSON.parse get_from(@url_stations, HEADERS_STATIONS)
  end

  def remap
    puts "=== remap ==="
    @all.each do |station|
      @map[station["uuid"]] = {
          "city_name" => station["city_name"],
          "station_name" => station["name"],
          "country" => station["country"],
          "slugs" => station["slugs"],
          "aliases" => station["aliases"]
        }
    end
  end

  def setup
    puts "=== Running setup ==="
    retrieve
    remap

    File.write @cache_file, JSON.pretty_generate(@map)
  end

  def open_cache
    puts "=== Opening existing cache ==="
    file = File.open @cache_file
    @map = JSON.parse file.read
  end

  def get_country(station_id)
    if @map[station_id]
      return @map[station_id]["country"]["name"]
    end
    "-"
  end

  def get_from(url, headers)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["X-RapidAPI-Key"] = headers.fetch(:"X-RapidAPI-Key")
    request["X-RapidAPI-Host"] = headers.fetch(:"X-RapidAPI-Host")
    response = http.request(request)
    response.body
  end

end
