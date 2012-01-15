var require = function (file, cwd) {
    var resolved = require.resolve(file, cwd || '/');
    var mod = require.modules[resolved];
    if (!mod) throw new Error(
        'Failed to resolve module ' + file + ', tried ' + resolved
    );
    var res = mod._cached ? mod._cached : mod();
    return res;
}

require.paths = [];
require.modules = {};
require.extensions = [".js",".coffee"];

require._core = {
    'assert': true,
    'events': true,
    'fs': true,
    'path': true,
    'vm': true
};

require.resolve = (function () {
    return function (x, cwd) {
        if (!cwd) cwd = '/';
        
        if (require._core[x]) return x;
        var path = require.modules.path();
        var y = cwd || '.';
        
        if (x.match(/^(?:\.\.?\/|\/)/)) {
            var m = loadAsFileSync(path.resolve(y, x))
                || loadAsDirectorySync(path.resolve(y, x));
            if (m) return m;
        }
        
        var n = loadNodeModulesSync(x, y);
        if (n) return n;
        
        throw new Error("Cannot find module '" + x + "'");
        
        function loadAsFileSync (x) {
            if (require.modules[x]) {
                return x;
            }
            
            for (var i = 0; i < require.extensions.length; i++) {
                var ext = require.extensions[i];
                if (require.modules[x + ext]) return x + ext;
            }
        }
        
        function loadAsDirectorySync (x) {
            x = x.replace(/\/+$/, '');
            var pkgfile = x + '/package.json';
            if (require.modules[pkgfile]) {
                var pkg = require.modules[pkgfile]();
                var b = pkg.browserify;
                if (typeof b === 'object' && b.main) {
                    var m = loadAsFileSync(path.resolve(x, b.main));
                    if (m) return m;
                }
                else if (typeof b === 'string') {
                    var m = loadAsFileSync(path.resolve(x, b));
                    if (m) return m;
                }
                else if (pkg.main) {
                    var m = loadAsFileSync(path.resolve(x, pkg.main));
                    if (m) return m;
                }
            }
            
            return loadAsFileSync(x + '/index');
        }
        
        function loadNodeModulesSync (x, start) {
            var dirs = nodeModulesPathsSync(start);
            for (var i = 0; i < dirs.length; i++) {
                var dir = dirs[i];
                var m = loadAsFileSync(dir + '/' + x);
                if (m) return m;
                var n = loadAsDirectorySync(dir + '/' + x);
                if (n) return n;
            }
            
            var m = loadAsFileSync(x);
            if (m) return m;
        }
        
        function nodeModulesPathsSync (start) {
            var parts;
            if (start === '/') parts = [ '' ];
            else parts = path.normalize(start).split('/');
            
            var dirs = [];
            for (var i = parts.length - 1; i >= 0; i--) {
                if (parts[i] === 'node_modules') continue;
                var dir = parts.slice(0, i + 1).join('/') + '/node_modules';
                dirs.push(dir);
            }
            
            return dirs;
        }
    };
})();

require.alias = function (from, to) {
    var path = require.modules.path();
    var res = null;
    try {
        res = require.resolve(from + '/package.json', '/');
    }
    catch (err) {
        res = require.resolve(from, '/');
    }
    var basedir = path.dirname(res);
    
    var keys = (Object.keys || function (obj) {
        var res = [];
        for (var key in obj) res.push(key)
        return res;
    })(require.modules);
    
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (key.slice(0, basedir.length + 1) === basedir + '/') {
            var f = key.slice(basedir.length);
            require.modules[to + f] = require.modules[basedir + f];
        }
        else if (key === basedir) {
            require.modules[to] = require.modules[basedir];
        }
    }
};

require.define = function (filename, fn) {
    var dirname = require._core[filename]
        ? ''
        : require.modules.path().dirname(filename)
    ;
    
    var require_ = function (file) {
        return require(file, dirname)
    };
    require_.resolve = function (name) {
        return require.resolve(name, dirname);
    };
    require_.modules = require.modules;
    require_.define = require.define;
    var module_ = { exports : {} };
    
    require.modules[filename] = function () {
        require.modules[filename]._cached = module_.exports;
        fn.call(
            module_.exports,
            require_,
            module_,
            module_.exports,
            dirname,
            filename
        );
        require.modules[filename]._cached = module_.exports;
        return module_.exports;
    };
};

if (typeof process === 'undefined') process = {};

if (!process.nextTick) process.nextTick = (function () {
    var queue = [];
    var canPost = typeof window !== 'undefined'
        && window.postMessage && window.addEventListener
    ;
    
    if (canPost) {
        window.addEventListener('message', function (ev) {
            if (ev.source === window && ev.data === 'browserify-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);
    }
    
    return function (fn) {
        if (canPost) {
            queue.push(fn);
            window.postMessage('browserify-tick', '*');
        }
        else setTimeout(fn, 0);
    };
})();

if (!process.title) process.title = 'browser';

if (!process.binding) process.binding = function (name) {
    if (name === 'evals') return require('vm')
    else throw new Error('No such module')
};

if (!process.cwd) process.cwd = function () { return '.' };

require.define("path", function (require, module, exports, __dirname, __filename) {
    function filter (xs, fn) {
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (fn(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length; i >= 0; i--) {
    var last = parts[i];
    if (last == '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Regex to split a filename into [*, dir, basename, ext]
// posix version
var splitPathRe = /^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/;

// path.resolve([from ...], to)
// posix version
exports.resolve = function() {
var resolvedPath = '',
    resolvedAbsolute = false;

for (var i = arguments.length; i >= -1 && !resolvedAbsolute; i--) {
  var path = (i >= 0)
      ? arguments[i]
      : process.cwd();

  // Skip empty and invalid entries
  if (typeof path !== 'string' || !path) {
    continue;
  }

  resolvedPath = path + '/' + resolvedPath;
  resolvedAbsolute = path.charAt(0) === '/';
}

// At this point the path should be resolved to a full absolute path, but
// handle relative paths to be safe (might happen when process.cwd() fails)

// Normalize the path
resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
var isAbsolute = path.charAt(0) === '/',
    trailingSlash = path.slice(-1) === '/';

// Normalize the path
path = normalizeArray(filter(path.split('/'), function(p) {
    return !!p;
  }), !isAbsolute).join('/');

  if (!path && !isAbsolute) {
    path = '.';
  }
  if (path && trailingSlash) {
    path += '/';
  }
  
  return (isAbsolute ? '/' : '') + path;
};


// posix version
exports.join = function() {
  var paths = Array.prototype.slice.call(arguments, 0);
  return exports.normalize(filter(paths, function(p, index) {
    return p && typeof p === 'string';
  }).join('/'));
};


exports.dirname = function(path) {
  var dir = splitPathRe.exec(path)[1] || '';
  var isWindows = false;
  if (!dir) {
    // No dirname
    return '.';
  } else if (dir.length === 1 ||
      (isWindows && dir.length <= 3 && dir.charAt(1) === ':')) {
    // It is just a slash or a drive letter with a slash
    return dir;
  } else {
    // It is a full dirname, strip trailing slash
    return dir.substring(0, dir.length - 1);
  }
};


exports.basename = function(path, ext) {
  var f = splitPathRe.exec(path)[2] || '';
  // TODO: make this comparison case-insensitive on windows?
  if (ext && f.substr(-1 * ext.length) === ext) {
    f = f.substr(0, f.length - ext.length);
  }
  return f;
};


exports.extname = function(path) {
  return splitPathRe.exec(path)[3] || '';
};

});

require.define("/client.coffee", function (require, module, exports, __dirname, __filename) {
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
  if (typeof module != "undefined" && module !== null) {
    module.exports = Client;
  } else {
    window.Client = Client;
  }
}).call(this);

});

require.define("/server.coffee", function (require, module, exports, __dirname, __filename) {
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
  if (typeof module != "undefined" && module !== null) {
    module.exports = Server;
  } else {
    window.Server = Server;
  }
}).call(this);

});

require.define("/player.coffee", function (require, module, exports, __dirname, __filename) {
    (function() {
  var Player, cap, magnitude, rotate;
  rotate = function(v, theta) {
    var x, y;
    x = v.x * Math.cos(theta) - v.y * Math.sin(theta);
    y = v.y * Math.cos(theta) + v.x * Math.sin(theta);
    return {
      x: x,
      y: y
    };
  };
  magnitude = function(v) {
    return Math.sqrt(v.x * v.x + v.y * v.y, 0.5);
  };
  cap = function(v, max) {
    var mag;
    mag = magnitude(v);
    if (mag < max) {
      return v;
    } else {
      return {
        x: v.x / mag * max,
        y: v.y / mag * max
      };
    }
  };
  Player = (function() {
    Player.maxSpeed = 10;
    function Player(initialState) {
      this.position = initialState.position;
      this.velocity = {
        x: 0,
        y: 0
      };
      this.directionVector = {
        x: 1.0,
        y: 0
      };
    }
    Player.prototype.updatePhysics = function(dt, inputs) {
      var acceleration, speed;
      if (inputs.right) {
        this.velocity = rotate(this.velocity, Math.PI / -2 * dt);
        this.directionVector = rotate(this.directionVector, Math.PI / -2 * dt);
      }
      if (inputs.left) {
        this.velocity = rotate(this.velocity, Math.PI / 2 * dt);
        this.directionVector = rotate(this.directionVector, Math.PI / 2 * dt);
      }
      speed = this.speed();
      if (inputs.forward) {
        acceleration = {
          x: this.directionVector.x * 1.0,
          y: this.directionVector.y * 1.0
        };
      } else {
        acceleration = {
          x: this.directionVector.x * speed * -1 / dt,
          y: this.directionVector.y * speed * -1 / dt
        };
      }
      this.position.x += this.velocity.x * dt + 0.5 * acceleration.x * dt * dt;
      this.position.y += this.velocity.y * dt + 0.5 * acceleration.y * dt * dt;
      this.velocity.x += acceleration.x * dt;
      this.velocity.y += acceleration.y * dt;
      this.velocity = cap(this.velocity, Player.maxSpeed);
      return this;
    };
    Player.prototype.speed = function() {
      return magnitude(this.velocity);
    };
    return Player;
  })();
  if (typeof module != "undefined" && module !== null) {
    module.exports = Player;
  } else {
    window.Player = Player;
  }
}).call(this);

});

require.define("/main.coffee", function (require, module, exports, __dirname, __filename) {
    (function() {
  module.exports = {
    Client: require('./client'),
    Server: require('./server'),
    Player: require('./player')
  };
}).call(this);

});
require("/main.coffee");

