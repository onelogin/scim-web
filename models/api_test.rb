class ApiTest < ActiveRecord::Base
  attr_accessor :fixtures_file

  validates_presence_of :token, :base_url, :fixtures_file, :email
  validates_format_of   :token, :with => /\w{8,}/, :message => "The token must be formed of at least 8 characters"
  validates_format_of   :base_url, 
                        :with => /^(http(?:s)?\:\/\/[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,6}(?:\/?|(?:\/[\w\-]+)*)(?:\/?|\/\w+\.[a-zA-Z]{2,4}(?:\?[\w]+\=[\w\-]+)?)?(?:\&[\w]+\=[\w\-]+)*)$/i, :multiline => true,
                        :message => 'Not a valid URL'
  validates_format_of   :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/, :on => :create


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
  def test
    tester = TestingHarness::Tester.new base_url, token,
                                        :json_fixture => json_fixture,
                                        :email => email,
                                        :debug => false,
                                        :report_filename => "reports/#{id}"
    tester.backgrounded.execute
  end
end

