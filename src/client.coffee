class Client
  constructor: ->
    @userCommands = []

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
    if time >= @nextSnap.time
      @oldSnap = @nextSnap
      @nextSnap = null
    if time == @oldSnap.time
      entities = @oldSnap.players
    else if @oldSnap? and @nextSnap?
      entities = @interpolate @oldSnap, @nextSnap, time
    else
      entities = @extrapolate @oldSnap, time

    @predict(@nextSnap or @oldSnap, @userCommands) if @userCommands.length > 0
    @userCommands.push time: time, input: input
    entities

  interpolate: (snap0, snap1, time) ->
    entities = {}
    interp = (time - snap0.time) / (snap1.time - snap0.time)
    for name, player of snap0.players
      p0 = player.position
      p1 = snap1.players[name].position
      entities[name] =
        position:
          x: (p0.x + p1.x) * interp
          y: (p0.y + p1.y) * interp
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
      t = lastAckTime = snap.players[@localPlayer.name].time
      for command in commands
        if command.time > lastAckTime
          @localPlayer.calculatePhysics(command.time - t, command.input)
          t = command.time

module.exports = Client
