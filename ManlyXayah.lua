class "Xayah"
require 'Eternal Prediction'
require "Collision"

local _shadow = myHero.pos
local feathers={}
local Feather = Collision:SetSpell(math.huge, 1800, 0.2, 40, true)
local time=os.clock()

function Xayah:__init()
  if myHero.charName ~= "Xayah" then return end
  if _G.EOWLoaded then
    Orb = 1
  elseif _G.SDK and _G.SDK.Orbwalker then
    Orb = 2
  end
  self:LoadSpells()
  self:LoadMenu()
  Callback.Add("Tick", function() self:Tick() end)
end

function Xayah:LoadMenu()
  self.Menu = MenuElement({type = MENU, id = "Xayah", name = "ManlyXayah"})

  --Combo
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
  self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
  self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = true})

  --KS
  self.Menu:MenuElement({type = MENU, id = "KS", name = "KS"})
  self.Menu.KS:MenuElement({id = "Q", name = "Use Q ", value = true})
  self.Menu.KS:MenuElement({id = "E", name = "Use E", value = true})

  --Misc
  self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc"})
  self.Menu.Misc:MenuElement({id = "AR", name = "Auto root", value = true})
  self.Menu.Misc:MenuElement({id = "x", name = "Min enemies to root",  value = 2, min = 1, max = 5})
  self.Menu.Misc:MenuElement({id = "R", name = "Auto R", value = true})
  self.Menu.Misc:MenuElement({id = "AAR", name = "R if X enemies hit",  value = 2, min = 1, max = 5})

  self.Menu:MenuElement({type = PARAM, id = "Time", name = "Feather-Refresh Time[?]", value = 0.5,min=0.1,max=1,step=0.1,tooltip="Depends On Your PC's Perfomance"})
end

local function Ready(spell)
  return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
end

local function GetHeroesInFeatherLine(feather)
  if feather then
    local to=Vector(myHero.pos)
    local from=Vector(feather.pos)
    local block, list = Feather:__GetHeroCollision(from, to, 3)
    if block then
      return list
    end
  end
end

local function isHeroInFeatherLine(hero)
  local num=0
  if #feathers>0 and hero.visible then
    for k,feather in pairs(feathers) do
      local list=GetHeroesInFeatherLine(feather)
      if list then
        for k,v in pairs(list) do
          if v==hero then
            num=num+1
          end
        end
      end
    end
  end
  return num
end

local function SetRealFeathers()
  local feathers2={feathers[1]}
  for k,feather in pairs(feathers) do
    local featherPos=Vector(feather.pos)
    local found=false
    for k,feather2 in pairs(feathers2) do
      local feather2Pos=Vector(feather2.pos)
      if featherPos==feather2Pos then
        found=true
      end
    end
    if not found then
      table.insert(feathers2,feather)
    end
  end
  feathers=feathers2
end

local function GetDamage(spell,target)
  local EDamage={50,60,70,80,90}
  if target then
    local line=isHeroInFeatherLine(target)
    if spell==_E and line>0 and Ready(_E) then
      local damage=EDamage[myHero:GetSpellData(_E).level]+(myHero.bonusDamage*0.6)
      damage=damage+(myHero.critChance*0.5)
      local baseDamage=damage
      for i=1,line do
        damage=damage+(baseDamage*0.8)
      end
      return CalcPhysicalDamage(myHero, target, damage)
    end
  end
  return 0
end

function Xayah:AutoRoot()
  local x = self.Menu.Misc.AR:Value()
  if Ready(_E)then
    local heroesToRoot=0
    for i=1,Game.HeroCount() do
      local hero=Game.Hero(i)
      if hero.visible and not hero.dead and hero.isEnemy and not hero.isImmortal then
        if isHeroInFeatherLine(hero)>=3 then
          heroesToRoot=heroesToRoot+1
        end
      end
    end
    if heroesToRoot>= self.Menu.Misc.x:Value()
    then
      Control.CastSpell(HK_E)
    end
  end
end
--

function Xayah:LoadSpells()
  Q = {delay = 0.3, range = 1100,speed = 700, width = 50}
  R = {delay = 1,range = 1100,speed = 2200,coneAngle = 45}
end

local intToMode = {
  [0] = "",
  [1] = "Combo",
  [2] = "Harass",
  [3] = "LastHit",
  [4] = "Clear"
}

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
    end
  else
    return GOS.GetMode()
  end
end

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

local function GetPercentHP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.health/unit.maxHealth
end

local function HpPred(unit, delay)
  if _G.GOS then
    hp =  GOS:HP_Pred(unit,delay)
  else
    hp = unit.health
  end
  return hp
end

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

function Xayah:Combo()
  local target = GetTarget(1100)
  if target == nil then return
  end
  if self.Menu.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 1100 then
    local Qdata = {speed = Q.speed, delay = Q.delay ,range = Q.range}
    local Qspell = Prediction:SetSpell(Qdata, TYPE_LINE, true)
    local pred = Qspell:GetPrediction(target,myHero.pos)
    if pred == nil then return end
    if pred and pred.hitChance >= 0.15 then
      Control.CastSpell(HK_Q, pred.castPos)
    end
  end
  if self.Menu.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < myHero.range then
    Control.CastSpell(HK_W)
  end
end

function Xayah:Misc()
  local target = GetTarget(1100)
  if target == nil then return
  end
  if self.Menu.KS.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 1100 then
    local level = myHero:GetSpellData(_Q).level
    local Qdamage = ({40, 60, 80, 100, 120})[level] * 2 + 0.5 * myHero.bonusDamage
    local Qdata = {speed = Q.speed, delay = Q.delay ,range = Q.range}
    local Qspell = Prediction:SetSpell(Qdata, TYPE_LINE, true)
    local pred = Qspell:GetPrediction(target,myHero.pos)
    if pred == nil then return end
    if pred and pred.hitChance >= 0.15 and Qdamage >= target.health and pred:hCollision() == 0 and pred:mCollision() == 0 then
      Control.CastSpell(HK_Q, pred.castPos)
    elseif pred and pred.hitChance >= 0.15 and Qdamage / 2 >= target.health then
      Control.CastSpell(HK_Q, pred.castPos)
    end
  end
  if self.Menu.Misc.R:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 1100 then PrintChat("1")
    local Rdata = {speed = R.speed, delay = R.delay ,range = R.range, coneAngle = R.coneAngle}
    local Rspell = Prediction:SetSpell(Rdata, TYPE_CONE, true)
    local pred = Rspell:GetPrediction(target,myHero.pos)
    if pred == nil then return end PrintChat("2")
    if pred and pred.hitChance >= 0 and pred:hCollision() >= self.Menu.Misc.AAR:Value() -1 then
      Control.CastSpell(HK_R, pred.castPos)
    end
  end
  if self.Menu.KS.E:Value() and Ready(_E) and GetDamage(_E, target) > target.health then
    Control.CastSpell(HK_E)
  end
end

function Xayah:Tick()
  self:Misc()
  self:AutoRoot()
  local Mode = GetMode()
  if Mode == "Combo" then
    self:Combo()
  end
  if os.clock()-time>self.Menu.Time:Value() then
    feathers={}
    for i=1,Game.ObjectCount() do
      local obj=Game.Object(i)
      if obj.name=="Feather" and obj.owner==myHero and obj.health>0 then
        table.insert(feathers,obj)
      end
      time=os.clock()
    end
    if #feathers>0 then
      SetRealFeathers()
    end
  end
end

function OnLoad()
  Xayah()
end
