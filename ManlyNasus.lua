class "Nasus"
--require("DamageLib")

local function Ready(spell)
    return Game.CanUseSpell(spell) == 0
end

local function GetTarget(range)
    local target = nil
    target = _G.SDK.TargetSelector:GetTarget(range)
    return target
end

local function GetMinion(range)
    for i = 1, Game.MinionCount() do
        local target = Game.Minion(i)
        if target.team == 200 then
            return target
        end
    end
end

local function GetBuffIndexByName(unit, name)
    for i = 1, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff.name == name then
            return i
        end
    end
end

local intToMode = {
    [0] = "",
    [1] = "Combo",
    [2] = "Harass",
    [3] = "Lasthit",
    [4] = "Clear"
}

local function GetMode()
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
        return "Combo"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
        return "Harass"
    elseif
        _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or
            _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]
     then
        return "Clear"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
        return "LastHit"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
        return "Flee"
    end
end

local function EnableOrb(bool)
    _G.SDK.Orbwalker:SetMovement(bool)
    _G.SDK.Orbwalker:SetAttack(bool)
end

function Nasus:__init()
    if myHero.charName ~= "Nasus" then
        return
    end

    PrintChat("ManlyNasus loaded")
    self:LoadMenu()
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
    Callback.Add(
        "Draw",
        function()
            self:Draw()
        end
    )
end

function Nasus:GetInventoryItem(itemID)
    for k, v in pairs({ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}) do
        if myHero:GetItemData(v).itemID == itemID and myHero:GetSpellData(v).currentCd == 0 then
            return v
        end
    end
    return nil
end

local function Qdmg(target)
    -- local TriForce = self:GetInventoryItem(3078)
    -- local IceBorn = self:GetInventoryItem(3025)
    -- local Sheen = self:GetInventoryItem(3057)
    local level = myHero:GetSpellData(_Q).level
    return CalcPhysicalDamage(
        myHero,
        target,
        (myHero:GetBuff(GetBuffIndexByName(myHero, "NasusQStacks")).stacks + ({30, 50, 70, 90, 110})[level] +
            myHero.totalDamage)
    )
    --local QDamage = myHero:GetBuff(GetBuffIndexByName(myHero,"NasusQStacks")).stacks + ({30, 50, 70, 90, 110})[level] + myHero.totalDamage
end

function Nasus:LoadMenu()
    self.Menu = MenuElement({type = MENU, id = "Nasus", name = "ManlyNasus"})

    --[[Combo]]
    self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = true})
    self.Menu.Combo:MenuElement({id = "E", name = "Use E", value = true})
    self.Menu.Combo:MenuElement({id = "R", name = "Auto R", value = true})
    self.Menu.Combo:MenuElement({id = "RHP", name = "Min Hp for R In %", value = 25, min = 0, max = 100})

    --[[Harass]]
    self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
    self.Menu.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Harass:MenuElement({id = "E", name = "Use E", value = true})
    self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana For Harass In %", value = 40, min = 0, max = 100})

    --[[LastHit]]
    self.Menu:MenuElement({type = MENU, id = "cs", name = "Lasthit"})
    self.Menu.cs:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.cs:MenuElement({id = "E", name = "Use E", value = true})
    self.Menu.cs:MenuElement({id = "Mana", name = "Min Mana for LastHit", value = 40, min = 0, max = 100})
    self.Menu.cs:MenuElement({id = "QAuto", name = "Auto Q LastHit", toggle = true, key = 85})
    self.Menu.cs:MenuElement({id = "QMana", name = "Min Mana For AutoQ LastHit", value = 40, min = 0, max = 100})

    --[[Clear]]
    self.Menu:MenuElement({type = MENU, id = "Clear", name = "Jungle / Lane Clear"})
    self.Menu.Clear:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Clear:MenuElement({id = "E", name = "Use E", value = true})

    --[[Draw]]
    self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
    self.Menu.Draw:MenuElement({id = "W", name = "Draw W Range", value = true})
    self.Menu.Draw:MenuElement({id = "E", name = "Draw E Range", value = true})
    -- self.Menu.Draw:MenuElement({id = "Q", name = "Draw Q damage on enemy", value = true})
end

function Nasus:Combo()
    local target = GetTarget(650)
    if target == nil then
        return
    end
    if self.Menu.Combo.Q:Value() and Ready(_Q) then
        if myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 then
            Control.CastSpell(HK_Q)
        end
    end

    if target == nil then
        return
    end
    if self.Menu.Combo.W:Value() and myHero.pos:DistanceTo(target.pos) < 600 and Ready(_W) then
        Control.CastSpell(HK_W, target)
    end

    if target == nil then
        return
    end
    if self.Menu.Combo.E:Value() and myHero.pos:DistanceTo(target.pos) < 650 and Ready(_E) then
        Control.CastSpell(HK_E, target.pos)
    end

    if self.Menu.Combo.R:Value() and myHero.health / myHero.maxHealth < self.Menu.Combo.RHP:Value() / 100 and Ready(_R) then
        local target = GetTarget(650)
        if target == nil then
            return
        end
        Control.CastSpell(HK_R)
    end
end

function Nasus:Harass()
    local target = GetTarget(650)
    if target == nil then
        return
    end
    if
        self.Menu.Harass.Q:Value() and myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 and Ready(_Q) and
            myHero.mana / myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100
     then
        Control.CastSpell(HK_Q)
    end
    if target == nil then
        return
    end
    if
        self.Menu.Harass.E:Value() and myHero.pos:DistanceTo(target.pos) <= 650 and Ready(_E) and
            myHero.mana / myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100
     then
        Control.CastSpell(HK_E, target)
    end
end

function Nasus:Lasthit()
    if self.Menu.cs.Q:Value() and Ready(_Q) and myHero.mana / myHero.maxMana >= self.Menu.cs.Mana:Value() / 100 then
        for i = 1, Game.MinionCount(320) do
            local target = Game.Minion(i)
            if target.team == 200 and myHero.pos:DistanceTo(target.pos) <= myHero.range + 100 then
                if Qdmg(target) > target.health then
                    EnableOrb(false)
                    Control.CastSpell(HK_Q)
                    Control.Attack(target)
                    DelayAction(
                        function()
                            EnableOrb(true)
                        end,
                        0.1
                    )
                end
            end
        end
    end

    if self.Menu.cs.E:Value() and Ready(_E) and myHero.mana / myHero.maxMana >= self.Menu.cs.Mana:Value() / 100 then
        local level = myHero:GetSpellData(_E).level
        local EDamage = ({55, 95, 135, 175, 215})[level] + 0.6 * myHero.ap
        for i = 1, Game.MinionCount(320) do
            local target = Game.Minion(i)
            if target == nil then
                return
            end
            if target.team == 200 and myHero.pos:DistanceTo(target.pos) <= 650 and EDamage >= target.health then
                Control.CastSpell(HK_E, target)
            end
        end
    end
end

function Nasus:Misc()
    if GetMode() == "Combo" then
        return
    end
    if self.Menu.cs.QAuto:Value() and Ready(_Q) and myHero.mana / myHero.maxMana >= self.Menu.cs.QMana:Value() / 100 then
        for i = 1, Game.MinionCount(320) do
            local target = Game.Minion(i)
            if target == nil then
                return
            end
            if
                target.team == 200 and myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 and
                    Qdmg(target) > target.health
             then
                EnableOrb(false)
                Control.CastSpell(HK_Q)
                Control.Attack(target)
                Control.Attack(target)
                DelayAction(
                    function()
                        EnableOrb(true)
                    end,
                    0.1
                )
            end
        end
    end
end

function Nasus:JClear()
    if self.Menu.Clear.Q:Value() and Ready(_Q) then
        for i = 1, Game.MinionCount(myHero.range) do
            local target = Game.Minion(i)
            if target == nil then
                return
            end
            if target.team == 300 and myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 then
                Control.CastSpell(HK_Q)
            end
        end
    end

    if self.Menu.Clear.E:Value() and Ready(_E) then
        for i = 1, Game.MinionCount(650) do
            local target = Game.Minion(i)
            if target == nil then
                return
            end
            if target.team == 300 and myHero.pos:DistanceTo(target.pos) <= 650 then
                Control.CastSpell(HK_E, target)
            end
        end
    end
end

function Nasus:LClear()
    if self.Menu.Clear.Q:Value() and Ready(_Q) then
        for i = 1, Game.MinionCount(myHero.range) do
            local target = Game.Minion(i)
            if target == nil then
                return
            end
            if target.team == 200 and myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 then
                Control.CastSpell(HK_Q)
            end
        end
    end

    if self.Menu.Clear.E:Value() and Ready(_E) then
        for i = 1, Game.MinionCount(650) do
            local target = Game.Minion(i)
            if target == nil then
                return
            end
            if target.team == 200 and myHero.pos:DistanceTo(target.pos) <= 650 then
                Control.CastSpell(HK_E, target)
            end
        end
    end
end

function Nasus:Tick()
    local Mode = GetMode()
    if Mode == "Combo" then
        self:Combo()
    elseif Mode == "Harass" then
        self:Harass()
    elseif Mode == "Clear" then
        self:JClear()
        self:LClear()
    elseif Mode == "LastHit" then
        self:Lasthit()
    elseif Mode == "" then
    end
    self:Misc()
end

function Nasus:Draw()
    if myHero.dead then
        return
    end
    if self.Menu.Draw.W:Value() then
        Draw.Circle(myHero.pos, 600, 1, Draw.Color(255, 255, 255, 255))
    end
    if self.Menu.Draw.E:Value() then
        Draw.Circle(myHero.pos, 650, 1, Draw.Color(255, 255, 255, 255))
    end
    --[[   if self.Menu.Draw.Q:Value() then
    for i = 1, Game.HeroCount() do
      local target = Game.Hero(i)
      if target and target.isEnemy and not target.dead and target.visible then 
        local barPos = target.hpBar
        local health = target.health
        local maxHealth = target.maxHealth
        local Qdmg = Qdmg(target)
          Draw.Rect(barPos.x + (( (health - Qdmg) / maxHealth) * 100) + 25, barPos.y - 13, (Qdmg / maxHealth )*100, 10, Draw.Color(255, 200, 200, 25))
      end
        end 
  end]]
end

function OnLoad()
    Nasus()
end
