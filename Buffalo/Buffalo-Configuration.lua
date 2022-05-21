--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo-configuration.lua
--	Desc:	Configuration of the buffs
--]]


BUFFALO_CLASS_DRUID			= 0x0001;
BUFFALO_CLASS_HUNTER		= 0x0002;
BUFFALO_CLASS_MAGE			= 0x0004;
BUFFALO_CLASS_PALADIN		= 0x0008;
BUFFALO_CLASS_PRIEST		= 0x0010;
BUFFALO_CLASS_ROGUE			= 0x0020;
BUFFALO_CLASS_SHAMAN		= 0x0040;
BUFFALO_CLASS_WARLOCK		= 0x0080;
BUFFALO_CLASS_WARRIOR		= 0x0100;

BUFFALO_CLASS_ALL			= 0x01ff;
BUFFALO_CLASS_MANAUSERS		= 0x00df


IG_MAINMENU_OPEN			= 850;
IG_MAINMENU_CLOSE			= 851;


--	General buffs placeholders:
BUFFALO_BUFF_Generel_FindHerbs_Name = "";
BUFFALO_BUFF_Generel_FindHerbs = { };

BUFFALO_BUFF_Generel_FindMinerals_Name = ""; 
BUFFALO_BUFF_Generel_FindMinerals = { }

--	Druid buffs placeholders:
BUFFALO_BUFF_Druid_MarkOfTheWild_Name = "";
BUFFALO_BUFF_Druid_MarkOfTheWild = { };

BUFFALO_BUFF_Druid_GiftOfTheWild_Name = "";
BUFFALO_BUFF_Druid_GiftOfTheWild = { };

BUFFALO_BUFF_Druid_Thorns_Name = "";
BUFFALO_BUFF_Druid_Thorns = { };

--	Mage buffs placeholders:
BUFFALO_BUFF_Mage_ArcaneIntellect_Name = "";
BUFFALO_BUFF_Mage_ArcaneIntellect = { };

BUFFALO_BUFF_Mage_ArcaneBrilliance_Name = "";
BUFFALO_BUFF_Mage_ArcaneBrilliance = { };

BUFFALO_BUFF_Mage_AmplifyMagic_Name = "";
BUFFALO_BUFF_Mage_AmplifyMagic = { };

BUFFALO_BUFF_Mage_DampenMagic_Name = "";
BUFFALO_BUFF_Mage_DampenMagic = { };

BUFFALO_BUFF_Mage_MageArmor_Name = "";
BUFFALO_BUFF_Mage_MageArmor = { };

BUFFALO_BUFF_Mage_IceArmor_Name = "";
BUFFALO_BUFF_Mage_IceArmor = { };

BUFFALO_BUFF_Mage_IceBarrier_Name = "";
BUFFALO_BUFF_Mage_IceBarrier = { };

--	Priest buff placeholders:
BUFFALO_BUFF_Priest_PowerWordFortitude_Name = "";
BUFFALO_BUFF_Priest_PowerWordFortitude = { };

BUFFALO_BUFF_Priest_PrayerOfFortitude_Name = "";
BUFFALO_BUFF_Priest_PrayerOfFortitude = { };

BUFFALO_BUFF_Priest_DivineSpirit_Name = "";
BUFFALO_BUFF_Priest_DivineSpirit = { };

BUFFALO_BUFF_Priest_PrayerOfSpirit_Name = "";
BUFFALO_BUFF_Priest_PrayerOfSpirit = { };

BUFFALO_BUFF_Priest_ShadowProtection_Name = "";
BUFFALO_BUFF_Priest_ShadowProtection = { };

BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name = "";
BUFFALO_BUFF_Priest_PrayerOfShadowProtection = { };

BUFFALO_BUFF_Priest_InnerFire_Name = "";
BUFFALO_BUFF_Priest_InnerFire = { };


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
--
--	Now here's a joke ...... I am not even using the spellID!!! Can prolly save some code.
function Buffalo_InitializeBuffMatrix()

	local localClassname, englishClassname = UnitClass("player");
	local matrix = { };

	--	General spells:
	BUFFALO_BUFF_Generel_FindHerbs_Name = Buffalo_GetSpellName(2383); 
	BUFFALO_BUFF_Generel_FindHerbs = {
		["BITMASK"]		= 0x01000,
		["ICONID"]		= 133939,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Generel_FindHerbs_Name),
		["CLASSES"]		= BUFFALO_CLASS_ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	BUFFALO_BUFF_Generel_FindMinerals_Name = Buffalo_GetSpellName(2580); 
	BUFFALO_BUFF_Generel_FindMinerals = {
		["BITMASK"]		= 0x02000,
		["ICONID"]		= 136025,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Generel_FindMinerals_Name),
		["CLASSES"]		= BUFFALO_CLASS_ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	matrix[BUFFALO_BUFF_Generel_FindMinerals_Name]	= BUFFALO_BUFF_Generel_FindMinerals;
	matrix[BUFFALO_BUFF_Generel_FindHerbs_Name]	= BUFFALO_BUFF_Generel_FindHerbs;


	if englishClassname == "DRUID" then
		BUFFALO_BUFF_Druid_MarkOfTheWild_Name = Buffalo_GetSpellName(9885); 
		BUFFALO_BUFF_Druid_MarkOfTheWild = {
			["BITMASK"]		= 0x0001,
			["ICONID"]		= 136078,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Druid_MarkOfTheWild_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= false,
			["PARENT"]		= "Gift of the Wild"
		};

		BUFFALO_BUFF_Druid_GiftOfTheWild_Name = Buffalo_GetSpellName(21850); 
		BUFFALO_BUFF_Druid_GiftOfTheWild = {
			["BITMASK"]		= 0x0001,
			["ICONID"]		= 136038,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Druid_GiftOfTheWild_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= true
		};

		BUFFALO_BUFF_Druid_Thorns_Name = Buffalo_GetSpellName(9910); 
		BUFFALO_BUFF_Druid_Thorns = {
			["BITMASK"]		= 0x0002,
			["ICONID"]		= 136104,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Druid_Thorns_Name),
			["CLASSES"]		= BUFFALO_CLASS_WARRIOR + BUFFALO_CLASS_DRUID,
			["PRIORITY"]	= 51,
			["GROUP"]		= false
		};

		matrix[BUFFALO_BUFF_Druid_MarkOfTheWild_Name]	= BUFFALO_BUFF_Druid_MarkOfTheWild;
		matrix[BUFFALO_BUFF_Druid_GiftOfTheWild_Name]	= BUFFALO_BUFF_Druid_GiftOfTheWild;
		matrix[BUFFALO_BUFF_Druid_Thorns_Name]			= BUFFALO_BUFF_Druid_Thorns;

	elseif englishClassname == "MAGE" then	
		BUFFALO_BUFF_Mage_ArcaneIntellect_Name = Buffalo_GetSpellName(10157);  
		BUFFALO_BUFF_Mage_ArcaneIntellect = {
			["BITMASK"]		= 0x0001,
			["ICONID"]		= 135932,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_ArcaneIntellect_Name),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 53,
			["GROUP"]		= false,
			["PARENT"]		= "Arcane Brilliance"
		};

		BUFFALO_BUFF_Mage_ArcaneBrilliance_Name = Buffalo_GetSpellName(23028);  
		BUFFALO_BUFF_Mage_ArcaneBrilliance = {
			["BITMASK"]		= 0x0001,
			["ICONID"]		= 135869,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_ArcaneBrilliance_Name),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 53,
			["GROUP"]		= true
		};

		BUFFALO_BUFF_Mage_AmplifyMagic_Name = Buffalo_GetSpellName(10170);
		BUFFALO_BUFF_Mage_AmplifyMagic = {
			["BITMASK"]		= 0x0002,
			["ICONID"]		= 135907,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_AmplifyMagic_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= false,
			["FAMILY"]		= "AmplifyDampen"
		};

		BUFFALO_BUFF_Mage_DampenMagic_Name = Buffalo_GetSpellName(10174);
		BUFFALO_BUFF_Mage_DampenMagic = {
			["BITMASK"]		= 0x0004,
			["ICONID"]		= 136006,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_DampenMagic_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 51,
			["GROUP"]		= false,
			["FAMILY"]		= "AmplifyDampen"
		};

		BUFFALO_BUFF_Mage_MageArmor_Name = Buffalo_GetSpellName(22783);
		BUFFALO_BUFF_Mage_MageArmor = {
			["BITMASK"]		= 0x0100,
			["ICONID"]		= 135991,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_MageArmor_Name),
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 13,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		BUFFALO_BUFF_Mage_IceArmor_Name = Buffalo_GetSpellName(10220);
		BUFFALO_BUFF_Mage_IceArmor = {
			["BITMASK"]		= 0x0200,
			["ICONID"]		= 135843,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_IceArmor_Name),
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 12,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		BUFFALO_BUFF_Mage_IceBarrier_Name = Buffalo_GetSpellName(13033);
		BUFFALO_BUFF_Mage_IceBarrier = {
			["BITMASK"]		= 0x0400,
			["ICONID"]		= 135988,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_IceBarrier_Name),
			["COOLDOWN"]	= 30,
			["CLASSES"]		= BUFFALO_CLASS_MAGE,
			["PRIORITY"]	= 11,
			["GROUP"]		= false
		};

		matrix[BUFFALO_BUFF_Mage_ArcaneBrilliance_Name]	= BUFFALO_BUFF_Mage_ArcaneBrilliance;
		matrix[BUFFALO_BUFF_Mage_ArcaneIntellect_Name]	= BUFFALO_BUFF_Mage_ArcaneIntellect;
		matrix[BUFFALO_BUFF_Mage_AmplifyMagic_Name]		= BUFFALO_BUFF_Mage_AmplifyMagic;
		matrix[BUFFALO_BUFF_Mage_DampenMagic_Name]		= BUFFALO_BUFF_Mage_DampenMagic;
		matrix[BUFFALO_BUFF_Mage_MageArmor_Name]		= BUFFALO_BUFF_Mage_MageArmor;
		matrix[BUFFALO_BUFF_Mage_IceArmor_Name]			= BUFFALO_BUFF_Mage_IceArmor;
		matrix[BUFFALO_BUFF_Mage_IceBarrier_Name]		= BUFFALO_BUFF_Mage_IceBarrier;

	elseif englishClassname == "PRIEST" then
		BUFFALO_BUFF_Priest_PowerWordFortitude_Name = Buffalo_GetSpellName(10938);
		BUFFALO_BUFF_Priest_PowerWordFortitude = { 
			["BITMASK"]		= 0x0001, 
			["ICONID"]		= 135987, 
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PowerWordFortitude_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 53, 
			["GROUP"]		= false, 
			["PARENT"]		= "Prayer of Fortitude" 
		};
	
		BUFFALO_BUFF_Priest_PrayerOfFortitude_Name = Buffalo_GetSpellName(21564);
		BUFFALO_BUFF_Priest_PrayerOfFortitude = {
			["BITMASK"]		= 0x0001, 
			["ICONID"]		= 135941, 
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PrayerOfFortitude_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 53, 
			["GROUP"]		= true 
		};

		BUFFALO_BUFF_Priest_DivineSpirit_Name = Buffalo_GetSpellName(27841);
		BUFFALO_BUFF_Priest_DivineSpirit = {
			["BITMASK"]		= 0x0002, 
			["ICONID"]		= 135898, 
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_DivineSpirit_Name),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 52, 
			["GROUP"]		= false, 
			["PARENT"]		= "Prayer of Spirit"
		};

		BUFFALO_BUFF_Priest_PrayerOfSpirit_Name = Buffalo_GetSpellName(27681);
		BUFFALO_BUFF_Priest_PrayerOfSpirit = {
			["BITMASK"]		= 0x0002, 
			["ICONID"]		= 135946,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PrayerOfSpirit_Name),
			["CLASSES"]		= BUFFALO_CLASS_MANAUSERS,
			["PRIORITY"]	= 52,
			["GROUP"]		= true 
		};

		BUFFALO_BUFF_Priest_ShadowProtection_Name = Buffalo_GetSpellName(10958);
		BUFFALO_BUFF_Priest_ShadowProtection = {
			["BITMASK"]		= 0x0004,
			["ICONID"]		= 136121,
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_ShadowProtection_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 51,
			["GROUP"]		= false,
			["PARENT"]		= "Prayer of Shadow Protection" 
		};
	
		BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name = Buffalo_GetSpellName(27683);
		BUFFALO_BUFF_Priest_PrayerOfShadowProtection = {
			["BITMASK"]		= 0x0004, 
			["ICONID"]		= 135945, 
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name),
			["CLASSES"]		= BUFFALO_CLASS_ALL,
			["PRIORITY"]	= 51, 
			["GROUP"]		= true 
		};

		BUFFALO_BUFF_Priest_InnerFire_Name = Buffalo_GetSpellName(10952);
		BUFFALO_BUFF_Priest_InnerFire = {
			["BITMASK"]		= 0x0100, 
			["ICONID"]		= 135926, 
			["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_InnerFire_Name),
			["CLASSES"]		= BUFFALO_CLASS_PRIEST,
			["PRIORITY"]	= 11, 
			["GROUP"]		= false 
		};

		matrix[BUFFALO_BUFF_Priest_PowerWordFortitude_Name]		= BUFFALO_BUFF_Priest_PowerWordFortitude;
		matrix[BUFFALO_BUFF_Priest_PrayerOfFortitude_Name]		= BUFFALO_BUFF_Priest_PrayerOfFortitude;
		matrix[BUFFALO_BUFF_Priest_DivineSpirit_Name]			= BUFFALO_BUFF_Priest_DivineSpirit;
		matrix[BUFFALO_BUFF_Priest_PrayerOfSpirit_Name]			= BUFFALO_BUFF_Priest_PrayerOfSpirit;
		matrix[BUFFALO_BUFF_Priest_ShadowProtection_Name]		= BUFFALO_BUFF_Priest_ShadowProtection;
		matrix[BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name]= BUFFALO_BUFF_Priest_PrayerOfShadowProtection;
		matrix[BUFFALO_BUFF_Priest_InnerFire_Name]				= BUFFALO_BUFF_Priest_InnerFire;
	end;

	--	Filter out spells we havent learned (SpellID is nil)
	for buffName, buffInfo in next, matrix do
		if not buffInfo["SPELLID"] then
			matrix[buffName] = nil;
		end;
	end;

	return matrix;
end;


function Buffalo_InitializeClassMatrix()

	local classMatrix = {
		["DRUID"]		= BUFFALO_CLASS_DRUID,
		["HUNTER"]		= BUFFALO_CLASS_HUNTER,
		["MAGE"]		= BUFFALO_CLASS_MAGE,
		["PALADIN"]		= BUFFALO_CLASS_PALADIN,
		["PRIEST"]		= BUFFALO_CLASS_PRIEST,
		["SHAMAN"]		= BUFFALO_CLASS_SHAMAN,
		["WARLOCK"]		= BUFFALO_CLASS_WARLOCK,
		["WARRIOR"]		= BUFFALO_CLASS_WARRIOR,
		["ROGUE"]		= BUFFALO_CLASS_ROGUE,
	}

	return classMatrix;
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






