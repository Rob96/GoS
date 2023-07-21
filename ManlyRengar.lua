---------------------------------------------------------------------------------------------------------------------------------------------------
if myHero.charName ~= "Rengar" then
    PrintChat("You aint Playin knife cat, Shutting down")
    return
 end
 ---------------------------------------------------------------------------------------------------------------------------------------------------
 class "Rengar"
 require "DamageLib"
 
 local _shadow = myHero.pos
 ---------------------------------------------------------------------------------------------------------------------------------------------------
 function Rengar:__init()
    PrintChat("ManlyRengar Enabled")
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
 ---------------------------------------------------------------------------------------------------------------------------------------------------
 local function GetTarget(range)
    local target = nil
    target = _G.SDK.TargetSelector:GetTarget(range)
    return target
 end
 ---------------------------------------------------------------------------------------------------------------------------------------------------
 local function Ready(spell)
    return Game.CanUseSpell(spell) == 0
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
    ---------------------------------------------------------------------------------------------------------------------------------------------------
    local function EnableOrb(bool)
       _G.SDK.Orbwalker:SetMovement(bool)
       _G.SDK.Orbwalker:SetAttack(bool)
    end
    local function Idmg(target)
       if
       (myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1)) or
       (myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2))
       then
          return 50 + 20 * myHero.levelData.lvl
       end
       return 0
    end
 
 
    --[[ local function NoPotion()
    for i = 0, 63 do
       local buff = myHero:GetBuff(i)
       if buff.type == 13 and Game.Timer() < buff.expireTime then
          return false
       end
    end
    return true
    end ]]
    function PercentHP(target)
       return 100 * target.health / target.maxHealth
    end
 
    function PercentMP(target)
       return 100 * target.mana / target.maxMana
    end
 
    local HKITEM = {
       [ITEM_1] = HK_ITEM_1,
       [ITEM_2] = HK_ITEM_2,
       [ITEM_3] = HK_ITEM_3,
       [ITEM_4] = HK_ITEM_4,
       [ITEM_5] = HK_ITEM_5,
       [ITEM_6] = HK_ITEM_6,
       [ITEM_7] = HK_ITEM_7
    }
 
    ---------------------------------------------------------------------------------------------------------------------------------------------------
    function Rengar:LoadSpells()
       Q = {
          range = myHero:GetSpellData(_Q).range,
          delay = myHero:GetSpellData(_Q).delay,
          speed = myHero:GetSpellData(_Q).speed,
          width = myHero:GetSpellData(_Q).width
       }
       W = {
          range = myHero:GetSpellData(_W).range,
          delay = myHero:GetSpellData(_W).delay,
          speed = myHero:GetSpellData(_W).speed,
          width = myHero:GetSpellData(_W).width
       }
       E = {
          range = myHero:GetSpellData(_E).range,
          delay = myHero:GetSpellData(_E).delay,
          speed = myHero:GetSpellData(_E).speed,
          width = myHero:GetSpellData(_E).width
       }
    end
    ---------------------------------------------------------------------------------------------------------------------------------------------------
    function Rengar:LoadMenu()
       self.Menu =
       MenuElement(
       {
          type = MENU,
          id = "Rengar",
          name = "ManlyRengar",
          leftIcon = "https://www.mobafire.com/images/champion/square/rengar.png"
       }
       )
       ---------------------------------------------------------------------------------------------------------------------------------------------------
       function Rengar:Clear()
          for i = 1, Game.MinionCount(725) do
             local minion = Game.Minion(i)
             if minion and minion.team ~= myHero.team then
                if myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearQ:Value() and Ready(_Q) then
                   Control.CastSpell(HK_Q, minion.pos)
                end
                if
                myHero.mana < 4 and myHero.pos:DistanceTo(minion.pos) < 725 and self.Menu.Clear.ClearE:Value() and
                Ready(_E)
                then
                   Control.CastSpell(HK_E, minion.pos)
                end
                if
                myHero.mana < 4 and myHero.pos:DistanceTo(minion.pos) < 410 and self.Menu.Clear.ClearW:Value() and
                Ready(_W)
                then
                   Control.CastSpell(HK_W)
                end
             end
          end
          ---------------------------------------------------------------------------------------------------------------------------------------------------
       end
 
       ---------------------------------------------------------------------------------------------------------------------------------------------------
       function Rengar:CQ()
          if GetTarget(410) == nil then
             self:CE()
             return
          end
          local qtarg = GetTarget(410)
          if self.Menu.Combo.ComboQ:Value() and Ready(_Q) and qtarg ~= nil then
             EnableOrb(false)
             Control.CastSpell(HK_Q, qtarg)
             EnableOrb(true)
          end
       end
       ---------------------------------------------------------------------------------------------------------------------------------------------------
       function Rengar:CE()
          if GetTarget(725) == nil then
             return
          end
          local etarg = GetTarget(725)
          if etarg ~= nil then
             if self.Menu.Combo.ComboE:Value() and Ready(_E) and etarg:GetCollision(E.width, E.speed, E.delay) == 0 then
                EnableOrb(false)
                Control.CastSpell(HK_E, etarg)
                EnableOrb(true)
             end
          end
       end
       ---------------------------------------------------------------------------------------------------------------------------------------------------
       function Rengar:CW()
          if GetTarget(410) == nil then
             self:CE()
             return
          end
          local wtarg = GetTarget(410)
          if self.Menu.Combo.ComboW:Value() and Ready(_W) and wtarg ~= nil then
             Control.CastSpell(HK_W, wtarg)
          end
       end
       ---------------------------------------------------------------------------------------------------------------------------------------------------
 
       ---------------------------------------------------------------------------------------------------------------------------------------------------
       function Rengar:Tick()
          if myHero.dead then
             return end
 
             self:AutoLevel()
             self:Activator()
             self:Summoners()
 
             local Mode = GetMode()
             if self.Menu.Combo.PrioKey:Value() then
                local x = self.Menu.Combo.Prio:Value() + 1
                Control.KeyUp(14)
                DelayAction(
                function()
                   self.Menu.Combo.Prio:Value(x)
                   end,
                   0.1
                   )
                end
 
                if self.Menu.Combo.Prio:Value() > 3 then
                   self.Menu.Combo.Prio:Value(1)
                end
 
                ---------------------------------------------------------------------------------------------------------------------------------------------------
                if Mode == "Combo" then
                   if myHero.mana == 4 then
                      if self.Menu.Combo.Prio:Value() == 1 then
                         self:CQ()
                      end
                      if self.Menu.Combo.Prio:Value() == 2 then
                         self:CW()
                      end
                      if self.Menu.Combo.Prio:Value() == 3 then
                         self:CE()
                      end
                   else
                      if self.Menu.Combo.Prio:Value() == 1 then
                         ---------------------------------------------------------------------------------------------------------------------------------------------------
                         self:CQ()
                         self:CE()
                         self:CW()
                      elseif self.Menu.Combo.Prio:Value() == 2 then
                         ---------------------------------------------------------------------------------------------------------------------------------------------------
                         self:CW()
                         self:CQ()
                         self:CE()
                      elseif self.Menu.Combo.Prio:Value() == 3 then
                         self:CE()
                         self:CQ()
                         self:CW()
                      end
                   end
                end
                ---------------------------------------------------------------------------------------------------------------------------------------------------
                if Mode == "Clear" then
                   self:Clear()
                end
                ---------------------------------------------------------------------------------------------------------------------------------------------------
             end
             ---------------------------------------------------------------------------------------------------------------------------------------------------
             --[[Combo]]
             self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
             self.Menu.Combo:MenuElement({id = "ComboQ", name = "Use Q", value = true})
             self.Menu.Combo:MenuElement({id = "ComboW", name = "Use W", value = true})
             self.Menu.Combo:MenuElement({id = "ComboE", name = "Use E", value = true})
             self.Menu.Combo:MenuElement({id = "Prio", name = "Combo Ferocity Priority", drop = {"Q", "W", "E"}})
             self.Menu.Combo:MenuElement({id = "PrioKey", name = "Priority key", key = string.byte("T")})
             ---------------------------------------------------------------------------------------------------------------------------------------------------
             --Clear
             self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
             self.Menu.Clear:MenuElement({id = "ClearQ", name = "Use Q", value = true})
             self.Menu.Clear:MenuElement({id = "ClearW", name = "Use W", value = true})
             self.Menu.Clear:MenuElement({id = "ClearE", name = "Use E", value = true})
             ---------------------------------------------------------------------------------------------------------------------------------------------------
             --Misc
             self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc"})
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
             ---------------------------------------------------------------------------------------------------------------------------------------------------
             --[[Draw]]
             self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawings"})
             self.Menu.Draw:MenuElement({id = "DrawQW", name = "Draw Q/W Range", value = true})
             self.Menu.Draw:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
             self.Menu.Draw:MenuElement({id = "DrawP", name = "Draw Priority", value = true})
             ---------------------------------------------------------------------------------------------------------------------------------------------------
             --ITEM ACTIVATOR
             self.Menu:MenuElement({type = MENU, id = "Activator", name = "Activator"})
             --self.Menu.Activator:MenuElement({type = SPACE, id = "A", name = "24/7 Item Activator"})
             --self.Menu.Activator:MenuElement({type = MENU, id = "Potions", name = "Potions"})
             --self.Menu.Activator.Potions:MenuElement({id = "Pot", name = "Use Pots?", value = true})
             --self.Menu.Activator.Potions:MenuElement({id = "HP", name = "Health % to Potion", value = 60, min = 0, max = 100})
             self.Menu.Activator:MenuElement({type = SPACE, id = "Ab", name = "Combo Item Activator"})
             self.Menu.Activator:MenuElement({type = MENU, id = "Items", name = "Items"})
             self.Menu.Activator.Items:MenuElement({id = "YG", name = "Youmuu's Ghostblade", value = true})
             self.Menu.Activator.Items:MenuElement({type = MENU, id = "YGS", name = "GhostBlade Settings"})
             self.Menu.Activator.Items.YGS:MenuElement(
             {id = "ED", name = "Enemy Distance", value = 1000, min = 400, max = 2500, step = 25}
             )
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
             self.Menu.Activator.Items.QSSS:MenuElement({id = "Grounded", name = "Grounded", value = true})
             self.Menu.Activator.Items.QSSS:MenuElement({id = "Drowsy", name = "Drowsy", value = true})
             self.Menu.Activator.Items.QSSS:MenuElement({id = "Asleep", name = "Asleep", value = true})
 
 
 
 
 
             ---------------------------------------------------------------------------------------------------------------------------------------------------
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
                               self.Menu.Activator.Summoners:MenuElement({id = "Grounded", name = "Grounded", value = true})
                               self.Menu.Activator.Summoners:MenuElement({id = "Drowsy", name = "Drowsy", value = true})
                               self.Menu.Activator.Summoners:MenuElement({id = "Asleep", name = "Asleep", value = true})
                            end
                            end,
                            2
                            )
                            self.Menu.Activator.Summoners:MenuElement(
                            {type = SPACE, id = "Note", name = "Note: Ghost/TP/Flash/Smite is not supported"}
                            )
                         end
                         ---------------------------------------------------------------------------------------------------------------------------------------------------
                         function Rengar:AutoLevel()
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
                         ---------------------------------------------------------------------------------------------------------------------------------------------------
                         function Rengar:Draw()
                            local P = self.Menu.Combo.Prio:Value()
                            local textPos = myHero.pos:To2D()
                            if myHero.dead then
                               return
                            end
                            if self.Menu.Draw.DrawQW:Value() then
                               Draw.Circle(myHero.pos, 450, 1, Draw.Color(255, 255, 255, 255))
                            end
                            if self.Menu.Draw.DrawE:Value() then
                               Draw.Circle(myHero.pos, 1000, 1, Draw.Color(255, 255, 255, 255))
                            end
                            if self.Menu.Draw.DrawP:Value() then
                               if P == 1 then
                                  Draw.Text("Empower Q", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 0, 0))
                               else
                                  if P == 2 then
                                     Draw.Text("Empower W", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 0, 0))
                                  else
                                     Draw.Text("Empower E", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 255, 0, 0))
                                  end
                               end
                            end
                            ---------------------------------------------------------------------------------------------------------------------------------------------------
                         end
                         ---------------------------------------------------------------------------------------------------------------------------------------------------
                         function Rengar:Summoners()
                            local target = GetTarget(1200)
                            if target == nil then
                               return
                            end
                            if GetMode() == "Combo" then
                               ---------------------------------------------------------------------------------------------------------------------------------------------------
 
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
                                                       (buff.type == 33 and self.Menu.Activator.Summoners.Grounded:Value()) or
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
                                        ---------------------------------------------------------------------------------------------------------------------------------------------------
                                     end
                                     ---------------------------------------------------------------------------------------------------------------------------------------------------
 
                                     function Rengar:Activator()
                                        local target = GetTarget(2500)
                                        local items = {}
                                        for slot = ITEM_1, ITEM_6 do
                                           local id = myHero:GetItemData(slot).itemID
                                           if id > 0 then
                                              items[id] = slot
                                           end
                                        end
                                        ---------------------------------------------------------------------------------------------------------------------------------------------------
                                        --PASSIVE ACTIVATOR
                                        --[[   local Potion = items[2003] or items[2010] or items[2031] or items[2032] or items[2033] -- ALl potions
                                        if Potion and self.Menu.Activator.Potions.Pot:Value() then
                                           if myHero:GetSpellData(Potion).currentCd == 0 and NoPotion() then
                                              if PercentHP(myHero) < self.Menu.Activator.Potions.HP:Value() then
                                                 Control.CastSpell(HKITEM[Potion])
                                              end
                                           end
                                           end ]]
                                           ---------------------------------------------------------------------------------------------------------------------------------------------------
                                           --COMBO MODE ACTIVATOR
                                           if target == nil then
                                              return
                                           end
                                           if GetMode() == "Combo" then
                                              ---------------------------------------------------------------------------------------------------------------------------------------------------
                                              local YGB = items[3142] -- Ghostblade
                                              if YGB then
                                                 if self.Menu.Activator.Items.YG:Value() and myHero:GetSpellData(YGB).currentCd == 0 then
                                                    if myHero.pos:DistanceTo(target.pos) <= self.Menu.Activator.Items.YGS.ED:Value() then
                                                       Control.CastSpell(HKITEM[YGB])
                                                    end
                                                 end
                                              end
 
                                              ---------------------------------------------------------------------------------------------------------------------------------------------------
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
                                                          (buff.type == 33 and self.Menu.Activator.Items.QSSS.Grounded:Value()) or
                                                          (buff.type == 34 and self.Menu.Activator.Items.QSSS.Drowsy:Value()) or
                                                          (buff.type == 35 and self.Menu.Activator.Items.QSSS.Asleep:Value())
                                                          then
 
                                                             Control.CastSpell(HKITEM[QSS])
                                                          end
                                                       end
                                                    end
                                                 end
                                              end
                                              ---------------------------------------------------------------------------------------------------------------------------------------------------
                                           end
                                           ---------------------------------------------------------------------------------------------------------------------------------------------------
                                        end
                                        ---------------------------------------------------------------------------------------------------------------------------------------------------
                                        function OnLoad()
                                           Rengar()
                                        end
                                        ---------------------------------------------------------------------------------------------------------------------------------------------------
 