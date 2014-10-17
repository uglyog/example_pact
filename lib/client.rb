require 'httparty'
require 'uri'
require 'json'
require 'ap'

class Client
  include HTTParty
  base_uri 'http://service-somewhere'

  def load_provider_json
    response = self.class.get("/provider.json?valid_date=#{URI::encode(Time.now.httpdate)}")
    if response.success?
      JSON.parse(response.body)
    end
  end

  def process_data
    data = load_provider_json
    ap data
    value = data['count'] / 100
    date = Time.parse(data['date'])
    puts value
    puts date
    [value, date]
  end

end
