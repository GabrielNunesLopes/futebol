--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Network"):WaitForChild("Remotes"))

local heartbeatRemote = Remotes.get("Heartbeat")
assert(heartbeatRemote:IsA("RemoteEvent"))

print("[Futebol] client bootstrap ready")
