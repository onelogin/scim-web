module RequestHelpers
  def request_path(request)
    request.env['REQUEST_PATH']
  end

  def http_referer_equals?(from, request)
    referer = request.env['HTTP_REFERER']
    puts "referrer: #{referer}"
    url_scheme = request.env['rack.url_scheme']
    puts "url scheme: #{url_scheme}"
    host = request.env['SERVER_NAME']
    puts "host: #{host}"
    port = request.env['SERVER_PORT']
    puts "port: #{port}"

    puts "from: #{from}"
    "#{url_scheme}://#{host}{from}" == referer
  end
end
