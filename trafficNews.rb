#!ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'hpricot'
require 'open-uri'
require 'time'
require 'date'

def relative_date(date)
  date = Date.parse(date, true) unless /Date.*/ =~ date.class.to_s
  days = (date - Date.today).to_i
  
  return 'today'     if days >= 0 and days < 1
  return 'tomorrow'  if days >= 1 and days < 2
  return 'yesterday' if days >= -1 and days < 0
  
  return "in #{days} days"      if days.abs < 60 and days > 0
  return "#{days.abs} days ago" if days.abs < 60 and days < 0
  
  return date.strftime('%A, %B %e') if days.abs < 182
  return date.strftime('%A, %B %e, %Y')
end

class TrafficDatum
  attr_accessor :Location
  attr_accessor :Report
  attr_accessor :LastUpdated
end

class Route
  attr_accessor :Name
  attr_accessor :Roads
end

class BBCBerkshireTrafficSource
  def name()
    "BBC Berkshire Travel"
  end
  
  def url()
    "http://www.bbc.co.uk/berkshire/travel/road_info_ssi_feature.shtml"
    #"./BBCBerkshireTravel.html" # old style
    #"./BBCBerkshireTravel2.html"
  end
  
  def get_road_information()
    doc = Hpricot(open(url()))

    traffic_data = Array.new

    doc.search("div[@class='item-body']").each do |summary|
      data = TrafficDatum.new

      # detail
      road = summary.at("div[@class='item-summary']/div[@class]")
      if road != nil
        road_type_code = road.get_attribute("class")
        case road_type_code
          when "road-motorway"
            road_type = "motorway"
          when "road-a"
            road_type = "a road"
          else
            road_type = "road"
        end
        road = road.at("span")
        data.Location = road.inner_text
        
        # summary
        detail = summary.at("div[@class='item-details']/p")
        if detail != nil
          data.Report = detail.inner_text
          traffic_data << data
        end
      end
    end
    traffic_data
  end
end

def traffic_sources()
  [ BBCBerkshireTrafficSource.new ]
end

def arborfield_route()
  route = Route.new
  route.Name = "via Arborfield"
  route.Roads = ["CHURCH ROAD", "A327", "SCHOOL ROAD", "BARKHAM ROAD", "MOLLY MILLAR", "FISHPONDS", "OAKLANDS DRIVE"]
  route
end

def winnersh_route()
  route = Route.new
  route.Name = "via Winnersh"
  route.Roads = ["FISHPONDS", "OXFORD ROAD", "READING ROAD", "A329", "LOWER EARLEY WAY", "B3270", "SHINFIELD ROAD", "A327"]
  route
end

def routes()
  [ arborfield_route ]
end

show_reports = false
show_relevant = true

traffic_sources().each do |source|
  puts "Source: #{source.name}\n\n"
  
  # Get traffic news
  reports = source.get_road_information
  puts "Downloaded #{reports.length} reports\n"
  
  if show_reports
    puts "Reports"
      reports.each do |report|
        puts report.LastUpdated, report.Location, report.Report, "\n"
      end
    end

    if show_relevant
      # Check each route for problems
      routes().each do |route|
        puts "Route: #{route.Name}\n\n"

        # Find data relevant to this route
        relevant = reports.select {|report| route.Roads.any? {|road| report.Location.upcase.include?(road)}}
        relevant = relevant.sort_by { |report| report.LastUpdated }.reverse

        if relevant.any?
          # Display relevant reports
          relevant.each do |routeReport|
          puts "Last updated #{relative_date(routeReport.LastUpdated)}\n"
          puts "Location\n#{routeReport.Location}"
          puts "Report\n#{routeReport.Report}\n\n"
        end
      else
        puts "No known issues\n\n"
      end
      puts "\n"
    end
  end
end
