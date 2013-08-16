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
    HTTParty.stub(:get).and_return(response)
    expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
  end

  describe 'pact with producer', :pact => true do

    let(:date) { Time.now.httpdate }

    before do
      my_producer.
        given("producer is in a sane state").
          upon_receiving("a request for producer json").
            with({
                method: :get,
                path: '/producer.json',
                query: URI::encode('valid_date=' + date)
            }).
            will_respond_with({
              status: 200,
              headers: { 'Content-Type' => 'application/json;charset=utf-8' },
              body: json_data
            })
    end

    it 'can process the json payload from the producer' do
      expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
    end

  end

end
