MP = require('multiplayer')
Client = MP.Client
Server = MP.Server
Player = MP.Player

renderPlayer = (player, element) ->
  element.style['left'] = "#{player.position.x}px"
  element.style['top'] = "#{player.position.y}px"

renderServer = (snapshot) ->
  for name, player of snapshot.players
    el = document.querySelector("#server-scene .player[data-player=#{name}]")
    renderPlayer player, el

renderClient = (clientName, entities) ->
  for name, player of entities
    el = document.querySelector("##{clientName}-scene .player[data-player=#{name}]")
    renderPlayer player, el

class FakeConnection
  constructor: (@latency) ->

  transmit: (data, receiver, method, args...) ->
    json = JSON.stringify data
    parsed = JSON.parse json
    args = JSON.parse(JSON.stringify(args))
    args.push parsed
    setTimeout (-> receiver[method].apply(receiver, args)), @latency

connection = new FakeConnection(400)

server = new Server()
server.fps = 20
server.addPlayer 'john', new Player(position: { x: 0, y: 0 })
server.addPlayer 'jane', new Player(position: { x: 100, y: 0 })

john = new Player(position: { x: 0, y: 0 })
john.name = 'john'
john.calculatePhysics = john.updatePhysics
jane = new Player(position: { x: 100, y: 0 })
jane.name = 'jane'
jane.calculatePhysics = jane.updatePhysics

johnClient = new Client(server.fps)
johnClient.localPlayer = john
janeClient = new Client(server.fps)
janeClient.localPlayer = jane

johnClient.readInput = -> { forward: true, right: Math.random() > 0.9, left: Math.random() < 0.1 }
janeClient.readInput = -> { forward: true, right: Math.random() > 0.95, left: Math.random() < 0.2 }

window.onload = ->
  server.run (snapshot) ->
    connection.transmit snapshot, johnClient, 'receiveSnapshot'
    connection.transmit snapshot, janeClient, 'receiveSnapshot'
    renderServer(snapshot)

  startClients = ->
    johnClient.run 30, (entities, command) ->
      johnClient.lastRenderedEntites = entities
      connection.transmit command, server, 'input', 'john'
      renderClient 'john', entities
    janeClient.run 30, (entities, command) ->
      janeClient.lastRenderedEntites = entities
      connection.transmit command, server, 'input', 'jane'
      renderClient 'jane', entities

  setTimeout startClients, 1000
