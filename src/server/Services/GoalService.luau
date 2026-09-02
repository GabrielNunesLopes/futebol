--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(ReplicatedStorage.Shared.Config.PhysicsConfig)
local FieldService = require(script.Parent.FieldService)
local BallService = require(script.Parent.BallService)

local GoalService = {}

local connection: RBXScriptConnection? = nil

function GoalService.start(arena: FieldService.ArenaRefs, onGoal: ("Blue" | "Red") -> ())
	if connection then
		connection:Disconnect()
	end

	local previous = BallService.getPosition()
	local accumulator = 0
	local armed = true

	connection = RunService.Heartbeat:Connect(function(dt)
		accumulator += math.min(dt, PhysicsConfig.FixedStep * PhysicsConfig.MaxCatchUpSteps)
		while accumulator >= PhysicsConfig.FixedStep do
			local current = BallService.getPosition()
			local insideMouth = math.abs(current.Z) <= arena.GoalHalfWidth - PhysicsConfig.Ball.Radius

			if armed and insideMouth then
				if previous.X <= arena.HalfLength and current.X > arena.HalfLength then
					armed = false
					onGoal("Blue")
				elseif previous.X >= -arena.HalfLength and current.X < -arena.HalfLength then
					armed = false
					onGoal("Red")
				end
			end

			if math.abs(current.X) < arena.HalfLength - PhysicsConfig.Ball.Radius then
				armed = true
			end

			previous = current
			accumulator -= PhysicsConfig.FixedStep
		end
	end)
end

return GoalService
