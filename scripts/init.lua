print("\n\nHello! This is my very fun game jam game!\n")

-- Setting up the window
tram.ui.SetWindowTitle("Backward Runner v1.0")
tram.ui.SetWindowSize(640, 480)

-- Pre-loading animation assets
tram.render.animation.Find("catrun"):Load()
tram.render.animation.Find("catthrow"):Load()
tram.render.animation.Find("blobjump"):Load()
tram.render.animation.Find("blobjump2"):Load()
tram.render.animation.Find("blobeat"):Load()
tram.render.animation.Find("blobeat2"):Load()

-- Pre-loading 3D models
tram.render.model.Find("cone"):Load()
tram.render.model.Find("cylinder"):Load()
tram.render.model.Find("diamond"):Load()
tram.render.model.Find("ico"):Load()
tram.render.model.Find("knot"):Load()
tram.render.model.Find("monkey"):Load()
tram.render.model.Find("sphere"):Load()
tram.render.model.Find("star"):Load()
tram.render.model.Find("teapot"):Load()
tram.render.model.Find("torus"):Load()

-- Setting up the global lighting.
tram.render.SetSunColor(tram.math.vec3(1.0, 1.0, 1.0))
tram.render.SetSunDirection((tram.math.DIRECTION_UP * 4.0 + tram.math.DIRECTION_SIDE * 2.0 + tram.math.DIRECTION_FORWARD):normalize())
tram.render.SetAmbientColor(tram.math.vec3(0.1, 0.1, 0.1))
tram.render.SetScreenClearColor(tram.render.COLOR_BLACK)

-- Setting up the camera
camera_pos = tram.math.DIRECTION_FORWARD * 1.7
camera_pos = camera_pos + tram.math.DIRECTION_UP * 2.0
tram.render.SetViewRotation(tram.math.quat(tram.math.vec3(-0.4, 3.14, 0.0)))
tram.render.SetViewPosition(camera_pos)

-- Setting up all of the models in the scene
cat_model = tram.components.Render()
cat_model:SetModel("cat")
cat_model:Init()

cat_animation = tram.components.Animation()
cat_animation:SetModel("cat")
cat_animation:Init()

cat_model:SetArmature(cat_animation)

cat_animation:Play("catrun")

cat_animation:SetOnAnimationFinishCallback("catthrow", function()
	cat_animation:Play("catrun")
end)


blob_model = tram.components.Render()
blob_model:SetModel("blob")
blob_model:SetLocation(tram.math.vec3(0.0, 0.0, 7.0))
blob_model:Init()

blob_animation = tram.components.Animation()
blob_animation:SetModel("blob")
blob_animation:Init()

blob_model:SetArmature(blob_animation)

blob_animation:Play("blobjump2")


object_model = tram.components.Render()
object_model:SetModel("cube")
object_model:SetLocation(tram.math.DIRECTION_FORWARD)
object_model:Init()


-- Initialize game logic
tiles = {}				-- list of all tiles in the scene
tile_progress = 0.0		-- how many units the tiles have slid past the plaer
lane = 2				-- lane in which the player is running
lane_progress = 2.0		-- same as lane, but interpolated
object_lane = 2			-- lane in which the object was thrown in
object_row = 0			-- row in which the object is in
object_progress = 0.0	-- how far along the current row the object is
object_state = "YEETED"	-- state of the object 

total_throws = 0		-- score tracking
succesful_throws = 0	-- more score tracking

total_rows = 0			-- how many rows the player has traversed

throw_probability = 0.0 -- probability that another object will be thrown

--- Generates a new row of tiles and adds it to the front of the scene
function InsertRow()
	local new_row = {
		obstacle = {math.random(0, 4) == 0,  -- we'll use a 1 in 5 probability
					math.random(0, 4) == 0,  -- of generating an obstacle for
					math.random(0, 4) == 0}, -- every tile generated
		
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
		
		new_row.model[tile]:SetLightmap("fullbright")
		new_row.model[tile]:Init()
	end
	
	table.insert(tiles, new_row)
end

--- Remove the last row off of the end of the scene
function RemoveRow()
	for tile = 1, 3 do
		tiles[1].model[tile]:Delete()
	end

	table.remove(tiles, 1)
end

--- Updates the model positions of every tile
function UpdateRows()
	for index, row in ipairs(tiles) do
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

--- Updates the model position of the thrown object
function UpdateObject()
	if object_state == "YEETED" then
		-- this position is behind the camera
		object_model:SetLocation(tram.math.DIRECTION_FORWARD * 5.0)
		return
	end

	-- spinning animation
	object_model:SetRotation(tram.math.quat(tram.math.vec3(tram.GetTickTime(), 1.1 * tram.GetTickTime(), 1.2 * tram.GetTickTime())))
	
	local pos = tram.math.DIRECTION_SIDE * (object_lane - lane_progress) * 2.0
	pos = pos + tram.math.DIRECTION_FORWARD * (-2.0 * (#tiles - object_row + 1) - object_progress + 4.0)
	pos = pos + tram.math.DIRECTION_UP * 0.5
	
	-- if the object hit an obstacle
	if object_state == "FUCKED" then
		pos = pos + tram.math.DIRECTION_UP * 2.0 * object_progress
	end
	
	-- animate the object dropping off together with last row of tiles
	if object_row == 1 then
		pos = pos + tram.math.DIRECTION_UP * -object_progress
	end
	
	object_model:SetLocation(pos)
end

--- Creates a new object with a random model and sets it to flying state
function ThrowObject()
	object_state = "FLYING"
	object_lane = lane
	object_row = #tiles - 1
	object_progress = 0.0
	
	total_throws = total_throws + 1
	
	cat_animation:FadeOut("catrun", 0.1)
	cat_animation:Play("catthrow", 1)
	
	local models = {
		"cone",
		"cube",
		"cylinder",
		"diamond",
		"ico",
		"knot",
		"monkey",
		"sphere",
		"star",
		"teapot",
		"torus"
	}
	local index = math.random(1, #models)
	
	object_model:Delete()
	
	object_model = tram.components.Render()
	object_model:SetModel(models[index])
	object_model:SetLocation(tram.math.DIRECTION_FORWARD)
	object_model:Init()
	
	CheckObject()
	
	-- show some demotivational messages to player
	if total_throws == 5 then
		ShowMessage("This is throw 5!! Will it be good???")
	elseif total_throws == 10 then
		if succesful_throws < 7 then
			ShowMessage("This is throw 10.. maybe you miss and be failure again???")
		else
			ShowMessage("This is throw 10.. maybe you hit again???")
		end
	elseif total_throws == 25 then
		ShowMessage("This is throw 25.. waow! Much throws!")
	elseif total_throws % 50 == 0 then
		ShowMessage("This is throw ", total_throws, ".. waow! Such playings!")
	end
end

--- Checks if object has collided with an obstacle
function CheckObject()
	if object_row == 0 then
	
		-- object reached the far end of the scene
		object_state = "YEETED"
		
	elseif object_row == 3 and object_lane == lane then
	
		-- object eaten by blob
		object_state = "YIPPEE"
		blob_animation:Play("blobeat2", 1, 1.0, 1.5)
		
		succesful_throws = succesful_throws + 1
		ShowMessage("Waow! Very throw! Such succesful!")
		
	elseif tiles[object_row].obstacle[object_lane] then
	
		-- object collided
		object_state = "FUCKED"		
		
		ShowMessage("Precision reduced to ",
					string.format("%.1f", 100.0 * (succesful_throws/total_throws)),
					"%.. not good!")
		
	end
end

--- Displays a message for the player
function ShowMessage(...)
	local parts = {...}
	local message = ""
	
	for i = 1, #parts do
		message = message .. parts[i]
	end

	-- currently we don't have access to GUI through Lua, so instead we will
	-- print the messages to console
	print(message)
	
end

-- Generating a couple of rows of tiles
InsertRow()
InsertRow()
InsertRow()
InsertRow()
InsertRow()
InsertRow()
InsertRow()
UpdateRows()

object_row = #tiles

-- Main update function
tram.event.AddListener(tram.event.FRAME, function()

	-- slide the tiles and the objects
	tile_progress = tile_progress + 2.0 * tram.GetDeltaTime()
	object_progress = object_progress + 4.0 * tram.GetDeltaTime()
	
	-- check if next row of tiles should be generated
	if tile_progress >= 2.0 then
		tile_progress = 0.0
		
		total_rows = total_rows + 1
		
		RemoveRow()
		InsertRow()
		
		-- show some more demotivational messages to the player
		if total_rows == 12 then
			ShowMessage("You have been running for 25 meters!!")
		elseif total_rows == 25 then
			ShowMessage("You have been running for 50 meters!!")
		elseif total_rows == 50 then
			ShowMessage("You have been running for 100 meters!!")
		elseif total_rows == 125 then
			ShowMessage("You have been running for 250 meters!!")
		elseif total_rows == 250 then
			ShowMessage("You have been running for 500 meters!!")
		elseif total_rows == 500 then
			ShowMessage("You have been running for 1 kilometer!!")
		elseif total_rows % 500 == 0 then
			ShowMessage("You have been running for ", total_rows/500, " kilometers!!")
			ShowMessage("Where ar you running to???")
		end
		
	end
	
	-- interpolate lane changing
	if lane_progress < lane then lane_progress = lane_progress + 5.0 * tram.GetDeltaTime() end
	if lane_progress > lane then lane_progress = lane_progress - 5.0 * tram.GetDeltaTime() end
	
	-- check if object collided with an obstacle or blob
	if object_progress >= 2.0 and object_state == "FLYING" then
		object_progress = 0.0
		
		object_row = object_row - 1
		
		CheckObject()
	end
	
	-- reset the object after collision animation
	if object_progress >= 2.0 and object_state == "FUCKED" then
		object_state = "YEETED"
	end
	
	-- reset the object after being eaten
	if object_progress >= 1.5 and object_state == "YIPPEE" then
		object_state = "YEETED"
	end
	
	-- randomly throw an object if it hasn't been thrown already
	if object_state == "YEETED" then
		throw_probability = throw_probability + 0.05 * tram.GetDeltaTime()
		if math.random() < throw_probability then
			ThrowObject()
			throw_probability = 0.0
		end
	end
	
	-- animate the player when changing lanes
	local change = lane_progress-lane
	local rotation = -0.5 + 1 / (1 + math.exp(-change))
	
	cat_model:SetRotation(tram.math.quat(tram.math.vec3(0.0, 2.5 * rotation, 0.0)))
	blob_model:SetRotation(tram.math.quat(tram.math.vec3(0.0, 1.0 * rotation, 0.0)))
	
	-- update model positions
	UpdateObject()
	UpdateRows()
	
end)

tram.event.AddListener(tram.event.KEYDOWN, function(event)

	if event.subtype == tram.ui.KEY_ACTION_STRAFE_LEFT or event.subtype == tram.ui.KEY_ACTION_LEFT then
		if lane < 3 then lane = lane + 1 end
	end
	
	if event.subtype == tram.ui.KEY_ACTION_STRAFE_RIGHT or event.subtype == tram.ui.KEY_ACTION_RIGHT then
		if lane > 1 then lane = lane - 1 end
	end

	if tram.ui.PollKeyboardKey(tram.ui.KEY_SPACE) and object_state == "YEETED" then
		ThrowObject()
	end
	
end)
