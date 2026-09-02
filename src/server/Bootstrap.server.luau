--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Network"):WaitForChild("Remotes"))

local FieldService = require(script.Parent.Services.FieldService)
local BallService = require(script.Parent.Services.BallService)
local PlayerMotorService = require(script.Parent.Services.PlayerMotorService)
local KickService = require(script.Parent.Services.KickService)

for _, remoteName in ipairs({ "Heartbeat", "InputFrame", "PlayerSnapshot", "KickRequest" }) do
	Remotes.getOrCreate(remoteName)
end

local arena = FieldService.createArena("1v1")
BallService.start(arena.Ball, arena)
PlayerMotorService.start()
KickService.start()

print("[Futebol] server bootstrap ready")
