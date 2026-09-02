--!strict

local RateLimitService = {}

export type Bucket = {
	Tokens: number,
	LastUpdate: number,
}

local buckets: { [string]: Bucket } = {}

local function keyFor(userId: number, action: string): string
	return string.format("%d:%s", userId, action)
end

function RateLimitService.allow(userId: number, action: string, capacity: number, refillPerSecond: number): boolean
	local now = os.clock()
	local key = keyFor(userId, action)
	local bucket = buckets[key]
	if not bucket then
		bucket = { Tokens = capacity, LastUpdate = now }
		buckets[key] = bucket
	end

	local elapsed = math.max(0, now - bucket.LastUpdate)
	bucket.LastUpdate = now
	bucket.Tokens = math.min(capacity, bucket.Tokens + elapsed * refillPerSecond)

	if bucket.Tokens < 1 then
		return false
	end

	bucket.Tokens -= 1
	return true
end

function RateLimitService.clearUser(userId: number)
	local prefix = tostring(userId) .. ":"
	for key in pairs(buckets) do
		if string.sub(key, 1, #prefix) == prefix then
			buckets[key] = nil
		end
	end
end

return RateLimitService
