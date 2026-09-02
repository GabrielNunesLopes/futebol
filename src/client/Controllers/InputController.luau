--!strict

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VectorMath = require(ReplicatedStorage.Shared.Math.VectorMath)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)

local InputController = {}
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local kickSequence = 0
local running = false

local function aimFromPointer(fallback: Vector3): Vector3
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return VectorMath.safeUnitXZ(fallback)
	end

	if UserInputService.MouseEnabled then
		local hit = mouse.Hit
		local pointerDirection = VectorMath.safeUnitXZ(hit.Position - root.Position)
		if pointerDirection.Magnitude > 1e-6 then
			return pointerDirection
		end
	end

	local fallbackDirection = VectorMath.safeUnitXZ(fallback)
	if fallbackDirection.Magnitude > 1e-6 then
		return fallbackDirection
	end
	return VectorMath.safeUnitXZ(root.CFrame.LookVector)
end

function InputController.start(fallbackAimProvider: () -> Vector3)
	if running then
		return
	end
	running = true

	local kickRemote = Remotes.get("KickRequest")
	ContextActionService:BindAction("CompetitiveKick", function(_, inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		kickSequence += 1
		kickRemote:FireServer(aimFromPointer(fallbackAimProvider()), kickSequence)
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	ContextActionService:SetTitle("CompetitiveKick", "CHUTE")
	ContextActionService:SetPosition("CompetitiveKick", UDim2.fromScale(0.83, 0.72))
end

return InputController
