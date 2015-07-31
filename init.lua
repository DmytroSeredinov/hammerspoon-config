local minimal = false

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

-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

settings.set("_asm.crashIfNotMain", false)

requirePlus.updatePaths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
requirePlus.updatePaths("Luarocks", "luarocks-5.3 path", true)

inspect = require("hs.inspect")
inspect1 = function(what) return inspect(what, {depth=1}) end
inspect2 = function(what) return inspect(what, {depth=2}) end

-- What can I say? I like the original Hydra's console documentation style,
-- rather than help("...")
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

if not minimal then -- normal init continues...

require("hs.window").animationDuration = 0 -- I'm a philistine, sue me

ipc.cliInstall("/opt/amagill")

-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_asm = {
    _ = package.loaded,
    extras    = require("hs._asm.extras"),
    _keys     = requirePlus.requirePath("utils._keys", true),
    _actions  = requirePlus.requirePath("utils._actions", true),
    _menus    = requirePlus.requirePath("utils._menus", true),
    _CMI      = require("utils.consolidateMenus"),
    relaunch = function()
        os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
        hs._exit(true, true)
    end,
}

hints.style = "vimperator"

-- terminal shell equivalencies...
edit = function(where)
    where = where or "."
    os.execute("/usr/local/bin/edit "..where)
end
m = function(which)
    os.execute("open x-man-page://"..tostring(which))
end
-- utf8.codepointToUTF8("U+2702")
_asm._CMI.addMenu(_asm._menus.applicationMenu.menuUserdata,      "icon",     true)
_asm._CMI.addMenu(_asm._menus.developerMenu.menuUserdata,        "icon", -1, true)
_asm._CMI.addMenu(_asm._menus.clipboard,                 "dynamicTitle", -1, true)
_asm._CMI.addMenu(_asm._menus.battery.menuUserdata,      "dynamicTitle", -1, true)
_asm._CMI.addMenu(_asm._menus.dateMenu.menuUserdata,     "dynamicTitle", -2, true)
_asm._CMI.panelShow()

_asm._actions.timestamp.status()

else
    print("++ Running minimal configuration")
end

print("++ Running: "..hs.processInfo.bundlePath)
print("++ Accessibility: "..tostring(hs.accessibilityState()))
