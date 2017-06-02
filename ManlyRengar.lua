if myHero.charName ~= "Rengar" then 
PrintChat ("You aint Playin knife cat, Shutting down")
return end

class "Rengar"
require('DamageLib')

local _shadow = myHero.pos

function Rengar:__init()
    if myHero.charName ~= "Rengar" then return end
    PrintChat("ManlyRengar Enabled")
    self:LoadSpells()
    self:LoadMenu()
    Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end

function Rengar:LoadSpells()
  Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
  W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
  E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
end

function Rengar:LoadMenu()
    self.Menu = MenuElement({type = MENU, id = "Rengar", name = "ManlyRengar", leftIcon="http://i3.kym-cdn.com/entries/icons/original/000/016/188/01.png"})

    --[[Combo]]
    self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
    self.Menu.Combo:MenuElement({id = "ComboQ", name = "Use Q", value = true})
    self.Menu.Combo:MenuElement({id = "ComboW", name = "Use W", value = true})
    self.Menu.Combo:MenuElement({id = "ComboE", name = "Use E", value = true})
  

    --[[Draw]]
    self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
    self.Menu.Draw:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
    self.Menu.Draw:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
    self.Menu.Draw:MenuElement({id = "DrawE", name = "Draw E Range", value = true})

    

    PrintChat("ManlyRengar Menu Loaded")
end

function Rengar:Tick()

  if myHero.dead then return end
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
      self:Combo()
      end
      
  
end

function Rengar:Combo()
    if _G.SDK.TargetSelector:GetTarget(725) == nil then return end


         local qtarg = _G.SDK.TargetSelector:GetTarget(430)
    if self.Menu.Combo.ComboQ:Value() and self:CanCast(_Q) then
      local castPosition = qtarg
        self:CastQ(castPosition)
        end
        

           local wtarg = _G.SDK.TargetSelector:GetTarget(430)
    if self.Menu.Combo.ComboW:Value() and self:CanCast(_W) then
    local castPosition = wtarg
      self:CastW(castPosition)
         end
      
           local etarg = _G.SDK.TargetSelector:GetTarget(725)
    if self.Menu.Combo.ComboE:Value() and self:CanCast(_E) and etarg:GetCollision(E.width,E.speed,E.delay) == 0 then
      local castPosition = etarg:GetPrediction(E.Speed, E.delay)
       self:CastE(castPosition)
      
   
   
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


        if self.Menu.Draw.DrawQ:Value() then
            Draw.Circle(myHero.pos, 450, 1, Draw.Color(255, 255, 255, 255))
        end
        if self.Menu.Draw.DrawW:Value() then
            Draw.Circle(myHero.pos, 450, 1, Draw.Color(255, 255, 255, 255))
        end
        if self.Menu.Draw.DrawE:Value() then
            Draw.Circle(myHero.pos, 1000, 1, Draw.Color(255, 255, 255, 255))
        end


end






function Rengar:HasBuff(unit, buffname)
    for K, Buff in pairs(self:GetBuffs(unit)) do
        if Buff.name:lower() == buffname:lower() then
            return true
        end
    end
    return false
end

function Rengar:GetBuffs(unit)
    self.T = {}
    for i = 0, unit.buffCount do
        local Buff = unit:GetBuff(i)
        if Buff.count > 0 then
            table.insert(self.T, Buff)
        end
    end
    return self.T
end

function Rengar:IsReady(spellSlot)
    return myHero:GetSpellData(spellSlot).currentCd == 0 and myHero:GetSpellData(spellSlot).level > 0
end


function Rengar:CanCast(spellSlot)
    return self:IsReady(spellSlot)
end

--function Rengar:IsValidTarget(obj, spellRange)
--    return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= spellRange
--end

function Rengar:IsValidTarget(unit,range) 
  return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 620 
end

function OnLoad()
    Rengar()
end
