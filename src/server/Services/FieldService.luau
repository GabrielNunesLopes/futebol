--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FieldConfig = require(ReplicatedStorage.Shared.Config.FieldConfig)
local PhysicsConfig = require(ReplicatedStorage.Shared.Config.PhysicsConfig)

local FieldService = {}

export type ArenaRefs = {
	Folder: Folder,
	Ball: Part,
	BlueSpawn: Vector3,
	RedSpawn: Vector3,
	Center: Vector3,
	HalfLength: number,
	HalfWidth: number,
	GoalHalfWidth: number,
	GoalDepth: number,
	BallY: number,
}

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, transparency: number?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Transparency = transparency or 0
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

local function makeEndSegments(folder: Folder, x: number, halfWidth: number, goalHalfWidth: number, wallThickness: number, wallHeight: number)
	local segmentLength = halfWidth - goalHalfWidth
	local zOffset = goalHalfWidth + segmentLength / 2
	for _, sign in ipairs({ -1, 1 }) do
		makePart(
			folder,
			if sign < 0 then "EndWallLower" else "EndWallUpper",
			Vector3.new(wallThickness, wallHeight, segmentLength),
			Vector3.new(x, wallHeight / 2, zOffset * sign),
			Color3.fromRGB(28, 31, 38)
		)
	end
end

function FieldService.createArena(mode: string): ArenaRefs
	local old = Workspace:FindFirstChild("CompetitiveArena")
	if old then
		old:Destroy()
	end

	local scale = FieldConfig.Modes[mode] or FieldConfig.Modes["1v1"]
	local length = FieldConfig.BaseLength * scale.LengthScale
	local width = FieldConfig.BaseWidth * scale.WidthScale
	local halfLength = length / 2
	local halfWidth = width / 2
	local goalHalfWidth = FieldConfig.GoalWidth / 2

	local folder = Instance.new("Folder")
	folder.Name = "CompetitiveArena"
	folder.Parent = Workspace

	local floor = makePart(folder, "Floor", Vector3.new(length, FieldConfig.FloorThickness, width), Vector3.new(0, -FieldConfig.FloorThickness / 2, 0), Color3.fromRGB(37, 101, 63))
	floor.Material = Enum.Material.Grass

	makePart(folder, "NorthWall", Vector3.new(length + FieldConfig.WallThickness * 2, FieldConfig.WallHeight, FieldConfig.WallThickness), Vector3.new(0, FieldConfig.WallHeight / 2, -halfWidth - FieldConfig.WallThickness / 2), Color3.fromRGB(28, 31, 38))
	makePart(folder, "SouthWall", Vector3.new(length + FieldConfig.WallThickness * 2, FieldConfig.WallHeight, FieldConfig.WallThickness), Vector3.new(0, FieldConfig.WallHeight / 2, halfWidth + FieldConfig.WallThickness / 2), Color3.fromRGB(28, 31, 38))
	makeEndSegments(folder, -halfLength - FieldConfig.WallThickness / 2, halfWidth, goalHalfWidth, FieldConfig.WallThickness, FieldConfig.WallHeight)
	makeEndSegments(folder, halfLength + FieldConfig.WallThickness / 2, halfWidth, goalHalfWidth, FieldConfig.WallThickness, FieldConfig.WallHeight)

	local centerLine = makePart(folder, "CenterLine", Vector3.new(0.18, 0.05, width), Vector3.new(0, 0.04, 0), Color3.fromRGB(235, 235, 235))
	centerLine.CanCollide = false

	for _, side in ipairs({ -1, 1 }) do
		local x = side * (halfLength + FieldConfig.GoalDepth / 2)
		local backWall = makePart(folder, if side < 0 then "BlueGoalBack" else "RedGoalBack", Vector3.new(FieldConfig.WallThickness, FieldConfig.WallHeight, FieldConfig.GoalWidth), Vector3.new(x + side * FieldConfig.GoalDepth / 2, FieldConfig.WallHeight / 2, 0), Color3.fromRGB(230, 230, 230), 0.3)
		backWall.CanCollide = true
	end

	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(PhysicsConfig.Ball.Radius * 2, PhysicsConfig.Ball.Radius * 2, PhysicsConfig.Ball.Radius * 2)
	ball.Position = Vector3.new(0, FieldConfig.BallHeight, 0)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = Color3.fromRGB(245, 245, 245)
	ball.Parent = folder

	return {
		Folder = folder,
		Ball = ball,
		BlueSpawn = Vector3.new(-FieldConfig.PlayerSpawnOffset, 3, 0),
		RedSpawn = Vector3.new(FieldConfig.PlayerSpawnOffset, 3, 0),
		Center = Vector3.new(0, FieldConfig.BallHeight, 0),
		HalfLength = halfLength,
		HalfWidth = halfWidth,
		GoalHalfWidth = goalHalfWidth,
		GoalDepth = FieldConfig.GoalDepth,
		BallY = FieldConfig.BallHeight,
	}
end

return FieldService
