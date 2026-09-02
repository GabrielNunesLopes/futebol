--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(ReplicatedStorage.Shared.Config.PhysicsConfig)
local MovementMath = require(ReplicatedStorage.Shared.Physics.MovementMath)
local VectorMath = require(ReplicatedStorage.Shared.Math.VectorMath)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local RateLimitService = require(script.Parent.RateLimitService)

local PlayerMotorService = {}

local intents: { [Player]: Vector3 } = {}
local sequences: { [Player]: number } = {}
local accumulator = 0
local snapshotAccumulator = 0
local running = false
local frozenState = true

local function sanitizeInput(value: any): Vector3?
	if typeof(value) ~= "Vector3" then
		return nil
	end
	if value.X ~= value.X or value.Y ~= value.Y or value.Z ~= value.Z then
		return nil
	end
	if math.abs(value.X) > 4 or math.abs(value.Z) > 4 or math.abs(value.Y) > 0.001 then
		return nil
	end
	return VectorMath.clampMagnitudeXZ(value, 1)
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end
	if root and root:IsA("BasePart") then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	intents[player] = Vector3.zero
	sequences[player] = 0
end

local function stepPlayers(dt: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local current = VectorMath.flattenXZ(root.AssemblyLinearVelocity)
			local intended = if frozenState then Vector3.zero else intents[player] or Vector3.zero
			local nextVelocity = MovementMath.stepVelocity(current, intended, dt)
			root.AssemblyLinearVelocity = Vector3.new(nextVelocity.X, root.AssemblyLinearVelocity.Y, nextVelocity.Z)
		end
	end
end

function PlayerMotorService.start()
	if running then
		return
	end
	running = true

	local inputRemote = Remotes.getOrCreate("InputFrame")
	local snapshotRemote = Remotes.getOrCreate("PlayerSnapshot")

	inputRemote.OnServerEvent:Connect(function(player: Player, input: any, sequence: any)
		if not RateLimitService.allow(player.UserId, "InputFrame", 20, 35) then
			return
		end
		local clean = sanitizeInput(input)
		if not clean or typeof(sequence) ~= "number" or sequence % 1 ~= 0 then
			return
		end
		local last = sequences[player] or 0
		if sequence <= last or sequence > last + 10000 then
			return
		end
		sequences[player] = sequence
		intents[player] = clean
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
		if player.Character then
			setupCharacter(player, player.Character)
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
		if player.Character then
			setupCharacter(player, player.Character)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		intents[player] = nil
		sequences[player] = nil
		RateLimitService.clearUser(player.UserId)
	end)

	RunService.Heartbeat:Connect(function(dt)
		accumulator += math.min(dt, PhysicsConfig.FixedStep * PhysicsConfig.MaxCatchUpSteps)
		while accumulator >= PhysicsConfig.FixedStep do
			stepPlayers(PhysicsConfig.FixedStep)
			accumulator -= PhysicsConfig.FixedStep
		end

		snapshotAccumulator += dt
		if snapshotAccumulator >= 1 / 15 then
			snapshotAccumulator = 0
			for _, player in ipairs(Players:GetPlayers()) do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					snapshotRemote:FireClient(player, root.Position, root.AssemblyLinearVelocity, sequences[player] or 0)
				end
			end
		end
	end)
end

function PlayerMotorService.freezeAll(frozen: boolean)
	frozenState = frozen
	if frozen then
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end

return PlayerMotorService
