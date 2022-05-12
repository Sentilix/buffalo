
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




TODO:
* Define the UI (muhahaa!)
* Handle single buffs (they are ignore for the time being)
* First (simple?) UI up.
* Ranking of buffs; i.e. 5-player (full group) before 4-player for example



General notes:
--------------

UnitBuff API:
	local name, iconID, count, school, duration, expirationTime, unitCaster = UnitBuff(unitid, b, "RAID|CANCELABLE");
Expiration time is time since last server restart. I am not sure how to get CurrentTime but should be doable.
