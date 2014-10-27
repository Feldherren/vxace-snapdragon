=begin

Snapdragon v0.0

Requirements: 
	Hime's Instance Items (http://himeworks.com/2014/01/instance-items/)

Skill or item with tag <snapdragon> applies snapdragon effect when used.
	Also supply script command for it.

Classes (and actors?) have tag:
	<snapdragon weapon [id]>
	<snapdragon armor [id]>
...where [id] is the ID number of the weapon or armor (as applicable) the unit will be turned into


<snapdragon inherit>
atk: 1.0
def: 1.0
mat: 1.0
mdf: 1.0
agi: 1.0
luk: 1.0
</snapdragon inherit>

Resulting equipment takes the appearance, base stats and traits of the indicated weapon, plus name and inherited stats from the sacrificed unit.

=end
module Snapdragon
  # Do not remove
  MATCH_WEAPON = //i
  MATCH_ARMOR = //i
  MATCH_INHERIT = //i
end