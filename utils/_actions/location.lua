-- i have a date/time format for logging that I like, but others copying this may not
local timestamp = timestamp
if not timestamp then timestamp = os.date end

local module       = {}
local location     = require("hs.location")
local settings     = require("hs.settings")
local canvas       = require("hs.canvas")
local screen       = require("hs.screen")
local stext        = require("hs.styledtext")
local timer        = require("hs.timer")
local reachability = require("hs.network.reachability")

-- _asm.monitoredLocations should be an array of the format:
-- {
--     {
--         identifier = "Home",  -- an arbitrary label of our own choosing
--         latitude = xx.xx,
--         longitude =  yy.yy,
--         radius = 50,          -- in meters
--         notifyOnEntry = true, -- if you want a callback when we enter the region
--         notifyOnExit = true   -- if you want a callback when we leave the region
--     }, {
--         identifier = "Library",
--         latitude = xx.xx,
--         longitude = yy.yy,
--         radius = 50,
--         notifyOnEntry = true,
--         notifyOnExit = true
--     }, etc.
-- }

local regions = settings.get("_asm.monitoredLocations") or {}
if #regions == 0 then
    print("~~ No regions specified in _asm.monitoredLocations, use hs.settings.set to specify them") ;
end

local label = canvas.new{}:behavior("canJoinAllSpaces"):level("popUpMenu"):show()
label[1] = {
    type             = "rectangle",
    action           = "strokeAndFill",
    strokeColor      = { red = .75, blue = .75, green = .75, alpha = .75 },
    fillColor        = { alpha = .75 },
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    clipToPath       = true,
}
label[2] = {
    type = "text",
}

local updateLabel = function(err)
    local sf   = screen.primaryScreen():fullFrame()
    local text = stext.new(err or module.labelWatcher:currentRegion() or "Unknown", {
        font = { name = "Menlo-Italic", size = 12, },
        color = ( err and { red = .75, blue = .75, green = .25, alpha = .75 } ) or
                (
                    module.labelWatcher:currentRegion() and
                        { red = .25, blue = .75, green = .75, alpha = .75 } or
                        { red = .75, blue = .25, green = .75, alpha = .75 }
                ),
        paragraphStyle = { alignment = "center", lineBreak = "clip" }
    })
    local textSz = label:minimumTextSize(2, text)
    label:frame{
        x = sf.x + sf.w - (100 + textSz.w),
        y = sf.y + sf.h - (4 + textSz.h),
        h = textSz.h + 3,
        w = textSz.w + 6,
    }
    label[2].frame = { x = 3, y = 0, h = textSz.h, w = textSz.w }
    label[2].text = text
end

local notifiedAboutInternet = false

local geocoderRequest
geocoderRequest = function()
    if not module._geocoder then
        if location.get() then
            module._geocoder = location.geocoder.lookupLocation(location.get(), function(good, result)
                module.addressInfo = result
                print(timestamp() .. ": Location = " .. (result and result[1] and result[1].name))
                if good then
                    notifiedAboutInternet = false
                    module._geocoder = nil
                else
                    if module.internetCheck:status() & reachability.flags.reachable > 0 then
                        print("~~ " .. timestamp() .. " geocoder error: " .. result .. ", will try again in 60 seconds")
                    elseif not notifiedAboutInternet then
                        print("~~ " .. timestamp() .. " geocoder requires internet access, waiting until reachability changes")
                        notifiedAboutInternet = true
                    end
                    module._geocoder = timer.doAfter(60, function()
                        module._geocoder = nil
                        geocoderRequest()
                    end)
                end
            end)
        else
            module._geocoder = timer.doAfter(60, function()
                module._geocoder = nil
                geocoderRequest()
            end)
        end
    end
end

module.internetCheck = reachability.internet()
module.label = label
module.labelWatcher = location.new():callback(function(self, message, ...)
    if message:match("Region$") then updateLabel(table.pack(...)[2]) end -- will be nil unless error
    if message == "didEnterRegion" or message == "didExitRegion" then geocoderRequest() end
end)
for i,v in ipairs(regions) do module.labelWatcher:addMonitoredRegion(v) end
geocoderRequest()

---- secondary watcher for testing -- not a great example since the whole point of adding an object/method
---- interface to hs.location was to allow different code to monitor for different region changes, but as a
---- proof-of-concept, it'll do for now...
--
--module.manager = location.new():callback(function(self, message, ...)
--    print(string.format("~~ %s:%s\n   %s", timestamp(), message, (inspecta(table.pack(...)):gsub("%s+", " "))))
--end)
--
---- just so they have at least some differences
--local doit = true
--for i,v in ipairs(regions) do
--    if doit then
--        module.manager:addMonitoredRegion(v)
--    end
--    doit = not doit
--end

return module
