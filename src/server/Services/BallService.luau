--!strict

local Players = game:GetService("Players")
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
local lastTouchUserId: number? = nil

local function applyFriction(v: Vector3, dt: number): Vector3
	local speed = v.Magnitude
	if speed <= 1e-6 then
		return Vector3.zero
	end
	local nextSpeed = math.max(0, speed - PhysicsConfig.Ball.Friction * dt)
	return v.Unit * nextSpeed
end

local function resolvePlayerContacts(nextPosition: Vector3, ballY: number): Vector3
	local combinedRadius = PhysicsConfig.Player.Radius + PhysicsConfig.Ball.Radius
	local resolved = nextPosition

	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local offset = VectorMath.flattenXZ(resolved - root.Position)
			local distance = offset.Magnitude
			if distance < combinedRadius then
				local normal = VectorMath.safeUnitXZ(offset)
				if normal.Magnitude <= 1e-6 then
					normal = VectorMath.safeUnitXZ(root.CFrame.LookVector)
					if normal.Magnitude <= 1e-6 then
						normal = Vector3.new(1, 0, 0)
					end
				end

				resolved = Vector3.new(root.Position.X + normal.X * combinedRadius, ballY, root.Position.Z + normal.Z * combinedRadius)
				local playerVelocity = VectorMath.flattenXZ(root.AssemblyLinearVelocity)
				local approachSpeed = math.max(0, playerVelocity:Dot(normal))
				if approachSpeed > 0.05 then
					velocity = VectorMath.clampMagnitudeXZ(velocity + normal * approachSpeed * PhysicsConfig.Ball.BodyPushFactor, PhysicsConfig.Ball.MaxSpeed)
					lastTouchUserId = player.UserId
				end
			end
		end
	end

	return resolved
end

local function step(dt: number)
	local currentBall = ball
	local currentArena = arena
	if not currentBall or not currentArena then
		return
	end

	velocity = VectorMath.clampMagnitudeXZ(applyFriction(velocity, dt), PhysicsConfig.Ball.MaxSpeed)
	local current = currentBall.Position
	local nextPosition = Vector3.new(current.X + velocity.X * dt, currentArena.BallY, current.Z + velocity.Z * dt)
	local radius = PhysicsConfig.Ball.Radius

	nextPosition = resolvePlayerContacts(nextPosition, currentArena.BallY)

	local behindGoalLine = math.abs(nextPosition.X) > currentArena.HalfLength
	if behindGoalLine then
		local maxGoalZ = currentArena.GoalHalfWidth - radius
		if nextPosition.Z > maxGoalZ then
			nextPosition = Vector3.new(nextPosition.X, currentArena.BallY, maxGoalZ)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(0, 0, -1), PhysicsConfig.Ball.Restitution)
		elseif nextPosition.Z < -maxGoalZ then
			nextPosition = Vector3.new(nextPosition.X, currentArena.BallY, -maxGoalZ)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(0, 0, 1), PhysicsConfig.Ball.Restitution)
		end

		local deepestX = currentArena.HalfLength + currentArena.GoalDepth - radius
		if nextPosition.X > deepestX then
			nextPosition = Vector3.new(deepestX, currentArena.BallY, nextPosition.Z)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(-1, 0, 0), PhysicsConfig.Ball.Restitution)
		elseif nextPosition.X < -deepestX then
			nextPosition = Vector3.new(-deepestX, currentArena.BallY, nextPosition.Z)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(1, 0, 0), PhysicsConfig.Ball.Restitution)
		end
	else
		local maxZ = currentArena.HalfWidth - radius
		if nextPosition.Z > maxZ then
			nextPosition = Vector3.new(nextPosition.X, currentArena.BallY, maxZ)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(0, 0, -1), PhysicsConfig.Ball.Restitution)
		elseif nextPosition.Z < -maxZ then
			nextPosition = Vector3.new(nextPosition.X, currentArena.BallY, -maxZ)
			velocity = BallMath.reflectVelocity(velocity, Vector3.new(0, 0, 1), PhysicsConfig.Ball.Restitution)
		end

		local insideGoalMouth = math.abs(nextPosition.Z) <= currentArena.GoalHalfWidth - radius
		local fieldX = currentArena.HalfLength - radius
		if not insideGoalMouth then
			if nextPosition.X > fieldX then
				nextPosition = Vector3.new(fieldX, currentArena.BallY, nextPosition.Z)
				velocity = BallMath.reflectVelocity(velocity, Vector3.new(-1, 0, 0), PhysicsConfig.Ball.Restitution)
			elseif nextPosition.X < -fieldX then
				nextPosition = Vector3.new(-fieldX, currentArena.BallY, nextPosition.Z)
				velocity = BallMath.reflectVelocity(velocity, Vector3.new(1, 0, 0), PhysicsConfig.Ball.Restitution)
			end
		end
	end

	currentBall.CFrame = CFrame.new(nextPosition)
end

function BallService.start(targetBall: BasePart, targetArena: FieldService.ArenaRefs)
	ball = targetBall
	arena = targetArena
	velocity = Vector3.zero
	lastTouchUserId = nil
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
	lastTouchUserId = nil
	local currentBall = ball
	local currentArena = arena
	if currentBall and currentArena then
		currentBall.CFrame = CFrame.new(position.X, currentArena.BallY, position.Z)
	end
end

function BallService.getPosition(): Vector3
	local currentBall = ball
	return if currentBall then currentBall.Position else Vector3.zero
end

function BallService.getVelocity(): Vector3
	return velocity
end

function BallService.setVelocity(newVelocity: Vector3)
	velocity = VectorMath.clampMagnitudeXZ(newVelocity, PhysicsConfig.Ball.MaxSpeed)
end

function BallService.setLastTouch(userId: number?)
	lastTouchUserId = userId
end

function BallService.getLastTouch(): number?
	return lastTouchUserId
end

return BallService
