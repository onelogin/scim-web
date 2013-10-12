require 'rubygems'
require 'sinatra'
require 'haml'
require 'supermodel'
require 'sinatra/reloader' if development?
require 'debugger' if development?

require_relative './models/api_test.rb'
require_relative './helpers/application_helper.rb'
require_relative './helpers/view_helper.rb'


helpers ApplicationHelper, ViewHelper

get '/api/0.1/docs' do
  haml :docs, :layout => :app_layout
end


get '/testing_harness' do
  @api_test = ApiTest.new
  haml :testing_harness, :layout => :app_layout
end

post '/check_api' do
  @api_test = ApiTest.new(params)

  if @api_test.valid?
    @api_test.perform
  else
    haml :testing_harness, :layout => :app_layout
  end
end


set :public_folder, 'assets'


get '/styles.css' do
  scss :styles
end
