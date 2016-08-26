local toolbar     = require"hs.webview.toolbar"
local console     = require"hs.console"
local image       = require"hs.image"
local fnutils     = require"hs.fnutils"
local listener    = require"utils.speech"
local application = require"hs.application"
local styledtext  = require"hs.styledtext"

local watchable   = require"hs._asm.watchable"
local canvas      = require"hs._asm.canvas"

local module = {}

local imageBasePath = hs.configdir .. "/_localAssets/images/"

local autoHideImage = function()
    return imageBasePath .. (module.watchConsoleAutoClose:value() and "unpinned.png" or "pinned.png")
end

local listenerImage = function()
    return imageBasePath .. (module.watchListenerStatus:value() and "microphone_on.png" or "microphone_off.png")
end

module.watchConsoleAutoClose = watchable.watch("hammerspoonMenu.status", function(...)
    module.toolbar:modifyItem{ id = "autoHide", image = image.imageFromPath(autoHideImage()) }
end)

module.watchListenerStatus = watchable.watch("utils.speech.isListening", function(...)
    module.toolbar:modifyItem{ id = "listener", image = image.imageFromPath(listenerImage()) }
end)

module.watchInternetStatus = watchable.watch("generalStatus.internet", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "internet", image = image.imageFromName(value and "NSToolbarBookmarks" or "NSStopProgressFreestandingTemplate") }
end)

module.watchVPNStatus = watchable.watch("generalStatus.privateVPN", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "privateVPN", image = image.imageFromName(value and "NSLockLockedTemplate" or "NSLockUnlockedTemplate") }
end)

local imageHolder = canvas.new{x = 10, y = 10, h = 50, w = 50}
imageHolder[1] = {
    frame = { h = 50, w = 50, x = 0, y = -6 },
    text = styledtext.new("⌘", {
        font = { name = ".AppleSystemUIFont", size = 50 },
        paragraphStyle = { alignment = "center" }
    }),
    type = "text",
}
local cheatSheetOn = imageHolder:imageFromCanvas()
imageHolder[2] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 0, y = 0 }, { x = 50, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
imageHolder[3] = {
    action = "stroke",
    closed = false,
    coordinates = { { x = 50, y = 0 }, { x = 0, y = 50 } },
    strokeColor = { red = 1.0 },
    strokeWidth = 3,
    type = "segments",
}
local cheatSheetOff = imageHolder:imageFromCanvas()
imageHolder = imageHolder:delete()

module.watchCheatSheetStatus = watchable.watch("cheatsheet.enabled", function(w, p, i, oldValue, value)
    module.toolbar:modifyItem{ id = "cheatsheet", image = value and cheatSheetOn or cheatSheetOff }
end)

local consoleToolbar = {
    {
        id = "autoHide",
        label = "Auto Hide Console",
        image = image.imageFromPath(autoHideImage()),
        tooltip = "Hide the Hammerspoon Console when focus changes?",
        fn = function(bar, attachedTo, item)
            _asm._menus.hammerspoonMenu.toggleWatcher()
        end,
    },
    {
        id = "listener",
        label = "HS Listener",
        image = image.imageFromPath(listenerImage()),
        tooltip = "Toggle the Hammerspoon Speech Recognition Listener",
        fn = function(bar, attachedTo, item)
            if listener.recognizer then
                if listener:isListening() then
                    listener:disableCompletely()
                else
                    listener:start()
                end
            else
                listener.init():start()
            end
        end,
    },
    { id = "NSToolbarFlexibleSpaceItem" },
    {
        id = "cust",
        label = "customize",
        tooltip = "Modify Toolbar",
        fn = function(t, w, i)
            t:customizePanel()
        end,
        image = image.imageFromName("NSToolbarCustomizeToolbarItemImage")
    }
}

fnutils.each({
    { "SmartGit",         "com.syntevo.smartgit", },
    { "XCode",            "com.apple.dt.Xcode" },
    { "Console",          "com.apple.Console", },
    { "Terminal",         "com.apple.Terminal" },
    { "BBEdit",           "com.barebones.bbedit" },
    { "Safari",           "com.apple.Safari" },
    { "Activity Monitor", "com.apple.ActivityMonitor"},
    { "AXUI Inspector",   "com.apple.AccessibilityInspector"},
}, function(entry)
    local app, bundleID = table.unpack(entry)
    table.insert(consoleToolbar, {
        id = bundleID,
        label = app,
        tooltip = app,
        image = image.imageFromAppBundle(bundleID),
        fn = function(bar, attachedTo, item)
            application.launchOrFocusByBundleID(bundleID)
        end,
        default = false,
    })
end)

table.insert(consoleToolbar, {
    id = "internet",
    label = "Internet",
    tooltip = "Internet Status",
    image = image.imageFromName(module.watchInternetStatus:value() and "NSToolbarBookmarks" or "NSStopProgressFreestandingTemplate"),
    fn = function(bar, attachedTo, item)
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "privateVPN",
    label = "Private VPN",
    tooltip = "Private VPN State",
    image = image.imageFromName(module.watchVPNStatus:value() and "NSLockLockedTemplate" or "NSLockUnlockedTemplate"),
    fn = function(bar, attachedTo, item)
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "hammerspoonDocumentation",
    label = "HS Documentation",
    tooltip = "Show HS Documentation Browser",
    image = image.imageFromName("NXHelpIndex"),
    fn = function(bar, attachedTo, item)
        local base = require"hs.doc.hsdocs"
        if not base._browser then
            base.help()
        else
            base._browser:show()
        end
    end,
    default = false,
})

table.insert(consoleToolbar, {
    id = "cheatsheet",
    label = "CheatSheet Status",
    tooltop = "Toggle CheatSheet Functionality",
    image = module.watchCheatSheetStatus:value() and cheatSheetOn or cheatSheetOff,
    fn = function(t, a, i)
        _asm._keys.cheatsheet.toggle()
    end,
    default = false,
})

-- get list of hammerspoon modules
local list = {}

-- local input = io.open(hs.docstrings_json_file, "rb")
-- local converted = require"hs.json".decode(input:read("a")),
-- input:close()
--
-- for i,v in ipairs(converted) do
--     table.insert(list1, v.name)
-- --     if v.items then
-- --         for i2, v2 in ipairs(converted) do
-- --             table.insert(list, v.name .. "." .. v2.name)
-- --         end
-- --     end
-- end

-- a little uglier, misses "space-holder, empty-of-functions" modules (like hs.spaces, which hs no formal definition in the docs, but is auto-created as a place-holder for hs.spaces.watcher), but faster
local examine
examine = function(tblName)
    local myTable = {}
    for i, v in pairs(tblName) do
        if type(v) == "table" then
            if v.__name == v.__path then
                table.insert(myTable, v.__name)
                local more = examine(v)
                if #more > 0 then
                    for i2,v2 in ipairs(more) do table.insert(myTable, v2) end
                end
            end
        end
    end
    return myTable
end
list = examine(hs.help.hs)
table.insert(list, "hs")

table.sort(list)

table.insert(consoleToolbar, {
    id = "searchID",
    label = "HS Doc Search",
    tooltip = "Search for a HS function or method",
    fn = function(t, w, i, text)
--         print(("~~ HS Doc Search callback with '%s'"):format(text))
        if text ~= "" then require"hs.doc.hsdocs".help(text) end
    end,
    default = false,

    searchfield               = true,
    searchHistoryLimit        = 10,
    searchHistoryAutosaveName = "HSDocsHistory",
    searchPredefinedSearches  = list,
    searchWidth               = 250,
})

module.toolbar = toolbar.new("_asmConsole_001")
      :addItems(consoleToolbar)
      :canCustomize(true)
      :autosaves(true)
      :setCallback(function(...)
                        print("+++ Oops! You better assign me something to do!")
                   end)

console.toolbar(module.toolbar)

return module
