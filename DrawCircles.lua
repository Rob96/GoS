class "DrawCircles"

function DrawCircles:__init()
  PrintChat("DrawCircles")
  self:LoadMenu()
  Callback.Add("Draw", function() self:Draw() end)
end

function DrawCircles:LoadMenu()
  self.Menu = MenuElement({type = MENU, id = "DrawCircles", name = "Draw Circles"})

  --[[Draw]]
  self.Menu:MenuElement({type = MENU, id = "Draw", name = "Draw Circles"})
  self.Menu.Draw:MenuElement({id = "ded", name = "Draw When Dead?", value = false})
  self.Menu.Draw:MenuElement({id = "on1", name = "Circle 1", value = false})
  self.Menu.Draw:MenuElement({id = "r1", name = "Range for Circle 1", value = 100, min = 0, max = 5000})
  self.Menu.Draw:MenuElement({id = "on2", name = "Circle 2", value = false})
  self.Menu.Draw:MenuElement({id = "r2", name = "Range for Circle 2", value = 100, min = 0, max = 5000})
  self.Menu.Draw:MenuElement({id = "on3", name = "Circle 3", value = false})
  self.Menu.Draw:MenuElement({id = "r3", name = "Range for Circle 3", value = 100, min = 0, max = 5000})
  self.Menu.Draw:MenuElement({id = "on4", name = "Circle 4", value = false})
  self.Menu.Draw:MenuElement({id = "r4", name = "Range for Circle 4", value = 100, min = 0, max = 5000})
  self.Menu.Draw:MenuElement({id = "on5", name = "Circle 5", value = false})
  self.Menu.Draw:MenuElement({id = "r5", name = "Range for Circle 5", value = 100, min = 0, max = 5000})
end

function DrawCircles:Draw()
  local r1 = self.Menu.Draw.r1:Value()
  local r2 = self.Menu.Draw.r2:Value()
  local r3 = self.Menu.Draw.r3:Value()
  local r4 = self.Menu.Draw.r4:Value()
  local r5 = self.Menu.Draw.r5:Value()
  if self.Menu.Draw.ded:Value() then
    if self.Menu.Draw.on1:Value() then

      Draw.Circle(myHero.pos, r1, 1, Draw.Color(255, 255, 0, 0))
    end
    if self.Menu.Draw.on2:Value() then
      Draw.Circle(myHero.pos, r2, 1, Draw.Color(255, 0, 255, 255))
    end
    if self.Menu.Draw.on3:Value() then
      Draw.Circle(myHero.pos, r3, 1, Draw.Color(255, 255, 0, 255))
    end
    if self.Menu.Draw.on4:Value() then
      Draw.Circle(myHero.pos, r4, 1, Draw.Color(255, 255, 255, 0))
    end
    if self.Menu.Draw.on5:Value() then
      Draw.Circle(myHero.pos, r5, 1, Draw.Color(255, 0, 0, 255))
    end

  else if myHero.dead then return end
    if self.Menu.Draw.on1:Value() then
      Draw.Circle(myHero.pos, r1, 1, Draw.Color(255, 255, 0, 0))
    end
    if self.Menu.Draw.on2:Value() then
      Draw.Circle(myHero.pos, r2, 1, Draw.Color(255, 0, 255, 255))
    end
    if self.Menu.Draw.on3:Value() then
      Draw.Circle(myHero.pos, r3, 1, Draw.Color(255, 255, 0, 255))
    end
    if self.Menu.Draw.on4:Value() then
      Draw.Circle(myHero.pos, r4, 1, Draw.Color(255, 255, 255, 0))
    end
    if self.Menu.Draw.on5:Value() then
      Draw.Circle(myHero.pos, r5, 1, Draw.Color(255, 0, 0, 255))
    end
  end
end

function OnLoad()
  DrawCircles()
end
