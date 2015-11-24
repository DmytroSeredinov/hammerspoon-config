local minimal = false
-- local oldPrint = print
-- print = function(...)
--     oldPrint(os.date("%H:%M:%S: "), ...)
-- end

-- I do too much with developmental versions of HS -- I don't need
-- extraneous info in the Console application for every require; very
-- few of my crashes  make it into Crashlytics anyways...
--
-- I don't recommend this unless you like doing your own troubleshooting
-- since it defeats some of the data captured for crash reports.
--

hs.require = require
require = rawrequire
require("hs.crash").crashLogToNSLog = true
require("hs.crash").crashLog("Disabled require logging to make log file sane")

-- adjust hotkey logging... info as the default is too much.
require("hs.hotkey").setLogLevel("warning")

-- -- Testing eventtap replacement for hotkey
--
--local R, M = pcall(require,"hs._asm.hotkey")
--if R then
--    print()
--    print("**** Replacing internal hs.hotkey with experimental module.")
--    print()
--    hs.hotkey = M
--    package.loaded["hs.hotkey"] = M   -- make sure require("hs.hotkey") returns us
--    package.loaded["hs/hotkey"] = M   -- make sure require("hs/hotkey") returns us
--else
--    print()
--    print("**** Error with experimental hs.hotkey: "..tostring(M))
--    print()
--end

local requirePlus = require("utils.require")
local settings    = require("hs.settings")
local ipc         = require("hs.ipc")
local hints       = require("hs.hints")
local utf8        = require("hs.utf8")
local image       = require("hs.image")
local window      = require("hs.window")
local timer       = require("hs.timer")
local drawing     = require("hs.drawing")
local screen      = require("hs.screen")
local console     = require("hs.console")

-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

settings.set("_asm.crashIfNotMain", false)

requirePlus.updatePaths("In Home", {
    hs.configdir.."/?.lua;"..
    hs.configdir.."/?/init.lua",
    hs.configdir.."/?.so"}, false)
requirePlus.updatePaths("Luarocks", "luarocks-5.3 path", true)

inspect = require("hs.inspect")
inspect1 = function(what) return inspect(what, {depth=1}) end
inspect2 = function(what) return inspect(what, {depth=2}) end
inspectnm = function(what) return inspect(what ,{process=function(item,path) if path[#path] == inspect.METATABLE then return nil else return item end end}) end
inspectnm1 = function(what) return inspect(what ,{process=function(item,path) if path[#path] == inspect.METATABLE then return nil else return item end end, depth=1}) end

-- may include locally added json files in docs versus built in help
doc = require("utils.docs")

tobits = function(num, bits)
    bits = bits or (math.floor(math.log(num,2) / 8) + 1) * 8
    if bits == -(1/0) then bits = 8 end
    local value = ""
    for i = (bits - 1), 0, -1 do
        value = value..tostring((num >> i) & 0x1)
    end
    return value
end

isinf = function(x) return x == math.huge end
isnan = function(x) return x ~= x end

if not minimal then -- normal init continues...

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_xtras = require("hs._asm.extras")
-- _xtras.console = require("hs.console")

_asm = {}
_asm._keys    = requirePlus.requirePath("utils._keys", true)
_asm._actions = requirePlus.requirePath("utils._actions", true)
_asm._menus   = requirePlus.requirePath("utils._menus", true)
_asm._CMI     = require("utils.consolidateMenus")
_asm.relaunch = function()
    os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
    hs._exit(true, true)
end

table.insert(_asm._actions.closeWhenLoseFocus.closeList, "nvALT")
_asm._actions.closeWhenLoseFocus.disable()

_asm._CMI.addMenu(_asm._menus.applicationMenu.menuUserdata, "icon",      true)
_asm._CMI.addMenu(_asm._menus.developerMenu.menuUserdata,   "icon",  -1, true)
_asm._CMI.addMenu(_asm._menus.clipboard,                    "title", -1, true)
_asm._CMI.addMenu(_asm._menus.battery.menuUserdata,         "title", -1, true)
_asm._CMI.addMenu(_asm._menus.autoCloseHS.menuUserdata,     "icon" , -1, true)
_asm._CMI.addMenu(_asm._menus.dateMenu.menuUserdata,        "title", -2, true)
_asm._CMI.panelShow()

_asm._actions.geeklets.registerShellGeeklet("cpu", 15,  "geeklets/system.sh",
        { x = 22, y = 44, h = 60, w = 350}, { color = { alpha = 1 } },
        { drawing.rectangle{ x = 12, y = 34, h = 80, w = 370 }
            :setFillColor{ alpha=.7, white = .5 }
            :setStrokeColor{ alpha=.5 }
            :setFill(true)
            :setRoundedRectRadii(5,5)
        }):start()
_asm._actions.geeklets.registerShellGeeklet("wifi", 60,  "geeklets/wifi.sh",
        { x = 22, y = 124, h = 60, w = 350}, {
            color = { alpha = 1 },
            paragraphStyle = { lineBreak = "clip" }
        }, { drawing.rectangle{ x = 12, y = 114, h = 80, w = 370 }
            :setFillColor{ alpha=.7, white = .5 }
            :setStrokeColor{ alpha=.5 }
            :setFill(true)
            :setRoundedRectRadii(5,5)
        }):start()
_asm._actions.geeklets.registerLuaGeeklet("hwm_check", 300,  "geeklets/hwm_check.lua",
        { x = 22, y = 204, h = 20, w = 350}, { color = { alpha = 1 } },
        { drawing.rectangle{ x = 12, y = 194, h = 40, w = 370 }
              :setFillColor{ alpha=.7, white = .5 }
              :setStrokeColor{ alpha=.5 }
              :setFill(true)
              :setRoundedRectRadii(5,5)
        }):start()

local geekletClock = function()
    local self = _asm._actions.geeklets.geeklets.clock
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

_asm._actions.geeklets.registerLuaGeeklet("clock", 1,  geekletClock, { }, {
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
_asm._actions.geeklets.geeklets.clock.hoverlock = true

_asm._actions.geeklets.startUpdates()

hints.style = "vimperator"
window.animationDuration = 0 -- I'm a philistine, sue me
ipc.cliInstall("/opt/amagill")

-- terminal shell equivalencies...
edit = function(where)
    where = where or "."
    os.execute("/usr/local/bin/edit "..where)
end
m = function(which)
    os.execute("open x-man-page://"..tostring(which))
end

-- _asm._actions.timestamp.status()

timer.waitUntil(
    load([[ return require("hs.window").get("Hammerspoon Console") ]]),
    function(timerObject)
        local win = window.get("Hammerspoon Console")
        local screen = win:screen()
        win:setTopLeft({
            x = screen:frame().x + screen:frame().w - win:size().w,
            y = screen:frame().y + screen:frame().h - win:size().h
        })
    end
)

-- hs.drawing.windowBehaviors.moveToActiveSpace
console.asHSDrawing():setBehavior(2)
console.smartInsertDeleteEnabled(false)
console.windowBackgroundColor({red=.6,blue=.7,green=.7})
console.outputBackgroundColor({red=.8,blue=.8,green=.8})
console.asHSDrawing():setAlpha(.9)

_asm.hs_default_print = print
print = function(...)
    hs.rawprint(...)
    console.printStyledtext(...)
end

else
    print("++ Running minimal configuration")
end

history = _asm._actions.consoleHistory.findInHistory

print("++ Running: "..hs.processInfo.bundlePath)
print("++ Accessibility: "..tostring(hs.accessibilityState()))

