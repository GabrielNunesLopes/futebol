--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local MovementMath = require(Shared.Physics.MovementMath)
	local PhysicsConfig = require(Shared.Config.PhysicsConfig)

	describe("MovementMath", function()
		it("normalizes diagonal input so it cannot exceed max speed", function()
			local velocity = Vector3.zero
			for _ = 1, 120 do
				velocity = MovementMath.stepVelocity(velocity, Vector3.new(1, 0, 1), 1 / 60)
			end
			expect(velocity.Magnitude).to.be.near(PhysicsConfig.Player.MaxSpeed, 0.001)
		end)

		it("accelerates toward max speed without overshooting", function()
			local velocity = MovementMath.stepVelocity(Vector3.zero, Vector3.new(1, 0, 0), 0.1)
			expect(velocity.X > 0).to.equal(true)
			expect(velocity.Magnitude <= PhysicsConfig.Player.MaxSpeed).to.equal(true)
		end)

		it("decelerates toward zero", function()
			local start = Vector3.new(20, 0, 0)
			local velocity = MovementMath.stepVelocity(start, Vector3.zero, 0.05)
			expect(velocity.Magnitude < start.Magnitude).to.equal(true)
		end)

		it("preserves a short momentum transition when reversing", function()
			local start = Vector3.new(20, 0, 0)
			local velocity = MovementMath.stepVelocity(start, Vector3.new(-1, 0, 0), 1 / 60)
			expect(velocity.X > 0).to.equal(true)
			expect(velocity.X < start.X).to.equal(true)
		end)
	end)
end
