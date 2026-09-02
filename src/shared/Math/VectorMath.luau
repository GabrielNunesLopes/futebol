--!strict

local VectorMath = {}

function VectorMath.flattenXZ(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function VectorMath.safeUnitXZ(v: Vector3): Vector3
	local flat = VectorMath.flattenXZ(v)
	local magnitude = flat.Magnitude
	if magnitude <= 1e-6 then
		return Vector3.zero
	end
	return flat / magnitude
end

function VectorMath.clampMagnitudeXZ(v: Vector3, maxMagnitude: number): Vector3
	local flat = VectorMath.flattenXZ(v)
	local magnitude = flat.Magnitude
	if magnitude <= maxMagnitude or magnitude <= 1e-6 then
		return flat
	end
	return flat / magnitude * maxMagnitude
end

return VectorMath
