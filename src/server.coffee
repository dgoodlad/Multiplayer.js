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
    frame = 0
    frameLength = 1000 / @fps
    gameLoop = =>
      t1 = new Date().milliseconds
      frame += 1
      state = @update frameLength
      callback frame, state
      t2 = new Date().milliseconds
      setTimeout gameLoop, frameLength - (t2 - t1)
    gameLoop()

  update: (dt) ->
    @world.update dt
    @world.getState()

  input: (name, command) ->
    return if command.time < @players[name].time
    dt = command.time - @players[name].time
    @players[name].updatePhysics dt, command.inputs
    @players[name].time = command.time

module.exports = Server
