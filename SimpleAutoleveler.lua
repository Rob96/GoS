class "SimpleAutoLeveler"

function SimpleAutoLeveler:__init()
  PrintChat("SimpleAutoLeveler")
  self:LoadMenu()
  Callback.Add("Tick", function() self:Tick() end)
end



function SimpleAutoLeveler:LoadMenu()
  self.Menu = MenuElement({type = MENU, id = "SimpleAutoLeveler", name = "SimpleAutoLeveler"})
  self.Menu:MenuElement({id = "lvEnabled", name = "Enable AutoLeveler", value = true})
  self.Menu:MenuElement({id = "Block", name = "Block on Level 1", value = true})
  self.Menu:MenuElement({id = "Order", name = "Skill Priority", drop = {"[Q] - [W] - [E] > Max [Q]","[Q] - [E] - [W] > Max [Q]","[W] - [Q] - [E] > Max [W]","[W] - [E] - [Q] > Max [W]","[E] - [Q] - [W] > Max [E]","[E] - [W] - [Q] > Max [E]"}})
end


function SimpleAutoLeveler:AutoLevel()
  if self.Menu.lvEnabled:Value() == false then return end
  local Sequence = {
    [1] = { HK_Q, HK_W, HK_E, HK_Q, HK_Q, HK_R, HK_Q, HK_W, HK_Q, HK_W, HK_R, HK_W, HK_W, HK_E, HK_E, HK_R, HK_E, HK_E },
    [2] = { HK_Q, HK_E, HK_W, HK_Q, HK_Q, HK_R, HK_Q, HK_E, HK_Q, HK_E, HK_R, HK_E, HK_E, HK_W, HK_W, HK_R, HK_W, HK_W },
    [3] = { HK_W, HK_Q, HK_E, HK_W, HK_W, HK_R, HK_W, HK_Q, HK_W, HK_Q, HK_R, HK_Q, HK_Q, HK_E, HK_E, HK_R, HK_E, HK_E },
    [4] = { HK_W, HK_E, HK_Q, HK_W, HK_W, HK_R, HK_W, HK_E, HK_W, HK_E, HK_R, HK_E, HK_E, HK_Q, HK_Q, HK_R, HK_Q, HK_Q },
    [5] = { HK_E, HK_Q, HK_W, HK_E, HK_E, HK_R, HK_E, HK_Q, HK_E, HK_Q, HK_R, HK_Q, HK_Q, HK_W, HK_W, HK_R, HK_W, HK_W },
    [6] = { HK_E, HK_W, HK_Q, HK_E, HK_E, HK_R, HK_E, HK_W, HK_E, HK_W, HK_R, HK_W, HK_W, HK_Q, HK_Q, HK_R, HK_Q, HK_Q },
  }
  local Slot = nil
  local Tick = 0
  local SkillPoints = myHero.levelData.lvl - (myHero:GetSpellData(_Q).level + myHero:GetSpellData(_W).level + myHero:GetSpellData(_E).level + myHero:GetSpellData(_R).level)
  local level = myHero.levelData.lvl
  local Check = Sequence[self.Menu.Order:Value()][level - SkillPoints + 1]
  if SkillPoints > 0 then
    if self.Menu.Block:Value() and level == 1 then return end
    if GetTickCount() - Tick > 800 and
    Check ~= nil then
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

        function SimpleAutoLeveler:Tick()
          if Game.IsChatOpen() == true then return end
          self:AutoLevel()
        end



    function OnLoad()
      SimpleAutoLeveler()
    end
