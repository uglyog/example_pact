require 'client'
require 'pact/consumer/rspec'

Pact.configure do | config |
  config.pact_dir = './pacts'
end

Pact.service_consumer "My Service Consumer" do
  has_pact_with "My Service Provider" do
    mock_service :my_service_provider do
      port 8081
    end
  end
end

describe Client, :pact => true do

  before do
    Client.base_uri 'localhost:8081'
  end

  let(:json_data) do
    {
      "test"  => "NO",
      "date"  => "2013-08-16T15:31:20+10:00",
      "count" => 1000
    }
  end
  let(:response) { double('Response', :success? => true, :body => json_data.to_json) }

  it 'can process the json payload from the provider' do
    allow(Client).to receive(:get) {response}
    expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
  end

  describe 'pact with provider', :pact => true do

    let(:date) { Time.now.httpdate }

    before do
      my_service_provider.given("provider is in a sane state").
        upon_receiving("a request for provider json").
          with(
            method: :get,
            path:   '/provider.json',
            query:  URI::encode('valid_date=' + date)
          ).
          will_respond_with(
            status:  200,
            headers: { 'Content-Type' => 'application/json;charset=utf-8' },
            body:    json_data
          )
    end

    it 'can process the json payload from the provider' do
      expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
    end

  end

end
