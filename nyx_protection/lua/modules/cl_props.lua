--[[
	Visualization of prop tips
]]

print("loading")

local SCREEN_WIDTH = ScrW()
local SCREEN_HEIGHT = ScrH()

local SCREEN_CENTER_X = math.floor(SCREEN_WIDTH / 2)
local SCREEN_CENTER_Y = math.floor(SCREEN_HEIGHT / 2)

local color_black = Color(0, 0, 0)
local color_background = Color(0, 0, 0, 100)

local bEnabled = true
local font = "ChatFont"

hook.Add("PostDrawHUD", "propProtection", function()
	--if not bEnabled then
	--	return
	--end

	local LOCAL_PLAYER = LocalPlayer()
	if not IsValid(LOCAL_PLAYER) then
		return
	end

	local trData = LOCAL_PLAYER:GetEyeTrace()
	if not trData then
		return
	end

	local prop = trData.Entity
	if not IsValid(prop) then
		return
	end

	local text = "Owner: qweqwe" --.. (PropNames[ent:EntIndex()] or "N/A")
	surface.SetFont("BudgetLabel")

	local Width, Height = surface.GetTextSize(text)
	local boxWidth = Width + 25
	local boxHeight = Height

	local text2 = tostring(prop) --"'" .. string.sub(table.remove(string.Explode("/", prop:GetModel() or "?")), 1, -5) .. "' [" .. prop:EntIndex() .. "]"
	local w2,h2 = surface.GetTextSize(text2)

	boxWidth = math.max(Width, w2, 0) + 25
	boxHeight = boxHeight + h2

	surface.SetDrawColor(color_background)
	surface.DrawRect(SCREEN_WIDTH - (boxWidth - 4), (SCREEN_CENTER_Y - boxHeight ) - 16, boxWidth - 16, boxHeight)
	surface.SetDrawColor(255, 255, 255, 255)

	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(SCREEN_WIDTH - (boxWidth - 4) + 6, (SCREEN_CENTER_Y - boxHeight ) - 12)
	surface.DrawText(text)

	surface.SetTextPos(SCREEN_WIDTH - (boxWidth - 4) + 6, SCREEN_CENTER_Y - boxHeight)
	surface.DrawText(text2)
end)

hook.Add("OnScreenSizeChanged", "propProtection", function()
	SCREEN_WIDTH = ScrW()
	SCREEN_HEIGHT = ScrH()

	SCREEN_CENTER_X = math.floor(SCREEN_WIDTH / 2)
	SCREEN_CENTER_Y = math.floor(SCREEN_HEIGHT / 2)
end)