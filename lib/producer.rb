require 'sinatra/base'
require 'json'

class Producer < Sinatra::Base

  get '/producer.json', :provides => 'json' do
    valid_time = Time.parse(params[:valid_date])
    JSON.pretty_generate({
      :test => 'NO',
      :valid_date => DateTime.now,
      :count => 1000
    })
  end

end
