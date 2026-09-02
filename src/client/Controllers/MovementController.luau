--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementMath = require(ReplicatedStorage.Shared.Physics.MovementMath)
local VectorMath = require(ReplicatedStorage.Shared.Math.VectorMath)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)

local MovementController = {}

local localPlayer = Players.LocalPlayer
local sequence = 0
local sendAccumulator = 0
local lastIntent = Vector3.zero
local controls: any = nil
local running = false

local function getControls()
	if controls then
		return controls
	end
	local playerScripts = localPlayer:WaitForChild("PlayerScripts")
	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	controls = playerModule:GetControls()
	return controls
end

local function cameraRelativeIntent(moveVector: Vector3): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return VectorMath.clampMagnitudeXZ(Vector3.new(moveVector.X, 0, moveVector.Z), 1)
	end

	local forward = VectorMath.safeUnitXZ(camera.CFrame.LookVector)
	local right = VectorMath.safeUnitXZ(camera.CFrame.RightVector)
	local world = right * moveVector.X + forward * -moveVector.Z
	return VectorMath.clampMagnitudeXZ(world, 1)
end

function MovementController.getLastIntent(): Vector3
	return lastIntent
end

function MovementController.start()
	if running then
		return
	end
	running = true

	local inputRemote = Remotes.get("InputFrame")
	local snapshotRemote = Remotes.get("PlayerSnapshot")

	snapshotRemote.OnClientEvent:Connect(function(serverPosition: any, serverVelocity: any, acknowledgedSequence: any)
		if typeof(serverPosition) ~= "Vector3" or typeof(serverVelocity) ~= "Vector3" or typeof(acknowledgedSequence) ~= "number" then
			return
		end
		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		local errorDistance = (root.Position - serverPosition).Magnitude
		if errorDistance > 7 then
			root.CFrame = CFrame.new(serverPosition) * (root.CFrame - root.CFrame.Position)
		elseif errorDistance > 0.35 then
			root.CFrame = root.CFrame:Lerp(CFrame.new(serverPosition) * (root.CFrame - root.CFrame.Position), 0.18)
		end
		root.AssemblyLinearVelocity = serverVelocity
	end)

	RunService.RenderStepped:Connect(function(dt)
		local moveVector = getControls():GetMoveVector()
		lastIntent = cameraRelativeIntent(moveVector)

		local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local predicted = MovementMath.stepVelocity(root.AssemblyLinearVelocity, lastIntent, dt)
			root.AssemblyLinearVelocity = Vector3.new(predicted.X, root.AssemblyLinearVelocity.Y, predicted.Z)
		end

		sendAccumulator += dt
		if sendAccumulator >= 1 / 30 then
			sendAccumulator = 0
			sequence += 1
			inputRemote:FireServer(lastIntent, sequence)
		end
	end)
end

return MovementController
