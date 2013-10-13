module RequestHelpers
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
end
