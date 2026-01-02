--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo-configuration.lua
--	Desc:	Configuration of the buffs
--]]

Buffalo = select(2, ...)

Buffalo["spellnames"] = {
	["shared"] = {
		["FindHerbs"]					= GetSpellInfo(2383),
		["FindMinerals"]				= GetSpellInfo(2580),
	},
	["druid"] = {
		["MarkOfTheWild"]				= GetSpellInfo(9885),
		["GiftOfTheWild"]				= GetSpellInfo(21850),
		["Thorns"]						= GetSpellInfo(9910),
		["OmenOfClarity"]				= GetSpellInfo(16864),
	},
	["mage"] = {
		["ArcaneIntellect"]				= GetSpellInfo(10157),
		["ArcaneBrilliance"]			= GetSpellInfo(23028),
		["AmplifyMagic"]				= GetSpellInfo(10170),
		["DampenMagic"]					= GetSpellInfo(10174),
		["MageArmor"]					= GetSpellInfo(22783),
		["FrostArmor"]					= GetSpellInfo(7301),
		["IceArmor"]					= GetSpellInfo(10220),
		["MoltenArmor"]					= GetSpellInfo(30482),
		["IceBarrier"]					= GetSpellInfo(13033),
	},
	["priest"] = {
		["PowerWordFortitude"]			= GetSpellInfo(10938),
		["PrayerOfFortitude"]			= GetSpellInfo(21564),
		["DivineSpirit"]				= GetSpellInfo(27841),
		["PrayerOfSpirit"]				= GetSpellInfo(27681),
		["ShadowProtection"]			= GetSpellInfo(10958),
		["PrayerOfShadowProtection"]	= GetSpellInfo(27683),
		["InnerFire"]					= GetSpellInfo(10952),
		["ShadowForm"]					= GetSpellInfo(15473),
	},
	["warlock"] = {
		["DemonSkin"]					= GetSpellInfo(696),
		["DemonArmor"]					= GetSpellInfo(11735),
		["FireShield"]					= GetSpellInfo(11771),
		["UnendingBreath"]				= GetSpellInfo(5697),
		["DetectLesserInvisibility"]	= GetSpellInfo(132),
		["DetectInvisibility"]			= GetSpellInfo(2970),
		["DetectGreaterInvisibility"]	= GetSpellInfo(11743),
		["Imp"]							= GetSpellInfo(688),
		["Voidwalker"]					= GetSpellInfo(697),
		["Felhunter"]					= GetSpellInfo(691),
		["Succubus"]					= GetSpellInfo(712),
		["Incubus"]						= GetSpellInfo(713),
	},
};

Buffalo["sorted"] = {
	["classes"] = { },
	["spells"] = { },
	["groupOnly"] = { },
	["groupAll"] = { },
};

Buffalo["spells"] = {
	["active"] = { },		--	All spells for the current class.
	["personal"] = { },		--	Spells for buffing, including selfie spells.
	["group"] = { },		--	Spells for buffing, raid buffing only.
};


--	Generate class tree.
--	Index by localized spell name which is why GetSpellInfo() is called directly:
Buffalo["classes"] = {
	["DRUID"] = {
		["SortOrder"]		= 1,
		["Mask"]			= Buffalo.classmasks.Druid,
		["IconID"]			= 625999,
		["spells"] = {
			[Buffalo.spellnames.druid.MarkOfTheWild] = {
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 9885,
				["Priority"]	= 52,
				["Parent"]		= Buffalo.spellnames.druid.GiftOfTheWild
			},
			[Buffalo.spellnames.druid.GiftOfTheWild] = {
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 21850,
				["Priority"]	= 52,
				["Group"]		= true,
				["Single"]		= Buffalo.spellnames.druid.MarkOfTheWild
			},
			[Buffalo.spellnames.druid.Thorns] = {
				["Bitmask"]		= 0x000002,
				["Classmask"]	= Buffalo.classmasks.Warrior + Buffalo.classmasks.Druid,
				["MaxSpellId"]	= 9910,
				["Priority"]	= 51,
			},
			[Buffalo.spellnames.druid.OmenOfClarity] = {
				["Bitmask"]		= 0x000100,
				["Classmask"]	= Buffalo.classmasks.Druid,
				["MaxSpellId"]	= 16864,
				["Priority"]	= 53,
			},
		},
	},
	["HUNTER"] = {
		["SortOrder"]		= 2,
		["Mask"]			= Buffalo.classmasks.Hunter,
		["IconID"]			= 626000,
	},
	["MAGE"] = {
		["SortOrder"]		= 3,
		["Mask"]			= Buffalo.classmasks.Mage,
		["IconID"]			= 626001,
		["spells"] = {
			[Buffalo.spellnames.mage.ArcaneIntellect] = {
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.MANAUSERS,
				["MaxSpellId"]	= 10157,
				["Priority"]	= 53,
				["Parent"]		= Buffalo.spellnames.mage.ArcaneBrilliance
			},
			[Buffalo.spellnames.mage.ArcaneBrilliance] = {
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.MANAUSERS,
				["MaxSpellId"]	= 23028,
				["Priority"]	= 53,
				["Group"]		= true,
				["Single"]		= Buffalo.spellnames.mage.ArcaneIntellect
			},
			[Buffalo.spellnames.mage.AmplifyMagic] = {
				["Bitmask"]		= 0x000002,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 10170,
				["Priority"]	= 52,
				["Family"]		= "AmplifyDampen"
			},
			[Buffalo.spellnames.mage.DampenMagic] = {
				["Bitmask"]		= 0x000004,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 10174,
				["Priority"]	= 51,
				["Family"]		= "AmplifyDampen"
			},
			[Buffalo.spellnames.mage.MageArmor] = {
				["Bitmask"]		= 0x000100,
				["Classmask"]	= Buffalo.classmasks.Mage,
				["MaxSpellId"]	= 22783,
				["Priority"]	= 13,
				["Family"]		= "Armor"
			},
			[Buffalo.spellnames.mage.FrostArmor] = {
				["Bitmask"]		= 0x000200,
				["Classmask"]	= Buffalo.classmasks.Mage,
				["MaxSpellId"]	= 7301,		--	12544,
				["Priority"]	= 12,
				["ReplacedBy"]	= Buffalo.spellnames.mage.IceArmor,
				["Family"]		= "Armor"
			},
			[Buffalo.spellnames.mage.IceArmor] = {
				["Bitmask"]		= 0x000200,
				["Classmask"]	= Buffalo.classmasks.Mage,
				["MaxSpellId"]	= 10220,
				["Priority"]	= 12,
				["Replacing"]	= Buffalo.spellnames.mage.FrostArmor,
				["Family"]		= "Armor"				
			},
			[Buffalo.spellnames.mage.IceBarrier] = {
				["Bitmask"]		= 0x000400,
				["Cooldown"]	= 30,
				["Classmask"]	= Buffalo.classmasks.Mage,
				["MaxSpellId"]	= 13033,
				["Priority"]	= 10,
			},
			--	TBC: 0x000800	Buffalo.spellnames.mage.MoltenArmor
		},
	},
	["PALADIN"] = {
		["SortOrder"]		= 4,
		["Mask"]			= Buffalo.classmasks.Paladin,
		["IconID"]			= 626003,
		["AllianceExpac"]	= 1,
		["HordeExpac"]		= 2,
	},
	["PRIEST"] = {
		["SortOrder"]		= 5,
		["Mask"]			= Buffalo.classmasks.Priest,
		["IconID"]			= 626004,
		["spells"] = {
			[Buffalo.spellnames.priest.PowerWordFortitude] = {
				["Bitmask"]		= 0x000001, 
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 10938,
				["Priority"]	= 53, 
				["Parent"]		= Buffalo.spellnames.priest.PrayerOfFortitude 
			},
			[Buffalo.spellnames.priest.PrayerOfFortitude] = {
				["Bitmask"]		= 0x000001, 
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 21564,
				["Priority"]	= 53, 
				["Group"]		= true,
				["Single"]		= Buffalo.spellnames.priest.PowerWordFortitude
			},
			[Buffalo.spellnames.priest.DivineSpirit] = {
				["Bitmask"]		= 0x000002, 
				["Classmask"]	= Buffalo.classmasks.MANAUSERS,
				["MaxSpellId"]	= 27841,
				["Priority"]	= 52, 
				["Parent"]		= Buffalo.spellnames.priest.PrayerOfSpirit
			},
			[Buffalo.spellnames.priest.PrayerOfSpirit] = {
				["Bitmask"]		= 0x000002, 
				["Classmask"]	= Buffalo.classmasks.MANAUSERS,
				["MaxSpellId"]	= 27681,
				["Priority"]	= 52,
				["Group"]		= true,
				["Single"]		= Buffalo.spellnames.priest.DivineSpirit
			},
			[Buffalo.spellnames.priest.ShadowProtection] = {
				["Bitmask"]		= 0x000004,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 10958,
				["Priority"]	= 51,
				["Parent"]		= Buffalo.spellnames.priest.PrayerOfShadowProtection 
			},
			[Buffalo.spellnames.priest.PrayerOfShadowProtection] = {
				["Bitmask"]		= 0x000004, 
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 27683,
				["Priority"]	= 51, 
				["Group"]		= true,
				["Single"]		= Buffalo.spellnames.priest.ShadowProtection
			},
			[Buffalo.spellnames.priest.ShadowForm] = {
				["Bitmask"]		= 0x000200, 
				["Classmask"]	= Buffalo.classmasks.Priest,
				["MaxSpellId"]	= 15473,
				["Priority"]	= 11, 
			},
			[Buffalo.spellnames.priest.InnerFire] = {
				["Bitmask"]		= 0x000100, 
				["Classmask"]	= Buffalo.classmasks.Priest,
				["MaxSpellId"]	= 10952,
				["Priority"]	= 12, 
			};
		},
	},
	["ROGUE"] = {
		["SortOrder"]		= 6,
		["Mask"]			= Buffalo.classmasks.Rogue,
		["IconID"]			= 626005,
	},
	["SHAMAN"] = {
		["SortOrder"]		= 7,
		["Mask"]			= Buffalo.classmasks.Shaman,
		["IconID"]			= 626006,
		["AllianceExpac"]	= 2,
		["HordeExpac"]		= 1,
	},
	["WARLOCK"] = {
		["SortOrder"]		= 8,
		["Mask"]			= Buffalo.classmasks.Warlock,
		["IconID"]			= 626007,
		["spells"] = {
			[Buffalo.spellnames.warlock.DetectLesserInvisibility] = { 
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 132,
				["Priority"]	= 21,
				["ReplacedBy"]	= Buffalo.spellnames.warlock.DetectInvisibility,
			},
			[Buffalo.spellnames.warlock.DetectInvisibility or '_DetectInvisibility'] = { 
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 2970,
				["Priority"]	= 21,
				["Replacing"]	= Buffalo.spellnames.warlock.DetectLesserInvisibility,
				["ReplacedBy"]	= Buffalo.spellnames.warlock.DetectGreaterInvisibility,
			},
			[Buffalo.spellnames.warlock.DetectGreaterInvisibility or '_DetectGreaterInvisibility'] = { 
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 11743,
				["Priority"]	= 21,
				["Replacing"]	= Buffalo.spellnames.warlock.DetectInvisibility,
			},
			[Buffalo.spellnames.warlock.UnendingBreath] = { 
				["Bitmask"]		= 0x000002,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 5697,
				["Priority"]	= 22,
				["IgnoreRangeCheck"] = true,
			},
			[Buffalo.spellnames.warlock.FireShield] = { 
				["Bitmask"]		= 0x000004,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 11771,
				["Priority"]	= 23,
				["IgnoreRangeCheck"] = true,
			},
			[Buffalo.spellnames.warlock.DemonSkin]	= {
				["Bitmask"]		= 0x000100,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 696,
				["Priority"]	= 11,
				["ReplacedBy"]	= Buffalo.spellnames.warlock.DemonArmor,
			},
			[Buffalo.spellnames.warlock.DemonArmor]	= { 
				["Bitmask"]		= 0x000100,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 11735,
				["Priority"]	= 11,
				["Replacing"]	= Buffalo.spellnames.warlock.DemonSkin,
			},
			--	TBC: 0x000100	Buffalo.spellnames.warlock.FelArmor
			[Buffalo.spellnames.warlock.Imp] = { 
				["Bitmask"]		= 0x000400,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 688,
				["Priority"]	= 39,
				["Family"]		= "Demon",
			},
			[Buffalo.spellnames.warlock.Voidwalker] = { 
				["Bitmask"]		= 0x000800,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 697,
				["Priority"]	= 38,
				["Family"]		= "Demon",
			},
			[Buffalo.spellnames.warlock.Felhunter] = { 
				["Bitmask"]		= 0x001000,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 691,
				["Priority"]	= 37,
				["Family"]		= "Demon",
			},
			[Buffalo.spellnames.warlock.Succubus] = { 
				["Bitmask"]		= 0x002000,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 712,
				["Priority"]	= 36,
				["Family"]		= "Demon",
				["Succubus"]	= true,
			},
			[Buffalo.spellnames.warlock.Incubus] = { 
				["Bitmask"]		= 0x002000,
				["Classmask"]	= Buffalo.classmasks.Warlock,
				["MaxSpellId"]	= 713,
				["Priority"]	= 36,
				["Family"]		= "Demon",
				["Incubus"]		= true,
			},
			--	TBC: 0x004000	Buffalo.spellnames.warlock.Felguard
			--	TBC: 0x008000	Buffalo.spellnames.warlock.Inferno
		},
	},
	["WARRIOR"] = {
		["SortOrder"]		= 9,
		["Mask"]			= Buffalo.classmasks.Warrior,
		["IconID"]			= 626008,
	},
	["PET"] = {
		["SortOrder"]		= 10,
		["Mask"]			= Buffalo.classmasks.Pet,
		["IconID"]			= 132599,
	},
	["shared"] = {
		["spells"] = {
			[Buffalo.spellnames.shared.FindHerbs]	= {
				["Bitmask"]		= 0x04000,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 2383,
				["Priority"]	= 10,
			},
			[Buffalo.spellnames.shared.FindMinerals] = {
				["Bitmask"]		= 0x08000,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 2580,
				["Priority"]	= 10,
			},	
		},
	},
}

--	Added in TBC:
--	Hack: the library has not loaded yet, we need to figure out the expansion level ourselves:
local _addonExpansionLevel = tonumber(C_AddOns.GetAddOnMetadata("Buffalo", "X-Expansion-Level"))

if (_addonExpansionLevel or 0) == 2 then

	Buffalo.spellnames.mage["MoltenArmor"]		= GetSpellInfo(30482);
	Buffalo.spellnames.warlock["Felguard"]		= GetSpellInfo(30146);
	Buffalo.spellnames.warlock["Inferno"]		= GetSpellInfo(34249);
	Buffalo.spellnames.warlock["FelArmor"]		= GetSpellInfo(28189);


	Buffalo.classes.MAGE.spells[Buffalo.spellnames.mage.MoltenArmor] = {
		["Bitmask"]		= 0x000800,
		["Classmask"]	= Buffalo.classmasks.Mage,
		["MaxSpellId"]	= 30482,
		["Priority"]	= 11,
		["Family"]		= "Armor",
	}

	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.Felguard] = {
		["Bitmask"]		= 0x004000,
		["Classmask"]	= Buffalo.classmasks.Warlock,
		["MaxSpellId"]	= 30146,
		["Priority"]	= 35,
		["Family"]		= "Demon",
	}
	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.Inferno] = {
		["Bitmask"]		= 0x008000,
		["Classmask"]	= Buffalo.classmasks.Warlock,
		["MaxSpellId"]	= 34249,
		["Priority"]	= 34,
		["Family"]		= "Demon",
	}

	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.DemonSkin]["ReplacedBy"]	= Buffalo.spellnames.warlock.FelArmor;
	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.DemonArmor] = nil;
	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.FelArmor] = {
		["Bitmask"]		= 0x000100,
		["Classmask"]	= Buffalo.classmasks.Warlock,
		["MaxSpellId"]	= 28189,
		["Priority"]	= 11,
		["Replacing"]	= Buffalo.spellnames.warlock.DemonSkin,
	}

	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.DetectLesserInvisibility].ReplacedBy = nil;
	Buffalo.classes.WARLOCK.spells[Buffalo.spellnames.warlock.DetectLesserInvisibility].MaxSpellId = 132;

end;


function Buffalo:updateSpellMatrix()
	Buffalo:updateSpellMatrixByClass(Buffalo.vars.PlayerClass);
	Buffalo:updateSpellMatrixByClass("shared");

	Buffalo:refreshActiveSpells();
end;

function Buffalo:updateSpellMatrixByClass(classname)
	local classInfo = Buffalo.classes[classname];
	if not classInfo then
		return;
	end;

	--	Loop 1: Make sure to disable all spells.
	--	This ensures dependencies will be handled correct regardless of what order they appear.
	for spellName, spellInfo in pairs(classInfo.spells) do
		spellInfo.Enabled = false;
		spellInfo.Learned = false;
	end;

	--	Loop 2: Do the actual spell update one by one:
	for spellName, spellInfo in pairs(classInfo.spells) do
		local enabled = nil;
		local learned = nil;
		local spellId = nil;

		local name, _, iconId, _, _, _, maxSpellId = GetSpellInfo(spellInfo.MaxSpellId);
		if name then
			local _, _, _, _, _, _, spellId = GetSpellInfo(spellName);
			if spellId ~= nil then
				enabled = true;
				learned = true;
			end;

			--	Disable this spell if there is a better active spell:
			if spellInfo.ReplacedBy and enabled then
				--	There is a better spell - and it is enabled:
				if classInfo.spells[spellInfo.ReplacedBy] and classInfo.spells[spellInfo.ReplacedBy].Learned then
					enabled = nil;
					learned = nil;
				end;
			end;

			--	Disable lower tier spell if this spell if active:
			if spellInfo.Replacing and enabled then
				classInfo.spells[spellInfo.Replacing].Enabled = nil;
				classInfo.spells[spellInfo.Replacing].Learned = nil;
			end;

			--	Handle Succubus / Incubus configuration:
			if spellInfo.Succubus then
				if Buffalo.config.value.UseIncubus then
					bitMask = 0x000000;
					enabled = nil;
				else
					bitMask = 0x002000;
				end;			
			elseif spellInfo.Incubus then
				if Buffalo.config.value.UseIncubus then
					bitMask = 0x002000;
				else
					bitMask = 0x000000;
					enabled = nil;
				end;
			end;

		end;

		spellInfo.Enabled = enabled;
		spellInfo.Learned = learned;
		spellInfo.IconID = iconId or 0;
		spellInfo.SpellID = spellId;
	end;

--	Buffalo.lib:printAll(classInfo);
--	print(string.format('*** Initializing, player=%s', Buffalo.vars.PlayerClass));
end;


--[[
	Buffalo.spells.active[<buff name>] = spellInfo
	Added in 0.7.0
	Refresh the list of all spells. This list contains both Learned and not learned spells.
--]]
function Buffalo:refreshActiveSpells()
	Buffalo.spells.active = { };

	local classInfo = Buffalo.classes[Buffalo.vars.PlayerClass];
	if classInfo then
		for spellName, spellInfo in pairs(classInfo.spells) do
			Buffalo.spells.active[spellName] = spellInfo;
		end;
	end;

	classInfo = Buffalo.classes.shared;
	if classInfo then
		for spellName, spellInfo in pairs(classInfo.spells) do
			Buffalo.spells.active[spellName] = spellInfo;
		end;
	end;
end;

--[[
	Buffalo.classes represented in a table ordered by SortOrder:
	Usefull when displaying stuff.
	Added in 0.6.0
--]]
function Buffalo:sortClasses()
	Buffalo.sorted.classes = { };

	--	Copy class information into a table so we can sort it using sortOrder:
	for className, classInfo in next, Buffalo.classes do
		if className ~= "sorted" and className ~= "shared" then
			tinsert(Buffalo.sorted.classes, {
				ClassName	= className, 
				IconID		= classInfo.IconID,
				SortOrder	= classInfo.SortOrder
			});
		end;
	end;
	table.sort(Buffalo.sorted.classes, function (a, b) return a.SortOrder < b.SortOrder; end);
end;

--[[
	Buffalo.spells.personal (when includeSelfBuffs = true)	Was: Buffalo.sorted.groupAll
	Buffalo.spells.group (no selfie buffs included)			Was: Buffalo.sorted.groupOnly
--]]
function Buffalo:updateGroupBuffs(includeSelfBuffs)
	--	This generate a table of all RAID buffs, ordered in priority:
	local buffs = { };

	local priority;
	local includeMask = 0x00ff;
	local selfiePrio = 0;

	--	This includes Self buffs, but not Find Herbs/Minerals
	local selfiePrioMask = 0x03f00;
	if includeSelfBuffs then
		includeMask = 0x0ffff;
		selfiePrio = 50;
	end;

	--	Works on ALL spells, not only ACTIVE (learned) spells.
	for spellName, spellInfo in pairs(Buffalo.spells.active) do
		if not spellInfo.Group and (bit.band(spellInfo.Bitmask, includeMask) > 0) then
			priority = spellInfo.Priority;

			if bit.band(spellInfo.Bitmask, selfiePrioMask) > 0 then
				priority = priority + selfiePrio;
			end;

			tinsert(buffs, {
				["SpellName"]	= spellName;
				["IconID"]		= spellInfo.IconID;
				["Bitmask"]		= spellInfo.Bitmask;
				["Priority"]	= priority;
				["Enabled"]		= spellInfo.Enabled;
				["Learned"]		= spellInfo.Learned;
			});
		end;
	end;

	table.sort(buffs, function (a, b) return a.Priority > b.Priority; end);

	if includeSelfBuffs then
		Buffalo.spells.personal = buffs;
	else
		Buffalo.spells.group = buffs;
	end;
end;

function Buffalo:getSpellID(spellname)
	local _, _, _, _, _, _, spellID = GetSpellInfo(spellname);
	return spellID;
end;

function Buffalo:getSpellName(spellID)
	return GetSpellInfo(spellID);
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

