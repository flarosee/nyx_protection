--[[
	Prop Spam/Crash Protection
]]

local SPAM_DETECTION = CreateConVar("nyx_spam_protection", 0, FCVAR_NONE, "Enables/Disables prop spam protection")
local MAX_SPAWNS = CreateConVar("nyx_spam_protection_max_spawns", 3, FCVAR_NONE, "Amount of props before prop protection checks", 1, 10)
local CONSECUTIVE_SPAWN_TIME = CreateConVar("nyx_spam_protection_consecutive_spawns", 3, FCVAR_NONE, "Time for consecutive prop spawns for checking spam", 1, 10)

local PROP_OWNERS = {}

local dangerousProps = {
	["models/props_phx/construct/metal_wire_angle360x1.mdl"] = true,
	["models/props_phx/construct/metal_wire_angle180x1.mdl"] = true,
	["models/props_phx/construct/metal_wire_angle90x1.mdl"] = true,
	["models/props_phx/construct/metal_wire_angle360x2.mdl"] = true,
	["models/props_phx/construct/metal_wire_angle180x2.mdl"] = true,
	["models/props_phx/construct/metal_wire_angle90x2.mdl"] = true,
	["models/boreas/exterior/trees27.mdl"] = true,
	["models/props_phx/misc/potato_launcher.mdl"] = true,
	["models/props_phx/construct/windows/window_curve360x1.mdl"] = true,
	["models/props_phx/construct/windows/window_curve180x1.mdl"] = true,
	["models/props_phx/construct/windows/window_curve360x2.mdl"] = true,
	["models/props_phx/construct/windows/window_curve180x2.mdl"] = true,
	["models/props_phx/construct/metal_dome360.mdl"] = true,
	["models/props_c17/playgroundslide01.mdl"] = true
}

local function findPropsAround(pos, dist, model)
	local foundEnts = ents.FindByClass("prop_physics")
	local filteredEnts = {}

	local sqrDistance = dist ^ 2

	local lower = model:lower()

	for _, v in ipairs(foundEnts) do
		if lower and v:GetModel():lower() ~= lower then
			continue
		end

		if pos:DistToSqr(v:GetPos()) > sqrDistance then
			continue
		end

		table.insert(filteredEnts, v)
	end

	return filteredEnts
end

local playerSpam = {}

hook.Add("PlayerDisconnected", "playerDisconnected", function(ply)
	if ply:IsBot() then return end

	playerSpam[ply:SteamID()] = nil
end)

hook.Add("PlayerSpawnedProp", "playerSpawnedProp", function(ply, model, ent)
	if not ply.USED_GM_SPAWN then return end
	--if not dangerousProps[model] then return end

	ply.USED_GM_SPAWN = nil

	--ent.m_owner = ply

	if not SPAM_DETECTION:GetBool() then
		return
	end

	local steamID = ply:SteamID()
	local realTime = RealTime()
	local maxSpawns = MAX_SPAWNS:GetInt() --dangerousProps[model] and 3 or 10

	if not playerSpam[steamID] then
		playerSpam[steamID] = {
			m_consecutiveTimer = realTime + CONSECUTIVE_SPAWN_TIME:GetFloat(),
			m_consecutiveSpawns = 0,
			m_lastSpawnedModel = model
		}
	end

	local spawns = playerSpam[steamID].m_consecutiveSpawns
	if realTime > playerSpam[steamID].m_consecutiveTimer then
		spawns = 0
	end

	if playerSpam[steamID].m_lastSpawnedModel == model then
		playerSpam[steamID].m_consecutiveTimer = realTime + 1.0
		spawns = spawns + 1
	end

	if spawns > maxSpawns then
		local mins, maxs = ent:GetCollisionBounds()
		local dist = math.max(math.abs(mins.x), math.abs(mins.y), math.abs(mins.z), maxs.x, maxs.y, maxs.z) * 2

		local foundEnts = findPropsAround(ent:GetPos(), dist, model)
		if #foundEnts > 2 then
			for _, entity in ipairs(foundEnts) do
				if not IsValid(entity) or ent:IsWorld() then
					continue
				end

				entity:SetCollisionGroup(COLLISION_GROUP_WORLD)

				local physObj = entity:GetPhysicsObject()
				if not physObj or not IsValid(physObj) then
					continue
				end

				physObj:Sleep()
				physObj:EnableMotion(false)

				if ent:GetClass() ~= "prop_ragdoll" then
					continue
				end

				for boneindex = 1, entity:GetPhysicsObjectCount() do
					local boneobject = entity:GetPhysicsObjectNum(boneindex)
					if not boneobject then
						continue
					end

					boneobject:Sleep()
				end
			end
		end
	end

	playerSpam[steamID].m_consecutiveSpawns = spawns
	playerSpam[steamID].m_lastSpawnedModel = model
end)

--[[
	Prevent gm_spawn madness
	(Overrides both the console command and _G.CCSpawn)
]]

function CCSpawn( ply, command, arguments )
	if not IsValid(ply) then return end

	if arguments[1] == nil then return end
	if arguments[1]:find("%.[/\\]") then return end

	-- Clean up the path from attempted blacklist bypasses
	arguments[1] = arguments[1]:gsub("\\\\+", "/")
	arguments[1] = arguments[1]:gsub("//+", "/")
	arguments[1] = arguments[1]:gsub("\\/+", "/")
	arguments[1] = arguments[1]:gsub("/\\+", "/")

	if not gamemode.Call("PlayerSpawnObject", ply, arguments[1], arguments[2]) then return end
	if not util.IsValidModel(arguments[1]) then return end

	ply.USED_GM_SPAWN = true

	local iSkin = tonumber( arguments[2] ) or 0
	local strBody = arguments[3] or nil

	if util.IsValidProp(arguments[1]) then
		GMODSpawnProp(ply, arguments[1], iSkin, strBody)
		return
	end

	if util.IsValidRagdoll( arguments[1] ) then
		GMODSpawnRagdoll(ply, arguments[1], iSkin, strBody)
		return
	end

	-- Not a ragdoll or prop.. must be an "effect" - spawn it as one
	GMODSpawnEffect( ply, arguments[ 1 ], iSkin, strBody )
end

concommand.Add("gm_spawn", CCSpawn, nil, "Spawns props/ragdolls")