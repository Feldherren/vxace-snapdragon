=begin

Snapdragon v1.0, by Feldherren (rpaliwoda@googlemail.com)

Updates:
  v0.1 - it lives! And, importantly, does stuff
  v0.2 - now works from <snapdragon> tag on skills; not items, though
  v0.3 - now requires Effects Manager, but <eff: snapdragon> tag now works for items and skills
  v0.35 - now doesn't crash if you try to use the effect on someone who doesn't have a <snapdragon [weapon/armor]: #> tag
  v0.4 - now supports <snapdragon immune> tag, for when you don't want someone or something to be snapdragonable
  v0.5 - now supports weapon/armor/immune tags on classes
  v1.0 - now complete, though it isn't really different from 0.5; works on actors (in and out of battle) and enemies
  v1.1 - now supports custom inheritance rates for actors, classes and enemies. Also, noticed and fixed a bug regarding armour tags; the arrays for actors and classes got mixed up at some point, there.
  v1.2 - now supports defining icons for resulting items from actors, classes or enemies
  
Requirements: 
	Hime's Instance Items (http://himeworks.com/2014/01/instance-items/)
  Hime's Effects Manager (http://himeworks.com/2012/10/effects-manager/)

'Snapdragon' or 'Snapshot' is a spell from Tactics Ogre that allowed you to convert party members into weapons.
This script allows you to do that in your games; turn units into a specific weapon (or other equippable), inheriting the unit's name and adding a portion of their parameters to the item's base parameters.

Actor/Enemy/Class tags:
	<snapdragon [weapon/armor]: [id]>
    [id] as the ID number of the weapon or armour (as applicable) the unit will be turned into. 
    Unit will not be subject to snapdragon effect if tag is not present.
  <snapdragon immune>
    Prevents snapdragon effect from functioning on actor or members of class
  <snapdragon inherit [mhp/mmp/atk/def/mat/mdf/agi/luk]: [amount]>
    Changes inheritance rate for the specified parameter; amount should be a decimal, with 1.0 indicating the unit's entire HP should be added to the base weapon stats.
  <snapdragon icon: [icon_index]>
    [icon_index] as the index of the icon to use for the resulting weapon or armour.

Skill/Item tags:
  <eff: snapdragon>
    Causes skill or item to apply the snapdragon effect

Resulting equipment takes the appearance, base stats and traits of the indicated weapon, plus name and inherited stats from the sacrificed unit.

If source actor continues to gain levels after being attached to the equipment (in the event they're not removed from the party), equipment stats will not update.

To-do:
  Notebox tags for additional features, so the base weapon doesn't need to have the feature assigned in the database.
    Mostly so we don't need a different sword for every class that has a special feature, like Death Knights adding instant death chance
  Notebox tags for attack animation?
  
This script is free for use in any project, though please add me to the credits and drop me an e-mail if you do use it.
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
  MATCH_ICON = /<snapdragon icon:\s*(\d*)/i
  # could probably be stored in a dictionary or similar with appropriate 
  # /<snapdragon inherit (mhp|mmp|atk|def|mat|mdf|agi|luk):\s*(\d.*)>/i
  MATCH_INHERIT_MHP = /<snapdragon inherit mhp:\s*(\d.*)>/i
  MATCH_INHERIT_MMP = /<snapdragon inherit mmp:\s*(\d.*)>/i
  MATCH_INHERIT_ATK = /<snapdragon inherit atk:\s*(\d.*)>/i
  MATCH_INHERIT_DEF = /<snapdragon inherit def:\s*(\d.*)>/i
  MATCH_INHERIT_MAT = /<snapdragon inherit mat:\s*(\d.*)>/i
  MATCH_INHERIT_MDF = /<snapdragon inherit mdf:\s*(\d.*)>/i
  MATCH_INHERIT_AGI = /<snapdragon inherit agi:\s*(\d.*)>/i
  MATCH_INHERIT_LUK = /<snapdragon inherit luk:\s*(\d.*)>/i
  
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
    
    alias :make_icon_index_snapdragon :make_icon_index
    def make_icon_index(icon_index)
      icon_index = :make_icon_index_snapdragon
      if get_snap_battler.actor?
        icon_index = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_ICON) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_ICON)[1].to_i : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_ICON) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_ICON)[1].to_i : Snapdragon::MATCH_ICON))
      else
        icon_index = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_ICON) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_ICON)[1].to_i : self.icon_index)
      end
      icon_index
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
      # I'd like not to repeat the whole block here, but actors have id when enemies have enemy_id, so I can't just say 'array = $data_actors' or 'array = $data_enemies' based on what the battler is, as I've found out
      # plus I need to deal with classes if there's nothing on an actor, too. This looks ugly...
      # it can probably be done more elegantly, but for now I'm glad it works
      # redo stuff here to work off numbers and loop through an array?
      if get_snap_battler.actor?
        match_inherit_mhp = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MHP) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MHP)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MHP) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MHP)[1].to_f : Snapdragon::INHERIT_MHP))
        match_inherit_mmp = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MMP) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MMP)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MMP) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MMP)[1].to_f : Snapdragon::INHERIT_MMP))
        match_inherit_atk = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_ATK) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_ATK)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_ATK) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_ATK)[1].to_f : Snapdragon::INHERIT_ATK))
        match_inherit_def = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_DEF) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_DEF)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_DEF) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_DEF)[1].to_f : Snapdragon::INHERIT_DEF))
        match_inherit_mat = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MAT) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MAT)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MAT) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MAT)[1].to_f : Snapdragon::INHERIT_MAT))
        match_inherit_mdf = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MDF) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_MDF)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MDF) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_MDF)[1].to_f : Snapdragon::INHERIT_MDF))
        match_inherit_agi = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_AGI) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_AGI)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_AGI) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_AGI)[1].to_f : Snapdragon::INHERIT_AGI))
        match_inherit_luk = ($data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_LUK) ? $data_actors[get_snap_battler.id].note.match(Snapdragon::MATCH_INHERIT_LUK)[1].to_f : ($data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_LUK) ? $data_classes[get_snap_battler.class_id].note.match(Snapdragon::MATCH_INHERIT_LUK)[1].to_f : Snapdragon::INHERIT_LUK))
      else
        match_inherit_mhp = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MHP) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MHP)[1].to_f : Snapdragon::INHERIT_MHP)
        match_inherit_mmp = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MMP) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MMP)[1].to_f : Snapdragon::INHERIT_MMP)
        match_inherit_atk = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_ATK) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_ATK)[1].to_f : Snapdragon::INHERIT_ATK)
        match_inherit_def = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_DEF) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_DEF)[1].to_f : Snapdragon::INHERIT_DEF)
        match_inherit_mat = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MAT) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MAT)[1].to_f : Snapdragon::INHERIT_MAT)
        match_inherit_mdf = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MDF) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_MDF)[1].to_f : Snapdragon::INHERIT_MDF)
        match_inherit_agi = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_AGI) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_AGI)[1].to_f : Snapdragon::INHERIT_AGI)
        match_inherit_luk = ($data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_LUK) ? $data_enemies[get_snap_battler.enemy_id].note.match(Snapdragon::MATCH_INHERIT_LUK)[1].to_f : Snapdragon::INHERIT_LUK)
      end
      params[0] += get_snap_battler.param_base(0) * match_inherit_mhp
      params[1] += get_snap_battler.param_base(1) * match_inherit_mmp
      params[2] += get_snap_battler.param_base(2) * match_inherit_atk
      params[3] += get_snap_battler.param_base(3) * match_inherit_def
      params[4] += get_snap_battler.param_base(4) * match_inherit_mat
      params[5] += get_snap_battler.param_base(5) * match_inherit_mdf
      params[6] += get_snap_battler.param_base(6) * match_inherit_agi
      params[7] += get_snap_battler.param_base(7) * match_inherit_luk
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
      if !match_weapon
        # check class for tags instead
        match_weapon = $data_classes[target.class_id].note.match( Snapdragon::MATCH_WEAPON )
      end
      match_armour = $data_actors[target.id].note.match( Snapdragon::MATCH_ARMOUR )
      if !match_armour
        # check class for tags instead
        match_armour = $data_classes[target.class_id].note.match( Snapdragon::MATCH_ARMOUR )
      end
    elsif target.enemy?
      match_weapon = $data_enemies[target.enemy_id].note.match( Snapdragon::MATCH_WEAPON )
      match_armour = $data_enemies[target.enemy_id].note.match( Snapdragon::MATCH_ARMOUR )
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
      if !match_immune
        #check class for tag
        match_immune = $data_classes[self.class_id].note.match( Snapdragon::MATCH_IMMUNE )
      end
    elsif self.enemy?
      match_immune = $data_enemies[self.enemy_id].note.match( Snapdragon::MATCH_IMMUNE )
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