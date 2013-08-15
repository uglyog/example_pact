require 'httparty'
require 'uri'
require 'json'

class Client

  def load_producer_json
    url = URI::encode('http://localhost:8081/producer.json?valid_date=' + Time.now.httpdate)
    puts url
    response = HTTParty.get(url)
    if response.success?
      JSON.parse(response.body)
    end
  end

end
