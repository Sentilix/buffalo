
--	Base matrix object placeholders:
BUFFALO_BUFF_MATRIX_CLASSIC = { };
BUFFALO_BUFF_MATRIX_TBC = { };

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
function Buffalo_InitializeBuffClasses()

	BUFFALO_BUFF_Druid_MarkOfTheWild_Name = Buffalo_GetSpellName(9885); 
	BUFFALO_BUFF_Druid_MarkOfTheWild = {
		["BITMASK"]		= 0x0001,
		["ICONID"]		= 136078,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Druid_MarkOfTheWild_Name);
		["PRIORITY"]	= 50,
		["GROUP"]		= false,
		["PARENT"]		= "Gift of the Wild"
	};

	BUFFALO_BUFF_Druid_GiftOfTheWild_Name = Buffalo_GetSpellName(21850); 
	BUFFALO_BUFF_Druid_GiftOfTheWild = {
		["BITMASK"]		= 0x0001,
		["ICONID"]		= 136038,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Druid_GiftOfTheWild_Name);
		["PRIORITY"]	= 100,
		["GROUP"]		= true
	};

	BUFFALO_BUFF_Druid_Thorns_Name = Buffalo_GetSpellName(9910); 
	BUFFALO_BUFF_Druid_Thorns = {
		["BITMASK"]		= 0x0002,
		["ICONID"]		= 136104,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Druid_Thorns_Name);
		["PRIORITY"]	= 40,
		["GROUP"]		= false
	};

	

	BUFFALO_BUFF_Mage_ArcaneIntellect_Name = Buffalo_GetSpellName(10157);  
	BUFFALO_BUFF_Mage_ArcaneIntellect = {
		["BITMASK"]		= 0x0001,
		["ICONID"]		= 135932,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_ArcaneIntellect_Name);
		["PRIORITY"]	= 50,
		["GROUP"]		= false,
		["PARENT"]		= "Arcane Brilliance"
	};

	BUFFALO_BUFF_Mage_ArcaneBrilliance_Name = Buffalo_GetSpellName(23028);  
	BUFFALO_BUFF_Mage_ArcaneBrilliance = {
		["BITMASK"]		= 0x0001,
		["ICONID"]		= 135869,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_ArcaneBrilliance_Name);
		["PRIORITY"]	= 100,
		["GROUP"]		= true
	};

	BUFFALO_BUFF_Mage_AmplifyMagic_Name = Buffalo_GetSpellName(10170);
	BUFFALO_BUFF_Mage_AmplifyMagic = {
		["BITMASK"]		= 0x0002,
		["ICONID"]		= 135907,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_AmplifyMagic_Name);
		["PRIORITY"]	= 40,
		["GROUP"]		= false
	};

	BUFFALO_BUFF_Mage_DampenMagic_Name = Buffalo_GetSpellName(10174);
	BUFFALO_BUFF_Mage_DampenMagic = {
		["BITMASK"]		= 0x0004,
		["ICONID"]		= 136006,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_DampenMagic_Name);
		["PRIORITY"]	= 30,
		["GROUP"]		= false
	};

	BUFFALO_BUFF_Mage_MageArmor_Name = Buffalo_GetSpellName(22783);
	BUFFALO_BUFF_Mage_MageArmor = {
		["BITMASK"]		= 0x0100,
		["ICONID"]		= 135991,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_MageArmor_Name);
		["PRIORITY"]	= 20,
		["GROUP"]		= false
	};

	BUFFALO_BUFF_Mage_IceArmor_Name = Buffalo_GetSpellName(10220);
	BUFFALO_BUFF_Mage_IceArmor = {
		["BITMASK"]		= 0x0200,
		["ICONID"]		= 135843,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Mage_IceArmor_Name);
		["PRIORITY"]	= 10,
		["GROUP"]		= false
	};

	
	
	BUFFALO_BUFF_Priest_PowerWordFortitude_Name = Buffalo_GetSpellName(10938);
	BUFFALO_BUFF_Priest_PowerWordFortitude = { 
		["BITMASK"]		= 0x0001, 
		["ICONID"]		= 135987, 
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PowerWordFortitude_Name);
		["PRIORITY"]	= 40, 
		["GROUP"]		= false, 
		["PARENT"]		= "Prayer of Fortitude" 
	};
	
	BUFFALO_BUFF_Priest_PrayerOfFortitude_Name = Buffalo_GetSpellName(21564);
	BUFFALO_BUFF_Priest_PrayerOfFortitude = {
		["BITMASK"]		= 0x0001, 
		["ICONID"]		= 135941, 
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PrayerOfFortitude_Name);
		["PRIORITY"]	= 100, 
		["GROUP"]		= true 
	};

	BUFFALO_BUFF_Priest_DivineSpirit_Name = Buffalo_GetSpellName(27841);
	BUFFALO_BUFF_Priest_DivineSpirit = {
		["BITMASK"]		= 0x0002, 
		["ICONID"]		= 135898, 
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_DivineSpirit_Name);
		["PRIORITY"]	= 30, 
		["GROUP"]		= false, 
		["PARENT"]		= "Prayer of Spirit"
	};

	BUFFALO_BUFF_Priest_PrayerOfSpirit_Name = Buffalo_GetSpellName(27681);
	BUFFALO_BUFF_Priest_PrayerOfSpirit = {
		["BITMASK"]		= 0x0002, 
		["ICONID"]		= 135946,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PrayerOfSpirit_Name);
		["PRIORITY"]	= 90,
		["GROUP"]		= true 
	};

	BUFFALO_BUFF_Priest_ShadowProtection_Name = Buffalo_GetSpellName(10958);
	BUFFALO_BUFF_Priest_ShadowProtection = {
		["BITMASK"]		= 0x0004,
		["ICONID"]		= 136121,
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_ShadowProtection_Name);
		["PRIORITY"]	= 20,
		["GROUP"]		= false,
		["PARENT"]		= "Prayer of Shadow Protection" 
	};
	
	BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name = Buffalo_GetSpellName(27683);
	BUFFALO_BUFF_Priest_PrayerOfShadowProtection = {
		["BITMASK"]		= 0x0004, 
		["ICONID"]		= 135945, 
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name);
		["PRIORITY"]	= 80, 
		["GROUP"]		= true 
	};

	BUFFALO_BUFF_Priest_InnerFire_Name = Buffalo_GetSpellName(10952);
	BUFFALO_BUFF_Priest_InnerFire = {
		["BITMASK"]		= 0x0100, 
		["ICONID"]		= 135926, 
		["SPELLID"]		= Buffalo_GetSpellID(BUFFALO_BUFF_Priest_InnerFire_Name);
		["PRIORITY"]	= 10, 
		["GROUP"]		= false 
	};
end;

function Buffalo_InitializeBuffMatrix()
	--	Classic setup:
	BUFFALO_BUFF_MATRIX_CLASSIC = {
		["DRUID"] = {
			[BUFFALO_BUFF_Druid_MarkOfTheWild_Name]				= BUFFALO_BUFF_Druid_MarkOfTheWild,
			[BUFFALO_BUFF_Druid_GiftOfTheWild_Name]				= BUFFALO_BUFF_Druid_GiftOfTheWild,
			[BUFFALO_BUFF_Druid_Thorns_Name]					= BUFFALO_BUFF_Druid_Thorns,
		},
		["MAGE"] = {
			[BUFFALO_BUFF_Mage_ArcaneIntellect_Name]			= BUFFALO_BUFF_Mage_ArcaneIntellect,
			[BUFFALO_BUFF_Mage_ArcaneBrilliance_Name]			= BUFFALO_BUFF_Mage_ArcaneBrilliance,
			[BUFFALO_BUFF_Mage_AmplifyMagic_Name]				= BUFFALO_BUFF_Mage_AmplifyMagic,
			[BUFFALO_BUFF_Mage_DampenMagic_Name]				= BUFFALO_BUFF_Mage_DampenMagic,
			[BUFFALO_BUFF_Mage_MageArmor_Name]					= BUFFALO_BUFF_Mage_MageArmor,
			[BUFFALO_BUFF_Mage_IceArmor_Name]					= BUFFALO_BUFF_Mage_IceArmor,
		},
		["PRIEST"] =  {
			[BUFFALO_BUFF_Priest_PowerWordFortitude_Name]		= BUFFALO_BUFF_Priest_PowerWordFortitude,		
			[BUFFALO_BUFF_Priest_PrayerOfFortitude_Name]		= BUFFALO_BUFF_Priest_PrayerOfFortitude,
			[BUFFALO_BUFF_Priest_DivineSpirit_Name]				= BUFFALO_BUFF_Priest_DivineSpirit,
			[BUFFALO_BUFF_Priest_PrayerOfSpirit_Name]			= BUFFALO_BUFF_Priest_PrayerOfSpirit,
			[BUFFALO_BUFF_Priest_ShadowProtection_Name]			= BUFFALO_BUFF_Priest_ShadowProtection,
			[BUFFALO_BUFF_Priest_PrayerOfShadowProtection_Name]	= BUFFALO_BUFF_Priest_PrayerOfShadowProtection,
			[BUFFALO_BUFF_Priest_InnerFire_Name]				= BUFFALO_BUFF_Priest_InnerFire,
		},
	};

	--	TBC setup, not officially supported (yet), wotlk is probably out before addon is ready!
	BUFFALO_BUFF_MATRIX_TBC = BUFFALO_BUFF_MATRIX_CLASSIC;
end;



