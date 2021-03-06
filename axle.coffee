# A wrapper library for interfacing with the API Axle API
http = require "http"
_    = require "underscore"

class Axle

  getOptions: ( path ) ->
    unless @domain?
      throw new Error "No domain set."

    headers =
      "Host":           @domain, "User-Agent":     "axle-node HTTP client",
      "Content-type":   "application/json"

    options =
      hostname: @domain
      port:     @port
      path:     @path( path )
      headers:  headers

  parseResponse: ( res, cb ) ->
    res.setEncoding( "utf8" )

    body = [ ]
    res.on "data", ( chunk ) -> body.push( chunk )

    res.on "end", () ->
      body_str = body.join ""

      if res.statusCode != 200
        error_details =
          status: res.statusCode,
          body:   body_str

        cb error_details, null
        return

      cb null, JSON.parse body_str

  poster: ( path, params, cb ) ->
    options = @getOptions path
    options.method = "POST"

    req = http.request options, ( res ) =>
      @parseResponse res, cb

    req.write JSON.stringify params
    req.end()

  getter: ( path, cb ) ->
    options = @getOptions path
    req = http.request options, ( res ) =>
      @parseResponse res, cb

    req.end()

class exports.V1 extends Axle
  constructor: ( @domain, @port=3000 ) ->
    @path_prefix = "/v1"

  path: ( extra ) ->
    @path_prefix + extra

  getKeysByApi: ( api, options, cb ) ->
    defaults =
      from: 0
      to:   10

    params = _.extend defaults, options

    endpoint =  "/api/#{api}/keys?from=#{params.from}&to=#{params.to}"
    endpoint += "&resolve=#{params.resolve}"
    @getter endpoint, cb

  getApis: ( options, cb ) ->
    defaults =
      from:    0
      to:      10
      resolve: false

    params = _.extend defaults, options

    endpoint  = "/apis?from=#{params.from}&to=#{params.to}"
    endpoint += "&resolve=#{params.resolve}"
    @getter endpoint, cb

  getKey: ( key, cb ) ->
    endpoint  = "/key/#{key}"
    @getter endpoint, cb

  getKeyStats: ( key, cb ) ->
    endpoint  = "/key/#{key}/stats"
    @getter endpoint, cb

  getKeyHits: ( key, cb ) ->
    endpoint  = "/key/#{key}/hits"
    @getter endpoint, cb

  getRealTimeKeyHits: ( key, cb ) ->
    endpoint  = "/key/#{key}/hits/now"
    @getter endpoint, cb

  getApiStats: ( api, cb ) ->
    endpoint  = "/api/#{api}/stats"
    @getter endpoint, cb

  getApiHits: ( api, cb ) ->
    endpoint  = "/api/#{api}/hits"
    @getter endpoint, cb

  getRealTimeApiHits: ( api, cb ) ->
    endpoint  = "/api/#{api}/hits/now"
    @getter endpoint, cb

  createApi: ( api, endpoint, options, cb ) ->
    defaults =
      endPoint: endpoint

    params       = _.extend defaults, options
    api_endpoint = "/api/#{api}"
    @poster api_endpoint, params, cb

  createKey: ( key, apis, options, cb ) ->
    # List of options that should be removed if empty string
    for opt in ["qpd", "qps", "sharedSecret"]
      if options[opt] == ""
        delete options[opt]

    defaults =
      forApis: apis
      qps:     2
      qpd:     86400*2

    # Combine with options
    params       = _.extend defaults, options
    api_endpoint = "/key/#{key}"
    @poster api_endpoint, params, cb
