local module = {}

-- time stamp information to test some of my modules in active use... and cause I'm
-- funny that way.


hs.settings.setDate("_asm.last_loaded",os.time())

setmetatable(module,
    {__gc = function(obj)
            hs.settings.setDate("_asm.last_clean_shutdown",os.time())
        end
    }
)

module.heartbeat = hs.timer.new(hs.timer.minutes(1), function()
        hs.settings.setDate("_asm.last_heartbeat",os.time())
        if hs.appfinder.windowFromWindowTitle("Hammerspoon Console") then
            hs.settings.set("_asm.open_console_at_start", true)
        else
            hs.settings.set("_asm.open_console_at_start", false)
        end
    end
):start()

module.status = function()
    print("-------------------------------------------------")
    print("      Last Heartbeat:", os.date("%c", hs.settings.get("_asm.last_heartbeat") or 0))
    print(" Last Clean Shutdown:", os.date("%c", hs.settings.get("_asm.last_clean_shutdown") or 0))
    print("Configuration loaded:", os.date("%c", hs.settings.get("_asm.last_loaded") or 0))
    print("-------------------------------------------------")
end

if hs.settings.get("_asm.open_console_at_start") then hs.openConsole() end

module.status()

return module
