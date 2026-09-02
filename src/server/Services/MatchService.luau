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
local playerGoals: { [number]: number } = {}
local running = false
local snapshotAccumulator = 0
local previousState = machine.State

local function isActivePlayer(player: Player): boolean
	return table.find(activePlayers, player) ~= nil
end

local function clearAssignments()
	for _, player in ipairs(activePlayers) do
		if player.Parent == Players then
			player:SetAttribute("CompetitiveTeam", nil)
		end
	end
	activePlayers = {}
	playerGoals = {}
end

local function assignPlayers(players: { Player })
	table.sort(players, function(a, b)
		return a.UserId < b.UserId
	end)
	activePlayers = players
	playerGoals = {}
	for index, player in ipairs(activePlayers) do
		player:SetAttribute("CompetitiveTeam", if index == 1 then "Blue" else "Red")
		playerGoals[player.UserId] = 0
	end
end

local function resetPositions()
	local currentArena = arena
	if not currentArena then
		return
	end
	BallService.reset(currentArena.Center)

	for _, player in ipairs(activePlayers) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local team = player:GetAttribute("CompetitiveTeam")
			local spawnPosition = if team == "Blue" then currentArena.BlueSpawn else currentArena.RedSpawn
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = CFrame.lookAt(spawnPosition, Vector3.new(0, spawnPosition.Y, 0))
		end
	end
end

function MatchService.getSnapshot()
	local snapshot = machine:getSnapshot()
	local payload: any = table.clone(snapshot)
	payload.PlayerGoals = table.clone(playerGoals)
	return payload
end

local function broadcastSnapshot()
	local remote = Remotes.get("MatchSnapshot")
	remote:FireAllClients(MatchService.getSnapshot())
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
	elseif toState == "Waiting" then
		PlayerMotorService.freezeAll(true)
		clearAssignments()
		local currentArena = arena
		if currentArena then
			BallService.reset(currentArena.Center)
		end
	elseif toState == "Finished" or toState == "GoalPause" then
		PlayerMotorService.freezeAll(true)
	end

	broadcastSnapshot()
end

local function stopToWaiting()
	clearAssignments()
	machine = MatchState.new()
	previousState = machine.State
	PlayerMotorService.freezeAll(true)
	local currentArena = arena
	if currentArena then
		BallService.reset(currentArena.Center)
	end
	broadcastSnapshot()
end

function MatchService.configure(targetArena: FieldService.ArenaRefs)
	arena = targetArena
end

function MatchService.start(players: { Player })
	if #players < 2 or machine.State ~= "Waiting" then
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
	if machine.State ~= "Waiting" then
		return false
	end
	local players = Players:GetPlayers()
	if #players < 2 then
		return false
	end
	return MatchService.start(players)
end

function MatchService.registerGoal(team: "Blue" | "Red", scorerUserId: number?)
	if machine:goal(team) then
		if scorerUserId then
			local scorer = Players:GetPlayerByUserId(scorerUserId)
			if scorer and scorer:GetAttribute("CompetitiveTeam") == team then
				playerGoals[scorerUserId] = (playerGoals[scorerUserId] or 0) + 1
			end
		end
		handleTransition(previousState, machine.State)
		previousState = machine.State
	end
end

function MatchService.isActive(): boolean
	return machine.State == "Playing" or machine.State == "Overtime"
end

function MatchService.hasMatch(): boolean
	return machine.State ~= "Waiting"
end

function MatchService.startLoop()
	if running then
		return
	end
	running = true

	Players.PlayerRemoving:Connect(function(player)
		if isActivePlayer(player) then
			stopToWaiting()
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local before = machine.State
		machine:tick(dt)
		if before ~= machine.State then
			handleTransition(before, machine.State)
			if machine.State == "Waiting" then
				task.defer(MatchService.tryStartFromServer)
			end
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
