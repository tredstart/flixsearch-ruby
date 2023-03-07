class FlixsearchController < ApplicationController
  before_action :get_stations, :get_filename

  def index

    if File.file? @filename
      file = File.open @filename
      @results = JSON.parse(file.read)
    else
      @results = []
    end
  end

  def create
    begin
      date = params.require(:date)
      city = params.require(:city)

    rescue
      render :index, status: :unprocessable_entity
    else
      if date.empty? || city.empty?
        render :index, status: :unprocessable_entity
      else
        date = Date.parse date
        date = date.strftime("%d.%m.%Y")
        cities = @stations.get_city(city)
        if cities.empty?
          render :index, status: :unprocessable_entity
        end
        @results = []
        cities.each do |c|
          @results.append @stations.get_departures(c, date)
        end

        # file = File.open @filename
        # @results = JSON.parse file.read

        @results.each do |stop|
          stop["direct_to"] = stop["direct_to"].sort_by { |key| key["country"] }
        end

        File.write @filename, JSON.pretty_generate(@results)

        respond_to do |format|
          format.html { redirect_to root_path, notice: "Successful request" }
          format.turbo_stream
        end
      end
    end
  end

  private

  def get_stations
    @stations = Stations.instance
  end

  def get_filename
    @filename = "result_#{session.id}.json"
  end

end
