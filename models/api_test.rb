class ApiTest < ActiveRecord::Base
  attr_accessor :fixtures_file

  validates_presence_of :token, :base_url, :fixtures_file

  def can_be_performed?
    #validate the file name format
    filename = self.fixtures_file[:filename]
    self.errors.add(:fixtures_file, "Must be a yaml file") unless filename =~ /.yaml$/

    # now validate that the file can be loaded
    file = self.fixtures_file[:tempfile]
    begin
      temp_hash  = YAML.load(file)
    rescue ArgumentError => e
      self.errors.add(:fixtures_file, "Could not parse YAML file. Verify it is correctly formatted")
      puts "Could not parse YAML: #{e.message}"
    end

    # and finally convert it to json and assign to the object
    begin
      self.json_fixture = temp_hash.to_json
    rescue ArgumentError => e
      self.errors.add(:json_fixture, "Parse error. We couldn't convert to json.")
      puts "Could not convert JSON: #{e.message}"
    end
  end

  # call api_test.backgrounded.perform
  def perform
    #App.log.info "Processing!"
  end
end

