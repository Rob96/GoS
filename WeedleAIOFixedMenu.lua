local KoreanChamps = {"Ezreal", "Zed", "Ahri", "Blitzcrank", "Caitlyn", "Brand", "Ziggs", "Morgana", "Syndra", "KogMaw", "Lux", "Cassiopeia", "Karma", "Orianna", "Ryze", "Jhin", "Jayce", "Kennen", "Thresh", "Amumu", "Elise", "Zilean", "Corki", "Sivir", "Aatrox", "Jinx", "Warwick", "Twitch", "Skarner", "Soraka", "Veigar", "Rengar", "Nami", "Lissandra", "LeeSin", "Bard", "Ashe", "Annie", "TwistedFate", "DrMundo", "Xerath", "Ivern", "Karthus", "Leblanc"}
if not table.contains(KoreanChamps, myHero.charName)  then print("" ..myHero.charName.. " Is Not (Yet) Supported") return end

local function Ready(spell)
  return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local KoreanMechanics = MenuElement({type = MENU, id = "KoreanMechanics", name = "WeedleAIO"})
KoreanMechanics:MenuElement({id = "Hold", name = "Hold Enable Key", key = string.byte(" ")})
KoreanMechanics:MenuElement({id = "Enabled", name = "Toggle Enable Key", key = string.byte("M"), toggle = true})
KoreanMechanics:MenuElement({type = MENU, id = "Spell", name = "Spell Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
  KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
  KoreanMechanics.Draw:MenuElement({id = "OFFDRAW", name = "Draw text when Off", value = true}) 
KoreanMechanics:MenuElement({type = SPACE, name = "Version 0.34 by Weedle and Sofie"})    


local _AllyHeroes
local function GetAllyHeroes()
  if _AllyHeroes then return _AllyHeroes end
  _AllyHeroes = {}
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isAlly then
      table.insert(_AllyHeroes, unit)
    end
  end
  return _AllyHeroes
end

local _EnemyHeroes
local function GetEnemyHeroes()
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

local function GetPercentHP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.health/unit.maxHealth
end

local function GetPercentMP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.mana/unit.maxMana
end

local function GetBuffData(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff
    end
  end
  return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
end

local function IsImmobileTarget(unit)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
      return true
    end
  end
  return false  
end

function IsValidTarget(unit, range, onScreen)
    local range = range or 20000  
    return unit and unit.distance <= range and not unit.dead and unit.valid and unit.visible and unit.isTargetable and not (onScreen and not unit.pos2D.onScreen)
end

local function GetBuffs(unit)
  local t = {}
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.count > 0 then
      table.insert(t, buff)
    end
  end
  return t
end

function HasBuff(unit, buffname)
  for K, Buff in pairs(GetBuffs(unit)) do
    if Buff.name:lower() == buffname:lower() then
      return true
    end
  end
  return false
end

function EnemiesAround(pos, range)
  local Count = 0
  for i = 1, Game.HeroCount() do
    local e = Game.Hero(i)
    if e and e.team ~= myHero.team and not e.dead and e.distance <= range then
      Count = Count + 1
    end
  end
  return Count
end

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
  return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
  return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

local _OnVision = {}
function OnVision(unit)
  if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
  if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
  if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
  return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
  if GetTickCount() - visionTick > 100 then
    for i,v in pairs(GetEnemyHeroes()) do
      OnVision(v)
    end
  end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
  if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
  if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
    -- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
    _OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
      DelayAction(function()
        local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
        local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
        if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
          _OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
          -- print("OnDash: "..unit.charName)
        end
      end,0.05)
  end
  return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay)
  if unit == nil then return end
  local speed = speed or math.huge
  local delay = delay or 0.25
  local unitSpeed = unit.ms
  if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
  if OnVision(unit).state == false then
    local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
    local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
    if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
    return predPos
  else
    if unitSpeed > unit.ms then
      local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
      if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
      return predPos
    elseif IsImmobileTarget(unit) then
      return unit.pos
    else
      return unit:GetPrediction(speed,delay)
    end
  end
end

local isCasting = 0 
function KoreanCast(key, pos)
local Cursor = mousePos
    if pos == nil or isCasting == 1 then return end
    isCasting = 1
        Control.SetCursorPos(pos)
        DelayAction(function()
          if Control.IsKeyDown(key) == false then
           Control.SetCursorPos(Cursor)
          end
        DelayAction(function()
         isCasting = 0
        end, 0.002)
        end, (KoreanMechanics.delay:Value() + Game.Latency()) / 1000)
end 


class "Ezreal"

function Ezreal:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Ezreal Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Ezreal:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  ----KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ezreal:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end 
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end 
end

function Ezreal:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end  
  local pos = GetPred(target, 1400, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end

function Ezreal:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1100) 
if target == nil then return end    
  local pos = GetPred(target, 1200, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_W, pos)
end
end

function Ezreal:R() 
  if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
  if targety == nil then return end   
  local pos = GetPred(targety, 2000, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_R, pos)
end
end

function Ezreal:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end   
      end   
  end
end

class "Zed"

function Zed:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Zed Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Zed:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  ----KoreanMechanics.Spell:MenuElement({id = "QR", name = "Max Q Combo Range", value = 1600, min = 0, max = 1600, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Zed:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end   
  end
end 

function Zed:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1100, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end

function Zed:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end  
  Control.CastSpell(HK_R, target.pos)
end
end 

function Zed:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      end   
  end
end

class "Ahri"

function Ahri:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Ahri Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Ahri:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  ----KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 875, min = 0, max = 875, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  ----KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 950, min = 0, max = 950, step = 10})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ahri:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
  end
end

function Ahri:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end  
  local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Ahri:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end  
  local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end 

function Ahri:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
          Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "Blitzcrank"

function Blitzcrank:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Blitzcrank Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Blitzcrank:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  ----KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 925, min = 0, max = 925, step = 10})
  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})

    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end 

function Blitzcrank:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
  end
end 

function Blitzcrank:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end  
  local pos = GetPred(target, 1800, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end

function Blitzcrank:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      end   
  end
end   

class "Caitlyn"

function Caitlyn:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Caitlyn Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Caitlyn:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  ----KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1250, min = 0, max = 1250, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  ----KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})     

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Caitlyn:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end
end

function Caitlyn:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1350)
if target == nil then return end  
  local pos = GetPred(target, 2200, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Caitlyn:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end  
  local pos = GetPred(target, 2000, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end 

function Caitlyn:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(3000)
if target == nil then return end  
  Control.CastSpell(HK_R, target.pos)
end
end   

function Caitlyn:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "Brand"

function Brand:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Brand Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Brand:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  ----KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  ----KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})     

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Brand:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end 
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end       
  end
end

function Brand:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1150)
if target == nil then return end  
  local pos = GetPred(target, 1400, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end   

function Brand:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1000) 
if target == nil then return end    
  local pos = GetPred(target, math.huge, 0.625 + Game.Latency()/1000)
  Control.CastSpell(HK_W, pos)
end
end 

function Brand:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(750)  
if target == nil then return end    
  Control.CastSpell(HK_E, target.pos)
end
end 

function Brand:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
if target == nil then return end  
  Control.CastSpell(HK_R, target.pos)
end
end   

function Brand:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end       
      end   
  end
end

class "Ziggs"

function Ziggs:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Ziggs Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Ziggs:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 850, min = 0, max = 850, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1000, min = 0, max = 1000, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 900, min = 0, max = 900, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")}) 

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ziggs:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end 
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end 
  end
end

function Ziggs:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Ziggs:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end 

function Ziggs:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end 

function Ziggs:R()
  if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
  if targety == nil then return end   
  local pos = GetPred(targety, 1750, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_R, pos)
end
end

function Ziggs:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end       
      end   
  end
end

class "Morgana"

function Morgana:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Morgana Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Morgana:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1300, min = 0, max = 1300, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 900, min = 0, max = 900, step = 10})  

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Morgana:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
  end
end

function Morgana:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1400)
if target == nil then return end  
  local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Morgana:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end  
  local pos = GetPred(target, math.huge, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end 

function Morgana:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
      end   
  end
end

class "Syndra"

function Syndra:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Syndra Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Syndra:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 800, min = 0, max = 800, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 925, min = 0, max = 925, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 650, min = 0, max = 650, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})     

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end

function Syndra:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() and myHero:GetSpellData(_W).name == "SyndraWCast" then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end   
  end
end

function Syndra:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end  
  local pos = GetPred(target, 1750, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end 

function Syndra:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end  
  local pos = GetPred(target, 1450, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end   

function Syndra:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end  
  local pos = GetPred(target, 902, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end 

function Syndra:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(845)
if target == nil then return end  
  Control.CastSpell(HK_R, target.pos)
end
end   

function Syndra:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "KogMaw"

function KogMaw:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Kog'Maw Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function KogMaw:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1175, min = 0, max = 1175, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1200, min = 0, max = 1200, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")}) 

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function KogMaw:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end
end

function KogMaw:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function KogMaw:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 100, (0.33 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end 

function KogMaw:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(1900)
if target == nil then return end  
  local pos = GetPred(target, math.huge, 1 + (Game.Latency()/1000))
  Control.CastSpell(HK_R, pos)
end
end 

local function GetRlvl()
local lvl = myHero:GetSpellData(_R).level
  if lvl >= 1 then
    return (lvl + 1)
elseif lvl == nil then return 1
  end
end

function KogMaw:GetKogRange()
local level = GetRlvl()
  if level == nil then return 1
  end
local Range = (({0, 1200, 1500, 1800})[level])
  return Range 
end

function KogMaw:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, KogMaw:GetKogRange() , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end       
      end   
  end
end

class "Lux"

function Lux:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Lux Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Lux:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1175, min = 0, max = 1175, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")}) 
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1200, min = 0, max = 1200, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Lux:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end   
    if KoreanMechanics.Spell.E:Value() and myHero:GetSpellData(_E).name == "LuxLightStrikeKugel" then
      self:E()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end
end

function Lux:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Lux:W()
  if Ready(_W) then
local Heroes = nil
  for i = 1, Game.HeroCount() do
  local Heroes = Game.Hero(i)
    if Heroes.distance < 1000 and Heroes.isAlly and not Heroes.dead and Heroes.charName ~= "Lux" then
      local pos = GetPred(Heroes, 1400, (0.25 + Game.Latency())/1000)
      Control.CastSpell(HK_W, pos)
    end
  end
end
end

function Lux:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1300, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end 

function Lux:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(3440)
if target == nil then return end  
  local pos = GetPred(target, 3000, 1 + (Game.Latency()/1000))
  Control.CastSpell(HK_R, pos)
end
end 

function Lux:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.CircleMinimap(myHero.pos, RRange , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end       
      end   
  end
end

class "Cassiopeia"

function Cassiopeia:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Cassiopeia Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Cassiopeia:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 850, min = 0, max = 850, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 800, min = 0, max = 800, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")}) 
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Cassiopeia:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end   
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end
end

function Cassiopeia:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(950)
if target == nil then return end  
  local pos = GetPred(target, math.huge, 0.41 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end 

function Cassiopeia:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(900)
if target == nil then return end  
  local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end   

function Cassiopeia:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end  
  Control.CastSpell(HK_E, target)
end
end   

function Cassiopeia:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end  
  local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_R, pos)
end
end     

function Cassiopeia:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, RRange , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end       
      end   
  end
end

class "Karma"

function Karma:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Karma Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Karma:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})   
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  KoreanMechanics.Spell:MenuElement({id = "EMode", name = "self E Toggle", key = string.byte("T"), toggle = true})  

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
end

function Karma:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end     
  end
end

function Karma:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end  
  local pos = GetPred(target, math.huge, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Karma:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(775)
if target == nil then return end  
  Control.CastSpell(HK_W, target)
end
end

function Karma:E()
  if Ready(_E) then
  if KoreanMechanics.Spell.EMode:Value() then
    Control.CastSpell(HK_E, myHero)
  end
  Control.CastSpell(HK_E, mousePos)
end
end

function Karma:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end
      if KoreanMechanics.Spell.EMode:Value() then
        Draw.Text("Self Shield ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))     
      end
      if not KoreanMechanics.Spell.EMode:Value()  then 
        Draw.Text("Self Shield OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end        
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end     
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end       
    end
  end
end

class "Orianna"

function Orianna:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Orianna Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Orianna:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1225, min = 0, max = 1225, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")}) 
  KoreanMechanics.Spell:MenuElement({id = "EMode", name = "self E Toggle", key = string.byte("T"), toggle = true})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Max Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Orianna:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
  end
end

function Orianna:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1225)
if target == nil then return end  
  local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Orianna:E()
if Ready(_E) then
  if KoreanMechanics.Spell.EMode:Value() then
    Control.CastSpell(HK_E, myHero)
  end
end
end   

function Orianna:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Spell.EMode:Value() then
        Draw.Text("Self E ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Spell.EMode:Value()  then 
        Draw.Text("Self E OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end         
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
    end
  end
end

class "Ryze"

function Ryze:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Ryze Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Ryze:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1000, min = 0, max = 1000, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 615, min = 0, max = 615, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")}) 
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 615, min = 0, max = 615, step = 10})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Ryze:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end 
  end
end

function Ryze:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end  
  local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Ryze:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end  
  Control.CastSpell(HK_W, pos)
end
end 

function Ryze:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end  
  Control.CastSpell(HK_E, target)
end
end 

function Ryze:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end       
      end   
  end
end

class "Jhin"

function Jhin:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Jhin Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Jhin:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 2500, min = 0, max = 600, step = 10})   
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})   
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})   
end

function Jhin:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end       
  end
end

function Jhin:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end  
  Control.CastSpell(HK_Q, target)
end
end   

function Jhin:W()
  if Ready(_W) then 
local target =  _G.SDK.TargetSelector:GetTarget(2600)
if target == nil then return end  
  local pos = GetPred(target, 5000, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_W, pos)
end
end 

function Jhin:R()
  if Ready(_R) or myHero:GetSpellData(_R).name == "JhinRShot" then
local target =  _G.SDK.TargetSelector:GetTarget(3100)
if target == nil then return end  
  local pos = GetPred(target, 1200, 1 + (Game.Latency()/1000))
  Control.CastSpell(HK_R, pos)
end
end 

function Jhin:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, 600, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circleminimap(myHero.pos, 3000 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end               
      end   
  end
end

class "Jayce"

function Jayce:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Jayce Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Jayce:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Max Range", value = 1600, min = 0, max = 1600, step = 10})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Jayce:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "JayceShockBlast" then
      self:Q()
    end
  end
end

function Jayce:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end  
  local pos = GetPred(target, 1382, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Jayce:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
    end
  end
end

class "Kennen"

function Kennen:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Kennen Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Kennen:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 10})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Kennen:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
  end
end

function Kennen:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end  
  local pos = GetPred(target, 1700, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end 

function Kennen:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
    end
  end
end

class "Thresh"

function Thresh:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Thresh Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Thresh:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1050, min = 0, max = 1050, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")}) 
  KoreanMechanics.Spell:MenuElement({id = "EMode", name = "E Pull Toggle", key = string.byte("T"), toggle = true})  

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Thresh:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "ThreshQ" then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end   
  end
end

function Thresh:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1500)
if target == nil then return end  
  local pos = GetPred(target, 1900, 0.5 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end 

function Thresh:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(600)
if target == nil then return end 
  local pos = GetPred(target, 2000, 0.25 + (0.25 + Game.Latency())/1000)
  if KoreanMechanics.Spell.EMode:Value() then
    local pos2 = Vector(myHero.pos) + (Vector(myHero.pos) - Vector(pos)):Normalized()*400
        Control.CastSpell(HK_E, pos2)
  end
  Control.CastSpell(HK_E, pos)
end
end

function Thresh:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end
      if KoreanMechanics.Spell.EMode:Value() then
        Draw.Text("E Pull Mode ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))     
      end
      if not KoreanMechanics.Spell.EMode:Value()  then 
        Draw.Text("U Pull Mode OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end        
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
    end
  end
end

class "Amumu"

function Amumu:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Amumu Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Amumu:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1100, min = 0, max = 1100, step = 10})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Amumu:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
  end
end

function Amumu:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1200)
if target == nil then return end  
  local pos = GetPred(target, 2000, 0.15 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end 

function Amumu:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
    end
  end
end

class "Elise"

function Elise:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Elise Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Elise:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "max Q Range", value = 625, min = 0, max = 625, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 950, min = 0, max = 950, step = 10})    
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")}) 
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1075, min = 0, max = 1075, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "EMode", name = "Spider E on Enemy Toggle", key = string.byte("T"), toggle = true})   

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Elise:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() and myHero:GetSpellData(_W).name == "EliseHumanW" then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end 
  end
end

function Elise:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(725)
if target == nil then return end  
  Control.CastSpell(HK_Q, pos)
end
end 

function Elise:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1050)
if target == nil then return end  
  local pos = GetPred(target, 2000, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_W, pos)
end
end 

function Elise:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1175)
if target == nil then return end
  local pos = GetPred(target, 1600, 0.25 + (Game.Latency()/1000))
  if myHero:GetSpellData(_E).name == "EliseHumanE" then
    Control.CastSpell(HK_E, pos)
  end
  if myHero:GetSpellData(_E).name == "EliseSpiderEInitial" and KoreanMechanics.Spell.EMode:Value() then
      Control.CastSpell(HK_E, target)
  end
  Control.CastSpell(HK_E, mousePos)
end
end

function Elise:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end
      if KoreanMechanics.Spell.EMode:Value() then
        Draw.Text("Spider E on Enemies ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))     
      end
      if not KoreanMechanics.Spell.EMode:Value()  then 
        Draw.Text("Spider E on Enemies OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end   
      if KoreanMechanics.Draw.QD.Enabled:Value() and myHero:GetSpellData(_Q).name == "EliseHumanQ"  then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.QD.Enabled:Value() and myHero:GetSpellData(_Q).name ~= "EliseHumanQ" then
           Draw.Circle(myHero.pos, 475, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end  
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() and myHero:GetSpellData(_E).name == "EliseHumanE" then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() and myHero:GetSpellData(_E).name ~= "EliseHumanE" then
            Draw.Circle(myHero.pos, 800, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end                 
      end   
  end
end

class "Zilean"

function Zilean:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Zilean Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Zilean:Menu()
  KoreanMechanics:MenuElement({id = "Speed", name = "Q Pred Speed", value = 1500, min = 500, max = 2000, step = 50})
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "max Q Range", value = 900, min = 0, max = 900, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Usage", key = string.byte("E")}) 
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 750, min = 0, max = 750, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "EMode", name = "Auto target E Toggle", key = string.byte("T"), toggle = true}) 
  KoreanMechanics.Spell:MenuElement({id = "RS", name = "R Settings", type = MENU})
  KoreanMechanics.Spell.RS:MenuElement({id = "R", name = "R Usage", value = true})        
  KoreanMechanics.Spell.RS:MenuElement({id = "RHP", name = "Smart R when HP% [?]", value = 10, min = 0, max = 100, step = 1}) 

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})     
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Zilean:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
    if KoreanMechanics.Spell.RS.R:Value() then
      self:R()
    end
  end
end

function Zilean:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end  
  local pos = GetPred(target, KoreanMechanics.Speed:Value(), 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end 
end 

function Zilean:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(850)
  if KoreanMechanics.Spell.EMode:Value() then 
    if target == nil then   Control.CastSpell(HK_E, myHero) end
    if target then
        Control.CastSpell(HK_E, target)
    end
  end
  if not KoreanMechanics.Spell.EMode:Value() then 
    if target == nil then return end
    Control.CastSpell(HK_E, mousePos)
  end
end
end

function Zilean:R()
  if Ready(_R) then
local Heroes = nil
  if KoreanMechanics.Spell.RS.R:Value() and Ready(_R) then
    local target =  _G.SDK.TargetSelector:GetTarget(1500)
    if target == nil then return end
    if target then
      for i = 1, Game.HeroCount() do
      local Heroes = Game.Hero(i)
        if Heroes.distance < 900 and Heroes.isAlly and not Heroes.dead and (Heroes.health/Heroes.maxHealth) < (KoreanMechanics.Spell.RS.RHP:Value()/100) then
          Control.CastSpell(HK_R, Heroes)
        end
      end
      if (myHero.health/myHero.maxHealth) < (KoreanMechanics.Spell.RS.RHP:Value()/100) then
        Control.CastSpell(HK_R, myHero)
      end
    end
  end
end
end

function Zilean:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end
      if KoreanMechanics.Spell.EMode:Value() then
        Draw.Text("Smart E ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))     
      end
      if not KoreanMechanics.Spell.EMode:Value()  then 
        Draw.Text("Smart E OFF", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end        
      if KoreanMechanics.Draw.QD.Enabled:Value() then
          Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end 
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, 900 , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end                   
    end
  end
end
  
class "Corki"

function Corki:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Corki Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Corki:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 825, min = 0, max = 825, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
  --KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 1300, min = 0, max = 1300, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Corki:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end   
  end
end 

function Corki:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end  
  local pos = GetPred(target, 1125, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_Q, pos)
end
end

function Corki:R()
  if Ready(_R) then
local target =  _G.SDK.TargetSelector:GetTarget(1400)
if target == nil then return end  
  local pos = GetPred(target, 2000, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_R, pos)
end
end 

function Corki:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, RRange, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end         
      end   
  end
end

class "Sivir"

function Sivir:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Sivir Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Sivir:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1200, min = 0, max = 1200, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Sivir:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
  end
end 

function Sivir:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1300)
if target == nil then return end  
  local pos = GetPred(target, 1350, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end

function Sivir:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      end   
  end
end

class "Aatrox"

function Aatrox:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Aatrox Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Aatrox:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 650, min = 0, max = 650, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1075, min = 0, max = 1075, step = 10})  

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end

function Aatrox:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end   
  end
end 

function Aatrox:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(750)
if target == nil then return end  
  local pos = GetPred(target, 2000, 0.6 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end

function Aatrox:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1350)
if target == nil then return end  
  local pos = GetPred(target, 1250, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_E, pos)
end
end

function Aatrox:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end         
      end   
  end
end

class "Jinx"

function Jinx:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Jinx Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Jinx:Menu()
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1500, min = 0, max = 1500, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("R")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 900, min = 0, max = 900, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")}) 

  KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Jinx:Tick()
  if KoreanMechanics.Enabled:Value() then
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end   
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end     
  end
end

function Jinx:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end  
  local pos = GetPred(target, 1500, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end

function Jinx:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end  
  local pos = GetPred(target, 900, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_E, pos)
end
end

function Jinx:R() 
  if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
  if targety == nil then return end   
  local pos = GetPred(targety, 2500, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_R, pos)
end
end

function Jinx:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end         
      end   
  end
end

class "Warwick"

function Warwick:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Warwick Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Warwick:Menu()
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Warwick:Tick()
  if KoreanMechanics.Enabled:Value() then
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end     
  end
end

function Warwick:R()  
  if Ready(_R) then
    local targety =  _G.SDK.TargetSelector:GetTarget()
    if targety == nil then return end   
    local pos = GetPred(targety, myHero:GetSpellData(R).range, 0.25 + Game.Latency()/1000)
    Control.CastSpell(HK_R, pos)
  end
end

function Warwick:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end
      local range = myHero:GetSpellData(_R).range     
      if range == nil then return end
      if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end       
      end   
  end
end

class "Annie"

function Annie:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Annie Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Annie:Menu()
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 600, min = 0, max = 600, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")}) 
  --KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 600, min = 0, max = 600, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})  
end

function Annie:Tick()
  if KoreanMechanics.Enabled:Value() then
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end     
  end
end

function Annie:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end  
  local pos = GetPred(target, 600, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end

function Annie:R()  
  if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
  if targety == nil then return end   
  local pos = GetPred(targety, 600, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_R, pos)
end
end

function Annie:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.WD.Enabled:Value() then
        Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
      end
      if KoreanMechanics.Draw.RD.Enabled:Value() then
        Draw.Circle(myHero.pos, RRange, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
      end
    end         
  end   
end

class "Ashe"

function Ashe:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Ashe Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Ashe:Menu()
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1200, min = 0, max = 1200, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})

  KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ashe:Tick()
  if KoreanMechanics.Enabled:Value() then
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end     
  end
end

function Ashe:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(1600)
if target == nil then return end  
  local pos = GetPred(target, 1200, (0.25 + Game.Latency())/1000)
  Control.CastSpell(HK_W, pos)
end
end

function Ashe:R() 
  if Ready(_R) then
local targety =  _G.SDK.TargetSelector:GetTarget()
  if targety == nil then return end   
  local pos = GetPred(targety, myHero:GetSpellData(R).range, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_R, pos)
end
end

function Ashe:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.WD.Enabled:Value() then
        Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
      end
    end         
  end   
end

class "Bard"

function Bard:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Bard Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Bard:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 925, min = 0, max = 925, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Bard:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end 
  end
end

function Bard:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then return end  
  local pos = GetPred(target, 925, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end

function Bard:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
        Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
      end
    end         
  end   
end

class "LeeSin"

function LeeSin:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Lee Sin Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function LeeSin:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1100, min = 0, max = 1100, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function LeeSin:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() and myHero:GetSpellData(_Q).name == "BlindMonkQOne" then
      self:Q()
    end
  end
end

function LeeSin:Q()
  if Ready(_Q) then
    local target = _G.SDK.TargetSelector:GetTarget(1350)
    if target == nil then return end
    local pos = GetPred(target, 1800, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_Q, pos)
  end
end

function LeeSin:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      end   
  end
end

class "Lissandra"

function Lissandra:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Lissandra Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Lissandra:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 700, min = 0, max = 700, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1050, min = 0, max = 1050, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Lissandra:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
  end
end

function Lissandra:Q()
  if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end
    local pos = GetPred(target, 2200, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_Q, pos)
end
end

function Lissandra:E()
  if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end
    local pos = GetPred(target, 850, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_E, pos)
end
end

function Lissandra:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "Nami"

function Nami:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Nami Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Nami:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 875, min = 0, max = 875, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
  --KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 2750, min = 0, max = 2750, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Nami:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end
end

function Nami:Q()
  if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end
    local pos = GetPred(target, 875, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_Q, pos)
end
end

function Nami:R()
  if Ready(_R) then
local target = _G.SDK.TargetSelector:GetTarget(2850)
if target == nil then return end
    local pos = GetPred(target, 2750, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_R, pos)
end
end

function Nami:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, RRange, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end
      end   
  end
end

class "Rengar"

function Rengar:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Rengar Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Rengar:Menu()
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1000, min = 0, max = 1000, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Rengar:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:E()
    end
  end
end

function Rengar:E()
  if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end
    local pos = GetPred(target, 1500, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_E, pos)
end
end

function Rengar:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "Veigar"

function Veigar:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Veigar Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Veigar:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 950, min = 0, max = 950, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 900, min = 0, max = 900, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 700, min = 0, max = 700, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
  --KoreanMechanics.Spell:MenuElement({id = "RR", name = "R Range", value = 650, min = 0, max = 650, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Veigar:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
    if KoreanMechanics.Spell.R:Value() then
      self:R()
    end
  end
end

function Veigar:Q()
  if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end
    local pos = GetPred(target, 2000, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_Q, pos)
end
end

function Veigar:W()
  if Ready(_W) then
local target = _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end
    local pos = GetPred(target, math.huge, 1.35 + (Game.Latency()/1000))
    Control.CastSpell(HK_W, pos)
end
end

function Veigar:E()
  if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(925)
if target == nil then return end
    local pos = GetPred(target, 700, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_E, pos)
end
end

function Veigar:R()
  if Ready(_R) then
local target = _G.SDK.TargetSelector:GetTarget(750)
if target == nil then return end
    Control.CastSpell(HK_R, target.pos)
end
end

function Veigar:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.Circle(myHero.pos, RRange, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end
      end   
  end
end

class "Soraka"

function Soraka:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Soraka Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Soraka:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 800, min = 0, max = 800, step = 25})
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 925, min = 0, max = 925, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Soraka:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
  end
end

function Soraka:Q()
  if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(950)
if target == nil then return end
    local pos = GetPred(target, 1750, 0.5 + (Game.Latency()/1000))
    Control.CastSpell(HK_Q, pos)
end
end

function Soraka:E()
  if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1000)
if target == nil then return end
    local pos = GetPred(target, 925, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_E, pos)
end
end

function Soraka:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "Skarner"

function Skarner:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Skarner Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Skarner:Menu()
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1000, min = 0, max = 1000, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Skarner:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
  end
end

function Skarner:E()
  if Ready(_E) then
local target = _G.SDK.TargetSelector:GetTarget(1250)
if target == nil then return end
    local pos = GetPred(target, 1500, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_E, pos)
end
end

function Skarner:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end
      end   
  end
end

class "Twitch"

function Twitch:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Twitch Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Twitch:Menu()
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 950, min = 0, max = 950, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Twitch:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
  end
end

function Twitch:W()
  if Ready(_W) then
local target = _G.SDK.TargetSelector:GetTarget(1100)
if target == nil then return end
    local pos = GetPred(target, 1400, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_W, pos)
end
end

function Twitch:Draw()
  if not myHero.dead then
    if KoreanMechanics.Draw.Enabled:Value() then
      local textPos = myHero.pos:To2D()
      if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
      end   
  end
end

class "TwistedFate"

function TwistedFate:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Twisted Fate Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
  Color = 0 
    LastW = 0 
end

function TwistedFate:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1450, min = 0, max = 1450, step = 25}) --1000 speed

  KoreanMechanics.Spell:MenuElement({id = "WG", name = "Gold Card Key", key = " "})
  KoreanMechanics.Spell:MenuElement({id = "WB", name = "Blue Card Key", key = "E"}) 
  KoreanMechanics.Spell:MenuElement({id = "WR", name = "Red Card Key", key = "T"})
  KoreanMechanics.Spell:MenuElement({id = "RS", name = "R Settings", type = MENU})  
  KoreanMechanics.Spell.RS:MenuElement({id = "R", name = "Ult Gold Card", value = true})  

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end


function TwistedFate:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.WG:Value() then
      Color = 1
      self:W()
    end
    if KoreanMechanics.Spell.WB:Value() then
      Color = 2
      self:W()
    end
    if KoreanMechanics.Spell.WR:Value() then
      Color = 3
      self:W()
    end
    if Color == 1 and myHero:GetSpellData(_W).name == "GoldCardLock" then 
      Control.CastSpell(HK_W) 
      DelayAction(function()
      Color = 0
      end, 0.1)     
    end 
    if Color == 2 and myHero:GetSpellData(_W).name == "BlueCardLock" then 
      Control.CastSpell(HK_W) 
      DelayAction(function()
      Color = 0
      end, 0.1)     
    end 
    if Color == 3 and myHero:GetSpellData(_W).name == "RedCardLock" then 
      Control.CastSpell(HK_W) 
      DelayAction(function()
      Color = 0
      end, 0.1)     
    end 
    if KoreanMechanics.Spell.RS.R:Value() then
      if HasBuff(myHero, "Gate") then
        Color = 1
        self:W()
      end
    end       
  end
end 

function TwistedFate:Q()
  if Ready(_Q) then
local target = _G.SDK.TargetSelector:GetTarget(1550)
if target == nil then return end
    local pos = GetPred(target, 1000, 0.25 + (Game.Latency()/1000))
    Control.CastSpell(HK_Q, pos)
end
end

function TwistedFate:W()
  if Ready(_W) and myHero:GetSpellData(_W).name == "PickACard" and GetTickCount() > LastW + 400 then
    Control.CastSpell(HK_W)
    LastW = GetTickCount()    
  end
end


function TwistedFate:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.RD.Enabled:Value() then
            Draw.CircleMinimap(myHero.pos, 5500, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
        end         
      end   
  end
end

class "DrMundo"

function DrMundo:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Mundo Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function DrMundo:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1050, min = 0, max = 1050, step = 25})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function DrMundo:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
  end
end 

function DrMundo:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1150)
if target == nil then return end  
  local pos = GetPred(target, 2000, 0.25 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end

function DrMundo:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      end   
  end
end

class "Xerath"

function Xerath:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Xerath Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Xerath:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Toggle", key = string.byte("T"), toggle = true})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1150, min = 0, max = 1150, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
--  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 1100, min = 0, max = 1100, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 1050, min = 0, max = 1050, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})     

  KoreanMechanics.Draw:MenuElement({id = "Toggle", name = "Draw Q Toggle", value = true})   
  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

RActive = "FALSE"
LastCast = 0
QRange = 750
QTick = 0 
QCharge = false
function Xerath:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if not Control.IsKeyDown(17) then
      if KoreanMechanics.Spell.Q:Value() then
        self:Qs()
      end
      if KoreanMechanics.Spell.W:Value() then
        self:W()
      end
      if KoreanMechanics.Spell.E:Value() then
        self:E()
      end 
      if KoreanMechanics.Spell.R:Value()  then
        RActive = "TRUE"
      end 
      if RActive == "TRUE" and myHero:GetSpellData(_R).name == "XerathRMissileWrapper" then
        self:R()
        LastCast = Game.Timer()
      end
      if myHero:GetSpellData(_R).name == "XerathLocusOfPower2" then 
        RActive = "FALSE"
      end
    end     
  end
end

function Xerath:HaveXerathBuff(unit)
  for i = 0, unit.buffCount do
      local buff = unit:GetBuff(i)
      if buff and buff.name == "XerathArcanopulseChargeUp" and buff.count > 0 and Game.Timer() < buff.expireTime then
          return buff.count
      end
  end
  return 0
end

QRange = 750
QTick = 0 
QCharge = false
function Xerath:Qs()
local target =  _G.SDK.TargetSelector:GetTarget(2000)
  if QCharge == true then
    QRange = 750 + 500*(GetTickCount()-QTick)/1000
    if QRange > 1500 then QRange = 1500 end
  end
  local QBuff = Xerath:HaveXerathBuff(myHero)
  if QCharge == false and QBuff > 0 then
    QTick = GetTickCount()
    QCharge = true
  end
  if QCharge == true and QBuff == 0 then
    QCharge = false
    QRange = 750 
  end
  if target == nil then return end  
  local pos = GetPred(target, 1600, (0.35 + Game.Latency())/1000)
  ExtraRange = 100
  if target.distance > 750 then
    ExtraRange = 150  
  end
  if Control.IsKeyDown(HK_Q) and QCharge == true then
    if QRange > target.distance + ExtraRange or QRange == 1500 then
      if not pos:ToScreen().onScreen then
      local pos2 = myHero.pos + Vector(myHero.pos,pos):Normalized() * math.random(530,760)
        Control.CastSpell(HK_Q, pos2)
      end
      local pos3 = GetPred(target, math.huge, (0.35 + Game.Latency())/1000)
      Control.CastSpell(HK_Q, pos3)
    end
  end
end 


function Xerath:W()
local target =  _G.SDK.TargetSelector:GetTarget(1200) 
if target == nil then return end    
  local pos = GetPred(target, math.huge, 0.35 + Game.Latency()/1000)
  Control.CastSpell(HK_W, pos)
end

function Xerath:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1150) 
if target == nil then return end    
  local pos = GetPred(target, 1600, 0.25 + Game.Latency()/1000)
  Control.CastSpell(HK_E, pos)
end
end 


function Xerath:R()
local hero = nil
  for i = 1, Game.HeroCount() do
    local hero = Game.Hero(i)
    if hero.isEnemy and IsValidTarget(hero, math.huge) and GetDistance(hero.pos, mousePos) < 300 then 
      targety = hero
    end
  end
  if targety == nil or targety.dead then return end     
  local pos = GetPred(targety, math.huge, 0.45 + Game.Latency()/1000)
  if pos:ToScreen().onScreen and Ready(_R) then
    Control.SetCursorPos(pos)
    DelayAction(function() Control.KeyDown(HK_R) end,0.01) 
        DelayAction(function() Control.KeyUp(HK_R) end, 0.05 + Game.Latency()/1000)         
  end
end   

function Xerath:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Spell.Q:Value() and KoreanMechanics.Draw.Toggle:Value() then
        Draw.Text("Q Toggle ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Spell.Q:Value() and KoreanMechanics.Draw.Toggle:Value() then 
        Draw.Text("Q Toggle Off", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end       
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end 
        if RActive == "TRUE" then
          Draw.Circle(mousePos, 300, 3, Draw.Color(255, 000, 000, 205))
        end
      end   
  end
end

class "Ivern"

function Ivern:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Ivern Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Ivern:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 1075, min = 0, max = 1075, step = 10})

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ivern:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
  end 
end

function Ivern:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(1175)
if target == nil then return end  
  local pos = GetPred(target, 1300, (0.25 + Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end

function Ivern:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      end   
  end
end

class "Karthus"

function Karthus:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Karthus Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end

function Karthus:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Aimbot Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 875, min = 0, max = 875, step = 10}) --0.625 delay
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
  KoreanMechanics.Spell:MenuElement({type = MENU, id = "AE", name = "Auto E"})  
  KoreanMechanics.Spell.AE:MenuElement({id = "ON", name = "Enabled", value = true})
  KoreanMechanics.Spell.AE:MenuElement({id = "Mana", name = "Mana (%) for E", value = 10, min = 0, max = 100, step = 1})
  KoreanMechanics.Spell:MenuElement({id = "RToggle", name = "R Toggle Key", key = string.byte("T"), toggle = true}) 
  KoreanMechanics.Spell:MenuElement({type = SPACE, name = "1. Change the Q HK in league settings to new key"})
  KoreanMechanics.Spell:MenuElement({type = SPACE, name = "2. Change the HK_Q in GOS settings to same key"})  

  KoreanMechanics.Draw:MenuElement({id = "Toggle", name = "Draw R Toggle", value = true}) 
  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})    
end

function Karthus:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end   
  end
  if KoreanMechanics.Spell.RToggle:Value() then
    self:R()
  end
  if not KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.Q:Value() then
      self:Q2()
    end
  end
  if KoreanMechanics.Spell.AE.ON:Value() then
    self:E()
  end
end

function Karthus:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(975)
if target == nil then Karthus:Q2() end  
  local pos = GetPred(target, 1500, 0.5 + (Game.Latency()/1000))
  Control.CastSpell(HK_Q, pos)
end
end

function Karthus:Q2()
  if Ready(_Q) then
  Control.CastSpell(HK_Q, pos)
end
end

function Karthus:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(975)
if target == nil then return end  
  local pos = GetPred(target, math.huge, 0.5 + (Game.Latency()/1000))
  Control.CastSpell(HK_W, pos)
end
end 

function Karthus:E()
  if Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Spell.AE.Mana:Value() / 100) then
    local Count = EnemiesAround(myHero, 425)
    if Count > 0 then
      if myHero:GetSpellData(_E).toggleState == 1 then
        Control.CastSpell(HK_E)
      end
    elseif Count == 0 then 
      if myHero:GetSpellData(_E).toggleState == 2 then
        Control.CastSpell(HK_E)
      end
    end
  end
end

function Karthus:Rdmg(unit)
local lvl = myHero:GetSpellData(_R).level 
if lvl == nil then return 0 end 
local AP = math.floor(myHero.ap)
local Rdmg = CalcMagicalDamage(myHero, unit, ({250, 400, 550})[lvl] + (0.6 * AP))
return Rdmg 
end 

function Karthus:R()
  if Ready(_R) then
    for i = 1, Game.HeroCount() do
    local hero = Game.Hero(i) 
      if hero.isEnemy and hero.valid and not hero.dead and Karthus:Rdmg(hero) > hero.health and hero.distance > 1000 then
        Control.CastSpell(HK_R) 
      end
    end
  end
end


function Karthus:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and not KoreanMechanics.Hold:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Spell.RToggle:Value() and KoreanMechanics.Draw.Toggle:Value() then
        Draw.Text("Auto R ON", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Spell.RToggle:Value() and KoreanMechanics.Draw.Toggle:Value() then 
        Draw.Text("Auto R Off", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 000, 000)) 
      end       
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
      if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end       
      end   
  end
end

class "Leblanc"

function Leblanc:__init()
  QRange = myHero:GetSpellData(_Q).range
  WRange = myHero:GetSpellData(_W).range
  ERange = myHero:GetSpellData(_E).range
  RRange = myHero:GetSpellData(_R).range
  print("Weedle's Leblanc Loaded")
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
  self:Menu()
end 

function Leblanc:Menu()
  KoreanMechanics.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
  --KoreanMechanics.Spell:MenuElement({id = "QR", name = "Q Range", value = 700, min = 0, max = 700, step = 10})
  KoreanMechanics.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
--  --KoreanMechanics.Spell:MenuElement({id = "WR", name = "W Range", value = 600, min = 0, max = 600, step = 10})  
  KoreanMechanics.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
  --KoreanMechanics.Spell:MenuElement({id = "ER", name = "E Range", value = 925, min = 0, max = 925, step = 10})
  KoreanMechanics.Spell:MenuElement({type = SPACE, name = "1. Change the E HK in league settings to new key"})
  KoreanMechanics.Spell:MenuElement({type = SPACE, name = "2. Change the HK_E in GOS settings to same key"})    

  KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
end

function Leblanc:Tick()
  if KoreanMechanics.Enabled:Value() or KoreanMechanics.Hold:Value() then 
    if KoreanMechanics.Spell.Q:Value() then
      self:Q()
    end
    if KoreanMechanics.Spell.W:Value() then
      self:W()
    end
    if KoreanMechanics.Spell.E:Value() then
      self:E()
    end
  end
  if not KoreanMechanics:Value() or KoreanMechanics.Hold:Value() then
    if KoreanMechanics.Spell.E:Value() then
      self:E2()
    end
  end
end

function Leblanc:Q()
  if Ready(_Q) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end  
  Control.CastSpell(HK_Q, target)
end 
end

function Leblanc:W()
  if Ready(_W) then
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end    
  local pos = GetPred(target, 1600, (0.25 + Game.Latency())/1000) 
  Control.CastSpell(HK_W, pos)
end
end 


function Leblanc:E()
  if Ready(_E) then
local target =  _G.SDK.TargetSelector:GetTarget(1025)
if target == nil then Leblanc:E2() end  
  local pos = GetPred(target, 1750, (0.25 + Game.Latency())/1000) 
  Control.CastSpell(HK_E, pos)
end
end 

function Leblanc:E2()
  if Ready(_E) then
  Control.CastSpell(HK_E, mousePos)
end
end

function Leblanc:Draw()
  if not myHero.dead then
      if KoreanMechanics.Draw.Enabled:Value() then
        local textPos = myHero.pos:To2D()
        if KoreanMechanics.Enabled:Value() then
        Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000))    
      end
      if not KoreanMechanics.Enabled:Value() and KoreanMechanics.Draw.OFFDRAW:Value() then 
        Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
      end 
      if KoreanMechanics.Draw.QD.Enabled:Value() then
            Draw.Circle(myHero.pos, QRange, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
        end
        if KoreanMechanics.Draw.WD.Enabled:Value() then
            Draw.Circle(myHero.pos, WRange, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
        end
        if KoreanMechanics.Draw.ED.Enabled:Value() then
            Draw.Circle(myHero.pos, ERange, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
        end       
      end   
  end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name..", thank you for using my Scripts ^^") end