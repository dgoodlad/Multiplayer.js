class Server
  constructor: ->
    # Rate at which the server updates the simulation
    # 20 fps makes for a nice round 50ms frame length, let's try that...
    @fps = 20
    @players = {}
    @time = 0

  addPlayer: (name, player) ->
    @players[name] = player
    player.time = @time

  run: (callback) ->
    frameLength = 1000 / @fps
    gameLoop = =>
      t1 = new Date().getTime()
      @time += 1
      # TODO update non-player entities
      callback @snapshot()
      t2 = new Date().getTime()
      @timeout = setTimeout gameLoop, frameLength - (t2 - t1)
    gameLoop()

  stop: ->
    clearTimeout @timeout if @timeout?

  input: (name, command) ->
    return if command.time < @players[name].time
    dt = @frameTimeInSeconds(command.time - @players[name].time)
    @players[name].updatePhysics dt, command.inputs if dt < 1
    @players[name].time = command.time

  frameTimeInSeconds: (time) ->
    time / @fps

  snapshot: ->
    snapshot =
      time: @time
      players: {}
    for name, player of @players
      snapshot.players[name] = @playerSnapshot(player)
    snapshot

  playerSnapshot: (player) ->
    time: player.time
    position: player.position
    velocity: player.velocity

if module?
  module.exports = Server
else
  window.Server = Server
