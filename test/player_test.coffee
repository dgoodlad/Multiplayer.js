vows = require 'vows'
assert = require 'assert'

assert.nearlyEqual = (actual, expected, precision = 5) ->
  multiplier = Math.pow 10, precision
  actual = Math.round actual * multiplier
  expected = Math.round expected * multiplier
  assert.equal actual, expected

Player = require '../src/player'

vows.describe("Player").addBatch
  'when given no input':
    topic: -> new Player(position: { x: 0, y: 0 }).updatePhysics(1.0, {})

    'should remain stationary': (player) ->
      assert.deepEqual player.position, { x: 0, y: 0 }

  'when told to move forward':
    topic: ->
      new Player(position: { x: 0, y: 0 }).updatePhysics(1.0, { forward: true })

    'should accelerate forward': (player) ->
      assert.deepEqual player.acceleration, { x: 1.0, y: 0 }

    'should be moving forward': (player) ->
      assert.deepEqual player.velocity, { x: 1.0, y: 0 }

    'should move forward': (player) ->
      assert.deepEqual player.position, { x: 0.5, y: 0 }

  'when told to turn right':
    topic: ->
      new Player(position: { x: 0, y: 0 }).updatePhysics(1.0, { right: true })

    'should be turning right': (player) ->
      assert.equal player.angularVelocity, Math.PI / -2

    'should have turned right': (player) ->
      assert.nearlyEqual player.directionVector.x, 0
      assert.nearlyEqual player.directionVector.y, -1.0

  'when told to turn left':
    topic: ->
      new Player(position: { x: 0, y: 0 }).updatePhysics(1.0, { left: true })

    'should be turning left': (player) ->
      assert.equal player.angularVelocity, Math.PI / 2

    'should have turned left': (player) ->
      assert.nearlyEqual player.directionVector.x, 0
      assert.nearlyEqual player.directionVector.y, 1.0

.export module
