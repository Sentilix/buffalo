--[[
-- Author      : Mimma
-- Create Date : 5/8/2022 7:34:58 PM
--]]



--	Misc. constants:
local BUFFALO_BUFFBUTTON_SIZE							= 32;
local BUFFALO_CURRENT_VERSION							= 0;
local BUFFALO_NAME										= "Buffalo"
local BUFFALO_MESSAGE_PREFIX							= "BuffaloV1"

--	Design/UI constants
local BUFFALO_CHAT_END									= "|r"
local BUFFALO_COLOUR_BEGINMARK							= "|c80"
local BUFFALO_COLOUR_CHAT								= BUFFALO_COLOUR_BEGINMARK.."C02020"
local BUFFALO_COLOUR_INTRO								= BUFFALO_COLOUR_BEGINMARK.."F82050"
local BUFFALO_ICON_OTHER_PASSIVE						= "Interface\\Icons\\INV_Misc_Gear_01";
local BUFFALO_ICON_DRUID_PASSIVE						= "Interface\\Icons\\INV_Misc_Monsterclaw_04";
local BUFFALO_ICON_MAGE_PASSIVE							= "Interface\\Icons\\INV_Jewelry_Talisman_04";	-- TODO: Find Mage icon!
local BUFFALO_ICON_PRIEST_PASSIVE						= "Interface\\Icons\\INV_Staff_30";				-- TODO: Can we maybe find a blank icon instead?

--	Internal variables
local BUFFALO_BuffBtn_Passive							= "";
local BUFFALO_BuffBtn_Active							= "";
local BUFFALO_BuffBtn_Combat							= "Interface\\Icons\\Ability_dualwield";
local BUFFALO_BuffBtn_Dead								= "Interface\\Icons\\Ability_rogue_feigndeath";
local IsBuffer											= false;
local BUFFALO_ScanFrequency								= 3.0;	-- Scan 5 timers/second? TODO: Make configurable!

--	List of classes and their spells.
--	{ classname, { priority, singleSpellID, singleIconName, groupSpellID, groupIconName }}
local Buffalo_ClassInfo = { }
--	TODO: DEFINE ....
local Buffalo_ClassInfo_Classic = { 
	"Priest", {  
		{ 1, 10938, "spell_holy_wordfortitude", 21564, "spell_holy_prayeroffortitude" },		-- Fortitude (rank 6 / rank 2)
		{ 2, 27841, "spell_holy_divinespirit",  27681, "spell_holy_prayerofspirit" }			-- Spirit (rank 4 / rank 1)
	}
};


-- Configuration:
--	Cached configation options:
local BUFFALO_OPTION_BuffButtonPosX						= "BuffButton.X";
local BUFFALO_OPTION_BuffButtonPosY						= "BuffButton.Y";
local BUFFALO_OPTION_BuffButtonVisible					= "BuffButton.Visible";

--	{realmname}{playername}{parameter}
Buffalo_Options = { }






--[[
	Echo functions
--]]

--	Echo a message for the local user only.
local function echo(msg)
	if msg then
		DEFAULT_CHAT_FRAME:AddMessage(BUFFALO_COLOUR_CHAT .. msg .. BUFFALO_CHAT_END)
	end
end

--	Echo in raid chat (if in raid) or party chat (if not)
local function partyEcho(msg)
	if IsInRaid() then
		SendChatMessage(msg, RAID_CHANNEL)
	elseif Buffalo_IsInParty() then
		SendChatMessage(msg, PARTY_CHANNEL)
	end
end

--	Echo a message for the local user only, including Buffalo "logo"
function Buffalo_Echo(msg)
	echo("-["..BUFFALO_COLOUR_INTRO.."BUFFALO"..BUFFALO_COLOUR_CHAT.."]- "..msg);
end




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

function Buffalo_CalculateVersion(versionString)
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
	end
	
	return version;
end

function Buffalo_IsInParty()
	if not IsInRaid() then
		return ( GetNumGroupMembers() > 0 );
	end
	return false
end




--[[
	Configuration functions
--]]
function Buffalo_GetOption(parameter, defaultValue)
	local realmname = GetRealmName();
	local playername = UnitName("player");

	-- Character level
	if Buffalo_Options[realmname] then
		if Buffalo_Options[realmname][playername] then
			if Buffalo_Options[realmname][playername][parameter] then
				local value = Buffalo_Options[realmname][playername][parameter];
				if (type(value) == "table") or not(value == "") then
					return value;
				end
			end		
		end
	end
	
	return defaultValue;
end

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
	Buffalo_SetOption(BUFFALO_OPTION_BuffButtonPosX, Buffalo_GetOption(BUFFALO_OPTION_BuffButtonPosX, x))
	Buffalo_SetOption(BUFFALO_OPTION_BuffButtonPosY, Buffalo_GetOption(BUFFALO_OPTION_BuffButtonPosY, y))

	local buttonVisibleDefault = "0";
	if IsBuffer then buttonVisibleDefault = "1"; end;
	Buffalo_GetOption(BUFFALO_OPTION_BuffButtonVisible, buttonVisibleDefault);

	if Buffalo_GetOption(BUFFALO_OPTION_BuffButtonVisible, buttonVisibleDefault) == "1" then
		BuffButton:Show();
	else
		BuffButton:Hide()
	end
end



--[[
	Initialization
--]]
function Buffalo_InitClassSpecificStuff()
	local _, classname = UnitClass("player");

	BUFFALO_BuffBtn_Passive = BUFFALO_ICON_OTHER_PASSIVE;
	if classname == "DRUID" then
		IsDruid = true;
		IsBuffer = true;
		BUFFALO_BuffBtn_Passive = BUFFALO_ICON_DRUID_PASSIVE;
	elseif classname == "MAGE" then
		IsMage = true;
		IsBuffer = true;
		BUFFALO_BuffBtn_Passive = BUFFALO_ICON_MAGE_PASSIVE;
	elseif classname == "PRIEST" then
		IsPriest = true;
		IsBuffer = true;
		BUFFALO_BuffBtn_Passive = BUFFALO_ICON_PRIEST_PASSIVE;
	end;

	--	Expansion-specific settings.
	--	TODO: We currently only support Classic!
	local expansionLevel = 1 * GetAddOnMetadata(BUFFALO_NAME, "X-Expansion-Level");
	if expansionLevel == 1 then
		Buffalo_ClassInfo = Buffalo_ClassInfo_Classic;
	else
		Buffalo_ClassInfo = Buffalo_ClassInfo_Classic;
		IsBuffer = false;	-- Effectively disables the addon!
	end;
end;



--[[
	Raid scanner
--]]
local function Buffalo_ScanRaid()
	Buffalo_Echo("Scanning raid ...");

	local cnt = GetNumGroupMembers();
	local unitid, name;
	local grouptype = "party";
	if IsInRaid() then grouptype = "raid"; end;


	--	TODO: Any way we can make this work with spellIDs instead?
	--	Possibly by translating during initalization:
	--	local spellname, _ = GetSpellInfo(spellID);

	local buffs = {
			["Power Word: Fortitude"] = 1,	["Prayer of Fortitude"] = 1,
			["Divine Spirit"] = 2,			["Prayer of Spirit"] = 2,
			["Shadow Protection"] = 4,		["Prayer of Shadow Protection"] = 4,
	}

	for n=1, cnt, 1 do
		unitid = grouptype .. n;

--	UnitBuff API:
--	local name, _, _, School, duration, expirationTime, unitCaster = UnitBuff(unitid, b, "RAID|CANCELABLE");
	
		local binValue = 0;
		for b = 1, 16, 1 do
			local name = UnitBuff(unitid, b, "RAID|CANCELABLE");
			if not name then break; end;

			if buffs[name] then
				binValue = binValue + buffs[name];
			end;
		end

		echo(string.format("%d -- %s, buffs=%d", n, UnitName(unitid), binValue));

	end;
end;



--[[
	WoW object handling
--]]
local function Buffalo_GetClassInfo(classname)
	classname = Buffalo_UCFirst(classname);

	for key, val in next, Buffalo_ClassInfo do 
		if val[1] == classname then
			return val;
		end
	end
	return nil;
end

local function Buffalo_UnitClass(unitid)
	local _, classname = UnitClass(unitid);
	return classname;
end;



--[[
	UI Control
--]]
function Buffalo_RepositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Buffalo_SetOption(BUFFALO_OPTION_BuffButtonPosX, x);
	Buffalo_SetOption(BUFFALO_OPTION_BuffButtonPosY, y);
	BuffButton:SetSize(BUFFALO_BUFFBUTTON_SIZE, BUFFALO_BUFFBUTTON_SIZE);

	if IsBuffer then
		BuffButton:Show();
	else
		BuffButton:Hide();
		echo("HIDING!");
	end;
end

local function Buffalo_HideBuffButton()
	Buffalo_SetButtonTexture(BUFFALO_BuffBtn_Passive);
	BuffButton:SetAttribute("type", nil);
	BuffButton:SetAttribute("unit", nil);
end;

local BuffButtonLastTexture = "";
function Buffalo_SetButtonTexture(textureName, isEnabled)
	local alphaValue = 0.5;
	if isEnabled then
		alphaValue = 1.0;
	end;

	if BuffButtonLastTexture ~= textureName then
		BuffButtonLastTexture = textureName;
		BuffButton:SetAlpha(alphaValue);
		BuffButton:SetNormalTexture(textureName);		
	end;
end;



--[[
	Timers
--]]
local TimerTick = 0
local NextScanTime = 0;

function Buffalo_GetTimerTick()
	return TimerTick;
end



--[[
	Event Handlers
--]]
function Buffalo_OnEvent(self, event, ...)
	local timerTick = Buffalo_GetTimerTick();

	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == BUFFALO_NAME then
		    Buffalo_InitializeConfigSettings();
		end

	elseif (event == "CHAT_MSG_ADDON") then
		--Buffalo_OnChatMsgAddon(event, ...)

	else
		if(debug) then 
			echo("**DEBUG**: Other event: "..event);

			local arg1, arg2, arg3, arg4 = ...;
			if arg1 then
				echo(string.format("**DEBUG**: arg1=%s", arg1));
			end;
			if arg2 then				
				echo(string.format("**DEBUG**: arg2=%s", arg2));
			end;
			if arg3 then				
				echo(string.format("**DEBUG**: arg3=%s", arg3));
			end;
			if arg4 then				
				echo(string.format("**DEBUG**: arg4=%s", arg4));
			end;
		end;
	end
end

function Buffalo_OnLoad()
	BUFFALO_CURRENT_VERSION = Buffalo_CalculateVersion(GetAddOnMetadata(BUFFALO_NAME, "Version") );

	Buffalo_Echo(string.format("Version %s by %s", GetAddOnMetadata(BUFFALO_NAME, "Version"), GetAddOnMetadata(BUFFALO_NAME, "Author")));
	Buffalo_Echo(string.format("Type %s/buffalo%s to configure the addon.", BUFFALO_COLOUR_INTRO, BUFFALO_COLOUR_CHAT));

    BuffaloEventFrame:RegisterEvent("ADDON_LOADED");

	C_ChatInfo.RegisterAddonMessagePrefix(BUFFALO_MESSAGE_PREFIX);

	Buffalo_InitClassSpecificStuff();
	Buffalo_RepositionateButton(BuffButton);
	Buffalo_HideBuffButton();
end

function Buffalo_OnTimer(elapsed)
	TimerTick = TimerTick + elapsed

	if TimerTick > (NextScanTime + BUFFALO_ScanFrequency) then
		Buffalo_ScanRaid();
		NextScanTime = TimerTick;
	end;
end

function Buffalo_OnBuffClick(self)
	--	TODO: Do stuff!
	Buffalo_Echo("PING!");
end;


