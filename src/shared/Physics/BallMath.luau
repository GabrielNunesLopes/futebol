--!strict

local PhysicsConfig = require(script.Parent.Parent.Config.PhysicsConfig)
local VectorMath = require(script.Parent.Parent.Math.VectorMath)

local BallMath = {}

function BallMath.computeKick(
	ballPosition: Vector3,
	playerPosition: Vector3,
	playerVelocity: Vector3,
	aimDirection: Vector3,
	power: number
): Vector3
	local contactNormal = VectorMath.safeUnitXZ(ballPosition - playerPosition)
	local aim = VectorMath.safeUnitXZ(aimDirection)

	if contactNormal.Magnitude <= 1e-6 then
		contactNormal = if aim.Magnitude > 1e-6 then aim else Vector3.new(1, 0, 0)
	end
	if aim.Magnitude <= 1e-6 then
		aim = contactNormal
	end

	local kickConfig = PhysicsConfig.Kick
	local blended = VectorMath.safeUnitXZ(contactNormal * (1 - kickConfig.AimBlend) + aim * kickConfig.AimBlend)
	local momentum = VectorMath.flattenXZ(playerVelocity) * kickConfig.MomentumContribution
	local velocity = blended * math.max(power, 0) + momentum

	return VectorMath.clampMagnitudeXZ(velocity, PhysicsConfig.Ball.MaxSpeed)
end

function BallMath.reflectVelocity(velocity: Vector3, normal: Vector3, restitution: number): Vector3
	local v = VectorMath.flattenXZ(velocity)
	local n = VectorMath.safeUnitXZ(normal)
	if n.Magnitude <= 1e-6 then
		return VectorMath.clampMagnitudeXZ(v, PhysicsConfig.Ball.MaxSpeed)
	end

	local reflected = v - 2 * v:Dot(n) * n
	return VectorMath.clampMagnitudeXZ(reflected * math.clamp(restitution, 0, 1), PhysicsConfig.Ball.MaxSpeed)
end

return BallMath
