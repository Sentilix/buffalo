--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo-configuration.lua
--	Desc:	Configuration of the buffs
--]]

Buffalo = select(2, ...)

Buffalo.matrix = { };
Buffalo.matrix.Buff = { };
Buffalo.matrix.Class = { };				--	[classname<english>]={ ICONID=<icon id>, MASK=<bitmask value> }
Buffalo.matrix.ClassSorted = { };		--	Same, but sorted by SORTORDER: [SORTORDER]={ NAME=classname<english>, ICONID=<icon id>, MASK=<bitmask value> }

Buffalo.matrix.Master = {
	["DRUID"] = {
		["SORTORDER"] = 1,
		["MASK"] = Buffalo.classmasks.Druid,
		["ICONID"] = 625999,
	},
	["HUNTER"] = {
		["SORTORDER"] = 2,
		["MASK"] = Buffalo.classmasks.Hunter,
		["ICONID"] = 626000,
	},
	["MAGE"] = {
		["SORTORDER"] = 3,
		["MASK"] = Buffalo.classmasks.Mage,
		["ICONID"] = 626001,
	},
	["PALADIN"] = {
		["SORTORDER"] = 4,
		["MASK"] = Buffalo.classmasks.Paladin,
		["ICONID"] = 626003,
		["ALLIANCE-EXPAC"] = 1,
		["HORDE-EXPAC"] = 2,
	},
	["PRIEST"] = {
		["SORTORDER"] = 5,
		["MASK"] = Buffalo.classmasks.Priest,
		["ICONID"] = 626004,
	},
	["ROGUE"] = {
		["SORTORDER"] = 6,
		["MASK"] = Buffalo.classmasks.Rogue,
		["ICONID"] = 626005,
	},
	["SHAMAN"] = {
		["SORTORDER"] = 7,
		["MASK"] = Buffalo.classmasks.Shaman,
		["ICONID"] = 626006,
		["ALLIANCE-EXPAC"] = 2,
		["HORDE-EXPAC"] = 1,
	},
	["WARLOCK"] = {
		["SORTORDER"] = 8,
		["MASK"] = Buffalo.classmasks.Warlock,
		["ICONID"] = 626007,
	},
	["WARRIOR"] = {
		["SORTORDER"] = 9,
		["MASK"] = Buffalo.classmasks.Warrior,
		["ICONID"] = 626008,
	},
	["DEATHKNIGHT"] = {
		["SORTORDER"] = 10,
		["MASK"] = Buffalo.classmasks.DeathKnight,
		["ICONID"] = 135771,
		["ALLIANCE-EXPAC"] = 3,
		["HORDE-EXPAC"] = 3,
	},
	["PET"] = {
		["SORTORDER"] = 11,
		["MASK"] = Buffalo.classmasks.Pet,
		["ICONID"] = 132599,
	}
};



function Buffalo:getSpellID(spellname)
	local _, _, _, _, _, _, spellID = GetSpellInfo(spellname);
	return spellID;
end;

function Buffalo:getSpellName(spellID)
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
function Buffalo:initializeBuffMatrix()

	local localClassname, englishClassname = UnitClass("player");
	local matrix = { };

	--	General spells:
	Buffalo.spellnames.general.FindHerbs = Buffalo:getSpellName(2383); 
	Buffalo.spellnames.general.FindMinerals = Buffalo:getSpellName(2580); 

	matrix[Buffalo.spellnames.general.FindHerbs]	= {
		["BITMASK"]		= 0x04000,
		["ICONID"]		= 133939,
		["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.general.FindHerbs),
		["CLASSES"]		= Buffalo.classmasks.ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	matrix[Buffalo.spellnames.general.FindMinerals] = {
		["BITMASK"]		= 0x08000,
		["ICONID"]		= 136025,
		["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.general.FindMinerals),
		["CLASSES"]		= Buffalo.classmasks.ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};



	if englishClassname == "DRUID" then
		Buffalo.spellnames.druid.MarkOfTheWild = Buffalo:getSpellName(9885);
		Buffalo.spellnames.druid.GiftOfTheWild = Buffalo:getSpellName(21850); 
		Buffalo.spellnames.druid.Thorns = Buffalo:getSpellName(9910); 

		matrix[Buffalo.spellnames.druid.MarkOfTheWild] = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 136078,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.druid.MarkOfTheWild),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= false,
			["PARENT"]		= Buffalo.spellnames.druid.GiftOfTheWild
		};

		matrix[Buffalo.spellnames.druid.GiftOfTheWild] = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 136078,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.druid.GiftOfTheWild),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= true,
			["SINGLE"]		= Buffalo.spellnames.druid.MarkOfTheWild
		};

		matrix[Buffalo.spellnames.druid.Thorns] = {
			["BITMASK"]		= 0x000002,
			["ICONID"]		= 136104,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.druid.Thorns),
			["CLASSES"]		= Buffalo.classmasks.Warrior + Buffalo.classmasks.Druid,
			["PRIORITY"]	= 51,
			["GROUP"]		= false
		};


	elseif englishClassname == "MAGE" then	
		Buffalo.spellnames.mage.ArcaneIntellect		= Buffalo:getSpellName(10157);  
		Buffalo.spellnames.mage.ArcaneBrilliance	= Buffalo:getSpellName(23028);  
		Buffalo.spellnames.mage.AmplifyMagic		= Buffalo:getSpellName(10170);
		Buffalo.spellnames.mage.DampenMagic			= Buffalo:getSpellName(10174);
		Buffalo.spellnames.mage.MoltenArmor			= Buffalo:getSpellName(30482);
		Buffalo.spellnames.mage.MageArmor			= Buffalo:getSpellName(22783);
		Buffalo.spellnames.mage.FrostArmor			= Buffalo:getSpellName(12544);
		Buffalo.spellnames.mage.IceArmor			= Buffalo:getSpellName(10220);
		Buffalo.spellnames.mage.IceBarrier			= Buffalo:getSpellName(13033);

		matrix[Buffalo.spellnames.mage.ArcaneIntellect] = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 135932,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.ArcaneIntellect),
			["CLASSES"]		= Buffalo.classmasks.MANAUSERS,
			["PRIORITY"]	= 53,
			["GROUP"]		= false,
			["PARENT"]		= Buffalo.spellnames.mage.ArcaneBrilliance
		};

		matrix[Buffalo.spellnames.mage.ArcaneBrilliance] = {
			["BITMASK"]		= 0x000001,
			["ICONID"]		= 135869,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.ArcaneBrilliance),
			["CLASSES"]		= Buffalo.classmasks.MANAUSERS,
			["PRIORITY"]	= 53,
			["GROUP"]		= true,
			["SINGLE"]		= Buffalo.spellnames.mage.ArcaneIntellect
		};

		matrix[Buffalo.spellnames.mage.AmplifyMagic] = {
			["BITMASK"]		= 0x000002,
			["ICONID"]		= 135907,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.AmplifyMagic),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 52,
			["GROUP"]		= false,
			["FAMILY"]		= "AmplifyDampen"
		};

		matrix[Buffalo.spellnames.mage.DampenMagic] = {
			["BITMASK"]		= 0x000004,
			["ICONID"]		= 136006,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.DampenMagic),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 51,
			["GROUP"]		= false,
			["FAMILY"]		= "AmplifyDampen"
		};

		matrix[Buffalo.spellnames.mage.MageArmor] = {
			["BITMASK"]		= 0x000100,
			["ICONID"]		= 135991,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.MageArmor),
			["CLASSES"]		= Buffalo.classmasks.Mage,
			["PRIORITY"]	= 13,
			["GROUP"]		= false,
			["FAMILY"]		= "Armor"
		};

		if Buffalo.spellnames.mage.IceArmor then
			matrix[Buffalo.spellnames.mage.IceArmor] = {
				["BITMASK"]		= 0x000200,
				["ICONID"]		= 135843,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.IceArmor),
				["CLASSES"]		= Buffalo.classmasks.Mage,
				["PRIORITY"]	= 12,
				["GROUP"]		= false,
				["FAMILY"]		= "Armor"
			};
		else
			matrix[Buffalo.spellnames.mage.FrostArmor] = {
				["BITMASK"]		= 0x000200,
				["ICONID"]		= 135843,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.FrostArmor),
				["CLASSES"]		= Buffalo.classmasks.Mage,
				["PRIORITY"]	= 15,
				["GROUP"]		= false,
				["FAMILY"]		= "Armor"
			};
		end;

		if Buffalo.spellnames.mage.MoltenArmor then
			matrix[Buffalo.spellnames.mage.MoltenArmor] = {
				["BITMASK"]		= 0x000800,
				["ICONID"]		= 132221,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.MoltenArmor),
				["CLASSES"]		= Buffalo.classmasks.Mage,
				["PRIORITY"]	= 14,
				["GROUP"]		= false,
				["FAMILY"]		= "Armor"
			};
		end;

		matrix[Buffalo.spellnames.mage.IceBarrier] = {
			["BITMASK"]		= 0x000400,
			["ICONID"]		= 135988,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.mage.IceBarrier),
			["COOLDOWN"]	= 30,
			["CLASSES"]		= Buffalo.classmasks.Mage,
			["PRIORITY"]	= 11,
			["GROUP"]		= false
		};


	elseif englishClassname == "PRIEST" then
		Buffalo.spellnames.priest.PowerWordFortitude		= Buffalo:getSpellName(10938);
		Buffalo.spellnames.priest.PrayerOfFortitude			= Buffalo:getSpellName(21564);
		Buffalo.spellnames.priest.DivineSpirit				= Buffalo:getSpellName(27841);
		Buffalo.spellnames.priest.PrayerOfSpirit			= Buffalo:getSpellName(27681);
		Buffalo.spellnames.priest.ShadowProtection			= Buffalo:getSpellName(10958);
		Buffalo.spellnames.priest.PrayerOfShadowProtection	= Buffalo:getSpellName(27683);
		Buffalo.spellnames.priest.InnerFire					= Buffalo:getSpellName(10952);
		Buffalo.spellnames.priest.ShadowForm				= Buffalo:getSpellName(15473);

		matrix[Buffalo.spellnames.priest.PowerWordFortitude] = { 
			["BITMASK"]		= 0x000001, 
			["ICONID"]		= 135987, 
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.PowerWordFortitude),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 53, 
			["GROUP"]		= false, 
			["PARENT"]		= Buffalo.spellnames.priest.PrayerOfFortitude 
		};
	
		matrix[Buffalo.spellnames.priest.PrayerOfFortitude] = {
			["BITMASK"]		= 0x000001, 
			["ICONID"]		= 135941, 
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.PrayerOfFortitude),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 53, 
			["GROUP"]		= true,
			["SINGLE"]		= Buffalo.spellnames.priest.PowerWordFortitude
		};

		matrix[Buffalo.spellnames.priest.DivineSpirit] = {
			["BITMASK"]		= 0x000002, 
			["ICONID"]		= 135898, 
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.DivineSpirit),
			["CLASSES"]		= Buffalo.classmasks.MANAUSERS,
			["PRIORITY"]	= 52, 
			["GROUP"]		= false, 
			["PARENT"]		= Buffalo.spellnames.priest.PrayerOfSpirit
		};

		matrix[Buffalo.spellnames.priest.PrayerOfSpirit] = {
			["BITMASK"]		= 0x000002, 
			["ICONID"]		= 135946,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.PrayerOfSpirit),
			["CLASSES"]		= Buffalo.classmasks.MANAUSERS,
			["PRIORITY"]	= 52,
			["GROUP"]		= true,
			["SINGLE"]		= Buffalo.spellnames.priest.DivineSpirit
		};

		matrix[Buffalo.spellnames.priest.ShadowProtection] = {
			["BITMASK"]		= 0x000004,
			["ICONID"]		= 136121,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.ShadowProtection),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 51,
			["GROUP"]		= false,
			["PARENT"]		= Buffalo.spellnames.priest.PrayerOfShadowProtection 
		};
	
		matrix[Buffalo.spellnames.priest.PrayerOfShadowProtection] = {
			["BITMASK"]		= 0x000004, 
			["ICONID"]		= 135945, 
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.PrayerOfShadowProtection),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 51, 
			["GROUP"]		= true,
			["SINGLE"]		= Buffalo.spellnames.priest.ShadowProtection
		};

		matrix[Buffalo.spellnames.priest.ShadowForm] = {
			["BITMASK"]		= 0x000200, 
			["ICONID"]		= 136200, 
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.ShadowForm),
			["CLASSES"]		= Buffalo.classmasks.Priest,
			["PRIORITY"]	= 11, 
			["GROUP"]		= false 
		};

		matrix[Buffalo.spellnames.priest.InnerFire] = {
			["BITMASK"]		= 0x000100, 
			["ICONID"]		= 135926, 
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.priest.InnerFire),
			["CLASSES"]		= Buffalo.classmasks.Priest,
			["PRIORITY"]	= 12, 
			["GROUP"]		= false 
		};


	elseif englishClassname == "WARLOCK" then
		Buffalo.spellnames.warlock.DemonSkin = Buffalo:getSpellName(696);
		Buffalo.spellnames.warlock.DemonArmor = Buffalo:getSpellName(11735);
		Buffalo.spellnames.warlock.FireShield = Buffalo:getSpellName(11771);
		Buffalo.spellnames.warlock.UnendingBreath = Buffalo:getSpellName(5697);
		Buffalo.spellnames.warlock.DetectLesserInvisibility = Buffalo:getSpellName(132);
		Buffalo.spellnames.warlock.DetectInvisibility = Buffalo:getSpellName(2970);
		Buffalo.spellnames.warlock.DetectGreaterInvisibility = Buffalo:getSpellName(11743);
		Buffalo.spellnames.warlock.Imp = Buffalo:getSpellName(688);
		Buffalo.spellnames.warlock.Voidwalker = Buffalo:getSpellName(697);
		Buffalo.spellnames.warlock.Felhunter = Buffalo:getSpellName(691);
		Buffalo.spellnames.warlock.Succubus = Buffalo:getSpellName(712);
		Buffalo.spellnames.warlock.Incubus = Buffalo:getSpellName(713);

		--	Pick the highest learned Invisibility rank:
		if Buffalo:getSpellID(Buffalo.spellnames.warlock.DetectGreaterInvisibility) then
			matrix[Buffalo.spellnames.warlock.DetectGreaterInvisibility] = { 
				["BITMASK"]		= 0x000001,
				["ICONID"]		= 136152,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.DetectGreaterInvisibility),
				["CLASSES"]		= Buffalo.classmasks.ALL,
				["PRIORITY"]	= 21,
				["GROUP"]		= false, 
			};
		elseif Buffalo:getSpellID(Buffalo.spellnames.warlock.DetectInvisibility) then
			matrix[Buffalo.spellnames.warlock.DetectInvisibility] = { 
				["BITMASK"]		= 0x000001,
				["ICONID"]		= 136152,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.DetectInvisibility),
				["CLASSES"]		= Buffalo.classmasks.ALL,
				["PRIORITY"]	= 21,
				["GROUP"]		= false, 
			};
		else
			matrix[Buffalo.spellnames.warlock.DetectLesserInvisibility] = { 
				["BITMASK"]		= 0x000001,
				["ICONID"]		= 136153,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.DetectLesserInvisibility),
				["CLASSES"]		= Buffalo.classmasks.ALL,
				["PRIORITY"]	= 21,
				["GROUP"]		= false, 
			};
		end

		matrix[Buffalo.spellnames.warlock.UnendingBreath] = { 
			["BITMASK"]		= 0x000002,
			["ICONID"]		= 136148,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.UnendingBreath),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 22,
			["GROUP"]		= false, 
			["IGNORERANGECHECK"] = true,
		};

		matrix[Buffalo.spellnames.warlock.FireShield] = { 
			["BITMASK"]		= 0x000004,
			["ICONID"]		= 135806,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.FireShield),
			["CLASSES"]		= Buffalo.classmasks.ALL,
			["PRIORITY"]	= 23,
			["GROUP"]		= false, 
			["IGNORERANGECHECK"] = true,
		};

		--	Only use Armor if learned, otherwise pick Skin:
		if Buffalo:getSpellID(Buffalo.spellnames.warlock.DemonArmor) then
			matrix[Buffalo.spellnames.warlock.DemonArmor]	= { 
				["BITMASK"]		= 0x000100,
				["ICONID"]		= 136185,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.DemonArmor),
				["CLASSES"]		= Buffalo.classmasks.Warlock,
				["PRIORITY"]	= 11,
				["GROUP"]		= false, 
			};
		elseif Buffalo:getSpellID(Buffalo.spellnames.warlock.DemonSkin) then
			matrix[Buffalo.spellnames.warlock.DemonSkin]	= {
				["BITMASK"]		= 0x000100,
				["ICONID"]		= 136185,
				["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.DemonSkin),
				["CLASSES"]		= Buffalo.classmasks.Warlock,
				["PRIORITY"]	= 11,
				["GROUP"]		= false, 
			};
		end;

		matrix[Buffalo.spellnames.warlock.Imp] = { 
			["BITMASK"]		= 0x000400,
			["ICONID"]		= 136218,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.Imp),
			["CLASSES"]		= Buffalo.classmasks.Warlock,
			["PRIORITY"]	= 39,
			["GROUP"]		= false, 
			["FAMILY"]		= "Demon",
		};

		matrix[Buffalo.spellnames.warlock.Voidwalker] = { 
			["BITMASK"]		= 0x000800,
			["ICONID"]		= 136221,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.Voidwalker),
			["CLASSES"]		= Buffalo.classmasks.Warlock,
			["PRIORITY"]	= 38,
			["GROUP"]		= false, 
			["FAMILY"]		= "Demon",
		};

		matrix[Buffalo.spellnames.warlock.Felhunter] = { 
			["BITMASK"]		= 0x001000,
			["ICONID"]		= 136217,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.Felhunter),
			["CLASSES"]		= Buffalo.classmasks.Warlock,
			["PRIORITY"]	= 37,
			["GROUP"]		= false, 
			["FAMILY"]		= "Demon",
		};

		--	Use Succubus as default; Incobus will have am invaoid bitmask:
		matrix[Buffalo.spellnames.warlock.Succubus] = { 
			["BITMASK"]		= 0x002000,
			["ICONID"]		= 136220,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.Succubus),
			["CLASSES"]		= Buffalo.classmasks.Warlock,
			["PRIORITY"]	= 36,
			["GROUP"]		= false, 
			["FAMILY"]		= "Demon",
		};

		matrix[Buffalo.spellnames.warlock.Incubus] = { 
			["BITMASK"]		= 0x000000,
			["ICONID"]		= 4352492,
			["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.warlock.Incubus),
			["CLASSES"]		= Buffalo.classmasks.Warlock,
			["PRIORITY"]	= 36,
			["GROUP"]		= false, 
			["FAMILY"]		= "Demon",
		};
	end;

	--	Filter out spells we havent learned (SpellID is nil)
	for buffName, buffInfo in next, matrix do
		if not buffInfo["SPELLID"] then
			matrix[buffName] = nil;
		end;
	end;

	return matrix;
end;


function Buffalo:initializeAssignedGroupDefaults()
	local localClassname, englishClassname = UnitClass("player");
	local assignedGroupBuffs = { };

	local groupMask = 0;

	if englishClassname == "DRUID" then
		groupMask = Buffalo.config.DEFAULT_Druid_GroupMask;
	elseif englishClassname == "MAGE" then
		groupMask = Buffalo.config.DEFAULT_Mage_GroupMask;
	elseif englishClassname == "PRIEST" then
		groupMask = Buffalo.config.DEFAULT_Priest_GroupMask;
	elseif englishClassname == "WARLOCK" then
		groupMask = Buffalo.config.DEFAULT_Warlock_GroupMask;
	end

	for groupNum = 1, 8, 1 do
		assignedGroupBuffs[groupNum] = groupMask;
	end;

	return assignedGroupBuffs;
end;






