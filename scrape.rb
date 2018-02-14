require 'nokogiri'
require 'net/http'
require 'uri'

url = URI.parse('http://quizknock.com')
res = Net::HTTP.start(url.host, url.port) do |http|
  http.get('/?s=shiritori')
end
html = res.body
#puts html

doc = Nokogiri::HTML.parse(html, nil, 'UTF-8')
doc.css('a').each do |anchor|
  puts anchor[:href] if anchor[:rel] == 'bookmark'
end
