--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PhysicsConfig = require(ReplicatedStorage.Shared.Config.PhysicsConfig)
local BallMath = require(ReplicatedStorage.Shared.Physics.BallMath)
local VectorMath = require(ReplicatedStorage.Shared.Math.VectorMath)
local FieldService = require(script.Parent.FieldService)

local BallService = {}

local ball: BasePart? = nil
local arena: FieldService.ArenaRefs? = nil
local velocity = Vector3.zero
local accumulator = 0
local heartbeatConnection: RBXScriptConnection? = nil

local function applyFriction(v: Vector3, dt: number): Vector3
	local speed = v.Magnitude
	if speed <= 1e-6 then
		return Vector3.zero
	end
	local nextSpeed = math.max(0, speed - PhysicsConfig.Ball.Friction * dt)
	return v.Unit * nextSpeed
end

local function step(dt: number)
	if not ball or not arena then
		return
	end

	velocity = VectorMath.clampMagnitudeXZ(applyFriction(velocity, dt), PhysicsConfig.Ball.MaxSpeed)
	local current = ball.Position
	local nextPosition = Vector3.new(current.X + velocity.X * dt, arena.BallY, current.Z + velocity.Z * dt)
	local radius = PhysicsConfig.Ball.Radius

	local maxZ = arena.HalfWidth - radius
	if nextPosition.Z > maxZ then
		nextPosition = Vector3.new(nextPosition.X, arena.BallY, maxZ)
		velocity = BallMath.reflectVelocity(velocity, Vector3.new(0, 0, -1), PhysicsConfig.Ball.Restitution)
	elseif nextPosition.Z < -maxZ then
		nextPosition = Vector3.new(nextPosition.X, arena.BallY, -maxZ)
		velocity = BallMath.reflectVelocity(velocity, Vector3.new(0, 0, 1), PhysicsConfig.Ball.Restitution)
	end

	local insideGoalMouth = math.abs(nextPosition.Z) <= arena.GoalHalfWidth - radius
	local fieldX = arena.HalfLength - radius
	if not insideGoalMouth then
		if nextPosition.X > fieldX then
			nextPosition = Vector3.new(fieldX, arena.BallY, nextPosition.Z)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(-1, 0, 0), PhysicsConfig.Ball.Restitution)
		elseif nextPosition.X < -fieldX then
			nextPosition = Vector3.new(-fieldX, arena.BallY, nextPosition.Z)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(1, 0, 0), PhysicsConfig.Ball.Restitution)
		end
	else
		local deepestX = arena.HalfLength + arena.GoalDepth - radius
		if nextPosition.X > deepestX then
			nextPosition = Vector3.new(deepestX, arena.BallY, nextPosition.Z)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(-1, 0, 0), PhysicsConfig.Ball.Restitution)
		elseif nextPosition.X < -deepestX then
			nextPosition = Vector3.new(-deepestX, arena.BallY, nextPosition.Z)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(1, 0, 0), PhysicsConfig.Ball.Restitution)
		end
	end

	ball.CFrame = CFrame.new(nextPosition)
end

function BallService.start(targetBall: BasePart, targetArena: FieldService.ArenaRefs)
	ball = targetBall
	arena = targetArena
	velocity = Vector3.zero
	accumulator = 0

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		accumulator += math.min(dt, PhysicsConfig.FixedStep * PhysicsConfig.MaxCatchUpSteps)
		local steps = 0
		while accumulator >= PhysicsConfig.FixedStep and steps < PhysicsConfig.MaxCatchUpSteps do
			step(PhysicsConfig.FixedStep)
			accumulator -= PhysicsConfig.FixedStep
			steps += 1
		end
	end)
end

function BallService.reset(position: Vector3)
	velocity = Vector3.zero
	if ball and arena then
		ball.CFrame = CFrame.new(position.X, arena.BallY, position.Z)
	end
end

function BallService.getPosition(): Vector3
	return if ball then ball.Position else Vector3.zero
end

function BallService.getVelocity(): Vector3
	return velocity
end

function BallService.setVelocity(newVelocity: Vector3)
	velocity = VectorMath.clampMagnitudeXZ(newVelocity, PhysicsConfig.Ball.MaxSpeed)
end

return BallService
