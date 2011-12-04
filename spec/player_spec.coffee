Player = require '../src/player'

beforeEach ->
  this.addMatchers
    toBeNearlyEqual: (expected, precision = 5) ->
      multiplier = Math.pow 10, precision
      actual = Math.round this.actual * multiplier
      expected = Math.round expected * multiplier
      actual == expected

describe "Player", ->
  player = null

  beforeEach ->
    player = new Player(position: { x: 0, y: 0 })

  it "should remain stationary given no inputs", ->
    player.updatePhysics 1.0, {}
    expect(player.position).toEqual { x: 0, y: 0 }

  it "should move forward", ->
    player.updatePhysics 1.0, { forward: true }
    expect(player.velocity).toEqual { x: 1.0, y: 0 }
    expect(player.position).toEqual { x: 0.5, y: 0 }

  it "should reach a maximum speed", ->
    player.updatePhysics 100.0, { forward: true }
    expect(player.speed()).toEqual Player.maxSpeed

  it "should turn right", ->
    player.updatePhysics 1.0, { right: true }
    expect(player.directionVector.x).toBeNearlyEqual 0
    expect(player.directionVector.y).toBeNearlyEqual -1.0

  it "should turn left", ->
    player.updatePhysics 1.0, { left: true }
    expect(player.directionVector.x).toBeNearlyEqual 0
    expect(player.directionVector.y).toBeNearlyEqual 1.0

  it "should handle a complex sequence of inputs", ->
    player
      .updatePhysics(0.25, { forward: true, right: true })
      .updatePhysics(0.25, { forward: true })
      .updatePhysics(0.25, { forward: true })
      .updatePhysics(0.25, { left: true })
      .updatePhysics(0.25, {})
    # Stopped
    expect(player.velocity.x).toBeNearlyEqual 0.0
    expect(player.velocity.y).toBeNearlyEqual 0.0
    # Facing the original direction (turned right then back left again)
    expect(player.directionVector.x).toBeNearlyEqual 1.0
    expect(player.directionVector.y).toBeNearlyEqual 0.0
    # Moved a little
    expect(player.position.x).toBeNearlyEqual 0.353591119
    expect(player.position.y).toBeNearlyEqual -.107629715

