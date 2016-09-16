-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
--physics.setDrawMode( "hybrid" )
local pontuacao = 0 
local textoPontuacao
local pontuacaoFinal

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

local somBloco = audio.loadSound(  "soms/bloco.mp3" )
local selectSound = audio.loadSound( "soms/select.mp3")
local function tocarSom(id)
	if id == 1 then
		local toca = audio.play(somBloco)
	end

	if id == 2 then
		local toca = audio.play(selectSound)
	end
end

local function perdeuJogo() 
	local options = {
		isModal = true, 
		effect = "fade",
		time = 500
	}
	composer.showOverlay( "perdeu", options )

end

function scene:create( event )
	local blocos = {}
	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	local sceneGroup = self.view

	-- We need physics started to add bodies, but we don't want the simulaton
	-- running until the scene is on the screen.
	physics.start()
	physics.pause()


	-- create a grey rectangle as the backdrop
	-- the physical screen will likely be a different shape than our defined content area
	-- since we are going to position the background from it's top, left corner, draw the
	-- background at the real top, left corner.
	--local background = display.newRect( display.screenOriginX, display.screenOriginY, screenW, screenH )
	print( screenW.." e "..screenH )

	local background = display.newImageRect( "imagens/background.png", screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background.x = 0 + display.screenOriginX 
	background.y = 0 + display.screenOriginY

	
	-- Construir a bola
	local bola = display.newImageRect( "imagens/bola.png", 20, 20 )
	bola.x = screenW / 2
	bola.y = screenH / 2 - 90

	-- add physica da bola
	physics.addBody( bola, { density=1.0, friction=0, bounce=1, radius=8} )
	
	--Dar empurrao na bolinha
	local yForce = math.random( -3,3 )
	if yForce == 0 then
		yForce = 1
	end
	bola:applyLinearImpulse( yForce , 2, bola.x, bola.y )


	bola.collision = function(self, event) 
		if(event.other.type == "perder") then
				print("Perdeu o jogo")
				self:removeSelf()
				perdeuJogo()
		end
		
		if(event.phase == "ended") then
	

			if(event.other.type == "bloco") then
				tocarSom(1)
				event.other:removeSelf()
				blocos[event.other.id] = nil
				pontuacao = pontuacao + 50
				textoPontuacao.text = "Pontos: "..pontuacao

				if pontuacao == pontuacaoFinal then
					self:removeSelf()
					perdeuJogo()

				end

			end

			if(event.other.type =="paddle") then
				tocarSom(2)
			end

		end

	end

	bola:addEventListener( "collision", bola )

	-- Criar paredes
	local paredeEsq = display.newRect(-10, 284, 10, 900)
	physics.addBody( paredeEsq, "static", {friction = 0, bounce = 1})
	paredeEsq.alpha = 0

	local paredeDir = display.newRect(screenW + 10, 284, 10, 900)
	physics.addBody( paredeDir, "static", {friction = 0, bounce = 1})
	paredeDir.alpha = 0

	local paredeInf = display.newRect(screenW / 2,screenH - 40, screenW,10)
	physics.addBody( paredeInf, "static", {friction = 0, bounce = 1})
	paredeInf.type = "perder"
	paredeInf.alpha = 0

	local paredeSup = display.newRect(display.contentWidth / 2,-50,screenW,10)
	physics.addBody( paredeSup, "static", {friction = 0, bounce = 1})
	paredeSup.alpha = 0




	-- PADDLE
	local paddle = display.newImageRect( "imagens/paddle.png", 100, 28 )
	paddle.type = "paddle"
	physics.addBody( paddle, "static", {friction= 0, bounce = 1} )
	paddle.x = screenW / 2
	paddle.y = paredeInf.y - 30

	local moverPaddle = function (event) 
		paddle.x = event.x

	end

	Runtime:addEventListener( "touch", moverPaddle )


	
	-- all display objects must be inserted into group
	sceneGroup:insert( background )
	sceneGroup:insert( bola )
	sceneGroup:insert( paredeEsq )
	sceneGroup:insert( paredeDir )
	sceneGroup:insert( paredeInf )
	sceneGroup:insert( paredeSup )
	sceneGroup:insert( paddle )

	-- Criar bloquinhos destruiveis
	--------------------------------------------
	local blocoWidth = 60
	local blocoHeight = 20

	local numLinhas = 4
	local numColunas = 4

	pontuacaoFinal = (numLinhas * numColunas) * 50

	local xPos = 0
	local yPos = 0

	local linha 
	local coluna
	local indexBloco = 0

	for coluna = 1, numColunas, 1 do
		xPos = blocoWidth * coluna + (coluna * 10)
		xPos = xPos - 15

		for linha = 1, numLinhas, 1 do
			yPos = blocoHeight * linha + (linha * 10)
			yPos = yPos - 20

			blocos[indexBloco] = display.newRect(xPos, yPos, blocoWidth, blocoHeight)
			blocos[indexBloco].id = indexBloco
			blocos[indexBloco].type = "bloco"
			blocos[indexBloco]:setFillColor((math.random(1,255) / 255),(math.random(1,255) / 255),(math.random(1,255) / 255))

			-- RGB 128, 240,28 no Corona = 128/255, 240 /255, 28 /255

			physics.addBody( blocos[indexBloco], "static", {friction = 1, bounce = 1})

			sceneGroup:insert(blocos[indexBloco])
			indexBloco = indexBloco + 1
		end
	end

	local pontos = "Pontos: ".. pontuacao
	-- Pontuacao
	textoPontuacao = display.newText( pontos, screenW -60, blocos[4].y - 30, native.systemFontBold, 18)
	textoPontuacao:setFillColor( 0 )

	sceneGroup:insert(textoPontuacao)
	
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
		physics.setGravity( 0, 0)
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
	
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	composer.gotoScene( "reload", "fade", 500 )
	package.loaded[physics] = nil
	physics = nil

end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene