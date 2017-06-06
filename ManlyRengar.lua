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
  self.Menu.Combo:MenuElement({type = MENU,id = "PTIp", name = "Q = 0,   W = 1,   E = 2"})
  self.Menu.Combo:MenuElement({id = "Prio", name = "Prioritise", value = 0, min = 0, max = 2})
  

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
  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.Menu.Combo.Prio:Value()== 0 then
    self:ComboQ()
    return end

  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.Menu.Combo.Prio:Value() == 1 then
    self:ComboW()
    return end

  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and self.Menu.Combo.Prio:Value() == 2 then
    self:ComboE()
    return end

  if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] --or 
  then
    self:JClear()
    
  end
if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] 
then
  self:LClear()
end
end


function Rengar:JClear()

  if self:GetValidMinion(650) == false then return end
  for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

    if  minion.team == 300 then



      if self:IsValidTarget(minion,410) and myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearQ:Value() and self:CanCast(_Q) then
        Control.CastSpell(HK_Q,minion.pos)

      
    end

    if self:IsValidTarget(minion,650) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Clear.ClearE:Value() and self:CanCast(_E) then
      Control.CastSpell(HK_E,minion.pos)


    end



    if self:IsValidTarget(minion,410) and myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearW:Value() and self:CanCast(_W) then
      Control.CastSpell(HK_W)

    end


  end


end

end

function Rengar:LClear()

  if self:GetValidMinion(650) == false then return end
  for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

    if  minion.team == 200 then



      if self:IsValidTarget(minion,410) and myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearQ:Value() and self:CanCast(_Q) then
        Control.CastSpell(HK_Q,minion.pos)

      
    end

    if self:IsValidTarget(minion,650) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Clear.ClearE:Value() and self:CanCast(_E) then
      Control.CastSpell(HK_E,minion.pos)


    end



    if self:IsValidTarget(minion,410) and myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearW:Value() and self:CanCast(_W) then
      Control.CastSpell(HK_W)

    end


  end


end

end
function Rengar:ComboQ()
  if _G.SDK.TargetSelector:GetTarget(1000) == false then return
  end


  local qtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboQ:Value() and self:CanCast(_Q)  then
    local castPosition = qtarg
    self:CastQ(castPosition)
  end

  if _G.SDK.TargetSelector:GetTarget(1000) == false then return
  end
  local etarg = _G.SDK.TargetSelector:GetTarget(725)
  if etarg ~= nil then
    if self.Menu.Combo.ComboE:Value() and self:CanCast(_E) and etarg:GetCollision(E.width,E.speed,E.delay) == 0
    then
      local castPosition = etarg
      self:CastE(castPosition)

    end
  end

  local wtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboW:Value() and self:CanCast(_W) then
    local castPosition = wtarg
    self:CastW(castPosition)
  end


end



function Rengar:ComboW()
  if _G.SDK.TargetSelector:GetTarget(1000) == false then return
  end

  local wtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboW:Value() and self:CanCast(_W) then
    local castPosition = wtarg
    self:CastW(castPosition)
  end

  local qtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboQ:Value() and self:CanCast(_Q) then
    local castPosition = qtarg
    self:CastQ(castPosition)
  end

  local etarg = _G.SDK.TargetSelector:GetTarget(725)
  if etarg ~= nil then
    if self.Menu.Combo.ComboE:Value() and self:CanCast(_E) and etarg:GetCollision(E.width,E.speed,E.delay) == 0 then
      local castPosition = etarg:GetPrediction(E.Speed, E.delay)
      self:CastE(castPosition)



    end


  end
end



function Rengar:ComboE()


  local etarg = _G.SDK.TargetSelector:GetTarget(725)
  if etarg ~= nil then
    if self.Menu.Combo.ComboE:Value() and self:CanCast(_E) and etarg:GetCollision(E.width,E.speed,E.delay) == 0 then
      local castPosition = etarg:GetPrediction(E.Speed, E.delay)
      self:CastE(castPosition)
    end
  end



  local qtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboQ:Value() and self:CanCast(_Q) then
    local castPosition = qtarg
    self:CastQ(castPosition)
  end



  local wtarg = _G.SDK.TargetSelector:GetTarget(410)
  if self.Menu.Combo.ComboW:Value() and self:CanCast(_W) then
    local castPosition = wtarg
    self:CastW(castPosition)





  end

end


function Rengar:CastQ(position)
  if position then
    Control.CastSpell(HK_Q, position)
  end
end

function Rengar:CastW(position)
  if position then
    Control.CastSpell(HK_W, position)
  end
end

function Rengar:CastE(position)
  if position then
    Control.CastSpell(HK_E, position)
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



function Rengar:IsReady(spellSlot)
  return myHero:GetSpellData(spellSlot).currentCd == 0 and myHero:GetSpellData(spellSlot).level > 0
end


function Rengar:CanCast(spellSlot)
  return self:IsReady(spellSlot)
end


function Rengar:GetValidMinion(range)
  for i = 1,Game.MinionCount() do
    local minion = Game.Minion(i)
    if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
      return true
    end
  end
  return false
end




function Rengar:IsValidTarget(unit,range)
  return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 620
end

function OnLoad()
  Rengar()
end
