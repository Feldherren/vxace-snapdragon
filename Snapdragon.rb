=begin

Snapdragon v0.3

Updates:
  v0.1 - it lives! And, importantly, does stuff
  v0.2 - now works from <snapdragon> tag on skills; not items, though
  v0.3 - now requires Effects Manager, but <eff: snapdragon> tag now works for items and skills
  v0.35 - now doesn't crash if you try to use the effect on someone who doesn't have a <snapdragon [weapon/armor]: #> tag
  x0.4 - now supports <snapdragon immune> tag, for when you don't want someone or something to be snapdragonable

Requirements: 
	Hime's Instance Items (http://himeworks.com/2014/01/instance-items/)
  Hime's Effects Manager (http://himeworks.com/2012/10/effects-manager/)

'Snapdragon' or 'Snapshot' is a spell from Tactics Ogre that allowed you to convert party members into weapons.
This script allows you to do that in your games; turn units into a specific weapon (or other equippable), inheriting the unit's name and adding a portion of their parameters to the item's base parameters.

Actor tags:
	<snapdragon [weapon/armor]: [id]>
    [id] as the ID number of the weapon or armor (as applicable) the unit will be turned into. 
    Unit will not be subject to snapdragon effect if tag is not present.
  <snapdragon immune>
    Prevents snapdragon effect from functioning on actor

Skill/Item tags:
  <eff: snapdragon>
    Causes skill or item to apply the snapdragon effect

Resulting equipment takes the appearance, base stats and traits of the indicated weapon, plus name and inherited stats from the sacrificed unit.

If source actor continues to gain levels after being attached to the equipment (in the event they're not removed from the party), equipment stats will not update.

To-do:
  Add support for class tags
    Prioritise actor/enemy tags, if present
  Allow specification of non-default inheritance rates?
    Have weapon store inheritance rate? Default to the default script values
  Support for removing enemies from combat?
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
  MATCH_IMMUNE = /<snapdragon immune>/i
  
  Effect_Manager.register_effect(:snapdragon)
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
    # check something matched
    if match_weapon or match_armour
      # create copy of snapdragon equipment
      if match_weapon
        #puts "creating weapon " + match_weapon[1]
        equipment = $game_party.get_instance($data_weapons[match_weapon[1].to_i])
      elsif match_armour
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
end
#===============================================================================
# Effects Manager stuff
#===============================================================================
module RPG
  class UsableItem
    def add_effect_snapdragon(code, data_id, args)
      args[0] = args[0].to_i
      add_effect(code, data_id, args)
    end 
  end
end

class Game_Battler
  def item_effect_snapdragon(user, item, effect)
    # stub
  end
end

class Game_Battler
  def item_effect_snapdragon(user, item, effect)
    match_immune = nil
    # check if immune
    if self.actor?
      match_immune = $data_actors[self.id].note.match( Snapdragon::MATCH_IMMUNE )
    elsif self.enemy?
      match_immune = $data_enemies[self.id].note.match( Snapdragon::MATCH_IMMUNE )
    end
    if !match_immune
      if $game_party.in_battle
        $game_troop.interpreter.snapdragon(self)
      else
        $game_map.interpreter.snapdragon(self)
      end
      @result.success = true
    else
      @result.success = false
    end
  end
end
#===============================================================================
# End of File
#===============================================================================