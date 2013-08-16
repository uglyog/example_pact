require 'ap'

require 'pact'
require 'pact/consumer/rspec'

$:.unshift 'lib'

Pact.configure do | config |
  config.consumer do
    name 'My Consumer'
  end
end

Pact.with_producer "My Producer" do
  mock_service :my_producer do
    port 8081
  end
end
