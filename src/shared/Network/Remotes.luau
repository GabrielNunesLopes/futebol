--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		if not RunService:IsServer() then
			error("ReplicatedStorage.Remotes does not exist on the client")
		end

		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	if not folder:IsA("Folder") then
		error("ReplicatedStorage.Remotes must be a Folder")
	end

	return folder
end

function Remotes.get(name: string): RemoteEvent
	local remote = getFolder():FindFirstChild(name)
	if not remote then
		error(string.format("RemoteEvent %q does not exist", name))
	end
	if not remote:IsA("RemoteEvent") then
		error(string.format("Remote %q is not a RemoteEvent", name))
	end
	return remote
end

function Remotes.getOrCreate(name: string): RemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		if not existing:IsA("RemoteEvent") then
			error(string.format("Remote %q exists but is not a RemoteEvent", name))
		end
		return existing
	end

	if not RunService:IsServer() then
		error(string.format("Client cannot create RemoteEvent %q", name))
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

return Remotes
