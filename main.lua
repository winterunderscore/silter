services = setmetatable({}, {
	__index = function(self, key)
		local service = game:GetService(key)
		self[key] = service
		return service
	end,
})

controls = setmetatable({
	keydown = Instance.new("BindableEvent"),
	keyup = Instance.new("BindableEvent"),
}, {
	__index = function(self, key)
		self[key] = {
			held = false,
			heldnotgpe = false,
			keydown = Instance.new("BindableEvent"),
			keyup = Instance.new("BindableEvent"),
		}
		return self[key]
	end,
})

plr = services.Players.LocalPlayer
isstudio = services.RunService:IsStudio()

function new(class, properties)
	local obj = Instance.new(class)
	for i,v in pairs(properties) do
		obj[i] = v
	end
	return obj
end

function randstring(len)
	len = len or math.random(16,32)
	local t = {}
	for i=1,len do
		t[i] = math.random(32,126)
	end
	return string.char(unpack(t))
end

screengui = (not isstudio and services.CoreGui:FindFirstChild("RobloxGui")) or new("ScreenGui", {Name = randstring(), ResetOnSpawn = false, Parent = (isstudio and plr:WaitForChild("PlayerGui")) or services.CoreGui})

cmdbar = new("TextBox", {
	["Name"] = randstring(),
	["AnchorPoint"] = Vector2.new(.5,.5),
	["Position"] = UDim2.fromScale(.5,.5),
	["BackgroundTransparency"] = .2,
	["BackgroundColor3"] = Color3.fromHex("000000"),
	["TextColor3"] = Color3.fromHex("e5e5e5"),
	["Size"] = UDim2.new(1, 0, 0, 35),
	["Font"] = Enum.Font.SourceSansLight,
	["TextSize"] = 30,
	["Visible"] = false,
	["ClearTextOnFocus"] = false,
	["Parent"] = screengui
})

list = new("ScrollingFrame", {
	["Name"] = randstring(),
	["AnchorPoint"] = Vector2.new(.5,0),
	["BackgroundTransparency"] = 1,
	["BackgroundColor3"] = Color3.fromHex("000000"),
	["BorderSizePixel"] = 0,
	["Position"] = UDim2.new(0.5,0,0.5,17),
	["Size"] = UDim2.new(1,0,0.5,-17),
	["ScrollBarThickness"] = 0,
	["Visible"] = false,
	["Parent"] = screengui
})

templatecmd = new("TextLabel", {
	["AnchorPoint"] = Vector2.new(.5,.5),
	["Position"] = UDim2.fromScale(.5,.5),
	["BackgroundTransparency"] = .4,
	["BackgroundColor3"] = Color3.fromHex("000000"),
	["TextColor3"] = Color3.fromHex("e5e5e5"),
	["Size"] = UDim2.new(1, 0, 0, 35),
	["Font"] = Enum.Font.SourceSansLight,
	["TextSize"] = 30,
	["Visible"] = false
})

replacements = {
	["inf"] = math.huge
}

cmdglobals = {

}

commands = {
	{
		name = "print",
		display = "print [args] - print [args] to the console",
		disabled = false,
		func = function(self, ...)
			print(...)
		end,
	},
	{
		name = "enable",
		display = "enable [cmd] - enable a command",
		func = function(self, cmd, ...)
			for i,v in pairs(findcmds(cmd or "", true)) do
				v.disabled = false
			end
		end,
	},
	{
		name = "disable",
		display = "disable [cmd] - disable a command",
		func = function(self, cmd, ...)
			for i,v in pairs(findcmds(cmd or "", true)) do
				v.disabled = true
			end
		end,
	},
	{
		name = "tpwalk",
		display = "tpwalk [studs] - teleports u to ur move direction",
		on = false,
		func = function(self, studs, ...)
			studs = studs or 1
			self.on = not self.on
			self.name = (self.on and "untpwalk") or "tpwalk"
			self.display = self.name..((self.on and " - disables tpwalk") or " [studs] - teleports u to ur move direction")
			while self.on and services.RunService.Heartbeat:Wait() do
				if not plr.Character then plr.CharacterAdded:Wait() end
				local chr = plr.Character
				local hum = chr:FindFirstChildOfClass("Humanoid")
				chr:TranslateBy(hum.MoveDirection * studs)
			end
		end,
	},
	{
		name = "infjump",
		display = "infjump - allows u to jump infinitely",
		on = false,
		connection = nil,
		func = function(self, ...)
			self.on = not self.on
			self.name = (self.on and "uninfjump") or "infjump"
			self.display = self.name..((self.on and " - disables infjump") or " - allows u to jump infinitely")
			if self.connection then self.connection:Disconnect() end
			if not self.on then return end
			self.connection = services.UserInputService.JumpRequest:Connect(function()
				plr.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
			end)
		end,
	},
	{
		name = "gravity",
		display = "gravity / grav [num] - sets the gravity (default is 196.2)",
		func = function(self, num, ...)
			services.Workspace.Gravity = tonumber(num) or 196.2
		end,
	},
	{
		name = "hint",
		display = "hint [duration] [text] - display a hint",
		func = function(self, duration, ...)
			hint(table.concat({...}, " "), tonumber(duration) or 1)
		end,
	},
	{
		name = "rspy",
		display = "rspy / remotespy - opens up SimpleSpy",
		aliases = {"remotespy"},
		func = function(self, ...)
			loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()
		end,
	},
	{
		name = "noclip",
		display = "noclip - allows u to go through objects",
		on = false,
		connection = nil,
		func = function(self, ...)
			self.on = not self.on
			self.name = (self.on and "clip") or "noclip"
			self.display = self.name..((self.on and " - disables noclip") or " - allows u to go through objects")
			if self.connection then self.connection:Disconnect() end
			if not self.on then return end
			self.connection = services.RunService.Stepped:Connect(function()
				if not plr.Character then plr.CharacterAdded:Wait() end
				if not self.on then return end
				for i,v in pairs(plr.Character:GetDescendants()) do
					if not v:IsA("BasePart") then continue end
					v.CanCollide = false
				end
			end)
		end,
	},
	{
		name = "density",
		display = "density [num] - allows u to set ur characters density",
		func = function(self, density, ...)
			density = density or 0
			if not plr.Character then plr.CharacterAdded:Wait()	end
			for i,v in pairs(plr.Character:GetDescendants()) do
				if not v:IsA("BasePart") then continue end
				v.CustomPhysicalProperties = PhysicalProperties.new(density, .3, .5)
			end
		end,
	},
	{
		name = "sit",
		display = "sit - makes ur character sit",
		func = function(self, ...)
			if not plr.Character then plr.CharacterAdded:Wait() end
			plr.Character:FindFirstChildOfClass("Humanoid").Sit = true
		end,
	},
	{
		name = "fly",
		display = "fly [flyspeed]",
		on = false,
		func = function(self, flyspeed, ...)
			flyspeed = tonumber(flyspeed) or 1
			self.on = not self.on
			self.name = (self.on and "unfly") or "fly"
			self.display = self.name..(not self.on and " [flyspeed] - allows ur character to fly" or " - disables fly")	

			local pos
			while self.on and services.RunService.Heartbeat:Wait() do
				if not plr.Character then plr.CharacterAdded:Wait() end
				local hrp = plr.Character:FindFirstChildOfClass("Humanoid").RootPart
				local cam = services.Workspace.CurrentCamera

				local dir = (cam.CFrame.LookVector * ((controls[Enum.KeyCode.W].heldnotgpe and 1 or 0) + (controls[Enum.KeyCode.S].heldnotgpe and -1 or 0))) + (cam.CFrame.RightVector * ((controls[Enum.KeyCode.D].heldnotgpe and 1 or 0) + (controls[Enum.KeyCode.A].heldnotgpe and -1 or 0)))
				pos = (pos or hrp.Position) + (dir*flyspeed)

				hrp.Velocity, hrp.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
				hrp.CFrame = CFrame.new(pos, pos + cam.CFrame.LookVector)
			end
		end,
	},
	{
		name = "fling",
		display = "fling [plr] [power] - fling a player (default power is 10)",
		func = function(self, name, pow, ...)
			pow = 9*(10^(tonumber(pow) or 10))
			pow = Vector3.new(pow/2,pow,pow/2)
			local players = getplayers(name)
			if #players <= 0 then hint("player not found") return end
			local player = players[1]
			if not player.Character then player.CharacterAdded:Wait() end
			if not plr.Character then plr.CharacterAdded:Wait() end

			local char = player.Character
			local hrp = char:FindFirstChildOfClass("Humanoid").RootPart
			local lchar = plr.Character
			local lhrp = lchar:FindFirstChildOfClass("Humanoid").RootPart

			local oldpos = lchar:GetPivot()

			exec({"noclip"})
			exec({"density", 100})
			local t = os.clock()
			local o = hrp.Position
			while ((hrp.Position - o).Magnitude < 5000) and os.clock() - t < 5 and services.RunService.Heartbeat:Wait() do
				lchar:PivotTo(char:GetPivot() + (hrp.Velocity/60) + Vector3.new(math.random(-1,1)/2,math.random(-1,1)/2,math.random(-1,1)/2))
				lhrp.Velocity = pow
			end
			exec({"clip"})
			exec({"density", 1})
			exec({"breakvelocity"})
			lchar:PivotTo(oldpos)
		end,
	},
	{
		name = "breakvelocity",
		display = "breakvelocity / breakvel - resets ur velocity",
		aliases = {"breakvel"},
		func = function(self, ...)
			local t = os.clock()
			for i=0,5 do
				services.RunService.Stepped:Wait()
				if not plr.Character then plr.CharacterAdded:Wait() end
				for i,v in pairs(plr.Character:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Velocity, v.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
					end
				end
			end
		end,
	},
	{
		name = "reset",
		display = "reset - reset ur character",
		func = function(self, ...)
			if plr.Character then plr.Character:BreakJoints() end
		end,
	}
}

table.sort(commands, function(v1, v2)
	return v1.name < v2.name
end)

function refreshlist()
	list:ClearAllChildren()
	new("UIListLayout", {Parent = list})
	for i,v in pairs(commands) do
		local cmd = templatecmd:Clone()
		cmd.Name = v.name
		cmd.Text = v.display
		cmd.Parent = list
	end
end
refreshlist()

function hint(text, duration)
	duration = tonumber(duration) or 1
	local a = new("Hint", {Parent = screengui, Text = text})
	game.Debris:AddItem(a, duration)
end -- heres how u know im that lazy to make a notification system

function getplayers(name)
	name = string.lower('^'..(name or ""))
	local t = {}
	for i,v in pairs(services.Players:GetPlayers()) do
		if v == plr then continue end
		if string.find(string.lower(v.Name), name) then
			table.insert(t,v)
			continue
		end
		if string.find(string.lower(v.DisplayName), name) then
			table.insert(t,v)
		end
	end
	return 
		(isstudio and {{Character = workspace.Dummy}}) or 
		t
end

function findcmds(name, includedisabled, namesonly)
	name = string.lower('^'..(name or ""))
	local t = {}
	local names = {}
	for i,v in pairs(commands) do
		if not (includedisabled or not v.disabled) then continue end
		if string.find(string.lower(v.name), name) then
			table.insert(t, v)
			table.insert(names, v.name)
			continue
		end
		if not v.aliases then continue end
		for i2,v2 in pairs(v.aliases) do
			if string.find(string.lower(v2), name) then
				table.insert(t,v)
				table.insert(names, v.name)
				break
			end
		end
	end
	return (namesonly and names) or t
end

function exec(args)
	local cmd = args[1]
	table.remove(args, 1)
	for i,v in pairs(args) do
		args[i] = replacements[v] or args[i]
	end
	if cmd and cmd ~= "" then
		local cmds = findcmds(cmd)
		if #cmds <= 0 then return end
		coroutine.wrap(function()
			local success, ret = pcall(cmds[1].func, cmds[1], unpack(args))
			if not success and isstudio then
				hint("execution error: "..ret, 5)
			end
		end)()
	end
end

cmdbar:GetPropertyChangedSignal("Text"):Connect(function()
	refreshlist()
	local a = findcmds(string.split(cmdbar.Text, " ")[1], false, true)
	for i,v in pairs(list:GetChildren()) do
		if v:IsA("TextLabel") then
			if table.find(a, v.Name) then
				v.Visible = true
				continue
			end
			v.Visible = false
		end
	end
end)

cmdbar.FocusLost:Connect(function(entered, input)
	local args = string.split(cmdbar.Text, " ")
	exec(args)
	cmdbar.Visible = false
	list.Visible = false
end)

services.UserInputService.InputBegan:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		controls[input.KeyCode].held = true
		controls[input.KeyCode].keydown:Fire(input, gpe)
		controls.keydown:Fire(input, gpe)
		if not gpe then
			controls[input.KeyCode].heldnotgpe = true
		end
	end
end)

services.UserInputService.InputEnded:Connect(function(input, gpe)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		controls[input.KeyCode].held = false
		controls[input.KeyCode].heldnotgpe = false
		controls[input.KeyCode].keyup:Fire(input, gpe)
		controls.keyup:Fire(input, gpe)
	end
end)

controls[Enum.KeyCode.Quote].keydown.Event:Connect(function(input, gpe)
	if not gpe then
		cmdbar:CaptureFocus()
		spawn(function()
			repeat cmdbar.Text = "" until cmdbar.Text == ""
			cmdbar.Visible = true
			list.Visible = true
		end)
	end
end)
