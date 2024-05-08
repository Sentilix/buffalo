--[[
--	Buffalo buff addon
--	------------------
--	Author: Mimma
--	File:   buffalo-configuration.lua
--	Desc:	Configuration of the buffs
--]]

Buffalo = select(2, ...)

Buffalo.matrix = { };
--Buffalo.matrix.Buff = { };			--	Replaced by Buffalo.spells.active[<spellname>]
--Buffalo.matrix.Class = { };			--	Replaced by Buffalo.classes[<classname>]	[classname<english>]={ ICONID=<icon id>, MASK=<bitmask value> }
--Buffalo.matrix.ClassSorted = { };		--	Same, but sorted by SORTORDER: [SORTORDER]={ NAME=classname<english>, ICONID=<icon id>, MASK=<bitmask value> }

--	Replaced by Buffalo.classes[<classname>]
--Buffalo.matrix.Master = {
--	["DRUID"] = {
--		["SORTORDER"] = 1,
--		["MASK"] = Buffalo.classmasks.Druid,
--		["ICONID"] = 625999,
--	},
--	["HUNTER"] = {
--		["SORTORDER"] = 2,
--		["MASK"] = Buffalo.classmasks.Hunter,
--		["ICONID"] = 626000,
--	},
--	["MAGE"] = {
--		["SORTORDER"] = 3,
--		["MASK"] = Buffalo.classmasks.Mage,
--		["ICONID"] = 626001,
--	},
--	["PALADIN"] = {
--		["SORTORDER"] = 4,
--		["MASK"] = Buffalo.classmasks.Paladin,
--		["ICONID"] = 626003,
--		["ALLIANCE-EXPAC"] = 1,
--		["HORDE-EXPAC"] = 2,
--	},
--	["PRIEST"] = {
--		["SORTORDER"] = 5,
--		["MASK"] = Buffalo.classmasks.Priest,
--		["ICONID"] = 626004,
--	},
--	["ROGUE"] = {
--		["SORTORDER"] = 6,
--		["MASK"] = Buffalo.classmasks.Rogue,
--		["ICONID"] = 626005,
--	},
--	["SHAMAN"] = {
--		["SORTORDER"] = 7,
--		["MASK"] = Buffalo.classmasks.Shaman,
--		["ICONID"] = 626006,
--		["ALLIANCE-EXPAC"] = 2,
--		["HORDE-EXPAC"] = 1,
--	},
--	["WARLOCK"] = {
--		["SORTORDER"] = 8,
--		["MASK"] = Buffalo.classmasks.Warlock,
--		["ICONID"] = 626007,
--	},
--	["WARRIOR"] = {
--		["SORTORDER"] = 9,
--		["MASK"] = Buffalo.classmasks.Warrior,
--		["ICONID"] = 626008,
--	},
--	["DEATHKNIGHT"] = {
--		["SORTORDER"] = 10,
--		["MASK"] = Buffalo.classmasks.DeathKnight,
--		["ICONID"] = 135771,
--		["ALLIANCE-EXPAC"] = 3,
--		["HORDE-EXPAC"] = 3,
--	},
--	["PET"] = {
--		["SORTORDER"] = 11,
--		["MASK"] = Buffalo.classmasks.Pet,
--		["ICONID"] = 132599,
--	}
--};


Buffalo["spellnames"] = {
	["shared"] = {
		["FindHerbs"]					= GetSpellInfo(2383),
		["FindMinerals"]				= GetSpellInfo(2580),
	},
	["druid"] = {
		["MarkOfTheWild"]				= GetSpellInfo(9885),
		["GiftOfTheWild"]				= GetSpellInfo(21850),
		["Thorns"]						= GetSpellInfo(9910),
	},
	["mage"] = {
		["ArcaneIntellect"]				= GetSpellInfo(10157),
		["ArcaneBrilliance"]			= GetSpellInfo(23028),
		["AmplifyMagic"]				= GetSpellInfo(10170),
		["DampenMagic"]					= GetSpellInfo(10174),
		["MageArmor"]					= GetSpellInfo(22783),
		["FrostArmor"]					= GetSpellInfo(12544),
		["IceArmor"]					= GetSpellInfo(10220),
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
	["groupAll"] = { },		-- Er denne ikke samme som "spells"?
};

Buffalo["spells"] = {
	["active"] = { },
};


--	Generate class tree.
--	Index by localized spell name . which is why GetSpellInfo() is called directly:
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
				["MaxSpellId"]	= 12544,
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
				["Priority"]	= 11,
			},
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
			[Buffalo.spellnames.warlock.DetectInvisibility] = { 
				["Bitmask"]		= 0x000001,
				["Classmask"]	= Buffalo.classmasks.ALL,
				["MaxSpellId"]	= 2970,
				["Priority"]	= 21,
				["Replacing"]	= Buffalo.spellnames.warlock.DetectLesserInvisibility,
				["ReplacedBy"]	= Buffalo.spellnames.warlock.DetectGreaterInvisibility,
			},
			[Buffalo.spellnames.warlock.DetectGreaterInvisibility] = { 
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


function Buffalo:updateSpellMatrix()
	Buffalo:updateSpellMatrixByClass(Buffalo.vars.PlayerClass);
	Buffalo:updateSpellMatrixByClass("shared");

	Buffalo:updateActiveBuffs();

	Buffalo:sortSpells();
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
	end;

	--	Loop 2: Do the actual spell update one by one:
	for spellName, spellInfo in pairs(classInfo.spells) do
		local name, _, iconId, _, _, _, maxSpellId = GetSpellInfo(spellInfo.MaxSpellId);
		if not name then return; end;

		local enabled = nil;
		local _, _, _, _, _, _, spellId = GetSpellInfo(spellName);
		if spellId ~= nil then
			enabled = true;
		end;

		--	Disable this spell if there is a better active spell:
		if spellInfo.ReplacedBy and enabled then
			--	There is a better spell - and it is enabled:
			if classInfo.spells[spellInfo.ReplacedBy].Enabled then
				enabled = nil;
			end;
		end;

		--	Disable lower tier spell if this spell if active:
		if spellInfo.Replacing and enabled then
			classInfo.spells[spellInfo.Replacing].Enabled = nil;
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

		spellInfo.Enabled = enabled;
		spellInfo.IconID = iconId;
		spellInfo.SpellID = spellId;
	end;

--	Buffalo.lib:printAll(classInfo);
--	print(string.format('*** Initializing, player=%s', Buffalo.vars.PlayerClass));
end;

--[[
	Buffalo.spells.active[<buff name>] = spellInfo
	Added in 0.7.0
--]]
function Buffalo:updateActiveBuffs()
	Buffalo.spells.active = { };

	local classInfo = Buffalo.classes[Buffalo.vars.PlayerClass];
	if classInfo then
		for spellName, spellInfo in pairs(classInfo.spells) do
			if spellInfo.Enabled then
				Buffalo.spells.active[spellName] = spellInfo;
			end;
		end;
	end;

	classInfo = Buffalo.classes.shared;
	if classInfo then
		for spellName, spellInfo in pairs(classInfo.spells) do
			if spellInfo.Enabled then
				Buffalo.spells.active[spellName] = spellInfo;
			end;
		end;
	end;
end;

--[[
	Buffalo.classes[<classname>] represented in a table ordered by Priority.
	Only self buffs are added into this.
	Added in 0.7.0
--]]
function Buffalo:sortSpells()
	Buffalo.sorted.spells = { };	

	local classInfo = Buffalo.classes[Buffalo.vars.PlayerClass];
	if classInfo then
		for spellName, spellInfo in pairs(classInfo.spells) do
			if spellInfo.frames then
				for _, frame in spellInfo.frames do
					frame:Hide();
				end;
			end;

			if spellInfo.Enabled and not spellInfo.Single then
				tinsert(Buffalo.sorted.spells, spellInfo);
			end;
		end;
	end;

	classInfo = Buffalo.classes.shared;
	if classInfo then
		for spellName, spellInfo in pairs(classInfo.spells) do
			if spellInfo.frames then
				for _, frame in spellInfo.frames do
					frame:Hide();
				end;
			end;

			if spellInfo.Enabled then
				tinsert(Buffalo.sorted.spells, spellInfo);
			end;
		end;
	end;

	table.sort(Buffalo.sorted.spells, function (a, b) return a.Priority < b.Priority; end);

--	Buffalo.lib:printAll(Buffalo.sorted.spells);
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

	--for buffName, props in pairs(Buffalo.matrix.Buff) do
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
				--buffProperties[buffCount].nextSpell	= props["NEXTSPELL"];		--?? There is no NEXTSPELL property
			});
		end;
	end;

	table.sort(buffs, function (a, b) return a.Priority > b.Priority; end);

	if includeSelfBuffs then
		Buffalo.sorted.groupAll = buffs;
	else
		Buffalo.sorted.groupOnly = buffs;
	end;
end;





--[[
Buffalo.matrix.Buffs = { };

function Buffalo:initializeSpellTree()
	--	General spells:
	Buffalo:addSpell( 2383, 0x004000, 10);												-- Find Herbs
	Buffalo:addSpell( 2580, 0x008000, 10);												-- Find Minerals
	--	Druid spells:
	Buffalo:addSpell( 9885, 0x000001, 52, { ["PARENT"] = 21850 });						-- Mark Of The Wild (single buff)
	Buffalo:addSpell(21850, 0x000001, 52, { ["SINGLE"] = 9885 });						-- Gift Of The Wild (group buff)
	Buffalo:addSpell( 9910, 0x000002, 51);					-- Thorns
	--	Mage spells:
	Buffalo:addSpell(10157, 0x000001, 53, { ["PARENT"] = 23028, ["CLASSES"] = Buffalo.classmasks.MANAUSERS });	-- Arcane Intellect (single buff)
	Buffalo:addSpell(23028, 0x000001, 53, { ["SINGLE"] = 10157, ["CLASSES"] = Buffalo.classmasks.MANAUSERS });	-- Arcane Brilliance (group buff)
	Buffalo:addSpell(10170, 0x000002, 52, { ["FAMILY"] = "AmplifyDampen" });			-- Amplify Magic (AmplifyDampen family)
	Buffalo:addSpell(10174, 0x000004, 51, { ["FAMILY"] = "AmplifyDampen" });			-- Dampen Magic (AmplifyDampen family)
	Buffalo:addSpell(30482, 0x000100, 14, { ["FAMILY"] = "Armor", ["CLASSES"] = Buffalo.classmasks.Mage });							-- [WotLK] Molten Armor (Armor family)
	Buffalo:addSpell(22783, 0x000100, 13, { ["FAMILY"] = "Armor", ["CLASSES"] = Buffalo.classmasks.Mage });							-- Mage Armor (Armor family)
	Buffalo:addSpell(12544, 0x000100, 12, { ["FAMILY"] = "Armor", ["CLASSES"] = Buffalo.classmasks.Mage, ["REPLACEDBY"] = 10220 });	-- Frost Armor (Armor family)
	Buffalo:addSpell(10220, 0x000100, 12, { ["FAMILY"] = "Armor", ["CLASSES"] = Buffalo.classmasks.Mage });							-- Ice Armor (Armor family)
	Buffalo:addSpell(13033, 0x000400, 11, { ["COOLDOWN"] = 30,    ["CLASSES"] = Buffalo.classmasks.Mage });		-- Ice Barrier (30 seconds cooldown)
	--	Priest spells:
	Buffalo:addSpell(10938, 0x000001, 53, { ["PARENT"] = 21564 });						-- Power Word: Fortitude (single buff)
	Buffalo:addSpell(21564, 0x000001, 53, { ["SINGLE"] = 10938 });						-- Prayer of Fortitude (group buff)
	Buffalo:addSpell(27841, 0x000002, 52, { ["PARENT"] = 27681, ["CLASSES"] = Buffalo.classmasks.MANAUSERS });	-- Divine Spirit (single buff)
	Buffalo:addSpell(27681, 0x000002, 52, { ["SINGLE"] = 27841, ["CLASSES"] = Buffalo.classmasks.MANAUSERS });	-- Prayer of Spirit (group buff)
	Buffalo:addSpell(10958, 0x000004, 51, { ["PARENT"] = 27683 });						-- Shadow Protection (single buff)
	Buffalo:addSpell(27683, 0x000004, 51, { ["SINGLE"] = 10958 });						-- Prayer of Shadow Protection (group buff)
	Buffalo:addSpell(10952, 0x000100, 12, { ["CLASSES"] = Buffalo.classmasks.Priest });	-- Inner Fire (selfie buff)
	Buffalo:addSpell(15473, 0x000200, 11, { ["CLASSES"] = Buffalo.classmasks.Priest });	-- Shadow Form (selfie buff)

	--	Warlock spells:
	Buffalo:addSpell(  696, 0x000100, 11, { ["CLASSES"] = Buffalo.classmasks.Warlock, ["REPLACEDBY"] = 11735 });	-- Demon Skin (selfie buff)
	Buffalo:addSpell(11735, 0x000100, 11, { ["CLASSES"] = Buffalo.classmasks.Warlock });	-- Demon Armor - replaces Demon Skin (selfie buff)
	Buffalo:addSpell(11771, 0x000004, 23, { ["IGNORERANGECHECK"] = true });					-- Fire Shield (single buff)
	Buffalo:addSpell(  132, 0x000001, 21, { ["REPLACEDBY"] = 2970 });						-- Detect Lesser Invisibility - replaced by Detect Invisibility
	Buffalo:addSpell( 2970, 0x000001, 21, { ["REPLACEDBY"] = 11743 });						-- Detect Invisibility - replaced by Detect Greater Invisibility
	Buffalo:addSpell(11743, 0x000001, 21);													-- Detect Greater Invisibility
	Buffalo:addSpell( 5697, 0x000002, 22, { ["IGNORERANGECHECK"] = true });					-- Unending Breath
	Buffalo:addSpell(  688, 0x000400, 39, { ["FAMILY"] = "Demon", ["CLASSES"] = Buffalo.classmasks.Warlock });	-- Demon: Imp
	Buffalo:addSpell(  697, 0x000800, 38, { ["FAMILY"] = "Demon", ["CLASSES"] = Buffalo.classmasks.Warlock });	-- Demon: Voidwalker
	Buffalo:addSpell(  691, 0x001000, 37, { ["FAMILY"] = "Demon", ["CLASSES"] = Buffalo.classmasks.Warlock });	-- Demon: Felhunter
	Buffalo:addSpell(  712, 0x002000, 36, { ["FAMILY"] = "Demon", ["CLASSES"] = Buffalo.classmasks.Warlock, ["SUCCUBUS"] = true });	-- Demon: Succubus
	Buffalo:addSpell(  713, 0x002000, 36, { ["FAMILY"] = "Demon", ["CLASSES"] = Buffalo.classmasks.Warlock, ["INCUBUS"] = true });	-- Demon: Incubus
end;


function Buffalo:addSpell(spellID, bitMask, priority, params)
	local name, _, iconID, _, _, _, maxSpellID = GetSpellInfo(spellID);

	if not name then
		--	Molten Armor ends here (a WOTLK spell).
		return;
	end;

	if not params then params = { }; end;
	local classMask = params["CLASSES"] or Buffalo.classmasks.ALL;
	local family = params["FAMILY"] or nil;
	local parent = Buffalo:getSpellName(params["PARENT"]) or nil;
	local single = Buffalo:getSpellName(params["SINGLE"]) or nil;
	local group = (params["SINGLE"] ~= nil);
	local cooldown = params["COOLDOWN"] or nil;
	local ignoreRangeCheck = params["IGNORERANGECHECK"] or nil;
	local replacedBy = params["REPLACEDBY"] or nil;

	local _, _, _, _, _, _, spellIDKnown = GetSpellInfo(name);
	enabled = (spellIDKnown ~= nil);

	if enabled and replacedBy and IsSpellKnown(replacedBy) then
		--	If we know a better replacement spell, use that instead:
		enabled = false;
	end;

	if params["SUCCUBUS"] and Buffalo.config.value.UseIncubus then
		bitMask = 0x000000;
		enabled = false;
	end;

	if params["INCUBUS"] and not Buffalo.config.value.UseIncubus then
		bitMask = 0x000000;
		enabled = false;
	end;

	Buffalo.matrix.Buffs[name] = { };
	Buffalo.matrix.Buffs[name].BitMask			= bitMask;
	Buffalo.matrix.Buffs[name].Classes			= classMask;
	Buffalo.matrix.Buffs[name].Cooldown			= cooldown;
	Buffalo.matrix.Buffs[name].Enabled			= enabled;
	Buffalo.matrix.Buffs[name].Family			= family;
	Buffalo.matrix.Buffs[name].Group			= group;
	Buffalo.matrix.Buffs[name].IconID			= iconID;
	Buffalo.matrix.Buffs[name].IgnoreRangeCheck	= ignoreRangeCheck;
	Buffalo.matrix.Buffs[name].Parent			= parent;
	Buffalo.matrix.Buffs[name].Priority			= priority;
	Buffalo.matrix.Buffs[name].Single			= single;
	Buffalo.matrix.Buffs[name].SpellID			= spellID;			-- Max rank spellID. Do we use the SpellID's anywhere? I don't think so!!
	Buffalo.matrix.Buffs[name].SpellIDKnown		= spellIDKnown;		-- Known rank spellID
end;
--]]

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
	--Buffalo.spellnames.shared.FindHerbs = Buffalo:getSpellName(2383); 
	--Buffalo.spellnames.shared.FindMinerals = Buffalo:getSpellName(2580); 

	matrix[Buffalo.spellnames.shared.FindHerbs]	= {
		["BITMASK"]		= 0x04000,
		["ICONID"]		= 133939,
		["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.shared.FindHerbs),
		["CLASSES"]		= Buffalo.classmasks.ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	matrix[Buffalo.spellnames.shared.FindMinerals] = {
		["BITMASK"]		= 0x08000,
		["ICONID"]		= 136025,
		["SPELLID"]		= Buffalo:getSpellID(Buffalo.spellnames.shared.FindMinerals),
		["CLASSES"]		= Buffalo.classmasks.ALL,
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};



	if englishClassname == "DRUID" then
		--Buffalo.spellnames.druid.MarkOfTheWild = Buffalo:getSpellName(9885);
		--Buffalo.spellnames.druid.GiftOfTheWild = Buffalo:getSpellName(21850); 
		--Buffalo.spellnames.druid.Thorns = Buffalo:getSpellName(9910); 

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
		--Buffalo.spellnames.mage.ArcaneIntellect		= Buffalo:getSpellName(10157);  
		--Buffalo.spellnames.mage.ArcaneBrilliance	= Buffalo:getSpellName(23028);  
		--Buffalo.spellnames.mage.AmplifyMagic		= Buffalo:getSpellName(10170);
		--Buffalo.spellnames.mage.DampenMagic			= Buffalo:getSpellName(10174);
		--Buffalo.spellnames.mage.MoltenArmor			= Buffalo:getSpellName(30482);
		--Buffalo.spellnames.mage.MageArmor			= Buffalo:getSpellName(22783);
		--Buffalo.spellnames.mage.FrostArmor			= Buffalo:getSpellName(12544);
		--Buffalo.spellnames.mage.IceArmor			= Buffalo:getSpellName(10220);
		--Buffalo.spellnames.mage.IceBarrier			= Buffalo:getSpellName(13033);

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
		--Buffalo.spellnames.priest.PowerWordFortitude		= Buffalo:getSpellName(10938);
		--Buffalo.spellnames.priest.PrayerOfFortitude			= Buffalo:getSpellName(21564);
		--Buffalo.spellnames.priest.DivineSpirit				= Buffalo:getSpellName(27841);
		--Buffalo.spellnames.priest.PrayerOfSpirit			= Buffalo:getSpellName(27681);
		--Buffalo.spellnames.priest.ShadowProtection			= Buffalo:getSpellName(10958);
		--Buffalo.spellnames.priest.PrayerOfShadowProtection	= Buffalo:getSpellName(27683);
		--Buffalo.spellnames.priest.InnerFire					= Buffalo:getSpellName(10952);
		--Buffalo.spellnames.priest.ShadowForm				= Buffalo:getSpellName(15473);

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
		--Buffalo.spellnames.warlock.DemonSkin = Buffalo:getSpellName(696);
		--Buffalo.spellnames.warlock.DemonArmor = Buffalo:getSpellName(11735);
		--Buffalo.spellnames.warlock.FireShield = Buffalo:getSpellName(11771);
		--Buffalo.spellnames.warlock.UnendingBreath = Buffalo:getSpellName(5697);
		--Buffalo.spellnames.warlock.DetectLesserInvisibility = Buffalo:getSpellName(132);
		--Buffalo.spellnames.warlock.DetectInvisibility = Buffalo:getSpellName(2970);
		--Buffalo.spellnames.warlock.DetectGreaterInvisibility = Buffalo:getSpellName(11743);
		--Buffalo.spellnames.warlock.Imp = Buffalo:getSpellName(688);
		--Buffalo.spellnames.warlock.Voidwalker = Buffalo:getSpellName(697);
		--Buffalo.spellnames.warlock.Felhunter = Buffalo:getSpellName(691);
		--Buffalo.spellnames.warlock.Succubus = Buffalo:getSpellName(712);
		--Buffalo.spellnames.warlock.Incubus = Buffalo:getSpellName(713);

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






