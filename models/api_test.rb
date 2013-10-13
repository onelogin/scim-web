class ApiTest < SuperModel::Base
  attributes :token, :base_url, :fixtures_file
  validates_presence_of :token, :base_url, :fixtures_file

  def can_be_performed?
    return false unless valid?

    #validate the file name format
    filename = fixtures_file['filename']
    self.errors.add(:fixtures_file, "Must be a yaml file") unless filename =~ /.yaml$/

    # now validate that the file can be loaded
    file = fixtures_file['tempfile']
    begin
      YAML.load(file)
    rescue ArgumentError => e
      self.errors.add(:fixtures_file, "Could not parse YAML file. Verify it is correctly formatted")
      puts "Could not parse YAML: #{e.message}"
    end
  end

  def perform
    true
  end
end
