
Buffalo buffing addon
---------------------

version 0.1.0-alpha1:
* No UI whatsoever (beside the buff button).
* Addon can BUFF for Priest, Mage (untested), Druid and Warlock (untested).
* Assigned groups are hardcoded to 1,2,3 and 4.
* Assigned buffs are assigned to bitmask 0x003. For a priest that is Fortitude and Spirit.
* Addon only supports Raids for the moment.
* Findings after first raid:
	* Distance check is missing
	* "raid40" unitid fix does not work


version 0.1.0-alpha2:
* Slash-handler added
	* Supports Version
* Distance check is missing - fixed
* Independent of Spell ranks
* Independent of spell names (localizations)
* Independent of class names (localizations)


version 0.2.0-alpha1:
* Added: Configuration UI for Raid buffs.
* Added: /buffalo help, show, hide
* Added/fixed persisted settings.


version 0.2.0-alpha2:
* Added: Mutual exclusive buffs are now handled.
* Bugfix: Fixed bug when converting to raid, causing LUA errors en massé!


version 0.3.0-alpha1
* Added: "Selfie" buffs: "Inner Fire", "Mage Armor" etc.
* Added: "Selfie" buffs added to the configuration UI.
* Bugfix: LUA errors when people join raid possibly fixed.
* Bugfix: Range check was not always working.




Backlog:
* 0.4.0:	Ranking of buffs; i.e. 5-player (full group) before 4-player for example
	Need to think this one throug: that are the exact rules?
* x.x.x:	Add window with next 5 expiring buffs?
* x.x.x:	Make a 10% buff warning window?
* x.x.x:	Paladins!




General notes:
--------------

UnitBuff API:
	local name, iconID, count, school, duration, expirationTime, unitCaster = UnitBuff(unitid, b, "RAID|CANCELABLE");
Expiration time is time since last server restart. I am not sure how to get CurrentTime but should be doable.

This can be used to display buff expire times.

