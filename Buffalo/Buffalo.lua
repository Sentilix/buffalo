--[[
-- Author      : Mimma
-- Create Date : 5/8/2022 7:34:58 PM
--]]

--	Misc. constants:
local BUFFALO_BUFFBUTTON_SIZE							= 32;
local BUFFALO_CURRENT_VERSION							= 0;
local BUFFALO_NAME										= "Buffalo"
local BUFFALO_MESSAGE_PREFIX							= "BuffaloV1"
local BUFFALO_UPDATE_MESSAGE_SHOWN						= false;

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
local BUFFALO_ScanFrequency								= 0.2;	-- Scan 5 timers/second? TODO: Make configurable!
local Buffalo_PlayerNameAndRealm						= "";
local Buffalo_InitializationComplete					= false;


--	[buffname]=<bitmask value>
local BUFF_MATRIX = { };
--	[classname<english>]=<bitmasl value>
local CLASS_MATRIX = { };




-- Configuration:
--	Loaded options:	{realmname}{playername}{parameter}
Buffalo_Options = { }

--	Configuration keys:
local BUFFALO_CONFIG_KEY_BuffButtonPosX					= "BuffButton.X";
local BUFFALO_CONFIG_KEY_BuffButtonPosY					= "BuffButton.Y";
local BUFFALO_CONFIG_KEY_BuffButtonVisible				= "BuffButton.Visible";

--	List of groups I am watching (or if pala: list of classes)
local BUFF_AssignedGroups = { 
	[1] = 3,
	[2] = 3,
	[3] = 3,
	[4] = 7,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

local BUFF_GroupBuffThreshold							= 4;		-- If at least N persons are missing same buff, group buffs will be used.



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
	Slash commands

	Main entry for Buffalo "slash" commands.
	This will send the request to one of the sub slash commands.
	Syntax: /buffalo [option, defaulting to "cfg"]
	Added in: 0.1.0
]]
SLASH_BUFFALO_BUFFALO1 = "/buffalo"
SlashCmdList["BUFFALO_BUFFALO"] = function(msg)
	local _, _, option = string.find(msg, "(%S*)")

	if not option or option == "" then
		option = "CFG";
	end;

	option = string.upper(option);
		
	if (option == "CFG" or option == "CONFIG") then
		SlashCmdList["BUFFALO_CONFIG"]();
	--elseif option == "DISABLE" then
	--	SlashCmdList["THALIZ_DISABLE"]();
	--elseif option == "ENABLE" then
	--	SlashCmdList["THALIZ_ENABLE"]();
	--elseif option == "HELP" then
	--	SlashCmdList["THALIZ_HELP"]();
	elseif option == "SHOW" then
		SlashCmdList["BUFFALO_SHOW"]();
	elseif option == "HIDE" then
		SlashCmdList["BUFFALO_HIDE"]();
	elseif option == "VERSION" then
		SlashCmdList["BUFFALO_VERSION"]();
	else
		Buffalo_Echo(string.format("Unknown command: %s", option));
	end
end

--[[
	Show the buff button
	Syntax: /buffaloshow
	Alternative: /buffalo show
	Added in: 0.1.0
]]
SLASH_BUFFALO_SHOW1 = "/buffaloshow"	
SlashCmdList["BUFFALO_SHOW"] = function(msg)
	BuffButton:Show();
	Buffalo_SetOption(BUFFALO_CONFIG_KEY_BuffButtonVisible, "1");
end

--[[
	Hide the resurrection button
	Syntax: /buffalohide
	Alternative: /buffalo hide
	Added in: 0.1.0
]]
SLASH_BUFFALO_HIDE1 = "/buffalohide"	
SlashCmdList["BUFFALO_HIDE"] = function(msg)
	BuffButton:Hide();
	Buffalo_SetOption(BUFFALO_CONFIG_KEY_BuffButtonVisible, "0");
end

--[[
	Request client version information
	Syntax: /buffaloversion
	Alternative: /buffalo version
	Added in: 0.1.0
]]
SLASH_BUFFALO_VERSION1 = "/buffaloversion"
SlashCmdList["BUFFALO_VERSION"] = function(msg)
	if IsInRaid() or Buffalo_IsInParty() then
		Buffalo_SendAddonMessage("TX_VERSION##");
	else
		Buffalo_Echo(string.format("%s is using Buffalo version %s", GetUnitName("player", true), GetAddOnMetadata(BUFFALO_NAME, "Version")));
	end
end



--[[
--
--	Internal Communication Functions
--
--]]
function Buffalo_SendAddonMessage(message)
	local memberCount = GetNumGroupMembers();
	if memberCount > 0 then
		local channel = nil;
		if IsInRaid() then
			channel = "RAID";
		elseif Buffalo_IsInParty() then
			channel = "PARTY";
		end;
		C_ChatInfo.SendAddonMessage(BUFFALO_MESSAGE_PREFIX, message, channel);
	end;
end


--[[
	Respond to a TX_VERSION command.
	Input:
		msg is the raw message
		sender is the name of the message sender.
	We should whisper this guy back with our current version number.
	We therefore generate a response back (RX) in raid with the syntax:
	Buffalo:<sender (which is actually the receiver!)>:<version number>
]]
function Buffalo_HandleTXVersion(message, sender)
	local response = GetAddOnMetadata(BUFFALO_NAME, "Version");
	Buffalo_SendAddonMessage("RX_VERSION#"..response.."#"..sender)
end

--[[
	A version response (RX) was received.
	The version information is displayed locally.
]]
function Buffalo_HandleRXVersion(message, sender)
	Buffalo_Echo(string.format("[%s] is using Buffalo version %s", sender, message))
end

function Buffalo_HandleTXVerCheck(message, sender)
	Buffalo_CheckIsNewVersion(message);
end

function Buffalo_OnChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;

	if prefix == BUFFALO_MESSAGE_PREFIX then
		Buffalo_HandleAddonMessage(msg, sender);
	end
end

function Buffalo_HandleAddonMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	

	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if recipient ~= "" then
		-- Note: recipient comes with realmname. We need to compare
		-- with realmname too, even GetUnitName() does not return one:
		recipient = Buffalo_GetPlayerAndRealmFromName(recipient);

		if recipient ~= Buffalo_PlayerNameAndRealm then
			return
		end
	end

	if cmd == "TX_VERSION" then
		Buffalo_HandleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		Buffalo_HandleRXVersion(message, sender)
	elseif cmd == "TX_VERCHECK" then
		Buffalo_HandleTXVerCheck(message, sender)
	end
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

function Buffalo_CheckIsNewVersion(versionstring)
	local incomingVersion = Buffalo_CalculateVersion( versionstring );

	if (BUFFALO_CURRENT_VERSION > 0 and incomingVersion > 0) then
		if incomingVersion > BUFFALO_CURRENT_VERSION then
			if not BUFFALO_UPDATE_MESSAGE_SHOWN then
				BUFFALO_UPDATE_MESSAGE_SHOWN = true;
				Buffalo_Echo(string.format("NOTE: A newer version of ".. COLOUR_INTRO .."BUFFALO"..COLOUR_CHAT.."! is available (version %s)!", versionstring));
				Buffalo_Echo("You can download latest version from https://www.curseforge.com/ or https://github.com/Sentilix/buffalo.");
			end
		end	
	end
end

function Buffalo_IsInParty()
	if not IsInRaid() then
		return ( GetNumGroupMembers() > 0 );
	end
	return false
end

function Buffalo_GetMyRealm()
	local realmname = GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

function Buffalo_GetPlayerAndRealm(unitid)
	local playername = GetUnitName(unitid, true);

	if not string.find(playername, "-") then
		playername = playername .."-".. Buffalo_GetMyRealm();
	end;

	return playername;
end;

function Buffalo_GetPlayerAndRealmFromName(playername)
	if not string.find(playername, "-") then
		playername = playername .."-".. Buffalo_GetMyRealm();
	end;

	return playername;
end;



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
	Buffalo_SetOption(BUFFALO_CONFIG_KEY_BuffButtonPosX, Buffalo_GetOption(BUFFALO_CONFIG_KEY_BuffButtonPosX, x))
	Buffalo_SetOption(BUFFALO_CONFIG_KEY_BuffButtonPosY, Buffalo_GetOption(BUFFALO_CONFIG_KEY_BuffButtonPosY, y))

	local buttonVisibleDefault = "0";
	if IsBuffer then buttonVisibleDefault = "1"; end;
	Buffalo_GetOption(BUFFALO_CONFIG_KEY_BuffButtonVisible, buttonVisibleDefault);

	if Buffalo_GetOption(BUFFALO_CONFIG_KEY_BuffButtonVisible, buttonVisibleDefault) == "1" then
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

	--	Expansion-specific settings.
	--	TODO: We currently only support Classic!
	BUFF_MATRIX = Buffalo_InitializeBuffMatrix();
	CLASS_MATRIX = Buffalo_InitializeClassMatrix();
		
	local matrixCount = 0;
	for _ in pairs(BUFF_MATRIX) do 
		matrixCount = matrixCount + 1; 
	end;

	if matrixCount > 0 then
		local expansionLevel = 1 * GetAddOnMetadata(BUFFALO_NAME, "X-Expansion-Level");
		if expansionLevel == 1  then
			IsBuffer = true;	-- Effectively disables addon for anything but classic!
		end;
	end;

	Buffalo_InitializationComplete = true;
end;



--[[
	Raid scanner
--]]
local function Buffalo_ScanRaid()
	--Buffalo_Echo("Scanning raid ...");

	if not IsBuffer or not Buffalo_InitializationComplete then
		return;
	end;

	--	If we're in combat, set Combat icon and skip scan.
	if UnitAffectingCombat("player") then
		Buffalo_SetButtonTexture(BUFFALO_BuffBtn_Combat);
		return;
	end;

	if UnitIsDeadOrGhost("player") then
		return;
	end;

	
	--	Generate a party/raid roster with meta info per character:
	local roster = { };
	local startNum, endNum, groupType, unitid, groupCount;

	if Buffalo_IsInParty() then
		grouptype = "party";
		groupCount = 1;
		startNum = 0;
		endNum = GetNumGroupMembers() - 1;
	elseif IsInRaid() then
		grouptype = "raid";
		groupCount = 8;
		startNum = 1;
		endNum = GetNumGroupMembers();
	else
		grouptype = "player";
		groupCount = 1;
		startNum = 0;
		endNum = 0
	end;

	--	Part 1:
	--	This generate a roster{} array based on unitid to find group, buffmask etc:
	if grouptype == "player" then
		roster["player"] = { ["Group"]=1, ["IsOnline"]=true, ["IsDead"]=nil, ["BuffMask"]=0, ["ClassMask"]=0x0fff };
	else
		for raidIndex = 1, 40, 1 do
			local name, rank, subgroup, level, _, filename, zone, online, dead, role, isML = GetRaidRosterInfo(raidIndex);
			if not name then break; end;

			local isOnline = 0 and online and 1;
			local isDead   = 0 and dead   and 1;

			if groupType == "raid" then
				unitid = grouptype..raidIndex;
			else
				unitid = "player"
				if raidIndex > 1 then
					unitid = grouptype..(raidIndex - 1);
				end;
			end;

			--	This is the english localization of the class. GetRaidRosterInfo delivers the localized name.
			local _, classname = UnitClass(unitid);

			--echo(string.format("Roster.add(unitid=%s, Group=%d)", unitid, subgroup));
			roster[unitid] = { ["Group"]=subgroup, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["ClassMask"]=CLASS_MATRIX[classname] };
		end;
	end;


	--	Part 2:
	--	This iterate over all players in party/raid and set the bitmapped buff mask on each
	--	applicable (i.e. not dead, not disconnected) player.
	local binValue;	
	for groupIndex = startNum, endNum, 1 do
		buffMask = 0;
		unitid = "player"
		if groupIndex > 0 then unitid = grouptype..groupIndex; end;

		--	This skips scanning for dead, offliners and people not in my group:
		local scanPlayerBuffs = true;
		local rosterInfo = roster[unitid];
		if rosterInfo then
			local groupMask = BUFF_AssignedGroups[rosterInfo["Group"]];

			if groupMask == 0 then					-- No buffs assigned: skip this group!
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

				local buffInfo = BUFF_MATRIX[buffName];
				if buffInfo then
					buffMask = buffMask + buffInfo["BITMASK"];
					--echo(string.format("Adding: %s on unit=%s, mask=%d", buffName, unitid, buffInfo["BITMASK"]));
				end;
			end

			--echo(string.format("Unitid=%s, mask=%s", unitid, buffMask));
			--	Each unitid is now set with a buffMask: a bitmask containing the buffs they currently have.
			roster[unitid]["BuffMask"] = buffMask;
		end;
	end;


	--	Next step is to figure out which buffs are missing, and then prioritize.
	--
	--	Run over Groups -> Buffs -> UnitIDs
	--	Result: { unitid, buffname, iconid, priority }

	local MissingBuffs = { };				-- Final list of all missing buffs with a Priority set.
	local missingBuffIndex = 0;				-- Buff counter
	for groupIndex = 1, groupCount, 1 do	-- Iterate over all available groups
		local groupMask = BUFF_AssignedGroups[groupIndex];
		--echo(string.format("Grp=%d, mask=%s", groupIndex, groupMask));

		if groupMask > 0 then
			--	We have found an assigned group now. 
			--	Search through the buffs, and count each buff per group and unit combo:
			for buffName, buffInfo in next, BUFF_MATRIX do
				local bitMask = buffInfo["BITMASK"];
				--	Skip buffs which we haven't committed to do:
				if(bit.band(bitMask, groupMask) > 0) then
					--echo(string.format("Buff=%s, mask=%d", buffName, bitMask));
					local buffMissingCounter = 0;		-- No buffs detected so far.
					local MissingBuffsInGroup = { };	-- No units missing buffs in group (yet).

					for raidIndex = startNum, endNum, 1 do
						unitid = "player";
						if raidIndex > 0 then unitid = grouptype .. raidIndex; end;

						local rosterInfo = roster[unitid];
						if rosterInfo and rosterInfo["Group"] == groupIndex and rosterInfo["IsOnline"] and not rosterInfo["IsDead"] then
							-- This one checks the class is eligible for the buff:
							if (bit.band(buffInfo["CLASSES"], rosterInfo["ClassMask"]) > 0)	then
								--echo(string.format("Class is eligible for buff, Unitid=%s, BuffClass=%d, ClassMask=%d", unitid, buffInfo["CLASSES"], rosterInfo["ClassMask"]));

								--	Note: this both checks the range of the spell, but also if the caster knows the spell!
								if IsSpellInRange(buffName, unitid) then
									--	There's a living person in this group. Check if he needs the specific buff.
									--	Note: If buffMask >= 256 then it is a local buff only for me ("player"),
									--	which we ignore for the time being.
									local buffMask = rosterInfo["BuffMask"];
									if (bit.band(buffMask, buffInfo["BITMASK"]) == 0) then
										if not buffInfo["GROUP"] and buffInfo["BITMASK"] < 256 then		-- Skip self buffs for now!
											buffMissingCounter = buffMissingCounter + 1;
											MissingBuffsInGroup[buffMissingCounter] = { unitid, buffName, buffInfo["ICONID"], buffInfo["PRIORITY"] };
											--echo(string.format("Adding: unit=%s, group=%d, buff=%s", UnitName(unitid), groupIndex, buffName));
										end;
									end;
								end;
							--else
								--echo(string.format("Class is not eligible for buff, Unitid=%s, Buff=%s, ClassMask=%d", unitid, buffName, rosterInfo["ClassMask"]));
							end;
						--else
							--echo(string.format("No Roster for Unitid=%s, Group=%d, (%s)", unitid, groupIndex, UnitName(unitid)));
						end;
					end;

					--	If this is a group buff, and enough people are missing it, use the big one instead!
					if buffInfo["PARENT"] and buffMissingCounter >= BUFF_GroupBuffThreshold then
						--echo(string.format("GROUP: missing=%d, threshold=%d", buffMissingCounter, BUFF_GroupBuffThreshold));
						local parentBuffInfo = BUFF_MATRIX[buffInfo["PARENT"]];
						missingBuffIndex = missingBuffIndex + 1;
						MissingBuffs[missingBuffIndex] = { unitid, buffInfo["PARENT"], parentBuffInfo["ICONID"], parentBuffInfo["PRIORITY"] };
					else
						-- Use single target buffing:
						for missingIndex = 1, buffMissingCounter, 1 do
							missingBuffIndex = missingBuffIndex + 1;
							MissingBuffs[missingBuffIndex] = MissingBuffsInGroup[missingIndex];
						end;
					end;
				--else
					--echo(string.format("Ignoring: group=%d, buff=%s", groupIndex, buffName));
				end;
			end;
		end;
	end;

	if missingBuffIndex > 0 then
		--	Now sort by Priority (descending order):
		table.sort(MissingBuffs, Buffalo_ComparePriority);

		if debug then	--	For debugging: output all missing buffs in prio:
			for buffIndex = 1, missingBuffIndex, 1 do
				local buff = MissingBuffs[buffIndex];
				local playername = UnitName(buff[1]) or UnitName("player");
				echo(string.format("Missing: UnitID=%s, Player=%s, Buff=%s, Prio=%d", buff[1], playername, buff[2], buff[3]));
			end;
		end;

		--	Now pick first buff from list and set icon:
		local missingBuff = MissingBuffs[1];
		unitid = missingBuff[1];
		Buffalo_UpdateBuffButton(unitid, missingBuff[2], missingBuff[3]);
	else
		Buffalo_UpdateBuffButton();
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


--[[
	UI Control
--]]
function Buffalo_RepositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Buffalo_SetOption(BUFFALO_CONFIG_KEY_BuffButtonPosX, x);
	Buffalo_SetOption(BUFFALO_CONFIG_KEY_BuffButtonPosY, y);
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

function Buffalo_UpdateBuffButton(unitid, spellname, textureId)
	if unitid then
		Buffalo_SetButtonTexture(textureId, true);
		BuffButton:SetAttribute("type", "spell");
		BuffButton:SetAttribute("spell", spellname);
		BuffButton:SetAttribute("unit", unitid);
	else
		Buffalo_SetButtonTexture(ICON_PASSIVE);
		BuffButton:SetAttribute("type", "spell");
		BuffButton:SetAttribute("spell", nil);
		BuffButton:SetAttribute("unit", nil);
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
		Buffalo_OnChatMsgAddon(event, ...)

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
	Buffalo_PlayerNameAndRealm = Buffalo_GetPlayerAndRealm("player");
	BUFFALO_CURRENT_VERSION = Buffalo_CalculateVersion(GetAddOnMetadata(BUFFALO_NAME, "Version") );

	Buffalo_Echo(string.format("Version %s by %s", GetAddOnMetadata(BUFFALO_NAME, "Version"), GetAddOnMetadata(BUFFALO_NAME, "Author")));
	Buffalo_Echo(string.format("Type %s/buffalo%s to configure the addon.", BUFFALO_COLOUR_INTRO, BUFFALO_COLOUR_CHAT));

    BuffaloEventFrame:RegisterEvent("ADDON_LOADED");
    BuffaloEventFrame:RegisterEvent("CHAT_MSG_ADDON");

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


