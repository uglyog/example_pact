require 'httparty'
require 'uri'

class Client

  def load_producer_json
    response = HTTParty.get(URI::encode('http://localhost:8081/producer.json?valid_date=' + Time.now.httpdate))
    if response.success?
      JSON.parse(response.body)
    end
  end

end
