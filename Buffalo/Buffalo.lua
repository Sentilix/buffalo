--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo.lua
--	Desc:	Core functionality: addon framework, event handling etc.
--]]

--	Misc. constants:
local BUFFALO_CURRENT_VERSION					= 0;
local BUFFALO_NAME								= "Buffalo"
local BUFFALO_MESSAGE_PREFIX					= "BuffaloV1"

--	Design/UI constants
local BUFFALO_CHAT_END							= "|r"
local BUFFALO_COLOUR_BEGINMARK					= "|c80"
local BUFFALO_COLOUR_CHAT						= BUFFALO_COLOUR_BEGINMARK.."E0C020"
local BUFFALO_COLOUR_INTRO						= BUFFALO_COLOUR_BEGINMARK.."F8F8F8"
local BUFFALO_ICON_PASSIVE						= 136112;
local BUFFALO_ICON_COMBAT						= "Interface\\Icons\\Ability_dualwield";
local BUFFALO_ICON_PLAYERDEAD					= "Interface\\Icons\\Ability_rogue_feigndeath";

--	Internal variables
local IsBuffer									= false;
local Buffalo_PlayerNameAndRealm				= "";
local Buffalo_InitializationComplete			= false;
local Buffalo_InitializationRetryTimer			= 0;
local Buffalo_UpdateMessageShown				= false;
local TimerTick = 0
local NextScanTime = 0;
local lastBuffTarget = "";

--	Array of buff properties for the griuo UI: { buffname, iconid, bitmask, priority }
local Buffalo_GroupBuffProperties				= { }
local Buffalo_SelfBuffProperties				= { }

--	[buffname]=<bitmask value>
local BUFF_MATRIX = { };

--	[classname<english>]=<bitmasl value>
local CLASS_MATRIX = { };

--	Debugging
local DEBUG_FunctionList = { };


-- Configuration:
--	Loaded options:	{realmname}{playername}{parameter}
Buffalo_Options = { }

--	Configuration keys:
local CONFIG_KEY_BuffButtonPosX					= "BuffButton.X";
local CONFIG_KEY_BuffButtonPosY					= "BuffButton.Y";
local CONFIG_KEY_BuffButtonVisible				= "BuffButton.Visible";
local CONFIG_KEY_AnnounceMissingBuff			= "AnnounceMissingBuff";
local CONFIG_KEY_AssignedBuffGroups				= "AssignedBuffGroups";
local CONFIG_KEY_AssignedBuffSelf				= "AssignedBuffSelf";

local CONFIG_DEFAULT_AssignedBuffSelf			= 0x0000;
local CONFIG_DEFAULT_AnnounceMissingBuff		= false;

--	Configured values (TODO: a few selected are still not configurable)
local CONFIG_AssignedBuffGroups					= { };		-- List of groups and their assigned buffs via bitmask. Persisted, but no UI for it.
local CONFIG_AssignedBuffSelf					= 0x0000;	-- (TODO: Make configurable!) List of assigned self buffs. Persisted, but no UI for it.
local CONFIG_GroupBuffThreshold					= 4;		-- (TODO: Make configurable!) If at least N persons are missing same buff, group buffs will be used.
local CONFIG_ScanFrequency						= 0.3;		-- (TODO: Make configurable!) Scan every N second.
local CONFIG_AnnounceMissingBuff				= false;	-- (TODO: Make configurable!) Announce next buff being cast. Persisted, but no UI for it.
local CONFIG_BuffButtonSize						= 32;		-- (TODO: Make configurable!) Size of buff button
local CONFIG_PlayerBuffPriority					= 90;		-- (TODO: Make configurable!) Priority to Self


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
	local _, _, option, params = string.find(msg, "(%S*).?(%S*)")

	if not option or option == "" then
		option = "CFG";
	end;

	option = string.upper(option);
		
	if (option == "CFG" or option == "CONFIG") then
		SlashCmdList["BUFFALO_CONFIG"]();
	elseif option == "DEBUG" then
		SlashCmdList["BUFFALO_DEBUG"](params);
	elseif option == "REMOVEDEBUG" or option == "STOPDEBUG" then
		SlashCmdList["BUFFALO_REMOVEDEBUG"](params);
	elseif option == "HELP" then
		SlashCmdList["BUFFALO_HELP"]();
	elseif option == "SHOW" then
		SlashCmdList["BUFFALO_SHOW"]();
	elseif option == "HIDE" then
		SlashCmdList["BUFFALO_HIDE"]();
	elseif option == "ANNOUNCE" then
		SlashCmdList["BUFFALO_ANNOUNCE"]();
	elseif option == "STOPANNOUNCE" then
		SlashCmdList["BUFFALO_STOPANNOUNCE"]();
	elseif option == "VERSION" then
		SlashCmdList["BUFFALO_VERSION"]();
	else
		Buffalo_Echo(string.format("Unknown command: %s", option));
	end
end

--[[
	Show the configuration dialogue
	Syntax: /buffaloconfig, /buffalocfg
	Alternative: /buffalo config, /buffalo cfg
	Added in: 0.1.0
]]
SLASH_BUFFALO_CONFIG1 = "/buffaloconfig"
SLASH_BUFFALO_CONFIG2 = "/buffalocfg"
SlashCmdList["BUFFALO_CONFIG"] = function(msg)
	Buffalo_OpenConfigurationDialogue();
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
	Buffalo_SetOption(CONFIG_KEY_BuffButtonVisible, "1");
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
	Buffalo_SetOption(CONFIG_KEY_BuffButtonVisible, "0");
end

--[[
	Enable buff announcements (locally)
	Syntax: /buffaloannounce
	Alternative: /buffalo announce
	Added in: 0.3.0
]]
SLASH_BUFFALO_ANNOUNCE1 = "/buffaloannounce"
SlashCmdList["BUFFALO_ANNOUNCE"] = function(msg)
	CONFIG_AnnounceMissingBuff = true;
	lastBuffTarget = "";
	Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);
	Buffalo_Echo("Buff announcements are now ON.");
end

--[[
	Disable buff announcements (locally)
	Syntax: /buffalostopannounce
	Alternative: /buffalo stopannounce
	Added in: 0.3.0
]]
SLASH_BUFFALO_STOPANNOUNCE1 = "/buffalostopannounce"
SlashCmdList["BUFFALO_STOPANNOUNCE"] = function(msg)
	CONFIG_AnnounceMissingBuff = false;
	Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);
	Buffalo_Echo("Buff announcements are now OFF.");
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
	Add a function to debug. If function is blank, it lists current functions.
	Syntax: /buffalodebug
	Alternative: /buffalo debug [function]
	Added in: 0.3.0
]]
SLASH_BUFFALO_DEBUG1 = "/buffalodebug"	
SlashCmdList["BUFFALO_DEBUG"] = function(msg)
	if msg and msg ~= "" then
		Buffalo_AddDebugFunction(msg);
	else
		Buffalo_ListDebugFunctions();
	end;
end

--[[
	Remove a function from the debugging list
	Syntax: /buffaloremovedebug
	Alternative: /buffalo removedebug [function]
	Added in: 0.3.0
]]
SLASH_BUFFALO_REMOVEDEBUG1 = "/buffaloremovedebug"	
SLASH_BUFFALO_REMOVEDEBUG2 = "/buffalostopdebug"	
SlashCmdList["BUFFALO_REMOVEDEBUG"] = function(msg)
	if msg and msg ~= "" then
		Buffalo_RemoveDebugFunction(msg);
	else
		Buffalo_ListDebugFunctions();
	end;
end
--[[
	Show HELP options
	Syntax: /buffalohelp
	Alternative: /buffalo help
	Added in: 0.2.0
]]
SLASH_BUFFALO_HELP1 = "/buffalohelp"
SlashCmdList["BUFFALO_HELP"] = function(msg)
	Buffalo_Echo(string.format("buffalo version %s options:", GetAddOnMetadata(BUFFALO_NAME, "Version")));
	Buffalo_Echo("Syntax:");
	Buffalo_Echo("    /buffalo [command]");
	Buffalo_Echo("Where commands can be:");
	Buffalo_Echo("    Config       (default) Open the configuration dialogue. Same as right-clicking buff button.");
	Buffalo_Echo("    Show         Shows the buff button.");
	Buffalo_Echo("    Hide         Hides the buff button.");
	Buffalo_Echo("    Announce     Announce when a buff is missing.");
	Buffalo_Echo("    stopannounce Stop announcing missing buffs.");
	Buffalo_Echo("    Version      Request version info from all clients.");
	Buffalo_Echo("    Help         This help.");
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
			if not Buffalo_UpdateMessageShown then
				Buffalo_UpdateMessageShown = true;
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
	local playername, realmname = UnitName(unitid);
	return playername.."-".. (realmname or Buffalo_GetMyRealm());
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

	local x,y = BuffButton:GetPoint();
	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosX, Buffalo_GetOption(CONFIG_KEY_BuffButtonPosX, x))
	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosY, Buffalo_GetOption(CONFIG_KEY_BuffButtonPosY, y))

	local buttonVisibleDefault = "0";
	if IsBuffer then buttonVisibleDefault = "1"; end;
	Buffalo_GetOption(CONFIG_KEY_BuffButtonVisible, buttonVisibleDefault);

	if Buffalo_GetOption(CONFIG_KEY_BuffButtonVisible, buttonVisibleDefault) == "1" then
		BuffButton:Show();
	else
		BuffButton:Hide()
	end

	--	Init the "assigned buff groups". This is a table, so we need to validate the integrity:
	local assignedBuffGroups = Buffalo_GetOption(CONFIG_KEY_AssignedBuffGroups, x);
	if type(assignedBuffGroups) == "table" and table.getn(assignedBuffGroups) == 8 then
		CONFIG_DEFAULT_AssignedBuffGroups = { }
		for groupNum = 1, 8, 1 do
			local groupMask = 0;
			if assignedBuffGroups[groupNum] then
				groupMask = assignedBuffGroups[groupNum];
			end;

			CONFIG_AssignedBuffGroups[groupNum] = 1 * groupMask;
		end;
	else
		--	Use the default assignments for my class: most important buffs in ALL groups:
		CONFIG_AssignedBuffGroups = Buffalo_InitializeAssignedGroupDefaults();
	end;
	Buffalo_SetOption(CONFIG_KEY_AssignedBuffGroups, CONFIG_AssignedBuffGroups);

	CONFIG_AssignedBuffSelf = Buffalo_GetOption(CONFIG_KEY_AssignedBuffSelf, CONFIG_DEFAULT_AssignedBuffSelf);
	Buffalo_SetOption(CONFIG_KEY_AssignedBuffSelf, CONFIG_AssignedBuffSelf);

	CONFIG_AnnounceMissingBuff = Buffalo_GetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_DEFAULT_AnnounceMissingBuff);
	Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);
end


--[[
	Initialization
--]]
function Buffalo_MainInitialization()
	Buffalo_InitializeConfigSettings();

	--	This sets the buffs up for MY class:
	BUFF_MATRIX = Buffalo_InitializeBuffMatrix();

	local matrixCount = 0;
	for _ in pairs(BUFF_MATRIX) do 
		matrixCount = matrixCount + 1; 
	end;

	if matrixCount == 0 and not Buffalo_InitializationComplete then
		--	This can fail if wow havent loaded all objects yet.
		--	We just wait a couple of seconds and try again:
		Buffalo_InitializationRetryTimer = TimerTick + 3;
		return;
	end;

	--	This sets up a class matrix with a bit for each class:
	CLASS_MATRIX = Buffalo_InitializeClassMatrix();

	Buffalo_InitializeGroupBuffUI();

	--	Expansion-specific settings.
	local expansionLevel = 1 * GetAddOnMetadata(BUFFALO_NAME, "X-Expansion-Level");
	if expansionLevel == 1  then
		IsBuffer = true;
	elseif expansionLevel == 2  then
		IsBuffer = true;
	end;

	if IsBuffer then
		BuffButton:Show();
	end;

	Buffalo_InitializationComplete = true;
	if CONFIG_AnnounceMissingBuff then
		Buffalo_Echo("Buff data loaded, Buffalo is ready.");
	end;
end;



--[[
	Raid scanner
--]]
local function Buffalo_ScanRaid()
	--Buffalo_Echo("Scanning raid ...");
	local debug = DEBUG_FunctionList["BUFFALO_SCANRAID"];

	if not IsBuffer or not Buffalo_InitializationComplete then
		return;
	end;

	--	If we're in combat, set Combat icon and skip scan.
	if UnitAffectingCombat("player") then
		Buffalo_SetButtonTexture(BUFFALO_ICON_COMBAT);
		return;
	end;

	--	Likewise if player is dead (sigh)
	if UnitIsDeadOrGhost("player") then
		Buffalo_SetButtonTexture(BUFFALO_ICON_PLAYERDEAD);
		return;
	end;

	
	--	Generate a party/raid/solo roster with meta info per character:
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
		grouptype = "solo";
		groupCount = 1;
		startNum = 0;
		endNum = 0
	end;

	--	Part 1:
	--	This generate a roster{} array based on unitid to find group, buffmask etc:
	local playername = UnitName("player");
	local currentUnitid = "player";
	if grouptype == "solo" then
		unitid = "player"
		roster[unitid] = { ["Group"]=1, ["IsOnline"]=true, ["IsDead"]=nil, ["BuffMask"]=0, ["ClassMask"]=BUFFALO_CLASS_ALL };

	elseif grouptype == "party" then
		unitid = "player";
		for raidIndex = startNum, endNum, 1 do
			if raidIndex > 0 then
				unitid = grouptype..raidIndex;
			end;
			
			local isOnline = 0 and UnitIsConnected(unitid) and 1;
			local isDead   = 0 and UnitIsDead(unitid) and 1;
			local _, classname = UnitClass(unitid);

			roster[unitid] = { ["Group"]=1, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["ClassMask"]=CLASS_MATRIX[classname] };
		end;

	else	-- Raid
		for raidIndex = 1, 40, 1 do
			local name, rank, subgroup, level, _, filename, zone, online, dead, role, isML = GetRaidRosterInfo(raidIndex);
			if name then
				local isOnline = 0 and online and 1;
				local isDead   = 0 and dead   and 1;

				unitid = grouptype..raidIndex;
				
				--	Find unitid on current player:
				if name == playername then
					currentUnitid = unitid;
				end;

				-- GetRaidRosterInfo delivers the localized class name.
				-- We need the english class name:
				local _, classname = UnitClass(unitid);

				roster[unitid] = { ["Group"]=subgroup, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["ClassMask"]=CLASS_MATRIX[classname] };
			end;
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
			local groupMask = CONFIG_AssignedBuffGroups[rosterInfo["Group"]];
			groupMask = bit.bor(groupMask, CONFIG_AssignedBuffSelf);

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
					buffMask = bit.bor(buffMask, buffInfo["BITMASK"]);
				end;
			end

			--	Add tracking icons ("Find Herbs", "Find Minerals" ...)
			local trackingIcon = GetTrackingTexture();
			for buffName, buffInfo in next, BUFF_MATRIX do
				if buffInfo["ICONID"] == trackingIcon then
					buffMask = bit.bor(buffMask, buffInfo["BITMASK"]);
				end;
			end;
			
			--	This may be nil when new people joins while scanning is done:
			if not roster[unitid] then
				roster[unitid] = { };
			end;
			--	Each unitid is now set with a buffMask: a bitmask containing the buffs they currently have.
			roster[unitid]["BuffMask"] = buffMask;
		end;		
	end;


	--	Part 3: Identify which buffs are missing.
	--
	--	Run over Groups -> Buffs -> UnitIDs
	--	Result: { unitid, buffname, iconid, priority }
	local unitname;
	local MissingBuffs = { };				-- Final list of all missing buffs with a Priority set.
	local missingBuffIndex = 0;				-- Buff counter
	local castingPlayerAndRealm = Buffalo_GetPlayerAndRealm("player");

	--	Raid buffs:
	for groupIndex = 1, groupCount, 1 do	-- Iterate over all available groups
		local groupMask = CONFIG_AssignedBuffGroups[groupIndex];
		--local selfieMask = CONFIG_AssignedBuffSelf;
		--local combiMask = bit.bor(groupMask, selfieMask);

		--	If groupMask is 0 then this group does not have any buffs to apply.
		if groupMask > 0 then
			--echo(string.format("Group=%s, mask=%s", groupIndex, groupMask));
			--	We have found an assigned group now. 
			--	Search through the buffs, and count each buff per group and unit combo:
			for buffName, buffInfo in next, BUFF_MATRIX do
				local buffMissingCounter = 0;		-- No buffs detected so far.
				local groupMemberCounter = 0;		-- Total # of units in group.
				local MissingBuffsInGroup = { };	-- No units missing buffs in group (yet).

				--	Skip buffs which we haven't committed to do. That includes GREATER/PRAYER buffs:
				if(bit.band(buffInfo["BITMASK"], groupMask) > 0) and not buffInfo["GROUP"] then
					--echo(string.format("Buff=%s, bmask=%d, group=%d, gmask=%d", buffName, bitMask, groupIndex, groupMask));
					local waitForCooldown = false;
					if buffInfo["COOLDOWN"] then
						local start, duration, enabled = GetSpellCooldown(buffName);
						waitForCooldown = (start > 3);
					end;
					if not waitForCooldown then
						--	No cooldown (checking on GCD here as well)
						--	Iterate over Party / Raid
						for raidIndex = startNum, endNum, 1 do
							unitid = "player";
							if raidIndex > 0 then unitid = grouptype .. raidIndex; end;
							unitname = Buffalo_GetPlayerAndRealm(unitid);

							local rosterInfo = roster[unitid];

							--	Check 1: Target must be online and alive:
							if rosterInfo and rosterInfo["IsOnline"] and not rosterInfo["IsDead"] then
								--echo(string.format("Checking %s (%s) in group %s", unitname, unitid, groupIndex));
								--	Check 2: Target must be in the current group:
								if rosterInfo["Group"] == groupIndex then
									groupMemberCounter = groupMemberCounter + 1;
									--echo(string.format("Found target %s (%s) in group %s", unitname, unitid, groupIndex));

									-- Check 3: Target class must be eligible for buff:
									if (bit.band(buffInfo["CLASSES"], rosterInfo["ClassMask"]) > 0)	then
										--echo(string.format("Class is eligible for buff, Buff=%s, Unit=%s, BuffClass=%d, ClassMask=%d", buffName, unitname, buffInfo["CLASSES"], rosterInfo["ClassMask"]));

										--	Check 4: Target must be in range:
										--if Buffalo_IsSpellInRange(buffName, unitid, unitIsCurrentPlayer) then 
										if IsSpellInRange(buffName, unitid) == 1 then 
											--echo(string.format("Spell in range, Buff=%s, Unit=%s, BuffClass=%d, ClassMask=%d", buffName, unitname, buffInfo["CLASSES"], rosterInfo["ClassMask"]));

											--	Check 5: There's a person alive in this group. Do he needs this specific buff?
											if (bit.band(rosterInfo["BuffMask"], buffInfo["BITMASK"]) == 0) then
												--echo(string.format("Found missing buff, unit=%s, group=%d, buff=%s", UnitName(unitid), groupIndex, buffName));

												--	Check 6: Missing buff detected! "Selfie" buffs are only available by current player, e.g. "Inner Fire":
												--if	(unitIsCurrentPlayer and bit.band(selfieMask, buffInfo["BITMASK"]) > 0) or	-- Selfie buff
												--	(bit.band(groupMask, buffInfo["BITMASK"]) > 0) then							-- Raid buff
												if	(bit.band(groupMask, buffInfo["BITMASK"]) > 0) then							-- Raid buff
													buffMissingCounter = buffMissingCounter + 1;
													local priority = buffInfo["PRIORITY"];
													--echo(string.format("Adding: unit=%s, group=%d, buff=%s", unitname, groupIndex, buffName));
													MissingBuffsInGroup[buffMissingCounter] = { unitid, buffName, buffInfo["ICONID"], priority };
												end;
											end;											
										end;
									end;
								end;
							end;
						end;	-- end iterate raid
					end;
				end;

				--	If this is a group buff, and enough people are missing it, use the big one instead!
				if buffInfo["PARENT"] and buffMissingCounter >= CONFIG_GroupBuffThreshold then
					--echo(string.format("GROUP: missing=%d, threshold=%d", buffMissingCounter, CONFIG_GroupBuffThreshold));
					local parentBuffInfo = BUFF_MATRIX[buffInfo["PARENT"]];
					local bufferUnitid = MissingBuffsInGroup[1][1];
					missingBuffIndex = missingBuffIndex + 1;
					local priority = parentBuffInfo["PRIORITY"] + (buffMissingCounter / groupMemberCounter * 5) + groupMemberCounter;
					MissingBuffs[missingBuffIndex] = { bufferUnitid, buffInfo["PARENT"], parentBuffInfo["ICONID"], priority };
				else
					-- Use single target buffing:
					for missingIndex = 1, buffMissingCounter, 1 do
						missingBuffIndex = missingBuffIndex + 1;
						MissingBuffs[missingBuffIndex] = MissingBuffsInGroup[missingIndex];
					end;
				end;
			end;	-- end iterate buff matrix
		end;
	end;	--	End iterate raid groups


	--	Self buffs:
	local groupMask = CONFIG_AssignedBuffSelf;
	if groupMask > 0 then
		--echo(string.format("GroupMask=%s", groupMask));

		--	We have found an assigned group now. 
		--	Search through the buffs, and count each buff per group and unit combo:
		for buffName, buffInfo in next, BUFF_MATRIX do
			--	Skip buffs which we haven't committed to do. That includes GREATER/PRAYER buffs:
			if(bit.band(buffInfo["BITMASK"], groupMask) > 0) and not buffInfo["GROUP"] then
				--echo(string.format("Buff=%s, bmask=%d, gmask=%d", buffName, bitMask, groupMask));
				local waitForCooldown = false;
				if buffInfo["COOLDOWN"] then
					local start, duration, enabled = GetSpellCooldown(buffName);
					waitForCooldown = (start > 3);
				end;
				if not waitForCooldown then
					--	No cooldown (checking on GCD here as well)
					local rosterInfo = roster[currentUnitid];
					--echo("currentUnitid = "..currentUnitid .." (".. UnitName(currentUnitid) ..")");
	
					--	Check 1: Target must be online and alive:
					if rosterInfo and not rosterInfo["IsDead"] then
						--echo(string.format("Checking %s (%s)", GetUnitName(currentUnitid, true), currentUnitid));

						--	Check 4: Target must be in range (and know the spell)
						--if Buffalo_IsSpellInRange(buffName, unitid, unitIsCurrentPlayer) then 
						if IsSpellInRange(buffName, currentUnitid) ~= 0 then 
							--echo(string.format("Spell in range, Buff=%s, Unit=%s, BuffClass=%d, ClassMask=%d", buffName, currentUnitid, buffInfo["CLASSES"], rosterInfo["ClassMask"]));

							--	Check 5: Do I needs this specific buff?
							if (bit.band(rosterInfo["BuffMask"], buffInfo["BITMASK"]) == 0) then
								--echo(string.format("Found missing buff, unit=%s, group=%d, buff=%s", UnitName(unitid), groupIndex, buffName));

								if (bit.band(groupMask, buffInfo["BITMASK"]) > 0) then
									--echo(string.format("Adding: unitid=%s, unit=%s, group=%d, buff=%s", unitid, unitname, groupIndex, buffName));
									missingBuffIndex = missingBuffIndex + 1;
									local priority = buffInfo["PRIORITY"];
									if not buffInfo["GROUP"] then
										--	Self buffs have prio, unless they can also be grouped.
										--	This is to avoid a Fort (single) self buffs overriding a Fort (group) buff in same group.
										priority = priority + CONFIG_PlayerBuffPriority;
									end;

									MissingBuffs[missingBuffIndex] = { currentUnitid, buffName, buffInfo["ICONID"], buffInfo["PRIORITY"]};
								end;
							end;											
						end;
					end;
				end;
			end;
		end;	-- end iterate buff matrix
	end;


	--	Part 4: Pick a buff to .. buff!
	--	Sort by priority and use first buff on list.
	if table.getn(MissingBuffs) > 0 then
		--	Sort by Priority (descending order):
		table.sort(MissingBuffs, Buffalo_ComparePriority);

		--	Now pick first buff from list and set icon:
		local missingBuff = MissingBuffs[1];
		unitid = missingBuff[1];

		local buffName = missingBuff[2];
		local targetPlayer = Buffalo_GetPlayerAndRealm(unitid);
		if CONFIG_AnnounceMissingBuff then
			if lastBuffTarget ~= targetPlayer..buffName then
				lastBuffTarget = targetPlayer..buffName;
				Buffalo_Echo(string.format("%s is missing %s.", targetPlayer, buffName));
			end;
		end;

		if debug then
			Buffalo_Echo(string.format("DEBUG: Buffing unit=%s(%s), Buff=%s, Icon=%s", unitid, targetPlayer, buffName, missingBuff[3]));
		end;

		Buffalo_UpdateBuffButton(unitid, buffName, missingBuff[3]);
	else
		Buffalo_UpdateBuffButton();

		if CONFIG_AnnounceMissingBuff then
			if lastBuffTarget ~= "" then
				Buffalo_Echo("No pending buffs.");
				lastBuffTarget = "";
			end;
		end;
	end;
end;

function Buffalo_ComparePriority(a, b)
	return a[4] > b[4];
end;




--[[
	WoW object handling
--]]
function Buffalo_IsSpellInRange(spellname, unitid, unitIsCurrentPlayer)
	local inRange = IsSpellInRange(spellname, unitid);
	if inRange == 0 then 
		return false;
	end;

	if inRange == 1 then
		return true;
	end;
	
	--	If player is myself, IsSpellInRange returns nil. But I am in range!
	return unitIsCurrentPlayer;
end;


--[[
	UI Control
--]]
function Buffalo_OpenConfigurationDialogue()
	Buffalo_RefreshGroupBuffUI();
	BuffaloConfigFrame:Show();
end;

function Buffalo_CloseConfigurationDialogue()
	BuffaloConfigFrame:Hide();
end;

function Buffalo_RepositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosX, x);
	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosY, y);
	BuffButton:SetSize(CONFIG_BuffButtonSize, CONFIG_BuffButtonSize);

	if IsBuffer then
		BuffButton:Show();
	else
		BuffButton:Hide();
	end;
end

local function Buffalo_HideBuffButton()
	Buffalo_SetButtonTexture(BUFFALO_ICON_PASSIVE);
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
		BuffButton:SetAttribute("*type1", "spell");
		BuffButton:SetAttribute("spell", spellname);
		BuffButton:SetAttribute("unit", unitid);
	else
		Buffalo_SetButtonTexture(BUFFALO_ICON_PASSIVE);
		BuffButton:SetAttribute("*type1", "spell");
		BuffButton:SetAttribute("spell", nil);
		BuffButton:SetAttribute("unit", nil);
	end;
end;

function Buffalo_OnAfterBuffClick(self, ...)
	local buttonName = ...;

	if buttonName == "RightButton" then
		Buffalo_OpenConfigurationDialogue();
	end;
end;

function Buffalo_GetGroupBuffProperties(includeSelfBuffs)
	--	This generate a table of all RAID buffs, ordered in priority:
	local buffProperties = { };
	local buffCount = 0;
	local priority;

	local includeMask = 0x00ff;
	local selfiePrio = 0;
	--	This includes Self buffs, but not Find Herbs/Minerals
	local selfiePrioMask = 0x0f00;
	if includeSelfBuffs then
		includeMask = 0x0ffff;
		selfiePrio = 50;
	end;
	for buffName, props in pairs(BUFF_MATRIX) do
		if not props["GROUP"] and (bit.band(props["BITMASK"], includeMask) > 0) then
			--echo(string.format("Adding buff via mask: %s, %d", buffName, includeMask));
			buffCount = buffCount + 1; 
			priority = props["PRIORITY"];

			if bit.band(props["BITMASK"], selfiePrioMask) > 0 then
				priority = priority + selfiePrio;
			end;

			buffProperties[buffCount] = { buffName, props["ICONID"], props["BITMASK"], priority };
		end;
	end;

	table.sort(buffProperties, Buffalo_ComparePriority);

	return buffProperties;
end;

function Buffalo_InitializeGroupBuffUI()
	Buffalo_GroupBuffProperties = Buffalo_GetGroupBuffProperties();
	Buffalo_SelfBuffProperties = Buffalo_GetGroupBuffProperties(true);

	local buffCount = table.getn(Buffalo_GroupBuffProperties);

	--	UI settings:
	local offsetX = 0;
	local offsetY = 0;
	local width = 50;
	local height= 40;
	local buttonX, buttonY;

	--	RAID buffs:
	--	Iterate over all groups and render icons.
	--	Note: all icons are dimmed out as if they were disabled.
	--	We will refresh the alpha value after rendering.
	local buttonName;
	local buttonId = 1;
	for groupNumber = 1, 8, 1 do
		buttonX = offsetX + width * (groupNumber - 1);
		for rowNumber = 1, buffCount, 1 do
			buttonY = offsetY - height * (rowNumber - 1);
			buttonName = string.format("$parentBuffRow%dCol%d", rowNumber, groupNumber);
			local entry = CreateFrame("Button", buttonName, BuffaloConfigFrameGroups, "BuffaloGroupButtonTemplate");
			entry:SetID(buttonId);
			entry:SetAlpha(0.4);
			entry:SetPoint("TOPLEFT", buttonX, buttonY);
			entry:SetNormalTexture(Buffalo_GroupBuffProperties[rowNumber][2]);
			entry:SetPushedTexture(Buffalo_GroupBuffProperties[rowNumber][2]);

			buttonId = buttonId + 1;
		end;
	end;

	--	SELF buffs:
	--	Iterate over all buffs and render icons.
	buttonY = 10;
	buffCount = table.getn(Buffalo_SelfBuffProperties);
	for rowNumber = 1, buffCount, 1 do
		--echo(string.format("SELF Buff=%s", Buffalo_SelfBuffProperties[rowNumber][2]));
		buttonX = offsetX + width * (rowNumber - 1);

		buttonName = string.format("BuffaloConfigFrameSelf%dCol0", rowNumber);
		local entry = CreateFrame("Button", buttonName, BuffaloConfigFrameSelf, "BuffaloGroupButtonTemplate");
		entry:SetID(buttonId);
		entry:SetAlpha(0.4);
		entry:SetPoint("TOPLEFT", buttonX, buttonY);
		entry:SetNormalTexture(Buffalo_SelfBuffProperties[rowNumber][2]);
		entry:SetPushedTexture(Buffalo_SelfBuffProperties[rowNumber][2]);

		buttonId = buttonId + 1;
	end;

	--	So now, lets apply the alpha values for enabled/disabled buffs:
	Buffalo_RefreshGroupBuffUI();
end;


--[[
	Set the alpha value on each icon, depending on the current buff's status
--]]
function Buffalo_RefreshGroupBuffUI()
	if not Buffalo_InitializationComplete then
		return;
	end;

	local buffCount = table.getn(Buffalo_GroupBuffProperties);

	--	RAID buffs:
	--	Iterate over all groups and render icons.
	local buttonName;
	for groupNumber = 1, 8, 1 do
		local buffMask = CONFIG_AssignedBuffGroups[groupNumber];

		for rowNumber = 1, buffCount, 1 do
			buttonName = string.format("BuffaloConfigFrameGroupsBuffRow%dCol%d", rowNumber, groupNumber);
			local entry = _G[buttonName];

			if (bit.band(buffMask, Buffalo_GroupBuffProperties[rowNumber][3]) > 0) then
				entry:SetAlpha(1.0);
			else
				entry:SetAlpha(0.4);
			end;
		end;
	end;

	--	SELF buffs:
	--	Iterate over all rows and render icons.
	local buttonName;
	local buffMask = CONFIG_AssignedBuffSelf;

	buffCount = table.getn(Buffalo_SelfBuffProperties);
	for rowNumber = 1, buffCount, 1 do
		buttonName = string.format("BuffaloConfigFrameSelf%dCol0", rowNumber);
		local entry = _G[buttonName];

		if (bit.band(buffMask, Buffalo_SelfBuffProperties[rowNumber][3]) > 0) then
			entry:SetAlpha(1.0);
		else
			entry:SetAlpha(0.4);
		end;
	end;

end;

function Buffalo_OnGroupBuffClick(self, ...)
	local buttonName = self:GetName();
	local buttonType = GetMouseButtonClicked();

	local _, _, row, col = string.find(buttonName, "[a-zA-Z]*(%d)[a-zA-Z]*(%d)");

	row = 1 * row;
	col = 1 * col;	-- Col=0: self buff, col 1-8: raid buff
--	echo(string.format("Row=%d, col=%d", row, col));

	--	GroupMask tells what buffs I have selected for the actual group.
	local groupMask;


	--	Properties are the name / icon/ mask for the clicked buff.
	local properties = { };
	if col == 0 then
		properties = Buffalo_SelfBuffProperties;
		groupMask = CONFIG_AssignedBuffSelf;
	else 
		properties = Buffalo_GroupBuffProperties;
		groupMask = CONFIG_AssignedBuffGroups[col];
	end;

	--	BuffMask is the clicked buff's bitvalue.
	local buffMask = properties[row][3];
	local maskOut = 0x0ffff - buffMask;		-- preserve all buffs except for the selected one:

	if buttonType == "LeftButton" then
		--	Left button: ADD the buff
		--	First disable all other buffs in same family (if any)

		local buffInfo = BUFF_MATRIX[properties[row][1]];

		local family = buffInfo["FAMILY"];
		if family then
			local familyMask = 0x0000;

			for buffName, buffInfo in next, BUFF_MATRIX do
				if buffInfo["FAMILY"] == family then
					--	Found a buff; reset it!
					familyMask = bit.bor(familyMask, buffInfo["BITMASK"]);
				end;
			end;

			groupMask = bit.band(groupMask, 0x0ffff - familyMask);
		end;

		groupMask = bit.bor(groupMask, buffMask);
	else
		--	REMOVE the buff:
		groupMask = bit.band(groupMask, maskOut);
	end;


	if col == 0 then
		CONFIG_AssignedBuffSelf = groupMask
		Buffalo_SetOption(CONFIG_KEY_AssignedBuffSelf, CONFIG_AssignedBuffSelf);
	else
		CONFIG_AssignedBuffGroups[col] = groupMask;
	end;

	Buffalo_RefreshGroupBuffUI();
end;

function Buffalo_OnCloseButtonClick()
	Buffalo_CloseConfigurationDialogue();
end;



--[[
	Timers
--]]
function Buffalo_GetTimerTick()
	return TimerTick;
end



--[[
	Debugging functions
	Added in: 0.3.0
--]]
function Buffalo_AddDebugFunction(functionName)
	functionName = Buffalo_CreateFunctionName(functionName);
	echo(string.format("%s added to debugging list.", functionName));
	DEBUG_FunctionList[functionName] = true;
end;

function Buffalo_RemoveDebugFunction(functionName)
	functionName = Buffalo_CreateFunctionName(functionName);
	echo(string.format("%s removed from debugging list.", functionName));
	DEBUG_FunctionList[functionName] = nil;
end;

function Buffalo_ListDebugFunctions()
	echo("Debugging list:");
	for functionName in next, DEBUG_FunctionList do
		echo("> "..functionName);
	end;
end;

function Buffalo_CreateFunctionName(functionName)
	return "BUFFALO_" .. string.upper(functionName);
end;


--[[
	Event Handlers
--]]
function Buffalo_OnEvent(self, event, ...)
	local timerTick = Buffalo_GetTimerTick();

	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == BUFFALO_NAME then
			Buffalo_MainInitialization();
			Buffalo_RepositionateButton(BuffButton);
			Buffalo_HideBuffButton();
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

	_G["BuffaloVersionString"]:SetText(string.format("Buffalo version %s by %s", GetAddOnMetadata(BUFFALO_NAME, "Version"), GetAddOnMetadata(BUFFALO_NAME, "Author")));

    BuffaloEventFrame:RegisterEvent("ADDON_LOADED");
    BuffaloEventFrame:RegisterEvent("CHAT_MSG_ADDON");

	C_ChatInfo.RegisterAddonMessagePrefix(BUFFALO_MESSAGE_PREFIX);
end

function Buffalo_OnTimer(elapsed)
	TimerTick = TimerTick + elapsed

	if TimerTick > (NextScanTime + CONFIG_ScanFrequency) then
		Buffalo_ScanRaid();
		NextScanTime = TimerTick;
	end;

	if not Buffalo_InitializationComplete and TimerTick > Buffalo_InitializationRetryTimer then
		Buffalo_MainInitialization();
	end;

end


