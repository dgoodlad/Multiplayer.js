express = require 'express'
app = express.createServer()
io  = require('socket.io').listen(app)

app.listen 8000

bundle = require('browserify')(
  entry: __dirname + '/entry.coffee'
  watch: true
)
app.use bundle

app.get '/', (req, res) ->
  res.sendfile __dirname + '/index.html'
