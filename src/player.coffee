rotate = (v, theta) ->
  x = v.x * Math.cos(theta) - v.y * Math.sin(theta)
  y = v.y * Math.cos(theta) + v.x * Math.sin(theta)
  { x: x, y: y }

class Player
  constructor: (initialState) ->
    @position = initialState.position
    @velocity = { x: 0, y: 0 }
    @acceleration = { x: 0, y: 0 }

    # Unit vector pointint in the direction the player is facing
    @directionVector = { x: 1.0, y: 0 }
    @angularVelocity = 0 # Radians / time

  updatePhysics: (dt, inputs) ->
    if inputs.forward
      @acceleration.x = @directionVector.x
      @acceleration.y = @directionVector.y

    if inputs.right
      @angularVelocity = Math.PI / -2
    else if inputs.left
      @angularVelocity = Math.PI / 2

    if @angularVelocity != 0
      @directionVector = rotate(@directionVector, @angularVelocity * dt)

    @position.x = @velocity.x * dt + 0.5 * @acceleration.x * @acceleration.x
    @position.y = @velocity.y * dt + 0.5 * @acceleration.y * @acceleration.y
    @velocity.x = @velocity.x + @acceleration.x * dt
    @velocity.y = @velocity.y + @acceleration.y * dt
    this

module.exports = Player
