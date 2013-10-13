require 'rubygems'
require 'sinatra'
require 'haml'
require 'supermodel'
require 'yaml'
require 'sinatra/reloader' if development?
require 'debugger' if development?

require_relative './models/api_test.rb'
require_relative './helpers/application_helper.rb'
require_relative './helpers/view_helper.rb'


helpers ApplicationHelper, ViewHelper

get '/' do
  redirect to('/api/0.1/docs')
end

get '/api/0.1/docs' do
  haml :docs, :layout => :app_layout
end


get '/testing_harness' do
  @api_test = ApiTest.new
  haml :testing_harness, :layout => :app_layout
end

post '/check_api' do
  @api_test = ApiTest.new(params)

  if @api_test.can_be_performed?
    @api_test.perform
    redirect to('/test/queued')
  else
    haml :testing_harness, :layout => :app_layout
  end
end

get '/test/queued' do
  haml :test_queued
end

set :public_folder, 'assets'


get '/styles.css' do
  scss :styles
end

not_found do
  haml :not_found
end
