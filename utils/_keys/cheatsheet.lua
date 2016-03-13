-- modified from code found at https://github.com/dharmapoudel/hammerspoon-config
--
-- Modified to more closely match my usage style and test some possible additions proposed for hs.application

------------------------------------------------------------------------
--/ Cheatsheet Copycat /--
------------------------------------------------------------------------

-- local commandEnum = {
--       [0] = '⌘',
--       [1] = '⇧ ⌘',
--       [2] = '⌥ ⌘',
--       [3] = '^ ⌥ ⌘',
--       [4] = '⌃ ⌘',
--       [5] = '⇧ ⌃ ⌘',
--       [7] = '',
--       [12] ='⌃',
--       [13] ='⌃',
--     }

-- gleaned from http://superuser.com/questions/415213/mac-app-to-compile-and-reference-keyboard-shortcuts

local commandEnum = {
    [0] = '⌘',
          '⇧⌘',
          '⌥⌘',
          '⌥⇧⌘',
          '⌃⌘',
          '⌃⇧⌘',
          '⌃⌥⌘',
          '⌃⌥⇧⌘',
          '',
          '⇧',
          '⌥',
          '⌥⇧',
          '⌃',
          '⌃⇧',
          '⌃⌥',
          '⌃⌥⇧',
}

local glyphs = {
    [2] = "⇥",
    [3] = "⇤",
    [4] = "⌤",
    [9] = "␣",
    [10] = "⌦",
    [11] = "↩",
    [16] = "↓",
    [17] = "⌘",
    [23] = "⌫",
    [24] = "←",
    [25] = "↑",
    [26] = "→",
    [27] = "⎋",
    [28] = "⌧",
    [98] = "⇞",
    [99] = "⇪",
    [100] = "←",
    [101] = "→",
    [102] = "↖",
    [104] = "↑",
    [105] = "↘",
    [106] = "↓",
    [107] = "⇟",
    [111] = "F1",
    [112] = "F2",
    [113] = "F3",
    [114] = "F4",
    [115] = "F5",
    [116] = "F6",
    [117] = "F7",
    [118] = "F8",
    [119] = "F9",
    [120] = "F10",
    [121] = "F11",
    [122] = "F12",
    [135] = "F13",
    [136] = "F14",
    [137] = "F15",
    [140] = "⏏",
    [143] = "F16",
    [144] = "F17",
    [145] = "F18",
    [146] = "F19",
}

-- make the functions all local so we don't pollute the global namespace

local getAllMenuItems -- forward reference

local getAllMenuItemsTable = function(t)
      local menu = {}
          for pos,val in pairs(t) do
              if(type(val)=="table") then
                  if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") then
                      menu[pos] = {}
                      menu[pos]['AXTitle'] = val['AXTitle']
                      menu[pos][1] = getAllMenuItems(val['AXChildren'][1])
                  elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                    if( val['AXMenuItemCmdModifiers'] ~='0' and (val['AXMenuItemCmdChar'] ~='' or type(val['AXMenuItemCmdGlyph']) == "number")) then
                        menu[pos] = {}
                        menu[pos]['AXTitle'] = val['AXTitle']
                        if val['AXMenuItemCmdChar'] == "" then
                            menu[pos]['AXMenuItemCmdChar'] = glyphs[val['AXMenuItemCmdGlyph']] or "?"..tostring(val['AXMenuItemCmdGlyph']).."?"
                        else
                            menu[pos]['AXMenuItemCmdChar'] = val['AXMenuItemCmdChar']
                        end
                        menu[pos]['AXMenuItemCmdModifiers'] = val['AXMenuItemCmdModifiers']
                      end
                  elseif(val['AXRole'] =="AXMenuItem" and type(val['AXChildren']) == "table") then
                      menu[pos] = {}
                      menu[pos][1] = getAllMenuItems(val['AXChildren'][1])
                  end
              end
          end
      return menu
end


getAllMenuItems = function(t)
    local menu = ""
        for pos,val in pairs(t) do
            if(type(val)=="table") then
                -- do not include help menu for now until I find best way to remove menubar items with no shortcuts in them
                if(val['AXRole'] =="AXMenuBarItem" and type(val['AXChildren']) == "table") and val['AXTitle'] ~="Help" then
                    menu = menu.."<ul class='col col"..pos.."'>"
                    menu = menu.."<li class='title'><strong>"..val['AXTitle'].."</strong></li>"
                    menu = menu.. getAllMenuItems(val['AXChildren'][1])
                    menu = menu.."</ul>"
                elseif(val['AXRole'] =="AXMenuItem" and not val['AXChildren']) then
                    if( val['AXMenuItemCmdModifiers'] ~='0' and (val['AXMenuItemCmdChar'] ~='' or type(val['AXMenuItemCmdGlyph']) == "number")) then
                        if val['AXMenuItemCmdChar'] == "" then
                            menu = menu.."<li><div class='cmdModifiers'>"..commandEnum[val['AXMenuItemCmdModifiers']].." "..(glyphs[val['AXMenuItemCmdGlyph']] or "?"..tostring(val['AXMenuItemCmdGlyph']).."?").."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                        else
                            menu = menu.."<li><div class='cmdModifiers'>"..commandEnum[val['AXMenuItemCmdModifiers']].." "..val['AXMenuItemCmdChar'].."</div><div class='cmdtext'>".." "..val['AXTitle'].."</div></li>"
                        end
                    end
                elseif(val['AXRole'] =="AXMenuItem" and type(val['AXChildren']) == "table") then
                    menu = menu..getAllMenuItems(val['AXChildren'][1])
                end

            end
        end
    return menu
end

local generateHtml = function()
    --local focusedApp= hs.window.frontmostWindow():application()
    local focusedApp = require("hs.application").frontmostApplication()
    local appTitle = focusedApp:title()
    local allMenuItems = focusedApp:getMenuItems();
    local myMenuItems = getAllMenuItems(allMenuItems)

    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:0; padding:0;}
            html, body{
              background-color:#eee;
              font-family: arial;
              font-size: 13px;
            }
            a{
              text-decoration:none;
              color:#000;
              font-size:12px;
            }
            li.title{ text-align:center;}
            ul, li{list-style: inside none; padding: 0 0 5px;}
            footer{
              position: fixed;
              left: 0;
              right: 0;
              height: 48px;
              background-color:#eee;
            }
            header{
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height:48px;
              background-color:#eee;
              z-index:99;
            }
            footer{ bottom: 0; }
            header hr,
            footer hr {
              border: 0;
              height: 0;
              border-top: 1px solid rgba(0, 0, 0, 0.1);
              border-bottom: 1px solid rgba(255, 255, 255, 0.3);
            }
            .title{
                padding: 15px;
            }
            li.title{padding: 0  10px 15px}
            .content{
              padding: 0 0 15px;
              font-size:12px;
              overflow:hidden;
            }
            .content.maincontent{
            position: relative;
              height: 577px;
              margin-top: 46px;
            }
            .content > .col{
              width: 23%;
              padding:10px 0 20px 20px;
            }

            li:after{
              visibility: hidden;
              display: block;
              font-size: 0;
              content: " ";
              clear: both;
              height: 0;
            }
            .cmdModifiers{
              width: 60px;
              padding-right: 15px;
              text-align: right;
              float: left;
              font-weight: bold;
            }
            .cmdtext{
              float: left;
              overflow: hidden;
              width: 165px;
            }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]]..appTitle..[[</strong></div>
              <hr />
            </header>
            <div class="content maincontent">]]..myMenuItems..[[</div>

          <footer>
            <hr />
              <div class="content" >
                <div class="col">
                  by <a href="https://github.com/dharmapoudel" target="_parent">dharma poudel</a>
                </div>
              </div>
          </footer>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.isotope/2.2.2/isotope.pkgd.min.js"></script>
        	<script type="text/javascript">
              var elem = document.querySelector('.content');
              var iso = new Isotope( elem, {
                // options
                itemSelector: '.col',
                layoutMode: 'masonry'
              });
              console.log("test");
            </script>
          </body>
        </html>
        ]]

    return html
end



local myView = nil

-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "C", function()
--   if not myView then
--     myView = hs.webview.new({x = 100, y = 100, w = 1080, h = 600}, { developerExtrasEnabled = true })
--       :windowStyle("utility")
--       :closeOnEscape(true)
--       :html(generateHtml())
--       :allowGestures(true)
--       :windowTitle("CheatSheets")
--       :show()
--     --myView:asHSWindow():focus()
--     --myView:asHSDrawing():setAlpha(.98):bringToFront()
--   else
--     myView:delete()
--     myView=nil
--   end
-- end)

-- I prefer a different type of key invocation/remove setup
local alert  = require("hs.alert")
local hotkey = require("hs.hotkey")
local timer  = require("hs.timer")

local cs = hotkey.modal.new({"cmd", "alt"}, "return")
    function cs:entered()
        alert("Building Cheatsheet Display...")
        -- Wrap in timer so alert has a chance to show when building the display is slow (I'm talking
        -- to you, Safari!).  Using a value of 0 seems to halt the alert animation in mid-sequence,
        -- so we use something almost as "quick" as 0.  Need to look at hs.timer someday and figure out
        -- why; perhaps 0 means "dispatch immediately, even before anything else in the queue"?
        timer.doAfter(.1, function()
            local screenFrame = require("hs.screen").mainScreen():frame()
            local viewFrame = {
                x = screenFrame.x + 100,
                y = screenFrame.y + 100,
                h = screenFrame.h - 200,
                w = screenFrame.w - 200,
            }
            myView = require("hs.webview").new(viewFrame, { developerExtrasEnabled = true })
              :windowStyle("utility")
              :closeOnEscape(true)
              :html(generateHtml())
              :allowGestures(true)
              :windowTitle("CheatSheets")
              :setLevel(require("hs.drawing").windowLevels.floating)
              :show()
              alert.closeAll() -- hide alert, if we finish fast enough
            --myView:asHSWindow():focus()
            --myView:asHSDrawing():setAlpha(.98):bringToFront()
        end)
    end
    function cs:exited()
        myView:delete()
        myView=nil
    end
cs:bind({}, "ESCAPE", function() cs:exit() end)
cs:bind({"cmd", "alt"}, "return", function() cs:exit() end) -- match the invoker, in case you're used to that


-- meet the expectations of my folder loader function... -- ASM
local module = {}
return module