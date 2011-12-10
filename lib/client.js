(function() {
  var Client;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Client = (function() {
    function Client(serverFps) {
      this.serverFps = serverFps;
      this.userCommands = [];
    }
    Client.prototype.run = function(fps, callback) {
      var frameLength, gameLoop, serverFrameLength, time, _ref;
      frameLength = 1000 / fps;
      serverFrameLength = 1000 / this.serverFps;
      time = ((_ref = this.oldSnap) != null ? _ref.time : void 0) || 0;
      gameLoop = __bind(function() {
        var command, entities, t1, t2;
        t1 = new Date().getTime();
        time += this.serverFps / fps;
        if ((this.oldSnap != null) && this.oldSnap.time > time) {
          time = this.oldSnap.time;
        }
        entities = this.renderFrame(time, this.readInput());
        command = this.userCommands[this.userCommands.length - 1];
        callback(entities, command);
        t2 = new Date().getTime();
        return this.timeout = setTimeout(gameLoop, frameLength - (t2 - t1));
      }, this);
      return gameLoop();
    };
    Client.prototype.receiveSnapshot = function(snapshot) {
      if ((this.oldSnap != null) && (this.nextSnap != null)) {
        this.oldSnap = this.nextSnap;
        this.nextSnap = snapshot;
      } else if (this.oldSnap != null) {
        this.nextSnap = snapshot;
      } else {
        this.oldSnap = snapshot;
      }
      return this.expireUserCommands(snapshot);
    };
    Client.prototype.expireUserCommands = function(latestSnap) {
      var lastAckTime;
      if (latestSnap.players[this.localPlayer.name]) {
        lastAckTime = latestSnap.players[this.localPlayer.name].time;
        return this.userCommands = this.userCommands.filter(function(command) {
          return command.time > lastAckTime;
        });
      }
    };
    Client.prototype.renderFrame = function(time, input) {
      var entities, _ref;
      if (input == null) {
        input = {};
      }
      if (time >= ((_ref = this.nextSnap) != null ? _ref.time : void 0)) {
        this.oldSnap = this.nextSnap;
        this.nextSnap = null;
      }
      if (time === this.oldSnap.time) {
        entities = this.oldSnap.players;
      } else if ((this.oldSnap != null) && (this.nextSnap != null)) {
        entities = this.interpolate(this.oldSnap, this.nextSnap, time);
      } else {
        entities = this.extrapolate(this.oldSnap, time);
      }
      if (this.userCommands.length > 0) {
        this.predict(this.nextSnap || this.oldSnap, this.userCommands);
      }
      entities[this.localPlayer.name].position = this.localPlayer.position;
      this.userCommands.push({
        time: time,
        inputs: input
      });
      return entities;
    };
    Client.prototype.interpolate = function(snap0, snap1, time) {
      var entities, interp, name, p0, p1, player, _ref;
      entities = {};
      interp = (time - snap0.time) / (snap1.time - snap0.time);
      _ref = snap0.players;
      for (name in _ref) {
        player = _ref[name];
        p0 = player.position;
        p1 = snap1.players[name].position;
        entities[name] = {
          position: {
            x: p0.x + (p1.x - p0.x) * interp,
            y: p0.y + (p1.y - p0.y) * interp
          }
        };
      }
      return entities;
    };
    Client.prototype.extrapolate = function(snap, time) {
      var entities, extrap, name, p, player, v, _ref;
      entities = {};
      extrap = time - snap.time;
      _ref = snap.players;
      for (name in _ref) {
        player = _ref[name];
        p = player.position;
        v = player.velocity;
        entities[name] = {
          position: {
            x: p.x + v.x * extrap,
            y: p.y + v.y * extrap
          }
        };
      }
      return entities;
    };
    Client.prototype.predict = function(snap, commands) {
      var command, dt, lastAckTime, t, _i, _len, _results;
      if (snap.players[this.localPlayer.name]) {
        this.localPlayer.position.x = snap.players[this.localPlayer.name].position.x;
        this.localPlayer.position.y = snap.players[this.localPlayer.name].position.y;
        this.localPlayer.velocity.x = snap.players[this.localPlayer.name].velocity.x;
        this.localPlayer.velocity.y = snap.players[this.localPlayer.name].velocity.y;
        t = lastAckTime = snap.players[this.localPlayer.name].time;
        _results = [];
        for (_i = 0, _len = commands.length; _i < _len; _i++) {
          command = commands[_i];
          _results.push(command.time > lastAckTime ? (dt = this.frameTimeInSeconds(command.time - t), this.localPlayer.calculatePhysics(dt, command.inputs), t = command.time) : void 0);
        }
        return _results;
      }
    };
    Client.prototype.frameTimeInSeconds = function(time) {
      return time / this.serverFps;
    };
    return Client;
  })();
  if (typeof module !== "undefined" && module !== null) {
    module.exports = Client;
  } else {
    window.Client = Client;
  }
}).call(this);
