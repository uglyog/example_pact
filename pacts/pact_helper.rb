require 'pact/provider/rspec'

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
