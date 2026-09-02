--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraController = {}
local player = Players.LocalPlayer
local running = false
local smoothedFocus = Vector3.zero

function CameraController.start()
	if running then
		return
	end
	running = true

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep("CompetitiveCamera", Enum.RenderPriority.Camera.Value, function(dt)
		local currentCamera = workspace.CurrentCamera
		if not currentCamera then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local arena = workspace:FindFirstChild("CompetitiveArena")
		local ball = arena and arena:FindFirstChild("Ball")
		if not root or not root:IsA("BasePart") then
			return
		end

		local focus = root.Position
		if ball and ball:IsA("BasePart") then
			local delta = ball.Position - root.Position
			local weighted = root.Position + delta * math.clamp(delta.Magnitude / 70, 0.18, 0.42)
			focus = Vector3.new(weighted.X, 0, weighted.Z)
		end

		local alpha = 1 - math.exp(-8 * dt)
		smoothedFocus = smoothedFocus:Lerp(focus, alpha)
		local cameraPosition = smoothedFocus + Vector3.new(0, 62, 38)
		currentCamera.CFrame = CFrame.lookAt(cameraPosition, smoothedFocus)
		currentCamera.FieldOfView = 55
	end)
end

return CameraController
