class Client
  constructor: (@serverFps) ->
    @userCommands = []

  run: (fps, callback) ->
    frameLength = 1000 / fps
    serverFrameLength = 1000 / @serverFps
    time = @oldSnap?.time or 0

    gameLoop = =>
      t1 = new Date().getTime()
      time += @serverFps / fps
      time = @oldSnap.time if @oldSnap? and @oldSnap.time > time
      entities = @renderFrame time, @readInput()
      command = @userCommands[@userCommands.length - 1]
      callback entities, command
      t2 = new Date().getTime()
      @timeout = setTimeout gameLoop, frameLength - (t2 - t1)
    gameLoop()

  receiveSnapshot: (snapshot) ->
    if @oldSnap? and @nextSnap?
      @oldSnap = @nextSnap
      @nextSnap = snapshot
    else if @oldSnap?
      @nextSnap = snapshot
    else
      @oldSnap = snapshot
    @expireUserCommands(snapshot)

  expireUserCommands: (latestSnap) ->
    if latestSnap.players[@localPlayer.name]
      lastAckTime = latestSnap.players[@localPlayer.name].time
      @userCommands = @userCommands.filter (command) -> command.time > lastAckTime

  renderFrame: (time, input = {}) ->
    if time >= @nextSnap?.time
      @oldSnap = @nextSnap
      @nextSnap = null
    if time == @oldSnap.time
      entities = @oldSnap.players
    else if @oldSnap? and @nextSnap?
      entities = @interpolate @oldSnap, @nextSnap, time
    else
      entities = @extrapolate @oldSnap, time

    @predict(@nextSnap or @oldSnap, @userCommands) if @userCommands.length > 0
    entities[@localPlayer.name].position = @localPlayer.position
    @userCommands.push time: time, inputs: input
    entities

  interpolate: (snap0, snap1, time) ->
    entities = {}
    interp = (time - snap0.time) / (snap1.time - snap0.time)
    for name, player of snap0.players
      p0 = player.position
      p1 = snap1.players[name].position
      entities[name] =
        position:
          x: p0.x + (p1.x - p0.x) * interp
          y: p0.y + (p1.y - p0.y) * interp
    entities

  extrapolate: (snap, time) ->
    entities = {}
    extrap = time - snap.time
    for name, player of snap.players
      p = player.position
      v = player.velocity
      entities[name] =
        position:
          x: p.x + v.x * extrap
          y: p.y + v.y * extrap
    entities

  predict: (snap, commands) ->
    if snap.players[@localPlayer.name]
      @localPlayer.position.x = snap.players[@localPlayer.name].position.x
      @localPlayer.position.y = snap.players[@localPlayer.name].position.y
      @localPlayer.velocity.x = snap.players[@localPlayer.name].velocity.x
      @localPlayer.velocity.y = snap.players[@localPlayer.name].velocity.y
      t = lastAckTime = snap.players[@localPlayer.name].time
      for command in commands
        if command.time > lastAckTime
          dt = @frameTimeInSeconds(command.time - t)
          @localPlayer.calculatePhysics(dt, command.inputs)
          t = command.time

  frameTimeInSeconds: (time) ->
    time / @serverFps

if module?
  module.exports = Client
else
  window.Client = Client
