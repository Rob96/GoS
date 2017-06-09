if myHero.charName ~= "Rengar" then
  PrintChat ("You aint Playin knife cat, Shutting down")
  return end

class "Rengar"
require('DamageLib')

local _shadow = myHero.pos

function Rengar:__init()
  PrintChat("ManlyRengar Enabled")
  self:LoadSpells()
  self:LoadMenu()
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)
end

function Rengar:LoadSpells()
  E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
end

function Rengar:LoadMenu()
  self.Menu = MenuElement({type = MENU, id = "Rengar", name = "ManlyRengar", leftIcon="http://i3.kym-cdn.com/entries/icons/original/000/016/188/01.png"})

  --[[Combo]]
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
  self.Menu.Combo:MenuElement({id = "ComboQ", name = "Use Q", value = true})
  self.Menu.Combo:MenuElement({id = "ComboW", name = "Use W", value = true})
  self.Menu.Combo:MenuElement({id = "ComboE", name = "Use E", value = true})
  self.Menu.Combo:MenuElement({id = "Prio", name = "Combo Ferocity Priority", drop = {"Q","W","E"}})

  self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
  self.Menu.Clear:MenuElement({id = "ClearQ", name = "Use Q", value = true})
  self.Menu.Clear:MenuElement({id = "ClearW", name = "Use W", value = true})
  self.Menu.Clear:MenuElement({id = "ClearE", name = "Use E", value = true})

  --[[Draw]]
  self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
  self.Menu.Draw:MenuElement({id = "DrawQW", name = "Draw Q/W Range", value = true})
  self.Menu.Draw:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
end

function Rengar:Tick()
  if myHero.dead then return end
  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.Menu.Combo.Prio:Value()== 1 then
    self:CQ() self:CE() self:CW()
    return end
  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.Menu.Combo.Prio:Value() == 2 then
    self:CW() self:CQ() self:CE()
    return end
  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.Menu.Combo.Prio:Value() == 3 then
    self:CE() self:CQ() self:CW()
    return end
  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]
  then
    self:JClear()
  end
  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]
  then
    self:LClear()
  end
end

function Rengar:JClear()
  for i = 1, Game.MinionCount(725) do
    local minion = Game.Minion(i)
    if  minion.team == 300 then
      if myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearQ:Value() and self:CanCast(_Q) then
        Control.CastSpell(HK_Q,minion.pos)
      end
      if myHero.pos:DistanceTo(minion.pos) < 725 and self.Menu.Clear.ClearE:Value() and self:CanCast(_E) then
        Control.CastSpell(HK_E,minion.pos)
      end
      if myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearW:Value() and self:CanCast(_W) then
        Control.CastSpell(HK_W)
      end
    end
  end
end

function Rengar:LClear()
  for i = 1, Game.MinionCount(725) do
    local minion = Game.Minion(i)
    if  minion.team == 200 then
      if myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearQ:Value() and self:CanCast(_Q) then
        Control.CastSpell(HK_Q,minion.pos)
      end
      if myHero.pos:DistanceTo(minion.pos) < 725 and self.Menu.Clear.ClearE:Value() and self:CanCast(_E) then
        Control.CastSpell(HK_E,minion.pos)
      end
      if myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearW:Value() and self:CanCast(_W) then
        Control.CastSpell(HK_W)
      end
    end
  end
end

function Rengar:CQ()
  if _G.SDK.TargetSelector:GetTarget(410) == false then self:CE() return
  end
  local qtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboQ:Value() and self:CanCast(_Q) and qtarg ~= nil  then
    Control.CastSpell(HK_Q, qtarg)
  end
end

function Rengar:CE()
  if _G.SDK.TargetSelector:GetTarget(725) == false then return
  end
  local etarg = _G.SDK.TargetSelector:GetTarget(725)
  if etarg ~= nil then
    if self.Menu.Combo.ComboE:Value() and self:CanCast(_E) and etarg:GetCollision(E.width,E.speed,E.delay) == 0
    then
      Control.CastSpell(HK_E, etarg)
    end
  end
end

function Rengar:CW()
  if _G.SDK.TargetSelector:GetTarget(410) == false then self:CE() return end
  local wtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboW:Value() and self:CanCast(_W) and wtarg ~= nil then
    Control.CastSpell(HK_W,wtarg)
  end
end

function Rengar:Draw()
  if myHero.dead then return end
  if self.Menu.Draw.DrawQW:Value() then
    Draw.Circle(myHero.pos, 450, 1, Draw.Color(255, 255, 255, 255))
  end
  if self.Menu.Draw.DrawE:Value() then
    Draw.Circle(myHero.pos, 1000, 1, Draw.Color(255, 255, 255, 255))
  end
end

function Rengar:CanCast(spell)
  return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
end


function OnLoad()
  Rengar()
end
