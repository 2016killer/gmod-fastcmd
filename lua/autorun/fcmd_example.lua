if CLIENT then
	local function lasertrail(startp, endp, num, mat)
		num = num or 100
		local len = (endp - startp):Length() / num
		local vel = (endp - startp):GetNormalized()
		local step = (endp - startp) / num
		local zerovec = Vector()

		local emitter = ParticleEmitter(LocalPlayer():GetPos())
		for i = 1, num do
			local part = emitter:Add('trails/electric', startp + step * i)
			if part then
				part:SetDieTime(math.max(i * 0.005, 0.1)) 

				part:SetStartSize(20) 
				part:SetEndSize(0) 

				part:SetStartLength(len)
				part:SetEndLength(len)

				part:SetGravity(zerovec) 
				part:SetVelocity(vel)		
			end
		end
		emitter:Finish()
	end

	local function laserreflection(trace, depth, mat)
		lasertrail(trace.StartPos, trace.HitPos, nil, 'trails/electric')
		if depth > 0 then
			depth = depth - 1
			timer.Simple(0.25, function()
				trace = util.QuickTrace(
					trace.HitPos,
					9999 * (trace.Normal - 2 * trace.HitNormal * trace.HitNormal:Dot(trace.Normal))
				)
				laserreflection(trace, depth, mat)
			end)
		end
	end

    local function snow(radius, center)
		local zerovec = Vector()

		local emitter = ParticleEmitter(LocalPlayer():GetPos())
		for i = 1, 300 do 
			local part = emitter:Add(
				'models/wireframe', 
				center + VectorRand() * radius * math.sqrt(math.random())
			) 
			if part then
				part:SetDieTime(3) 

				part:SetStartAlpha(255) 
				part:SetEndAlpha(0)

				part:SetStartSize(30) 
				part:SetEndSize(0) 

                part:SetStartLength(30)
				part:SetEndLength(0)

				part:SetGravity(zerovec) 
				part:SetVelocity(VectorRand() * 50)	
				
				part:SetAngleVelocity(AngleRand() * 0.1)
			end
		end
		emitter:Finish()
	end

	concommand.Add('fcmd_example1', function(ply, cmd, args) 
		laserreflection(ply:GetEyeTrace(), 10, 'trails/electric')
	end)

	local startpos
	concommand.Add('+fcmd_example2', function(ply, cmd, args) 
		startpos = ply:GetEyeTrace().HitPos
	end)

	concommand.Add('-fcmd_example2', function(ply, cmd, args)
		lasertrail(startpos, ply:GetEyeTrace().HitPos, nil, 'trails/plasma')
	end)


	concommand.Add('fcmd_example3', function(ply, cmd, args) 
		snow(1000, ply:GetEyeTrace().HitPos)
	end)

end

