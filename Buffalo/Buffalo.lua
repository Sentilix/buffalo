--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo.lua
--	Desc:	Core functionality: addon framework, event handling etc.
--]]

Buffalo = select(2, ...)

local addonMetadata = {
	["ADDONNAME"]		= "Buffalo",
	["SHORTNAME"]		= "BUFFALO",
	["PREFIX"]			= "BuffaloV1",
	["NORMALCHATCOLOR"]	= "E0C020",
	["HOTCHATCOLOR"]	= "F8F8F8",
};
local A = DigamAddonLib:new(addonMetadata);

Buffalo.lib = A;

Buffalo.SyncUnused								= "(None)";
Buffalo.Version									= 0;

--	Note: This is NOT persisted. We want players to always be in 
--	PERSONAL mode unless specified otherwise (aka: in a raid!)
Buffalo.vars = { };
Buffalo.vars.CurrentRaidMode					= Buffalo.raidmodes.Personal;
Buffalo.vars.RaidModeLockedBy					= "";
Buffalo.vars.RaidModeQueryDone					= false;
Buffalo.vars.BuffButtonLastTexture				= "";
Buffalo.vars.PersonalBuffFrameHeight			= 0;
Buffalo.vars.RaidBuffFrameHeight				= 0;

--	Internal variables
Buffalo.vars.PlayerIsBuffClass					= false;
Buffalo.vars.PlayerNameAndRealm					= "";
Buffalo.vars.PlayerClass						= UnitClass("player");
Buffalo.vars.PlayerFaction						= UnitFactionGroup("player");

Buffalo.vars.InitializationComplete				= false;
Buffalo.vars.InitializationRetryTimer			= 0;
Buffalo.vars.UpdateMessageShown					= false;
Buffalo.vars.TimerTick							= 0
Buffalo.vars.NextScanTime						= 0;
Buffalo.vars.LastBuffTarget						= "";
Buffalo.vars.LastBuffStatus						= "";
Buffalo.vars.LastBuffFired						= nil;
Buffalo.vars.SyncClass							= nil;
Buffalo.vars.SyncBuff							= nil;
Buffalo.vars.SyncGroup							= nil;

Buffalo.vars.OrderedBuffGroups					= { };		-- [buff index] = { PRIORITY, NAME, MASK, ICONID } 


-- Configuration:
--	Loaded options:	{realmname}{playername}{parameter}
--	TODO: Move into Buffalo object?
Buffalo_Options = { }


--	Dropdown menu for Healer (add/replace healer) selection:
Buffalo.vars.SyncBuffGroupDropdownMenu = CreateFrame("FRAME", "BuffaloSyncFrameBuff", UIParent, "UIDropDownMenuTemplate");
Buffalo.vars.SyncBuffGroupDropdownMenu:SetPoint("CENTER");
Buffalo.vars.SyncBuffGroupDropdownMenu:Hide();
UIDropDownMenu_SetWidth(Buffalo.vars.SyncBuffGroupDropdownMenu, 1);
UIDropDownMenu_SetText(Buffalo.vars.SyncBuffGroupDropdownMenu, "");

UIDropDownMenu_Initialize(Buffalo.vars.SyncBuffGroupDropdownMenu, function(self, level, menuList)
	if Buffalo_buffGroupDropdownMenu_Initialize then
		Buffalo_buffGroupDropdownMenu_Initialize(self, level, menuList); 
	end;
end);


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
	elseif option == "RESETBUTTON" then
		SlashCmdList["BUFFALO_RESETBUTTON"]();
	elseif option == "ANNOUNCE" then
		SlashCmdList["BUFFALO_ANNOUNCE"]();
	elseif option == "STOPANNOUNCE" then
		SlashCmdList["BUFFALO_STOPANNOUNCE"]();
	elseif option == "VERSION" then
		SlashCmdList["BUFFALO_VERSION"]();
	else
		A:echo(string.format("Unknown command: %s", option));
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
	Buffalo:openConfigurationDialogue();
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
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonVisible, true);
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
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonVisible,false);
end

--[[
	Reset the buff button to screen center.
	Syntax: /buffalo resetbutton
	Added in: 5.0.0
]]
SLASH_BUFFALO_RESETBUTTON1 = "/buffaloresetbutton"
SlashCmdList["BUFFALO_RESETBUTTON"] = function(msg)

	BuffButton:ClearAllPoints();
	BuffButton:SetPoint("CENTER", "UIParent", "CENTER", 0, 0);
	BuffButton:SetSize(Buffalo.config.value.BuffButtonSize, Buffalo.config.value.BuffButtonSize);

	if Buffalo.config.value.BuffButtonVisible then
		BuffButton:Show();
	end;

	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonPosX, 0);
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonPosY, 0);

	A:echo("The Buffalo button has been reset.");
end

--[[
	Enable buff announcements (locally)
	Syntax: /buffaloannounce
	Alternative: /buffalo announce
	Added in: 0.3.0
]]
SLASH_BUFFALO_ANNOUNCE1 = "/buffaloannounce"
SlashCmdList["BUFFALO_ANNOUNCE"] = function(msg)
	Buffalo.config.value.AnnounceMissingBuff = true;
	Buffalo.config.value.AnnounceCompletedBuff = true;
	Buffalo.vars.LastBuffTarget = "";
	Buffalo.vars.LastBuffStatus = "";
	Buffalo:setConfigOption(Buffalo.config.key.AnnounceMissingBuff, Buffalo.config.value.AnnounceMissingBuff);
	Buffalo:setConfigOption(Buffalo.config.key.AnnounceCompletedBuff, Buffalo.config.value.AnnounceCompletedBuff);
	A:echo("Buff announcements are now ON.");
end

--[[
	Disable buff announcements (locally)
	Syntax: /buffalostopannounce
	Alternative: /buffalo stopannounce
	Added in: 0.3.0
]]
SLASH_BUFFALO_STOPANNOUNCE1 = "/buffalostopannounce"
SlashCmdList["BUFFALO_STOPANNOUNCE"] = function(msg)
	Buffalo.config.value.AnnounceMissingBuff = false;
	Buffalo.config.value.AnnounceCompletedBuff = false;
	Buffalo:setConfigOption(Buffalo.config.key.AnnounceMissingBuff, Buffalo.config.value.AnnounceMissingBuff);
	Buffalo:setConfigOption(Buffalo.config.key.AnnounceCompletedBuff, Buffalo.config.value.AnnounceCompletedBuff);
	A:echo("Buff announcements are now OFF.");
end

--[[
	Request client version information
	Syntax: /buffaloversion
	Alternative: /buffalo version
	Added in: 0.1.0
]]
SLASH_BUFFALO_VERSION1 = "/buffaloversion"
SlashCmdList["BUFFALO_VERSION"] = function(msg)
	if IsInRaid() or Buffalo:isInParty() then
		A:sendAddonMessage("TX_VERSION##");
	else
		A:echo(string.format("%s is using Buffalo version %s", GetUnitName("player", true), A.addonVersion));
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
		Buffalo:addDebugFunction(msg);
	else
		Buffalo:listDebugFunctions();
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
		Buffalo:removeDebugFunction(msg);
	else
		Buffalo:listDebugFunctions();
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
	A:echo(string.format("buffalo version %s options:", A.addonVersion));
	A:echo("Syntax:");
	A:echo("    /buffalo [command]");
	A:echo("Where commands can be:");
	A:echo("    Config       (default) Open the configuration dialogue. Same as right-clicking buff button.");
	A:echo("    Show         Shows the buff button.");
	A:echo("    Hide         Hides the buff button.");
	A:echo("    Announce     Announce when a buff is missing.");
	A:echo("    stopannounce Stop announcing missing buffs.");
	A:echo("    Version      Request version info from all clients.");
	A:echo("    Help         This help.");
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
function Buffalo:handleTXVersion(message, sender)
	A:sendAddonMessage("RX_VERSION#".. A.addonVersion .."#"..sender)
end

--[[
	A version response (RX) was received.
	The version information is displayed locally.
]]
function Buffalo:handleRXVersion(message, sender)
	A:echo(string.format("[%s] is using Buffalo version %s", sender, message))
end

function Buffalo:handleTXVerCheck(message, sender)
	Buffalo:checkIsNewVersion(message);
end


--[[
	RAIDMODE:

	The raidmode is broadcast to all clients of same class via the
	TX_RAIDMODE. There is no response for this.
	request:
		TX_RAIDMODE#<raidmode>#<classname>

	Any changes in the raid assignments are sent to all clients of
	same class via the TX_RDUPDATE. There is no response for this.
	request:
		TX_RDUPDATE#<buffIndex>/<groupIndex>/<playername>#<classname>
		
	Request current raidmode. All  client of same class should respond 
	current raidmode back. Until then, current client will use raid mode 0.
	This is used when a client enters raid, relog or reloads UI.
		TX_QRYRAIDMODE##<classname>
		RX_QRYRAIDMODE#<raid mode>/<lock owner>#<recipient=myself>
		
	Request Raid Assignments. Called after a RX_QRYRAIDMODE is returned.
		TX_QRYRAIDASSIGNMENTS##<promoted sender>
	Response: List of (one per group):
		RX_QRYRAIDASSIGNMENTS#<groupIndex>/<buffer 2>/<buffer 2>/<buffer 3>#sender


--]]
function Buffalo:handleAddonMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	

	--	Ignore messages sent from myself, unless it is a Version check (*sigh*)
	if sender == Buffalo.vars.PlayerNameAndRealm then
		if cmd ~= "TX_VERSION" and cmd ~= "RX_VERSION" then
			return;
		end;
	end;

	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if recipient ~= "" then
		--	Buffalo-specific: Recipient can also be a classname.
		if recipient == Buffalo.vars.PlayerClass then
			--	This is for me (a class-specific message);
		else
			--	Check if this is for me - if not, skip!
			-- Recipient comes with realmname, so we need to compare with realmname too:
			recipient = Buffalo:getPlayerAndRealmFromName(recipient);

			if recipient ~= Buffalo.vars.PlayerNameAndRealm then
				return
			end
		end;
	end

	if cmd == "TX_VERSION" then
		Buffalo:handleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		Buffalo:handleRXVersion(message, sender)
	elseif cmd == "TX_VERCHECK" then
		Buffalo:handleTXVerCheck(message, sender)

	elseif cmd == "TX_RAIDMODE" then
		Buffalo:handleTXRaidMode(message, sender);
	elseif cmd == "TX_RDUPDATE" then
		Buffalo:handleTXRdUpdate(message, sender);
	elseif cmd == "TX_QRYRAIDMODE" then
		Buffalo:handleTXQueryRaidMode(message, sender);
	elseif cmd == "RX_QRYRAIDMODE" then
		Buffalo:handleRXQueryRaidMode(message, sender);
	elseif cmd == "TX_QRYRAIDASSIGNMENTS" then
		Buffalo:handleTXQueryRaidAssignments(message, sender);
	elseif cmd == "RX_QRYRAIDASSIGNMENTS" then
		Buffalo:handleRXQueryRaidAssignments(message, sender);
	end
end

function Buffalo:onChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;

	if prefix == A.addonPrefix then
		Buffalo:handleAddonMessage(msg, sender);
	end
end



--[[
	Misc. helper functions
--]]

--	Convert a msg so first letter is uppercase, and rest as lower case.
function Buffalo:upperCaseFirst(playername)
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

function Buffalo:calculateVersion(versionString)
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
	end
	
	return version;
end

function Buffalo:checkIsNewVersion(versionstring)
	local incomingVersion = Buffalo:calculateVersion( versionstring );

	if (Buffalo.Version > 0 and incomingVersion > 0) then
		if incomingVersion > Buffalo.Version then
			if not Buffalo.vars.UpdateMessageShown then
				Buffalo.vars.UpdateMessageShown = true;
				A:echo(string.format("NOTE: A newer version of ".. A.charColorHot .."BUFFALO".. A.chatColorNormal .."! is available (version %s)!", versionstring));
				A:echo("You can download latest version from https://www.curseforge.com/ or https://github.com/Sentilix/buffalo.");
			end
		end	
	end
end

function Buffalo:isInParty()
	if not IsInRaid() then
		return ( GetNumGroupMembers() > 0 );
	end
	return false
end

function Buffalo:getMyRealm()
	local realmname = GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

function Buffalo:getPlayerAndRealm(unitid)
	local playername, realmname = UnitName(unitid);
	if not realmname or realmname == "" then
		realmname = Buffalo:getMyRealm();
	end;

	return playername.."-".. realmname;
end;

function Buffalo:getPlayerAndRealmFromName(playername)
	if not string.find(playername, "-") then
		playername = playername .."-".. Buffalo:getMyRealm();
	end;

	return playername;
end;



--[[
	Configuration functions
--]]
function Buffalo:getConfigOption(parameter, defaultValue)
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

function Buffalo:setConfigOption(parameter, value)
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



--[[
	Initialization
--]]
function Buffalo:initializeConfigSettings()
	if not Buffalo_Options then
		Buffalo_options = { };
	end

	local x,y = BuffButton:GetPoint();
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonPosX, Buffalo:getConfigOption(Buffalo.config.key.BuffButtonPosX, x))
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonPosY, Buffalo:getConfigOption(Buffalo.config.key.BuffButtonPosY, y))

	local value = Buffalo:getConfigOption(Buffalo.config.key.BuffButtonVisible, Buffalo.config.default.BuffButtonVisible);
	if type(value) == "boolean" then
		Buffalo.config.value.BuffButtonVisible = value;
	else
		Buffalo.config.value.BuffButtonVisible = Buffalo.config.default.BuffButtonVisible;
	end;
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonVisible, Buffalo.config.value.BuffButtonVisible);

	Buffalo.config.value.ScanFrequency = Buffalo:getConfigOption(Buffalo.config.key.ScanFrequency, Buffalo.config.default.ScanFrequency);
	if Buffalo.config.value.ScanFrequency < 0.1 or Buffalo.config.value.ScanFrequency > 1 then
		Buffalo.config.value.ScanFrequency = Buffalo.config.default.ScanFrequency;
	end;
	Buffalo:setConfigOption(Buffalo.config.key.ScanFrequency, Buffalo.config.value.ScanFrequency);

	Buffalo.config.value.ButtonOpacity = Buffalo:getConfigOption(Buffalo.config.key.ButtonOpacity, Buffalo.config.default.ButtonOpacity);
	if Buffalo.config.value.ButtonOpacity == nil or Buffalo.config.value.ButtonOpacity < 0.0 or Buffalo.config.value.ButtonOpacity > 1.0 then
		Buffalo.config.value.ButtonOpacity = Buffalo.config.default.ButtonOpacity;
	end;
	Buffalo:setConfigOption(Buffalo.config.key.ButtonOpacity, Buffalo.config.value.ButtonOpacity);

	Buffalo.config.value.RenewOverlap = Buffalo:getConfigOption(Buffalo.config.key.RenewOverlap, Buffalo.config.default.RenewOverlap);
	if Buffalo.config.value.RenewOverlap < 0 or Buffalo.config.value.RenewOverlap > 120 then
		Buffalo.config.value.RenewOverlap = Buffalo.config.default.RenewOverlap;
	end;
	Buffalo:setConfigOption(Buffalo.config.key.RenewOverlap, Buffalo.config.value.RenewOverlap);

	Buffalo.config.value.GroupBuffThreshold = Buffalo:getConfigOption(Buffalo.config.key.GroupBuffThreshold, Buffalo.config.default.GroupBuffThreshold);
	if Buffalo.config.value.GroupBuffThreshold < 1 or Buffalo.config.value.GroupBuffThreshold > 6 then
		Buffalo.config.value.GroupBuffThreshold = Buffalo.config.default.GroupBuffThreshold;
	end;
	Buffalo:setConfigOption(Buffalo.config.key.GroupBuffThreshold, Buffalo.config.value.GroupBuffThreshold);

	if Buffalo.config.value.BuffButtonVisible then
		BuffButton:Show();
	else
		BuffButton:Hide()
	end

	--	Init the "assigned buff groups". This is a table, so we need to validate the integrity:
	local assignedBuffGroups = Buffalo:getConfigOption(Buffalo.config.key.AssignedBuffGroups, nil);
	if type(assignedBuffGroups) == "table" and table.getn(assignedBuffGroups) == 8 then
		Buffalo.config.default.AssignedBuffGroups = { }
		for groupNum = 1, 8, 1 do
			local groupMask = 0;
			if assignedBuffGroups[groupNum] then
				groupMask = assignedBuffGroups[groupNum];
			end;

			Buffalo.config.value.AssignedBuffGroups[groupNum] = tonumber(groupMask);
		end;
	else
		--	Use the default assignments for my class: most important buffs in ALL groups:
		Buffalo.config.value.AssignedBuffGroups = Buffalo:initializeAssignedGroupDefaults();
	end;
	Buffalo:setConfigOption(Buffalo.config.key.AssignedBuffGroups, Buffalo.config.value.AssignedBuffGroups);

	--	Read SyncBuffsfrom Config! initialized a bit later with defaults.
	local syncBuffTable = { };
	local failureDetected = false;
	local syncedBuffs = Buffalo:getConfigOption(Buffalo.config.key.SynchronizedBuffs, nil);

	if type(syncedBuffs) == "table" then
		for buffIndex = 1, table.getn(syncedBuffs), 1 do
			if type(syncedBuffs[buffIndex]) ~= "table" then
				failureDetected = true;
				break;
			end;

			syncBuffTable[buffIndex] = { };
			
			for groupIndex = 1, table.getn(syncedBuffs[buffIndex]), 1 do
				if not syncedBuffs[buffIndex][groupIndex] then
					failureDetected = true;
					break;
				end;

				local buffname = syncedBuffs[buffIndex][groupIndex]["BUFFNAME"];
				local bitmask = syncedBuffs[buffIndex][groupIndex]["BITMASK"];
				local player = syncedBuffs[buffIndex][groupIndex]["PLAYER"];
				if type(buffname) ~= "string" or type(bitmask) ~= "string" then
					failureDetected = true;
					break;
				end;

				syncBuffTable[buffIndex][groupIndex] = {
					["BUFFNAME"] = buffname,
					["BITMASK"] = bitmask,
					["PLAYER"] = player,
				}
			end;
		end;
	end;
	Buffalo.config.value.SynchronizedBuffs = { };
	if not failureDetected and table.getn(syncBuffTable) > 0 then
		Buffalo.config.value.SynchronizedBuffs = syncBuffTable;
	end;


	Buffalo.config.value.AssignedClasses = Buffalo:getConfigOption(Buffalo.config.key.AssignedClasses, Buffalo.config.default.AssignedClasses)
	
	Buffalo.config.value.AssignedBuffSelf = Buffalo:getConfigOption(Buffalo.config.key.AssignedBuffSelf, Buffalo.config.default.AssignedBuffSelf);
	Buffalo:setConfigOption(Buffalo.config.key.AssignedBuffSelf, Buffalo.config.value.AssignedBuffSelf);

	Buffalo.config.value.AnnounceMissingBuff = Buffalo:getConfigOption(Buffalo.config.key.AnnounceMissingBuff, Buffalo.config.default.AnnounceMissingBuff);
	Buffalo:setConfigOption(Buffalo.config.key.AnnounceMissingBuff, Buffalo.config.value.AnnounceMissingBuff);

	Buffalo.config.value.AnnounceCompletedBuff = Buffalo:getConfigOption(Buffalo.config.key.AnnounceCompletedBuff, Buffalo.config.default.AnnounceCompletedBuff);
	Buffalo:setConfigOption(Buffalo.config.key.AnnounceCompletedBuff, Buffalo.config.value.AnnounceCompletedBuff);

	Buffalo.config.value.UseIncubus = Buffalo:getConfigOption(Buffalo.config.key.UseIncubus, Buffalo.config.default.UseIncubus);
	Buffalo:setConfigOption(Buffalo.config.key.UseIncubus, Buffalo.config.value.UseIncubus);
end


--[[
	Generate a class matrix, based on the current expansion level.
	Buffalo.matrix.Class represented in a table ordered by Classname.
	Usefull when doing classname lookups.
	Added in 0.4.0
--]]
function Buffalo:initializeClasses()
	Buffalo.classmasks.Selected = 0x0000;

	local expacKey = "AllianceExpac";
	if Buffalo.vars.PlayerFaction == "Horde" then
		expacKey = "HordeExpac";
	end;

	for className, classInfo in next, Buffalo.classes do
		if className ~= "shared" then
			classInfo.Enabled = nil;
			if not classInfo[expacKey] or classInfo[expacKey] <= A.addonExpansionLevel then
				classInfo.Enabled = true;

				Buffalo.classmasks.Selected = bit.bor(Buffalo.classmasks.Selected, classInfo.Mask);
			end;
		end;
	end;

	--	Update the SortOrder indexed version as well:
	Buffalo:sortClasses();
end;

--[[
	Generate array of Classes with a Buff mask each.
	If the array already exists, info is preserved. This is
	so we can load the array from settings.
--]]
function Buffalo:initializeClassBuffs()
	if not Buffalo.config.value.AssignedClasses then
		Buffalo.config.value.AssignedClasses = { };
	end;

	for className, classInfo in next, Buffalo.classes do
		if className ~= "shared" then
			if not Buffalo.config.value.AssignedClasses[className] then
				--	The setting for this class does not exist.
				--	Create one by looking at the matrix defaults.
				local classMask = 0;
				for _, spellInfo in next, Buffalo.spells.active do

					if bit.band(classInfo.Mask, spellInfo.Classmask) > 0 then
						--	Strip off selfie buffs:
						local buffMask = bit.band(spellInfo.Bitmask, 0x00ff);
						classMask = bit.bor(classMask, buffMask);
					end;
				end;
				Buffalo.config.value.AssignedClasses[className] = classMask;
			end;
		end;
	end;
	
	Buffalo:setConfigOption(Buffalo.config.key.AssignedClasses, Buffalo.config.value.AssignedClasses);
end;


function Buffalo:mainInitialization(reloaded)
	Buffalo.vars.CurrentRaidMode = Buffalo.raidmodes.Personal;
	Buffalo:initializeConfigSettings();

	--	Time to update the MATRIX!
	Buffalo:updateSpellMatrix();

	if not reloaded then
		if #Buffalo.spells.active == 0 then
			--	This can fail if wow havent loaded all objects yet.
			--	We just wait a couple of seconds and try again:
			Buffalo.vars.InitializationRetryTimer = Buffalo.vars.TimerTick + 5;
			return;
		end;
	end;

	Buffalo:updateGroupBuffs();
	Buffalo:updateGroupBuffs(true);


	--	This set all eligible classes to Enabled=true:
	Buffalo:initializeClasses();

	Buffalo:initializeClassBuffs();

	Buffalo:initializeBuffSettingsUI(true);
	Buffalo:updateGroupBuffUI();
	Buffalo:refreshClassSettingsUI();

	--	Note: setting defaults should be part of the config, but at that time
	--	the Buffalo_InitializeBuffSync() has not yet been called.
	if table.getn(Buffalo.config.value.SynchronizedBuffs) == 0 then
		for buffIndex = 1, #Buffalo.vars.OrderedBuffGroups, 1 do
			Buffalo.config.value.SynchronizedBuffs[buffIndex] = { };
			for groupIndex = 1, 8, 1 do
				Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex] = {   
					["BUFFNAME"] = Buffalo.vars.OrderedBuffGroups[buffIndex].name,
					["BITMASK"] = Buffalo.vars.OrderedBuffGroups[buffIndex].bitmask,
					["ICONID"] =  Buffalo.vars.OrderedBuffGroups[buffIndex].iconid,
					["PLAYER"] = nil,
				};
			end;
		end;
	end;
	Buffalo:setConfigOption(Buffalo.config.key.SynchronizedBuffs, Buffalo.config.value.SynchronizedBuffs);

	Buffalo:requestRaidModeUpdate();

	--	Expansion-specific settings.
	Buffalo.vars.PlayerIsBuffClass = false;
	if A.addonExpansionLevel == 1 or A.addonExpansionLevel == 2 or A.addonExpansionLevel == 3 then
		--	Check if the current class can cast buffs.
		--	Note: herbing/mining is excluded via the 0x00ff mask:
		for buffName, buffInfo in next, Buffalo.spells.active do
			if bit.band(buffInfo.Bitmask, 0x00ff) > 0 then
				Buffalo.vars.PlayerIsBuffClass = true;
				break;
			end;
		end;
	end;

	if Buffalo.vars.PlayerIsBuffClass and Buffalo.config.value.BuffButtonVisible then
		BuffButton:Show();
	else
		BuffButton:Hide();
	end;

	Buffalo.vars.InitializationComplete = true;

	if Buffalo.config.value.AnnounceMissingBuff and Buffalo.vars.PlayerIsBuffClass then
		A:echo("Buff data loaded, Buffalo is ready.");
	end;
end;

function Buffalo:filterTable(input, filterFunction)
	local output = {};
	for key, value in pairs(input) do
		if filterFunction(value) then
			output[key] = value;
		end
	end
	return output;
end;



--[[
	Raid scanner
--]]
function Buffalo:scanRaid()
	local debug = Buffalo.debug.Functions["Buffalo:scanRaid"];

	if not Buffalo.vars.PlayerIsBuffClass or not Buffalo.vars.InitializationComplete then
		return;
	end;

	--	If we're in combat, set Combat icon and skip scan.
	if UnitAffectingCombat("player") then
		Buffalo:setButtonTexture(Buffalo.ui.icons.Combat);
		return;
	end;

	--	Likewise if player is dead (sigh)
	if UnitIsDeadOrGhost("player") then
		Buffalo:setButtonTexture(Buffalo.ui.icons.PlayerIsDead);
		return;
	end;

	
	--	Generate a party/raid/solo roster with meta info per character:
	local roster = { };
	local startNum, endNum, groupType, unitid, groupCount;

	if Buffalo:isInParty() then
		groupType = "party";
		groupCount = 1;
		startNum = 1;
		endNum = GetNumGroupMembers();
	elseif IsInRaid() then
		groupType = "raid";
		groupCount = 8;
		startNum = 1;
		endNum = GetNumGroupMembers();
	else
		groupType = "solo";
		groupCount = 1;
		startNum = 0;
		endNum = 0
	end;

	--	Part 1:
	--	This generate a roster{} array based on unitid to find group, buffmask etc:
	local playername = UnitName("player");
	local currentUnitid = "player";
	if groupType == "solo" then
		unitid = "player"
		roster[unitid] = Buffalo:getUnitRosterEntry(unitid, 1)

	elseif groupType == "party" then
		-- Get Players and pets in party
		unitid = "player";
		roster[unitid] = Buffalo:getUnitRosterEntry(unitid, 1);
		for raidIndex = startNum, endNum, 1 do

			unitid = groupType..raidIndex;
			roster[unitid] = Buffalo:getUnitRosterEntry(unitid, 1);
			-- No need to check pet for non-existing player
			if roster[unitid] then
				unitid = groupType .. "pet" .. raidIndex;
				roster[unitid] = Buffalo:getUnitRosterEntry(unitid, 1);
			end;
		end;

	else	-- Raid
		for raidIndex = 1, 40, 1 do
			local name, rank, subgroup, level, _, filename, zone, online, dead, role, isML = GetRaidRosterInfo(raidIndex);
			if name then
				unitid = "raid"..raidIndex;
				roster[unitid] = Buffalo:getUnitRosterEntry(unitid, subgroup, online, dead);

				-- No need to check pet for non-existing player
				if roster[unitid] then
					-- Save unitid on current player:
					if name == playername then
						currentUnitid = unitid;
					end;

					--	Only support Hunter pets for now; Lock pets are a bit more restricted when it comes to buffing!
					local _, currentClass = UnitClass(unitid);
					if currentClass == "HUNTER" then
						unitid = groupType .. "pet" .. raidIndex;
						roster[unitid] = Buffalo:getUnitRosterEntry(unitid, subgroup);
					end;
				end;
			end;
		end;
	end;

	local currentTime = GetTime();

	local assignedGroups = Buffalo.config.value.AssignedBuffGroups;
	if Buffalo.vars.CurrentRaidMode ~= Buffalo.raidmodes.Personal then
		assignedGroups = Buffalo.config.value.AssignedRaidGroups;
	end;


	--	Part 2:
	--	This iterate over all players in party/raid and set the bitmapped buff mask on each
	--	applicable (i.e. not dead, not disconnected) player.
	local binValue;	
	for unitid, rosterInfo in next, roster do
		local buffMask = 0;

		--	This skips scanning for dead, offliners and people not in my group:
		local scanPlayerBuffs = true;
		local groupMask = bit.bor(assignedGroups[rosterInfo["Group"]], Buffalo.config.value.AssignedBuffSelf);
		if groupMask == 0 then					-- No buffs assigned: skip this group!
			scanPlayerBuffs = false;
		elseif not rosterInfo["IsOnline"] then
			scanPlayerBuffs = false;
		elseif rosterInfo["IsDead"] then
			scanPlayerBuffs = false;
		end;
			
		if scanPlayerBuffs then
			for buffIndex = 1, 40, 1 do
				local buffName, iconID, _, _, duration, expirationTime = UnitBuff(unitid, buffIndex, "CANCELABLE");
				if not buffName then break; end;

				local buffInfo = Buffalo.spells.active[buffName];
				if buffInfo and buffInfo.Enabled then
					if expirationTime and duration > 0 then
						local timeOverlap = Buffalo.config.value.RenewOverlap;
						if duration <= 60 and timeOverlap > 10 then 
							--	For short buffs (<1m): Only allow up to 10 seconds overlap (example: mage armor)
							timeOverlap = 10; 
						elseif duration <= 300 and timeOverlap > 30 then 
							--	For medium buffs (<5m): Only allow up to 30 seconds overlap (example: pala single blessings)
							timeOverlap = 30; 
						elseif duration <= 900 and timeOverlap > 60 then 
							--	For semi-long buffs (<15m): Only allow up to 60 seconds overlap (example: thorns, pala greater blessings)
							timeOverlap = 60; 
						end;

						renewTime = expirationTime - timeOverlap;

						if renewTime > currentTime then
							buffMask = bit.bor(buffMask, buffInfo.Bitmask);
						else
							--	Set expirationTime on roster object so we can check the time later on:
							local renewName = buffName;
							if buffInfo.Single then 
								renewName = buffInfo.Single;
							end;

							if not roster[unitid] then 
								roster[unitid] = { }; 
							end;
							roster[unitid][renewName] = expirationTime;
						end;
					else
						buffMask = bit.bor(buffMask, buffInfo.Bitmask);
					end;
				end;
			end

			--	Add tracking icons ("Find Herbs", "Find Minerals" ...).
			--	Methods differs between classic (1.x / 2.5) and tbc/wotlk (2.4/3.4):
			if A.addonExpansionLevel < 3 then
				--	Classic:
				--	Possible problem: Documentation does not state wether the returned name is localized or not.
				--	All examples shows English names, so going for that until I know better ...
				local trackingIcon = GetTrackingTexture();
				for buffName, buffInfo in next, Buffalo.spells.active do
					if buffInfo.Enabled and buffInfo.IconID == trackingIcon then
						--A.echo(string.format("<CLASSIC> Adding TrackingIcon buff:%s, mask:%s", buffName, buffInfo["BITMASK"]));
						buffMask = bit.bor(buffMask, buffInfo.Bitmask);
					end;
				end;
			--elseif A.addonExpansionLevel > 1 then
			--	--	TBC classic (2.5.4) / WOTLK:
			--	for n=1, GetNumTrackingTypes() do
			--		local buffName, spellID, active = GetTrackingInfo(n);
			--		if active then
			--			buffInfo = Buffalo.spells.active[buffName];
			--			if buffInfo and buffInfo.Enabled then
			--				--echo(string.format("<TBC> Adding TrackingIcon buff:%s, mask:%s", buffName, buffInfo["BITMASK"]));
			--				buffMask = bit.bor(buffMask, buffInfo.Bitmask);
			--			end;
			--		end;
			--	end;
			end;

			--	Warlock pets:
			local petType = UnitCreatureFamily('pet');
			if petType == 'Imp' then
				buffMask = bit.bor(buffMask, 0x000400);
			elseif petType == 'Voidwalker' then
				buffMask = bit.bor(buffMask, 0x000800);
			elseif petType == 'Felhunter' then
				buffMask = bit.bor(buffMask, 0x001000);
			elseif (petType == 'Succubus' or petType == 'Incubus') then
				buffMask = bit.bor(buffMask, 0x002000);
			end;
			
			--	This can be nil when new people joins while scanning is done:
			if not roster[unitid] then
				roster[unitid] = { };
			end;
			--	Each unitid is now set with a buffMask: a bitmask containing the buffs they currently have.
			roster[unitid].BuffMask = buffMask;
		end;		
	end;


	--	Part 3: Identify which buffs are missing.
	--
	--	Run over Groups -> Buffs -> UnitIDs
	--	Result: { unitid, buffname, iconid, priority }
	local unitname;
	local MissingBuffs = { };				-- Final list of all missing buffs with a Priority set.
	local missingBuffIndex = 0;				-- Buff counter
	local castingPlayerAndRealm = Buffalo:getPlayerAndRealm("player");

	--	Raid buffs:
	for groupIndex = 1, groupCount, 1 do	-- Iterate over all available groups
		local groupMask = assignedGroups[groupIndex] or 0;

		local filterFunction = function(entry)
			return entry.Group == groupIndex;
		end;

		--	If groupMask is 0 then this group does not have any buffs to apply.
		if groupMask > 0 then
			--	Search through the buffs, and count each buff per group and unit combo:
			for buffName, buffInfo in next, Buffalo.spells.active do
				--A:echo(string.format("Buff=%s, group=%d, gmask=%d", buffName, groupIndex, groupMask));

				if buffInfo.Enabled then
					local buffMissingCounter = 0;		-- No buffs detected so far.
					local groupMemberCounter = 0;		-- Total # of units in group.
					local MissingBuffsInGroup = { };	-- No units missing buffs in group (yet).

					--	Skip buffs which we haven't committed to do. That includes GREATER/PRAYER buffs:
					if(bit.band(buffInfo.Bitmask, groupMask) > 0) and not buffInfo.Group then
						--A:echo(string.format("Buff=%s, group=%d, gmask=%d", buffName, groupIndex, groupMask));
						local waitForCooldown = false;
						if buffInfo.Cooldown then
							local start, duration, enabled = GetSpellCooldown(buffName);
							waitForCooldown = (start > 3);
						end;
						if not waitForCooldown then
							--	Iterate over Party
							for unitid, rosterInfo in pairs(Buffalo:filterTable(roster, filterFunction)) do
								--	Check 1: Target must be online and alive:
								if rosterInfo and rosterInfo.IsOnline and not rosterInfo.IsDead then
									groupMemberCounter = groupMemberCounter + 1;
									
									-- Check 2: Target class must be eligible for buff:
									local classMask = Buffalo.config.value.AssignedClasses[rosterInfo.Class];							
									if (bit.band(classMask, buffInfo.Bitmask) > 0)	then
									
										--	Check 3: Target must be in range:
										if (buffInfo.IgnoreRangeCheck) or (IsSpellInRange(buffName, unitid) == 1) then 
										
											--	Check 4: There's a person alive in this group. Do he needs this specific buff?
											if (bit.band(rosterInfo.BuffMask, buffInfo.Bitmask) == 0) then
											
												--	Check 5: Missing buff detected! "Selfie" buffs are only available by current player, e.g. "Inner Fire":
												if	(bit.band(groupMask, buffInfo.Bitmask) > 0) then							-- Raid buff
													buffMissingCounter = buffMissingCounter + 1;
													local priority = buffInfo.Priority;
												
													local expirationTime = roster[unitid][buffName];
													if expirationTime then
														--	Set priority so first expiring buffs are selected first.
														local seconds = math.floor(expirationTime - currentTime);
														priority = priority - (50 + seconds);
													end;

													MissingBuffsInGroup[buffMissingCounter] = {
														['unitid']		= unitid, 
														['name']		= buffName, 
														['iconid']		= buffInfo.IconID, 
														['priority']	= priority, 
														['expTime']		= expirationTime 
													};
												
												end;
											end;
										end;
									end;
								end;
							end;	-- end iterate raid
						end;
					end;

					--	If this is a group buff, and enough people are missing it, use the big one instead!
					if buffInfo.Parent and buffMissingCounter >= Buffalo.config.value.GroupBuffThreshold then
						local parentBuffInfo = Buffalo.spells.active[buffInfo.Parent];
						if parentBuffInfo and parentBuffInfo.Enabled then
							local bufferUnitid = MissingBuffsInGroup[1].unitid;
							missingBuffIndex = missingBuffIndex + 1;
							local priority = parentBuffInfo.Priority + (buffMissingCounter / groupMemberCounter * 5) + groupMemberCounter;
							MissingBuffs[missingBuffIndex] = {
								['unitid']		= bufferUnitid, 
								['name']		= buffInfo.Parent, 
								['iconid']		= parentBuffInfo.IconID, 
								['priority']	= priority, 
								['expTime']		= 0 
							};
						end;
					else
						-- Use single target buffing:
						for missingIndex = 1, buffMissingCounter, 1 do
							missingBuffIndex = missingBuffIndex + 1;
							MissingBuffs[missingBuffIndex] = MissingBuffsInGroup[missingIndex];
						end;
					end;
				end;
			end;	-- end iterate buff matrix
		end;
	end;	--	End iterate raid groups


	--	Self buffs:
	if Buffalo.config.value.AssignedBuffSelf > 0 then
		--	Search through the buffs, and count each buff per group and unit combo:
		for buffName, buffInfo in next, Buffalo.spells.active do
			if buffInfo.Enabled then

				--	Skip buffs which we haven't committed to do. That includes GREATER/PRAYER buffs:
				if(bit.band(buffInfo.Bitmask, Buffalo.config.value.AssignedBuffSelf) > 0) and not buffInfo.Group then

					local waitForCooldown = false;
					if buffInfo.Cooldown then
						local start, duration, enabled = GetSpellCooldown(buffName);
						waitForCooldown = (start > 3);
					end;
					if not waitForCooldown then
						--	No cooldown (checking on GCD here as well)
						local rosterInfo = roster[currentUnitid];
	
						--	Check 1: Target must be online and alive:
						if rosterInfo and not rosterInfo.IsDead then

							--	Check 4: Target must be in range (and know the spell) (self buffs? We dont care about range!)
							--	Check 5: Do I needs this specific buff?
							if (bit.band(rosterInfo.BuffMask, buffInfo.Bitmask) == 0) then

								if (bit.band(Buffalo.config.value.AssignedBuffSelf, buffInfo.Bitmask) > 0) then
									missingBuffIndex = missingBuffIndex + 1;
									local priority = buffInfo.Priority;
									if not buffInfo.Group then
										--	Self buffs have prio, unless they can also be grouped.
										--	This is to avoid a Fort (single) self buffs overriding a Fort (group) buff in same group.
										priority = priority + Buffalo.config.value.PlayerBuffPriority;
									end;

									local expirationTime = rosterInfo[buffName];
									if expirationTime then
										--	Set priority so first expiring buffs are selected first.
										local seconds = math.floor(expirationTime - currentTime);
										priority = priority - (50 + seconds);
									end;

									MissingBuffs[missingBuffIndex] = { 
										['unitid']		= currentUnitid, 
										['name']		= buffName, 
										['iconid']		= buffInfo.IconID, 
										['priority']	= priority, 
										['expTime']		= expirationTime
									};
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
	if #MissingBuffs > 0 then
		--	Sort by Priority (descending order):
		table.sort(MissingBuffs, function (a, b) return a.priority > b.priority; end);

		--	Now pick first buff from list and set icon:
		local missingBuff = MissingBuffs[1];

		unitid = missingBuff.unitid;

		local buffName = missingBuff.name;
		if Buffalo.config.value.AnnounceMissingBuff then
			local targetPlayer = Buffalo:getPlayerAndRealm(unitid);
			local targetStatus = "MISSING";
			local expirationTime = missingBuff.expTime;

			if expirationTime and expirationTime > 0 then
				targetStatus = "RENEW";
			end;

			if Buffalo.vars.LastBuffTarget ~= targetPlayer..buffName or Buffalo.vars.LastBuffStatus ~= targetStatus then
				Buffalo.vars.LastBuffTarget = targetPlayer..buffName;
				Buffalo.vars.LastBuffStatus = targetStatus;

				if expirationTime and expirationTime > 0 then
					local seconds = math.ceil(expirationTime - currentTime);
					local minutes = math.floor(seconds / 60);
					seconds = seconds - minutes * 60;

					A:echo(string.format("%s's %s%s%s will expire in %02d:%02d.", targetPlayer, Buffalo.ui.colours.ExpiringBuff, buffName, A.chatColorNormal, minutes, seconds));
				else
					A:echo(string.format("%s is missing %s%s%s.", targetPlayer, Buffalo.ui.colours.MissingBuff, buffName, A.chatColorNormal));
				end;
			end;
		end;

		if debug then
			A:echo(string.format("DEBUG: Buffing unit=%s(%s), Buff=%s, Icon=%s", unitid, targetPlayer, buffName, missingBuff.iconid));
		end;

		Buffalo:updateBuffButton(unitid, buffName, missingBuff.iconid);
	else
		Buffalo:updateBuffButton();

		if Buffalo.config.value.AnnounceMissingBuff then
			if Buffalo.vars.LastBuffTarget ~= "" then
				A:echo("No pending buffs.");
				Buffalo.vars.LastBuffTarget = "";
				Buffalo.vars.LastBuffStatus = "";
			end;
		end;
	end;
end;


function Buffalo:getUnitRosterEntry(unitid, group, isOnline, isDead)
	if string.find(unitid, "pet") then
		local group = group or 1;
		local isOnline = isOnline or (0 and UnitIsConnected(unitid) and 1);
		local isDead   = isDead or (0 and UnitIsDead(unitid) and 1);
		local classname = "PET"
		if isOnline then
			return { ["Group"]=group, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["Class"]=classname, ["ClassMask"]=Buffalo.classes[classname].Mask };
		end;
	elseif unitid == "player" and group == 1 then
		return { ["Group"]=1, ["IsOnline"]=true, ["IsDead"]=nil, ["BuffMask"]=0, ["Class"]=Buffalo.vars.PlayerClass, ["ClassMask"]=Buffalo.classmasks.ALL };
	else
		local isOnline = 0 and UnitIsConnected(unitid) and 1;
		local isDead   = 0 and UnitIsDead(unitid) and 1;
		local _, classname = UnitClass(unitid);
	
		if classname then
			local classUpper = string.upper(classname);
			return { ["Group"]=group, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["Class"]=classUpper, ["ClassMask"]=Buffalo.classes[classname].Mask };
		end;
	end;
	return nil;
end;


--[[
	UI Control
--]]
function Buffalo:openConfigurationDialogue()
	Buffalo:updateGroupBuffUI();

	Buffalo:closeClassConfigDialogue();
	Buffalo:closeGeneralConfigDialogue();
	BuffaloConfigFrame:Show();
end;

function Buffalo:closeConfigurationDialogue()
	Buffalo:closeClassConfigDialogue();
	Buffalo:closeGeneralConfigDialogue();
	BuffaloConfigFrame:Hide();
end;

function Buffalo:openGeneralConfigDialogue()
	Buffalo:refreshGeneralSettingsUI();

	local bleft = BuffaloConfigFrame:GetLeft();
	local btop = BuffaloConfigFrame:GetTop();
	local bwidth, cwidth = BuffaloConfigFrame:GetWidth(), BuffaloGeneralConfigFrame:GetWidth();
	local bheight, cheight = BuffaloConfigFrame:GetHeight(), BuffaloGeneralConfigFrame:GetHeight();

	local height = btop - cheight + 20;
	local left = bleft + ((bwidth - cwidth) / 2);
	
	BuffaloGeneralConfigFrame:SetPoint("BOTTOMLEFT", left, height);
	BuffaloGeneralConfigFrame:Show();
end;

function Buffalo:closeGeneralConfigDialogue()
	BuffaloGeneralConfigFrame:Hide();
end;

function Buffalo:openClassConfigDialogue()
	Buffalo:refreshClassSettingsUI();

	local bleft, btop = BuffaloConfigFrame:GetLeft(), BuffaloConfigFrame:GetTop();
	local bwidth, cwidth = BuffaloConfigFrame:GetWidth(), BuffaloClassConfigFrame:GetWidth();
	local cheight = BuffaloClassConfigFrame:GetHeight();

	local height = btop - cheight - 30;
	local left = bleft + ((bwidth - cwidth) / 2);
	
	BuffaloClassConfigFrame:SetPoint("BOTTOMLEFT", left, height);
	BuffaloClassConfigFrame:Show();
end;

function Buffalo:closeClassConfigDialogue()
	BuffaloClassConfigFrame:Hide();
end;

function Buffalo_repositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonPosX, x);
	Buffalo:setConfigOption(Buffalo.config.key.BuffButtonPosY, y);
	BuffButton:SetSize(Buffalo.config.value.BuffButtonSize, Buffalo.config.value.BuffButtonSize);

	if Buffalo.vars.PlayerIsBuffClass then
		BuffButton:Show();
	else
		BuffButton:Hide();
	end;
end

function Buffalo:hideBuffButton()
	Buffalo:setButtonTexture(Buffalo.ui.icons.Passive);
	BuffButton:SetAttribute("type", nil);
	BuffButton:SetAttribute("unit", nil);
end;

function Buffalo:setButtonTexture(textureName, isEnabled)
	local alphaValue = 0.5;
	if isEnabled then
		alphaValue = 1.0;
	end;

	if Buffalo.vars.BuffButtonLastTexture ~= textureName then
		Buffalo.vars.BuffButtonLastTexture = textureName;

		BuffButton:SetAlpha(alphaValue * Buffalo.config.value.ButtonOpacity);
		BuffButton:SetNormalTexture(textureName);		
	end;
end;

function Buffalo:updateBuffButton(unitid, spellname, textureId)
	if unitid and not UnitAffectingCombat("player") then
		Buffalo:setButtonTexture(textureId, true);
		BuffButton:SetAttribute("*type1", "spell");
		BuffButton:SetAttribute("spell", spellname);
		BuffButton:SetAttribute("unit", unitid);
	else
		Buffalo:setButtonTexture(Buffalo.ui.icons.Passive);
		BuffButton:SetAttribute("*type1", "spell");
		BuffButton:SetAttribute("spell", nil);
		BuffButton:SetAttribute("unit", nil);
	end;
end;

function Buffalo_onBeforeBuffClick(self, ...)
	Buffalo.vars.LastBuffFired = BuffButton:GetAttribute("spell");
end;

function Buffalo_onAfterBuffClick(self, ...)
	local buttonName = ...;

	if buttonName == "RightButton" then
		Buffalo:openConfigurationDialogue();
	end;
end;

--	Initialize the overall buffing UI.
--	UI is split into PERSONAL and RAID buffing UI.
--	This function will initiate both, but the Update function
--	will only show the current active one.
--	NOTE:
--	Function will be called in case Talents are updated; therefore
--	we must re-use existing buttons and show/hide as needed.
function Buffalo:initializeBuffSettingsUI(firstTimeInitialization)
	local selfCount = #Buffalo.spells.personal;
	local activeBuffCount = 0;

	local posX, posY;

	--	We might be called during other events, but don't accept anything until ready:
	if not firstTimeInitialization and not Buffalo.vars.InitializationComplete then
		return;
	end;

	--	Labels etc. are only do during Initialization:
	if firstTimeInitialization then
		--	Generate Raid Mode buttons in top of screen:
		posX = Buffalo.ui.buffConfigDialog.Left;
		posY = Buffalo.ui.buffConfigDialog.Top - 40;
		for _, raidmode in next, Buffalo.raidmodes.setup do
			local buttonName = string.format("raidmode_%s", raidmode["RAIDMODE"]);
			local fButton = CreateFrame("Button", buttonName, BuffaloConfigFrame, "BuffaloBuffButtonTemplate");
			fButton:SetPoint("TOPLEFT", posX, posY);
			fButton:SetNormalTexture(raidmode["ICON"]);
			fButton:SetPushedTexture(raidmode["ICON"]);
			if raidmode["RAIDMODE"] == Buffalo.vars.CurrentRaidMode then
				fButton:SetAlpha(Buffalo.ui.alpha.Enabled);
			else
				fButton:SetAlpha(Buffalo.ui.alpha.Disabled);
			end;

			local fLabel = fButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
			fLabel:SetText(raidmode["CAPTION"]);
			fLabel:SetPoint("LEFT", 40, 0);
			fButton:SetScript("OnClick", Buffalo_onRaidModeClick);
			fButton:Show();

			posX = posX + Buffalo.ui.buffConfigDialog.ButtonWidth;
		end;

		--	Generate group labels:
		posX = Buffalo.ui.buffConfigDialog.Left;
		posY = Buffalo.ui.buffConfigDialog.Top - 80;
		for groupIndex = 1, 8, 1 do
			local labelName = string.format("buffgrouplabel_%s", groupIndex);
			local fLabel = BuffaloConfigFrame:CreateFontString(labelName, "ARTWORK", "GameFontNormal");
			fLabel:SetText(string.format("Group %s", groupIndex));
			fLabel:SetPoint("TOPLEFT", posX, posY);
			fLabel:SetTextColor(Buffalo.ui.colours.GroupLabels[1], Buffalo.ui.colours.GroupLabels[2], Buffalo.ui.colours.GroupLabels[3]);
	
			posX = posX + Buffalo.ui.buffConfigDialog.Width;
		end;

		--	SELF buffs, label:
		posX = 32;
		posY = -10;
		local fLabel = BuffaloConfigFrameSelf:CreateFontString("selfbufflabel", "ARTWORK", "GameFontNormal");
		fLabel:SetText("Self buffs");
		fLabel:SetPoint("TOPLEFT", posX, posY);
		fLabel:SetTextColor(Buffalo.ui.colours.GroupLabels[1], Buffalo.ui.colours.GroupLabels[2], Buffalo.ui.colours.GroupLabels[3]);
	end;

	Buffalo:initializePersonalGroupBuffs();
	Buffalo:initializeRaidGroupBuffs();


	--	Iterate over all buffs and render icons.
	posX = Buffalo.ui.buffConfigDialog.Left;
	posY = 0;
	for rowNumber = 1, selfCount, 1 do
		buttonName = string.format("buffalo_personal_buff_%d_0", rowNumber);
		local entry = _G[buttonName];
		if not entry then
			entry = CreateFrame("Button", buttonName, BuffaloConfigFrameSelf, "BuffaloGroupButtonTemplate");
			entry:SetNormalTexture(Buffalo.spells.personal[rowNumber].IconID);
			entry:SetPushedTexture(Buffalo.spells.personal[rowNumber].IconID);
		end;

		if Buffalo.spells.personal[rowNumber].Learned then
			entry:SetAlpha(Buffalo.ui.alpha.Disabled);
			entry:SetPoint("TOPLEFT", posX, posY);
			entry:Show();
			posX = posX + Buffalo.ui.buffConfigDialog.Width;
			activeBuffCount = activeBuffCount + 1;
		else
			entry:Hide();
		end
	end;

	buttonName = "BuffaloClassConfigFrameUseIncubus";	
	local checkBox = _G[buttonName];
	if not checkBox then
		checkBox = CreateFrame("CheckButton", buttonName, BuffaloConfigFrameSelf, "ChatConfigCheckButtonTemplate");
		checkBox:SetPoint("TOPLEFT", Buffalo.ui.buffConfigDialog.Left, -56);
		_G[checkBox:GetName().."Text"]:SetText("Use Incubus");
		checkBox:SetScript("OnClick", Buffalo_handleCheckbox);
	end;
	checkboxValue = nil;
	if Buffalo.config.value.UseIncubus then
		checkboxValue = 1;
	end;
	checkBox:SetChecked(checkboxValue);

	local _, className = UnitClass("player");
	if className == "WARLOCK" then
		checkBox:Show();
	else
		checkBox:Hide();
	end;

	--	Need to check if someone picked Incubus ...
	Buffalo:updateDemon();


	--	Class configuration:
	local colWidth = 40;				-- Width of each column.
	local rowHeight = 40;				-- Height of each row.
	local posX, posY, buffMask;

	--	Step 1:
	--	Display a row of Class icons (only during Initialization)
	posX = 0;
	posY = 0;
	if firstTimeInitialization then
		for className, classInfo in next, Buffalo.sorted.classes do
			buttonName = string.format("ClassImage%s", className);
			local entry = CreateFrame("Button", buttonName, BuffaloClassConfigFrameClass, "BuffaloClassButtonTemplate");
			entry:SetAlpha(Buffalo.ui.alpha.Enabled);
			entry:SetPoint("TOPLEFT", posX, posY);
			entry:SetNormalTexture(classInfo.IconID);
			entry:SetPushedTexture(classInfo.IconID);

			posX = posX + colWidth;
		end;
	end;


	--	Step 2 - ClassConfig dialogue:
	--	Display buff image for each buff+class combo:
	--	Counters include unlearned buffs as well, as we need to generate (but not show) the buttons.
	posY = 0;
	activeBuffCount = 0;
	local buffCount = #Buffalo.spells.group;
	for rowNumber = 1, buffCount, 1 do
		posX = 0;
		
		if Buffalo.spells.group[rowNumber].Learned then
			activeBuffCount = activeBuffCount + 1;
			posY = posY - rowHeight;
		end;
		
		for _, classInfo in next, Buffalo.sorted.classes do
			buttonName = string.format("%s_row%s", classInfo.ClassName, rowNumber);
			local entry = _G[buttonName];
			if not entry then
				entry = CreateFrame("Button", buttonName, BuffaloClassConfigFrameClass, "BuffaloBuffButtonTemplate");
				entry:SetNormalTexture(Buffalo.spells.group[rowNumber].IconID);
				entry:SetPushedTexture(Buffalo.spells.group[rowNumber].IconID);
			end;

			if Buffalo.spells.group[rowNumber].Learned then
				entry:SetAlpha(Buffalo.ui.alpha.Disabled);
				entry:SetPoint("TOPLEFT", 4+posX, posY);
				entry:Show();
			else
				entry:Hide();
			end;
			posX = posX + colWidth;
		end;
	end;
	
	--	Set windows size to fit icons for class config:
	BuffaloClassConfigFrame:SetHeight(128 + activeBuffCount * rowHeight);
	BuffaloClassConfigFrame:SetWidth(posX + 52);
	BuffaloClassConfigFrameHeaderTexture:SetWidth(2 * (posX + 52));

	Buffalo.vars.BuffingDialogReady = true;
end;

--[[
	Render the RaidBuff portion + labels and Icons for Personal buffing.
	Selfie buffs are rendered elsewhere.
--]]
function Buffalo:initializePersonalGroupBuffs()
	local posX, posY;

	--	RAID buffs:
	--	Iterate over all groups and render icons.
	--	Note: all icons are dimmed out as if they were disabled.
	--	We will refresh the alpha value after rendering.
	local buttonName;
	for groupNumber = 1, 8, 1 do
		posX = Buffalo.ui.buffConfigDialog.Left + Buffalo.ui.buffConfigDialog.Width * (groupNumber - 1);
		posY = Buffalo.ui.buffConfigDialog.Top - 20;
		for rowNumber = 1, #Buffalo.spells.group, 1 do
			local spellInfo = Buffalo.spells.group[rowNumber];

			--	Button to toggle all Row buffs:
			if groupNumber == 1 then
				buttonName = string.format("toggle_row_%d", rowNumber);
				local rowBtn = _G[buttonName];
				if not rowBtn then
					rowBtn = CreateFrame("Button", buttonName, BuffaloConfigFramePersonal, "BuffaloMiniButtonTemplate");
					rowBtn:SetNormalTexture(spellInfo.IconID);
					rowBtn:SetPushedTexture(spellInfo.IconID);
				end;
				rowBtn:SetPoint("TOPLEFT", posX - 60, posY-8);
				if spellInfo.Learned then
					rowBtn:Show();
				else
					rowBtn:Hide();
				end;
			end;

			--	One button per group - 8 in total per row:
			buttonName = string.format("buffalo_personal_buff_%d_%d", rowNumber, groupNumber);
			local entry = _G[buttonName];
			if not entry then
				entry = CreateFrame("Button", buttonName, BuffaloConfigFramePersonal, "BuffaloGroupButtonTemplate");
				entry:SetNormalTexture(spellInfo.IconID);
				entry:SetPushedTexture(spellInfo.IconID);
			end;
			entry:SetAlpha(Buffalo.ui.alpha.Disabled);
			entry:SetPoint("TOPLEFT", posX, posY);

			if spellInfo.Learned then
				entry:Show();
				posY = posY - Buffalo.ui.buffConfigDialog.Height;
			else
				entry:Hide();
			end;
		end;
	end;

	Buffalo.vars.PersonalBuffFrameHeight = posY * -1;
end;

function Buffalo:initializeRaidGroupBuffs()

	--	Iterate over all buffs for this class, and store result in a "temp" table
	--	so we do not do this every time we update also.
	--	Sync.Buffs = { priority, buffname, buffmask, iconid }
	Buffalo.vars.OrderedBuffGroups = { };
	for buffName, buffInfo in next, Buffalo.spells.active do
		if not buffInfo.Group and bit.band(buffInfo.Bitmask, 0x00ff) > 0 then
			tinsert(Buffalo.vars.OrderedBuffGroups, {
				['priority']	= buffInfo.Priority, 
				['name']		= buffName, 
				['bitmask']		= buffInfo.Bitmask,
				['iconid']		= buffInfo.IconID
			});
		end;
	end;

	--	And now in correct order (by priority):
	table.sort(Buffalo.vars.OrderedBuffGroups, function (a, b) return a.priority > b.priority; end);

	--	Render the buff icon, and thereby defining the final size of the frame:
	local posX = 32;
	local posY = Buffalo.ui.buffConfigDialog.Top - 20;
	for buffIndex = 1, #Buffalo.vars.OrderedBuffGroups, 1 do
		local buttonName = string.format("buffrow_%s", buffIndex);
		local fButton = _G[buttonName];
		if not fButton then
			fButton = CreateFrame("Button", buttonName, BuffaloConfigFrameRaid, "BuffaloBuffButtonTemplate");
		end;

		fButton:SetPoint("TOPLEFT", posX, posY);
		fButton:SetNormalTexture(Buffalo.vars.OrderedBuffGroups[buffIndex].iconid);
		fButton:SetPushedTexture(Buffalo.vars.OrderedBuffGroups[buffIndex].iconid);
		fButton:SetScript("OnClick", nil);
		fButton:Show();

		posY = posY - Buffalo.ui.buffConfigDialog.Height;
	end;

	Buffalo.vars.RaidBuffFrameHeight = -1 * posY;
	
	--	Now render frame buttons for all potential buffers.
	posY = Buffalo.ui.buffConfigDialog.Top - 20;
	for buffIndex = 1, #Buffalo.vars.OrderedBuffGroups, 1 do
		posX = Buffalo.ui.buffConfigDialog.Left;

		for groupIndex = 1, 8, 1 do
			local bufferName = string.format("buffgroup_%s_%s", buffIndex, groupIndex);
			local fBuffer = _G[bufferFrame];
			if not fBuffer then
				fBuffer = CreateFrame("Button", bufferName, BuffaloConfigFrameRaid, "GroupBuffTemplate");
			end;
			fBuffer:SetPoint("TOPLEFT", posX, posY);
			_G[bufferName.."Text"]:SetTextColor(Buffalo.ui.colours.Unused[1], Buffalo.ui.colours.Unused[2], Buffalo.ui.colours.Unused[3]);
			_G[bufferName.."Text"]:SetText(Buffalo.SyncUnused);
			fBuffer:Show();

			posX = posX + Buffalo.ui.buffConfigDialog.Width;
		end;
		posY = posY - Buffalo.ui.buffConfigDialog.Height;
	end;
end;

--	Switch raidmode:
--	Must be promoted to Switch
function Buffalo_onRaidModeClick(sender)
	local buttonName = sender:GetName();

	local _, _, raidmode = string.find(buttonName, "raidmode_(%d*)");
	if raidmode then
		raidmode = tonumber(raidmode);

		local unitIsPromoted = Buffalo:unitIsPromoted("player");

		--	Raidmode 1 and 2 may reqire promotions, so check both current and new mode:
		--	Scenario 1: We switch to raid mode 1 (raidmode=OPEN), or
		--	Scenario 2: We swithc FROM raid mode 1 (currentRM=OPEN):
		if raidmode == Buffalo.raidmodes.OpenRaid or Buffalo.vars.CurrentRaidMode == Buffalo.raidmodes.OpenRaid then
			if Buffalo.raidmodes.OpenRaidRequiresPromotion and not unitIsPromoted then
				A:echo("You cannot change raid mode unless you are promoted.");
				return;
			end;
		end;

		if raidmode == Buffalo.raidmodes.ClosedRaid or Buffalo.vars.CurrentRaidMode == Buffalo.raidmodes.ClosedRaid then
			if Buffalo.raidmodes.ClosedRaidRequiresPromotion and not unitIsPromoted then
				A:echo("You cannot change raid mode unless you are promoted.");
				return;
			end;
		end;

		if raidmode == Buffalo.raidmodes.Personal then
			Buffalo.vars.RaidModeLockedBy = "";
		else
			Buffalo.vars.RaidModeLockedBy = Buffalo.vars.PlayerNameAndRealm;
		end;

		Buffalo:setRaidMode(raidmode, true);
	end;

	Buffalo:updateGroupBuffUI();
end;

--	Change raidmode:
--	UI is updated, and if AnnounceRaidModeChange is set, a message is sent
--	to all other people of same class.
function Buffalo:setRaidMode(raidmode, AnnounceRaidModeChange)
	Buffalo.vars.CurrentRaidMode = tonumber(raidmode);

	if AnnounceRaidModeChange then
		A:sendAddonMessage(string.format("TX_RAIDMODE#%s#%s", raidmode, Buffalo.vars.PlayerClass));
	end;

	Buffalo:updateGroupBuffUI();
end;

--	Called when another client switches raid mode.
function Buffalo:handleTXRaidMode(message, sender)
	local raidmode = tonumber(message);

	if raidmode == Buffalo.raidmodes.Personal then
		Buffalo.vars.RaidModeLockedBy = "";
	else
		Buffalo.vars.RaidModeLockedBy = sender;
	end;

	if sender == Buffalo.vars.PlayerNameAndRealm then
		-- If sender is myself, no need to refresh or update again	
		return;
	end;

	Buffalo:setRaidMode(raidmode);

	if not Buffalo.raidmodes.DisplayRaidModeChanges then
		--	Displaying raid mode changes has been disabled.
		return;
	end;

	for _, rmInfo in next, Buffalo.raidmodes.setup do
		if rmInfo["RAIDMODE"] == raidmode then
			A:echo(string.format("[%s] changed raid mode to [%s].", sender, rmInfo["CAPTION"]));
			return;
		end;
	end;

	--	Oops, someone changed raid mode to a mode this client does not know!
	--	Can happen if a RaidMode3 is implemented, and the user does not upgrade!!
	A:echo(string.format("[%s] changed raid mode.", sender));
end;

--	TX_RDUPDATE: Called when another client updates the raid assignments.
function Buffalo:handleTXRdUpdate(message, sender)
	local _, _, buffIndex, groupIndex, playername = string.find(message, "([^/]*)/([^/]*)/([^/]*)");

	buffIndex = tonumber(buffIndex);
	groupIndex = tonumber(groupIndex);

	local buffInfo = Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex];	-- Assignment for a specific row + group
	if playername == "" then
		buffInfo["PLAYER"] = nil;
	else
		buffInfo["PLAYER"] = playername;
	end;

	Buffalo:updateGroupBuffUI();
end;

--	TX_QRYRAIDMODE:
--	If player is promoted, answer current raidmode back.
function Buffalo:handleTXQueryRaidMode(message, sender)
	A:sendAddonMessage(string.format("RX_QRYRAIDMODE#%s/%s#%s", Buffalo.vars.CurrentRaidMode, Buffalo.vars.RaidModeLockedBy, sender));
end;

--	RX_QRYRAIDMODE:
function Buffalo:handleRXQueryRaidMode(message, sender)
	local _, _, raidmode, lockedBy = string.find(message, "([^/]*)/([^/]*)");

	raidmode = tonumber(raidmode);
	if raidmode and (raidmode == Buffalo.raidmodes.OpenRaid or raidmode == Buffalo.raidmodes.ClosedRaid) then
		Buffalo:setRaidMode(raidmode);
		Buffalo.vars.RaidModeLockedBy = lockedBy or "";

		--	Now we got the raidmode solved, but we don't have the raid assignments yet.
		--	This time we know who to ask.
		--	However there is a potential problem here: 
		--	If more than one person whispers back we don't want to send requests to ALL
		--	of them, only the first one. 
		if not Buffalo.vars.RaidModeQueryDone then
			Buffalo.vars.RaidModeQueryDone = true;
			A:sendAddonMessage(string.format("TX_QRYRAIDASSIGNMENTS##%s", sender));
		end;

		Buffalo:updateGroupBuffUI();
	end;
end;

function Buffalo:requestRaidModeUpdate()
	if IsInRaid() then
		Buffalo.vars.RaidModeQueryDone = false;
		Buffalo:resetRaidAssignments();

		A:sendAddonMessage(string.format("TX_QRYRAIDMODE##%s", Buffalo.vars.PlayerClass));
	end;
end;

--	Send all assignments for current raid back to the requester.
function Buffalo:handleTXQueryRaidAssignments(message, sender)
	for groupIndex = 1, 8, 1 do
		local payload = string.format("%s", groupIndex);

		--	Note: We HAVE to set a name in the empty spots, otherwise string split later on fucks up:
		for buffIndex = 1, table.getn(Buffalo.config.value.SynchronizedBuffs), 1 do
			local syncBuff = Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex];
			local bufferName = syncBuff["PLAYER"] or "?";
			if bufferName == "" then
				bufferName = "?";
			end;
			payload = payload.."/".. bufferName;
		end;

		--	A message per group:
		--	RX_QRYRAIDASSIGNMENTS#<groupnum>/<buffer 2>/<buffer 2>/<buffer 3>#sender
		A:sendAddonMessage(string.format("RX_QRYRAIDASSIGNMENTS#%s#%s", payload, sender));			
	end;
end;

function Buffalo:handleRXQueryRaidAssignments(message, sender)
	local _, _, groupIndex, buffers = string.find(message, "([^/]*)/(%S*)");

	groupIndex = tonumber(groupIndex);
	local buffTable = Buffalo:splitString(buffers);

	for buffIndex = 1, table.getn(buffTable), 1 do
		local buffer = buffTable[buffIndex];
		if buffer == "?" then
			buffer = nil;
		end;
		Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex]["PLAYER"] = buffer;
	end;
end;

function Buffalo:splitString(string, separator)
	if not separator then
		separator = "/";
	end;

	local worktable = { };
	for str in string.gmatch(string, "([^"..separator.."]+)") do
		table.insert(worktable, str);
	end;
	return worktable;
end;

function Buffalo:resetRaidAssignments()
	for buffIndex = 1, table.getn(Buffalo.config.value.SynchronizedBuffs), 1 do
		for groupIndex = 1, 8, 1 do
			Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex]["PLAYER"] = nil;
		end;
	end;
end;


function Buffalo:unitIsPromoted(unitid)
	return UnitIsGroupAssistant(unitid) or UnitIsGroupLeader(unitid);
end;

function Buffalo:onBuffGroupClick(sender)
	local buttonName = sender:GetName();
	local _, _, buffIndex, groupIndex = string.find(buttonName, "buffgroup_(%d)_(%d)");

	if not buffIndex or not groupIndex then return; end;

	Buffalo.vars.SyncClass = Buffalo.vars.PlayerClass;	-- Only support current class (raid mode 1+2)
	Buffalo.vars.SyncBuff = tonumber(buffIndex);
	Buffalo.vars.SyncGroup = tonumber(groupIndex);

	--	Now we are ready to open the popup ...!
	ToggleDropDownMenu(1, nil, Buffalo.vars.SyncBuffGroupDropdownMenu, "cursor", 3, -3);

	Buffalo:updateAssignedRaidGroups();
end;

--	Re-generate group buff mask for groups in a Raid.
function Buffalo:updateAssignedRaidGroups()
	if Buffalo.vars.CurrentRaidMode == Buffalo.raidmodes.Personal then return; end;

	local raidGroups = { };
	for groupIndex = 1, 8, 1 do
		local groupMask = 0;
	
		for buffIndex = 1, #Buffalo.vars.OrderedBuffGroups, 1 do
			local buffInfo = Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex];	-- Assignment for a specific row + group
			if buffInfo["PLAYER"] == Buffalo.vars.PlayerNameAndRealm then
				groupMask = bit.bor(groupMask, buffInfo["BITMASK"]);
			end;
		end;

		raidGroups[groupIndex] = groupMask;
	end;

	Buffalo.config.value.AssignedRaidGroups = raidGroups;
end;

function Buffalo_buffGroupDropdownMenu_Initialize(self, level, menuList)
	--	Unassign: first choice.
	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.text       = Buffalo.SyncUnused;
	info.icon		= nil;
	info.func       = function() Buffalo:BuffGroupDropdownMenu_OnClick(this, nil) end;
	UIDropDownMenu_AddButton(info);

	local classInfo = Buffalo.classes[Buffalo.vars.SyncClass];
	local players = Buffalo:getPlayersInRoster(classInfo.Mask);
	for playerIndex = 1, #players, 1 do
		local info = UIDropDownMenu_CreateInfo();
		info.notCheckable = true;
		info.text       = players[playerIndex]["NAME"];
		info.icon		= players[playerIndex]["ICONID"];
		info.func       = function() Buffalo:BuffGroupDropdownMenu_OnClick(this, players[playerIndex]) end;
		UIDropDownMenu_AddButton(info);
	end
end;

--	nil means unassign
function Buffalo:BuffGroupDropdownMenu_OnClick(sender, playerInfo)
	local syncBuff = Buffalo.config.value.SynchronizedBuffs[Buffalo.vars.SyncBuff][Buffalo.vars.SyncGroup];

	if playerInfo then
		syncBuff["PLAYER"] = playerInfo["NAME"];
	else
		syncBuff["PLAYER"] = nil;
	end;

	--	Send a message to clients of same class that buff assignments was updated.
	local payload = string.format("%s/%s/%s", Buffalo.vars.SyncBuff, Buffalo.vars.SyncGroup, syncBuff["PLAYER"] or "");
	A:sendAddonMessage(string.format("TX_RDUPDATE#%s#%s", payload, Buffalo.vars.PlayerClass));

	Buffalo:updateGroupBuffUI();
end;

function Buffalo:getPlayersInRoster(classMask)
	local players = { };		-- List of { "NAME", "MASK", "ICONID", "CLASS" }

	if IsInRaid() then
		for n = 1, 40, 1 do
			local unitid = "raid"..n;
			if not UnitName(unitid) then break; end;
			
			local fullName = Buffalo:getPlayerAndRealm(unitid);
			local _, className = UnitClass(unitid);
			local classInfo = Buffalo.classes[className];

			if bit.band(classInfo.Mask, classMask) > 0 then
				tinsert(players, { 
					["NAME"] = fullName,
					["MASK"] = classInfo.Mask, 
					["ICONID"] = classInfo.IconID,
					["CLASS"] = className,
				});
			end;
		end;

	elseif Buffalo:isInParty() then
		for n = 1, GetNumGroupMembers(), 1 do
			local unitid = "party"..n;
			if not UnitName(unitid) then
				unitid = "player";
			end;

			local fullName = Buffalo:getPlayerAndRealm(unitid);
			local _, className = UnitClass(unitid);		
			local classInfo = Buffalo.classes[className];

			if bit.band(classInfo.Mask, classMask) > 0 then
				tinsert(players, {
					["NAME"] = fullName, 
					["MASK"] = classInfo.Mask, 
					["ICONID"] = classInfo.IconID,
					["CLASS"] = className, 
				});
			end;
		end;
	else
		--	SOLO play, somewhat usefull when testing
		local unitid = "player";
		local fullName = Buffalo:getPlayerAndRealm(unitid);
		local _, className = UnitClass(unitid);
		local classInfo = Buffalo.Classes[className];

		if bit.band(classInfo.Mask, classMask) > 0 then
			tinsert(players, {
				["NAME"] = fullName,
				["MASK"] = classInfo.Mask, 
				["ICONID"] = classInfo.IconID,
				["CLASS"] = className,
			});
		end;
	end;

	return players;
end;

function Buffalo:onGroupRosterUpdate()
	if not isInRaid then
		Buffalo:setRaidMode(Buffalo.raidmodes.Personal);
	else
		Buffalo:updateRaidModeButtons();
	end;
end;

function Buffalo:onPlayerTalentUpdate()
	if not Buffalo.vars.InitializationComplete then
		return;
	end;

	Buffalo:updateSpellMatrix();

	Buffalo:updateGroupBuffs();
	Buffalo:updateGroupBuffs(true);
	Buffalo:refreshActiveSpells();

	Buffalo:initializeBuffSettingsUI();
	Buffalo:updateGroupBuffUI();
	Buffalo:refreshClassSettingsUI();
end;

--	Update Buffing UI (main entry)
--	This will update PERSONAL or RAID buffs, depending on raid mode.
function Buffalo:updateGroupBuffUI()
	if not Buffalo.vars.InitializationComplete then
		return;
	end;

	local frame = nil;
	local height = 0;
	if Buffalo.vars.CurrentRaidMode == Buffalo.raidmodes.Personal then
		BuffaloConfigFrameCaption:SetText("Assign buffs for specific groups by left/right clicking the icons.");

		local backdrops = {
			["DRUID"] = Buffalo.ui.backdrops.DruidFrame,
			["MAGE"] = Buffalo.ui.backdrops.MageFrame,
			["PRIEST"] = Buffalo.ui.backdrops.PriestFrame,
			["WARLOCK"] = Buffalo.ui.backdrops.WarlockFrame,
		};

		local _, _, _, _, _, _, spellId = GetSpellInfo("Shadowform");
		if spellId then
			backdrops["PRIEST"] = Buffalo.ui.backdrops.ShadowPriestFrame;
		end;

		BuffaloConfigFrame:SetBackdrop(backdrops[Buffalo.vars.PlayerClass]);

		BuffaloConfigFrameRaid:Hide();
		frame = BuffaloConfigFramePersonal;
		height = Buffalo.vars.PersonalBuffFrameHeight;

		Buffalo:updatePersonalBuffUI();
	else
		if Buffalo.vars.CurrentRaidMode == Buffalo.raidmodes.OpenRaid then
			BuffaloConfigFrameCaption:SetText(string.format("Raid assignments are enabled by [%s]", Buffalo.vars.RaidModeLockedBy));
			BuffaloConfigFrame:SetBackdrop(Buffalo.ui.backdrops.OpenRaidFrame);
		else -- Buffalo.raidmodes.ClosedRaid
			BuffaloConfigFrameCaption:SetText(string.format("Raid assignments are locked by [%s]", Buffalo.vars.RaidModeLockedBy));
			BuffaloConfigFrame:SetBackdrop(Buffalo.ui.backdrops.ClosedRaidFrame);
		end;

		BuffaloConfigFramePersonal:Hide();
		frame = BuffaloConfigFrameRaid;
		height = Buffalo.vars.RaidBuffFrameHeight;

		Buffalo:updateRaidBuffUI();
	end;

	frame:SetHeight(height);
	BuffaloConfigFrame:SetHeight(frame:GetHeight() + 230);
	frame:Show();

	Buffalo:updateRaidModeButtons();

	--	SELF buffs:
	--	Iterate over all rows and render icons.
	local buttonName, entry;
	local buffMask = Buffalo.config.value.AssignedBuffSelf;

	local posX = Buffalo.ui.buffConfigDialog.Left;
	local posY = Buffalo.ui.buffConfigDialog.Top;
	for rowNumber = 1, #Buffalo.spells.personal, 1 do
		buttonName = string.format("buffalo_personal_buff_%d_0", rowNumber);
		entry = _G[buttonName];
		entry:SetPoint("TOPLEFT", posX, posY);

		if Buffalo.spells.personal[rowNumber].Enabled then
			entry:Show();
			posX = posX + Buffalo.ui.buffConfigDialog.Width;
		else
			entry:Hide();
		end;

		if (bit.band(buffMask, Buffalo.spells.personal[rowNumber].Bitmask) > 0) then
			entry:SetAlpha(Buffalo.ui.alpha.Enabled);
		else
			entry:SetAlpha(Buffalo.ui.alpha.Disabled);
		end;
	end;
end;

function Buffalo:updateRaidModeButtons()
	--	Generate Raid mode buttons:
	--	They are only visible when in a Raid:
	local isInRaid = IsInRaid();
	for _, raidmode in next, Buffalo.raidmodes.setup do
		local fButton = _G[string.format("raidmode_%s", raidmode["RAIDMODE"])];
		if isInRaid then
			if raidmode["RAIDMODE"] == Buffalo.vars.CurrentRaidMode then
				fButton:SetAlpha(Buffalo.ui.alpha.Enabled);
			else
				fButton:SetAlpha(Buffalo.ui.alpha.Disabled);
			end;
			fButton:Show();
		else
			fButton:Hide();
		end;
	end;
end;

function Buffalo:updatePersonalBuffUI()
	local buffCount = #Buffalo.spells.group;

	local assignedGroups = Buffalo.config.value.AssignedBuffGroups;
	if Buffalo.vars.CurrentRaidMode ~= Buffalo.raidmodes.Personal then
		assignedGroups = Buffalo.config.value.AssignedRaidGroups;
	end;

	--	PERSONAL raid buffs:
	--	Iterate over all groups and render icons.
	for groupNumber = 1, 8, 1 do
		local buffMask = assignedGroups[groupNumber];

		for rowNumber = 1, buffCount, 1 do
			local buttonName = string.format("buffalo_personal_buff_%d_%d", rowNumber, groupNumber);
			local entry = _G[buttonName];

			local alpha = Buffalo.ui.alpha.Disabled;
			if (bit.band(buffMask, Buffalo.spells.group[rowNumber].Bitmask) > 0) then
				alpha = Buffalo.ui.alpha.Enabled;
			end;

			if Buffalo.vars.CurrentRaidMode ~= Buffalo.raidmodes.Personal then
				entry:Disable();
			else
				entry:Enable();
			end;

			entry:SetAlpha(alpha);
		end;
	end;
end;

function Buffalo:updateRaidBuffUI()
	if not Buffalo.vars.OrderedBuffGroups then return; end;

	for buffIndex = 1, #Buffalo.vars.OrderedBuffGroups, 1 do

		for groupIndex = 1, 8, 1 do
			local bufferName = string.format("buffgroup_%s_%s", buffIndex, groupIndex);
			local fBuffer = _G[bufferName];

			local buffInfo = Buffalo.config.value.SynchronizedBuffs[buffIndex][groupIndex];
			if buffInfo["PLAYER"] then
				_G[bufferName.."Text"]:SetTextColor(Buffalo.ui.colours.Buffer[1], Buffalo.ui.colours.Buffer[2], Buffalo.ui.colours.Buffer[3]);
				_G[bufferName.."Text"]:SetText(buffInfo["PLAYER"]);
			else
				_G[bufferName.."Text"]:SetTextColor(Buffalo.ui.colours.Unused[1], Buffalo.ui.colours.Unused[2], Buffalo.ui.colours.Unused[3]);
				_G[bufferName.."Text"]:SetText(Buffalo.SyncUnused);
			end;
		end;
	end;

	Buffalo:updateAssignedRaidGroups();
end;

function Buffalo:refreshGeneralSettingsUI()
	--	Refresh sliders with value and text:
	BuffaloConfigFramePrayerThreshold:SetValue(Buffalo.config.value.GroupBuffThreshold);
	BuffaloSliderPrayerThresholdText:SetText(string.format("%s/5 people", Buffalo.config.value.GroupBuffThreshold));

	BuffaloConfigFrameRenewOverlap:SetValue(Buffalo.config.value.RenewOverlap);
	BuffaloSliderRenewOverlapText:SetText(string.format("%s seconds", Buffalo.config.value.RenewOverlap));

	BuffaloConfigFrameScanFrequency:SetValue(Buffalo.config.value.ScanFrequency * 10);
	BuffaloSliderScanFrequencyText:SetText(string.format("%s/10 sec.", Buffalo.config.value.ScanFrequency * 10));

	BuffaloConfigFrameButtonOpacity:SetValue(Buffalo.config.value.ButtonOpacity * 100);
	BuffaloSliderButtonOpacityText:SetText(string.format("%s percent", Buffalo.config.value.ButtonOpacity * 100));

	--	Refresh checkboxes:
	local checkboxValue = nil;
	if Buffalo.config.value.AnnounceMissingBuff then
		checkboxValue = 1;
	end;
	BuffaloConfigFrameOptionAnnounceMissing:SetChecked(checkboxValue);

	checkboxValue = nil;
	if Buffalo.config.value.AnnounceCompletedBuff then
		checkboxValue = 1;
	end;
	BuffaloConfigFrameOptionAnnounceComplete:SetChecked(checkboxValue);
end;

function Buffalo:refreshClassSettingsUI()
	--	Update alpha value on each button so it matches the current settings.

	buffCount = #Buffalo.spells.group;
	for rowNumber = 1, buffCount, 1 do
		for _, classInfo in next, Buffalo.sorted.classes do
			buttonName = string.format("%s_row%s", classInfo.ClassName, rowNumber);
			local entry = _G[buttonName];

			if bit.band(Buffalo.config.value.AssignedClasses[classInfo.ClassName], Buffalo.spells.group[rowNumber].Bitmask) > 0 then
				entry:SetAlpha(Buffalo.ui.alpha.Enabled);
			else
				entry:SetAlpha(Buffalo.ui.alpha.Disabled);
			end;
		end;
	end;
end;

function Buffalo:onConfigurationBuffClick(self, ...)
	local buttonName = self:GetName();
	local buttonType = GetMouseButtonClicked();

	local _, _, row, col = string.find(buttonName, "buffalo_personal_buff_(%d+)_(%d+)");

	row = 1 * row;
	col = 1 * col;	-- Col=0: self buff, col 1-8: raid buff

	--	GroupMask tells what buffs I have selected for the actual group.
	local groupMask;
	--	Properties are the name / icon/ mask for the clicked buff.
	local properties = { };
	if col == 0 then
		properties = Buffalo.spells.personal;
		groupMask = Buffalo.config.value.AssignedBuffSelf;
	else 
		properties = Buffalo.spells.group;
		groupMask = Buffalo.config.value.AssignedBuffGroups[col];
	end;

	--	BuffMask is the clicked buff's bitvalue.
	local buffMask = properties[row].Bitmask;
	local maskOut = 0x0ffff - buffMask;		-- preserve all buffs except for the selected one:

	if buttonType == "LeftButton" then
		--	Left button: ADD the buff
		--	First disable all other buffs in same family (if any)

		local spellInfo = Buffalo.spells.active[properties[row].SpellName];
		local family = spellInfo.Family;
		if family then
			local familyMask = 0x0000;

			for _, spellInfo in next, Buffalo.spells.active do
				if spellInfo.Family == family then
					familyMask = bit.bor(familyMask, spellInfo.Bitmask);
				end;
			end;

			groupMask = bit.band(groupMask, 0x0ffff - familyMask);
		end;

		groupMask = bit.bor(groupMask, buffMask);
	else
		groupMask = bit.band(groupMask, maskOut);
	end;


	if col == 0 then
		Buffalo.config.value.AssignedBuffSelf = groupMask
		Buffalo:setConfigOption(Buffalo.config.key.AssignedBuffSelf, Buffalo.config.value.AssignedBuffSelf);
	else
		Buffalo.config.value.AssignedBuffGroups[col] = groupMask;
	end;

	Buffalo:updateGroupBuffUI();
end;

function Buffalo:onToggleRowBuffsClick(self, ...)
	local buttonName = self:GetName();
	local buttonType = GetMouseButtonClicked();
	local _, _, rowOrCol, number = string.find(buttonName, "toggle_(%a+)_(%d)");

	local enableBuffs = (buttonType == "LeftButton");

	--	"column" buffs makes no sense.
	if rowOrCol == "row" then
		Buffalo:toggleRowBuffs(1 * number, enableBuffs);
	end;
end;

function Buffalo:toggleRowBuffs(rowNumber, enableBuffs)
	local spellName = Buffalo.spells.group[rowNumber].SpellName;
	local spellInfo = Buffalo.spells.active[spellName];
	if not spellInfo then
		return;
	end; 

	--	GroupMask tells what buffs I have selected for the actual group.
	local spellMask = Buffalo.spells.group[rowNumber].Bitmask;			--	spellMask is the clicked buff's bitvalue.
	local maskOut = 0x0ffff - spellMask;									-- preserve all buffs except for the selected one:

	local groupMask, col;
	for col = 1, 8, 1 do
		groupMask  = Buffalo.config.value.AssignedBuffGroups[col];

		if enableBuffs then
			--	ADD the buff: first disable all other buffs in same family (if any)
			local family = spellInfo.Family;
			if family then
				local familyMask = 0x0000;
				for _, spellInfo in next, Buffalo.spells.active do
					if spellInfo.Family == family then
						familyMask = bit.bor(familyMask, spellInfo.Bitmask);
					end;
				end;

				groupMask = bit.band(groupMask, 0x0ffff - familyMask);
			end;

			groupMask = bit.bor(groupMask, spellMask);
		else
			groupMask = bit.band(groupMask, maskOut);
		end;

		Buffalo.config.value.AssignedBuffGroups[col] = groupMask;
	end;

	Buffalo:updateGroupBuffUI();
end;

function Buffalo:onClassConfigClick(self, ...)
	local buttonName = self:GetName();
	local buttonType = GetMouseButtonClicked();

	local _, _, className, row = string.find(buttonName, "([A-Z]*)_row(%d)");

	row = 1 * row;

	local classMask = Buffalo.config.value.AssignedClasses[className];
	local buffMask = Buffalo.spells.group[row].Bitmask;

	if buttonType == "LeftButton" then
		--	Left button: ADD the buff
		classMask = bit.bor(classMask, buffMask);
	else
		--	Right button: REMOVE the buff
		classMask = bit.band(classMask, 0x03fff - buffMask);
	end;

	Buffalo.config.value.AssignedClasses[className] = classMask;

	Buffalo:setConfigOption(Buffalo.config.key.AssignedClasses, Buffalo.config.value.AssignedClasses);

	Buffalo:refreshClassSettingsUI();
end;


function Buffalo:onConfigurationCloseButtonClick()
	Buffalo:closeConfigurationDialogue();
end;

function Buffalo:onGeneralConfigCloseButtonClick()
	Buffalo:closeGeneralConfigDialogue();
end;

function Buffalo:onClassConfigCloseButtonClick()
	Buffalo:closeClassConfigDialogue();
end;

function Buffalo_onPrayerThresholdChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	if value ~= Buffalo.config.value.GroupBuffThreshold then
		Buffalo.config.value.GroupBuffThreshold = value;
		Buffalo:setConfigOption(Buffalo.config.key.GroupBuffThreshold, Buffalo.config.value.GroupBuffThreshold);
	end;
	
	BuffaloSliderPrayerThresholdText:SetText(string.format("%s/5 people", Buffalo.config.value.GroupBuffThreshold));
end;

function Buffalo_onRenewOverlapChanged(object)
	local value = math.floor(object:GetValue());

	value = (math.floor(value / 5)) * 5;

	object:SetValueStep(5);
	object:SetValue(value);

	if value ~= Buffalo.config.value.RenewOverlap then
		Buffalo.config.value.RenewOverlap = value;
		Buffalo:setConfigOption(Buffalo.config.key.RenewOverlap, Buffalo.config.value.RenewOverlap);
	end;
	
	BuffaloSliderRenewOverlapText:SetText(string.format("%s seconds", Buffalo.config.value.RenewOverlap));
end;


function Buffalo_onScanFrequencyChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	--	Slider works from 1-10, we need values from 0.1 - 1:
	value = value / 10;
	if value ~= Buffalo.config.value.ScanFrequency then
		Buffalo.config.value.ScanFrequency = value;
		Buffalo:setConfigOption(Buffalo.config.key.ScanFrequency, Buffalo.config.value.ScanFrequency);
	end;
	
	BuffaloSliderScanFrequencyText:SetText(string.format("%s/10 sec.", Buffalo.config.value.ScanFrequency * 10));
end;

function Buffalo_onButtonOpacityChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	--	Slider works from 1-100, we need values from 0.0 - 1.0:
	value = value / 100;
	if value ~= Buffalo.config.value.ButtonOpacity then
		Buffalo.config.value.ButtonOpacity = value;
		Buffalo:setConfigOption(Buffalo.config.key.ButtonOpacity, Buffalo.config.value.ButtonOpacity);

		BuffButton:SetAlpha(value);
	end;
	
	BuffaloSliderButtonOpacityText:SetText(string.format("%s percent", Buffalo.config.value.ButtonOpacity * 100));
end;

function Buffalo_handleCheckbox(checkbox)
	if not checkbox then return end;

	local checkboxname = checkbox:GetName();

	-- "single" checkboxes (checkboxes with no impact on other checkboxes):
	if checkboxname == "BuffaloConfigFrameOptionAnnounceMissing" then
		if BuffaloConfigFrameOptionAnnounceMissing:GetChecked() then
			Buffalo.config.value.AnnounceMissingBuff = true;
			A:echo("Missing Buff announcements are now ON.");
		else
			Buffalo.config.value.AnnounceMissingBuff = false;
			A:echo("Missing Buff announcements are now OFF.");
		end;
		Buffalo:setConfigOption(Buffalo.config.key.AnnounceMissingBuff, Buffalo.config.value.AnnounceMissingBuff);
	end;

	if checkboxname == "BuffaloConfigFrameOptionAnnounceComplete" then
		if BuffaloConfigFrameOptionAnnounceComplete:GetChecked() then
			Buffalo.config.value.AnnounceCompletedBuff = true;
			A:echo("Completed Buff announcements are now ON.");
		else
			Buffalo.config.value.AnnounceCompletedBuff = false;
			A:echo("Completed Buff announcements are now OFF.");
		end;
		Buffalo:setConfigOption(Buffalo.config.key.AnnounceCompletedBuff, Buffalo.config.value.AnnounceCompletedBuff);
	end;

	if checkboxname == "BuffaloClassConfigFrameUseIncubus" then
		if BuffaloClassConfigFrameUseIncubus:GetChecked() then
			Buffalo.config.value.UseIncubus = true;
			A:echo("Incubus selected as favourite demon.");
		else
			Buffalo.config.value.UseIncubus = false;
			A:echo("Succubus selected as favourite demon.");
		end;
		Buffalo:setConfigOption(Buffalo.config.key.UseIncubus, Buffalo.config.value.UseIncubus);
	end;

	Buffalo:updateDemon();
end;

function Buffalo:updateDemon()
	if Buffalo.vars.PlayerClass ~= "WARLOCK" then
		return; 
	end;

	--	Get spells from the Matrix to see if user actually knows them:
	if not Buffalo.spells.active[Buffalo.spellnames.warlock.Succubus].Learned and not Buffalo.spells.active[Buffalo.spellnames.warlock.Incubus].Learned then
	end;

	local disabledDemon = Buffalo.spellnames.warlock.Incubus;
	local enabledDemon = Buffalo.spellnames.warlock.Succubus;
	if Buffalo.config.value.UseIncubus then
		disabledDemon = Buffalo.spellnames.warlock.Succubus;
		enabledDemon = Buffalo.spellnames.warlock.Incubus;
	end;
	Buffalo.spells.active[disabledDemon].Bitmask = 0x000000;
	Buffalo.spells.active[disabledDemon].Enabled = nil;
	Buffalo.spells.active[enabledDemon].Bitmask = 0x002000;
	Buffalo.spells.active[enabledDemon].Enabled = true;

	local demonButton;
	for rowNumber = 1, #Buffalo.spells.personal, 1 do
		if Buffalo.spells.personal[rowNumber].SpellName == disabledDemon then
			demonButton = _G[string.format("buffalo_personal_buff_%d_0", rowNumber)];
			demonButton:Hide();
		end;

		if Buffalo.spells.personal[rowNumber].SpellName == enabledDemon then
			demonButton = _G[string.format("buffalo_personal_buff_%d_0", rowNumber)];
			demonButton:Show();
		end;
	end;
end;



--[[
	Timers
--]]
function Buffalo:getTimerTick()
	return Buffalo.vars.TimerTick;
end



--[[
	Debugging functions
	Added in: 0.3.0
--]]
function Buffalo:addDebugFunction(functionName)
	functionName = Buffalo:createFunctionName(functionName);
	echo(string.format("%s added to debugging list.", functionName));
	Buffalo.debug.Functions[functionName] = true;
end;

function Buffalo:removeDebugFunction(functionName)
	functionName = Buffalo:createFunctionName(functionName);
	echo(string.format("%s removed from debugging list.", functionName));
	Buffalo.debug.Functions[functionName] = nil;
end;

function Buffalo:listDebugFunctions()
	echo("Debugging list:");
	for functionName in next, Buffalo.debug.Functions do
		echo("> "..functionName);
	end;
end;

function Buffalo:createFunctionName(functionName)
	return "BUFFALO_" .. string.upper(functionName);
end;


--[[
	Event Handlers
--]]
function Buffalo_onEvent(self, event, ...)
	Buffalo.vars.TimerTick = Buffalo:getTimerTick();

	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == A.addonName then
			Buffalo:mainInitialization();
			Buffalo_repositionateButton(BuffButton);
			Buffalo:hideBuffButton();
		end

	elseif (event == "PLAYER_TALENT_UPDATE") then
		Buffalo:onPlayerTalentUpdate(event, ...)

	elseif (event == "CHAT_MSG_ADDON") then
		Buffalo:onChatMsgAddon(event, ...)

	elseif (event == "GROUP_ROSTER_UPDATE") then
		Buffalo:onGroupRosterUpdate(event, ...)

	elseif(event == "UNIT_SPELLCAST_STOP") then
		local caster = ...;
		if caster == "player" then
			Buffalo.vars.LastBuffFired = nil;
		end;

	elseif(event == "UNIT_SPELLCAST_FAILED") then
		local caster = ...;
		if caster == "player" then
			Buffalo.vars.LastBuffFired = nil;
		end;

	elseif(event == "UNIT_SPELLCAST_SUCCEEDED") then
		local caster, _, spellId = ...;

		if caster == "player" then
			local buffName = GetSpellInfo(spellId);
			if buffName and buffName == Buffalo.vars.LastBuffFired then
				Buffalo.vars.LastBuffFired = nil;
				if Buffalo.config.value.AnnounceCompletedBuff and not UnitAffectingCombat("player") then
					local unitid = BuffButton:GetAttribute("unit");
					if unitid then
						A:echo(string.format("%s was buffed with %s.", Buffalo:getPlayerAndRealm(unitid) or "nil", buffName));
					end;
				end;
			end;
		end;

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

function Buffalo_onLoad()
	local _, classname = UnitClass("player");
	Buffalo.vars.PlayerClass = classname;
	Buffalo.vars.PlayerNameAndRealm = Buffalo:getPlayerAndRealm("player");

	if not Buffalo.classes[classname] or not Buffalo.classes[classname].spells then
		--	Warriors etc are not supported (no spells to buff), so we make sure Initialization is not performed!
		BuffButton:Hide();
		Buffalo.vars.InitializationRetryTimer = 86400;
		A:echo('Addon will go to sleep (Unsupported class)');
		return;
	end;

	Buffalo.Version = A:calculateVersion();

	A:echo(string.format("Type %s/buffalo%s to configure the addon.", A.chatColorHot, A.chatColorNormal));

	_G["BuffaloVersionString"]:SetText(string.format("Buffalo version %s by %s", A.addonVersion, A.addonAuthor));

    BuffaloEventFrame:RegisterEvent("ADDON_LOADED");
    BuffaloEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    BuffaloEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    BuffaloEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
    BuffaloEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED");
    BuffaloEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    BuffaloEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE");

	BuffaloClassConfigFrame:SetBackdrop(Buffalo.ui.backdrops.ClassFrame);
	BuffaloGeneralConfigFrame:SetBackdrop(Buffalo.ui.backdrops.GeneralFrame);

	BuffaloConfigFramePrayerThreshold:SetBackdrop(Buffalo.ui.backdrops.Slider);
	BuffaloConfigFrameRenewOverlap:SetBackdrop(Buffalo.ui.backdrops.Slider);
	BuffaloConfigFrameScanFrequency:SetBackdrop(Buffalo.ui.backdrops.Slider);
	BuffaloConfigFrameButtonOpacity:SetBackdrop(Buffalo.ui.backdrops.Slider);

	C_ChatInfo.RegisterAddonMessagePrefix(A.addonPrefix);
end

function Buffalo_onTimer(elapsed)
	Buffalo.vars.TimerTick = Buffalo.vars.TimerTick + elapsed

	if Buffalo.vars.TimerTick > (Buffalo.vars.NextScanTime + Buffalo.config.value.ScanFrequency) then
		Buffalo:scanRaid();
		Buffalo.vars.NextScanTime = Buffalo.vars.TimerTick;
	end;

	if not Buffalo.vars.InitializationComplete and Buffalo.vars.TimerTick > Buffalo.vars.InitializationRetryTimer then
		Buffalo:mainInitialization(true);
	end;

end
