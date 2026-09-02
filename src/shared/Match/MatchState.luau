--!strict

local MatchConfig = require(script.Parent.Parent.Config.MatchConfig)

local MatchState = {}
MatchState.__index = MatchState

export type TeamName = "Blue" | "Red"
export type StateName = "Waiting" | "Countdown" | "Playing" | "GoalPause" | "Overtime" | "Finished"

export type Snapshot = {
	State: StateName,
	BlueScore: number,
	RedScore: number,
	TimeRemaining: number,
	CountdownRemaining: number,
	Overtime: boolean,
	Winner: TeamName?,
}

function MatchState.new()
	local self = setmetatable({}, MatchState)
	self.State = "Waiting" :: StateName
	self.BlueScore = 0
	self.RedScore = 0
	self.TimeRemaining = MatchConfig.RegulationSeconds
	self.CountdownRemaining = 0
	self.GoalPauseRemaining = 0
	self.Overtime = false
	self.Winner = nil :: TeamName?
	return self
end

function MatchState:start()
	self.BlueScore = 0
	self.RedScore = 0
	self.TimeRemaining = MatchConfig.RegulationSeconds
	self.CountdownRemaining = MatchConfig.CountdownSeconds
	self.GoalPauseRemaining = 0
	self.Overtime = false
	self.Winner = nil
	self.State = "Countdown"
end

function MatchState:goal(team: TeamName): boolean
	if self.State ~= "Playing" and self.State ~= "Overtime" then
		return false
	end

	if team == "Blue" then
		self.BlueScore += 1
	else
		self.RedScore += 1
	end

	if self.State == "Overtime" then
		self.Winner = team
		self.State = "Finished"
		return true
	end

	self.GoalPauseRemaining = MatchConfig.GoalPauseSeconds
	self.State = "GoalPause"
	return true
end

function MatchState:tick(dt: number)
	if dt <= 0 then
		return
	end

	if self.State == "Countdown" then
		self.CountdownRemaining = math.max(0, self.CountdownRemaining - dt)
		if self.CountdownRemaining <= 0 then
			self.State = if self.Overtime then "Overtime" else "Playing"
		end
	elseif self.State == "GoalPause" then
		self.GoalPauseRemaining = math.max(0, self.GoalPauseRemaining - dt)
		if self.GoalPauseRemaining <= 0 then
			self.CountdownRemaining = MatchConfig.CountdownSeconds
			self.State = "Countdown"
		end
	elseif self.State == "Playing" then
		self.TimeRemaining = math.max(0, self.TimeRemaining - dt)
		if self.TimeRemaining <= 0 then
			if self.BlueScore == self.RedScore then
				self.Overtime = true
				self.CountdownRemaining = MatchConfig.CountdownSeconds
				self.State = "Countdown"
			else
				self.Winner = if self.BlueScore > self.RedScore then "Blue" else "Red"
				self.State = "Finished"
			end
		end
	end
end

function MatchState:getSnapshot(): Snapshot
	return {
		State = self.State,
		BlueScore = self.BlueScore,
		RedScore = self.RedScore,
		TimeRemaining = self.TimeRemaining,
		CountdownRemaining = self.CountdownRemaining,
		Overtime = self.Overtime,
		Winner = self.Winner,
	}
end

return MatchState
