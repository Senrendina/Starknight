require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

SpearCharge = WeaponAbility:new()

function SpearCharge:init()
  SpearCharge:reset()

  self.cooldownTimer = 0
end

function SpearCharge:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.cooldownTimer == 0 and not self.weapon.currentAbility and not status.resourceLocked("energy") and self.fireMode == "alt" then
    self:setState(self.windup)
  end
end

function SpearCharge:windup()
  self.weapon:setStance(self.stances.windup)

  animator.setAnimationState("bladeCharge", "charge")
  animator.setParticleEmitterActive("bladeCharge", true)

  local chargeTimer = self.chargeTime
  while self.fireMode == "alt" do
    chargeTimer = math.max(0, chargeTimer - self.dt)
    if chargeTimer == 0 and self.flipCharge then
	  animator.setGlobalTag("bladeDirectives", "flipx")
    end
    coroutine.yield()
  end

  if chargeTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.slash)
  end
end

function SpearCharge:slash()
  self.weapon:setStance(self.stances.slash)
  self.weapon:updateAim()

  animator.setAnimationState("bladeCharge", "idle")
  animator.setParticleEmitterActive("bladeCharge", false)
  animator.setAnimationState("stabSwoosh", "fire", true)
  animator.playSound("chargedSwing")

  util.wait(self.stances.slash.duration, function()
    local damageArea = partDamageArea("stabSwoosh")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)
  
  animator.setGlobalTag("bladeDirectives", "")

  self.cooldownTimer = self.cooldownTime
end

function SpearCharge:reset()
  animator.setGlobalTag("bladeDirectives", "")
  animator.setParticleEmitterActive("bladeCharge", false)
  animator.setAnimationState("bladeCharge", "idle")
end

function SpearCharge:uninit()
  self:reset()
end