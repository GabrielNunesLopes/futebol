--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Network"):WaitForChild("Remotes"))

local FieldService = require(script.Parent.Services.FieldService)
local BallService = require(script.Parent.Services.BallService)
local PlayerMotorService = require(script.Parent.Services.PlayerMotorService)
local KickService = require(script.Parent.Services.KickService)
local GoalService = require(script.Parent.Services.GoalService)
local MatchService = require(script.Parent.Services.MatchService)

for _, remoteName in ipairs({ "Heartbeat", "InputFrame", "PlayerSnapshot", "KickRequest", "MatchSnapshot" }) do
	Remotes.getOrCreate(remoteName)
end

local arena = FieldService.createArena("1v1")
BallService.start(arena.Ball, arena)
PlayerMotorService.start()
MatchService.configure(arena)
MatchService.startLoop()
KickService.setActiveProvider(MatchService.isActive)
KickService.start()
GoalService.start(arena, MatchService.registerGoal)

local function tryStartMatch()
	if not MatchService.isActive() then
		MatchService.tryStartFromServer()
	end
end

Players.PlayerAdded:Connect(function()
	task.delay(1, tryStartMatch)
end)

task.defer(tryStartMatch)

print("[Futebol] server bootstrap ready")
