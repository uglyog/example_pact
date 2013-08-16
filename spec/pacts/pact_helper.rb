Pact.with_consumer 'My Consumer' do
  producer_state "producer is in a sane state" do
    set_up do
      # Create a thing here using your factory of choice
    end
  end
end

require 'producer'
Pact.configure do | config |
  config.producer do
    name "My Producer"
    app { Producer.new }
  end
end
