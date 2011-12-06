Client = require './src/client'
Server = require './src/server'
Player = require './src/player'

round = (number) ->
  return "" unless number?
  number.toPrecision 4

pad = (s, length = 40) ->
  s2 = s or ""
  while s2.length < length
    s2 += " "
  s2

serverStatus = (server) ->
  # SERVER @ 10
  # jane: (8.7) 2.0, 1.5
  # john: (8.7) 3.0, 2.0
  # 
  lines = []
  lines.push "SERVER @ #{server.time}"
  for name, player of server.players
    lines.push "#{name}: (#{round player.time}) #{round player.position.x} #{round player.position.y}"
  lines.push ""
  lines

clientStatus = (client) ->
  # JOHN @ 10.30
  # jane: 2.0, 1.5
  # john: 3.5, 2.0
  # 9.30 9.80 10.30
  lines = []
  lines.push "#{client.localPlayer.name.toUpperCase()} @ #{round client.userCommands[client.userCommands.length-1]?.time}"
  for name, player of client.lastRenderedEntites
    lines.push "#{name}: #{round player.position.x} #{round player.position.y}"
  lines.push "#{client.userCommands.length} unacknowledged"
  lines

class FakeConnection
  constructor: (@latency) ->

  transmit: (data, receiver, method, args...) ->
    json = JSON.stringify data
    parsed = JSON.parse json
    args = JSON.parse(JSON.stringify(args))
    args.push parsed
    setTimeout (-> receiver[method].apply(receiver, args)), @latency

connection = new FakeConnection(200)

server = new Server()
server.fps = 20
server.addPlayer 'john', new Player(position: { x: 0, y: 0 })
server.addPlayer 'jane', new Player(position: { x: 10, y: 0 })

john = new Player(position: { x: 0, y: 0 })
john.name = 'john'
john.calculatePhysics = john.updatePhysics
jane = new Player(position: { x: 10, y: 0 })
jane.name = 'jane'
jane.calculatePhysics = jane.updatePhysics

johnClient = new Client(server.fps)
johnClient.localPlayer = john
janeClient = new Client(server.fps)
janeClient.localPlayer = jane

johnClient.readInput = -> { forward: true, right: true }
janeClient.readInput = -> { forward: true, left: true }

server.run (snapshot) ->
  connection.transmit snapshot, johnClient, 'receiveSnapshot'
  connection.transmit snapshot, janeClient, 'receiveSnapshot'
  ss = serverStatus server
  johnStatus = clientStatus johnClient
  janeStatus = clientStatus janeClient
  for i in [0..4]
    console.log "#{pad ss[i]} #{pad johnStatus[i]} #{pad janeStatus[i]}"

startClients = ->
  johnClient.run 60, (entities, command) ->
    johnClient.lastRenderedEntites = entities
    connection.transmit command, server, 'input', 'john'
  janeClient.run 60, (entities, command) ->
    janeClient.lastRenderedEntites = entities
    connection.transmit command, server, 'input', 'jane'

setTimeout startClients, 1000
