--[[
	Player Spawn Protection

	its simplicity was intentional
]]

local ENABLED = CreateConVar("nyx_spawn_protection", 0, FCVAR_NONE, "Enables/Disables player spawn protection")
local DURATION = CreateConVar("nyx_spawn_protection_duration", 5, FCVAR_NONE, "Duration the player will be in spawn protection (in seconds)", 1, 10)

gameevent.Listen("player_spawn")
gameevent.Listen("player_disconnect")

local SPAWN_PROTECTED = {}

hook.Add("player_spawn", "spawnProtection", function(data)
	local ply = Player(data.userid)
	SPAWN_PROTECTED[ply:SteamID()] = CurTime() + DURATION:GetInt()
end)

hook.Add("EntityTakeDamage", "spawnProtection", function(ply, pDamage)
	if not ENABLED:GetBool() then
		return
	end

	if not ply:IsPlayer() then
		return
	end

	local steamID = ply:SteamID()
	if SPAWN_PROTECTED[steamID] and CurTime() < SPAWN_PROTECTED[steamID] then
		pDamage:ScaleDamage(0)
		pDamage:SetDamage(0)

		return true
	end

	local attacker = pDamage:GetAttacker()
	if not attacker:IsPlayer() then
		return
	end

	local attackerSteamID = attacker:SteamID()
	if SPAWN_PROTECTED[attackerSteamID] and CurTime() < SPAWN_PROTECTED[attackerSteamID] then
		SPAWN_PROTECTED[attackerSteamID] = nil

		pDamage:ScaleDamage(0)
		pDamage:SetDamage(0)

		return true
	end
end)

hook.Add("player_disconnect", "spawnProtection", function(data)
	SPAWN_PROTECTED[data.networkid] = nil
end)