require 'sinatra/base'
require 'json'

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
