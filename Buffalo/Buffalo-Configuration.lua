--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo-configuration.lua
--	Desc:	Configuration of the buffs
--]]



local BUFFALO_CLASS_DRUID      	= 0x0001;
local BUFFALO_CLASS_HUNTER     	= 0x0002;
local BUFFALO_CLASS_MAGE       	= 0x0004;
local BUFFALO_CLASS_PALADIN    	= 0x0008;
local BUFFALO_CLASS_PRIEST     	= 0x0010;
local BUFFALO_CLASS_ROGUE      	= 0x0020;
local BUFFALO_CLASS_SHAMAN     	= 0x0040;
local BUFFALO_CLASS_WARLOCK    	= 0x0080;
local BUFFALO_CLASS_WARRIOR    	= 0x0100;
local BUFFALO_CLASS_DEATHKNIGHT	= 0x0200;
local BUFFALO_CLASS_PET        	= 0x0400;

local BUFFALO_CLASS_MANAUSERS  	= 0x00df;
local BUFFALO_CLASS_ALL        	= 0x07ff;


BUFFALO_CLASS_MATRIX_MASTER = {
	["DRUID"] = {
		["MASK"] = BUFFALO_CLASS_DRUID,
		["ICONID"] = 625999,
	},
	["HUNTER"] = {
		["MASK"] = BUFFALO_CLASS_HUNTER,
		["ICONID"] = 626000,
	},
	["MAGE"] = {
		["MASK"] = BUFFALO_CLASS_MAGE,
		["ICONID"] = 626001,
	},
	["PALADIN"] = {
		["MASK"] = BUFFALO_CLASS_PALADIN,
		["ICONID"] = 626003,
		["ALLIANCE-EXPAC"] = 1,
		["HORDE-EXPAC"] = 2,
	},
	["PRIEST"] = {
		["MASK"] = BUFFALO_CLASS_PRIEST,
		["ICONID"] = 626004,
	},
	["ROGUE"] = {
		["MASK"] = BUFFALO_CLASS_ROGUE,
		["ICONID"] = 626005,
	},
	["SHAMAN"] = {
		["MASK"] = BUFFALO_CLASS_SHAMAN,
		["ICONID"] = 626006,
		["ALLIANCE-EXPAC"] = 2,
		["HORDE-EXPAC"] = 1,
	},
	["WARLOCK"] = {
		["MASK"] = BUFFALO_CLASS_WARLOCK,
		["ICONID"] = 626007,
	},
	["WARRIOR"] = {
		["MASK"] = BUFFALO_CLASS_WARRIOR,
		["ICONID"] = 626008,
	},
	["DEATHKNIGHT"] = {
		["MASK"] = BUFFALO_CLASS_DEATHKNIGHT,
		["ICONID"] = 135771,
		["ALLIANCE-EXPAC"] = 3,
		["HORDE-EXPAC"] = 3,
	},
	["PET"] = {
		["MASK"] = BUFFALO_CLASS_PET,
		["ICONID"] = 132599,
	}
};

SpellName_Generel_FindHerbs = "";
SpellName_Generel_FindMinerals = "";


IG_MAINMENU_OPEN			= 850;
IG_MAINMENU_CLOSE			= 851;



--	Druid default: 0x0001 = Wild on all groups
local CONFIG_DEFAULT_Druid_GroupMask = 1;
--	Mage default: 0x0001 = Intellect on all groups
local CONFIG_DEFAULT_Mage_GroupMask = 1;
--	Priests default: 0x0003 = Fort + Spirit on all groups
local CONFIG_DEFAULT_Priest_GroupMask = 3;



local function echo(msg)
	if msg then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
end

function Buffalo_GetSpellID(spellname)
	local _, _, _, _, _, _, spellID = GetSpellInfo(spellname);
	return spellID;
end;

function Buffalo_GetSpellName(spellID)
	return GetSpellInfo(spellID);
end;


--	I admit: this is a weird construction, but please read ...
--
--	I use the (highest) spellID to fetch the NAME of the spell.
--	And after that I find the SpellID from the name of that spell!
--	Thre are two reasons to why I do so:
--	* Localization: the spell name is not hardcoded, so this (should) work for 
--	  both EN/US, DE and FR clients.
--	* Lower levels or unlearned spells: The highest leared spellID is set, or
--	  nil in case the player does not know that spell at all.
function Buffalo_InitializeBuffMatrix()

	local localClassname, englishClassname = UnitClass("player");
	local matrix = { };

	--	General spells:
	SpellName_Generel_FindHerbs = Buffalo_GetSpellName(2383); 
	SpellName_Generel_FindMinerals = Buffalo_GetSpellName(2580); 

	local Generel_FindHerbs = {
		["BITMASK"]		= 0x04000,
		["ICONID"]		= 133939,
		["SPELLID"]		= Buffalo_GetSpellID(SpellName_Generel_FindHerbs),
		["CLASSES"]		= BUFFALO_CLASS_ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	local Generel_FindMinerals = {
		["BITMASK"]		= 0x08000,
		["ICONID"]		= 136025,
		["SPELLID"]		= Buffalo_GetSpellID(SpellName_Generel_FindMinerals),
		["CLASSES"]		= BUFFALO_CLASS_ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	matrix[SpellName_Generel_FindMinerals]	= Generel_FindMinerals;
	matrix[SpellName_Generel_FindHerbs]		= Generel_FindHerbs;


	if englishClassname == "DRUID" then
		local SpellName_Druid_MarkOfTheWild = Buffalo_GetSpellName(9885);
		local SpellName_Druid_GiftOfTheWild = Buffalo_GetSpellName(21850); 
		local SpellName_Druid_Thorns = Buffalo_GetSpellName(9910); 

		local Druid_MarkOfTheWild = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 136078,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Druid_MarkOfTheWild),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= false,
			["PARENT"]		= SpellName_Druid_GiftOfTheWild
		};

		local Druid_GiftOfTheWild = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 136078,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Druid_GiftOfTheWild),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= true,
			["SINGLE"]		= SpellName_Druid_MarkOfTheWild
		};

		local Druid_Thorns = {
			["BITMASK"]		= 0x000002,
			["ICONID"]		= 136104,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Druid_Thorns),
			["CLASSES"]		= BUFFALO_CLASS_WARRIOR + BUFFALO_CLASS_DRUID,
			["PRIORITY"]	= 51,
			["GROUP"]		= false
		};

		matrix[SpellName_Druid_MarkOfTheWild]	= Druid_MarkOfTheWild;
		matrix[SpellName_Druid_GiftOfTheWild]	= Druid_GiftOfTheWild;
		matrix[SpellName_Druid_Thorns]			= Druid_Thorns;

	elseif englishClassname == "MAGE" then	
		local SpellName_Mage_ArcaneIntellect = Buffalo_GetSpellName(10157);  
		local SpellName_Mage_ArcaneBrilliance = Buffalo_GetSpellName(23028);  
		local SpellName_Mage_AmplifyMagic = Buffalo_GetSpellName(10170);
		local SpellName_Mage_DampenMagic = Buffalo_GetSpellName(10174);
		local SpellName_Mage_MoltenArmor = Buffalo_GetSpellName(30482);
		local SpellName_Mage_MageArmor = Buffalo_GetSpellName(22783);
		local SpellName_Mage_FrostArmor = Buffalo_GetSpellName(12544);
		local SpellName_Mage_IceArmor = Buffalo_GetSpellName(10220);
		local SpellName_Mage_IceBarrier = Buffalo_GetSpellName(13033);

		local Mage_ArcaneIntellect = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 135932,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_ArcaneIntellect),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 53,
			["GROUP"]		= false,
			["PARENT"]		= SpellName_Mage_ArcaneBrilliance
		};

		local Mage_ArcaneBrilliance = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 135869,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_ArcaneBrilliance),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 53,
			["GROUP"]		= true,
			["SINGLE"]		= SpellName_Mage_ArcaneIntellect
		};

		local Mage_AmplifyMagic = {
			["BITMASK"]		= 0x000002,
			["ICONID"]		= 135907,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_AmplifyMagic),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= false,
			["FAMILY"]		= "AmplifyDampen"
		};

		local Mage_DampenMagic = {
			["BITMASK"]		= 0x000004,
			["ICONID"]		= 136006,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_DampenMagic),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 51,
			["GROUP"]		= false,
			["FAMILY"]		= "AmplifyDampen"
		};

		local Mage_FrostArmor = {
			["BITMASK"]		= 0x001000,
			["ICONID"]		= 135843,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_FrostArmor),
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 15,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		local Mage_MoltenArmor = {
			["BITMASK"]		= 0x000800,
			["ICONID"]		= 132221,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_MoltenArmor),
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 14,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		local Mage_MageArmor = {
			["BITMASK"]		= 0x000100,
			["ICONID"]		= 135991,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_MageArmor),
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 13,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		local Mage_IceArmor = {
			["BITMASK"]		= 0x000200,
			["ICONID"]		= 135843,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_IceArmor),
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 12,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		local Mage_IceBarrier = {
			["BITMASK"]		= 0x000400,
			["ICONID"]		= 135988,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Mage_IceBarrier),
			["COOLDOWN"]	= 30,
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 11,
			["GROUP"]		= false
		};

		matrix[SpellName_Mage_ArcaneBrilliance]			= Mage_ArcaneBrilliance;
		matrix[SpellName_Mage_ArcaneIntellect]			= Mage_ArcaneIntellect;
		matrix[SpellName_Mage_AmplifyMagic]				= Mage_AmplifyMagic;
		matrix[SpellName_Mage_DampenMagic]				= Mage_DampenMagic;
		matrix[SpellName_Mage_FrostArmor]				= Mage_FrostArmor;
		if SpellName_Mage_MoltenArmor then
			matrix[SpellName_Mage_MoltenArmor]			= Mage_MoltenArmor;
		end;
		matrix[SpellName_Mage_MageArmor]				= Mage_MageArmor;
		matrix[SpellName_Mage_IceArmor]					= Mage_IceArmor;
		matrix[SpellName_Mage_IceBarrier]				= Mage_IceBarrier;

	elseif englishClassname == "PRIEST" then
		local SpellName_Priest_PowerWordFortitude = Buffalo_GetSpellName(10938);
		local SpellName_Priest_PrayerOfFortitude = Buffalo_GetSpellName(21564);
		local SpellName_Priest_DivineSpirit = Buffalo_GetSpellName(27841);
		local SpellName_Priest_PrayerOfSpirit = Buffalo_GetSpellName(27681);
		local SpellName_Priest_ShadowProtection = Buffalo_GetSpellName(10958);
		local SpellName_Priest_PrayerOfShadowProtection = Buffalo_GetSpellName(27683);
		local SpellName_Priest_InnerFire = Buffalo_GetSpellName(10952);
		local SpellName_Priest_ShadowForm = Buffalo_GetSpellName(15473);

		local Priest_PowerWordFortitude = { 
			["BITMASK"]		= 0x000001, 
			["ICONID"]		= 135987, 
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_PowerWordFortitude),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 53, 
			["GROUP"]		= false, 
			["PARENT"]		= SpellName_Priest_PrayerOfFortitude 
		};
	
		local Priest_PrayerOfFortitude = {
			["BITMASK"]		= 0x000001, 
			["ICONID"]		= 135941, 
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_PrayerOfFortitude),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 53, 
			["GROUP"]		= true,
			["SINGLE"]		= SpellName_Priest_PowerWordFortitude
		};

		local Priest_DivineSpirit = {
			["BITMASK"]		= 0x000002, 
			["ICONID"]		= 135898, 
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_DivineSpirit),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 52, 
			["GROUP"]		= false, 
			["PARENT"]		= SpellName_Priest_PrayerOfSpirit
		};

		local Priest_PrayerOfSpirit = {
			["BITMASK"]		= 0x000002, 
			["ICONID"]		= 135946,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_PrayerOfSpirit),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 52,
			["GROUP"]		= true,
			["SINGLE"]		= SpellName_Priest_DivineSpirit
		};

		local Priest_ShadowProtection = {
			["BITMASK"]		= 0x000004,
			["ICONID"]		= 136121,
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_ShadowProtection),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 51,
			["GROUP"]		= false,
			["PARENT"]		= SpellName_Priest_PrayerOfShadowProtection 
		};
	
		local Priest_PrayerOfShadowProtection = {
			["BITMASK"]		= 0x000004, 
			["ICONID"]		= 135945, 
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_PrayerOfShadowProtection),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 51, 
			["GROUP"]		= true,
			["SINGLE"]		= SpellName_Priest_ShadowProtection
		};

		local Priest_ShadowForm = {
			["BITMASK"]		= 0x000200, 
			["ICONID"]		= 136200, 
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_ShadowForm),
			["CLASSES"]		= BUFFALO_CLASS_PRIEST,
			["PRIORITY"]	= 11, 
			["GROUP"]		= false 
		};

		local Priest_InnerFire = {
			["BITMASK"]		= 0x000100, 
			["ICONID"]		= 135926, 
			["SPELLID"]		= Buffalo_GetSpellID(SpellName_Priest_InnerFire),
			["CLASSES"]		= BUFFALO_CLASS_PRIEST,
			["PRIORITY"]	= 12, 
			["GROUP"]		= false 
		};

		matrix[SpellName_Priest_PowerWordFortitude]		= Priest_PowerWordFortitude;
		matrix[SpellName_Priest_PrayerOfFortitude]		= Priest_PrayerOfFortitude;
		matrix[SpellName_Priest_DivineSpirit]			= Priest_DivineSpirit;
		matrix[SpellName_Priest_PrayerOfSpirit]			= Priest_PrayerOfSpirit;
		matrix[SpellName_Priest_ShadowProtection]		= Priest_ShadowProtection;
		matrix[SpellName_Priest_PrayerOfShadowProtection]= Priest_PrayerOfShadowProtection;
		matrix[SpellName_Priest_InnerFire]				= Priest_InnerFire;
		matrix[SpellName_Priest_ShadowForm]				= Priest_ShadowForm;
	end;

	--	Filter out spells we havent learned (SpellID is nil)
	for buffName, buffInfo in next, matrix do
		if not buffInfo["SPELLID"] then
			matrix[buffName] = nil;
		end;
	end;

	return matrix;
end;


function Buffalo_InitializeAssignedGroupDefaults()
	local localClassname, englishClassname = UnitClass("player");
	local assignedGroupBuffs = { };

	local groupMask = 0;

	if englishClassname == "DRUID" then
		groupMask = CONFIG_DEFAULT_Druid_GroupMask;
	elseif englishClassname == "MAGE" then
		groupMask = CONFIG_DEFAULT_Mage_GroupMask;
	elseif englishClassname == "PRIEST" then
		groupMask = CONFIG_DEFAULT_Priest_GroupMask;
	end

	for groupNum = 1, 8, 1 do
		assignedGroupBuffs[groupNum] = groupMask;
	end;

	return assignedGroupBuffs;
end;






