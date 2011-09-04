BAT_ACCELERATION = 0.40
BAT_TERMINAL_VELOCITY = 5
BAT_FRICTION = 0.10
BALL_ACCELERATION = 5
BALL_TERMINAL_VELOCITY = 5
BALL_FRICTION = 0
LEFT = 0
RIGHT = 1

class Entity
  x: 0, y: 0, vx: 0, vy: 0 
  constructor: (@context, @maxX, @maxY, @minX, @minY, @offsetX, @offsetY, @a, @tv, @f) ->

  update: ->
    # Apply friction
    @vx -= @f if @vx > 0
    @vx += @f if @vx < 0
    @vy -= @f if @vy > 0
    @vy += @f if @vy < 0

    # Make sure we dont go faster than terminal velocity
    @vx = @tv if @vx > @tv
    @vx = -@tv if @vx < -@tv
    @vy = @tv if @vy > @tv
    @vy = -@tv if @vy < -@tv

    # Update the entitys co-ordinates
    @x += @vx
    @y += @vy

    @checkBoundary()
  
  checkBoundary: ->
    @x = @maxX-@w if @x+@w > @maxX
    @x = @minX if @x < @minX
    @y = @maxY-@h if @y+@h > @maxY
    @y = @minY if @y < @minY

  draw: ->
    @context.fillStyle = 'rgba(0,0,0,0.8)'
    @context.fillRect @x+@offsetX, @y+@offsetY, @w, @h

  accelX: -> @vx += @a
  accelY: -> @vy += @a
  decelX: -> @vx -= @a
  decelY: -> @vy -= @a

class Bat extends Entity
  w: 40, h: 175

class Ball extends Entity
  w: 40, h: 40, x: 200, y: 200, winner: null

  checkWinner: -> @winner

  checkBoundary: ->
    if @x+@w > @maxX
      @winner = 1
    if @x < @minX
      @winner = 2

    # If we hit the top or the bottom we need to bounce
    @vy = -@vy if @y+@h > @maxY or @y < @minY
  
  checkCollision: (e, bat) -> 
    x = @x + @offsetX
    y = @y + @offsetY
    ex = e.x + e.offsetX
    ey = e.y + e.offsetY
    if y >= ey and y <= ey+e.h
      if bat is LEFT and x < ex+e.w
        @x += BAT_TERMINAL_VELOCITY / 2
        @vx = -@vx
      if bat is RIGHT and x+@w > ex
        @x -= BAT_TERMINAL_VELOCITY / 2
        @vx = -@vx

  draw: ->
    @context.fillStyle = 'rgba(0,0,0,0.8)'
    @context.fillRect @x+@offsetX, @y+@offsetY, @w, @h
  
class PongApp
  main: ->
    @createCanvas()
    @addKeyObservers()
    @startNewGame()

  startNewGame: ->
    @entities = []
    @entities.push(new Bat @context, @canvas.width, @canvas.height, 0, 0, 30, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION)
    @entities.push(new Bat @context, @canvas.width, @canvas.height, 0, 0, @canvas.width - 70, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION)
    @entities.push(new Ball @context, @canvas.width, @canvas.height, 0, 0, 0, 0, BALL_ACCELERATION, BALL_TERMINAL_VELOCITY, BALL_FRICTION)
    
    @entities[2].vx = 5
    @entities[2].vy = 5
    
    @runLoop()
  
  runLoop: ->
    setTimeout =>
      # Adjust for player key input
      @entities[0].decelY() if @aPressed
      @entities[0].accelY() if @zPressed
      @entities[1].decelY() if @upPressed
      @entities[1].accelY() if @downPressed

      # Update position of entities
      @entities.forEach (e) -> e.update()

      # Check for ball collsions with bats
      @entities[2].checkCollision @entities[0], LEFT
      @entities[2].checkCollision @entities[1], RIGHT

      # Check for winner
      player = @entities[2].checkWinner()
      if player
        @terminateRunLoop = true
        @score = [0, 0] unless @score
        @score[player-1]++
        @notifyCurrentUser "Player #{player} wins! Score: #{@score[0]} - #{@score[1]}. New game starting in 3 seconds."
        setTimeout =>
          @notifyCurrentUser ''
          @terminateRunLoop = false
          @startNewGame()
        , 3000

      # Clear the Canvas
      @clearCanvas()
    
      # Redraw game entities
      @entities.forEach (e) -> e.draw()

      # Run again unless we have been killed
      @runLoop() unless @terminateRunLoop
    , 10

  notifyCurrentUser: (message) ->
    document.getElementById('message').innerHTML = message

  # Run when the game is quit to clean up everything we create
  cleanup: ->
    @terminateRunLoop = true
    @clearCanvas()

  # Creates an overlay for the sceen and a canvas to draw the game on
  createCanvas: ->
    @canvas = document.getElementById 'canvas'
    @context = @canvas.getContext '2d'
    @canvas.width = document.width
    @canvas.height = document.height

  clearCanvas: ->
    @context.clearRect 0, 0, @canvas.width, @canvas.height

  addKeyObservers: ->
    document.addEventListener 'keydown', (e) =>
      switch e.keyCode
        when 40 then @downPressed = true
        when 38 then @upPressed = true
        when 90 then @zPressed = true
        when 65 then @aPressed = true
    , false
  
    document.addEventListener 'keyup', (e) =>
      switch e.keyCode
        when 27 then @cleanup()
        when 40 then @downPressed = false
        when 38 then @upPressed = false
        when 90 then @zPressed = false
        when 65 then @aPressed = false
    , false

pong = new PongApp
pong.main()