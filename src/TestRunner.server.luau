--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("TestEZ"))
local tests = ReplicatedStorage:WaitForChild("Tests")

local results = TestEZ.TestBootstrap:run({ tests })
if results.failureCount > 0 then
	error(string.format("TestEZ failed: %d test(s)", results.failureCount))
end

print(string.format("[Futebol Tests] passed: %d", results.successCount))
