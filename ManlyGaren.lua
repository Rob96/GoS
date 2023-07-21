class "ManlyGaren"
require("DamageLib")

local intToMode = {
    [0] = "",
    [1] = "Combo",
    [2] = "Harass",
    [3] = "Lasthit",
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
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
        return "Lasthit"
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
        return "Flee"
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
--[[ 

local function NoPotion()
  for i = 0, 63 do
    local buff = myHero:GetBuff(i)
    if buff.type == 13 and Game.Timer() < buff.expireTime then
      return false
    end
  end
  return true
end ]]
function ManlyGaren:__init()
    if myHero.charName ~= "Garen" then
        return
    end
    PrintChat("ManlyGaren Loaded")
    self:LoadMenu()
    Callback.Add(
        "Tick",
        function()
            self:Tick()
        end
    )
    --Callback.Add("Draw", function() self:Draw() end)
end

function ManlyGaren:HasBuff(unit, buffname)
    for K, Buff in pairs(self:GetBuffs(unit)) do
        if Buff.name:lower() == buffname:lower() then
            return true
        end
    end
    return false
end

function ManlyGaren:GetBuffs(unit)
    self.T = {}
    for i = 0, unit.buffCount do
        local Buff = unit:GetBuff(i)
        if Buff.count > 0 then
            table.insert(self.T, Buff)
        end
    end
    return self.T
end

function ManlyGaren:GetBuffData(unit, buffname)
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

function EnemiesAround(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)
        if Hero and Hero.team ~= myHero.team and not Hero.dead and pos:DistanceTo(Hero.pos) <= range then
            Count = Count + 1
        end
    end
    return Count
end

function MinionsAround(pos, range)
    local Count = 0
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if Minion and Minion.team ~= myHero.team and not Minion.dead and pos:DistanceTo(Minion.pos) <= range then
            Count = Count + 1
        end
    end
    return Count
end

function MonstersAround(pos, range)
    local Count = 0
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if
            Minion and Minion.team ~= myHero.team and not Minion.dead and pos:DistanceTo(Minion.pos) <= range and
                Minion.team == 300
         then
            Count = Count + 1
        end
    end
    return Count
end

function GetMinion(pos, range)
    for i = 1, Game.MinionCount(range) do
        local target = Game.Minion(i)
        if target.team == 200 or target.team == 300 then
            return target
        end
    end
end

function PercentHP(target)
    return 100 * target.health / target.maxHealth
end

function ManlyGaren:Rdmg(target)
    local Rdamage = 0
    local level = myHero:GetSpellData(_R).level
    Rdamage = ({140, 300, 450})[level] + ({25, 30, 35})[level] / 100 * (target.maxHealth - target.health)
    return Rdamage
end

local function Qdmg(target)
    local level = myHero:GetSpellData(_Q).level
    return CalcPhysicalDamage(myHero, target, (30 * level + myHero.totalDamage * 0.5 + myHero.totalDamage))
end

function ManlyGaren:LoadMenu()
    self.Menu = MenuElement({type = MENU, id = "ManlyGaren", name = "ManlyGaren"})
    -- Combo
    self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
    self.Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Combo:MenuElement({id = "QReset", name = "Only Q as auto reset", value = false})
    self.Menu.Combo:MenuElement({type = SPACE, name = "Note: Disables other Q logic"})
    self.Menu.Combo:MenuElement({id = "QClose", name = "Use Q to gapclose?", value = true})
    self.Menu.Combo:MenuElement(
        {id = "QCloseRange", name = "Max range to gapclose", value = 300, min = 0, max = 1500, step = 25}
    )
    self.Menu.Combo:MenuElement({id = "W", name = "Use W", value = false})
    self.Menu.Combo:MenuElement({id = "E", name = "Use E", value = true})
    self.Menu.Combo:MenuElement({id = "R", name = "R on kill", value = true})
    -- Clear
    self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear"})
    self.Menu.Clear:MenuElement({id = "Q", name = "Use Q", value = true})
    self.Menu.Clear:MenuElement({id = "W", name = "Use W", value = false})
    self.Menu.Clear:MenuElement({id = "E", name = "Use E", value = true})
    self.Menu.Clear:MenuElement({id = "EMin", name = "Min lane-minions for E", value = 3, min = 1, max = 6})
    -- Lasthit
    self.Menu:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit"})
    self.Menu.Lasthit:MenuElement({id = "Q", name = "Q", value = true})

    --[[Misc]]
    self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    self.Menu.Misc:MenuElement({id = "Q", name = "Q Flee", value = true})
    self.Menu.Misc:MenuElement({id = "CancleE", name = "Auto Cancle E"})
    self.Menu.Misc:MenuElement(
        {id = "CancleERange", name = "Range to enemy hero E cancle", value = 500, min = 0, max = 1000, step = 25}
    )
    self.Menu.Misc:MenuElement(
        {id = "CancleEMinion", name = "Min lane-minions cancle E", value = 1, min = 0, max = 6, step = 1}
    )
    --self.Menu.Misc:MenuElement({id = "W", name = "Auto W on big hits and cc?", value = false})
    self.Menu.Misc:MenuElement({type = SPACE})
    self.Menu.Misc:MenuElement({id = "RKS", name = "Auto KS R", value = true})
    --self.Menu.Misc:MenuElement({id = "Rdmg", name = "Draw R damage on champion", value = true})
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
                "[E] - [W] - [Q] > Max [E]"
            }
        }
    )

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

function ManlyGaren:AutoLevel()
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

function ManlyGaren:Summoners()
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

function ManlyGaren:Activator()
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

function ManlyGaren:Tick()
    if myHero.dead then
        return
    end
    local target = GetTarget(1500)
    local Mode = GetMode()
    self:Misc()
    self:AutoLevel()
    self:Activator()
    self:Summoners()

    if Mode == "Combo" then
        self:Combo()
    end
    if Mode == "Clear" then
        self:Clear()
    end
    if Mode == "Lasthit" then
        self:Lasthit()
    end
    if Mode == "Flee" then
        self:Flee()
    end
end

function ManlyGaren:Combo()
    if myHero.dead then
        return
    end
    local target = GetTarget(1500)
    local MinQ = self.Menu.Combo.QCloseRange:Value()
    if target == nil then
        return
    end

    if self.Menu.Combo.Q:Value() and Ready(_Q) then
        if self.Menu.Combo.QReset:Value() then
            if myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 and myHero.attackData.state == 3 then
                EnableOrb(false)
                Control.CastSpell(HK_Q)
                Control.Attack(target)
                DelayAction(
                    function()
                        EnableOrb(true)
                    end,
                    0.15
                )
            end
        elseif self.Menu.Combo.QClose:Value() then
            if myHero.pos:DistanceTo(target.pos) <= MinQ then
                Control.CastSpell(HK_Q)
            end
        elseif myHero.pos:DistanceTo(target.pos) <= myHero.range + 150 then
            Control.CastSpell(HK_Q)
        end
    end

    if self.Menu.Combo.W:Value() and Ready(_W) then
        if myHero.pos:DistanceTo(target.pos) <= 300 then
            Control.CastSpell(HK_W)
        end
    end

    if self.Menu.Combo.E:Value() and Ready(_E) and Ready(_Q) == false then
        if self:HasBuff(myHero, "GarenQ") == false and self:HasBuff(myHero, "GarenE") == false then
            if myHero.pos:DistanceTo(target.pos) <= 350 then
                Control.CastSpell(HK_E)
            end
        end
    end

    if self.Menu.Combo.R:Value() and Ready(_R) then
        if self:Rdmg(target) > target.health and myHero.pos:DistanceTo(target.pos) <= 400 then
            EnableOrb(false)
            Control.CastSpell(HK_R, target)
            DelayAction(
                function()
                    EnableOrb(true)
                end,
                0.28
            )
        end
    end
end

function ManlyGaren:Clear()
    local Emobs = self.Menu.Clear.EMin:Value()

    if self.Menu.Clear.Q:Value() and Ready(_Q) then
        if MinionsAround(myHero.pos, 250) >= 1 and myHero.attackData.state == 3 then
            Control.CastSpell(HK_Q)
        end
    end

    if self.Menu.Clear.W:Value() and Ready(_W) then
        if MonstersAround(myHero.pos, 200) >= 1 then
            Control.CastSpell(HK_W)
        end
    end

    if self.Menu.Clear.E:Value() and Ready(_E) and not self:HasBuff(myHero, "GarenE") then
        if MinionsAround(myHero.pos, 350) >= Emobs or MonstersAround(myHero.pos, 350) >= 1 then
            Control.CastSpell(HK_E)
        end
    end
end

function ManlyGaren:Lasthit()
    if self.Menu.Lasthit.Q:Value() and Ready(_Q) then
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
                        0.3
                    )
                end
            end
        end
    end
end

function ManlyGaren:Misc()
    local ERange = self.Menu.Misc.CancleERange:Value()
    local target = EAround(myHero.pos, 400)

    if self:HasBuff(myHero, "GarenE") == true then
        EnableAttack(false)
    else
        EnableAttack(true)
    end

    if self.Menu.Misc.CancleE:Value() and Ready(_E) then
        if self:HasBuff(myHero, "GarenE") then
            if
                EnemiesAround(myHero.pos, ERange) < 1 and MinionsAround(myHero.pos, ERange) < 1 and
                    MonstersAround(myHero.pos, ERange) == 0
             then
                Control.CastSpell(HK_E)
            end
        end
    end

    if self.Menu.Misc.RKS:Value() and Ready(_R) then
        if target == nil then
            return
        end
        if self:Rdmg(target) > target.health and myHero.pos:DistanceTo(target.pos) <= 400 then
            EnableOrb(false)
            Control.CastSpell(HK_R, target)
            DelayAction(
                function()
                    EnableOrb(true)
                end,
                0.28
            )
        end
    end
end

function ManlyGaren:Flee()
    if self.Menu.Misc.Q:Value() and Ready(_Q) then
        Control.CastSpell(HK_Q)
    end
end

--[[     function ManlyGaren:Draw()
      if self.Menu.Misc.Rdmg:Value() and Ready(_R) then
        for i = 1, Game.HeroCount() do
          local target = Game.Hero(i)
          if target and target.isEnemy and not target.dead and target.visible then
            local barPos = target.hpBar
            local textPos = myHero.pos:To2D()
            local health = target.health
            local maxHealth = target.maxHealth
            local Rdmg = self:Rdmg(target)
            if Rdmg < target.health then
              Draw.Rect(barPos.x + (( (health - Rdmg) / maxHealth) * 100) + 25, barPos.y - 13, (Rdmg / maxHealth )*100, 10, Draw.Color(255, 200, 200, 25))
            else
              Draw.Rect(barPos.x + 20 , barPos.y - 13 ,((target.health/target.maxHealth)*100),10, Draw.Color(150, 255, 255, 000))
              Draw.Text("Execute", 20, barPos.x + 20, barPos.y + 5, Draw.Color(255, 255, 000, 000))
            end
          end
        end
      end

    end ]]
function OnLoad()
    ManlyGaren()
end
