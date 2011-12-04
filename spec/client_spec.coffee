Client = require '../src/client'

describe "Client", ->
  client = null

  beforeEach ->
    client = new Client

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

    xit "should run client-side prediction", ->

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

