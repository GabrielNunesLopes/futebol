--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Network"):WaitForChild("Remotes"))

local FieldService = require(script.Parent.Services.FieldService)
local BallService = require(script.Parent.Services.BallService)

Remotes.getOrCreate("Heartbeat")

local arena = FieldService.createArena("1v1")
BallService.start(arena.Ball, arena)

print("[Futebol] server bootstrap ready")
