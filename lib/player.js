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
  if (typeof module !== "undefined" && module !== null) {
    module.exports = Player;
  } else {
    window.Player = Player;
  }
}).call(this);
