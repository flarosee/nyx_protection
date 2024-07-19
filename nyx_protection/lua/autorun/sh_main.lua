if SERVER then
	AddCSLuaFile()

	include("modules/sv_props.lua")
	include("modules/sv_spawn_protection.lua")

	AddCSLuaFile("modules/cl_props.lua")
end

if CLIENT then
	include("modules/cl_props.lua")
end