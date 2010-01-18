#!ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'hpricot'
require 'open-uri'

class TrafficData
  attr_accessor :Location
  attr_accessor :Report
end

def removeMarkup(html)
  	html.sub(%r{<body.*?>(.*?)</body>}mi, '\1').gsub(/<.*?>/m, ' ').gsub(%r{(\n\s*){2}}, "\n\n")
end

def removeExtraWhitespace(text)
  text.gsub(/\s+/, ' ')
end





# load the BBC Berkshire Travel News web page
#path = "http://www.bbc.co.uk/berkshire/travel/road_info_ssi_feature.shtml"
path = "./BBCBerkshireTravel.html"
doc = Hpricot(open(path))

traffic_data = Array.new

doc.search("table[@class='tpegTable']").each do |table|
  table.search("tr").each do |row|
    cols = row.search("td")
    if cols[1] != nil || cols[2] != nil
      data = TrafficData.new
      data.Location = removeExtraWhitespace(cols[1].inner_text)
      data.Report = removeExtraWhitespace(cols[2].inner_text)
      traffic_data << data
    end
  end
end

roads = ["A327", "SCHOOL ROAD", "BARKHAM ROAD", "MOLLY MILLAR'S LANE", "OAKLANDS DRIVE"]
relevant = traffic_data.select {|d| roads.any? {|s| d.Location.upcase.include?(s) }  }

relevant.each do |datum|
  puts "Location: #{datum.Location}\nReport: #{datum.Report}\n\n"
end

