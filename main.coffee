# out: main.js

{Phaser} = window

scrW = 640
scrH = 480

game = null
layer = null
flayer = null

cursors = null
jumpMaxHeight = 100
keys = null
player = null
playerSpeed = 150

solidTileIndices = [2, 3, 4, 5, 6, 7, 8,
                    21, 24, 25, 26, 27, 28, 29,
                    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
                    61, 62, 66, 67, 68, 69, 70, 71, 72, 73, 74,
                    112, 113, 114,
                    121, 122, 123, 124, 125]

main = ->
  game = new Phaser.Game scrW, scrH, Phaser.AUTO, '', {
    preload, create, render, update
  }
  return

preload = ->
  game.load.tilemap 'area01', 'assets/area01.json', null,
                    Phaser.Tilemap.TILED_JSON
  game.load.image 'area01_tiles', 'assets/area01_level_tiles.png'
  game.load.spritesheet 'gripe', 'assets/gripe.png', 32, 32
  return

create = ->
  game.physics.startSystem Phaser.Physics.ARCADE
  cursors = game.input.keyboard.createCursorKeys()
  keys = game.input.keyboard.addKeys
    jump: Phaser.KeyCode.SPACEBAR

  game.stage.backgroundColor = '#9bd4ff'
  map = game.add.tilemap 'area01'
  map.addTilesetImage 'area01_level_tiles', 'area01_tiles', 32, 32
  layer = map.createLayer 'background'
  layer.resizeWorld()
  flayer = map.createLayer 'foreground'
  map.setCollision solidTileIndices, true, layer
  map.setCollision solidTileIndices, true, flayer

  playerGroup = game.add.group undefined, 'player_group'
  map.createFromObjects 'objects', 'mainPlayer', 'gripe', 0,
                        true, false, playerGroup
  player = playerGroup.getAt 0
  game.physics.arcade.enable player
  player.body.gravity.y = 2000
  player.grounded = false
  player.jumpStartY = null
  player.jumpExhausted = false
  player.enableBody = true
  player.animations.add 'stand', [2], 1, true
  player.animations.add 'walkright', [0, 1, 2, 3, 4, 5, 6, 7], 6, true
  player.animations.add 'walkleft', [15, 14, 13, 12, 11, 10, 9, 8], 6, true
  player.animations.play 'stand'

  game.camera.follow player
  game.camera.deadzone = new Phaser.Rectangle(
    scrW/2 - scrW/10, scrH/2 - scrH/10, scrW/5, scrH/5)
  return

render = ->

update = ->
  do ->
    vx = 0
    if cursors.left.isDown
      vx -= playerSpeed
    if cursors.right.isDown
      vx += playerSpeed
    player.body.velocity.x = vx
    player.animations.play switch
      when vx < 0 then 'walkleft'
      when vx > 0 then 'walkright'
      else 'stand'

  if keys.jump.isDown and not player.jumpExhausted
    player.body.allowGravity = false
    player.body.velocity.y = -400
    if player.grounded
      player.jumpStartY = player.y
      player.grounded = false
    if player.y < player.jumpStartY - jumpMaxHeight
      player.jumpExhausted = true
  else
    player.body.allowGravity = true

  game.physics.arcade.collide player, layer, (->), processPlayerTilemap
  game.physics.arcade.collide player, flayer, (->), processPlayerTilemap

processPlayerTilemap = (player, tile) ->
  return unless solidTileIndices.indexOf(tile.index) > -1
  playerFeet = player.y + player.body.height
  playerLeft = player.x
  playerRight = player.x + player.body.width
  tileLeft = tile.x * tile.width
  tileRight = tileLeft + tile.width
  tileTop = tile.y * tile.height
  tileBot = tileTop + tile.height
  if (playerFeet >= tileTop and playerFeet < tileBot and
      playerRight > tileLeft + 2 and playerLeft < tileRight - 2)
    player.grounded = true
    player.jumpExhausted = false
  else if (playerFeet > tileBot and
           playerRight > tileLeft + 2 and playerLeft < tileRight - 2)
    player.jumpExhausted = true
  true

main()
