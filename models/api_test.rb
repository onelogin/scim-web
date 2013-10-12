class ApiTest < SuperModel::Base
  attributes :token, :base_url, :fixtures_file
  validates_presence_of :token, :base_url, :fixtures_file
end
