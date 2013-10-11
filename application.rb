require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'


get '/api/0.1/docs' do
  haml :docs, :layout => :app_layout
end


get '/testing_harness' do
  haml :testing_harness, :layout => :app_layout
end

get '/what/time/is/it/in/:number/hours' do
  number = params[:number].to_i
  time = Time.now + number * 3600
  "The time in #{number} hours will be #{time.strftime('%I:%M %p')}"
end


set :public_folder, 'assets'


get '/styles.css' do
  scss :styles
end
