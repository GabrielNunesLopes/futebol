--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)

local HudController = {}
local localPlayer = Players.LocalPlayer
local running = false

local function corner(radius: number): UICorner
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	return ui
end

local function textLabel(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245, 247, 250)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextScaled = false
	label.Parent = parent
	return label
end

local function formatTime(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

function HudController.start()
	if running then
		return
	end
	running = true

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("CompetitiveHUD")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "CompetitiveHUD"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local top = Instance.new("Frame")
	top.Name = "TopBar"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.fromScale(0.5, 0.025)
	top.Size = UDim2.fromOffset(330, 76)
	top.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
	top.BackgroundTransparency = 0.08
	corner(14).Parent = top
	top.Parent = gui

	local blue = textLabel(top, "BlueScore", "0", UDim2.fromOffset(80, 50), UDim2.fromOffset(15, 5), 36)
	blue.TextColor3 = Color3.fromRGB(70, 155, 255)
	local red = textLabel(top, "RedScore", "0", UDim2.fromOffset(80, 50), UDim2.fromOffset(235, 5), 36)
	red.TextColor3 = Color3.fromRGB(255, 80, 90)
	local timer = textLabel(top, "Timer", "3:00", UDim2.fromOffset(130, 34), UDim2.fromOffset(100, 7), 24)
	timer.TextXAlignment = Enum.TextXAlignment.Center
	local state = textLabel(top, "State", "AGUARDANDO", UDim2.fromOffset(190, 22), UDim2.fromOffset(70, 44), 13)
	state.TextColor3 = Color3.fromRGB(175, 182, 195)
	state.TextXAlignment = Enum.TextXAlignment.Center

	local centerMessage = textLabel(gui, "CenterMessage", "", UDim2.fromScale(0.5, 0.15), UDim2.fromScale(0.25, 0.38), 52)
	centerMessage.TextScaled = true
	centerMessage.TextStrokeTransparency = 0.35
	centerMessage.Visible = false

	local scoreboard = Instance.new("Frame")
	scoreboard.Name = "Scoreboard"
	scoreboard.AnchorPoint = Vector2.new(0.5, 0.5)
	scoreboard.Position = UDim2.fromScale(0.5, 0.5)
	scoreboard.Size = UDim2.fromOffset(560, 330)
	scoreboard.BackgroundColor3 = Color3.fromRGB(12, 14, 19)
	scoreboard.BackgroundTransparency = 0.04
	scoreboard.Visible = false
	corner(16).Parent = scoreboard
	scoreboard.Parent = gui

	local title = textLabel(scoreboard, "Title", "PLACAR", UDim2.new(1, -30, 0, 48), UDim2.fromOffset(15, 12), 25)
	title.TextXAlignment = Enum.TextXAlignment.Left
	local rows = Instance.new("Frame")
	rows.Name = "Rows"
	rows.Size = UDim2.new(1, -30, 1, -78)
	rows.Position = UDim2.fromOffset(15, 65)
	rows.BackgroundTransparency = 1
	rows.Parent = scoreboard
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = rows

	local function rebuildRows()
		for _, child in ipairs(rows:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local teamName = player:GetAttribute("CompetitiveTeam") or "—"
			local pingMs = math.floor(player:GetNetworkPing() * 2000 + 0.5)
			local row = textLabel(rows, player.Name, string.format("%-18s   %s   Ping %d ms", player.DisplayName, teamName, pingMs), UDim2.new(1, 0, 0, 48), UDim2.new(), 17)
			row.BackgroundTransparency = 0.65
			row.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
			row.TextXAlignment = Enum.TextXAlignment.Left
			corner(10).Parent = row
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Tab then
			rebuildRows()
			scoreboard.Visible = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab then
			scoreboard.Visible = false
		end
	end)

	local snapshotRemote = Remotes.get("MatchSnapshot")
	snapshotRemote.OnClientEvent:Connect(function(snapshot: any)
		if typeof(snapshot) ~= "table" then
			return
		end
		blue.Text = tostring(snapshot.BlueScore or 0)
		red.Text = tostring(snapshot.RedScore or 0)
		timer.Text = formatTime(snapshot.TimeRemaining or 0)

		local matchState = tostring(snapshot.State or "Waiting")
		state.Text = string.upper(matchState)
		centerMessage.Visible = false

		if matchState == "Countdown" then
			local remaining = tonumber(snapshot.CountdownRemaining) or 0
			centerMessage.Text = if remaining <= 0.05 then "GO!" else tostring(math.max(1, math.ceil(remaining)))
			centerMessage.Visible = true
		elseif matchState == "Overtime" then
			state.Text = "OVERTIME • GOLDEN GOAL"
		elseif matchState == "GoalPause" then
			centerMessage.Text = "GOL!"
			centerMessage.Visible = true
		elseif matchState == "Finished" then
			local myTeam = localPlayer:GetAttribute("CompetitiveTeam")
			centerMessage.Text = if snapshot.Winner == myTeam then "VITÓRIA" else "DERROTA"
			centerMessage.Visible = true
		elseif matchState == "Waiting" then
			state.Text = "AGUARDANDO 2 JOGADORES"
		end
	end)
end

return HudController
