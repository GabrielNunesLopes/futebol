--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(ReplicatedStorage.Shared.Config.PhysicsConfig)
local BallMath = require(ReplicatedStorage.Shared.Physics.BallMath)
local VectorMath = require(ReplicatedStorage.Shared.Math.VectorMath)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local RateLimitService = require(script.Parent.RateLimitService)
local BallService = require(script.Parent.BallService)

local KickService = {}

local lastKickAt: { [Player]: number } = {}
local activeProvider: (() -> boolean)? = nil
local running = false

function KickService.setActiveProvider(provider: () -> boolean)
	activeProvider = provider
end

local function isFiniteVector3(value: any): boolean
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
end

function KickService.start()
	if running then
		return
	end
	running = true

	local remote = Remotes.getOrCreate("KickRequest")
	remote.OnServerEvent:Connect(function(player: Player, aimDirection: any, _sequence: any)
		if not RateLimitService.allow(player.UserId, "KickRequest", 5, 10) then
			return
		end
		if activeProvider and not activeProvider() then
			return
		end
		if not isFiniteVector3(aimDirection) then
			return
		end

		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end

		local now = os.clock()
		local previous = lastKickAt[player] or -math.huge
		if now - previous < PhysicsConfig.Kick.Cooldown then
			return
		end

		local ballPosition = BallService.getPosition()
		local offset = VectorMath.flattenXZ(ballPosition - root.Position)
		if offset.Magnitude > PhysicsConfig.Kick.Range then
			return
		end

		lastKickAt[player] = now
		local kickVelocity = BallMath.computeKick(
			ballPosition,
			root.Position,
			root.AssemblyLinearVelocity,
			VectorMath.safeUnitXZ(aimDirection),
			PhysicsConfig.Kick.Power
		)
		BallService.setVelocity(kickVelocity)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastKickAt[player] = nil
	end)
end

return KickService
