---------------------------------------------------------------------------------------------------------------------------------------------------
class "Khazix"
require('Eternal Prediction')
local evtext = "Auto check will be added later"
---------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------
function Khazix:__init()
	if myHero.charName ~= "Khazix" then return end
	
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
function Khazix:LoadSpells()
  Q = {range = 325}
  QEvolved = {range = 375}
  W = {range = 1100, delay = 0.25, speed = 1700, width = 60 }
  Wdata = {speed = W.speed, delay = W.delay,range = W.range }
  Wspell = Prediction:SetSpell(Wdata, TYPE_LINE, true)
  E = {range = 700, delay = 0.25, speed = 1650, width = 250 }
  EEvolved = {range = 900, delay = 0.25, speed = 1650, width = 250 }
  Edata = {speed = E.speed, delay = E.delay,range = E.range }
  Espell = Prediction:SetSpell(Edata, TYPE_CIRCULAR, true)
  EEvolveddata = {speed = EEvolved.speed, delay = EEvolved.delay,range = EEvolved.range }
  EEvolvedspell = Prediction:SetSpell(EEvolveddata, TYPE_CIRCULAR, true)
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
function Khazix:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Khazix", name = "ManlyKha´Shits - Earyl Beta"})
---------------------------------------------------------------------------------------------------------------------------------------------------
	--[[Combo]]
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  self.Menu.Combo:MenuElement({type = MENU, id = "Q", name = "Q Settings"})
  self.Menu.Combo.Q:MenuElement({id = "Q", name = "Use Q", value = true})
  self.Menu.Combo.Q:MenuElement({id = "QReset", name = "Only Q as auto reset", value = true})

  self.Menu.Combo:MenuElement({type = MENU, id = "W", name = "W Settings"})
  self.Menu.Combo.W:MenuElement({id = "W", name = "Use W", value = true})
  self.Menu.Combo.W:MenuElement(({id = "Wmax", name = "Max Range for W", value = 650, min = 50, max = 1100}))
  self.Menu.Combo.W:MenuElement(({id = "Wmin", name = "Min Range for W", value = 50, min = 50, max = 1100}))
  self.Menu.Combo.W:MenuElement({id = "Wpred", name = "Pred for W", value = 0.15, min = 0.01, max = 1, step = 0.01})

  self.Menu.Combo:MenuElement({type = MENU, id = "E", name = "E Settings"})
  self.Menu.Combo.E:MenuElement({id = "E", name = "Use E", value = true})
  self.Menu.Combo.E:MenuElement(({id = "Emax", name = "Max Range for E", value = 950, min = 50, max = 900}))
  self.Menu.Combo.E:MenuElement(({id = "Emin", name = "Min Range for E", value = 400, min = 50, max = 900}))
  
---------------------------------------------------------------------------------------------------------------------------------------------------
self.Menu:MenuElement({type = MENU, id ="Evolved", name = "Evolved spells"})
self.Menu.Evolved:MenuElement({type = SPACE, id ="i", name = "Enable when evolved"})
self.Menu.Evolved:MenuElement({id = "Q", name = "Q", value = false})
self.Menu.Evolved:MenuElement({id = "W", name = "W (No evolved logic implemented yet)", value = false})
self.Menu.Evolved:MenuElement({id = "E", name = "E", value = false})
self.Menu.Evolved:MenuElement({id = "R", name = "R (No evolved logic implemented yet)", value = false})
self.Menu.Evolved:MenuElement({type = SPACE, id = "ii", name = "AutoCheck will be added in the future"})
---------------------------------------------------------------------------------------------------------------------------------------------------

	--[[Draw]]
	self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
  self.Menu.Draw:MenuElement({id = "Q", name = "Draw Q Range", value = true})
  self.Menu.Draw:MenuElement({id = "W", name = "Draw W Range", value = true})
  self.Menu.Draw:MenuElement({id = "E", name = "Draw E Range", value = true})
---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function Khazix:Tick()
local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	end
---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function Khazix:Combo()
local Qrange
local Erange
local ES
local hitchance = self.Menu.Combo.W.Wpred:Value()
local target = GetTarget(1200)
if target == nil then return end
if self.Menu.Evolved.Q:Value() then Qrange = 375 else Qrange = 325 end
if self.Menu.Evolved.E:Value() then Erange = 900 ES = EEvolvedspell else Erange = 700 ES = Espell end
---------------------------------------------------------------------------------------------------------------------------------------------------
if self.Menu.Combo.Q.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) <= Qrange then
if self.Menu.Combo.Q.QReset:Value() == false then 
Control.CastSpell(HK_Q,target)
elseif myHero.attackData.state == STATE_WINDDOWN then
Control.CastSpell(HK_Q, target)
end
end
---------------------------------------------------------------------------------------------------------------------------------------------------
if self.Menu.Combo.E.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) <= Erange and myHero.pos:DistanceTo(target.pos) <= self.Menu.Combo.E.Emax:Value() and myHero.pos:DistanceTo(target.pos) >= self.Menu.Combo.E.Emin:Value() then
	local pred = ES:GetPrediction(target,myHero.pos)
	if pred == nil then return end
	if pred and pred.hitChance >= 0.1 then
  EnableOrb(false)
Control.CastSpell(HK_E, pred.castPos)
  EnableOrb(true)
end 
end
---------------------------------------------------------------------------------------------------------------------------------------------------
if self.Menu.Combo.W.W:Value() and Ready(_W) and Ready(_E) == false and myHero.pos:DistanceTo(target.pos) <= self.Menu.Combo.W.Wmax:Value() and myHero.pos:DistanceTo(target.pos) >= self.Menu.Combo.W.Wmin:Value() then
	local pred = Wspell:GetPrediction(target,myHero.pos)
	if pred == nil then return end
  if pred and pred.hitChance >= hitchance and myHero.pos:DistanceTo(target.pos) <= 260 then
EnableOrb(false)
Control.CastSpell(HK_W, pred.castPos)
EnableOrb(true)
return end
	if pred and pred.hitChance >= hitchance and pred:mCollision() == 0 and pred:hCollision() == 0 then
  EnableOrb(false)
Control.CastSpell(HK_W, pred.castPos)
EnableOrb(true)
end
end
---------------------------------------------------------------------------------------------------------------------------------------------------
-- if self.Menu.Combo.R:Value() and Ready(_R) and EnemiesAround(myHero.pos,600) >= self.Menu.Misc.minR:Value() then
-- Control.CastSpell(HK_R)
-- end
---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------
function Khazix:Draw()
local Qrange
local Erange
local x = Draw.Color(255, 255, 255, 255)
if myHero.dead then return end
if self.Menu.Evolved.Q:Value() then Qrange = 375 else Qrange = 325 end
if self.Menu.Evolved.E:Value() then Erange = 900 else Erange = 700 end
  if self.Menu.Draw.Q:Value() then
  Draw.Circle(myHero.pos, Qrange, 1,x)
  end
  if self.Menu.Draw.W:Value() then
  Draw.Circle(myHero.pos, 1000, 1,x)
  end
  if self.Menu.Draw.E:Value()  then
  Draw.Circle(myHero.pos, Erange,1,x)
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------
function OnLoad()
	Khazix()
  ---------------------------------------------------------------------------------------------------------------------------------------------------
end
---------------------------------------------------------------------------------------------------------------------------------------------------