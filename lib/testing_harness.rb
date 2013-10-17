require 'httparty'
require 'fileutils'
require 'pony'

module Mailer
  class TestsMailer
    def self.send_message(params)
      Pony.mail(
        :from => "OneLogin" + "<support@onelogin.com>", :to => params[:to],
        :subject => "Your API Test report results", :body => params[:message],
        :port => '587',
        :via => :smtp,
        :headers => { 'Content-Type' => 'text/html' },
        :via_options => {
          :address => 'smtp.gmail.com',
          :port => '587',
          :enable_starttls_auto => true,
          :user_name => '',
          :password => '',
          :authentication => :plain,
          :domain => 'localhost.localdomain'
      })
    end
  end
end

module TestingHarness

  class ReportWriter
    def create_file(path, extension)
      dir = File.dirname(path)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      path << ".#{extension}"

      File.new(path, 'w')
      path
    end

    def initialize(path)
      @path = create_file(path, 'html')
    end

    def append(text)
      File.open( @path, 'a+') { |f| f.write(text + "\n") }
    end

    def ok(text)
      append("<p class='success'>#{text} Result: OK</p>")
    end

    def error(text)
      append("<p class='error'>#{text} Result: ERROR </p>")
    end

    def read
      f = File.open(@path, "r")
      text = f.read
      f.close

      text
    end
  end

  class Validity
    attr_accessor :writer

    def initialize(opts = {})
      path = opts[:filename] || 'reports/example'
      @writer = ReportWriter.new(path)
    end

    def validate_listing(out, options= {})
      result = true
      response = out.parsed_response
      result = (out.code == 200)

      resources = out.parsed_response['Resources']

      if options[:deleted]
        resources_array = resources.map{|hash| hash.values_at('userName')}.flatten
        return false if  resources_array.include?(options[:value])
      end

      result = if resources.nil?
        false
      elsif (total_results = response['totalResults']) > 0
        (total_results == resources.count)
      end
    end

    def validate_resource_creation(out, options={})
      if options[:conflicted]
        out.code == 409 && response_has_errors?(out.parsed_response, '409')
      else
        compliant = out.code == 201
        #&& !out.headers['location'].nil? #&& mandatory_fields_present?(schema, out)
        @writer.ok "Test: Create" if compliant
        compliant
      end
    end

    def mandatory_fields_present?(schema, out)
      mandatory_fields = get_mandatory_fields_from_schema(schema)
      mandatory_fields.all? {|field| !out.parsed_response[field].nil?}
    end

    def get_mandatory_fields_from_schema(schema)
      @@mandatory_fields||= schema['attributes'].select {|attr| attr['required']}.map{|field| field['name']}
    end

    def validate_resource_fetch(out, id_field, options={})
      result = true
      response = out.parsed_response

      if options[:deleted]
        result = (out.code == 404) && response_has_errors?(out.parsed_response)
      else
        return false if out.code != 200 || response[id_field].nil?

        if response['meta'].nil? || response['meta']['location'].nil? || response['id'].nil?
          result = false
        end
      end

      @writer.ok "Test: Lookup."

      result
    end

    def validate_resource_update(out, options={})
      if options[:deleted]
        out.code == 404 && response_has_errors?(out.parsed_response)
      else
        response = out.parsed_response
        compliant = out.code == 200 && !response.nil? && !response['id'].nil? && !response['name'].nil? && !response['userName'].nil?
        @writer.ok "Test: Update" if compliant
        compliant
      end
    end


    def validate_resource_deletion(out, options = {})
      if options[:deleted]
        out.code == 404 && response_has_errors?(out.parsed_response)
      else
        compliant = out.code == 200
        @writer.ok "Test: Create" if compliant
        compliant
      end
    end

    def response_has_errors?(response, error_code='404')
      begin
        errors = response['Errors']
        errors.first['code'] == error_code && !errors.first['description'].nil?
      rescue
        return false
      end
    end
  end

  class Tester

    class << self
      def new(uri, token, *args)
        Class.new(AbstractTester) { |klass|
          klass.base_uri uri
          klass.format   :json
          klass.headers  'Content-Type' => 'application/json'
          klass.headers  'HTTP_APIKEY' => token
        }.new(*args)
      end
    end

    class AbstractTester
      include HTTParty

      def initialize(opts)
        @json_fixture = JSON.parse(opts[:json_fixture])
        @debug        = $stdout if opts[:debug]
        @validator    = Validity.new(:filename => opts[:report_filename])
        @email        = opts[:email]
      end

      def execute
        test_create
        test_lookup
        test_update
        test_delete

        Mailer::TestsMailer.send_message(:to => @email, :message => @validator.writer.read)
      end

      def get_schema
        @schema ||= self.class.get('/Schemas', :debug_output => @debug)
      end

      def create
        body = @json_fixture['create']
        reponse = self.class.post('/Users', :body =>  body.to_json, debug_output: @debug)
        @resource_id = reponse.parsed_response['id']
        reponse
      end

      def delete
        id = @resource_id
        delete_url = "/Users/#{id}.json"
        self.class.delete(delete_url, :debug_output => @debug)
      end

      def update
        id = @resource_id
        url = "/Users/#{id}.json"
        body = @json_fixture['update']
        self.class.put(url, :body => body.to_json, :debug_output => @debug)
      end

      def lookup(options={})
        id = @resource_id
        lookup_url = "/Users/#{id}.json"
        self.class.get(lookup_url, :debug_output => @debug)
      end

      def list(options = {})
        if options[:filter]
          self.class.get("/Users?attributes=email&filter=email%20eq%20example@testonelog.in", :debug_output => @debug)
        else
          self.class.get("/Users", :debug_output =>  @debug)
          #if options[:deleted]
            #options[:value] = "example@testonelog.in"
          #end
        end
      end

      def test_create(options={})
        @validator.validate_resource_creation(create, options) # we'll see how to add the schema later
      end

      def test_delete(options={})
        @validator.validate_resource_deletion(delete, options)
      end

      def test_lookup(options={})
        @validator.validate_resource_fetch(lookup, 'userName', options)
      end

      def test_update(options={})
        @validator.validate_resource_update(update, options)
      end

      def test_list(options={})
        @validator.validate_listing(list, options)
      end
    end
  end


    #def self.test_resource_search
      #email = 'example@testonelog.in'
      #search_url = "/Users?attributes=email&filter=" + CGI.escape("email eq #{email}")
      #self.get(search_url, debug_output: @@debug_output)
    #end

  #end
end
