=begin

Snapdragon v0.1

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
    Defer to
  Add support for non-snapdragon-able characters?
    At least prevent removing the character in that case

=end
module Snapdragon
  # Whether or not to remove actor from party if snapdragon effect is used on them.
  REMOVE_ACTOR = true
  # Inheritance rates
  INHERIT_MHP = 0.01
  INHERIT_MMP = 0.01
  INHERIT_ATK = 0.25
  INHERIT_DEF = 0.20
  INHERIT_MAT = 0.25
  INHERIT_MDF = 0.20
  INHERIT_AGI = 0.10
  INHERIT_LUK = 0.10
  # Do not remove
  MATCH_WEAPON = /<snapdragon weapon:\s*(\d*)>/i
  MATCH_ARMOUR = /<snapdragon armou*r:\s*(\d*)>/i
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
    # get snapdragon equipment from notetags
    match_weapon = nil
    match_armour = nil
    if target.actor?
      match_weapon = $data_actors[target.id].note.match( Snapdragon::MATCH_WEAPON )
      match_armour = $data_actors[target.id].note.match( Snapdragon::MATCH_ARMOUR )
    elsif target.enemy?
      match_weapon = $data_enemies[target.id].note.match( Snapdragon::MATCH_WEAPON )
      match_armour = $data_enemies[target.id].note.match( Snapdragon::MATCH_ARMOUR )
    end
    # create copy of snapdragon equipment
    if match_weapon != nil
      puts "creating weapon " + match_weapon[1]
      equipment = $game_party.get_instance($data_weapons[match_weapon[1].to_i])
    elsif match_armour != nil
      puts "creating armour " + match_armour[1]
      equipment = $game_party.get_instance($data_armors[match_armour[1].to_i])
    end
    equipment.snap_battler = target
    $game_party.gain_item(equipment, 1)
    # use snap_battler on new equipment to attach target to it
    # remove actor from party if REMOVE_ACTOR is true
    if (target.actor? and Snapdragon::REMOVE_ACTOR)
      $game_party.remove_actor(target.id)
    end
  end
end
#===============================================================================
# End of File
#===============================================================================