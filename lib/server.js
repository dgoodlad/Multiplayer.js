(function() {
  var Server;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Server = (function() {
    function Server() {
      this.fps = 20;
      this.players = {};
      this.time = 0;
    }
    Server.prototype.addPlayer = function(name, player) {
      this.players[name] = player;
      return player.time = this.time;
    };
    Server.prototype.run = function(callback) {
      var frameLength, gameLoop;
      frameLength = 1000 / this.fps;
      gameLoop = __bind(function() {
        var t1, t2;
        t1 = new Date().getTime();
        this.time += 1;
        callback(this.snapshot());
        t2 = new Date().getTime();
        return this.timeout = setTimeout(gameLoop, frameLength - (t2 - t1));
      }, this);
      return gameLoop();
    };
    Server.prototype.stop = function() {
      if (this.timeout != null) {
        return clearTimeout(this.timeout);
      }
    };
    Server.prototype.input = function(name, command) {
      var dt;
      if (command.time < this.players[name].time) {
        return;
      }
      dt = this.frameTimeInSeconds(command.time - this.players[name].time);
      if (dt < 1) {
        this.players[name].updatePhysics(dt, command.inputs);
      }
      return this.players[name].time = command.time;
    };
    Server.prototype.frameTimeInSeconds = function(time) {
      return time / this.fps;
    };
    Server.prototype.snapshot = function() {
      var name, player, snapshot, _ref;
      snapshot = {
        time: this.time,
        players: {}
      };
      _ref = this.players;
      for (name in _ref) {
        player = _ref[name];
        snapshot.players[name] = this.playerSnapshot(player);
      }
      return snapshot;
    };
    Server.prototype.playerSnapshot = function(player) {
      return {
        time: player.time,
        position: player.position,
        velocity: player.velocity
      };
    };
    return Server;
  })();
  if (typeof module !== "undefined" && module !== null) {
    module.exports = Server;
  } else {
    window.Server = Server;
  }
}).call(this);
