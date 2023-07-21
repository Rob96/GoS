class "ManlyTwistedFate"
require("DamageLib")

local ToSelect = "NONE"
local WName = "NONE"
local lastpick = 0
local _EnemyHeroes

local intToMode = {
    [0] = "",
    [1] = "Combo",
    [2] = "Harass",
    [3] = "LastHit",
    [4] = "Clear"
}

local HKITEM = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
    [ITEM_7] = HK_ITEM_7
}

local function Ready(spell)
    return Game.CanUseSpell(spell) == 0
end

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

local function EnableAttack(bool)
    _G.SDK.Orbwalker:SetAttack(bool)
end

function ManlyTwistedFate:__init()
    if myHero.charName ~= "TwistedFate" then
        return
    end
    PrintChat("ManlyTwistedFate Loaded")
    self:LoadSpells()
    self:LoadMenu()
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
end

function ManlyTwistedFate:LoadSpells()
    Q = {delay = 0.25, range = 1450, speed = 1000}
    Qdata = {speed = Q.speed, delay = Q.delay, range = Q.range}
  --  Qspell = Prediction:SetSpell(Qdata, TYPE_LINE, true)
end

function ManlyTwistedFate:HasBuff(unit, buffname)
    for K, Buff in pairs(self:GetBuffs(unit)) do
        if Buff.name:lower() == buffname:lower() then
            return true
        end
    end
    return false
end

function ManlyTwistedFate:GetBuffs(unit)
    self.T = {}
    for i = 0, unit.buffCount do
        local Buff = unit:GetBuff(i)
        if Buff.count > 0 then
            table.insert(self.T, Buff)
        end
    end
    return self.T
end

function ManlyTwistedFate:GetBuffData(unit, buffname)
    for i = 0, unit.buffCount do
        local Buff = unit:GetBuff(i)
        if Buff.name:lower() == buffname:lower() and Buff.count > 0 then
            return Buff
        end
    end
    return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}
end

function GetEnemyHeroes()
    if _EnemyHeroes then
        return _EnemyHeroes
    end
    _EnemyHeroes = {}
    for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        if unit.isEnemy then
            table.insert(_EnemyHeroes, unit)
        end
    end
    return _EnemyHeroes
end

function EAround(pos, range)
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
        if Hero and Hero.team ~= myHero.team and not Hero.dead and pos:DistanceTo(Hero.pos) <= range then
            return Hero
        end
    end
end

function PercentHP(target)
    return 100 * target.health / target.maxHealth
end

function PercentMP(target)
    return 100 * target.mana / target.maxMana
end

local function Qdmg(target)
    local level = myHero:GetSpellData(_Q).level
    return CalcMagicalDamage(myHero, target, (15 + 45 * level + myHero.ap * 0.8))
end

function ManlyTwistedFate:LoadMenu()
    self.Menu = MenuElement({type = MENU, id = "ManlyTwistedFate", name = "ManlyTwistedFate"})
    -- Combo
    self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Combo:MenuElement(
        {id = "QMin", name = "Min range for Q in combo", value = 0, min = 0, max = 1250, step = 1}
    )
    self.Menu.Combo:MenuElement(
        {id = "QMax", name = "Max range for Q in combo", value = 500, min = 0, max = 1250, step = 1}
    )
    self.Menu.Combo:MenuElement(
        {id = "QMana", name = "Min mana for Q in combo in %", value = 30, min = 0, max = 100, step = 1}
    )
    --self.Menu.Combo:MenuElement({id = "QChance", name = "Q hitchance in Combo", value = 0.1, min = 0, max = 1, step = 0.01})
    self.Menu.Combo:MenuElement({type = SPACE})
    self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = true})
    self.Menu.Combo:MenuElement({id = "GoldMana", name = "Min mana for Gold in %", value = 30, min = 0, max = 100})
    -- Clear
    self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear"})
    self.Menu.Clear:MenuElement({id = "W", name = "Use W", value = true})
    self.Menu.Clear:MenuElement({id = "RedMana", name = "Min mana for Red in %", value = 30, min = 0, max = 100})
    --[[Misc]]
    self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    self.Menu.Misc:MenuElement({id = "GoldR", name = "Gold card on ult", value = true})
    self.Menu.Misc:MenuElement({id = "R", name = "Ult Key", key = 99})
    self.Menu.Misc:MenuElement({type = SPACE})
    self.Menu.Misc:MenuElement({id = "QCC", name = "Use Q on CC", value = true})
    self.Menu.Misc:MenuElement({id = "QKS", name = "Use Q for ks", value = true})
    self.Menu.Misc:MenuElement({id = "QCCMana", name = "Min mana for Q on CC in %", value = 30, min = 0, max = 100})
    self.Menu.Misc:MenuElement({id = "QKSMana", name = "Min mana for Q killsteal in %", value = 0, min = 0, max = 100})
    --self.Menu.Misc:MenuElement({id = "QCCChance", name = "Hitchance for Q on CC", value = 0, min = 0.01, max = 1, step = 0.01})
    --self.Menu.Misc:MenuElement({id = "QKSChance", name = "Hitchance for Q on KS", value = 0, min = 0.01, max = 1, step = 0.01})
    self.Menu.Misc:MenuElement({type = SPACE})
    self.Menu.Misc:MenuElement({id = "lvEnabled", name = "Enable AutoLeveler", value = true})
    self.Menu.Misc:MenuElement({id = "Block", name = "Block on Level 1", value = true})
    self.Menu.Misc:MenuElement(
        {
            id = "Order",
            name = "Skill Priority",
            drop = {
                "[Q] - [W] - [E] > Max [Q]",
                "[Q] - [E] - [W] > Max [Q]",
                "[W] - [Q] - [E] > Max [W]",
                "[W] - [E] - [Q] > Max [W]",
                "[E] - [Q] - [W] > Max [E]",
                "[E] - [W] - [Q] > Max [E]",
                "ADTF"
            }
        }
    )
    self.Menu:MenuElement({type = MENU, id = "CardPick", name = "Card Picker"})
    self.Menu.CardPick:MenuElement({id = "Gold", name = "Gold key", key = 85})
    self.Menu.CardPick:MenuElement({id = "Red", name = "Red key", key = 84})
    self.Menu.CardPick:MenuElement({id = "Blue", name = "Blue key", key = 83})
    --ITEM ACTIVATOR
    self.Menu:MenuElement({type = MENU, id = "Activator", name = "Activator"})
    self.Menu.Activator:MenuElement({type = MENU, id = "Items", name = "Items"})
    self.Menu.Activator.Items:MenuElement({id = "QSS", name = "QSS / Scimitar / Dawn", value = true})
    self.Menu.Activator.Items:MenuElement({type = MENU, id = "QSSS", name = "QSS Settings"})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Blind", name = "Blind", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Charm", name = "Charm", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Supression", name = "Supression", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Flee", name = "Flee", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Fear", name = "Fear", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Slow", name = "Slow", value = false})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Root", name = "Root/Snare", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Poly", name = "Polymorph", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Silence", name = "Silence", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Stun", name = "Stun", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Taunt", name = "Taunt", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Knockup", name = "Knockup", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Knockback", name = "Knockback", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Disarm", name = "Disarm", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Drowsy", name = "Drowsy", value = true})
    self.Menu.Activator.Items.QSSS:MenuElement({id = "Asleep", name = "Asleep", value = true})
    --SUMMONER ACTIVATOR
    self.Menu.Activator:MenuElement({type = MENU, id = "Summoners", name = "Summoner Spells"})
    DelayAction(
        function()
            if
                myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" or
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal"
             then
                self.Menu.Activator.Summoners:MenuElement({id = "Heal", name = "Auto Heal", value = true})
                self.Menu.Activator.Summoners:MenuElement(
                    {id = "HealHP", name = "Health % to Heal", value = 25, min = 0, max = 100}
                )
            end
        end,
        2
    )
    DelayAction(
        function()
            if
                myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" or
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier"
             then
                self.Menu.Activator.Summoners:MenuElement({id = "Barrier", name = "Auto Barrier", value = true})
                self.Menu.Activator.Summoners:MenuElement(
                    {id = "BarrierHP", name = "Health % to Barrier", value = 25, min = 0, max = 100}
                )
            end
        end,
        2
    )
    DelayAction(
        function()
            if
                myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" or
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerDot"
             then
                self.Menu.Activator.Summoners:MenuElement({id = "Ignite", name = "Ignite in Combo", value = true})
                self.Menu.Activator.Summoners:MenuElement(
                    {id = "IgniteHP", name = "Enemy Hp for Ignite", value = 30, min = 0, max = 100, step = 1}
                )
            end
        end,
        2
    )
    DelayAction(
        function()
            if
                myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" or
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust"
             then
                self.Menu.Activator.Summoners:MenuElement({id = "Exh", name = "Exhaust in Combo", value = true})
                self.Menu.Activator.Summoners:MenuElement(
                    {id = "ExhaustHp", name = "Enemy Hp for Exhaust", value = 30, min = 0, max = 100, step = 1}
                )
            end
        end,
        2
    )
    DelayAction(
        function()
            if
                myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" or
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost"
             then
                self.Menu.Activator.Summoners:MenuElement({id = "Cleanse", name = "Auto Cleanse", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Blind", name = "Blind", value = false})
                self.Menu.Activator.Summoners:MenuElement({id = "Charm", name = "Charm", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Supression", name = "Supression", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Flee", name = "Flee", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Fear", name = "Fear", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Slow", name = "Slow", value = false})
                self.Menu.Activator.Summoners:MenuElement({id = "Root", name = "Root/Snare", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Poly", name = "Polymorph", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Silence", name = "Silence", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Stun", name = "Stun", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Taunt", name = "Taunt", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Knockup", name = "Knockup", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Knockback", name = "Knockback", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Disarm", name = "Disarm", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Drowsy", name = "Drowsy", value = true})
                self.Menu.Activator.Summoners:MenuElement({id = "Asleep", name = "Asleep", value = true})
            end
        end,
        2
    )
    self.Menu.Activator.Summoners:MenuElement(
        {type = SPACE, id = "Note", name = "Note: Ghost/TP/Flash/smite is not supported"}
    )
end

function ManlyTwistedFate:AutoLevel()
    if self.Menu.Misc.lvEnabled:Value() == false then
        return
    end
    local Sequence = {
        [1] = {
            HK_Q,
            HK_W,
            HK_E,
            HK_Q,
            HK_Q,
            HK_R,
            HK_Q,
            HK_W,
            HK_Q,
            HK_W,
            HK_R,
            HK_W,
            HK_W,
            HK_E,
            HK_E,
            HK_R,
            HK_E,
            HK_E
        },
        [2] = {
            HK_Q,
            HK_E,
            HK_W,
            HK_Q,
            HK_Q,
            HK_R,
            HK_Q,
            HK_E,
            HK_Q,
            HK_E,
            HK_R,
            HK_E,
            HK_E,
            HK_W,
            HK_W,
            HK_R,
            HK_W,
            HK_W
        },
        [3] = {
            HK_W,
            HK_Q,
            HK_E,
            HK_W,
            HK_W,
            HK_R,
            HK_W,
            HK_Q,
            HK_W,
            HK_Q,
            HK_R,
            HK_Q,
            HK_Q,
            HK_E,
            HK_E,
            HK_R,
            HK_E,
            HK_E
        },
        [4] = {
            HK_W,
            HK_E,
            HK_Q,
            HK_W,
            HK_W,
            HK_R,
            HK_W,
            HK_E,
            HK_W,
            HK_E,
            HK_R,
            HK_E,
            HK_E,
            HK_Q,
            HK_Q,
            HK_R,
            HK_Q,
            HK_Q
        },
        [5] = {
            HK_E,
            HK_Q,
            HK_W,
            HK_E,
            HK_E,
            HK_R,
            HK_E,
            HK_Q,
            HK_E,
            HK_Q,
            HK_R,
            HK_Q,
            HK_Q,
            HK_W,
            HK_W,
            HK_R,
            HK_W,
            HK_W
        },
        [6] = {
            HK_E,
            HK_W,
            HK_Q,
            HK_E,
            HK_E,
            HK_R,
            HK_E,
            HK_W,
            HK_E,
            HK_W,
            HK_R,
            HK_W,
            HK_W,
            HK_Q,
            HK_Q,
            HK_R,
            HK_Q,
            HK_Q
        },
        [7] = {
            HK_W,
            HK_E,
            HK_W,
            HK_E,
            HK_W,
            HK_R,
            HK_E,
            HK_W,
            HK_E,
            HK_W,
            HK_R,
            HK_E,
            HK_Q,
            HK_Q,
            HK_Q,
            HK_R,
            HK_Q,
            HK_Q
        }
    }
    local Slot = nil
    local Tick = 0
    local SkillPoints =
        myHero.levelData.lvl -
        (myHero:GetSpellData(_Q).level + myHero:GetSpellData(_W).level + myHero:GetSpellData(_E).level +
            myHero:GetSpellData(_R).level)
    local level = myHero.levelData.lvl
    local Check = Sequence[self.Menu.Misc.Order:Value()][level - SkillPoints + 1]
    if SkillPoints > 0 then
        if self.Menu.Misc.Block:Value() and level == 1 then
            return
        end
        if GetTickCount() - Tick > 800 and Check ~= nil then
            Control.KeyDown(HK_LUS)
            Control.KeyDown(Check)
            Slot = Check
            Tick = GetTickCount()
        end
    end
    if Control.IsKeyDown(HK_LUS) then
        Control.KeyUp(HK_LUS)
    end
    if Slot and Control.IsKeyDown(Slot) then
        Control.KeyUp(Slot)
    end
end

function ManlyTwistedFate:Summoners()
    local target = GetTarget(1200)
    if target == nil then
        return
    end
    if GetMode() == "Combo" then
        if
            myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" or
                myHero:GetSpellData(SUMMONER_2).name == "SummonerDot"
         then
            if self.Menu.Activator.Summoners.Ignite:Value() then
                if
                    myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and
                        self.Menu.Activator.Summoners.IgniteHP:Value() / 100 >= target.health / target.maxHealth and
                        myHero.pos:DistanceTo(target.pos) < 600
                 then
                    Control.CastSpell(HK_SUMMONER_1, target)
                elseif
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_1) and
                        self.Menu.Activator.Summoners.IgniteHP:Value() / 100 >= target.health / target.maxHealth and
                        myHero.pos:DistanceTo(target.pos) < 600
                 then
                    Control.CastSpell(HK_SUMMONER_2, target)
                end
            end
        end

        if
            myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" or
                myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust"
         then
            if self.Menu.Activator.Summoners.Exh:Value() then
                if
                    myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) and
                        self.Menu.Activator.Summoners.ExhaustHp:Value() / 100 >= target.health / target.maxHealth and
                        myHero.pos:DistanceTo(target.pos) < 650
                 then
                    Control.CastSpell(HK_SUMMONER_1, target)
                elseif
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_1) and
                        self.Menu.Activator.Summoners.ExhaustHp:Value() / 100 >= target.health / target.maxHealth and
                        myHero.pos:DistanceTo(target.pos) < 650
                 then
                    Control.CastSpell(HK_SUMMONER_2, target)
                end
            end
        end

        if
            myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" or
                myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal"
         then
            if self.Menu.Activator.Summoners.Heal:Value() then
                if
                    myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) and
                        PercentHP(myHero) < self.Menu.Activator.Summoners.HealHP:Value()
                 then
                    Control.CastSpell(HK_SUMMONER_1)
                elseif
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_1) and
                        PercentHP(myHero) < self.Menu.Activator.Summoners.HealHP:Value()
                 then
                    Control.CastSpell(HK_SUMMONER_2)
                end
            end
        end

        if
            myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" or
                myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier"
         then
            if self.Menu.Activator.Summoners.Barrier:Value() then
                if
                    myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) and
                        PercentHP(myHero) < self.Menu.Activator.Summoners.BarrierHP:Value()
                 then
                    Control.CastSpell(HK_SUMMONER_1)
                elseif
                    myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_1) and
                        PercentHP(myHero) < self.Menu.Activator.Summoners.BarrierHP:Value()
                 then
                    Control.CastSpell(HK_SUMMONER_2)
                end
            end
        end

        if
            myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" or
                myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost"
         then
            if self.Menu.Activator.Summoners.Cleanse:Value() then
                for i = 0, myHero.buffCount do
                    local buff = myHero:GetBuff(i)
                    if buff.count > 0 then
                        if
                            (buff.type == 5 and self.Menu.Activator.Summoners.Stun:Value()) or
                                (buff.type == 7 and self.Menu.Activator.Summoners.Silence:Value()) or
                                (buff.type == 8 and self.Menu.Activator.Summoners.Taunt:Value()) or
                                (buff.type == 10 and self.Menu.Activator.Summoners.Poly:Value()) or
                                (buff.type == 11 and self.Menu.Activator.Summoners.Slow:Value()) or
                                (buff.type == 12 and self.Menu.Activator.Summoners.Root:Value()) or
                                (buff.type == 22 and self.Menu.Activator.Summoners.Fear:Value()) or
                                (buff.type == 23 and self.Menu.Activator.Summoners.Charm:Value()) or
                                (buff.type == 25 and self.Menu.Activator.Summoners.Supression:Value()) or
                                (buff.type == 26 and self.Menu.Activator.Summoners.Blind:Value()) or
                                (buff.type == 29 and self.Menu.Activator.Summoners.Flee:Value()) or
                                (buff.type == 30 and self.Menu.Activator.Summoners.Knockup:Value()) or
                                (buff.type == 31 and self.Menu.Activator.Summoners.Knockback:Value()) or
                                (buff.type == 32 and self.Menu.Activator.Summoners.Disarm:Value()) or
                                (buff.type == 34 and self.Menu.Activator.Summoners.Drowsy:Value()) or
                                (buff.type == 35 and self.Menu.Activator.Summoners.Asleep:Value())
                         then
                            if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" and Ready(SUMMONER_1) then
                                Control.CastSpell(HK_SUMMONER_1)
                            elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" and Ready(SUMMONER_2) then
                                Control.CastSpell(HK_SUMMONER_2)
                            end
                        end
                    end
                end
            end
        end
    end
end

function ManlyTwistedFate:Activator()
    local target = GetTarget(2500)
    local items = {}
    for slot = ITEM_1, ITEM_6 do
        local id = myHero:GetItemData(slot).itemID
        if id > 0 then
            items[id] = slot
        end
    end
    --COMBO MODE ACTIVATOR
    if target == nil then
        return
    end
    if GetMode() == "Combo" then
        local QSS = items[3140] or items[3139] or items[6035] --QSS - Scimitar - Dawn
        if QSS then
            if self.Menu.Activator.Items.QSS:Value() and myHero:GetSpellData(QSS).currentCd == 0 then
                for i = 0, myHero.buffCount do
                    local buff = myHero:GetBuff(i)
                    if buff.count > 0 then
                        if
                            (buff.type == 5 and self.Menu.Activator.Items.QSSS.Stun:Value()) or
                                (buff.type == 7 and self.Menu.Activator.Items.QSSS.Silence:Value()) or
                                (buff.type == 8 and self.Menu.Activator.Items.QSSS.Taunt:Value()) or
                                (buff.type == 10 and self.Menu.Activator.Items.QSSS.Poly:Value()) or
                                (buff.type == 11 and self.Menu.Activator.Items.QSSS.Slow:Value()) or
                                (buff.type == 12 and self.Menu.Activator.Items.QSSS.Root:Value()) or
                                (buff.type == 22 and self.Menu.Activator.Items.QSSS.Fear:Value()) or
                                (buff.type == 23 and self.Menu.Activator.Items.QSSS.Charm:Value()) or
                                (buff.type == 25 and self.Menu.Activator.Items.QSSS.Supression:Value()) or
                                (buff.type == 26 and self.Menu.Activator.Items.QSSS.Blind:Value()) or
                                (buff.type == 29 and self.Menu.Activator.Items.QSSS.Flee:Value()) or
                                (buff.type == 30 and self.Menu.Activator.Items.QSSS.Knockup:Value()) or
                                (buff.type == 31 and self.Menu.Activator.Items.QSSS.Knockback:Value()) or
                                (buff.type == 32 and self.Menu.Activator.Items.QSSS.Disarm:Value()) or
                                (buff.type == 34 and self.Menu.Activator.Items.QSSS.Drowsy:Value()) or
                                (buff.type == 35 and self.Menu.Activator.Items.QSSS.Asleep:Value())
                         then
                            Control.CastSpell(HKITEM[QSS])
                        end
                    end
                end
            end
        end
    end
end

function ManlyTwistedFate:Tick()
    if myHero.dead then
        return
    end
    local Mode = GetMode()
    self:CardPick()
    self:Misc()
    self:AutoLevel()
    self:Activator()
    self:Summoners()

    if Mode == "Combo" then
        self:Combo()
    end
end

function ManlyTwistedFate:Combo()
    local target = EAround(myHero.pos, 1300)
    local QMin = self.Menu.Combo.QMin:Value()
    local QMax = self.Menu.Combo.QMax:Value()
    local QMana = self.Menu.Combo.QMana:Value() / 100
    --   local QChance = self.Menu.Combo.QChance:Value()
    if target == nil then
        return
    end

    if
        self.Menu.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) >= QMin and
            myHero.pos:DistanceTo(target.pos) <= QMax and
            myHero.mana / myHero.maxMana >= QMana
     then
        -- local pred = Qspell:GetPrediction(target,myHero.pos)
        --if pred == nil then return end
        --if pred and pred.hitChance >= QChance then
        EnableOrb(false)
        Control.CastSpell(HK_Q, target.pos)
        --EnableOrb(true)
        DelayAction(
            function()
                EnableOrb(true)
            end,
            0.28
        )
    end
    --end
end

function ManlyTwistedFate:Misc()
    local target = EAround(myHero.pos, 1300)
    --local QCCChance = self.Menu.Misc.QCCChance:Value()
    --  local QKSChance = self.Menu.Misc.QKSChance:Value()

    if target == nil then
      return
  end

    --Q ON CC
    if self.Menu.Misc.QCC:Value() and Ready(_Q) and myHero.mana / myHero.maxMana >= self.Menu.Misc.QCCMana:Value() / 100 then
        for x = 0, target.buffCount do
            local buff = target:GetBuff(x)
            if
                buff and
                    (buff.type == 5 or buff.type == 8 or buff.type == 10 or buff.type == 11 or buff.type == 12 or
                        buff.type == 22 or
                        buff.type == 23 or
                        buff.type == 25 or
                        buff.type == 29 or
                        buff.type == 30 or
                        buff.type == 33 or
                        buff.type == 35 or
                        buff.name == "recall") and
                    buff.count > 0
             then
              if target == nil then
                return
            end
                -- local pred = Qspell:GetPrediction(target,myHero.pos)
                -- if pred == nil then return end
                --if pred and pred.hitChance >= QCCChance then
                EnableOrb(false)
                Control.CastSpell(HK_Q, target.pos)
                DelayAction(
                    function()
                        EnableOrb(true)
                    end,
                    0.28
                )
            end
            --   end
        end
    end

    --Q ON KS

    if self.Menu.Misc.QKS:Value() and Ready(_Q) and myHero.mana / myHero.maxMana >= self.Menu.Misc.QKSMana:Value() / 100 then
        if Qdmg(target) > target.health then
          if target == nil then
            return
        end
            -- local pred = Qspell:GetPrediction(target,myHero.pos)
            --  if pred == nil then return end
            --  if pred and pred.hitChance >= QKSChance then
            EnableOrb(false)
            Control.CastSpell(HK_Q, target.pos)
            DelayAction(
                function()
                    EnableOrb(true)
                end,
                0.28
            )
        end
    -- end
    end
end

function ManlyTwistedFate:CardPick()
    local Mode = GetMode()
    local WName = myHero:GetSpellData(_W).name
    local WStatus = myHero:GetSpellData(_W).toggleState

    if Mode == "Combo" then
        local target = GetTarget(myHero.range + 300)
        if self.Menu.Combo.W:Value() then
            if (Ready(_W)) and WName == "PickACard" and target and GetTickCount() > lastpick + 500 then
                if myHero.mana / myHero.maxMana >= self.Menu.Combo.GoldMana:Value() / 100 then
                    ToSelect = "GOLD"
                else
                    ToSelect = "BLUE"
                end
                if ToSelect ~= "NONE" and (Ready(_W)) then
                    EnableOrb(false)
                    Control.CastSpell(HK_W)
                    EnableOrb(true)
                    lastpick = GetTickCount()
                end
            end
        end
    end

    if Mode == "Clear" then
        if self.Menu.Clear.W:Value() then
            if (Ready(_W)) and WName == "PickACard" and GetTickCount() > lastpick + 500 then
                for i = 1, Game.MinionCount(1000) do
                    local target = Game.Minion(i)
                    if
                        target.team == 200 and myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 or
                            target.team == 300 and myHero.pos:DistanceTo(target.pos) <= myHero.range + 150
                     then
                        if myHero.mana / myHero.maxMana >= self.Menu.Clear.RedMana:Value() / 100 then
                            ToSelect = "RED"
                        else
                            ToSelect = "BLUE"
                        end
                        if (Ready(_W)) and ToSelect ~= "NONE" then
                            EnableOrb(false)
                            Control.CastSpell(HK_W)
                            EnableOrb(true)
                            lastpick = GetTickCount()
                        end
                    end
                end
            end
        end
    end

    if (Ready(_W)) and WName == "PickACard" and GetTickCount() > lastpick + 500 then
        ToSelect = "NONE"
        if self.Menu.CardPick.Gold:Value() then
            ToSelect = "GOLD"
        elseif self.Menu.CardPick.Red:Value() then
            ToSelect = "RED"
        elseif self.Menu.CardPick.Blue:Value() then
            ToSelect = "BLUE"
        end
        if ToSelect ~= "NONE" and (Ready(_W)) then
            EnableOrb(false)
            Control.CastSpell(HK_W)
            EnableOrb(true)
            lastpick = GetTickCount()
        end
    end

    if self.Menu.Misc.GoldR:Value() and self:HasBuff(myHero, "Gate") then
        if (Ready(_W)) and WName == "PickACard" and GetTickCount() > lastpick + 500 then
            ToSelect = "GOLD"
            EnableOrb(false)
            Control.CastSpell(HK_W)
            EnableOrb(true)
            lastpick = GetTickCount()
        end
    end

    if (WStatus == 2) then
        ToSelect = "NONE"
    end

    if
        (Ready(_W)) and ((ToSelect == "GOLD" or self.Menu.CardPick.Gold:Value()) and WName == "GoldCardLock") or
            (Ready(_W)) and ((ToSelect == "RED" or self.Menu.CardPick.Red:Value()) and WName == "RedCardLock") or
            (Ready(_W)) and ((ToSelect == "BLUE" or self.Menu.CardPick.Blue:Value()) and WName == "BlueCardLock")
     then
        EnableOrb(false)
        Control.CastSpell(HK_W)
        EnableOrb(true)
    end
end

function OnLoad()
    ManlyTwistedFate()
end

--Credits to Trus for card stuffs, Romanov for activator and general help, prob some others /s
