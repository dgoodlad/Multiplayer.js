rotate = (v, theta) ->
  x = v.x * Math.cos(theta) - v.y * Math.sin(theta)
  y = v.y * Math.cos(theta) + v.x * Math.sin(theta)
  { x: x, y: y }

magnitude = (v) ->
  Math.sqrt(v.x * v.x + v.y * v.y, 0.5)

cap = (v, max) ->
  mag = magnitude(v)
  if mag < max
    v
  else
    x: v.x / mag * max
    y: v.y / mag * max

class Player
  @maxSpeed = 10

  constructor: (initialState) ->
    @position = initialState.position
    @velocity = { x: 0, y: 0 }

    # Unit vector pointint in the direction the player is facing
    @directionVector = { x: 1.0, y: 0 }

  updatePhysics: (dt, inputs) ->
    if inputs.right
      @velocity = rotate @velocity, Math.PI / -2 * dt
      @directionVector = rotate @directionVector, Math.PI / -2 * dt
    if inputs.left
      @velocity = rotate @velocity, Math.PI / 2 * dt
      @directionVector = rotate @directionVector, Math.PI / 2 * dt

    speed = @speed()
    if inputs.forward
      acceleration =
        x: @directionVector.x * 1.0
        y: @directionVector.y * 1.0
    else
      acceleration =
        x: @directionVector.x * speed * -1 / dt
        y: @directionVector.y * speed * -1 / dt

    @position.x += @velocity.x * dt + 0.5 * acceleration.x * dt * dt
    @position.y += @velocity.y * dt + 0.5 * acceleration.y * dt * dt
    @velocity.x += acceleration.x * dt
    @velocity.y += acceleration.y * dt
    @velocity = cap @velocity, Player.maxSpeed
    this

  speed: ->
    magnitude @velocity

if module?
  module.exports = Player
else
  window.Player = Player
