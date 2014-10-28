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
	What if we want one spell to create swords and another to create brooches?
		Skill/item tag is <snapdragon [identifier]>?
			Then <snapdragon [identifier] weapon [id]>
			<snapdragon [identifier] inherit [stat]: [float]>

Class/actor tag:
	<snapdragon inherit atk: 1.0>
	<snapdragon inherit def: 1.0>
	<snapdragon inherit mat: 1.0>
	<snapdragon inherit mdf: 1.0>
	<snapdragon inherit agi: 1.0>
	<snapdragon inherit luk: 1.0>

Resulting equipment takes the appearance, base stats and traits of the indicated weapon, plus name and inherited stats from the sacrificed unit.

=end
module Snapdragon
  # Do not remove
  MATCH_WEAPON = /<snapdragon weapon:\s*(\d*)>/i
  MATCH_ARMOR = /<snapdragon armou*r:\s*(\d*)>/i
  MATCH_INHERIT_ATK = /<snapdragon inherit atk:\s*(\d*.\d*)>/i
  MATCH_INHERIT_DEF = /<snapdragon inherit def:\s*(\d*.\d*)>/i
  MATCH_INHERIT_MAT = /<snapdragon inherit mat:\s*(\d*.\d*)>/i
  MATCH_INHERIT_MDF = /<snapdragon inherit mdf:\s*(\d*.\d*)>/i
  MATCH_INHERIT_AGI = /<snapdragon inherit agi:\s*(\d*.\d*)>/i
  MATCH_INHERIT_LUK = /<snapdragon inherit luk:\s*(\d*.\d*)>/i
end