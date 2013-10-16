configure :development do
  set :database, 'postgres://postgres:postgres@localhost:5432/scim_dev'
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
