--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Network"):WaitForChild("Remotes"))

local MovementController = require(script.Parent.Controllers.MovementController)
local InputController = require(script.Parent.Controllers.InputController)

local heartbeatRemote = Remotes.get("Heartbeat")
assert(heartbeatRemote:IsA("RemoteEvent"))

MovementController.start()
InputController.start(MovementController.getLastIntent)

print("[Futebol] client bootstrap ready")
