# out: main.js
"use strict"

{Phaser} = window

scrW = 640
scrH = 480

controls = null
cursors = null
game = null
keys = null
layer = null
flayer = null
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
  game.load.image 'slider_handle', 'assets/slider-handle.png'
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
  map.setCollision solidTileIndices, true, layer

  playerGroup = game.add.group undefined, 'player_group'
  map.createFromObjects 'objects', 'mainPlayer', 'gripe', 0,
                        true, false, playerGroup
  player = playerGroup.getAt 0
  game.physics.arcade.enable player
  player.body.gravity.y = 2000
  player.grounded = false
  player.jumpMaxHeight = 200
  player.jumpStartY = null
  player.jumpExhausted = false
  player.enableBody = true
  player.animations.add 'standright', [2], 1, true
  player.animations.add 'standleft', [13], 1, true
  player.animations.add 'walkright', [0, 1, 2, 3, 4, 5, 6, 7], 6, true
  player.animations.add 'walkleft', [15, 14, 13, 12, 11, 10, 9, 8], 6, true
  player.animations.play 'standright'

  game.camera.follow player
  game.camera.deadzone = new Phaser.Rectangle(
    scrW/2 - scrW/10, scrH/2 - scrH/10, scrW/5, scrH/5)

  flayer = map.createLayer 'foreground'
  map.setCollision solidTileIndices, true, flayer

  controls = game.add.group undefined, 'control_group'
  addSlider 'maxH', player, 'jumpMaxHeight', 0, 250
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
      else switch player.animations.name
        when 'walkleft', 'standleft' then 'standleft'
        else 'standright'

  if keys.jump.isDown and not player.jumpExhausted
    player.body.allowGravity = false
    player.body.velocity.y = -400
    if player.grounded
      player.jumpStartY = player.y
      player.grounded = false
    if player.y < player.jumpStartY - player.jumpMaxHeight
      player.jumpExhausted = true
  else
    player.body.allowGravity = true
    player.jumpExhausted = true

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
  if (playerFeet >= tileTop - 1 and playerFeet < tileBot and
      playerRight > tileLeft and playerLeft < tileRight)
    player.grounded = true
    player.jumpExhausted = false
  else if (playerFeet > tileBot and
           playerRight > tileLeft and playerLeft < tileRight)
    player.jumpExhausted = true
  true

addSlider = (label, obj, prop, min, max) ->
  if obj[prop] == undefined
    console.log "#{obj}.#{prop} not found in addSlider!"
  grp = game.add.group controls, "#{label}_ctl_group"
  grp.fixedToCamera = true
  grp.x = 0
  grp.y = 0

  width = 0

  labelText = game.add.text width, 8, label, {
    font: "16px Arial", fill: "#ffffff", align: "right"
  }, grp
  width += labelText.width

  slider = game.add.group grp, "#{label}_slider"
  slider.x = width
  handle = null
  do ->
    leftEdge = 0
    rightEdge = scrW/4
    groove = game.add.graphics 0, 0, slider
    groove.lineStyle 2, 0xffffff
    groove.moveTo 4, 16
    groove.lineTo rightEdge-4, 16

    hx = (obj[prop] / (max - min)) * rightEdge
    handle = game.add.sprite hx, 16, 'slider_handle', 0, slider
    handle.anchor = { x: 0.5, y: 0.5 }
    handle.inputEnabled = true
    handle.input.boundsRect = new Phaser.Rectangle(
      0, 4, scrW / 4, 28
    )
    handle.input.draggable = true
    handle.input.allowVerticalDrag = false
    width += rightEdge

  valueText = game.add.text width, 8, obj[prop], {
    font: "16px Arial", fill: "#ffffff", align: "right"
  }, grp
  width += valueText.width + 64

  bg = game.add.graphics 0, 0, grp
  bg.beginFill 0x000000, 0.5
  bg.drawRect 0, 0, width, 32
  bg.endFill()
  grp.sendToBack bg

  handle.events.onDragUpdate.add ->
    newVal = (handle.x / (scrW / 4)) * (max - min)
    obj[prop] = newVal
    valueText.setText newVal
    return

  return

main()
