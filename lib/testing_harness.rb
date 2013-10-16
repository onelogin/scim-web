require 'httparty'

module TestingHarness
  class Validity
    @@mandatory_fields = nil

    def self.validate_listing(out, options= {})
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

    def self.validate_resource_creation(out, options={})
      if options[:conflicted]
        out.code == 409 && response_has_errors?(out.parsed_response, '409')
      else
        out.code == 201 #&& !out.headers['location'].nil? #&& mandatory_fields_present?(schema, out)
      end
    end

    def self.mandatory_fields_present?(schema, out)
      mandatory_fields = get_mandatory_fields_from_schema(schema)
      mandatory_fields.all? {|field| !out.parsed_response[field].nil?}
    end

    def self.get_mandatory_fields_from_schema(schema)
      @@mandatory_fields||= schema['attributes'].select {|attr| attr['required']}.map{|field| field['name']}
    end

    def self.validate_resource_fetch(out, id_field, options={})
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

      result
    end

    def self.validate_resource_update(out, options={})
      if options[:deleted]
        out.code == 404 && response_has_errors?(out.parsed_response)
      else
        response = out.parsed_response
        out.code == 200 && !response.nil? && !response['id'].nil? && !response['name'].nil? && !response['userName'].nil?
      end
    end


    def self.validate_resource_deletion(out, options = {})
      if options[:deleted]
        out.code == 404 && response_has_errors?(out.parsed_response)
      else
        out.code == 200
      end
    end

    def self.response_has_errors?(response, error_code='404')
      begin
        errors = response['Errors']
        errors.first['code'] == error_code && !errors.first['description'].nil?
      rescue
        return false
      end
    end
  end

  class Tester
    include HTTParty
    @@debug_output = nil
    @@schema = nil
    @@current_test_resource_id = nil

    def self.init(options)
      self.format :json
      self.headers   'Content-Type' => 'application/json'
      #self.headers   'Authorization' => "apikey #{options[:apikey]}"
      self.headers    'HTTP_APIKEY' => "#{options[:apikey]}"

      uri = options[:hostname]

      uri << options[:path] || "/scim/v1"
      self.base_uri uri

    end

    def self.get_schema
      @@schema ||= self.get('/Schemas', debug_output: @@debug_output)
    end

    def self.create_resource(options)
      body = options[:user]

      reponse = self.post('/Users', body: body.to_json, debug_output: @@debug_output)
      @@current_test_resource_id = reponse.parsed_response['id']
      reponse
    end

    def self.update_resource(options)
      id = @@current_test_resource_id || 99999999
      url = "/Users/#{id}.json"

      body =  options[:user]
      self.put(url, body: body.to_json, debug_output: @@debug_output)
    end

    def self.delete_resource
      id = @@current_test_resource_id
      delete_url = "/Users/#{id}.json"
      self.delete(delete_url, debug_output: @@debug_output)
    end


    def self.debug(debug = false)
      @@debug_output = $stdout if debug
    end

    def self.test_resource_creation(options={})
      out = self.create_resource(:user => options[:user])
      Validity.validate_resource_creation(out, options) # we'll see how to add the schema later
    end

    def self.test_resource_deletion(options={})
      out = self.delete_resource
      Validity.validate_resource_deletion(out, options)
    end

    def self.test_resource_lookup(options={})
      id = @@current_test_resource_id || -1
      lookup_url = "/Users/#{id}.json"
      out = self.get(lookup_url, debug_output: @@debug_output)
      Validity.validate_resource_fetch(out, 'userName', options)
    end

    def self.test_resource_listing(options= {})
      if options[:filter]
        out = self.get("/Users?attributes=email&filter=email%20eq%20example@testonelog.in", debug_output: @@debug_output)
      else
        out = self.get("/Users", debug_output: @@debug_output)
        if options[:deleted]
          options[:value] = "example@testonelog.in"
        end
      end

      Validity.validate_listing(out, options)
    end

    def self.test_resource_search
      email = 'example@testonelog.in'
      search_url = "/Users?attributes=email&filter=" + CGI.escape("email eq #{email}")
      self.get(search_url, debug_output: @@debug_output)
    end

    def self.test_resource_update(options={})
      out = self.update_resource(:user => options[:user])
      Validity.validate_resource_update(out, options)
    end
  end
end
