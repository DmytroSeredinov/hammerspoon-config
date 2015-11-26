local geekery = _asm._actions.geeklets
local screen  = require("hs.screen")
local stext   = require("hs.styledtext")
local fnutils = require("hs.fnutils")
local drawing = require("hs.drawing")

local monitorTopY   = screen.mainScreen():frame().y

geekery.registerShellGeeklet("cpu", 15,  "geeklets/system.sh",
        { x = 22, y = monitorTopY + 22, h = 60, w = 350}, { color = { alpha = 1 } },
        { drawing.rectangle{ x = 12, y = monitorTopY + 12, h = 80, w = 370 }
            :setFillColor{ alpha=.7, white = .5 }
            :setStrokeColor{ alpha=.5 }
            :setFill(true)
            :setRoundedRectRadii(5,5)
        }):start()
geekery.registerShellGeeklet("wifi", 60,  "geeklets/wifi.sh",
        { x = 22, y = monitorTopY + 102, h = 60, w = 350}, {
            color = { alpha = 1 },
            paragraphStyle = { lineBreak = "clip" }
        }, { drawing.rectangle{ x = 12, y = monitorTopY + 92, h = 80, w = 370 }
            :setFillColor{ alpha=.7, white = .5 }
            :setStrokeColor{ alpha=.5 }
            :setFill(true)
            :setRoundedRectRadii(5,5)
        }):start()

geekery.registerLuaGeeklet("hwm_check", 300,  "geeklets/hwm_check.lua",
        { x = 22, y = monitorTopY + 182, h = 20, w = 350}, { color = { alpha = 1 } },
        { drawing.rectangle{ x = 12, y = monitorTopY + 172, h = 40, w = 370 }
              :setFillColor{ alpha=.7, white = .5 }
              :setStrokeColor{ alpha=.5 }
              :setFill(true)
              :setRoundedRectRadii(5,5)
        }):start()

local geekletRemoteCheck = function()
    local result = stext.new("")
    for i,v in fnutils.sortByKeys(_asm._actions.remoteCheck.output) do
        result = result..v.."\n"
    end
    return result
end

geekery.registerLuaGeeklet("remoteCheck", 300, geekletRemoteCheck,
        { x = 400, y = monitorTopY + 22, h = 56 * 3, w = 400 }, { skip = true },
        { drawing.rectangle{x = 390, y = monitorTopY + 12, h = 200, w = 420 }
            :setFillColor{ alpha=.7, white = .5 }
            :setStrokeColor{ alpha=.5 }
            :setFill(true)
            :setRoundedRectRadii(5,5)
        }):start()

local geekletClock = function()
    local self = geekery.geeklets.clock
    local screenFrame = screen.mainScreen():fullFrame()
    local clockTime = os.date("%I:%M:%S %p")
    local clockPos = drawing.getTextDrawingSize(clockTime, self.textStyle)
    clockPos.w = clockPos.w + 4
    clockPos.x = screenFrame.x + screenFrame.w - (clockPos.w + 4)
    clockPos.y = screenFrame.y + screenFrame.h - (clockPos.h + 4)
    local clockBlockPos = {
        x = clockPos.x - 3,
        y = clockPos.y,
        h = clockPos.h + 3,
        w = clockPos.w + 6,
    }
    self.drawings[2]:setFrame(clockBlockPos)
    self.drawings[1]:setFrame(clockPos)
    return clockTime
end

geekery.registerLuaGeeklet("clock", 1,  geekletClock, { }, {
            font = { name = "Menlo-Italic", size = 12, },
            color = { red=.75, blue=.75, green=.75, alpha=.75},
            paragraphStyle = { alignment = "center", lineBreak = "clip" }
        }, {
            drawing.rectangle{}:setStroke(true)
                                  :setStrokeColor({ red=.75, blue=.75, green=.75, alpha=.75})
                                  :setFill(true)
                                  :setFillColor({alpha=.75})
                                  :setRoundedRectRadii(5,5)
        }):hover(true):start()
geekery.geeklets.clock.hoverlock = true

if _asm._actions.diskSpace then
    geekery.registerLuaGeeklet("diskSpace", 60,
        function() return nil end,                   -- no text handled by geeklets
        { },                                         -- no frame for the essentially empty object
        { skip = true },                             -- no style for text handled by geeklets
        { _asm._actions.diskSpace.geekletInterface } -- responds to geeklet requests
    ):start()
end

geekery.startUpdates()
