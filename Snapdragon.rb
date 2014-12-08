=begin

Snapdragon v0.1

Updates:
  v0.1 - it lives! And, importantly, does stuff
  v0.2 - now works from <snapdragon> tag on skills; not items, though

Requirements: 
	Hime's Instance Items (http://himeworks.com/2014/01/instance-items/)
    Place Snapdragon script BELOW this in the material list

Eventually skill or item with tag <snapdragon> applies snapdragon effect when used.
Right now, however, You can use the script command snapdragon(target) to create a snapdragon weapon based on tags in the actor or enemy's notebox

Actors have tag:
	<snapdragon weapon: [id]>
	<snapdragon armor: [id]>
...where [id] is the ID number of the weapon or armor (as applicable) the unit will be turned into

Resulting equipment takes the appearance, base stats and traits of the indicated weapon, plus name and inherited stats from the sacrificed unit.

If source actor continues to gain levels after being attached to the equipment (in the event they're not removed from the party), equipment stats will not update.

To-do:
  Add support for class tags
    Prioritise character tags
  Add support for non-snapdragon-able characters?
    At least prevent removing the character in that case
    <no snapdragon>?
    Also, not snapdragonable if no tags present?
      Currently it just errors and crashes the game
  Allow specification of non-default inheritance rates?
    Have weapon store inheritance rate? Default to the default script values
  Support for removing enemies from combat?
  Tags for items
    <snapdragon> and attached effect
    make_damage_value works for skills, but NOT items, annoyingly
  Usable without additional effect
    Currently it refuses to do anything if the skill doesn't at least restore HP or something, out of battle
=end
module Snapdragon
  # Whether or not to remove actor from party if snapdragon effect is used on them.
  REMOVE_ACTOR = true
  # Whether or not to recover equipment from actors about to be removed. Only useful if REMOVE_ACTOR is true.
  RECOVER_EQUIPMENT = true
  # Default inheritance rates
  INHERIT_MHP = 0.00
  INHERIT_MMP = 0.00
  INHERIT_ATK = 0.5
  INHERIT_DEF = 0.0
  INHERIT_MAT = 0.5
  INHERIT_MDF = 0.0
  INHERIT_AGI = 0.2
  INHERIT_LUK = 0.0
  # Do not remove
  MATCH_WEAPON = /<snapdragon weapon:\s*(\d*)>/i
  MATCH_ARMOUR = /<snapdragon armou*r:\s*(\d*)>/i
  MATCH_SNAPDRAGON = /<snapdragon>/i
end

$imported = {} if $imported.nil?
$imported[:Feld_Snapdragon] = true

module RPG
  class EquipItem < BaseItem  
    def snap_battler=(b)
      @snap_battler = b
      refresh
    end
    
    def get_snap_battler
      @snap_battler
    end
    
    alias :make_name_snapdragon :make_name
    def make_name(name)
      name = :make_name_snapdragon
      name = get_snap_battler.name if self.get_snap_battler
      name
    end
    
    alias :make_params_snapdragon :make_params
    def make_params(params)
      params = make_params_snapdragon(params)
      params = apply_snapdragon_params(params) if self.get_snap_battler
      params
    end
    
    def apply_snapdragon_params(params)
      params[0] += get_snap_battler.param_base(0) * Snapdragon::INHERIT_MHP
      params[1] += get_snap_battler.param_base(1) * Snapdragon::INHERIT_MMP
      params[2] += get_snap_battler.param_base(2) * Snapdragon::INHERIT_ATK
      params[3] += get_snap_battler.param_base(3) * Snapdragon::INHERIT_DEF
      params[4] += get_snap_battler.param_base(4) * Snapdragon::INHERIT_MAT
      params[5] += get_snap_battler.param_base(5) * Snapdragon::INHERIT_MDF
      params[6] += get_snap_battler.param_base(6) * Snapdragon::INHERIT_AGI
      params[7] += get_snap_battler.param_base(7) * Snapdragon::INHERIT_LUK
      params
    end
  end
end
#===============================================================================
# Game_Interpreter
#===============================================================================
class Game_Interpreter
  def snapdragon(target)
    match_weapon = nil
    match_armour = nil
    # get snapdragon equipment from notetags
    if target.actor?
      match_weapon = $data_actors[target.id].note.match( Snapdragon::MATCH_WEAPON )
      match_armour = $data_actors[target.id].note.match( Snapdragon::MATCH_ARMOUR )
    elsif target.enemy?
      match_weapon = $data_enemies[target.id].note.match( Snapdragon::MATCH_WEAPON )
      match_armour = $data_enemies[target.id].note.match( Snapdragon::MATCH_ARMOUR )
    end
    # create copy of snapdragon equipment
    if match_weapon != nil
      #puts "creating weapon " + match_weapon[1]
      equipment = $game_party.get_instance($data_weapons[match_weapon[1].to_i])
    elsif match_armour != nil
      #puts "creating armour " + match_armour[1]
      equipment = $game_party.get_instance($data_armors[match_armour[1].to_i])
    end
    equipment.snap_battler = target.clone
    $game_party.gain_item(equipment, 1)
    # use snap_battler on new equipment to attach target to it
    # remove actor from party if REMOVE_ACTOR is true
    if (target.actor? and Snapdragon::REMOVE_ACTOR)
      if Snapdragon::RECOVER_EQUIPMENT
        $game_actors[target.id].clear_equipments()
      end
      $game_party.remove_actor(target.id)
    end
  end
end

class Game_Battler
  alias :make_damage_value_snapdragon :make_damage_value
  def make_damage_value(user, item)
    make_damage_value_snapdragon(user, item)
    #puts item.class
    match = nil
    if item.class == RPG::Skill
      match = $data_skills[item.id].note.match( Snapdragon::MATCH_SNAPDRAGON )
    elsif item.class == RPG::Item
      #not working. Items don't even go here
      match = puts $data_items[item.id].note.match( Snapdragon::MATCH_SNAPDRAGON )
      puts match
    end
    if match != nil
      if $game_party.in_battle
        $game_troop.interpreter.snapdragon(self)
      else
        $game_map.interpreter.snapdragon(self)
      end
    end
  end
end
#===============================================================================
# End of File
#===============================================================================