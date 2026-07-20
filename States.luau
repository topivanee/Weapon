--State Manager
--- modules/StateManager.lua

local Service = {}

function Service.checkState(character:Model, ...)
	local statusFolder = character:FindFirstChild("Status")
	if not statusFolder then return end
	local statesToCheck = {...}
	for _, state in statesToCheck do
		if statusFolder:FindFirstChild(state) then
			return true
		end
	end
	return false
end

function Service.removeState(character:Model, stateName:string)
	local statusFolder = character:FindFirstChild("Status")
	if not statusFolder then return end
	for _, state in statusFolder:GetChildren() do
		if state.Name == stateName then
			state:Destroy()
		end
	end
end

function Service.addState(character:Model, stateName:string, duration : number, Attributes:any)
	local statusFolder = character:FindFirstChild("Status")
	if not statusFolder then 
		statusFolder = Instance.new("Folder")
		statusFolder.Name = "Status"
		statusFolder.Parent = character
	end
	if character and stateName then
		local newState = Instance.new("BoolValue")
		newState.Name = stateName
		if Attributes then
			for name,value in Attributes do
				newState:SetAttribute(name, value)
			end
		end
		newState.Parent = statusFolder
		if duration then
			task.delay(duration, function()
				newState:Destroy()
			end)
		end
		return newState
	end
	return nil
end





return Service

--loadAnimationScript

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local assets = replicatedStorage.Animations

Players.PlayerAdded:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", math.huge)
	local Animator = humanoid.Animator
	local coreFolder = character:WaitForChild("Core", math.huge)
	local animationsModule = require(coreFolder.Animations)

	animationsModule.loadAnims(Animator,assets.Character)
	print(animationsModule.loadedAnimations)
end)

--ClientManager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

local stateManager = require(modulesFolder:WaitForChild("StateManager"))

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local statusFolder = character:WaitForChild("Status")



RunService.RenderStepped:Connect(function()

	task.spawn(function()

		local finalWalkSpeed = 16
		local finalJumpPower = 50
		if statusFolder:FindFirstChild("Stunned") then
			finalWalkSpeed = 0
			finalJumpPower = 0
			script.Parent.StunnedText.Visible = true
		else
			script.Parent.StunnedText.Visible = false
		end
		humanoid.WalkSpeed = finalWalkSpeed
		humanoid.JumpPower = finalJumpPower
		if finalJumpPower == 0 then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end)
end)

--AnimationsModule

local module = {}
module.loadedAnimations = {}
function module.loadAnims(Animator:Animator,folder:Folder)
	for _, anim in folder:GetDescendants() do
		if anim:IsA("Animation") then
			local fullName = anim:GetFullName()
			fullName = fullName:split("ReplicatedStorage.Animations.")[2]
			module.loadedAnimations[fullName] = Animator:LoadAnimation(anim)
		end
	end
end

return module

--stunPlayerScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local modulesFolder = ReplicatedStorage.Modules

local stateManager = require(modulesFolder.StateManager)

local stunPart = script.Parent
local debounce = false
stunPart.Touched:Connect(function(hit)
	if debounce then
		return
	end

	local character = hit.Parent

	if not character:IsA("Model") then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)

	if not player then
		return
	end
	debounce = true
	local humanoidPlayer = character:FindFirstChild("Humanoid")
	local animatorPlayer = humanoidPlayer.Animator
	local coreFolder = character:FindFirstChild("Core")
	local animationsModule = require(coreFolder.Animations)
	local stunAnim:AnimationTrack = animationsModule.loadedAnimations["Character.Stunned"]
	stateManager.addState(character, "Stunned", stunAnim.Length)
	stunAnim:Play()
	task.wait(stunAnim.Length)
	stunAnim:Stop()
	task.wait(1)
	debounce = false
end)





