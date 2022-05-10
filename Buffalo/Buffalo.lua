--[[
-- Author      : Mimma
-- Create Date : 5/8/2022 7:34:58 PM
--]]

--	TODO:
--	* Nothing happens when you click the Buff button ... is it important? :-D
--	* Rewrite buff structures for other classes than Priests
--	* Define the UI (muhahaa!)
--	* Handle single buffs (they are ignore for the time being)


--	Misc. constants:
local BUFFALO_BUFFBUTTON_SIZE							= 32;
local BUFFALO_CURRENT_VERSION							= 0;
local BUFFALO_NAME										= "Buffalo"
local BUFFALO_MESSAGE_PREFIX							= "BuffaloV1"

--	Raid buffs:
--	Druid
local BUFF_Druid_Wild									= 1;		--	0x0001
local BUFF_Druid_Thorns									= 2;		--	0x0002
--	Hunter: (TODO: aspects?)
--	Mage:
local BUFF_Mage_Intellect								= 1;		--	0x0001
local BUFF_Mage_AmplifyMagic							= 2;		--	0x0002
local BUFF_Mage_DampenMagic								= 4;		--	0x0004
local BUFF_Mage_MageArmor								= 256;		--	0x0100
local BUFF_Mage_IceArmor								= 512;		--	0x0200
--	Paladin:
local BUFF_Paladin_BlessingOfLight						= 1;		--	0x0001;
local BUFF_Paladin_BlessingOfWisdom						= 2;		--	0x0002;
local BUFF_Paladin_BlessingOfSalvation					= 4;		--	0x0004;
local BUFF_Paladin_BlessingOfMight						= 8;		--	0x0008;
--	todo: missing a few blessings!
--	todo: missing auras!
local BUFF_Paladin_RighteousFury						= 256;		--	0x0100;

--	Priest:
local BUFF_Priest_Fortitude								= 1;		--	0x0001
local BUFF_Priest_Spirit								= 2;		--	0x0002
local BUFF_Priest_Shadow								= 4;		--	0x0004
local BUFF_Priest_InnerFire								= 256;		--	0x0100
--	Rogue: (no class buffs)
--	Shaman: (TODO: Totems, weapon imbuements?)
--	Warlock:
local BUFF_Warlock_UnderwaterBreath						= 1;		--	0x0001
--	Warrior: (no class buffs)

--	List of groups I am watching (or if pala: list of classes)
local BUFF_AssignedGroups = { }
--	While testing (no UI) we set group 1+2+3 as my group:
BUFF_AssignedGroups[1] = true;
BUFF_AssignedGroups[2] = true;
BUFF_AssignedGroups[3] = true;

BUFF_GroupBuffThreshold									= 2;		-- If at least N persons are missing same buff, group buffs will be used.


--	[classname][buffname]=<bitmask value>
local BUFF_MATRIX = { };

local BUFF_MATRIX_CLASSIC = {
	["DRUID"] = {
		["Mark of the Wild"]							= BUFF_Druid_Wild,
		["Gift of the Wild"]							= BUFF_Druid_Wild,
		["Thorns"]										= BUFF_Druid_Thorns,
	},
	["MAGE"] = {
		["Arcane Intellect"]							= BUFF_Mage_Intellect,
		["Arcane Brilliance"]							= BUFF_Mage_Intellect,
		["Amplify Magic"]								= BUFF_Mage_AmplifyMagic,
		["Dampen Magic"]								= BUFF_Mage_DampenMagic,
		["Mage Armor"]									= BUFF_Mage_MageArmor,
		["Ice Armor"]									= BUFF_Mage_IceArmor,
	},
	["PALADIN"] = {
		["Blessing of Light"]							= BUFF_Paladin_BlessingOfLight,
		["Greater Blessing of Light"]					= BUFF_Paladin_BlessingOfLight,
		["Blessing of Wisdom"]							= BUFF_Paladin_BlessingOfWisdom,
		["Greater Blessing of Wisdom"]					= BUFF_Paladin_BlessingOfWisdom,
		["Blessing of Salvation"]						= BUFF_Paladin_BlessingOfSalvation,	-- Todo: is there greater blessing of salvation?
		["Blessing of Might"]							= BUFF_Paladin_BlessingOfMight,
		["Greater Blessing of Might"]					= BUFF_Paladin_BlessingOfMight,
		["Righteous Fury"]								= BUFF_Paladin_RighteousFury,
	},
	["PRIEST"] =  {
		["Power Word: Fortitude"]			= { ["MASK"] = BUFF_Priest_Fortitude, ["ICONID"] = 135987, ["PRIORITY"] = 50, ["GROUP"] = false, ["PARENT"] = "Prayer of Fortitude" },
		["Prayer of Fortitude"]				= { ["MASK"] = BUFF_Priest_Fortitude, ["ICONID"] = 135941, ["PRIORITY"] = 100, ["GROUP"] = true },
		["Divine Spirit"]					= { ["MASK"] = BUFF_Priest_Spirit, ["ICONID"] = 135898, ["PRIORITY"] = 40, ["GROUP"] = false, ["PARENT"] = "Prayer of Spirit" },
		["Prayer of Spirit"]				= { ["MASK"] = BUFF_Priest_Spirit, ["ICONID"] = 135946, ["PRIORITY"] = 90, ["GROUP"] = true },
		["Shadow Protection"]				= { ["MASK"] = BUFF_Priest_Shadow, ["ICONID"] = 136121, ["PRIORITY"] = 30, ["GROUP"] = false, ["PARENT"] = "Prayer of Shadow Protection" },
		["Prayer of Shadow Protection"]		= { ["MASK"] = BUFF_Priest_Shadow, ["ICONID"] = 135945, ["PRIORITY"] = 80, ["GROUP"] = true },
		["Inner Fire"]						= { ["MASK"] = BUFF_Priest_InnerFire, ["ICONID"] = 135926, ["PRIORITY"] = 10, ["GROUP"] = false },
	},
	["WARLOCK"] = {
		["Underwater Breathing"]						= BUFF_Warlock_UnderwaterBreath,
	}
};


--	UnitBuff API:
--		local name, iconID, count, school, duration, expirationTime, unitCaster = UnitBuff(unitid, b, "RAID|CANCELABLE");
--	Expiration time is time since last server restart. I am not sure how to get CurrentTime but should be doable.



--	Design/UI constants
local BUFFALO_CHAT_END									= "|r"
local BUFFALO_COLOUR_BEGINMARK							= "|c80"
local BUFFALO_COLOUR_CHAT								= BUFFALO_COLOUR_BEGINMARK.."C02020"
local BUFFALO_COLOUR_INTRO								= BUFFALO_COLOUR_BEGINMARK.."F82050"
local ICON_PASSIVE										= 136112;
local BUFFALO_ICON_OTHER_PASSIVE						= "Interface\\Icons\\INV_Misc_Gear_01";
local BUFFALO_ICON_DRUID_PASSIVE						= "Interface\\Icons\\INV_Misc_Monsterclaw_04";
local BUFFALO_ICON_MAGE_PASSIVE							= "Interface\\Icons\\INV_Jewelry_Talisman_04";	-- TODO: Find Mage icon!
local BUFFALO_ICON_PRIEST_PASSIVE						= "Interface\\Icons\\INV_Staff_30";				-- TODO: Can we maybe find a blank icon instead?

--	Internal variables
local BUFFALO_BuffBtn_Combat							= "Interface\\Icons\\Ability_dualwield";
local BUFFALO_BuffBtn_Dead								= "Interface\\Icons\\Ability_rogue_feigndeath";
local IsBuffer											= false;
local BUFFALO_ScanFrequency								= 5.0;	-- Scan 5 timers/second? TODO: Make configurable!



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

	if classname == "DRUID" then
		IsDruid = true;
		IsBuffer = true;
	elseif classname == "MAGE" then
		IsMage = true;
		IsBuffer = true;
	elseif classname == "PRIEST" then
		IsPriest = true;
		IsBuffer = true;
	end;

	--	Expansion-specific settings.
	--	TODO: We currently only support Classic!
	local expansionLevel = 1 * GetAddOnMetadata(BUFFALO_NAME, "X-Expansion-Level");
	if expansionLevel == 1 then
		BUFF_MATRIX = BUFF_MATRIX_CLASSIC;
	else
		BUFF_MATRIX = { }
		IsBuffer = false;	-- Effectively disables the addon!
	end;
end;



--[[
	Raid scanner
--]]
local function Buffalo_ScanRaid()
	Buffalo_Echo("Scanning raid ...");

	local startNum = 1;
	local endNum = GetNumGroupMembers();
	local grouptype = "party";
	if IsInRaid() then
		grouptype = "raid";
	else
		startNum = 0;
		endNum = endNum - 1;
	end;


	--	Generate a raid roster with meta info per character:
	local roster = { };
	for raidIndex = 1, 40, 1 do
		local name, rank, subgroup, level, class, filename, zone, online, dead, role, isML = GetRaidRosterInfo(raidIndex);
		if not name then break; end;

		local isOnline = 0 and online and 1;
		local isDead   = 0 and dead   and 1;
		local unitid = "raid"..raidIndex;	-- TODO: ehm .. and in a party?

		roster[unitid] = { ["Group"]=subgroup, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0 };
	end;



	local unitid, binValue;	
	local buffMatrix = Buffalo_GetBuffMatrixForClass();

	for n = startNum, endNum, 1 do
		buffMask = 0;
		unitid = "player"
		if n > 0 then unitid = grouptype .. n; end;

		--	This skips scanning for dead, offliners and people not in my group:
		local scanPlayerBuffs = true;
		local rosterInfo = roster[unitid];
		if rosterInfo then
			if not BUFF_AssignedGroups[rosterInfo["Group"]] then
				scanPlayerBuffs = false;
			elseif not rosterInfo["IsOnline"] then
				scanPlayerBuffs = false;
			elseif rosterInfo["IsDead"] then
				scanPlayerBuffs = false;
			end;
		end;
			
		if scanPlayerBuffs then
			for buffIndex = 1, 40, 1 do
				local buffName, iconID = UnitBuff(unitid, buffIndex, "CANCELABLE");

				if not buffName then break; end;

				local buffInfo = buffMatrix[buffName];
				if buffInfo then
					buffMask = buffMask + buffInfo["MASK"];

					echo(string.format("*** ICON, Buff=%s, Icon=%d", buffName, iconID));
				end;
			end

			roster[unitid]["BuffMask"] = buffMask;
			--echo(string.format("Unitid=%s, Name=%s, buffMask=%d, Group=%d", unitid, UnitName(unitid), buffMask, rosterInfo["Group"]));
		end;

		--	So for each player we now have the following key information:
		--	* UnitID
		--	* Group (1-8)
		--	* BuffMask (based on MY current class)
	end;

	--	Now we just need to prioritise what buff to apply. So:
	--	Run over Groups -> Buffs -> UnitIDs
	--	Result: { unitid, buffname, iconid, priority }
	local unitid;
	local MissingBuffs = { };
	local missingBuffIndex = 0;
	for groupIndex = 1, 8, 1 do
		if BUFF_AssignedGroups[groupIndex] then
			--	We have found an assigned group now. Search through the buffs, and count each buff per group and unit combo:
			for buffName, buffInfo in next, buffMatrix do
				local buffMissingCounter = 0;		-- No buffs detected so far.
				local MissingBuffsInGroup = { };	-- No units missing buffs in group (yet).

				for raidIndex = 1, 40, 1 do
					unitid = "raid"..raidIndex;
					local rosterInfo = roster[unitid];
					if rosterInfo and rosterInfo["Group"] == groupIndex and rosterInfo["IsOnline"] and not rosterInfo["IsDead"] then
						--	There's a living person in this group!
						--	Check if he needs the specific buff.
						--	Note: If buffMask >= 256 then it is a local buff only for me ("player").
						local buffMask = rosterInfo["BuffMask"];
						if (bit.band(buffMask, buffInfo["MASK"]) == 0) then
							if not buffInfo["GROUP"] and buffInfo["MASK"] < 256 then		-- Skip self buffs for now!
								buffMissingCounter = buffMissingCounter + 1;
								MissingBuffsInGroup[buffMissingCounter] = { unitid, buffName, buffInfo["ICONID"], buffInfo["PRIORITY"] };
								--echo(string.format("Adding: unit=%s, group=%d, buff=%s", UnitName(unitid), groupIndex, buffName));
							end;
						end;
					end;
				end;

				--	If this is a group buff, and enough people are missing it, use the big one instead!
				if buffInfo["PARENT"] and buffMissingCounter >= BUFF_GroupBuffThreshold then
					local parentBuffInfo = buffMatrix[buffInfo["PARENT"]];
					missingBuffIndex = missingBuffIndex + 1;
					MissingBuffs[missingBuffIndex] = { unitid, buffInfo["PARENT"], parentBuffInfo["ICONID"], parentBuffInfo["PRIORITY"] };
				else
					-- Use single target buffing:
					for missingIndex = 1, buffMissingCounter, 1 do
						missingBuffIndex = missingBuffIndex + 1;
						MissingBuffs[missingBuffIndex] = MissingBuffsInGroup[missingIndex];
					end;
				end;
			end;
		end;
	end;

	if missingBuffIndex > 0 then
		--	Now sort by Priority (descending order):
		table.sort(MissingBuffs, Buffalo_ComparePriority);

		--	Final check:
		--	List all buffs I need to apply! They are not currently ordered by anything.
		if debug then
			for buffIndex = 1, missingBuffIndex, 1 do
				local buff = MissingBuffs[buffIndex];
				local playername = UnitName(buff[1]) or UnitName("player");
				echo(string.format("Missing: UnitID=%s, Player=%s, Buff=%s, Prio=%d", buff[1], playername, buff[2], buff[3]));
			end;
		end;

		--	Now pick first buff from list and set icon:
		local missingBuff = MissingBuffs[1];
		Buffalo_SetButtonTexture(missingBuff[3], true);
	else
		Buffalo_SetButtonTexture(ICON_PASSIVE);
	end;
end;

function Buffalo_ComparePriority(a, b)
	return a[4] > b[4];
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

--[[
	Return classname for current player in uppercase.
	TODO: How will this work on e.g. a French client?
--]]
function Buffalo_UnitClass(unitid)
	local _, classname = UnitClass(unitid);
	return classname;
end;

function Buffalo_GetBuffMatrixForClass(classname)
	if not classname then
		classname = Buffalo_UnitClass("player");
	end;
	
	return BUFF_MATRIX[classname];
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
	end;
end

local function Buffalo_HideBuffButton()
	Buffalo_SetButtonTexture(ICON_PASSIVE);
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


