class "Xayah"
require "PremiumPrediction"
require "Collision"

local _shadow = myHero.pos
local feathers = {}
local Feather = Collision:SetSpell(math.huge, 1800, 0.2, 40, true)
local time = os.clock()

function Xayah:__init()
    if myHero.charName ~= "Xayah" then
        return
    end

    self:LoadSpells()
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

function Xayah:LoadMenu()
    self.Menu = MenuElement({type = MENU, id = "Xayah", name = "ManlyXayah"})

    --Combo
    self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
    self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = true})

    --Clear

    self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear settings"})
    self.Menu.Clear:MenuElement({id = "Q", name = "Use Q", Value = true})
    self.Menu.Clear:MenuElement(
        {id = "MQ", name = "Min mana for Q clear in %", value = 100, min = 0, max = 100, step = 1}
    )
    self.Menu.Clear:MenuElement({id = "W", name = "Use W", Value = true})
    self.Menu.Clear:MenuElement(
        {id = "MW", name = "Min mana for W clear in %", value = 100, min = 0, max = 100, step = 1}
    )

    --KS
    self.Menu:MenuElement({type = MENU, id = "KS", name = "KS"})
    self.Menu.KS:MenuElement({id = "Q", name = "Use Q ", value = true})
    self.Menu.KS:MenuElement({id = "E", name = "Use E", value = true})

    --Misc
    self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    self.Menu.Misc:MenuElement({id = "AR", name = "Auto root", value = true})
    self.Menu.Misc:MenuElement({id = "x", name = "Min enemies to root", value = 2, min = 1, max = 5})
    self.Menu.Misc:MenuElement({id = "Qrange", name = "Min Q Range", value = 550, min = 10, max = 1100, step = 10})

    --Draw
    self.Menu:MenuElement({type = MENU, id = "Draw", name = "Draw"})
    self.Menu.Draw:MenuElement({id = "Q", name = "Draw min Q range", value = true})
    self.Menu.Draw:MenuElement({id = "R", name = "Draw R range", value = true})
    self.Menu.Draw:MenuElement({id = "F", name = "Feather line and counter", value = true})

    self.Menu:MenuElement(
        {
            type = PARAM,
            id = "Time",
            name = "Feather-Refresh Time[?]",
            value = 0.5,
            min = 0.1,
            max = 1,
            step = 0.1,
            tooltip = "Depends On Your PC's Perfomance"
        }
    )
end

local function DrawLine3D(k1, k2, width, col)
    local p1 = k1:To2D()
    local p2 = k2:To2D()
    Draw.Line(p1.x, p1.y, p2.x, p2.y, width, col)
end

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and
        myHero:GetSpellData(spell).mana <= myHero.mana and
        Game.CanUseSpell(spell) == 0
end

local function GetHeroesInFeatherLine(feather)
    if feather then
        local to = Vector(myHero.pos)
        local from = Vector(feather.pos)
        local block, list = Feather:__GetHeroCollision(from, to, 3)
        if block then
            return list
        end
    end
end

local function isHeroInFeatherLine(hero)
    local num = 0
    if #feathers > 0 and hero.visible then
        for k, feather in pairs(feathers) do
            local list = GetHeroesInFeatherLine(feather)
            if list then
                for k, v in pairs(list) do
                    if v == hero then
                        num = num + 1
                    end
                end
            end
        end
    end
    return num
end

local function SetRealFeathers()
    local feathers2 = {feathers[1]}
    for k, feather in pairs(feathers) do
        local featherPos = Vector(feather.pos)
        local found = false
        for k, feather2 in pairs(feathers2) do
            local feather2Pos = Vector(feather2.pos)
            if featherPos == feather2Pos then
                found = true
            end
        end
        if not found then
            table.insert(feathers2, feather)
        end
    end
    feathers = feathers2
end

local function GetDamage(spell, target)
    local EDamage = {50, 60, 70, 80, 90}
    if target then
        local line = isHeroInFeatherLine(target)
        if spell == _E and line > 0 and Ready(_E) then
            local damage = EDamage[myHero:GetSpellData(_E).level] + (myHero.bonusDamage * 0.6)
            damage = damage + (myHero.critChance * 0.75)
            local baseDamage = damage
            for i = 1, line do
                damage = damage + (baseDamage * 0.9)
            end
            return CalcPhysicalDamage(myHero, target, damage)
        end
    end
    return 0
end

function Xayah:AutoRoot()
    if Ready(_E) and self.Menu.Misc.AR:Value() then
        local heroesToRoot = 0
        for i = 1, Game.HeroCount() do
            local hero = Game.Hero(i)
            if hero.visible and not hero.dead and hero.isEnemy and not hero.isImmortal then
                if isHeroInFeatherLine(hero) >= 3 then
                    heroesToRoot = heroesToRoot + 1
                end
            end
        end
        if heroesToRoot >= self.Menu.Misc.x:Value() then
            Control.CastSpell(HK_E)
        end
    end
end
--

function Xayah:LoadSpells()
    Q = {delay = 0.4, range = 1100, speed = 600, radius = 50, type = "linear"}
    Qdata = {speed = Q.speed, delay = Q.delay, range = Q.range, radius = Q.radius, type = Q.type}
end

local intToMode = {
    [0] = "",
    [1] = "Combo",
    [2] = "Harass",
    [3] = "LastHit",
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
    end
end

local function GetTarget(range)
    local target = nil
    target = _G.SDK.TargetSelector:GetTarget(range)
    return target
end

local function EnableOrb(bool)
    _G.SDK.Orbwalker:SetMovement(bool)
    _G.SDK.Orbwalker:SetAttack(bool)
end

function Xayah:Combo()
    local QR = self.Menu.Misc.Qrange:Value()
    local target = GetTarget(1100)
    if target == nil then
        return
    end

    if self.Menu.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) > QR then
        local pred = _G.PremiumPrediction:GetPrediction(myHero, target, Qdata)
        if pred.CastPos and pred.HitChance >= 0.1 then
            EnableOrb(false)
            Control.CastSpell(HK_Q, pred.CastPos)
            EnableOrb(true)
        end
    end

    if self.Menu.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < myHero.range then
        Control.CastSpell(HK_W)
    end
end

function Xayah:Clear()
    for i = 1, Game.MinionCount(1200) do
        local minion = Game.Minion(i)
        if minion.team == 300 or minion.team == 200 then
            if
                myHero.mana / myHero.maxMana >= self.Menu.Clear.MQ:Value() / 100 and Ready(_Q) and
                    self.Menu.Clear.Q:Value()
             then
                local pred = _G.PremiumPrediction:GetPrediction(myHero, minion, Qdata)
                if pred.CastPos and pred.HitChance >= 0.1 then
                    EnableOrb(false)
                    Control.CastSpell(HK_Q, pred.CastPos)
                    EnableOrb(true)
                end
            end

            if
                myHero.mana / myHero.maxMana >= self.Menu.Clear.MW:Value() / 100 and Ready(_W) and
                    self.Menu.Clear.W:Value()
             then
                if myHero.pos:DistanceTo(minion.pos) < myHero.range then
                    Control.CastSpell(HK_W)
                end
            end
        end
    end
end

local function Qdmg(target)
    local level = myHero:GetSpellData(_Q).level
    return CalcPhysicalDamage(myHero, target, (30 + 15 * level + myHero.bonusDamage * 0.5) * 2)
end

function Xayah:Misc()
    local QR = self.Menu.Misc.Qrange:Value()
    local target = GetTarget(1100)
    if target == nil then
        return
    end

    if self.Menu.KS.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) > QR then
        local pred = _G.PremiumPrediction:GetPrediction(myHero, target, Qdata)
        if pred.CastPos and pred.HitChance >= 0.1 and Qdmg(target) > target.health then
            EnableOrb(false)
            Control.CastSpell(HK_Q, pred.CastPos)
            EnableOrb(true)
        elseif pred.CastPos and pred.HitChance >= 0.1 and Qdmg(target) / 2 >= target.health then
            EnableOrb(false)
            Control.CastSpell(HK_Q, pred.CastPos)
            EnableOrb(true)
        end
    end

    if self.Menu.KS.E:Value() and Ready(_E) and GetDamage(_E, target) > target.health then
        Control.CastSpell(HK_E)
    end
end

function Xayah:Tick()
    local target = GetTarget(1000)
    self:Misc()
    self:AutoRoot()
    local Mode = GetMode()
    if Mode == "Combo" then
        self:Combo()
    elseif Mode == "Clear" then
        self:Clear() --self:JClear()
    end
    if os.clock() - time > self.Menu.Time:Value() then
        feathers = {}
        for i = 1, Game.ObjectCount() do
            local obj = Game.Object(i)
            if obj.name == "Feather" --[[ and obj.owner == myHero (returns nil  --- BROKEN) ]] and obj.health > 0 then
                table.insert(feathers, obj)
            end
            time = os.clock()
        end
        if #feathers > 0 then
            SetRealFeathers()
        end
    end
end

function Xayah:Draw()
    local Q = self.Menu.Misc.Qrange:Value()
    local textPos = myHero.pos:To2D()
    local f = 0
    if #feathers ~= 0 and self.Menu.Draw.F:Value() then
        for k, feather in pairs(feathers) do
            DrawLine3D(Vector(feather.pos), Vector(myHero.pos), 1)
            f = f + 1
        end
        Draw.Text("Feathers = " .. f, 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 000, 255, 000))
    end
    if self.Menu.Draw.Q:Value() then
        Draw.Circle(Vector(myHero.pos), Q)
    end
    if self.Menu.Draw.R:Value() then
        Draw.Circle(Vector(myHero.pos), 1000)
    end
end

function OnLoad()
    Xayah()
end
