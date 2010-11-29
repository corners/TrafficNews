#!ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'hpricot'
require 'open-uri'
require 'time'
require 'date'

def remove_markup(html)
  	html.sub(%r{<body.*?>(.*?)</body>}mi, '\1').gsub(/<.*?>/m, ' ').gsub(%r{(\n\s*){2}}, "\n\n")
end

def remove_extra_whitespace(text)
  text.gsub(/\s+/, ' ')
end

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
    #"./BBCBerkshireTravel.html"
  end
  
  def get_road_information()
    
    doc = Hpricot(open(url()))

    traffic_data = Array.new

    doc.search("table[@class='tpegTable']").each do |table|
      table.search("tr").each do |row|
        cols = row.search("td")
        if cols[1] != nil || cols[2] != nil
          data = TrafficDatum.new
          data.Location = remove_extra_whitespace(cols[1].inner_text).strip
          data.Report = remove_extra_whitespace(cols[2].inner_text).strip
          data.LastUpdated = extract_last_updated(data.Report)
          traffic_data << data
        end
      end
    end
    traffic_data
  end
  
  def extract_last_updated(report)
    # Text in format: Last updated: 1st January 2010 12:51
	  matches = report.scan(/Last updated\: (\d+)(th|st|nd) ([a-zA-Z]+) (\d{4}) at (\d+)\:(\d+)/)
    match = matches[0]
    if match != nil
      # Convert to a parsable format
  	  str = "#{match[0]} #{match[2]} #{match[3]} #{match[4]}:#{match[5]}:00"
      result = DateTime.parse(str)
    else
      result = DateTime.now    
    end
    result
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

traffic_sources().each do |source|
  puts "Source: #{source.name}\n\n"
  
  # Get traffic news
  reports = source.get_road_information

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



