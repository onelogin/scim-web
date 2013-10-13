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

set :public_folder, 'assets'

# preprocess styles.scss with sass
get('/styles.css') { scss :styles }

not_found { haml :not_found }

# FILTERS
before do
  case request_path(request)
  when '/test/queued'
    redirect_to_root unless http_referer_equals?('/testing_harness', request)
  end
end

def redirect_to_root
  redirect to('/')
end

def request_path(request)
  request.env['REQUEST_PATH']
end

def http_referer_equals?(from, request)
  referer = request.env['HTTP_REFERER']
  url_scheme = request.env['rack.url_scheme']
  host = request.env['SERVER_NAME']
  port = request.env['SERVER_PORT']

  "#{url_scheme}://#{host}:#{port}#{from}" == referer
end

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
  @api_test = ApiTest.new(params[:api_test])

  if @api_test.can_be_performed?
    @api_test.perform
    redirect to('/test/queued')
  else
    haml :testing_harness, :layout => :app_layout
  end
end

get '/test/queued' do
  haml :test_queued, :layout => :app_layout
end

