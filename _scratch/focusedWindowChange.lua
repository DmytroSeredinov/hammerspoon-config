local module      = {}
local window      = require "hs.window"
local application = require "hs.application"
local uielement   = require "hs.uielement"

-- may be nil if application has no window atm
module.actionFunction = function(win)
    if win then
        print(string.format("%s -- focused window change: %s (%s)", os.date("%F %T"), win:title(), win:application():name()))
    else
        print(string.format("%s -- focused window change: %s (%s)", os.date("%F %T"), "** no window **", application.frontmostApplication():name()))
    end
end

local watcherFunction -- forward declaration since this is needed to create the watcher

local newWatcher = function(andNotify)
    local win = window.focusedWindow()
    if andNotify then module.actionFunction(win) end
    local app = win and win:application() or application.frontmostApplication()
    local watcher = app:newWatcher(watcherFunction):start({uielement.watcher.applicationDeactivated, uielement.watcher.focusedWindowChanged, uielement.watcher.elementDestroyed})

    -- this is annoying... quitting an application doesn't destroy it's uielement, so we can't
    -- add just add uielement.watcher.elementDestroyed to the hs.uielement watcher... we have to
    -- store the application's pid so hs.application.watcher can detect the termination and force
    -- an update for us
    module.activePID = app:pid()

    return watcher
end

watcherFunction = function(el, ev, ...)
    if ev == uielement.watcher.applicationDeactivated then
        module.watcher:stop()
        module.watcher = newWatcher(true)
    elseif ev == uielement.watcher.focusedWindowChanged then
        -- when the last window for an app closes, but the app remains empty, el will be
        -- a raw `hs.uielement` object, which we don't want to deal with.
        if getmetatable(el).__name ~= "hs.window" then el = nil end
        module.actionFunction(el)
    else
        print("~~ unexpected event: " .. ev .. " on " .. tostring(el))
    end
end

module.watcher = newWatcher()

module.terminationWatcher = application.watcher.new(function(n, e, o)
    if e == application.watcher.terminated and o:pid() == module.activePID then
        -- force an applicationDeactivated event so that it rebuilds the watcher.
        watcherFunction(nil, uielement.watcher.applicationDeactivated)
    end
end):start()

return module

