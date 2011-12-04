Server = require '../src/server'

describe "Server", ->
  [server, player] = [null, null]

  beforeEach ->
    server = new Server
    player =
      position: { x: 0, y: 0 }
      velocity: { x: 0, y: 0 }
      updatePhysics: ->
    server.addPlayer 'test', player
    spyOn player, 'updatePhysics'

  it "should handle a single input command", ->
    server.input 'test', { time: 1.0, inputs: { forward: true } }
    expect(player.time).toEqual 1.0
    expect(player.updatePhysics).toHaveBeenCalledWith 1.0, { forward: true }

  it "should ignore old input commands", ->
    server.input 'test', { time: 1.0, inputs: { forward: true } }
    server.input 'test', { time: 0.5, inputs: { right: true } }
    expect(player.time).toEqual 1.0
    expect(player.updatePhysics).toHaveBeenCalledWith 1.0, { forward: true }
    expect(player.updatePhysics.callCount).toEqual 1

  it "should handle multiple input commands", ->
    server.input 'test', { time: 1.0, inputs: { forward: true } }
    server.input 'test', { time: 1.5, inputs: { left: true } }
    expect(player.time).toEqual 1.5
    expect(player.updatePhysics).toHaveBeenCalledWith 1.0, { forward: true }
    expect(player.updatePhysics).toHaveBeenCalledWith 0.5, { left: true }
    expect(player.updatePhysics.callCount).toEqual 2

  it "should generate a snapshot of the world", ->
    snapshot = server.snapshot()
    expect(snapshot).toEqual
      time: 0
      players:
        'test':
          time: 0
          position: { x: 0, y: 0 }
          velocity: { x: 0, y: 0 }
