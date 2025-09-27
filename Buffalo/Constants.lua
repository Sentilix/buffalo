--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   constants.lua
--	Desc:	Buffalo non-configurable constants
--]]

Buffalo = select(2, ...)

--	Class constants
Buffalo.classmasks = { };

Buffalo.classmasks.Druid			= 0x0001;
Buffalo.classmasks.Hunter			= 0x0002;
Buffalo.classmasks.Mage				= 0x0004;
Buffalo.classmasks.Paladin			= 0x0008;
Buffalo.classmasks.Priest			= 0x0010;
Buffalo.classmasks.Rogue			= 0x0020;
Buffalo.classmasks.Shaman			= 0x0040;
Buffalo.classmasks.Warlock			= 0x0080;
Buffalo.classmasks.Warrior			= 0x0100;
Buffalo.classmasks.DeathKnight		= 0x0200;
Buffalo.classmasks.Pet				= 0x0400;
--	Class behavior:
Buffalo.classmasks.MANAUSERS		= 0x04df;
Buffalo.classmasks.ALL				= 0x03ff;
Buffalo.classmasks.Selected			= 0x0000;


--	Configuration:
Buffalo.config = { };

--	Druid default: 0x0001 = Wild on all groups
Buffalo.config.DEFAULT_Druid_GroupMask		= 0x000001;
--	Mage default: 0x0001 = Intellect on all groups
Buffalo.config.DEFAULT_Mage_GroupMask		= 0x000001;
--	Priests default: 0x0003 = Fort + Spirit on all groups
Buffalo.config.DEFAULT_Priest_GroupMask		= 0x000011;
--	Warlock default: 0x0000 = no default buffs
Buffalo.config.DEFAULT_Warlock_GroupMask	= 0x000000;


--	Configuration keys:
Buffalo.config.key = { };
Buffalo.config.key.AnnounceCompletedBuff		= "AnnounceCompletedBuff";
Buffalo.config.key.AnnounceMissingBuff			= "AnnounceMissingBuff";
Buffalo.config.key.AssignedBuffGroups			= "AssignedBuffGroups";
Buffalo.config.key.AssignedBuffSelf				= "AssignedBuffSelf";
Buffalo.config.key.AssignedClasses				= "AssignedClasses";
Buffalo.config.key.BuffButtonPosX				= "BuffButton.X";
Buffalo.config.key.BuffButtonPosY				= "BuffButton.Y";
Buffalo.config.key.BuffButtonVisible			= "BuffButton.Visible";
Buffalo.config.key.ButtonOpacity				= "ButtonOpacity";
Buffalo.config.key.GroupBuffThreshold			= "GroupBuffThreshold";
Buffalo.config.key.RenewOverlap					= "RenewOverlap";
Buffalo.config.key.ScanFrequency				= "ScanFrequency";
Buffalo.config.key.SynchronizedBuffs			= "SynchronizedBuffGroups";
Buffalo.config.key.UseIncubus					= "UseIncubus";

Buffalo.config.default = { };
Buffalo.config.default.AnnounceCompletedBuff	= false;	-- Announce when a buff has being cast.
Buffalo.config.default.AnnounceMissingBuff		= false;	-- Announce next buff being cast.
Buffalo.config.default.AssignedBuffSelf			= 0x0000;	-- Default is no selfbuffs assigned.
Buffalo.config.default.AssignedBuffGroups		= { };
Buffalo.config.default.AssignedClasses			= { };		-- Classes with buff assignments: Buffalo.config.value.AssignedClasses[classname] = [bitmask]. Set runtime.
Buffalo.config.default.BuffButtonVisible		= true;
Buffalo.config.default.ButtonOpacity			= 1.0;		-- Default opacity: none (100%)
Buffalo.config.default.GroupBuffThreshold		= 4;		-- Default is to use greater buffs when 4+ people needs a buff.
Buffalo.config.default.RenewOverlap				= 30;		-- If buff ends withing <n> seconds Buffalo will attempt to rebuff
Buffalo.config.default.ScanFrequency			= 0.3;		-- Scan every <n> second (0.1 - 1.0 seconds)
Buffalo.config.default.UseIncubus				= false;	-- Default is to use the Succubus

--	Configured values (TODO: a few selected are still not configurable)
Buffalo.config.value = { };
Buffalo.config.value.AnnounceCompletedBuff		= Buffalo.config.default.AnnounceCompletedBuff;
Buffalo.config.value.AnnounceMissingBuff		= Buffalo.config.default.AnnounceMissingBuff;
Buffalo.config.value.AssignedBuffGroups			= { };		-- List of groups and their assigned buffs via bitmask. Persisted, but no UI for it. Set runtime.
Buffalo.config.value.AssignedRaidGroups			= { };		-- Same but for Raid buffing.
Buffalo.config.value.AssignedBuffSelf			= Buffalo.config.default.AssignedBuffSelf;
Buffalo.config.value.AssignedClasses			= Buffalo.config.default.AssignedClasses;
Buffalo.config.value.BuffButtonVisible			= Buffalo.config.default.BuffButtonVisible;
Buffalo.config.value.ButtonOpacity				= Buffalo.config.default.ButtonOpacity;
Buffalo.config.value.GroupBuffThreshold			= Buffalo.config.default.GroupBuffThreshold;
Buffalo.config.value.RenewOverlap				= Buffalo.config.default.RenewOverlap;
Buffalo.config.value.ScanFrequency				= Buffalo.config.default.ScanFrequency;
Buffalo.config.value.SynchronizedBuffs			= { };		-- [buff row][group num] = { [BUFFNAME], [BITMASK], [PLAYER] }
Buffalo.config.value.UseIncubus					= Buffalo.config.default.UseIncubus;

--	Other configuration options considered in future releases:
Buffalo.config.value.BuffButtonSize				= 32;		-- Size of buff button
Buffalo.config.value.PlayerBuffPriority			= 90;		-- Priority to Self'

--	Miscellaneous:
Buffalo.sounds = { };
Buffalo.sounds.IG_MAINMENU_OPEN		= 850;
Buffalo.sounds.IG_MAINMENU_CLOSE	= 851;


--	Design/UI constants
Buffalo.ui = { };

Buffalo.ui.colours = { };
Buffalo.ui.colours.ExpiringBuff					= "|c80F0F000"
Buffalo.ui.colours.MissingBuff					= "|c80F05000"
Buffalo.ui.colours.GroupLabels					= { 1.0, 0.7, 0.0 };
Buffalo.ui.colours.Buffer						= { 1.0, 1.0, 1.0 };
Buffalo.ui.colours.Unused						= { 0.4, 0.4, 0.4 };

Buffalo.ui.alpha = { };
Buffalo.ui.alpha.Disabled						= 0.33;
Buffalo.ui.alpha.Enabled						= 1.00;

Buffalo.ui.icons = { };
Buffalo.ui.icons.Passive						= 136112;
Buffalo.ui.icons.Combat							= "Interface\\Icons\\Ability_dualwield";
Buffalo.ui.icons.PlayerIsDead					= "Interface\\Icons\\Ability_rogue_feigndeath";
Buffalo.ui.icons.RaidNone						= 134121;	-- Raid mode 0: white
Buffalo.ui.icons.RaidOpen						= 134125;	-- Raid mode 1: green
Buffalo.ui.icons.RaidClosed						= 134124;	-- Raid mode 2: red

Buffalo.ui.buffConfigDialog = { };
Buffalo.ui.buffConfigDialog.Top					= 0;
Buffalo.ui.buffConfigDialog.Left				= 120;
Buffalo.ui.buffConfigDialog.Width				= 100;
Buffalo.ui.buffConfigDialog.Height				= 40;
Buffalo.ui.buffConfigDialog.ButtonWidth			= 200;


--	Backdrops:
Buffalo.ui.backdrops = { };

Buffalo.ui.backdrops.ClassFrame = {
	bgFile = "Interface\\TalentFrame\\WarriorProtection-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
};
Buffalo.ui.backdrops.GeneralFrame = {
	bgFile = "Interface\\TalentFrame\\RogueCombat-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
};
Buffalo.ui.backdrops.Slider = {
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-TestWatermark-Border",
	tileEdge = true,
	edgeSize = 16,
};

Buffalo.ui.backdrops.DruidFrame = {
	bgFile = "Interface\\TalentFrame\\ShamanRestoration-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
Buffalo.ui.backdrops.MageFrame = {
	bgFile = "Interface\\TalentFrame\\MageFrost-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
Buffalo.ui.backdrops.PriestFrame = {
	bgFile = "Interface\\TalentFrame\\PriestDiscipline-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
Buffalo.ui.backdrops.ShadowPriestFrame = {
	bgFile = "Interface\\TalentFrame\\PriestShadow-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
Buffalo.ui.backdrops.WarlockFrame = {
	bgFile = "Interface\\TalentFrame\\WarlockCurses-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
Buffalo.ui.backdrops.OpenRaidFrame = {
	bgFile = "Interface\\TalentFrame\\PaladinCombat-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};
Buffalo.ui.backdrops.ClosedRaidFrame = {
	bgFile = "Interface\\TalentFrame\\WarriorFury-Topleft",
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
	tile = 0,
	tileSize = 900,
};



--	Debugging
Buffalo.debug = { };
Buffalo.debug.Functions							= { };



--	Raid modes:
--	Render Raid modes: currently supporting mode 0/1/2:
Buffalo.raidmodes = { };
Buffalo.raidmodes.Personal			= 0x0001;		--	Assignments are using the "normal" SOLO frame.
Buffalo.raidmodes.OpenRaid			= 0x0010;		--	Assignments are using Raid frame. Everyone can assign.
Buffalo.raidmodes.ClosedRaid		= 0x0020;		--	Assignments are using Raid frame. Promoted can assign.
Buffalo.raidmodes.setup = {
	{ 
		["RAIDMODE"] = Buffalo.raidmodes.Personal,	
		["ICON"] = Buffalo.ui.icons.RaidNone, 
		["CAPTION"] = "Personal assignments" 
	}, { 
		["RAIDMODE"] = Buffalo.raidmodes.OpenRaid,		
		["ICON"] = Buffalo.ui.icons.RaidOpen, 
		["CAPTION"] = "Open Raid assignments" 
	}, { 
		["RAIDMODE"] = Buffalo.raidmodes.ClosedRaid,	
		["ICON"] = Buffalo.ui.icons.RaidClosed, 
		["CAPTION"] = "Closed Raid assignments" 
	},
};


Buffalo.raidmodes.OpenRaidRequiresPromotion		= true;		-- true: (switching to) Raidmode 1 requires promotion
Buffalo.raidmodes.ClosedRaidRequiresPromotion	= true;		-- true: (switching to) Raidmode 2 requires promotion
Buffalo.raidmodes.DisplayRaidModeChanges		= false;	-- true: show a local message when raid mode changes. Can be spammy.

