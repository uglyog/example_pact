Example use of the Pact gem
===========================

When writing a lot of small services, testing the interactions between these becomes a major headache.
That's the problem Pact is trying to solve.

Integration tests tyically are slow and brittle, requiring each component to have it's own environment to run the
tests in. With a micro-service architecture, this becomes even more of a problem. They also have to be 'all-knowing' 
and this makes them difficult to keep from being fragile.

After J. B. Rainsberger's talk "Integrated Tests Are A Scam" people have been thinking how to get the confidence we 
need to deploy our software to production without having a tiresome integration test suite that does not give us all
the coverage we think it does.

Pact is a ruby gem that allows you to define a pact between service consumers and providers. It provides a DSL for
service consumers to define the request they will make to a service provider and the response they expect back. This
expectation is used in the consumers specs to provide a mock provider, and is also played back in the provider
pact:verify tasks to ensure the provider actually does provide the response the consumer expects.

This allows you to test both sides of an integration point using fast unit tests.

#Example Pact use#

Given we have a client that needs to make a HTTP GET request to a sinatra webapp, and requires a response in JSON
format. The client would look something like:

client.rb:

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
    
    end

and the provider:
provider.rb

    class Provider < Sinatra::Base
    
      before do
        content_type 'application/json;charset=utf-8'
      end
    
      get '/provider.json', :provides => 'json' do
        valid_time = Time.parse(params[:valid_date])
        JSON.pretty_generate({
          :test => 'NO',
          :date => "2013-08-16T15:31:20+10:00",
          :count => 1000
        })
      end
    end


This provider expects a valid_date parameter in HTTP date format, and then returns some simple json back.

Running the client with the following rake task against the provider works nicely:

    desc 'Run the client'
    task :run_client => :init do
      require 'client'
      require 'ap'
      ap Client.new.load_provider_json
    end

    $ rake run_client
    http://localhost:8081/provider.json?valid_date=Thu,%2015%20Aug%202013%2003:15:15%20GMT
    {
              "test" => "NO",
        "valid_date" => "2013-08-15T13:31:39+10:00",
             "count" => 1000
    }


Now lets get the client to use the data it gets back from the provider. Here is the updated client method that uses the
returned data:

client.rb

      def process_data
        data = load_provider_json
        ap data
        value = data['count'] / 100
        date = Time.parse(data['date'])
        puts value
        puts date
        [value, date]
      end

Add a spec to test this client:

client_spec.rb:

    require 'spec_helper'
    require 'client'


    describe Client do


      let(:json_data) do
        {
          "test" => "NO",
          "date" => "2013-08-16T15:31:20+10:00",
          "count" => 100
        }
      end
      let(:response) { double('Response', :success? => true, :body => json_data.to_json) }


      it 'can process the json payload from the provider' do
        expect(subject.process_data).to eql([10, Time.parse(json_data['date'])])
      end

    end

Let's run this spec and see it all pass:

    $ rake spec
    /Users/ronald/.rvm/rubies/ruby-1.9.3-p448/bin/ruby -S rspec ./spec/client_spec.rb


    Client
    http://localhost:8081/provider.json?valid_date=Fri,%2016%20Aug%202013%2005:44:41%20GMT
    {
         "test" => "NO",
         "date" => "2013-08-16T15:31:20+10:00",
        "count" => 100
    }
    1
    2013-08-16 15:31:20 +1000
      can process the json payload from the provider


    Finished in 0.00409 seconds
    1 example, 0 failures

However, there is a problem with this integration point. The provider returns a 'valid_date' while the consumer is 
trying to use 'date', which will blow up when run for real even with the tests all passing. Here is where Pact comes in.

#Pact to the rescue#

Lets setup Pact in the consumer. Pact lets the consumers define the expectations for the integration point.

    Pact.service_consumer "My Service Consumer" do
      has_pact_with "My Service Provider" do
        mock_service :my_service_provider do
          port 8081
        end
      end
    end

This defines a consumer and a provider that runs on port 8081.

The spec for the client now has a pact section.

client_spec.rb:

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
        expect(subject.process_data).to eql([1, Time.parse(json_data['date'])])
      end

    end


Running this spec still passes, but it creates a pact file which we can use to validate our assumptions
on the provider side.

    $ rake spec
    /Users/ronald/.rvm/rubies/ruby-1.9.3-p448/bin/ruby -S rspec ./spec/client_spec.rb


    Client
    http://localhost:8081/provider.json?valid_date=Fri,%2016%20Aug%202013%2006:09:44%20GMT
    {
      "test"  => "NO",
      "date"  => "2013-08-16T15:31:20+10:00",
      "count" => 100
    }
    1
    2013-08-16 15:31:20 +1000
      can process the json payload from the provider
      pact with provider
    http://localhost:8081/provider.json?valid_date=Fri,%2016%20Aug%202013%2006:09:44%20GMT
    {
      "test"  => "NO",
      "date"  => "2013-08-16T15:31:20+10:00",
      "count" => 100
    }
    1
    2013-08-16 15:31:20 +1000
        can process the json payload from the provider

Generated pact file (pacts/my_consumer-my_service_provider.json):

    {
      "provider": {
        "name": "My Service Provider"
      },
      "consumer": {
        "name": "My Service Consumer"
      },
      "interactions": [
        {
          "description": "a request for provider json",
          "provider_state": "provider is in a sane state",
          "request": {
            "method": "get",
            "path": "/provider.json",
            "query": "valid_date=Fri,%2017%20Oct%202014%2005:39:25%20GMT"
          },
          "response": {
            "status": 200,
            "headers": {
              "Content-Type": "application/json;charset=utf-8"
            },
            "body": {
              "test": "NO",
              "date": "2013-08-16T15:31:20+10:00",
              "count": 1000
            }
          }
        }
      ],
      "metadata": {
        "pactSpecificationVersion": "1.0.0"
      }
    }

#Provider Setup#

Pact has a rake task to verify the provider against the generated pact file. It can get the pact file from any URL
(like the last sucessful CI build), but we just going to use the local one. Here is the addition to the Rakefile.

Rakefile:
    require 'pact/tasks'

This will automatically find and load the pact_helper.rb, and give us our verification tasks.

spec/pacts/pact_helper.rb

    Pact.service_provider "My Service Provider" do
      honours_pact_with 'My Service Consumer' do
        pact_uri './pacts/my_service_consumer-my_service_provider.json'
      end
    end
    
    Pact.provider_states_for "My Service Consumer" do
      provider_state "provider is in a sane state" do
        no_op
      end
    end

Now if we run our pact verification task, it should fail.

    $ rake pact:verify:local


    Pact in spec/pacts/my_consumer-my_service_provider.json
      Given provider is in a sane state
        a request for provider json to /provider.json
          returns a response which
            has status code 200
            has a matching body (FAILED - 1)
            includes headers
              "Content-Type" with value "application/json" (FAILED - 2)


    Failures:


      1) Pact in spec/pacts/my_service_consumer-my_service_provider.json Given provider is in a sane state a request for provider json to /provider.json returns a response which has a matching body
         Failure/Error: expect(parse_entity_from_response(last_response)).to match_term response['body']
           {
             "date"  => {
               :expected => "2013-08-16T15:31:20+10:00",
               :actual   => nil
             },
             "count" => {
               :expected => 100,
               :actual   => 1000
             }
           }

Looks like we need to update the provider to return 'date' instead of 'valid_date', we also need to update the client expectation to return 1000 for the count. Doing this, and we now have fast unit tests on each side of the integration point instead of tedious integration tests.
