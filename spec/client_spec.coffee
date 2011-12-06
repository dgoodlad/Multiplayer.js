Client = require '../src/client'

beforeEach ->
  this.addMatchers
    toNearlyEqual: (expected, precision = 5) ->
      multiplier = Math.pow 10, precision
      actual = Math.round this.actual * multiplier
      expected = Math.round expected * multiplier
      actual == expected

describe "Client", ->
  client = null
  player = null

  beforeEach ->
    client = new Client
    player = client.localPlayer =
      jasmine.createSpyObj 'Player', ['calculatePhysics']

  it "should maintain a pair of the two most recent snapshots", ->
    client.receiveSnapshot { time: 1, players: {} }
    client.receiveSnapshot { time: 2, players: {} }
    expect(client.oldSnap.time).toEqual 1
    expect(client.nextSnap.time).toEqual 2

  describe "rendering a frame", ->
    beforeEach ->
      client.receiveSnapshot { time: 1.0, players: {} }
      client.receiveSnapshot { time: 2.0, players: {} }

    it "should roll over smoothly to using nextSnap", ->
      client.renderFrame(2)
      expect(client.oldSnap.time).toEqual 2

  describe "entity interpolation", ->
    beforeEach ->
      client.receiveSnapshot time: 1.0, players:
        'test':
          position: { x: 0, y: 0 }
      client.receiveSnapshot time: 2.0, players:
        'test':
          position: { x: 1, y: 2 }

    it "should render the entity at its first position", ->
      entities = client.renderFrame(1.0)
      expect(entities['test'].position).toEqual { x: 0, y: 0 }

    it "should interpolate the entity's position", ->
      entities = client.renderFrame(1.5)
      expect(entities['test'].position).toEqual { x: 0.5, y: 1.0 }

  describe "entity extrapolation", ->
    beforeEach ->
      client.receiveSnapshot time: 1.0, players:
        'test':
          position: { x: 0, y: 0 }
          velocity: { x: 1, y: 2 }
      client.receiveSnapshot time: 2.0, players:
        'test':
          position: { x: 1, y: 2 }
          velocity: { x: 1, y: 2 }

    it "should extrapolate the entity's position", ->
      entities = client.renderFrame(2.5)
      expect(entities['test'].position).toEqual { x: 1.5, y: 3 }

  describe "input handling", ->
    beforeEach ->
      client.receiveSnapshot { time: 1, players: {} }
      client.receiveSnapshot { time: 2, players: {} }

    it "should grab the user's input as a user command", ->
      client.renderFrame 1.5, { forward: true }
      expect(client.userCommands[0].time).toEqual 1.5
      expect(client.userCommands[0].input).toEqual { forward: true }

  describe "client-side prediction", ->
    beforeEach ->
      client.localPlayer.name = 'john'
      client.receiveSnapshot { time: 1, players: { 'john': time: 1, position: { x: 0, y: 0 } } }
      client.receiveSnapshot { time: 2, players: { 'john': time: 1, position: { x: 0, y: 0 } } }

    it "should replay a single un-acknowledged user command", ->
      client.renderFrame 1.25, { forward: true }
      client.renderFrame 1.5, {}
      expect(player.calculatePhysics.callCount).toEqual 1
      expect(player.calculatePhysics).toHaveBeenCalledWith 0.25, { forward: true }

    it "should replay multiple user commands", ->
      client.renderFrame 1.25, { forward: true }
      client.renderFrame 1.5, { right: true }
      client.renderFrame 1.75, { left: true }
      expect(player.calculatePhysics.callCount).toEqual 3
      expect(player.calculatePhysics.argsForCall[0]).toEqual [ 0.25, { forward: true } ]
      expect(player.calculatePhysics.argsForCall[1]).toEqual [ 0.25, { forward: true } ]
      expect(player.calculatePhysics.argsForCall[2]).toEqual [ 0.25, { right: true } ]

    it "should discard acknowledged user commands", ->
      client.renderFrame 1.5, { forward: true }
      client.renderFrame 2.0, { right: true }
      client.receiveSnapshot { time: 3, players: { 'john': time: 1.5, position: { x: 0.25, y: 0 } } }
      expect(client.userCommands).toEqual [ { time: 2.0, input: { right: true } } ]

