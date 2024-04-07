--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo.lua
--	Desc:	Core functionality: addon framework, event handling etc.
--]]

local addonMetadata = {
	["ADDONNAME"]		= "Buffalo",
	["SHORTNAME"]		= "BUFFALO",
	["PREFIX"]			= "BuffaloV1",
	["NORMALCHATCOLOR"]	= "E0C020",
	["HOTCHATCOLOR"]	= "F8F8F8",
};
local A = DigamAddonLib:new(addonMetadata);


--	Design/UI constants
local BUFFALO_COLOUR_EXPIRING					= "|c80F0F000"
local BUFFALO_COLOUR_MISSING					= "|c80F05000"
local BUFFALO_ICON_PASSIVE						= 136112;
local BUFFALO_ICON_COMBAT						= "Interface\\Icons\\Ability_dualwield";
local BUFFALO_ICON_PLAYERDEAD					= "Interface\\Icons\\Ability_rogue_feigndeath";
local BUFFALO_ALPHA_DISABLED					= 0.42;
local BUFFALO_ALPHA_ENABLED						= 1.00;
local BUFFALO_COLOR_GROUPLABELS					= { 1.0, 0.7, 0.0 };
local BUFFALO_COLOR_BUFFER						= { 1.0, 1.0, 1.0 };
local BUFFALO_COLOR_UNUSED						= { 0.4, 0.4, 0.4 };

local BUFFALO_ICON_RAID_NONE					= 134121;	-- Raid mode 0: white
local BUFFALO_ICON_RAID_OPEN					= 134125;	-- Raid mode 1: green
local BUFFALO_ICON_RAID_CLOSED					= 134124;	-- Raid mode 2: red

local BUFFALO_BACKDROP_CLASSES_FRAME = {
	bgFile = "Interface\\TalentFrame\\WarriorProtection-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
};
local BUFFALO_BACKDROP_GENEREL_FRAME = {
	bgFile = "Interface\\TalentFrame\\RogueCombat-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
};
local BUFFALO_BACKDROP_RAIDMODE0_DRUID_FRAME = {
	bgFile = "Interface\\TalentFrame\\ShamanRestoration-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
local BUFFALO_BACKDROP_RAIDMODE0_MAGE_FRAME = {
	bgFile = "Interface\\TalentFrame\\MageFrost-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
local BUFFALO_BACKDROP_RAIDMODE0_PRIEST_FRAME = {
	bgFile = "Interface\\TalentFrame\\PriestDiscipline-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
local BUFFALO_BACKDROP_RAIDMODE1_FRAME = {
	bgFile = "Interface\\TalentFrame\\PaladinCombat-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
local BUFFALO_BACKDROP_RAIDMODE2_FRAME = {
	bgFile = "Interface\\TalentFrame\\WarriorFury-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
local BUFFALO_BACKDROP_SLIDER = {
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-TestWatermark-Border",
	tileEdge = true,
	edgeSize = 16,
};


local BUFFALO_SYNC_UNUSED						= "(None)";


--	Render Raid modes: currently supporting mode 0/1/2:
local BUFFALO_RAIDMODE_PERSONAL					= 0x0001;		--	Assignments are using the "normal" SOLO frame.
local BUFFALO_RAIDMODE_OPEN						= 0x0010;		--	Assignments are using Raid frame. Everyone can assign.
local BUFFALO_RAIDMODE_CLOSED					= 0x0020;		--	Assignments are using Raid frame. Promoted can assign.
local BUFFALO_RAIDMODE_CENTRAL					= 0x0100;		--	Currently unsupported

local Buffalo_RaidModes = {
	{ ["RAIDMODE"] = BUFFALO_RAIDMODE_PERSONAL,	["ICON"] = BUFFALO_ICON_RAID_NONE, ["CAPTION"] = "Personal assignments" },
	{ ["RAIDMODE"] = BUFFALO_RAIDMODE_OPEN,		["ICON"] = BUFFALO_ICON_RAID_OPEN, ["CAPTION"] = "Open Raid assignments" },
	{ ["RAIDMODE"] = BUFFALO_RAIDMODE_CLOSED,	["ICON"] = BUFFALO_ICON_RAID_CLOSED, ["CAPTION"] = "Closed Raid assignments" },
};

local BUFFALO_RaidMode1RequiresPromotion		= true;		-- true: (switching to) Raidmode 1 requires promotion
local BUFFALO_RaidMode2RequiresPromotion		= true;		-- true: (switching to) Raidmode 2 requires promotion
local BUFFALO_DisplayRaidModeChanges			= false;	-- true: show a local message when raid mode changes. Can be spammy.


--	Note: This is NOT persisted. We want players to always be in 
--	PERSONAL mode unless specified otherwise (aka: in a raid!)
local Buffalo_CurrentRaidMode					= BUFFALO_RAIDMODE_PERSONAL;
local Buffalo_RaidModeLockedBy					= "";
local Buffalo_RaidModeQueryDone					= false;

--	Internal variables
local IsBuffer									= false;
local Buffalo_PlayerNameAndRealm				= "";
local Buffalo_PlayerClass						= "";
local Buffalo_InitializationComplete			= false;
local Buffalo_InitializationRetryTimer			= 0;
local Buffalo_UpdateMessageShown				= false;
local TimerTick									= 0
local NextScanTime								= 0;
local lastBuffTarget							= "";
local lastBuffStatus							= "";
local lastBuffFired								= nil;

local Buffalo_OrderedBuffGroups					= { };		-- [buff index] = { 1=PRIORITY, 2=NAME, 3=MASK, 4=ICONID } 
local Buffalo_GroupBuffProperties				= { };		--	Array of buff properties for the group UI: { buffname, iconid, bitmask, priority }
local Buffalo_SelfBuffProperties				= { };
local BUFF_MATRIX								= { };		--	[buffname]=<bitmask value>
local CLASS_MATRIX								= { };		--	[classname<english>]={ ICONID=<icon id>, MASK=<bitmask value> }
local CLASS_MASK_ALL							= 0x0000;

--	Debugging
local DEBUG_FunctionList						= { };


-- Configuration:
--	Loaded options:	{realmname}{playername}{parameter}
Buffalo_Options = { }

--	Configuration keys:
local CONFIG_KEY_AnnounceCompletedBuff			= "AnnounceCompletedBuff";
local CONFIG_KEY_AnnounceMissingBuff			= "AnnounceMissingBuff";
local CONFIG_KEY_AssignedBuffGroups				= "AssignedBuffGroups";
local CONFIG_KEY_AssignedBuffSelf				= "AssignedBuffSelf";
local CONFIG_KEY_AssignedClasses				= "AssignedClasses";
local CONFIG_KEY_BuffButtonPosX					= "BuffButton.X";
local CONFIG_KEY_BuffButtonPosY					= "BuffButton.Y";
local CONFIG_KEY_BuffButtonVisible				= "BuffButton.Visible";
local CONFIG_KEY_GroupBuffThreshold				= "GroupBuffThreshold";
local CONFIG_KEY_RenewOverlap					= "RenewOverlap";
local CONFIG_KEY_ScanFrequency					= "ScanFrequency";
local CONFIG_KEY_SynchronizedBuffs				= "SynchronizedBuffGroups";

local CONFIG_DEFAULT_AnnounceCompletedBuff		= false;	-- Announce when a buff has being cast.
local CONFIG_DEFAULT_AnnounceMissingBuff		= false;	-- Announce next buff being cast.
local CONFIG_DEFAULT_AssignedBuffSelf			= 0x0000;	-- Default is no selfbuffs assigned.
local CONFIG_DEFAULT_AssignedClasses			= { };		-- Classes with buff assignments: CONFIG_AssignedClasses[classname] = [bitmask]. Set runtime.
local CONFIG_DEFAULT_BuffButtonVisible			= true;
local CONFIG_DEFAULT_GroupBuffThreshold			= 4;		-- Default is to use greater buffs when 4+ people needs a buff.
local CONFIG_DEFAULT_RenewOverlap				= 30;		-- If buff ends withing <n> seconds Buffalo will attempt to rebuff
local CONFIG_DEFAULT_ScanFrequency				= 0.3;		-- Scan every <n> second (0.1 - 1.0 seconds)

--	Configured values (TODO: a few selected are still not configurable)
local CONFIG_AnnounceCompletedBuff				= CONFIG_DEFAULT_AnnounceCompletedBuff;
local CONFIG_AnnounceMissingBuff				= CONFIG_DEFAULT_AnnounceMissingBuff;
local CONFIG_AssignedBuffGroups					= { };		-- List of groups and their assigned buffs via bitmask. Persisted, but no UI for it. Set runtime.
local CONFIG_AssignedRaidGroups					= { };		-- Same but for Raid buffing.
local CONFIG_AssignedBuffSelf					= CONFIG_DEFAULT_AssignedBuffSelf;
local CONFIG_AssignedClasses					= CONFIG_DEFAULT_AssignedClasses;
local CONFIG_SynchronizedBuffs					= { };		-- [buff row][group num] = { [BUFFNAME], [BITMASK], [PLAYER] }
	--[[
		CONFIG_SynchronizedBuffs[<rowNumber>][<groupNumber>] = {
			["BUFFNAME"] = <buff name - foreign key to BUFF_MATRIX>,
			["BITMASK"] = <buff mask>
			["PLAYER"] = <full playername assigned or nil if none assigned>,
		}
	--]]

local CONFIG_BuffButtonVisible					= CONFIG_DEFAULT_BuffButtonVisible;
local CONFIG_GroupBuffThreshold					= CONFIG_DEFAULT_GroupBuffThreshold;
local CONFIG_RenewOverlap						= CONFIG_DEFAULT_RenewOverlap;
local CONFIG_ScanFrequency						= CONFIG_DEFAULT_ScanFrequency;

--	Other configuration options considered in future releases:
local CONFIG_BuffButtonSize						= 32;		-- Size of buff button
local CONFIG_PlayerBuffPriority					= 90;		-- Priority to Self'



--	Dropdown menu for Healer (add/replace healer) selection:
Buffalo_SyncBuffGroupDropdownMenu = CreateFrame("FRAME", "BuffaloSyncFrameBuff", UIParent, "UIDropDownMenuTemplate");
Buffalo_SyncBuffGroupDropdownMenu:SetPoint("CENTER");
Buffalo_SyncBuffGroupDropdownMenu:Hide();
UIDropDownMenu_SetWidth(Buffalo_SyncBuffGroupDropdownMenu, 1);
UIDropDownMenu_SetText(Buffalo_SyncBuffGroupDropdownMenu, "");

UIDropDownMenu_Initialize(Buffalo_SyncBuffGroupDropdownMenu, function(self, level, menuList)
	if Buffalo_SyncBuffGroupDropdownMenu_Initialize then
		Buffalo_SyncBuffGroupDropdownMenu_Initialize(self, level, menuList); 
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
	Buffalo_SetOption(CONFIG_KEY_BuffButtonVisible, true);
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
	Buffalo_SetOption(CONFIG_KEY_BuffButtonVisible,false);
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
	BuffButton:SetSize(CONFIG_BuffButtonSize, CONFIG_BuffButtonSize);

	if CONFIG_BuffButtonVisible then
		BuffButton:Show();
	end;

	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosX, 0);
	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosY, 0);

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
	CONFIG_AnnounceMissingBuff = true;
	CONFIG_AnnounceCompletedBuff = true;
	lastBuffTarget = "";
	lastBuffStatus = "";
	Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);
	Buffalo_SetOption(CONFIG_KEY_AnnounceCompletedBuff, CONFIG_AnnounceCompletedBuff);
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
	CONFIG_AnnounceMissingBuff = false;
	CONFIG_AnnounceCompletedBuff = false;
	Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);
	Buffalo_SetOption(CONFIG_KEY_AnnounceCompletedBuff, CONFIG_AnnounceCompletedBuff);
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
	if IsInRaid() or Buffalo_IsInParty() then
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
local function Buffalo_HandleTXVersion(message, sender)
	A:sendAddonMessage("RX_VERSION#".. A.addonVersion .."#"..sender)
end

--[[
	A version response (RX) was received.
	The version information is displayed locally.
]]
local function Buffalo_HandleRXVersion(message, sender)
	A:echo(string.format("[%s] is using Buffalo version %s", sender, message))
end

local function Buffalo_HandleTXVerCheck(message, sender)
	Buffalo_CheckIsNewVersion(message);
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
local function Buffalo_HandleAddonMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	

	--	Ignore messages sent from myself, unless it is a Version check (*sigh*)
	if sender == Buffalo_PlayerNameAndRealm then
		if cmd ~= "TX_VERSION" and cmd ~= "RX_VERSION" then
			return;
		end;
	end;

	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if recipient ~= "" then
		--	Buffalo-specific: Recipient can also be a classname.
		if recipient == Buffalo_PlayerClass then
			--	This is for me (a class-specific message);
		else
			--	Check if this is for me - if not, skip!
			-- Recipient comes with realmname, so we need to compare with realmname too:
			recipient = Buffalo_GetPlayerAndRealmFromName(recipient);

			if recipient ~= Buffalo_PlayerNameAndRealm then
				return
			end
		end;
	end

	if cmd == "TX_VERSION" then
		Buffalo_HandleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		Buffalo_HandleRXVersion(message, sender)
	elseif cmd == "TX_VERCHECK" then
		Buffalo_HandleTXVerCheck(message, sender)

	elseif cmd == "TX_RAIDMODE" then
		Buffalo_HandleTXRaidMode(message, sender);
	elseif cmd == "TX_RDUPDATE" then
		Buffalo_HandleTXRdUpdate(message, sender);
	elseif cmd == "TX_QRYRAIDMODE" then
		Buffalo_HandleTXQueryRaidMode(message, sender);
	elseif cmd == "RX_QRYRAIDMODE" then
		Buffalo_HandleRXQueryRaidMode(message, sender);
	elseif cmd == "TX_QRYRAIDASSIGNMENTS" then
		Buffalo_HandleTXQueryRaidAssignments(message, sender);
	elseif cmd == "RX_QRYRAIDASSIGNMENTS" then
		Buffalo_HandleRXQueryRaidAssignments(message, sender);
	end
end

local function Buffalo_OnChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;

	if prefix == A.addonPrefix then
		Buffalo_HandleAddonMessage(msg, sender);
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

local function Buffalo_CalculateVersion(versionString)
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
	end
	
	return version;
end

local function Buffalo_CheckIsNewVersion(versionstring)
	local incomingVersion = Buffalo_CalculateVersion( versionstring );

	if (BUFFALO_CURRENT_VERSION > 0 and incomingVersion > 0) then
		if incomingVersion > BUFFALO_CURRENT_VERSION then
			if not Buffalo_UpdateMessageShown then
				Buffalo_UpdateMessageShown = true;
				A:echo(string.format("NOTE: A newer version of ".. A.charColorHot .."BUFFALO".. A.chatColorNormal .."! is available (version %s)!", versionstring));
				A:echo("You can download latest version from https://www.curseforge.com/ or https://github.com/Sentilix/buffalo.");
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
	if not realmname or realmname == "" then
		realmname = Buffalo_GetMyRealm();
	end;

	return playername.."-".. realmname;
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



--[[
	Initialization
--]]
local function Buffalo_InitializeConfigSettings()
	if not Buffalo_Options then
		Buffalo_options = { };
	end

	local x,y = BuffButton:GetPoint();
	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosX, Buffalo_GetOption(CONFIG_KEY_BuffButtonPosX, x))
	Buffalo_SetOption(CONFIG_KEY_BuffButtonPosY, Buffalo_GetOption(CONFIG_KEY_BuffButtonPosY, y))

	local value = Buffalo_GetOption(CONFIG_KEY_BuffButtonVisible, CONFIG_DEFAULT_BuffButtonVisible);
	if type(value) == "boolean" then
		CONFIG_BuffButtonVisible = value;
	else
		CONFIG_BuffButtonVisible = CONFIG_DEFAULT_BuffButtonVisible;
	end;
	Buffalo_SetOption(CONFIG_KEY_BuffButtonVisible, CONFIG_BuffButtonVisible);

	CONFIG_ScanFrequency = Buffalo_GetOption(CONFIG_KEY_ScanFrequency, CONFIG_DEFAULT_ScanFrequency);
	if CONFIG_ScanFrequency < 0.1 or CONFIG_ScanFrequency > 1 then
		CONFIG_ScanFrequency = CONFIG_DEFAULT_ScanFrequency;
	end;
	Buffalo_SetOption(CONFIG_KEY_ScanFrequency, CONFIG_ScanFrequency);

	CONFIG_RenewOverlap = Buffalo_GetOption(CONFIG_KEY_RenewOverlap, CONFIG_DEFAULT_RenewOverlap);
	if CONFIG_RenewOverlap < 0 or CONFIG_RenewOverlap > 120 then
		CONFIG_RenewOverlap = CONFIG_DEFAULT_RenewOverlap;
	end;
	Buffalo_SetOption(CONFIG_KEY_RenewOverlap, CONFIG_RenewOverlap);

	CONFIG_GroupBuffThreshold = Buffalo_GetOption(CONFIG_KEY_GroupBuffThreshold, CONFIG_DEFAULT_GroupBuffThreshold);
	if CONFIG_GroupBuffThreshold < 1 or CONFIG_GroupBuffThreshold > 5 then
		CONFIG_GroupBuffThreshold = CONFIG_DEFAULT_GroupBuffThreshold;
	end;
	Buffalo_SetOption(CONFIG_KEY_GroupBuffThreshold, CONFIG_GroupBuffThreshold);

	if CONFIG_BuffButtonVisible then
		BuffButton:Show();
	else
		BuffButton:Hide()
	end

	--	Init the "assigned buff groups". This is a table, so we need to validate the integrity:
	local assignedBuffGroups = Buffalo_GetOption(CONFIG_KEY_AssignedBuffGroups, nil);
	if type(assignedBuffGroups) == "table" and table.getn(assignedBuffGroups) == 8 then
		CONFIG_DEFAULT_AssignedBuffGroups = { }
		for groupNum = 1, 8, 1 do
			local groupMask = 0;
			if assignedBuffGroups[groupNum] then
				groupMask = assignedBuffGroups[groupNum];
			end;

			CONFIG_AssignedBuffGroups[groupNum] = tonumber(groupMask);
		end;
	else
		--	Use the default assignments for my class: most important buffs in ALL groups:
		CONFIG_AssignedBuffGroups = Buffalo_InitializeAssignedGroupDefaults();
	end;
	Buffalo_SetOption(CONFIG_KEY_AssignedBuffGroups, CONFIG_AssignedBuffGroups);

	--	Read SyncBuffsfrom Config! initialized a bit later with defaults.
	local syncBuffTable = { };
	local failureDetected = false;
	local syncedBuffs = Buffalo_GetOption(CONFIG_KEY_SynchronizedBuffs, nil);

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
	CONFIG_SynchronizedBuffs = { };
	if not failureDetected and table.getn(syncBuffTable) > 0 then
		CONFIG_SynchronizedBuffs = syncBuffTable;
	end;


	CONFIG_AssignedClasses = Buffalo_GetOption(CONFIG_KEY_AssignedClasses, CONFIG_DEFAULT_AssignedClasses)
	
	CONFIG_AssignedBuffSelf = Buffalo_GetOption(CONFIG_KEY_AssignedBuffSelf, CONFIG_DEFAULT_AssignedBuffSelf);
	Buffalo_SetOption(CONFIG_KEY_AssignedBuffSelf, CONFIG_AssignedBuffSelf);

	CONFIG_AnnounceMissingBuff = Buffalo_GetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_DEFAULT_AnnounceMissingBuff);
	Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);

	CONFIG_AnnounceCompletedBuff = Buffalo_GetOption(CONFIG_KEY_AnnounceCompletedBuff, CONFIG_DEFAULT_AnnounceCompletedBuff);
	Buffalo_SetOption(CONFIG_KEY_AnnounceCompletedBuff, CONFIG_AnnounceCompletedBuff);
end


--[[
	Generate a class matrix, based on the current expansion level.
	Added in 0.4.0
--]]
local function Buffalo_InitializeClassMatrix()
	local factionEN = UnitFactionGroup("player");

	CLASS_MATRIX = { };
	CLASS_MASK_ALL = 0x0000;

	local expacKey = "ALLIANCE-EXPAC";
	if factionEN == "Horde" then
		expacKey = "HORDE-EXPAC";
	end;

	for className, classInfo in next, BUFFALO_CLASS_MATRIX_MASTER do
		if not classInfo[expacKey] or classInfo[expacKey] <= A.addonExpansionLevel then
			CLASS_MATRIX[className] = classInfo;
			CLASS_MASK_ALL = bit.bor(CLASS_MASK_ALL, classInfo["MASK"]);
		end;
	end;
end;


--[[
	Generate array of Classes with a Buff mask each.
	If the array already exists, info is preserved. This is
	so we can load the array from settings.
--]]
local function Buffalo_InitializeClassBuffs()
	if not CONFIG_AssignedClasses then
		CONFIG_AssignedClasses = { };
	end;

	for className, classInfo in next, BUFFALO_CLASS_MATRIX_MASTER do
		if not CONFIG_AssignedClasses[className] then
			--	The setting for this class does not exist. Create one by looking
			--	at the matrix defaults.
			local classMask = 0;
			for buffName, buffInfo in next, BUFF_MATRIX do

				if bit.band(classInfo["MASK"], buffInfo["CLASSES"]) > 0 then
					--	Strip off selfie buffs:
					local buffMask = bit.band(buffInfo["BITMASK"], 0x00ff);
					classMask = bit.bor(classMask, buffMask);
				end;
			end;
			CONFIG_AssignedClasses[className] = classMask;
		end;
	end;
	
	Buffalo_SetOption(CONFIG_KEY_AssignedClasses, CONFIG_AssignedClasses);
end;


local function Buffalo_MainInitialization(reloaded)
	Buffalo_CurrentRaidMode = BUFFALO_RAIDMODE_PERSONAL;
	Buffalo_InitializeConfigSettings();

	--	This sets the buffs up for MY class:
	BUFF_MATRIX = Buffalo_InitializeBuffMatrix();

	if not reloaded then
		local matrixCount = 0;
		for _ in pairs(BUFF_MATRIX) do 
			matrixCount = matrixCount + 1; 
		end;

		if matrixCount == 0 then
			--	This can fail if wow havent loaded all objects yet.
			--	We just wait a couple of seconds and try again:
			Buffalo_InitializationRetryTimer = TimerTick + 5;
			return;
		end;
	end;

	Buffalo_GroupBuffProperties = Buffalo_GetGroupBuffProperties();
	Buffalo_SelfBuffProperties = Buffalo_GetGroupBuffProperties(true);

	--	This sets up a matrix with icon+mask for each class, based on expansion level:
	Buffalo_InitializeClassMatrix();

	Buffalo_InitializeClassBuffs();

	Buffalo_InitializeBuffSettingsUI();

	--	Note: setting defaults should be part of the config, but at that time
	--	the Buffalo_InitializeBuffSync() has not yet been called.
	if table.getn(CONFIG_SynchronizedBuffs) == 0 then
		for buffIndex = 1, table.getn(Buffalo_OrderedBuffGroups), 1 do
			CONFIG_SynchronizedBuffs[buffIndex] = { };
			for groupIndex = 1, 8, 1 do
				CONFIG_SynchronizedBuffs[buffIndex][groupIndex] = {   
					["BUFFNAME"] = Buffalo_OrderedBuffGroups[buffIndex][2],
					["BITMASK"] = Buffalo_OrderedBuffGroups[buffIndex][3],
					["ICONID"] =  Buffalo_OrderedBuffGroups[buffIndex][4],
					["PLAYER"] = nil,
				};
			end;
		end;
	end;
	Buffalo_SetOption(CONFIG_KEY_SynchronizedBuffs, CONFIG_SynchronizedBuffs);

	Buffalo_RequestRaidModeUpdate();

	--	Expansion-specific settings.
	IsBuffer = false;
	if A.addonExpansionLevel == 1 or A.addonExpansionLevel == 2 or A.addonExpansionLevel == 3 then
		--	Check if the current class can cast buffs.
		--	Note: herbing/mining is excluded via the 0x00ff mask:
		for buffName, buffInfo in next, BUFF_MATRIX do
			if bit.band(buffInfo["BITMASK"], 0x00ff) > 0 then
				IsBuffer = true;
				break;
			end;
		end;
	end;

	if IsBuffer and CONFIG_BuffButtonVisible then
		BuffButton:Show();
	else
		BuffButton:Hide();
	end;

	Buffalo_InitializationComplete = true;

	if CONFIG_AnnounceMissingBuff and IsBuffer then
		A:echo("Buff data loaded, Buffalo is ready.");
	end;
end;

local function Buffalo_FilterTable(input, filterFunction)
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
local function Buffalo_ScanRaid()
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
		roster[unitid] = Buffalo_GetUnitRosterEntry(unitid, 1);

	elseif groupType == "party" then
		-- Get Players and pets in party
		unitid = "player";
		roster[unitid] = Buffalo_GetUnitRosterEntry(unitid, 1);

		for raidIndex = startNum, endNum, 1 do
			unitid = groupType..raidIndex;
			roster[unitid] = Buffalo_GetUnitRosterEntry(unitid, 1);

			-- No need to check pet for non-existing player
			if roster[unitid] then
				unitid = groupType .. "pet" .. raidIndex;
				roster[unitid] = Buffalo_GetUnitRosterEntry(unitid, 1);
			end;
		end;

	else	-- Raid
		for raidIndex = 1, 40, 1 do
			local name, rank, subgroup, level, _, filename, zone, online, dead, role, isML = GetRaidRosterInfo(raidIndex);
			if name then
				unitid = groupType..raidIndex;
				roster[unitid] = Buffalo_GetUnitRosterEntry(unitid, subgroup, online, dead);

				-- No need to check pet for non-existing player
				if roster[unitid] then
					unitid = groupType .. "pet" .. raidIndex;
					roster[unitid] = Buffalo_GetUnitRosterEntry(unitid, subgroup);
				end;

				-- Find unitid on current player:
				if name == playername then
					currentUnitid = unitid;
				end;
			end;
		end;
	end;

	local currentTime = GetTime();

	local assignedGroups = CONFIG_AssignedBuffGroups;
	if Buffalo_CurrentRaidMode ~= BUFFALO_RAIDMODE_PERSONAL then
		assignedGroups = CONFIG_AssignedRaidGroups;
	end;


	--	Part 2:
	--	This iterate over all players in party/raid and set the bitmapped buff mask on each
	--	applicable (i.e. not dead, not disconnected) player.
	local binValue;	
	for unitid, rosterInfo in next, roster do
		local buffMask = 0;

		--	This skips scanning for dead, offliners and people not in my group:
		local scanPlayerBuffs = true;
		local groupMask = bit.bor(assignedGroups[rosterInfo["Group"]], CONFIG_AssignedBuffSelf);

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

				local buffInfo = BUFF_MATRIX[buffName];
				if buffInfo then
					if expirationTime and duration > 0 then
						local timeOverlap = CONFIG_RenewOverlap;
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
							buffMask = bit.bor(buffMask, buffInfo["BITMASK"]);
						else
							--	Set expirationTime on roster object so we can check the time later on:
							local renewName = buffName;
							if buffInfo["SINGLE"] then 
								renewName = buffInfo["SINGLE"];
							end;

							if not roster[unitid] then 
								roster[unitid] = { }; 
							end;
							roster[unitid][renewName] = expirationTime;
						end;
					else
						buffMask = bit.bor(buffMask, buffInfo["BITMASK"]);
					end;
				end;
			end

			--	Add tracking icons ("Find Herbs", "Find Minerals" ...).
			--	Methods differs between classic and tbc:
			if A.addonExpansionLevel == 1 then
				--	Classic:
				--	Possible problem: Documentation does not state wether the returned name is localized or not.
				--	All examples shows English names, so going for that until I know better ...
				local trackingIcon = GetTrackingTexture();
				for buffName, buffInfo in next, BUFF_MATRIX do
					if buffInfo["ICONID"] == trackingIcon then
						--A.echo(string.format("<CLASSIC> Adding TrackingIcon buff:%s, mask:%s", buffName, buffInfo["BITMASK"]));
						buffMask = bit.bor(buffMask, buffInfo["BITMASK"]);
					end;
				end;
			elseif A.addonExpansionLevel > 1 then
				--	TBC / WOTLK:
				for n=1, GetNumTrackingTypes() do
					local buffName, spellID, active = GetTrackingInfo(n);
					if active then
						buffInfo = BUFF_MATRIX[buffName];
						if buffInfo then
							--echo(string.format("<TBC> Adding TrackingIcon buff:%s, mask:%s", buffName, buffInfo["BITMASK"]));
							buffMask = bit.bor(buffMask, buffInfo["BITMASK"]);
						end;
					end;
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
		local groupMask = assignedGroups[groupIndex] or 0;
		local filterFunction = function(entry)
			return entry["Group"] == groupIndex
		end;
		
		--	If groupMask is 0 then this group does not have any buffs to apply.
		if groupMask > 0 then
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
						--	Iterate over Party
						for unitid, rosterInfo in pairs(Buffalo_FilterTable(roster, filterFunction)) do
							-- Get player name (for debugging only)
							unitname = Buffalo_GetPlayerAndRealm(unitid);
							
							--	Check 1: Target must be online and alive:
							if rosterInfo and rosterInfo["IsOnline"] and not rosterInfo["IsDead"] then
								-- A:echo(string.format("Checking %s (%s) in group %s", unitname, unitid, groupIndex));
								groupMemberCounter = groupMemberCounter + 1;
									
								-- Check 2: Target class must be eligible for buff:
								local classMask = CONFIG_AssignedClasses[rosterInfo["Class"]];
								
								if (bit.band(classMask, buffInfo["BITMASK"]) > 0)	then
									-- A:echo(string.format("Class is eligible for buff, Buff=%s, Unit=%s", buffName, unitname));
									
									--	Check 3: Target must be in range:
									if IsSpellInRange(buffName, unitid) == 1 then
										-- A:echo(string.format("Spell in range, Buff=%s, Unit=%s, BuffClass=%d, ClassMask=%d", buffName, unitname, buffInfo["CLASSES"], rosterInfo["ClassMask"]));
										-- A:echo(string.format("%s - %s -> %s", rosterInfo["BuffMask"], buffInfo["BITMASK"], bit.band(rosterInfo["BuffMask"], buffInfo["BITMASK"])));
										--	Check 4: There's a person alive in this group. Do he needs this specific buff?
										if (bit.band(rosterInfo["BuffMask"], buffInfo["BITMASK"]) == 0) then
											-- A:echo(string.format("Found missing buff, unit=%s, group=%d, buff=%s", UnitName(unitid), groupIndex, buffName));
											-- A:echo(string.format("%s - %s -> %s", groupMask, buffInfo["BITMASK"], bit.band(groupMask, buffInfo["BITMASK"])));
											
											--	Check 5: Missing buff detected! "Selfie" buffs are only available by current player, e.g. "Inner Fire":
											if	(bit.band(groupMask, buffInfo["BITMASK"]) > 0) then							-- Raid buff
												buffMissingCounter = buffMissingCounter + 1;
												local priority = buffInfo["PRIORITY"];
												-- A:echo(string.format("Adding: unit=%s, group=%d, buff=%s", unitname, groupIndex, buffName));
												
												local expirationTime = roster[unitid][buffName];
												if expirationTime then
													--	Set priority so first expiring buffs are selected first.
													local seconds = math.floor(expirationTime - currentTime);
													priority = priority - (50 + seconds);
												end;
												MissingBuffsInGroup[buffMissingCounter] = { unitid, buffName, buffInfo["ICONID"], priority, expirationTime };
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
					local parentBuffInfo = BUFF_MATRIX[buffInfo["PARENT"]];
					if parentBuffInfo then
						local bufferUnitid = MissingBuffsInGroup[1][1];
						missingBuffIndex = missingBuffIndex + 1;
						local priority = parentBuffInfo["PRIORITY"] + (buffMissingCounter / groupMemberCounter * 5) + groupMemberCounter;
						MissingBuffs[missingBuffIndex] = { bufferUnitid, buffInfo["PARENT"], parentBuffInfo["ICONID"], priority, 0 };
					end;
				else
					-- Use single target buffing:
					for missingIndex = 1, buffMissingCounter, 1 do
						missingBuffIndex = missingBuffIndex + 1;
						MissingBuffs[missingBuffIndex] = MissingBuffsInGroup[missingIndex];
						-- A:echo(string.format("%d - %s(%s) | buff: %s", missingIndex, MissingBuffs[missingBuffIndex][1], Buffalo_GetPlayerAndRealm(MissingBuffs[missingBuffIndex][1]), MissingBuffs[missingBuffIndex][2]));
					end;
				end;
			end;	-- end iterate buff matrix
		end;
	end;	--	End iterate raid groups


	--	Self buffs:
	local groupMask = CONFIG_AssignedBuffSelf;
	if groupMask > 0 then
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
	
					--	Check 1: Target must be online and alive:
					if rosterInfo and not rosterInfo["IsDead"] then
						--echo(string.format("Checking %s (%s)", GetUnitName(currentUnitid, true), currentUnitid));

						--	Check 4: Target must be in range (and know the spell)
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

									local expirationTime = rosterInfo[buffName];
									if expirationTime then
										--	Set priority so first expiring buffs are selected first.
										local seconds = math.floor(expirationTime - currentTime);
										priority = priority - (50 + seconds);
									end;

									MissingBuffs[missingBuffIndex] = { currentUnitid, buffName, buffInfo["ICONID"], priority, expirationTime};
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
		--A:echo("num: "..#MissingBuffs);
		for i, missingBuff in ipairs(MissingBuffs) do
			--A:echo(i..": "..missingBuff[2].."("..missingBuff[4]..") on: "..missingBuff[1]);
		end

		--	Now pick first buff from list and set icon:
		local missingBuff = MissingBuffs[1];
		unitid = missingBuff[1];

		local buffName = missingBuff[2];
		if CONFIG_AnnounceMissingBuff then
			local targetPlayer = Buffalo_GetPlayerAndRealm(unitid);
			local targetStatus = "MISSING";
			local expirationTime = missingBuff[5];

			if expirationTime and expirationTime > 0 then
				targetStatus = "RENEW";
			end;

			if lastBuffTarget ~= targetPlayer..buffName or lastBuffStatus ~= targetStatus then
				lastBuffTarget = targetPlayer..buffName;
				lastBuffStatus = targetStatus;

				if expirationTime and expirationTime > 0 then
					local seconds = math.ceil(expirationTime - currentTime);
					local minutes = math.floor(seconds / 60);
					seconds = seconds - minutes * 60;

					A:echo(string.format("%s's %s%s%s will expire in %02d:%02d.", targetPlayer, BUFFALO_COLOUR_EXPIRING, buffName, A.chatColorNormal, minutes, seconds));
				else
					A:echo(string.format("%s is missing %s%s%s.", targetPlayer, BUFFALO_COLOUR_MISSING, buffName, A.chatColorNormal));
				end;
			end;
		end;

		if debug then
			A:echo(string.format("DEBUG: Buffing unit=%s(%s), Buff=%s, Icon=%s", unitid, targetPlayer, buffName, missingBuff[3]));
		end;

		Buffalo_UpdateBuffButton(unitid, buffName, missingBuff[3]);
	else
		Buffalo_UpdateBuffButton();

		if CONFIG_AnnounceMissingBuff then
			if lastBuffTarget ~= "" then
				A:echo("No pending buffs.");
				
				lastBuffTarget = "";
				lastBuffStatus = "";
			end;
		end;
	end;
end;

function Buffalo_ComparePriority(a, b)
	return a[4] > b[4];
end;



--[[
	UI Control
--]]
function Buffalo_OpenConfigurationDialogue()
	Buffalo_UpdateGroupBuffUI();

	Buffalo_CloseClassConfigDialogue();
	Buffalo_CloseGeneralConfigDialogue();
	BuffaloConfigFrame:Show();
end;

function Buffalo_CloseConfigurationDialogue()
	Buffalo_CloseClassConfigDialogue();
	Buffalo_CloseGeneralConfigDialogue();
	BuffaloConfigFrame:Hide();
end;

function Buffalo_OpenGeneralConfigDialogue()
	Buffalo_RefreshGeneralSettingsUI();

	local bleft = BuffaloConfigFrame:GetLeft();
	local btop = BuffaloConfigFrame:GetTop();
	local bwidth, cwidth = BuffaloConfigFrame:GetWidth(), BuffaloGeneralConfigFrame:GetWidth();
	local bheight, cheight = BuffaloConfigFrame:GetHeight(), BuffaloGeneralConfigFrame:GetHeight();

	local height = btop - cheight + 20;
	local left = bleft + ((bwidth - cwidth) / 2);
	
	BuffaloGeneralConfigFrame:SetPoint("BOTTOMLEFT", left, height);
	BuffaloGeneralConfigFrame:Show();
end;

function Buffalo_CloseGeneralConfigDialogue()
	BuffaloGeneralConfigFrame:Hide();
end;

function Buffalo_OpenClassConfigDialogue()
	Buffalo_RefreshClassSettingsUI();

	local bleft, btop = BuffaloConfigFrame:GetLeft(), BuffaloConfigFrame:GetTop();
	local bwidth, cwidth = BuffaloConfigFrame:GetWidth(), BuffaloClassConfigFrame:GetWidth();
	local cheight = BuffaloClassConfigFrame:GetHeight();

	local height = btop - cheight - 30;
	local left = bleft + ((bwidth - cwidth) / 2);
	
	BuffaloClassConfigFrame:SetPoint("BOTTOMLEFT", left, height);
	BuffaloClassConfigFrame:Show();
end;

function Buffalo_CloseClassConfigDialogue()
	BuffaloClassConfigFrame:Hide();
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
	if unitid and not UnitAffectingCombat("player") then
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

function Buffalo_OnBeforeBuffClick(self, ...)
	lastBuffFired = BuffButton:GetAttribute("spell");
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
	local selfiePrioMask = 0x03f00;
	if includeSelfBuffs then
		includeMask = 0x0ffff;
		selfiePrio = 50;
	end;
	for buffName, props in pairs(BUFF_MATRIX) do
		if not props["GROUP"] and (bit.band(props["BITMASK"], includeMask) > 0) then
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

--	Initialize the overall buffing UI.
--	UI is split into PERSONAL and RAID buffing UI.
--	This function will initiate both, but the Update function
--	will only show the current active one.
function Buffalo_InitializeBuffSettingsUI()
	local buffCount = table.getn(Buffalo_GroupBuffProperties);
	local selfCount = table.getn(Buffalo_SelfBuffProperties);

	local posX, posY;
	local UISettings = {
		Top = 0,
		Left = 120,
		Width = 100,
		Height = 40,
		ButtonWidth = 200,
	};

	--	Generate Raid Mode buttons:
	posX = UISettings.Left;
	posY = UISettings.Top - 40;
	for _, raidmode in next, Buffalo_RaidModes do
		local buttonName = string.format("raidmode_%s", raidmode["RAIDMODE"]);
		local fButton = CreateFrame("Button", buttonName, BuffaloConfigFrame, "BuffaloBuffButtonTemplate");
		fButton:SetPoint("TOPLEFT", posX, posY);
		fButton:SetNormalTexture(raidmode["ICON"]);
		fButton:SetPushedTexture(raidmode["ICON"]);
		if raidmode["RAIDMODE"] == Buffalo_CurrentRaidMode then
			fButton:SetAlpha(BUFFALO_ALPHA_ENABLED);
		else
			fButton:SetAlpha(BUFFALO_ALPHA_DISABLED);
		end;

		local fLabel = fButton:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		fLabel:SetText(raidmode["CAPTION"]);
		fLabel:SetPoint("LEFT", 40, 0);
		fButton:SetScript("OnClick", Buffalo_RaidModeOnClick);
		fButton:Show();

		posX = posX + UISettings.ButtonWidth;
	end;

	--	Generate group labels:
	posX = UISettings.Left;
	posY = UISettings.Top - 80;
	for groupIndex = 1, 8, 1 do
		local labelName = string.format("buffgrouplabel_%s", groupIndex);
		local fLabel = BuffaloConfigFrame:CreateFontString(labelName, "ARTWORK", "GameFontNormal");
		fLabel:SetText(string.format("Group %s", groupIndex));
		fLabel:SetPoint("TOPLEFT", posX, posY);
		fLabel:SetTextColor(BUFFALO_COLOR_GROUPLABELS[1], BUFFALO_COLOR_GROUPLABELS[2], BUFFALO_COLOR_GROUPLABELS[3]);
	
		posX = posX + UISettings.Width;
	end;


	Buffalo_InitializePersonalGroupBuffs(UISettings);
	Buffalo_InitializeRaidGroupBuffs(UISettings);


	--	SELF buffs, label:
	posX = 32;
	posY = -10;
	local fLabel = BuffaloConfigFrameSelf:CreateFontString("selfbufflabel", "ARTWORK", "GameFontNormal");
	fLabel:SetText("Self buffs");
	fLabel:SetPoint("TOPLEFT", posX, posY);
	fLabel:SetTextColor(BUFFALO_COLOR_GROUPLABELS[1], BUFFALO_COLOR_GROUPLABELS[2], BUFFALO_COLOR_GROUPLABELS[3]);

	--	Iterate over all buffs and render icons.
	posX = UISettings.Left;
	posY = 0;
	for rowNumber = 1, selfCount, 1 do
		buttonName = string.format("buffalo_personal_buff_%d_0", rowNumber);
		local entry = CreateFrame("Button", buttonName, BuffaloConfigFrameSelf, "BuffaloGroupButtonTemplate");
		entry:SetAlpha(BUFFALO_ALPHA_DISABLED);
		entry:SetPoint("TOPLEFT", posX, posY);
		entry:SetNormalTexture(Buffalo_SelfBuffProperties[rowNumber][2]);
		entry:SetPushedTexture(Buffalo_SelfBuffProperties[rowNumber][2]);

		posX = posX + UISettings.Width;
	end;


	--	Class configuration:
	local colWidth = 40;				-- Width of each column.
	local rowHeight = 40;				-- Height of each row.
	local posX, posY, buffMask;

	--	Step 1:
	--	Display a row of Class icons.
	posX = 0;
	posY = 0;
	for className, classInfo in next, CLASS_MATRIX do
		buttonName = string.format("ClassImage%s", className);

		local entry = CreateFrame("Button", buttonName, BuffaloClassConfigFrameClass, "BuffaloClassButtonTemplate");
		entry:SetAlpha(BUFFALO_ALPHA_ENABLED);
		entry:SetPoint("TOPLEFT", posX, posY);
		entry:SetNormalTexture(classInfo["ICONID"]);
		entry:SetPushedTexture(classInfo["ICONID"]);

		posX = posX + colWidth;
	end;


	--	Step 2:
	--	Display buff image for each buff+class combo:
	posY = 0;
	buffCount = table.getn(Buffalo_GroupBuffProperties);
	for rowNumber = 1, buffCount, 1 do
		posX = 0;
		posY = posY - rowHeight;

		for className, classInfo in next, CLASS_MATRIX do
			-- We just disable the buttons, we will refresh status in a second.
			buttonName = string.format("%s_row%s", className, rowNumber);

			local entry = CreateFrame("Button", buttonName, BuffaloClassConfigFrameClass, "BuffaloBuffButtonTemplate");
			entry:SetAlpha(BUFFALO_ALPHA_DISABLED);
			entry:SetPoint("TOPLEFT", 4+posX, posY);
			entry:SetNormalTexture(Buffalo_GroupBuffProperties[rowNumber][2]);
			entry:SetPushedTexture(Buffalo_GroupBuffProperties[rowNumber][2]);

			posX = posX + colWidth;
		end;
	end;
	
	--	Set windows size to fit icons for class config:
	BuffaloClassConfigFrame:SetHeight(128 + buffCount * rowHeight);
	BuffaloClassConfigFrame:SetWidth(posX + 52);
	BuffaloClassConfigFrameHeaderTexture:SetWidth(2 * (posX + 52));
end;

local personalBuffFrameHeight = 0;
function Buffalo_InitializePersonalGroupBuffs(UISettings)
	local buffCount = table.getn(Buffalo_GroupBuffProperties);
	local posX, posY;

	--	RAID buffs:
	--	Iterate over all groups and render icons.
	--	Note: all icons are dimmed out as if they were disabled.
	--	We will refresh the alpha value after rendering.
	local buttonName;
	for groupNumber = 1, 8, 1 do
		posX = UISettings.Left + UISettings.Width * (groupNumber - 1);
		posY = UISettings.Top - 20;
		for rowNumber = 1, buffCount, 1 do
			buttonName = string.format("buffalo_personal_buff_%d_%d", rowNumber, groupNumber);
			local entry = CreateFrame("Button", buttonName, BuffaloConfigFramePersonal, "BuffaloGroupButtonTemplate");
			entry:SetAlpha(BUFFALO_ALPHA_DISABLED);
			entry:SetPoint("TOPLEFT", posX, posY);
			entry:SetNormalTexture(Buffalo_GroupBuffProperties[rowNumber][2]);
			entry:SetPushedTexture(Buffalo_GroupBuffProperties[rowNumber][2]);

			posY = posY - UISettings.Height;
		end;
	end;

	personalBuffFrameHeight = posY * -1;
end;

local raidBuffFrameHeight = 0;
function Buffalo_InitializeRaidGroupBuffs(UISettings)

	--	Iterate over all buffs for this class, and store result in a "temp" table
	--	so we do not do this every time we update also.
	--	Sync.Buffs = { priority, buffname, buffmask, iconid }
	Buffalo_OrderedBuffGroups = { };
	for buffName, buffInfo in next, BUFF_MATRIX do
		if not buffInfo["GROUP"] and bit.band(buffInfo["BITMASK"], 0x00ff) > 0 then
			tinsert(Buffalo_OrderedBuffGroups, { buffInfo["PRIORITY"], buffName, buffInfo["BITMASK"], buffInfo["ICONID"] });
		end;
	end;

	--	And now in correct order (by priority):
	table.sort(Buffalo_OrderedBuffGroups, function (a, b) return a[1] > b[1]; end);

	--	Render the buff icon, and thereby defining the final size of the frame:
	local posX = 32;
	local posY = UISettings.Top - 20;
	for buffIndex = 1, table.getn(Buffalo_OrderedBuffGroups), 1 do
		local buttonName = string.format("buffrow_%s", buffIndex);
		local fButton = CreateFrame("Button", buttonName, BuffaloConfigFrameRaid, "BuffaloBuffButtonTemplate");
		fButton:SetPoint("TOPLEFT", posX, posY);
		fButton:SetNormalTexture(Buffalo_OrderedBuffGroups[buffIndex][4]);
		fButton:SetPushedTexture(Buffalo_OrderedBuffGroups[buffIndex][4]);
		fButton:SetScript("OnClick", nil);

		posY = posY - UISettings.Height;
	end;

	raidBuffFrameHeight = -1 * posY;
	
	--	Now render frame buttons for all potential buffers.
	posY = UISettings.Top - 20;
	for buffIndex = 1, table.getn(Buffalo_OrderedBuffGroups), 1 do
		posX = UISettings.Left;

		for groupIndex = 1, 8, 1 do
			local bufferName = string.format("buffgroup_%s_%s", buffIndex, groupIndex);

			local fBuffer = CreateFrame("Button", bufferName, BuffaloConfigFrameRaid, "GroupBuffTemplate");
			fBuffer:SetPoint("TOPLEFT", posX, posY);
			_G[bufferName.."Text"]:SetTextColor(BUFFALO_COLOR_UNUSED[1], BUFFALO_COLOR_UNUSED[2], BUFFALO_COLOR_UNUSED[3]);
			_G[bufferName.."Text"]:SetText(BUFFALO_SYNC_UNUSED);
			fBuffer:Show();

			posX = posX + UISettings.Width;
		end;
		posY = posY - UISettings.Height;
	end;
end;

--	Switch raidmode:
--	Must be promoted to Switch
function Buffalo_RaidModeOnClick(sender)
	local buttonName = sender:GetName();

	local _, _, raidmode = string.find(buttonName, "raidmode_(%d*)");
	if raidmode then
		raidmode = tonumber(raidmode);

		local unitIsPromoted = Buffalo_UnitIsPromoted("player");

		--	Raidmode 1 and 2 may reqire promotions, so check both current and new mode:
		--	Scenario 1: We switch to raid mode 1 (raidmode=OPEN), or
		--	Scenario 2: We swithc FROM raid mode 1 (currentRM=OPEN):
		if raidmode == BUFFALO_RAIDMODE_OPEN or Buffalo_CurrentRaidMode == BUFFALO_RAIDMODE_OPEN then
			if BUFFALO_RaidMode1RequiresPromotion and not unitIsPromoted then
				A:echo("You cannot change raid mode unless you are promoted.");
				return;
			end;
		end;

		if raidmode == BUFFALO_RAIDMODE_CLOSED or Buffalo_CurrentRaidMode == BUFFALO_RAIDMODE_CLOSED then
			if BUFFALO_RaidMode2RequiresPromotion and not unitIsPromoted then
				A:echo("You cannot change raid mode unless you are promoted.");
				return;
			end;
		end;

		if raidmode == BUFFALO_RAIDMODE_PERSONAL then
			Buffalo_RaidModeLockedBy = "";
		else
			Buffalo_RaidModeLockedBy = Buffalo_PlayerNameAndRealm;
		end;

		Buffalo_SetRaidMode(raidmode, true);
	end;

	Buffalo_UpdateGroupBuffUI();
end;

--	Change raidmode:
--	UI is updated, and if AnnounceRaidModeChange is set, a message is sent
--	to all other people of same class.
function Buffalo_SetRaidMode(raidmode, AnnounceRaidModeChange)
	Buffalo_CurrentRaidMode = tonumber(raidmode);

	if AnnounceRaidModeChange then
		A:sendAddonMessage(string.format("TX_RAIDMODE#%s#%s", raidmode, Buffalo_PlayerClass));
	end;

	Buffalo_UpdateGroupBuffUI();
end;

--	Called when another client switches raid mode.
function Buffalo_HandleTXRaidMode(message, sender)
	local raidmode = tonumber(message);

	if raidmode == BUFFALO_RAIDMODE_PERSONAL then
		Buffalo_RaidModeLockedBy = "";
	else
		Buffalo_RaidModeLockedBy = sender;
	end;

	if sender == Buffalo_PlayerNameAndRealm then
		-- If sender is myself, no need to refresh or update again	
		return;
	end;

	Buffalo_SetRaidMode(raidmode);

	if not BUFFALO_DisplayRaidModeChanges then
		--	Displaying raid mode changes has been disabled.
		return;
	end;

	for _, rmInfo in next, Buffalo_RaidModes do
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
function Buffalo_HandleTXRdUpdate(message, sender)
	local _, _, buffIndex, groupIndex, playername = string.find(message, "([^/]*)/([^/]*)/([^/]*)");

	buffIndex = tonumber(buffIndex);
	groupIndex = tonumber(groupIndex);

	local buffInfo = CONFIG_SynchronizedBuffs[buffIndex][groupIndex];	-- Assignment for a specific row + group
	if playername == "" then
		buffInfo["PLAYER"] = nil;
	else
		buffInfo["PLAYER"] = playername;
	end;

	Buffalo_UpdateGroupBuffUI();
end;

--	TX_QRYRAIDMODE:
--	If player is promoted, answer current raidmode back.
function Buffalo_HandleTXQueryRaidMode(message, sender)
	A:sendAddonMessage(string.format("RX_QRYRAIDMODE#%s/%s#%s", Buffalo_CurrentRaidMode, Buffalo_RaidModeLockedBy, sender));
end;

--	RX_QRYRAIDMODE:
function Buffalo_HandleRXQueryRaidMode(message, sender)
	local _, _, raidmode, lockedBy = string.find(message, "([^/]*)/([^/]*)");

	raidmode = tonumber(raidmode);
	if raidmode and (raidmode == BUFFALO_RAIDMODE_OPEN or raidmode == BUFFALO_RAIDMODE_CLOSED) then
		Buffalo_SetRaidMode(raidmode);
		Buffalo_RaidModeLockedBy = lockedBy or "";

		--	Now we got the raidmode solved, but we don't have the raid assignments yet.
		--	This time we know who to ask.
		--	However there is a potential problem here: 
		--	If more than one person whispers back we don't want to send requests to ALL
		--	of them, only the first one. 
		if not Buffalo_RaidModeQueryDone then
			Buffalo_RaidModeQueryDone = true;
			A:sendAddonMessage(string.format("TX_QRYRAIDASSIGNMENTS##%s", sender));
		end;

		Buffalo_UpdateGroupBuffUI();
	end;
end;

function Buffalo_RequestRaidModeUpdate()
	if IsInRaid() then
		Buffalo_RaidModeQueryDone = false;
		Buffalo_ResetRaidAssignments();

		A:sendAddonMessage(string.format("TX_QRYRAIDMODE##%s", Buffalo_PlayerClass));
	end;
end;

--	Send all assignments for current raid back to the requester.
function Buffalo_HandleTXQueryRaidAssignments(message, sender)
	for groupIndex = 1, 8, 1 do
		local payload = string.format("%s", groupIndex);

		--	Note: We HAVE to set a name in the empty spots, otherwise string split later on fucks up:
		for buffIndex = 1, table.getn(CONFIG_SynchronizedBuffs), 1 do
			local syncBuff = CONFIG_SynchronizedBuffs[buffIndex][groupIndex];
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

function Buffalo_HandleRXQueryRaidAssignments(message, sender)
	local _, _, groupIndex, buffers = string.find(message, "([^/]*)/(%S*)");

	groupIndex = tonumber(groupIndex);
	local buffTable = Buffalo_SplitString(buffers);

	for buffIndex = 1, table.getn(buffTable), 1 do
		local buffer = buffTable[buffIndex];
		if buffer == "?" then
			buffer = nil;
		end;
		CONFIG_SynchronizedBuffs[buffIndex][groupIndex]["PLAYER"] = buffer;
	end;
end;

function Buffalo_SplitString(string, separator)
	if not separator then
		separator = "/";
	end;

	local worktable = { };
	for str in string.gmatch(string, "([^"..separator.."]+)") do
		table.insert(worktable, str);
	end;
	return worktable;
end;

function Buffalo_ResetRaidAssignments()
	for buffIndex = 1, table.getn(CONFIG_SynchronizedBuffs), 1 do
		for groupIndex = 1, 8, 1 do
			CONFIG_SynchronizedBuffs[buffIndex][groupIndex]["PLAYER"] = nil;
		end;
	end;
end;


function Buffalo_UnitIsPromoted(unitid)
	return UnitIsGroupAssistant(unitid) or UnitIsGroupLeader(unitid);
end;

local Buffalo_SyncClass = nil;
local Buffalo_SyncBuff = nil;
local Buffalo_SyncGroup = nil;
function Buffalo_SyncBuffGroupOnClick(sender)
	local buttonName = sender:GetName();
	local _, _, buffIndex, groupIndex = string.find(buttonName, "buffgroup_(%d)_(%d)");

	if not buffIndex or not groupIndex then return; end;

	Buffalo_SyncClass = Buffalo_PlayerClass;	-- Only support current class (raid mode 1+2)
	Buffalo_SyncBuff = tonumber(buffIndex);
	Buffalo_SyncGroup = tonumber(groupIndex);

	--	Now we are ready to open the popup ...!
	ToggleDropDownMenu(1, nil, Buffalo_SyncBuffGroupDropdownMenu, "cursor", 3, -3);

	Buffalo_UpdateAssignedRaidGroups();
end;

--	Re-generate group buff mask for groups in a Raid.
function Buffalo_UpdateAssignedRaidGroups()
	if Buffalo_CurrentRaidMode == BUFFALO_RAIDMODE_PERSONAL then return; end;

	local raidGroups = { };
	for groupIndex = 1, 8, 1 do
		local groupMask = 0;
	
		for buffIndex = 1, table.getn(Buffalo_OrderedBuffGroups), 1 do
			local buffInfo = CONFIG_SynchronizedBuffs[buffIndex][groupIndex];	-- Assignment for a specific row + group
			local buff = Buffalo_OrderedBuffGroups[buffIndex];					-- Data for a specific buff

			if buffInfo["PLAYER"] == Buffalo_PlayerNameAndRealm then
				groupMask = bit.bor(groupMask, buffInfo["BITMASK"]);
			end;
		end;

		raidGroups[groupIndex] = groupMask;
	end;

	CONFIG_AssignedRaidGroups = raidGroups;
end;

function Buffalo_SyncBuffGroupDropdownMenu_Initialize(self, level, menuList)
	--	Unassign: first choice.
	local info = UIDropDownMenu_CreateInfo();
	info.notCheckable = true;
	info.text       = BUFFALO_SYNC_UNUSED;
	info.icon		= nil;
	info.func       = function() Buffalo_SyncBuffGroupDropdownMenu_OnClick(this, nil) end;
	UIDropDownMenu_AddButton(info);

	local classInfo = CLASS_MATRIX[Buffalo_SyncClass];
	local players = Buffalo_GetPlayersInRoster(classInfo["MASK"]);
	for playerIndex = 1, table.getn(players), 1 do
		local info = UIDropDownMenu_CreateInfo();
		info.notCheckable = true;
		info.text       = players[playerIndex]["NAME"];
		info.icon		= players[playerIndex]["ICONID"];
		info.func       = function() Buffalo_SyncBuffGroupDropdownMenu_OnClick(this, players[playerIndex]) end;
		UIDropDownMenu_AddButton(info);
	end
end;

--	nil means unassign
function Buffalo_SyncBuffGroupDropdownMenu_OnClick(sender, playerInfo)
	local syncBuff = CONFIG_SynchronizedBuffs[Buffalo_SyncBuff][Buffalo_SyncGroup];

	if playerInfo then
		syncBuff["PLAYER"] = playerInfo["NAME"];
	else
		syncBuff["PLAYER"] = nil;
	end;

	--	Send a message to clients of same class that buff assignments was updated.
	local payload = string.format("%s/%s/%s", Buffalo_SyncBuff, Buffalo_SyncGroup, syncBuff["PLAYER"] or "");
	A:sendAddonMessage(string.format("TX_RDUPDATE#%s#%s", payload, Buffalo_PlayerClass));

	Buffalo_UpdateGroupBuffUI();
end;

function Buffalo_GetUnitRosterEntry(unitid, group, isOnline, isDead)
	if string.find(unitid, "pet") then
		local group = group or 1;
		local isOnline = isOnline or (0 and UnitIsConnected(unitid) and 1);
		local isDead   = isDead or (0 and UnitIsDead(unitid) and 1);
		local classname = "PET"

		if isOnline then
			return { ["Group"]=group, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["Class"]=classname, ["ClassMask"]=CLASS_MATRIX[classname]["MASK"] };
		end;
	elseif unitid == "player" and group == 1 then
		return { ["Group"]=1, ["IsOnline"]=true, ["IsDead"]=nil, ["BuffMask"]=0, ["Class"]=Buffalo_PlayerClass, ["ClassMask"]=CLASS_MASK_ALL };
	else
		local isOnline = 0 and UnitIsConnected(unitid) and 1;
		local isDead   = 0 and UnitIsDead(unitid) and 1;
		local _, classname = UnitClass(unitid);
	
		if classname then
			local classUpper = string.upper(classname);
			return { ["Group"]=group, ["IsOnline"]=isOnline, ["IsDead"]=isDead, ["BuffMask"]=0, ["Class"]=classUpper, ["ClassMask"]=CLASS_MATRIX[classname]["MASK"] };
		end;
	end;

	return nil;
end;

function Buffalo_GetPlayersInRoster(classMask)
	local players = { };		-- List of { "NAME", "MASK", "ICONID", "CLASS" }

	if IsInRaid() then
		for n = 1, 40, 1 do
			local unitid = "raid"..n;
			if not UnitName(unitid) then break; end;
			
			local fullName = Buffalo_GetPlayerAndRealm(unitid);
			local _, className = UnitClass(unitid);
			local classInfo = CLASS_MATRIX[className];

			if bit.band(classInfo["MASK"], classMask) > 0 then
				tinsert(players, { 
					["NAME"] = fullName,
					["MASK"] = classInfo["MASK"], 
					["ICONID"] = classInfo["ICONID"],
					["CLASS"] = className,
				});
			end;
		end;

	elseif Buffalo_IsInParty() then
		for n = 1, GetNumGroupMembers(), 1 do
			local unitid = "party"..n;
			if not UnitName(unitid) then
				unitid = "player";
			end;

			local fullName = Buffalo_GetPlayerAndRealm(unitid);
			local _, className = UnitClass(unitid);		
			local classInfo = CLASS_MATRIX[className];

			if bit.band(classInfo["MASK"], classMask) > 0 then
				tinsert(players, {
					["NAME"] = fullName, 
					["MASK"] = classInfo["MASK"], 
					["ICONID"] = classInfo["ICONID"],
					["CLASS"] = className, 
				});
			end;
		end;
	else
		--	SOLO play, somewhat usefull when testing
		local unitid = "player";
		local fullName = Buffalo_GetPlayerAndRealm(unitid);
		local _, className = UnitClass(unitid);
		local classInfo = CLASS_MATRIX[className];

		if bit.band(classInfo["MASK"], classMask) > 0 then
			tinsert(players, {
				["NAME"] = fullName,
				["MASK"] = classInfo["MASK"], 
				["ICONID"] = classInfo["ICONID"],
				["CLASS"] = className,
			});
		end;
	end;

	return players;
end;

function Buffalo_OnGroupRosterUpdate()
	if not isInRaid then
		Buffalo_SetRaidMode(BUFFALO_RAIDMODE_PERSONAL);
	else
		Buffalo_UpdateRaidModeButtons();
	end;
end;

--	Update Buffing UI (main entry)
--	This will update PERSONAL or RAID buffs, depending on raid mode.
function Buffalo_UpdateGroupBuffUI()
	if not Buffalo_InitializationComplete then
		return;
	end;

	local frame = nil;
	local height = 0;
	if Buffalo_CurrentRaidMode == BUFFALO_RAIDMODE_PERSONAL then
		BuffaloConfigFrameCaption:SetText("Assign buffs for specific groups by left/right clicking the icons.");

		local backdrops = {
			["DRUID"] = BUFFALO_BACKDROP_RAIDMODE0_DRUID_FRAME,
			["MAGE"] = BUFFALO_BACKDROP_RAIDMODE0_MAGE_FRAME,
			["PRIEST"] = BUFFALO_BACKDROP_RAIDMODE0_PRIEST_FRAME,
		};

		BuffaloConfigFrame:SetBackdrop(backdrops[Buffalo_PlayerClass]);

		BuffaloConfigFrameRaid:Hide();
		frame = BuffaloConfigFramePersonal;
		height = personalBuffFrameHeight;

		Buffalo_UpdatePersonalBuffUI();
	else
		if Buffalo_CurrentRaidMode == BUFFALO_RAIDMODE_OPEN then
			BuffaloConfigFrameCaption:SetText(string.format("Raid assignments are enabled by [%s]", Buffalo_RaidModeLockedBy));
			BuffaloConfigFrame:SetBackdrop(BUFFALO_BACKDROP_RAIDMODE1_FRAME);
		else -- BUFFALO_RAIDMODE_CLOSED
			BuffaloConfigFrameCaption:SetText(string.format("Raid assignments are locked by [%s]", Buffalo_RaidModeLockedBy));
			BuffaloConfigFrame:SetBackdrop(BUFFALO_BACKDROP_RAIDMODE2_FRAME);
		end;

		BuffaloConfigFramePersonal:Hide();
		frame = BuffaloConfigFrameRaid;
		height = raidBuffFrameHeight;

		Buffalo_UpdateRaidBuffUI();
	end;

	frame:SetHeight(height);
	BuffaloConfigFrame:SetHeight(frame:GetHeight() + 230);
	frame:Show();

	Buffalo_UpdateRaidModeButtons();

	--	SELF buffs:
	--	Iterate over all rows and render icons.
	local buttonName, entry;
	local buffMask = CONFIG_AssignedBuffSelf;

	buffCount = table.getn(Buffalo_SelfBuffProperties);
	for rowNumber = 1, buffCount, 1 do
		buttonName = string.format("buffalo_personal_buff_%d_0", rowNumber);
		entry = _G[buttonName];

		if (bit.band(buffMask, Buffalo_SelfBuffProperties[rowNumber][3]) > 0) then
			entry:SetAlpha(BUFFALO_ALPHA_ENABLED);
		else
			entry:SetAlpha(BUFFALO_ALPHA_DISABLED);
		end;
	end;
end;

function Buffalo_UpdateRaidModeButtons()
	--	Generate Raid mode buttons:
	--	They are only visible when in a Raid:
	local isInRaid = IsInRaid();
	for _, raidmode in next, Buffalo_RaidModes do
		local fButton = _G[string.format("raidmode_%s", raidmode["RAIDMODE"])];
		if isInRaid then
			if raidmode["RAIDMODE"] == Buffalo_CurrentRaidMode then
				fButton:SetAlpha(BUFFALO_ALPHA_ENABLED);
			else
				fButton:SetAlpha(BUFFALO_ALPHA_DISABLED);
			end;
			fButton:Show();
		else
			fButton:Hide();
		end;
	end;
end;

function Buffalo_UpdatePersonalBuffUI()
	local buffCount = table.getn(Buffalo_GroupBuffProperties);

	local assignedGroups = CONFIG_AssignedBuffGroups;
	if Buffalo_CurrentRaidMode ~= BUFFALO_RAIDMODE_PERSONAL then
		assignedGroups = CONFIG_AssignedRaidGroups;
	end;

	--	PERSONAL raid buffs:
	--	Iterate over all groups and render icons.
	for groupNumber = 1, 8, 1 do
		--local buffMask = CONFIG_AssignedBuffGroups[groupNumber];
		local buffMask = assignedGroups[groupNumber];

		for rowNumber = 1, buffCount, 1 do
			local buttonName = string.format("buffalo_personal_buff_%d_%d", rowNumber, groupNumber);
			local entry = _G[buttonName];

			local alpha = BUFFALO_ALPHA_DISABLED;
			if (bit.band(buffMask, Buffalo_GroupBuffProperties[rowNumber][3]) > 0) then
				alpha = BUFFALO_ALPHA_ENABLED;
			end;

			if Buffalo_CurrentRaidMode ~= BUFFALO_RAIDMODE_PERSONAL then
				entry:Disable();
			else
				entry:Enable();
			end;			

			entry:SetAlpha(alpha);
		end;
	end;
end;

function Buffalo_UpdateRaidBuffUI()
	if not Buffalo_OrderedBuffGroups then return; end;

	for buffIndex = 1, table.getn(Buffalo_OrderedBuffGroups), 1 do

		for groupIndex = 1, 8, 1 do
			local bufferName = string.format("buffgroup_%s_%s", buffIndex, groupIndex);
			local fBuffer = _G[bufferName];

			local buffInfo = CONFIG_SynchronizedBuffs[buffIndex][groupIndex];
			if buffInfo["PLAYER"] then
				_G[bufferName.."Text"]:SetTextColor(BUFFALO_COLOR_BUFFER[1], BUFFALO_COLOR_BUFFER[2], BUFFALO_COLOR_BUFFER[3]);
				_G[bufferName.."Text"]:SetText(buffInfo["PLAYER"]);
			else
				_G[bufferName.."Text"]:SetTextColor(BUFFALO_COLOR_UNUSED[1], BUFFALO_COLOR_UNUSED[2], BUFFALO_COLOR_UNUSED[3]);
				_G[bufferName.."Text"]:SetText(BUFFALO_SYNC_UNUSED);
			end;
		end;
	end;

	Buffalo_UpdateAssignedRaidGroups();
end;

function Buffalo_RefreshGeneralSettingsUI()
	--	Refresh sliders with value and text:
	BuffaloConfigFramePrayerThreshold:SetValue(CONFIG_GroupBuffThreshold);
	BuffaloSliderPrayerThresholdText:SetText(string.format("%s/5 people", CONFIG_GroupBuffThreshold));

	BuffaloConfigFrameRenewOverlap:SetValue(CONFIG_RenewOverlap);
	BuffaloSliderRenewOverlapText:SetText(string.format("%s seconds", CONFIG_RenewOverlap));

	BuffaloConfigFrameScanFrequency:SetValue(CONFIG_ScanFrequency * 10);
	BuffaloSliderScanFrequencyText:SetText(string.format("%s/10 sec.", CONFIG_ScanFrequency * 10));

	--	Refresh checkboxes:
	local checkboxValue = nil;
	if CONFIG_AnnounceMissingBuff then
		checkboxValue = 1;
	end;
	BuffaloConfigFrameOptionAnnounceMissing:SetChecked(checkboxValue);

	checkboxValue = nil;
	if CONFIG_AnnounceCompletedBuff then
		checkboxValue = 1;
	end;
	BuffaloConfigFrameOptionAnnounceComplete:SetChecked(checkboxValue);
end;

function Buffalo_RefreshClassSettingsUI()
	--	Update alpha value on each button so it matches the current settings.
	buffCount = table.getn(Buffalo_GroupBuffProperties);
	for rowNumber = 1, buffCount, 1 do
		for className, classInfo in next, CLASS_MATRIX do
			buttonName = string.format("%s_row%s", className, rowNumber);

			local entry = _G[buttonName];
			if bit.band(CONFIG_AssignedClasses[className], Buffalo_GroupBuffProperties[rowNumber][3]) > 0 then
				entry:SetAlpha(BUFFALO_ALPHA_ENABLED);
			else
				entry:SetAlpha(BUFFALO_ALPHA_DISABLED);
			end;
		end;
	end;
end;

function Buffalo_ConfigurationBuffOnClick(self, ...)
	local buttonName = self:GetName();
	local buttonType = GetMouseButtonClicked();

	local _, _, row, col = string.find(buttonName, "buffalo_personal_buff_(%d)_(%d)");

	row = 1 * row;
	col = 1 * col;	-- Col=0: self buff, col 1-8: raid buff

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
					familyMask = bit.bor(familyMask, buffInfo["BITMASK"]);
				end;
			end;

			groupMask = bit.band(groupMask, 0x0ffff - familyMask);
		end;

		groupMask = bit.bor(groupMask, buffMask);
	else
		groupMask = bit.band(groupMask, maskOut);
	end;


	if col == 0 then
		CONFIG_AssignedBuffSelf = groupMask
		Buffalo_SetOption(CONFIG_KEY_AssignedBuffSelf, CONFIG_AssignedBuffSelf);
	else
		CONFIG_AssignedBuffGroups[col] = groupMask;
	end;

	Buffalo_UpdateGroupBuffUI();
end;

function Buffalo_ClassConfigOnClick(self, ...)
	local buttonName = self:GetName();
	local buttonType = GetMouseButtonClicked();

	local _, _, className, row = string.find(buttonName, "([A-Z]*)_row(%d)");

	row = 1 * row;

	local classMask = CONFIG_AssignedClasses[className];
	local buffMask = Buffalo_GroupBuffProperties[row][3];

	if buttonType == "LeftButton" then
		--	Left button: ADD the buff
		classMask = bit.bor(classMask, buffMask);
	else
		--	Right button: REMOVE the buff
		classMask = bit.band(classMask, 0x03fff - buffMask);
	end;

	CONFIG_AssignedClasses[className] = classMask;

	Buffalo_SetOption(CONFIG_KEY_AssignedClasses, CONFIG_AssignedClasses);

	Buffalo_RefreshClassSettingsUI();
end;


function Buffalo_ConfigurationOnCloseButtonClick()
	Buffalo_CloseConfigurationDialogue();
end;

function Buffalo_GeneralConfigOnCloseButtonClick()
	Buffalo_CloseGeneralConfigDialogue();
end;

function Buffalo_ClassConfigOnCloseButtonClick()
	Buffalo_CloseClassConfigDialogue();
end;

function Buffalo_PrayerThresholdChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	if value ~= CONFIG_GroupBuffThreshold then
		CONFIG_GroupBuffThreshold = value;
		Buffalo_SetOption(CONFIG_KEY_GroupBuffThreshold, CONFIG_GroupBuffThreshold);
	end;
	
	BuffaloSliderPrayerThresholdText:SetText(string.format("%s/5 people", CONFIG_GroupBuffThreshold));
end;

function Buffalo_RenewOverlapChanged(object)
	local value = math.floor(object:GetValue());

	value = (math.floor(value / 5)) * 5;

	object:SetValueStep(5);
	object:SetValue(value);

	if value ~= CONFIG_RenewOverlap then
		CONFIG_RenewOverlap = value;
		Buffalo_SetOption(CONFIG_KEY_RenewOverlap, CONFIG_RenewOverlap);
	end;
	
	BuffaloSliderRenewOverlapText:SetText(string.format("%s seconds", CONFIG_RenewOverlap));
end;


function Buffalo_ScanFrequencyChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	--	Slider works from 1-10, we need values from 0.1 - 1:
	value = value / 10;
	if value ~= CONFIG_ScanFrequency then
		CONFIG_ScanFrequency = value;
		Buffalo_SetOption(CONFIG_KEY_ScanFrequency, CONFIG_ScanFrequency);
	end;
	
	BuffaloSliderScanFrequencyText:SetText(string.format("%s/10 sec.", CONFIG_ScanFrequency * 10));
end;

function Buffalo_HandleCheckbox(checkbox)
	local checkboxname = checkbox:GetName();

	-- "single" checkboxes (checkboxes with no impact on other checkboxes):
	if checkboxname == "BuffaloConfigFrameOptionAnnounceMissing" then
		if BuffaloConfigFrameOptionAnnounceMissing:GetChecked() then
			CONFIG_AnnounceMissingBuff = true;
			A:echo("Missing Buff announcements are now ON.");
		else
			CONFIG_AnnounceMissingBuff = false;
			A:echo("Missing Buff announcements are now OFF.");
		end;
		Buffalo_SetOption(CONFIG_KEY_AnnounceMissingBuff, CONFIG_AnnounceMissingBuff);
	end;

	if checkboxname == "BuffaloConfigFrameOptionAnnounceComplete" then
		if BuffaloConfigFrameOptionAnnounceComplete:GetChecked() then
			CONFIG_AnnounceCompletedBuff = true;
			A:echo("Completed Buff announcements are now ON.");
		else
			CONFIG_AnnounceCompletedBuff = false;
			A:echo("Completed Buff announcements are now OFF.");
		end;
		Buffalo_SetOption(CONFIG_KEY_AnnounceCompletedBuff, CONFIG_AnnounceCompletedBuff);
	end;
	
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
		if addonname == A.addonName then
			Buffalo_MainInitialization();
			Buffalo_RepositionateButton(BuffButton);
			Buffalo_HideBuffButton();
		end

	elseif (event == "CHAT_MSG_ADDON") then
		Buffalo_OnChatMsgAddon(event, ...)

	elseif (event == "GROUP_ROSTER_UPDATE") then
		Buffalo_OnGroupRosterUpdate(event, ...)

	elseif(event == "UNIT_SPELLCAST_STOP") then
		local caster = ...;
		if caster == "player" then
			lastBuffFired = nil;
		end;

	elseif(event == "UNIT_SPELLCAST_FAILED") then
		local caster = ...;
		if caster == "player" then
			lastBuffFired = nil;
		end;

	elseif(event == "UNIT_SPELLCAST_SUCCEEDED") then
		local caster, _, spellId = ...;

		if caster == "player" then
			local buffName = GetSpellInfo(spellId);
			if buffName and buffName == lastBuffFired then
				lastBuffFired = nil;
				if CONFIG_AnnounceCompletedBuff and not UnitAffectingCombat("player") then
					local unitid = BuffButton:GetAttribute("unit");
					if unitid then
						A:echo(string.format("%s was buffed with %s.", Buffalo_GetPlayerAndRealm(unitid) or "nil", buffName));
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

function Buffalo_OnLoad()
	local _, classname = UnitClass("player");
	Buffalo_PlayerClass = classname;
	Buffalo_PlayerNameAndRealm = Buffalo_GetPlayerAndRealm("player");

	BUFFALO_CURRENT_VERSION = A:calculateVersion();

	A:echo(string.format("Type %s/buffalo%s to configure the addon.", A.chatColorHot, A.chatColorNormal));

	_G["BuffaloVersionString"]:SetText(string.format("Buffalo version %s by %s", A.addonVersion, A.addonAuthor));

    BuffaloEventFrame:RegisterEvent("ADDON_LOADED");
    BuffaloEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    BuffaloEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    BuffaloEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
    BuffaloEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED");
    BuffaloEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

	BuffaloClassConfigFrame:SetBackdrop(BUFFALO_BACKDROP_CLASSES_FRAME);
	BuffaloGeneralConfigFrame:SetBackdrop(BUFFALO_BACKDROP_GENEREL_FRAME);

	BuffaloConfigFramePrayerThreshold:SetBackdrop(BUFFALO_BACKDROP_SLIDER);
	BuffaloConfigFrameRenewOverlap:SetBackdrop(BUFFALO_BACKDROP_SLIDER);
	BuffaloConfigFrameScanFrequency:SetBackdrop(BUFFALO_BACKDROP_SLIDER);

	C_ChatInfo.RegisterAddonMessagePrefix(A.addonPrefix);
end

function Buffalo_OnTimer(elapsed)
	TimerTick = TimerTick + elapsed

	if TimerTick > (NextScanTime + CONFIG_ScanFrequency) then
		Buffalo_ScanRaid();
		NextScanTime = TimerTick;
	end;

	if not Buffalo_InitializationComplete and TimerTick > Buffalo_InitializationRetryTimer then
		Buffalo_MainInitialization(true);
	end;

end
