Buffalo - Raid buff addon
-------------------------

Buffalo adds a new button for your UI, which will lit up with an icon when someone in your group or raid needs a new buff from you. The assigned groups can be configured, so you can
set up which groups you will monitor and what buffs you will do.

You can move the button by pressing Shift while dragging the icon to a desired position.

Buffalo works for Classic and TBC.


Slash Commands
--------------
Buffalo does not need much setup, so there are only a few commands available:

* /buffalo config - opens the Group/Buff configuration screen. This can also be done by right-clicking the buff button.
* /buffalo hide - hides the Buff button
* /buffalo show - (default) shows the Buff button again (yay!)
* /buffalo version - shows the current version of Buffalo.
* /buffalo announce - write a message locally when a buff is missing.
* /buffalo stopannounce - (default) stop writing missing buffs.

 

Note:
This is a beta version, and there may be bugs. Should you find one, feel free to report it below, together with relevant information, such as:
* What class did you play
* What buff failed
* What realm type (Classic Era, Tbc, WoTLK ...)
* Did you get any errors?

 
 

Not yet implemented:
--------------------
* Paladin buffs are not yet implemented. I hope to make addon 100% compatible with PallyPower,thus exchanging buffs.
* Addon communication to other instances of Buffalo are not implemented.
* WotLK



Hey, that addon reminds me of SmartBuff!
----------------------------------------
It sure does! I have been using SmartBuff for many years, and loved it. But now it seems there isn't a working SmartBuff addon out there.

This addon is not a SmartBuff clone!

Buffalo works differently, and have a stronger focus on party/raid buffing, where SmartBuff worked for everyone - including your Warrior for that Find Herbs buff. Buffalo does not support buffing in combat. This is a limitation implemented by Blizzard, which didn't exist back in the SmartBuff days.



Buff priority:
--------------
ALL			FindHerbs					10
ALL			FindMinerals				10

Druid		Thorns						11
Druid		GiftOfTheWild				52
Druid		MarkOfTheWild				52

Mage		IceBarrier					11
Mage		IceArmor					12
Mage		MageArmor					13
Mage		DampenMagic					51
Mage		AmplifyMagic				52
Mage		ArcaneBrilliance			53
Mage		ArcaneIntellect				53

Priest		InnerFire					11
Priest		PrayerOfShadowProtection	51
Priest		ShadowProtection			51
Priest		PrayerOfSpirit				52
Priest		DivineSpirit				52
Priest		PrayerOfFortitude			53
Priest		PowerWordFortitude			53



Version history
---------------
Version 0.3.0-beta1
* Added: Option to announce next buff in queue (/buffalo announce).
* Bugfix: Init of Buffalo sometimes failed due to WoW still not done caching data, added a delay to fix that.
* Bugfix: Buffalo repeatedly attempted to buff selfie buffs on others.
* Bugfix: The buff scanner did not always pick up missing buffs as it should.
* Bugfix: Addon didnt handle buffs with a cooldown (currently only Ice Barrier).


Version 0.3.0-alpha2
* Added: Raid (non-group) buffs are now visible in selfie UI
* Added: Find Herbs, Find Minerals to selfie UI
* Added: Ice Barrier (frost Mage shield)
* Bugfix: TOC file for TBC was missing configuration file, made Buffalo fail.
* Bugfix: Unlearned spells still pops up for buffing.
* Bugfix: Taking spells on CD into account


version 0.3.0-alpha1
* Added: "Selfie" buffs: "Inner Fire", "Mage Armor" etc.
* Added: "Selfie" buffs added to the configuration UI.
* Bugfix: LUA errors when people join raid possibly fixed.
* Bugfix: Range check was not always working.


version 0.2.0-alpha2:
* Added: Mutual exclusive buffs are now handled.
* Bugfix: Fixed bug when converting to raid, causing LUA errors en massé!


version 0.2.0-alpha1:
* Added: Configuration UI for Raid buffs.
* Added: /buffalo help, show, hide
* Added/fixed persisted settings.


version 0.1.0-alpha2:
* Slash-handler added
	* Supports Version
* Distance check is missing - fixed
* Independent of Spell ranks
* Independent of spell names (localizations)
* Independent of class names (localizations)


version 0.1.0-alpha1:
* No UI whatsoever (beside the buff button).
* Addon can BUFF for Priest, Mage (untested), Druid and Warlock (untested).
* Assigned groups are hardcoded to 1,2,3 and 4.
* Assigned buffs are assigned to bitmask 0x003. For a priest that is Fortitude and Spirit.
* Addon only supports Raids for the moment.
* Findings after first raid:
	* Distance check is missing
	* "raid40" unitid fix does not work





Backlog:
* x.x.x:	Ranking of buffs; i.e. 5-player (full group) before 4-player for example. Need to think this one throug: that are the exact rules?
* x.x.x:	Configure class-level buffs via UI
* x.x.x:	Add window with next 5 expiring buffs?
* x.x.x:	Make a 10% buff warning window?
* x.x.x:	Paladins!


