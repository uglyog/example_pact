Pact.with_consumer 'My Consumer' do
  producer_state "provider is in a sane state" do
    set_up do
      # Create a thing here using your factory of choice
    end
  end
end

require 'provider'
Pact.configure do | config |
  config.producer do
    name "My Provider"
    app { Provider.new }
  end
end
