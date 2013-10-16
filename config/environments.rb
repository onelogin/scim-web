configure :development do
  config = YAML::load(File.open('config/database.yml'))
  environment = Sinatra::Application.environment.to_s

  ActiveRecord::Base.establish_connection(config[environment])
  set :show_exceptions, true
end

configure :production do
  db = URI.parse(ENV['HEROKU_POSTGRESQL_GRAY_URL'])

  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end
