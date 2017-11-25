class "Karma"
require 'Eternal Prediction'

local function Ready (spell)
  return Game.CanUseSpell(spell) == 0
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

function Karma:LoadSpells()
  Q = {delay = 0.25, range = 950,speed = 1700, width = 50}
  Qdata = {speed = Q.speed, delay = Q.delay ,range = Q.range}
  Qspell = Prediction:SetSpell(Qdata, TYPE_LINE, true)

end

local intToMode = {
  [0] = "",
  [1] = "Combo",
  [2] = "Harass",
  [3] = "Lasthit",
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
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
      return "Lasthit"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
      return "Flee"
    end
  else
    return GOS.GetMode()
  end
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

function Karma:__init()
  if myHero.charName ~= "Karma" then return end
  if _G.EOWLoaded then
    Orb = 1
  elseif _G.SDK and _G.SDK.Orbwalker then
    Orb = 2
  end
  PrintChat("SimpleKarma loaded")
  self:LoadMenu()
  self:LoadSpells()
  Callback.Add('Tick', function() self:Tick() end)
  Callback.Add('Draw', function() self:Draw() end)
end

function Karma:LoadMenu()
  self.Menu = MenuElement({type = MENU, id = "Karma", name = "SimpleKarma"})

  --[[Combo]]
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
  self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = true})
  self.Menu.Combo:MenuElement({id = "E", name = "Use E", value = true})
  self.Menu.Combo:MenuElement({id = "R", name = "Use R", value = true})
  self.Menu.Combo:MenuElement({id = "WHP", name = "Min Hp for RW In %", value = 25, min = 0, max = 100})

  --[[Draw]]
  self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
  self.Menu.Draw:MenuElement({id = "W", name = "Draw W Range", value = true})
  self.Menu.Draw:MenuElement({id = "Q", name = "Draw Q Range", value = true})
end

function Karma:Combo()
  local target = GetTarget(1200)
  if target == nil then return end

  if self.Menu.Combo.R:Value() and Ready(_R) then

    if self.Menu.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 675 and myHero.health/myHero.maxHealth < self.Menu.Combo.WHP:Value() / 100 then
      EnableOrb(false)
      Control.CastSpell(HK_R) Control.CastSpell(HK_W, target)
      EnableOrb(true)
    end

    if self.Menu.Combo.Q:Value () and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1200
    then
      local pred = Qspell:GetPrediction(target,myHero.pos)
      if pred == nil then return end
      if pred and pred.hitChance >= 0.1 and pred:hCollision() == 0 and pred:mCollision() == 0  then
        Control.CastSpell(HK_R) Control.CastSpell(HK_Q, pred.castPos)
      end
    end
  end

  if self.Menu.Combo.Q:Value () and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= 1200
  then
    local pred = Qspell:GetPrediction(target,myHero.pos)
    if pred == nil then return end
    if pred and pred.hitChance >= 0.1 and pred:hCollision() == 0 and pred:mCollision() == 0  then
      Control.CastSpell(HK_Q, pred.castPos)
    end
  end

  if self.Menu.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 675  then
    EnableOrb(false)
    Control.CastSpell(HK_W, target)
    EnableOrb(true)
  end

  if self.Menu.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= 500  then
    EnableOrb(false)
    Control.CastSpell(HK_E, myHero)
    EnableOrb(true)
  end
end

function Karma:Tick()
  local Mode = GetMode()
  if Mode == "Combo" then
    self:Combo()
  end

end

function Karma:Draw()
  if myHero.dead then return end
  if self.Menu.Draw.Q:Value() then
    Draw.Circle(myHero.pos, 950, 1, Draw.Color(200, 200, 200, 200))
  end
  if self.Menu.Draw.W:Value() then
    Draw.Circle(myHero.pos, 675, 1, Draw.Color(255, 200, 255, 255))
  end
end

function OnLoad()
  Karma()
end
