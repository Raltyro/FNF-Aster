local Color = Classic:extend("Color")

function Color:new(r, g, b, a) self.r, self.g, self.b, self.a = r or 1, g or 1, b or 1, a or 1 end

function Color.get_WHITE() return Color(1, 1, 1) end
function Color.get_BLACK() return Color(0, 0, 0) end
function Color.get_RED() return Color(1, 0, 0) end
function Color.get_GREEN() return Color(0, 1, 0) end
function Color.get_BLUE() return Color(0, 0, 1) end

return Color