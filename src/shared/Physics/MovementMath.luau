--!strict

local PhysicsConfig = require(script.Parent.Parent.Config.PhysicsConfig)
local VectorMath = require(script.Parent.Parent.Math.VectorMath)

local MovementMath = {}

local function moveToward(current: Vector3, target: Vector3, maxDelta: number): Vector3
	local delta = target - current
	local distance = delta.Magnitude
	if distance <= maxDelta or distance <= 1e-6 then
		return target
	end
	return current + delta / distance * maxDelta
end

function MovementMath.stepVelocity(current: Vector3, input: Vector3, dt: number): Vector3
	local player = PhysicsConfig.Player
	local currentXZ = VectorMath.flattenXZ(current)
	local inputXZ = VectorMath.clampMagnitudeXZ(input, 1)

	if dt <= 0 then
		return VectorMath.clampMagnitudeXZ(currentXZ, player.MaxSpeed)
	end

	if inputXZ.Magnitude <= 1e-6 then
		return moveToward(currentXZ, Vector3.zero, player.Deceleration * dt)
	end

	local desiredVelocity = VectorMath.safeUnitXZ(inputXZ) * (player.MaxSpeed * inputXZ.Magnitude)
	local acceleration = player.Acceleration
	if currentXZ.Magnitude > 1e-6 and currentXZ:Dot(desiredVelocity) < 0 then
		acceleration = player.ReverseAcceleration
	end

	local nextVelocity = moveToward(currentXZ, desiredVelocity, acceleration * dt)
	return VectorMath.clampMagnitudeXZ(nextVelocity, player.MaxSpeed)
end

return MovementMath
