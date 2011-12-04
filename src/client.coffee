class Client
  receiveSnapshot: (snapshot) ->
    @oldSnap = @nextSnap
    @nextSnap = snapshot

  renderFrame: (time) ->
    if time >= @nextSnap.time
      @oldSnap = @nextSnap
      @nextSnap = null
    if time == @oldSnap.time
      @oldSnap.players
    else if @oldSnap? and @nextSnap?
      entities = {}
      interp = (time - @oldSnap.time) / (@nextSnap.time - @oldSnap.time)
      for name, player of @oldSnap.players
        p0 = player.position
        p1 = @nextSnap.players[name].position
        entities[name] =
          position:
            x: (p0.x + p1.x) * interp
            y: (p0.y + p1.y) * interp
      entities
    else
      entities = {}
      extrap = time - @oldSnap.time
      for name, player of @oldSnap.players
        p = player.position
        v = player.velocity
        entities[name] = 
          position:
            x: p.x + v.x * extrap
            y: p.y + v.y * extrap
      entities


module.exports = Client
