--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local BallMath = require(Shared.Physics.BallMath)
	local PhysicsConfig = require(Shared.Config.PhysicsConfig)

	describe("BallMath", function()
		it("kicks away from the player on center contact", function()
			local velocity = BallMath.computeKick(
				Vector3.new(2, 0, 0),
				Vector3.zero,
				Vector3.zero,
				Vector3.new(1, 0, 0),
				PhysicsConfig.Kick.Power
			)
			expect(velocity.X).to.be.greaterThan(0)
		end)

		it("changes direction for side contact", function()
			local velocity = BallMath.computeKick(
				Vector3.new(1, 0, 1),
				Vector3.zero,
				Vector3.zero,
				Vector3.new(1, 0, 0),
				PhysicsConfig.Kick.Power
			)
			expect(math.abs(velocity.Z)).to.be.greaterThan(0)
		end)

		it("includes bounded player momentum", function()
			local withoutMomentum = BallMath.computeKick(Vector3.new(1, 0, 0), Vector3.zero, Vector3.zero, Vector3.new(1, 0, 0), 20)
			local withMomentum = BallMath.computeKick(Vector3.new(1, 0, 0), Vector3.zero, Vector3.new(10, 0, 0), Vector3.new(1, 0, 0), 20)
			expect(withMomentum.X).to.be.greaterThan(withoutMomentum.X)
		end)

		it("clamps kick velocity to the configured ball max speed", function()
			local velocity = BallMath.computeKick(Vector3.new(1, 0, 0), Vector3.zero, Vector3.new(500, 0, 0), Vector3.new(1, 0, 0), 500)
			expect(velocity.Magnitude).to.be.lessThanOrEqual(PhysicsConfig.Ball.MaxSpeed + 0.001)
		end)

		it("reflects velocity with restitution", function()
			local reflected = BallMath.reflectVelocity(Vector3.new(20, 0, 0), Vector3.new(-1, 0, 0), 0.5)
			expect(reflected.X).to.be.near(-10, 0.001)
		end)
	end)
end
