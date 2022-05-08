--[[
-- Author      : Mimma
-- Create Date : 5/8/2022 7:34:58 PM
--]]



--	Misc. constants:
BUFFALO_REZBUTTON_SIZE									= 32;

--	List of classes and their spells.
--	{ classname, { priority, singleSpellID, singleIconName, groupSpellID, groupIconName }}
local Buffalo_Classes = { 
	"Priest", {  
		{ 1, 10938, "spell_holy_wordfortitude", 21564, "spell_holy_prayeroffortitude" },		-- Fortitude (rank 6 / rank 2)
		{ 2, 27841, "spell_holy_divinespirit",  27681, "spell_holy_prayerofspirit" }			-- Spirit (rank 4 / rank 1)
	}
}


-- Configuration:
--	{realmname}{playername}{parameter}
Buffalo_Options = { }

--	Cached configation options:
local Buffalo_OPTION_BuffButtonPosX						= "BuffButton.X";
local Buffalo_OPTION_BuffButtonPosY						= "BuffButton.Y";
local Buffalo_OPTION_BuffButtonVisible					= "BuffButton.Visible";



--[[
	Misc. helper functions
--]]

--	Convert a msg so first letter is uppercase, and rest as lower case.
function Buffalo_UCFirst(playername)
	if not playername then
		return ""
	end	

	-- Handles utf8 characters in beginning.. Ugly, but works:
	local offset = 2;
	local firstletter = string.sub(playername, 1, 1);
	if(not string.find(firstletter, '[a-zA-Z]')) then
		firstletter = string.sub(playername, 1, 2);
		offset = 3;
	end;

	return string.upper(firstletter) .. string.lower(string.sub(playername, offset));
end



--[[
	Configuration functions
--]]
function Buffalo_SetOption(parameter, value)
	local realmname = GetRealmName();
	local playername = UnitName("player");

	-- Character level:
	if not Buffalo_Options[realmname] then
		Buffalo_Options[realmname] = { };
	end
		
	if not Buffalo_Options[realmname][playername] then
		Buffalo_Options[realmname][playername] = { };
	end
		
	Buffalo_Options[realmname][playername][parameter] = value;
end

function Buffalo_InitializeConfigSettings()
	if not Buffalo_Options then
		Buffalo_options = { };
	end

--	Buffalo_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, Thaliz_Target_Channel_Default))
--	Buffalo_SetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, Thaliz_Target_Whisper_Default))
--	Buffalo_SetOption(Thaliz_OPTION_ResurrectionWhisperMessage, Thaliz_GetOption(Thaliz_OPTION_ResurrectionWhisperMessage, Thaliz_Resurrection_Whisper_Message_Default))

	local x,y = BuffButton:GetPoint();
	Buffalo_SetOption(Buffalo_OPTION_BuffButtonPosX, Buffalo_GetOption(Buffalo_OPTION_BuffButtonPosX, x))
	Buffalo_SetOption(Buffalo_OPTION_BuffButtonPosY, Buffalo_GetOption(Buffalo_OPTION_BuffButtonPosY, y))

	if Buffalo_GetOption(Buffalo_OPTION_BuffButtonVisible) == "1" then
		BuffButton:Show();
	else
		BuffButton:Hide()
	end
end



--[[
	WoW object handling
--]]
function Buffalo_GetClassinfo(classname)
	classname = Buffalo_UCFirst(classname);

	for key, val in next, Buffalo_ClassInfo do 
		if val[1] == classname then
			return val;
		end
	end
	return nil;
end


--[[
	Event Handlers
--]]
function Buffalo_OnBuffClick(self)
	--	TODO:
end;




--[[
	UI Control
--]]
function Buffalo_RepositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Buffalo_SetOption(Buffalo_OPTION_BuffButtonPosX, x);
	Buffalo_SetOption(Buffalo_OPTION_BuffButtonPosY, y);

	BuffButton:SetSize(BUFFALO_REZBUTTON_SIZE, BUFFALO_REZBUTTON_SIZE);

	local classinfo = Buffalo_GetClassinfo(Thaliz_UnitClass("player"));

	local spellname = classinfo[4];
	if spellname then
		RezButton:Show();
	else
		RezButton:Hide();
	end;
end
