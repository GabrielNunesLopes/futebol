--!strict

return {
	FixedStep = 1 / 60,
	MaxCatchUpSteps = 5,

	Player = {
		MaxSpeed = 34,
		Acceleration = 115,
		Deceleration = 145,
		ReverseAcceleration = 92,
		Radius = 2.35,
	},

	Ball = {
		MaxSpeed = 95,
		Friction = 3.2,
		Restitution = 0.86,
		Radius = 1.35,
		BodyPushFactor = 0.9,
	},

	Kick = {
		Power = 58,
		Range = 5.25,
		Cooldown = 0.18,
		AimBlend = 0.35,
		MomentumContribution = 0.42,
		ExistingBallVelocityRetention = 0.16,
	},
}
