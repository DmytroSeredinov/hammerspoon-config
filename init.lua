local R, M = pcall(require,"hs._asm.hotkey")
if R then
    print()
    print("**** Replacing internal hs.hotkey with experimental module.")
    print()
    hs.hotkey = M
    package.loaded["hs.hotkey"] = M   -- make sure require("hs.hotkey") returns us
    package.loaded["hs/hotkey"] = M   -- make sure require("hs/hotkey") returns us
else
    print()
    print("**** Error with experimental hs.hotkey: "..tostring(M))
    print()
end

local requirePlus = require("utils.require")
local settings    = require("hs.settings")
local ipc         = require("hs.ipc")
local hints       = require("hs.hints")

-- Set to True or False indicating if you want a crash report when lua is invoked on  threads other than main (0) -- this should not happen, as lua is only supposed to execute in the main thread (unsupported and scary things can happen otherwise).  There is a performance hit, though, since the debug hook will be invoked for every call to a lua function, so usually this should be enabled only when testing in-development modules.

settings.set("_asm.crashIfNotMain", false)

requirePlus.updatePaths("In Home", {
    os.getenv("HOME").."/.hammerspoon/?.lua;"..
    os.getenv("HOME").."/.hammerspoon/?/init.lua",
    os.getenv("HOME").."/.hammerspoon/?.so"}, false)
requirePlus.updatePaths("Luarocks", "luarocks-5.3 path", true)

inspect = require("hs.inspect")
inspect1 = function(what) return inspect(what, {depth=1}) end

ipc.cliInstall("/opt/amagill")

-- What can I say? I like the original Hydra's console documentation style,
-- rather than help("...")
doc = require("utils.docs")


-- For my convenience while testing and screwing around...
-- If something grows into usefulness, I'll modularize it.
_asm = {
    _ = package.loaded,
    extras    = require("hs._asm.extras"),
    _keys     = requirePlus.requirePath("utils._keys", true),
    _actions  = requirePlus.requirePath("utils._actions", true),
    _menus    = requirePlus.requirePath("utils._menus", true),
    relaunch = function()
        os.execute([[ (while ps -p ]]..hs.processInfo.processID..[[ > /dev/null ; do sleep 1 ; done ; open -a "]]..hs.processInfo.bundlePath..[[" ) & ]])
        hs._exit(true, true)
    end,
}

if tonumber(_VERSION:match("5%.(%d+)$")) > 2 then
-- wrapping this in load keeps lua 5.2 from crapping on the >> and &.
    toBits = load([[
        return function(num, bits)
            bits = bits or (math.floor(math.log(num,2) / 8) + 1) * 8
            local value = ""
            for i = (bits - 1), 0, -1 do
                value = value..tostring((num >> i) & 0x1)
            end
            return value
        end
    ]])()
else
    toBits = function(num, bits)
        bits = bits or (math.floor(math.log(num,2) / 8) + 1) * 8
        local value = ""
        for i = (bits - 1), 0, -1 do
            value = value..tostring(bit32.band(bit32.rshift(num, i), 0x1))
        end
        return value
    end
end

hints.style = "vimperator"

print("++ Running: "..hs.processInfo.bundlePath)
print("++ Accessibility: "..tostring(hs.accessibilityState()))
_asm._actions.timestamp.status()