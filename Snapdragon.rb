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
			Get snapdragon working in general first.

Class/actor tag:
	<snapdragon inherit atk: 1.0>
	<snapdragon inherit def: 1.0>
	<snapdragon inherit mat: 1.0>
	<snapdragon inherit mdf: 1.0>
	<snapdragon inherit agi: 1.0>
	<snapdragon inherit luk: 1.0>
	
	When not specified, assume 0.0?

Resulting equipment takes the appearance, base stats and traits of the indicated weapon, plus name and inherited stats from the sacrificed unit.

Use snapdragon on unit
Refer to weapon/equipment created by snapdragon
Create instance
Add targeted actor/creature to instance

methods for getting params, name should refer to the actor/creature

=end
module Snapdragon
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
  MATCH_ARMOR = /<snapdragon armou*r:\s*(\d*)>/i
  #MATCH_INHERIT_ATK = /<snapdragon inherit atk:\s*(\d*.\d*)>/i
  #MATCH_INHERIT_DEF = /<snapdragon inherit def:\s*(\d*.\d*)>/i
  #MATCH_INHERIT_MAT = /<snapdragon inherit mat:\s*(\d*.\d*)>/i
  #MATCH_INHERIT_MDF = /<snapdragon inherit mdf:\s*(\d*.\d*)>/i
  #MATCH_INHERIT_AGI = /<snapdragon inherit agi:\s*(\d*.\d*)>/i
  #MATCH_INHERIT_LUK = /<snapdragon inherit luk:\s*(\d*.\d*)>/i
end

$imported = {} if $imported.nil?
$imported[:Feld_Snapdragon] = true

module RPG
  class EquipItem < BaseItem
    #attr_accessor :inherit_atk
    #attr_accessor :inherit_def
    #attr_accessor :inherit_mat
    #attr_accessor :inherit_mdf
    #attr_accessor :inherit_agi
    #attr_accessor :inherit_luk
  
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
      #get_snap_battler.param.size.times do |i|
      #  params[i] += get_snap_battler.params[i] 
      #end
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
# Instance Manager: setup_instance
#===============================================================================

#===============================================================================
# End of File
#===============================================================================