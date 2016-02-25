require 'spec_helper'
require 'client'

describe Client do

  let(:json_data) do
    {
      "test" => "NO",
      "date" => "2013-08-16T15:31:20+10:00",
      "count" => 1000
    }
  end
  let(:response) { double('Response', :success? => true, :body => json_data.to_json) }

  it 'can process the json payload from the producer' do
    allow(HTTParty).to receive_messages(:get => response)
    expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
  end

  describe 'pact with provider', :pact => true do

    let(:date) { Time.now.httpdate }

    before do
      my_provider.
        given("provider is in a sane state").
          upon_receiving("a request for provider json").
            with(
                method: :get,
                path: '/provider.json',
                query: URI::encode('valid_date=' + date)
            ).
            will_respond_with(
              status: 200,
              headers: { 'Content-Type' => 'application/json;charset=utf-8' },
              body: json_data
            )
    end

    it 'can process the json payload from the provider' do
      expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
    end

  end

end
