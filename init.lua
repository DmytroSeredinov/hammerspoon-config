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
require("hs.logger").historySize(1000)

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
local stext       = require("hs.styledtext")
local fnutils     = require("hs.fnutils")


-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

settings.set("_asm.crashIfNotMain", false)

requirePlus.updatePaths("In Home", {
    hs.configdir.."/?.lua;"..
    hs.configdir.."/?/init.lua",
    hs.configdir.."/?.so"}, false)
requirePlus.updatePaths("Luarocks", "luarocks-5.3 path", true)

inspect = require("hs.inspect")
inspectm = function (what, how)
    if how then return inspect(what, how) else return inspect(what, { metatables = 1 }) end
end
inspect1 = function(what) return inspect(what, {depth=1}) end
inspect2 = function(what) return inspect(what, {depth=2}) end

-- need to make third-party docs possible; this is totally out of date
-- -- may include locally added json files in docs versus built in help
-- doc = require("utils.docs")
doc = help

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
-- _xtras.docmaker = require("utils.docmaker")

-- _xtras.console = require("hs.console")

_asm = {}

_asm.relaunch = function()
    os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
    hs._exit(true, true)
end

_asm.watchables = require("utils.watchables")

_asm._keys    = requirePlus.requirePath("utils._keys", true)
_asm._actions = requirePlus.requirePath("utils._actions", true)
_asm._menus   = requirePlus.requirePath("utils._menus", true)
-- need to rethink requirePlus so that it can handle folders with name/init.lua
_asm._menus.XProtectStatus = require"utils._menus.XprotectStatus"

_asm._CMI     = require("utils.consolidateMenus")

table.insert(_asm._actions.closeWhenLoseFocus.closeList, "nvALT")
_asm._actions.closeWhenLoseFocus.disable()

_asm._CMI.addMenu(_asm._menus.applicationMenu.menuUserdata, "icon",      true)
_asm._CMI.addMenu(_asm._menus.developerMenu.menuUserdata,   "icon",  -1, true)
_asm._CMI.addMenu(_asm._menus.newClipper.menu,              "title", -1, true)
_asm._CMI.addMenu(_asm._menus.volumes.menu,                 "icon",  -1, true)
_asm._CMI.addMenu(_asm._menus.battery.menuUserdata,         "title", -1, true)
-- going to have to revisit CMI... it doesn't do arbitrary sized icons well, plus I think I want a dark mode
-- time to consider image filters for hs.image?
_asm._CMI.addMenu(_asm._menus.dateMenu.menuUserdata,        "title", -2, true)
_asm._CMI.addMenu(_asm._menus.amphetamine.menu,             "icon",  -2, true)
_asm._CMI.addMenu(_asm._menus.XProtectStatus.fullMenu,      "icon",  -2, true)
-- _asm._CMI.addMenu(_asm._menus.XProtectStatus.pluginMenu,    "icon",  -2, true)
-- _asm._CMI.addMenu(_asm._menus.XProtectStatus.statusMenu,    "icon",  -2, true)
_asm._CMI.panelShow()

dofile("geekery.lua")

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

_asm.consoleToolbar = require"utils.consoleToolbar"

_asm.hs_default_print = print
print = function(...)
    hs.rawprint(...)
    console.printStyledtext(...)
end

colorsFor = function(name)
    local a = stext.new("")
    for i,v in fnutils.sortByKeys(drawing.color.colorsFor(name)) do
        a = a..stext.new(i.."\n", { color = { white = .5 }, backgroundColor = v })
    end
    print(a)
end

colorDump = function()
    for i,v in fnutils.sortByKeys(drawing.color.lists()) do
        print(i)
        colorsFor(i)
    end
end

resetSpaces = function()
    local s = require("hs._asm.undocumented.spaces")
    -- bypass check for raw function access
    local si = require("hs._asm.undocumented.spaces.internal")
    for k,v in pairs(s.spacesByScreenUUID()) do
        local first = true
        for a,b in ipairs(v) do
            if first and si.spaceType(b) == s.types.user then
                si.showSpaces(b)
                si._changeToSpace(b)
                first = false
            else
                si.hideSpaces(b)
            end
            si.spaceTransform(b, nil)
        end
        si.setScreenUUIDisAnimating(k, false)
    end
    hs.execute("killall Dock")
end

mb = function(url)
    local webview     = require("hs.webview")
    url = url or "https://www.google.com"
    if not _asm.mb then
        _asm.mb = webview.new({x=100,y=100,h=500,w=500},{
            developerExtrasEnabled=true
        }):windowStyle(1+2+4+8)
          :allowTextEntry(true):allowGestures(true)
    end
    return _asm.mb:url(url):show()
end

bundleIDForApp = function(app)
    return hs.execute([[mdls -name kMDItemCFBundleIdentifier -r "$(mdfind 'kMDItemKind==Application' | grep /]] .. app .. [[.app | head -1)"]])
end

history = _asm._actions.consoleHistory.history

idunno = "¯\\_(ツ)_/¯" -- I like it and may want to use it sometime

else
    print("++ Running minimal configuration")
end

print("++ Running: "..hs.processInfo.bundlePath)
print("++ Accessibility: "..tostring(hs.accessibilityState()))

