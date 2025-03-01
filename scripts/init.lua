print("\n\nHello! This is my very fun game jam game!\n")

-- Setting up the window
tram.ui.SetWindowTitle("Teapot Explorer v1.0")
tram.ui.SetWindowSize(640, 480)

-- Loading assets

tram.render.animation.Find("catrun"):Load()
tram.render.animation.Find("blobjump"):Load()



-- Setting up the global lighting.
tram.render.SetSunColor(tram.math.vec3(1.0, 1.0, 1.0))
tram.render.SetSunDirection(tram.math.DIRECTION_UP)
tram.render.SetAmbientColor(tram.math.vec3(0.1, 0.1, 0.1))
--tram.render.SetScreenClearColor(tram.render.COLOR_BLACK)
tram.render.SetScreenClearColor(tram.render.COLOR_WHITE * 0.1)


camera_pos = tram.math.DIRECTION_FORWARD * 1.7
camera_pos = camera_pos + tram.math.DIRECTION_UP * 2.0

-- Move the camera a bit away from the origin.
--tram.render.SetViewPosition(tram.math.DIRECTION_FORWARD * -4.2)
tram.render.SetViewRotation(tram.math.quat(tram.math.vec3(-0.4, 3.14, 0.0)))
tram.render.SetViewPosition(camera_pos)

-- Setting up a light so that you can see something.
-- scene_light = tram.components.Light()
-- scene_light:SetColor(tram.render.COLOR_WHITE)
-- scene_light:SetLocation(tram.math.vec3(5.0, 5.0, 5.0))
-- scene_light:Init()

-- Adding a teapot to the scene.
cat_model = tram.components.Render()
cat_model:SetModel("cat")
cat_model:Init()

cat_animation = tram.components.Animation()
cat_animation:SetModel("cat")
cat_animation:Init()

cat_model:SetArmature(cat_animation)

cat_animation:Play("catrun")


blob_model = tram.components.Render()
blob_model:SetModel("blob")
blob_model:SetLocation(tram.math.vec3(0.0, 0.0, 7.0))
blob_model:Init()

blob_animation = tram.components.Animation()
blob_animation:SetModel("blob")
blob_animation:Init()

blob_model:SetArmature(blob_animation)

blob_animation:Play("blobjump")



tiles = {}
tile_progress = 0.0
lane = 2
lane_progress = 2.0

function InsertRow()
	local new_row = {
		obstacle = {math.random(0, 4) == 0,
					math.random(0, 4) == 0,
					math.random(0, 4) == 0},
		
		model = {tram.components.Render(),
				 tram.components.Render(),
				 tram.components.Render()}
	}
	
	for tile = 1, 3 do
		if new_row.obstacle[tile] then
			new_row.model[tile]:SetModel("tileobstacle")
		else 
			new_row.model[tile]:SetModel("tile")
		end
		
		--new_row.model[tile]:SetDirectionalLight(true)
		new_row.model[tile]:SetLightmap("fullbright")
		new_row.model[tile]:Init()
	end
	
	table.insert(tiles, new_row)
end

function RemoveRow()
	
	for tile = 1, 3 do
		tiles[1].model[tile]:Delete()
	end

	table.remove(tiles, 1)
end

function UpdateRows()
	--print("updating rows")
	for index, row in ipairs(tiles) do
		--print("index ", index, " row ", row)
		for tile = 1, 3 do
			local pos = tram.math.DIRECTION_SIDE * (tile - lane_progress) * 2.0
			pos = pos + tram.math.DIRECTION_FORWARD * (-2.0 * (#tiles - index + 1) - tile_progress + 4.0)
			if index == 1 then
				pos = pos + tram.math.DIRECTION_UP * -tile_progress
			end
			row.model[tile]:SetLocation(pos)
		end
	end
end

InsertRow()
InsertRow()
InsertRow()
InsertRow()
InsertRow()
InsertRow()
InsertRow()
UpdateRows()



tram.event.AddListener(tram.event.FRAME, function()
	tile_progress = tile_progress + 2.0 * tram.GetDeltaTime()
	
	if tile_progress >= 2.0 then
		tile_progress = 0.0
		
		RemoveRow()
		InsertRow()
	end
	
	if lane_progress < lane then lane_progress = lane_progress + 5.0 * tram.GetDeltaTime() end
	if lane_progress > lane then lane_progress = lane_progress - 5.0 * tram.GetDeltaTime() end
	
	UpdateRows()
end)

tram.event.AddListener(tram.event.KEYDOWN, function(event)

	if event.subtype == tram.ui.KEY_ACTION_STRAFE_LEFT or event.subtype == tram.ui.KEY_ACTION_LEFT then
		if lane < 3 then lane = lane + 1 end
	end
	
	if event.subtype == tram.ui.KEY_ACTION_STRAFE_RIGHT or event.subtype == tram.ui.KEY_ACTION_RIGHT then
		if lane > 1 then lane = lane - 1 end
	end


	
	print(KEY_ACTION_STRAFE_LEFT, lane)
end)

-- -- This vector here will contain teapot euler angle rotation in radians.
-- local teapot_modifier = tram.math.vec3(0.0, 0.0, 0.0)

-- -- This function will be called every tick.
-- tram.event.AddListener(tram.event.TICK, function()
	-- if tram.ui.PollKeyboardKey(tram.ui.KEY_LEFT) or tram.ui.PollKeyboardKey(tram.ui.KEY_A) then
		-- teapot_modifier = teapot_modifier - tram.math.vec3(0.0, 0.01, 0.0)
	-- end
	
	-- if tram.ui.PollKeyboardKey(tram.ui.KEY_RIGHT) or tram.ui.PollKeyboardKey(tram.ui.KEY_D) then
		-- teapot_modifier = teapot_modifier + tram.math.vec3(0.0, 0.01, 0.0)
	-- end
	
	-- if tram.ui.PollKeyboardKey(tram.ui.KEY_UP) or tram.ui.PollKeyboardKey(tram.ui.KEY_W) then
		-- teapot_modifier = teapot_modifier - tram.math.vec3(0.01, 0.0, 0.0)
	-- end
	
	-- if tram.ui.PollKeyboardKey(tram.ui.KEY_DOWN) or tram.ui.PollKeyboardKey(tram.ui.KEY_S) then
		-- teapot_modifier = teapot_modifier + tram.math.vec3(0.01, 0.0, 0.0)
	-- end
	
	-- teapot:SetRotation(tram.math.quat(teapot_modifier))
-- end)
