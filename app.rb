require "slack"
require 'oauth'
require 'json'
require 'nokogiri'
require 'net/http'
require 'uri'

consumer_key = ENV['QKBOT_TWITTER_CONSUMER_KEY']
consumer_secret = ENV['QKBOT_TWITTER_CONSUMER_SECRET']
access_token = ENV['QKBOT_TWITTER_ACCESS_TOKEN']
access_token_secret = ENV['QKBOT_TWITTER_ACCESS_TOKEN_SECRET']

consumer = OAuth::Consumer.new(
  consumer_key,
  consumer_secret,
  {
    :site   => 'http://api.twitter.com',
    :scheme => :header
  }
)

token_hash = {
  :access_token        => access_token,
  :access_token_secret => access_token_secret
}

request_token = OAuth::AccessToken.from_hash(consumer, token_hash)

response_available = request_token.request(:get, 'https://api.twitter.com/1.1/trends/available.json')
availables = JSON.parse(response_available.body)

japan_woeid = nil
availables.each do |available|
  if available["name"] == "Japan" then
    japan_woeid = available["woeid"]
    break
  end
end

response_place = request_token.request(:get, 'https://api.twitter.com/1.1/trends/place.json?id=' + japan_woeid.to_s)
japan_trends = JSON.parse(response_place.body)


Slack.configure do |config|
  config.token = ENV['QKBOT_SLACK_TOKEN']
end

slack_post_text = ""
japan_trends[0]['trends'].each do |trend|
  slack_post_text += "`#{trend['name']}` "
end
slack_post_text += "\n ``` \n"

japan_trends[0]['trends'].each do |trend|
  get_path = '/?s=' + trend['name'].delete('#')
  puts get_path
  url = URI.parse('http://quizknock.com')
  res = Net::HTTP.start(url.host, url.port) do |http|
    http.get(get_path)
  end
  html = res.body
 
  doc = Nokogiri::HTML.parse(html, nil, 'UTF-8')
  doc.css('a').each do |anchor|
    link = anchor[:href] if anchor[:rel] == 'bookmark'
    link = nil if link.to_s.include?("daily") #朝ノックを除外
    puts link unless link.nil?
    unless link.nil?
      title = anchor[:title]
      slack_post_text += "いま話題の `#{trend['name']}` をQuizKnockでチェック！ \n\n #{title} \n #{link} \n\n\n"
    end
  end
end
slack_post_text += "```"

Slack.chat_postMessage(text: slack_post_text, channel: '#bot_test')




