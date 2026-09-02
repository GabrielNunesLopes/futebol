--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchState = require(ReplicatedStorage.Shared.Match.MatchState)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local FieldService = require(script.Parent.FieldService)
local BallService = require(script.Parent.BallService)
local PlayerMotorService = require(script.Parent.PlayerMotorService)

local MatchService = {}

local arena: FieldService.ArenaRefs? = nil
local machine = MatchState.new()
local activePlayers: { Player } = {}
local running = false
local snapshotAccumulator = 0
local previousState = machine.State

local function assignPlayers(players: { Player })
	table.sort(players, function(a, b)
		return a.UserId < b.UserId
	end)
	activePlayers = players
	for index, player in ipairs(activePlayers) do
		player:SetAttribute("CompetitiveTeam", if index == 1 then "Blue" else "Red")
	end
end

local function resetPositions()
	if not arena then
		return
	end
	BallService.reset(arena.Center)

	for _, player in ipairs(activePlayers) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local team = player:GetAttribute("CompetitiveTeam")
			local spawnPosition = if team == "Blue" then arena.BlueSpawn else arena.RedSpawn
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = CFrame.lookAt(spawnPosition, Vector3.new(0, spawnPosition.Y, 0))
		end
	end
end

local function broadcastSnapshot()
	local remote = Remotes.get("MatchSnapshot")
	remote:FireAllClients(machine:getSnapshot())
end

local function handleTransition(fromState: string, toState: string)
	if fromState == toState then
		return
	end

	if toState == "Countdown" then
		PlayerMotorService.freezeAll(true)
		resetPositions()
	elseif toState == "Playing" or toState == "Overtime" then
		PlayerMotorService.freezeAll(false)
	elseif toState == "Finished" or toState == "Waiting" or toState == "GoalPause" then
		PlayerMotorService.freezeAll(true)
	end

	broadcastSnapshot()
end

function MatchService.configure(targetArena: FieldService.ArenaRefs)
	arena = targetArena
end

function MatchService.start(players: { Player })
	if #players < 2 then
		return false
	end
	assignPlayers({ players[1], players[2] })
	machine = MatchState.new()
	machine:start()
	previousState = "Waiting"
	handleTransition(previousState, machine.State)
	previousState = machine.State
	return true
end

function MatchService.tryStartFromServer(): boolean
	local players = Players:GetPlayers()
	if #players < 2 then
		return false
	end
	return MatchService.start(players)
end

function MatchService.registerGoal(team: "Blue" | "Red")
	if machine:goal(team) then
		handleTransition(previousState, machine.State)
		previousState = machine.State
	end
end

function MatchService.getSnapshot()
	return machine:getSnapshot()
end

function MatchService.isActive(): boolean
	return machine.State == "Playing" or machine.State == "Overtime"
end

function MatchService.startLoop()
	if running then
		return
	end
	running = true

	RunService.Heartbeat:Connect(function(dt)
		local before = machine.State
		machine:tick(dt)
		if before ~= machine.State then
			handleTransition(before, machine.State)
		end
		previousState = machine.State

		snapshotAccumulator += dt
		if snapshotAccumulator >= 0.1 then
			snapshotAccumulator = 0
			broadcastSnapshot()
		end
	end)
end

return MatchService
