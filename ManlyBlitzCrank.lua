---------------------------------------------------------------------------------------------------------------------------------------------------
class "BlitzCrank"
require 'Eternal Prediction'
require 'Damagelib'
---------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:__init()
  if myHero.charName ~= "Blitzcrank" then return end

  if _G.EOWLoaded then
    Orb = 1
  elseif _G.SDK and _G.SDK.Orbwalker then
    Orb = 2
  end
  self:LoadSpells()
  self:LoadMenu()
  Callback.Add('Tick', function() self:Tick() end)
  Callback.Add('Draw', function() self:Draw() end)
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:LoadSpells()
  Q = {range = 925, delay = 0.1, speed = 1800, width = 70 }
  Qdata = {speed = Q.speed, delay = Q.delay,range = Q.range }
  Qspell = Prediction:SetSpell(Qdata, TYPE_LINE, true)
end


---------------------------------------------------------------------------------------------------------------------------------------------------
local function Ready (spell)
  return Game.CanUseSpell(spell) == 0
end
---------------------------------------------------------------------------------------------------------------------------------------------------
local function GetTarget(range)
  local target = nil
  if Orb == 1 then
    target = EOW:GetTarget(range)
  elseif Orb == 2 then
    target = _G.SDK.TargetSelector:GetTarget(range)
  elseif Orb == 3 then
    target = GOS:GetTarget(range)
  end
  return target
end
---------------------------------------------------------------------------------------------------------------------------------------------------
local intToMode = {
  [0] = "",
  [1] = "Combo",
  [2] = "Harass",
  [3] = "LastHit",
  [4] = "Clear"
}
---------------------------------------------------------------------------------------------------------------------------------------------------
local function GetMode()
  if Orb == 1 then
    return intToMode[EOW.CurrentMode]
  elseif Orb == 2 then
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
      return "Combo"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
      return "Harass"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
      return "Clear"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
      return "LastHit"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
      return "Flee"
    end
  else
    return GOS.GetMode()
  end
end
---------------------------------------------------------------------------------------------------------------------------------------------------
local function EnableOrb(bool)
  if Orb == 1 then
    EOW:SetMovements(bool)
    EOW:SetAttacks(bool)
  elseif Orb == 2 then
    _G.SDK.Orbwalker:SetMovement(bool)
    _G.SDK.Orbwalker:SetAttack(bool)
  else
    GOS.BlockMovement = not bool
    GOS.BlockAttack = not bool
  end
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function EnemiesAround(pos, range)
  local Count = 0
  for i = 1, Game.HeroCount() do
    local Hero = Game.Hero(i)
    if Hero and Hero.team ~= myHero.team and not Hero.dead and pos:DistanceTo(Hero.pos) <= range then
      Count = Count + 1
    end
  end
  return Count
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function EAround(pos, range)
  for i = 1, Game.HeroCount() do
    local Hero = Game.Hero(i)
    if Hero and Hero.team ~= myHero.team and not Hero.dead and pos:DistanceTo(Hero.pos) <= range then
      return Hero
    end
  end
end
---------------------------------------------------------------------------------------------------------------------------------------------------
local function Rdmg()
  local level = myHero:GetSpellData(_R).level
  return CalcMagicalDamage(myHero, target, (125 + 125 * level + myHero.ap))
end
---------------------------------------------------------------------------------------------------------------------------------------------------
local _EnemyHeroes
function GetEnemyHeroes()
  if _EnemyHeroes then return _EnemyHeroes end
  _EnemyHeroes = {}
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isEnemy then
      table.insert(_EnemyHeroes, unit)
    end
  end
  return _EnemyHeroes
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:LoadMenu()
  self.Menu = MenuElement({type = MENU, id = "BlitzCrank", name = "ManlyBitchCrank"})
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  --[[Combo]]
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
  self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = false})
  self.Menu.Combo:MenuElement({id = "E", name = "Use E", value = true})
  self.Menu.Combo:MenuElement({id = "R", name = "Use R", value = true})
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  --[[Harass]]
  self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  self.Menu.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
  self.Menu.Harass:MenuElement({id = "E", name = "Use E", value = true})
  self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana For Harass", value = 40, min = 0, max = 100})
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  --[[Misc]]
  self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc"})
  self.Menu.Misc:MenuElement({id = "Q", name = "Auto Q", value = true})
  self.Menu.Misc:MenuElement({type = MENU, id = "OnlyQ", name = "Only Q Enabled targets"})
  for i, Enemy in pairs(GetEnemyHeroes()) do
    self.Menu.Misc.OnlyQ:MenuElement({name = Enemy.charName, id = Enemy.networkID, value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/6.24.1/img/champion/"..Enemy.charName..".png"})
  end
  self.Menu.Misc:MenuElement(({id = "Qmax", name = "Max Range for Q", value = 950, min = 50, max = 950}))
  self.Menu.Misc:MenuElement(({id = "Qmin", name = "Min Range for Q", value = 50, min = 50, max = 950}))
  self.Menu.Misc:MenuElement({id = "Qchance", name = "Pred for Q", value = 0.15, min = 0.01, max = 1, step = 0.01})
  self.Menu.Misc:MenuElement({id = "minR", name = "Min enemies hit for R", value = 2, min = 1, max = 5})
  self.Menu.Misc:MenuElement({id = "RKS", name = "R KS?", value = true})
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  --[[Draw]]
  self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
  self.Menu.Draw:MenuElement({id = "Q", name = "Draw Q Range", value = true})
  self.Menu.Draw:MenuElement({id = "R", name = "Draw R Range", value = true})
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:Tick()
  self:Misc()
  local Mode = GetMode()
  if Mode == "Combo" then
    self:Combo()
  elseif Mode == "Harass" then
    self:Harass()
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:Combo()
  local hitchance = self.Menu.Misc.Qchance:Value()
  local target = GetTarget(1200)
  if target == nil then return end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  if self.Menu.Combo.Q:Value() and Ready(_Q) then
    for i,Enemy in pairs(GetEnemyHeroes()) do
      if not Enemy.dead then
        if self.Menu.Misc.OnlyQ[Enemy.networkID]:Value() then
          if myHero.pos:DistanceTo(Enemy.pos)>=self.Menu.Misc.Qmin:Value() and myHero.pos:DistanceTo(Enemy.pos)<=self.Menu.Misc.Qmax:Value()
          then
            local pred = Qspell:GetPrediction(Enemy,myHero.pos)
            if pred == nil then return end
            if pred and pred.hitChance >= hitchance and pred:mCollision() == 0 and pred:hCollision() == 0 then
              EnableOrb(false)
              Control.CastSpell(HK_Q, pred.castPos)
              EnableOrb(true)
            end
          end
        end
      end
    end
  end
  -------------------------------------------------s--------------------------------------------------------------------------------------------------
  if self.Menu.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= myHero.range and myHero.attackData.state == STATE_WINDDOWN then
    Control.CastSpell(HK_E)
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  if self.Menu.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) <= 1000 then
    Control.CastSpell(HK_W)
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  if self.Menu.Combo.R:Value() and Ready(_R) and EnemiesAround(myHero.pos,600) >= self.Menu.Misc.minR:Value() then
    Control.CastSpell(HK_R)
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:Harass()
  local hitchance = self.Menu.Misc.Qchance:Value()
  local target = GetTarget(1200)
  if target == nil then return end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  if self.Menu.Harass.Q:Value() and Ready(_Q)then
    for i,Enemy in pairs(GetEnemyHeroes()) do
      if not Enemy.dead then
        if self.Menu.Misc.OnlyQ[Enemy.networkID]:Value() then
          if myHero.pos:DistanceTo(Enemy.pos)>=self.Menu.Misc.Qmin:Value() and myHero.pos:DistanceTo(Enemy.pos)<=self.Menu.Misc.Qmax:Value()
          then
            local pred = Qspell:GetPrediction(Enemy,myHero.pos)
            if pred == nil then return end
            if pred and pred.hitChance >= hitchance and pred:mCollision() == 0 and pred:hCollision() == 0 then
              EnableOrb(false)
              Control.CastSpell(HK_Q, pred.castPos)
              EnableOrb(true)
            end
          end
        end
      end
    end
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  if self.Menu.Harass.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= myHero.range and myHero.attackData.state == STATE_WINDDOWN then
    Control.CastSpell(HK_E)
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:Misc()
  hitchance = self.Menu.Misc.Qchance:Value()

  if self.Menu.Misc.RKS:Value() and Ready(_R) then
    target = EAround(myHero.pos, 600)
    if target == nil then return end
    if target.health < Rdmg() then 
      Control.CastSpell(HK_R)
    end
    print(Rdmg())
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  if self.Menu.Misc.Q:Value() and Ready(_Q)then
    for i,Enemy in pairs(GetEnemyHeroes()) do
      if not Enemy.dead then
        if self.Menu.Misc.OnlyQ[Enemy.networkID]:Value() then
          if myHero.pos:DistanceTo(Enemy.pos)>=self.Menu.Misc.Qmin:Value() and myHero.pos:DistanceTo(Enemy.pos)<=self.Menu.Misc.Qmax:Value()
          then
            local pred = Qspell:GetPrediction(Enemy,myHero.pos)
            if pred == nil then return end
            if pred and pred.hitChance >= hitchance and pred:mCollision() == 0 and pred:hCollision() == 0 then
              EnableOrb(false)
              Control.CastSpell(HK_Q, pred.castPos)
              EnableOrb(true)
            end
          end
        end
      end
    end
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function BlitzCrank:Draw()
  if myHero.dead then return end
  if self.Menu.Draw.Q:Value() then
    Draw.Circle(myHero.pos, 950, 3,  Draw.Color(255, 000, 222, 255))
  end
  if self.Menu.Draw.R:Value() then
    Draw.Circle(myHero.pos, 600, 3,  Draw.Color(255, 000, 222, 255))
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------
function OnLoad()
  BlitzCrank()
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
