vows = require 'vows'
assert = require 'assert'

Server = require '../src/server'

vows.describe("Server").addBatch
  'with no players':
    topic: ->
      server = new Server

    'should have an empty list of players': (server) ->
      assert.isEmpty server.players

  'with one player':
    topic: ->
      server = new Server
      stub = (dt, inputs) ->
        stub.called = true
        stub.dt = dt
        stub.inputs = inputs
      server.addPlayer 'test', updatePhysics: stub
      server

    'should be able to find its player': (server) ->
      assert.isObject server.players['test']

    'after receiving an input command':
      topic: (server) ->
        server.input 'test', { time: 1.0, inputs: { forward: true } }
        server

      'should update the players time': (server) ->
        assert.equal server.players['test'].time, 1.0

      'should update the players physics': (server) ->
        player = server.players['test']
        assert.isTrue player.updatePhysics.called
        assert.equal player.updatePhysics.dt, 1.0
        assert.deepEqual player.updatePhysics.inputs, forward: true

      'after receiving an out-dated input command':
        topic: (server) ->
          server.players['test'].updatePhysics.called = false
          server.input 'test', { time: 0.5, inputs: { left: true } }
          server

        'should not update the players time': (server) ->
          assert.notEqual server.players['test'].time, 0.5

        'should not update the players physics': (server) ->
          assert.isFalse server.players['test'].updatePhysics.called

        'after receiving another input command':
          topic: (server) ->
            server.players['test'].updatePhysics.called = false
            server.input 'test', { time: 1.5, inputs: { right: true } }
            server

          'should update the players time': (server) ->
            assert.equal server.players['test'].time, 1.5

          'should update the players physics': (server) ->
            player = server.players['test']
            assert.isTrue player.updatePhysics.called
            assert.equal player.updatePhysics.dt, 0.5
            assert.deepEqual player.updatePhysics.inputs, right: true

.export module
