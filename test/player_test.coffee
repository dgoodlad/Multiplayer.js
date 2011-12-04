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

    'should be moving forward': (player) ->
      assert.deepEqual player.velocity, { x: 1.0, y: 0 }

    'should move forward': (player) ->
      assert.deepEqual player.position, { x: 0.5, y: 0 }

  'when told to move forward for a very long time':
    topic: ->
      new Player(position: { x: 0, y: 0 })
        .updatePhysics(100.0, { forward: true })

    'should have hit maximum velocity': (player) ->
      assert.equal player.speed(), Player.maxSpeed

  'when told to turn right':
    topic: ->
      new Player(position: { x: 0, y: 0 }).updatePhysics(1.0, { right: true })

    'should have turned right': (player) ->
      assert.nearlyEqual player.directionVector.x, 0
      assert.nearlyEqual player.directionVector.y, -1.0

  'when told to turn left':
    topic: ->
      new Player(position: { x: 0, y: 0 }).updatePhysics(1.0, { left: true })

    'should have turned left': (player) ->
      assert.nearlyEqual player.directionVector.x, 0
      assert.nearlyEqual player.directionVector.y, 1.0

  'when told to stop turning':
    topic: ->
      new Player(position: { x: 0, y: 0 })
        .updatePhysics(1.0, { left: true })
        .updatePhysics(1.0, {})

  'when given a complex sequence of movements':
    topic: ->
      new Player(position: { x: 0, y: 0 })
        .updatePhysics(0.25, { forward: true, right: true })
        .updatePhysics(0.25, { forward: true })
        .updatePhysics(0.25, { forward: true })
        .updatePhysics(0.25, { left: true })
        .updatePhysics(0.25, {})

    'should be stopped': (player) ->
      assert.nearlyEqual player.velocity.x, 0.0
      assert.nearlyEqual player.velocity.y, 0.0

    'should be facing the right direction': (player) ->
      assert.nearlyEqual player.directionVector.x, 1.0
      assert.nearlyEqual player.directionVector.y, 0.0

    'should have moved appropriately': (player) ->
      # dir.x = .923879533
      # dir.y = -.382683432
      #
      #   .03125 @ -Math.PI / 8 radians; speed = 0.25
      #   .09375 @ -Math.PI / 8 radians; speed = 0.5
      #   .15625 @ -Math.PI / 8 radians; speed = 0.75
      # = .28125 @ -Math.PI / 8 radians
      # = (.259841119, -.107629715)
      #
      #   .09375 @ 0 radians;
      # = (.09375, 0)
      #
      # = (.353591119, -.107629715)
      assert.nearlyEqual player.position.x, 0.353591119
      assert.nearlyEqual player.position.y, -.107629715

.export module
