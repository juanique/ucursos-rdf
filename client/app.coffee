express = require("express")
http = require("http")
fs = require("fs")
util = require("util")

app = express.createServer()
app.configure 'development', ->

app.error (err, req, res, next) ->
  util.puts "APP.ERROR: " + util.inspect(err)
  next err

publicDir = __dirname + "/public"
srcDir = __dirname + "/src"

app.set "views", srcDir

app.use express.compiler(src: srcDir, dest: publicDir, enable: ["coffeescript", "less"])
app.use express.static(publicDir)
app.use express.bodyParser()


proxy = (request, response, proxyHost, proxyPort) ->
    proxy_url = request.originalUrl
    console.log "redirecting to : #{proxy_url}"

    postData = JSON.stringify(request.body)

    postOptions =
        host: proxyHost
        port: proxyPort
        path: proxy_url
        method: request.method
        headers: request.headers

    postReq = http.request postOptions, (proxy_response) ->
        proxy_response.addListener "data", (chunk) ->
            response.write chunk, "binary"

        proxy_response.addListener "end", ->
            response.end()

        response.writeHead proxy_response.statusCode, proxy_response.headers

    if postData
      postReq.write(postData)
    postReq.end()

app.all /^\/sparql\/(.*)/, (request, response) ->
  proxy(request, response, "www.rdfclip.com", 8890)

app.all /^\/api\/(.*)/, (request, response) ->
  proxy(request, response, "www.rdfclip.com", 80)


app.get /^\/$/, (req, res) ->
  res.render "index.jade", layout: false

app.get /.+\.html/, (req, res) ->
  jadeFile = req.originalUrl.replace(/html$/, "jade").substring(1)
  res.render jadeFile, layout: false

app.listen(3000)
console.log "Listening port 3000"
