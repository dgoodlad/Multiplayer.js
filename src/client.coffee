class Client
  receiveSnapshot: (snapshot) ->
    @oldSnap = @nextSnap
    @nextSnap = snapshot

  renderFrame: (time) ->
    if time >= @nextSnap.time
      @oldSnap = @nextSnap
      @nextSnap = null
    if time == @oldSnap.time
      entities = @oldSnap.players
    else if @oldSnap? and @nextSnap?
      entities = @interpolate @oldSnap, @nextSnap, time
    else
      entities = @extrapolate @oldSnap, time

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


module.exports = Client
