express = require 'express'
app = express.createServer()
io  = require('socket.io').listen(app)

#World = require('./world')
#Server = require('./server')
#world = new World()
#server = new Server(world)

app.listen 8000

app.get '/', (req, res) ->
  res.sendfile __dirname + '/index.html'

app.use express.static(__dirname + "/lib")
#clients = new Object
#
#io.sockets.on 'connection', (socket) ->
#  socket.emit 'hello'
#
#  socket.on 'hello', (name) ->
#    clients[name] = socket
#    world.addEntity name,
#      role: 'server'
#      socket: socket
#
#    socket.on 'input', (data) ->
#
#      # Handle client input
#
#    socket.on 'disconnect', ->
#      delete clients[name]
#
#world.run (state) ->
#  socket.volatile.emit 'state', state for name, socket of clients
#
