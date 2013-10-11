require 'rubygems'
require 'sinatra'
require 'haml'
require 'sinatra/reloader' if development?
require 'debugger' if development?


get '/api/0.1/docs' do
  haml :docs, :layout => :app_layout
end


get '/testing_harness' do
  haml :testing_harness, :layout => :app_layout
end

post '/check_api' do
  puts "Hello"
end


set :public_folder, 'assets'


get '/styles.css' do
  scss :styles
end
