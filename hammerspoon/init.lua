hs.application.runningApplications()

local log = hs.logger.new('init','debug')
log.i('Initializing') -- will print "[mymodule] Initializing" to the console

function readMyEnv()
  local filePath = os.getenv("HOME") .. "/.myenv"
  local f = io.open(filePath, "r")
  lines = {}
  if f then
    for line in io.lines(filePath) do
      lines[#lines + 1] = line
    end
  end
  f:close()
  return lines
end

function getHostname()
  local f = io.popen("/bin/hostname")
  local hostname = f:read("*a") or ""
  f:close()
  hostname = string.gsub(hostname, "\n$", "")
  return hostname
end

local ENV = readMyEnv()
local HOSTNAME = getHostname()

function isEnv(check)
  return hs.fnutils.contains(ENV, check)
end

local moveMouseScreen = nil

function moveMouseToNextScreen()
    if moveMouseScreen == nil then
        moveMouseScreen = hs.screen.mainScreen()
    end
        
    moveMouseScreen = moveMouseScreen:next()
    local r = moveMouseScreen:frame()

    local centerX = r.w / 2
    local centerY = r.h / 2
    hs.mouse.setRelativePosition({x=centerX, y=centerY}, moveMouseScreen)
end



function preferredScreen()
  return hs.screen.find('BenQ GW2765')
end



function baseMove(x, y, w, h)
  return function()
    local win = hs.window.focusedWindow()
    if win == nil then
        return
    end

    win:moveToUnit({x=x, y=y, w=w, h=h}, 0)
  end
end

function moveToScreenFactory(dir)
  return function()
    local win = hs.window.focusedWindow()
    if win == nil then
      log.i("windows was nil so not moving") 
      return
    end
    if dir == 'N' then win:moveOneScreenNorth(0)
    elseif dir == 'S' then win:moveOneScreenSouth(0)
    elseif dir == 'E' then win:moveOneScreenEast(0)
    elseif dir == 'W' then win:moveOneScreenWest(0)
    end
  end
end

function fullScreen()
  local win = hs.window.focusedWindow()
  if win == nil then
    log.i("windows was nil so not maximizing") 
    return
  end
  win:maximize(0)
end

function typeTimestamp()
  hs.eventtap.keyStroke({'cmd'}, 'b');
  hs.eventtap.keyStrokes(os.date('%Y-%m-%d (%a) %I:%M %p'))
  hs.eventtap.keyStroke({'cmd'}, 'b');
end

function typeDate()
  hs.eventtap.keyStrokes(os.date('%Y-%m-%d'))
end

function typeClipboard()
  local s = hs.pasteboard.readString()
  for i = 1, #s do
    local c = s:sub(i, i)
    hs.eventtap.keyStrokes(c)
    hs.timer.usleep(50000)
  end
end

function cuSlackMeeting()
  local win = hs.window.focusedWindow();

  hs.application.launchOrFocus("Slack");
  hs.eventtap.keyStroke({'cmd'}, '1');
  hs.eventtap.keyStrokes("/status :calendar: meeting");
  hs.eventtap.keyStroke({}, "return");
  hs.eventtap.keyStrokes("/dnd 1 hour");
  hs.eventtap.keyStroke({}, "return");

  if win ~= nil then
    win:focus();
  end
end

function foo()
    co = coroutine.create(function ()
        status, body, headers = hs.http.get(
          "http://192.168.102.5:5000/smart-next/" .. HOSTNAME
        )
        log.i(status)
    end)
    coroutine.resume(co)
end

local windowFocusState = {
  window=nil,
  originalScreen=nil,
  originalFrame=nil
};

function focusWindow()
  local win = hs.window.focusedWindow();

  windowFocusState.window = win
  windowFocusState.originalScreen = win:screen()
  windowFocusState.originalFrame = win:frame()

  win:moveToScreen(preferredScreen())
  win:maximize()
end

function unfocusWindow()
  local win = hs.window.focusedWindow();

  if win ~= windowFocusState.window then
    return
  end

  win:moveToScreen(windowFocusState.originalScreen)
  win:setFrame(windowFocusState.originalFrame)
end

function googleDocMarkListItemDone()
  hs.eventtap.keyStroke({'cmd'}, 'right');
  hs.eventtap.keyStroke({'cmd', 'shift'}, 'left');
  hs.eventtap.keyStroke({'option'}, '/');
  hs.eventtap.keyStrokes('text color: dark gray 1');
  hs.eventtap.keyStroke({}, 'down');
  hs.eventtap.keyStroke({}, 'return');
  hs.eventtap.keyStroke({'cmd', 'shift'}, 'X');
end

function tabSearch()
  if isEnv("shopify_mac") then
    local chrome = hs.application.find("Google Chrome")
    local windowToUse = hs.window.focusedWindow()

    if windowToUse:application() ~= chrome then
      local currentScreen = hs.screen.mainScreen()
      windowToUse = hs.fnutils.find(
        chrome:allWindows(),
        function(win)
          return win:screen() == currentScreen
        end
      )

      if windowToUse == nil then
        windowToUse = chrome:allWindows()[1]
      end
    end

    hs.timer.doAfter(0.001, function ()
      windowToUse:focus()
      hs.eventtap.keyStroke({'shift','cmd'}, 'a');
    end)
  elseif isEnv("personal_mac") then
    local firefox = hs.application.find("Firefox")
    firefox:activate()
    hs.eventtap.keyStroke({"cmd"}, "l")
    hs.eventtap.keyStrokes("% ")
  end
end

--local H = hs.hotkey.modal.new({}, 'F20')
--H:bind('', 'l', nil, hs.toggleConsole);

local HYPER0 = {'ctrl', 'cmd', 'shift', 'alt'};  -- right cmd (mac) | alt (surface)
local HYPER1 = {'ctrl', 'cmd', 'shift'}; -- right option/alt (mac) | app/menu (surface)

--                                      x     y     w     h
hs.hotkey.bind(HYPER0, 'a', baseMove(0.00, 0.00, 0.50, 1.00))  -- split left
hs.hotkey.bind(HYPER0, 'w', baseMove(0.00, 0.00, 1.00, 0.50))  -- split top
hs.hotkey.bind(HYPER0, 's', baseMove(0.00, 0.50, 1.00, 0.50))  -- split bottom
hs.hotkey.bind(HYPER0, 'd', baseMove(0.50, 0.00, 0.50, 1.00))  -- split right

hs.hotkey.bind(HYPER0, '1', baseMove(0.00, 0.00, 1.00, 0.33)) -- top third
hs.hotkey.bind(HYPER0, '2', baseMove(0.00, 0.33, 1.00, 0.33)) -- middle third
hs.hotkey.bind(HYPER0, '3', baseMove(0.00, 0.66, 1.00, 0.34)) -- bottom third

hs.hotkey.bind(HYPER1, '1', baseMove(0.00, 0.00, 0.33, 1.00)) -- top third
hs.hotkey.bind(HYPER1, '2', baseMove(0.33, 0.00, 0.33, 1.00)) -- middle third
hs.hotkey.bind(HYPER1, '3', baseMove(0.66, 0.00, 0.34, 1.00)) -- bottom third

hs.hotkey.bind(HYPER0, 'q', baseMove(0.00, 0.00, 0.50, 0.50))  -- top left
hs.hotkey.bind(HYPER0, 'e', baseMove(0.50, 0.00, 0.50, 0.50))  -- top right
hs.hotkey.bind(HYPER0, 'c', baseMove(0.50, 0.50, 0.50, 0.50))  -- bottom right
hs.hotkey.bind(HYPER0, 'z', baseMove(0.00, 0.50, 0.50, 0.50))  -- bottom left

hs.hotkey.bind(HYPER0, 'x', fullScreen)

hs.hotkey.bind(HYPER1, 'a', moveToScreenFactory('W'))
hs.hotkey.bind(HYPER1, 'w', moveToScreenFactory('N'))
hs.hotkey.bind(HYPER1, 's', moveToScreenFactory('S'))
hs.hotkey.bind(HYPER1, 'd', moveToScreenFactory('E'))

-- hs.hotkey.bind({'ctrl', 'cmd', 'alt', 'shift'}, 'l', hs.toggleConsole);
hs.hotkey.bind({'ctrl', 'cmd', 'alt'}, 'V', typeClipboard);
-- hs.hotkey.bind({'cmd', 'shift'}, '-', hs.toggleConsole);
hs.hotkey.bind(HYPER0, 'M', cuSlackMeeting);
hs.hotkey.bind(HYPER0, 'F', focusWindow);
hs.hotkey.bind(HYPER1, 'F', unfocusWindow);
hs.hotkey.bind(HYPER0, 'L', googleDocMarkListItemDone);
hs.hotkey.bind(HYPER0, 'T', typeDate);

hs.hotkey.bind(HYPER1, 'home', moveMouseToNextScreen)

hs.hotkey.bind(HYPER1, '/', foo);

hs.hotkey.bind({'option'}, 't', tabSearch)

ampOnIcon = [[ASCII:
.....1a..........AC..........E
..............................
......4.......................
1..........aA..........CE.....
e.2......4.3...........h......
..............................
..............................
.......................h......
e.2......6.3..........t..q....
5..........c..........s.......
......6..................q....
......................s..t....
.....5c.......................
]]

ampOffIcon = [[ASCII:
.....1a.....x....AC.y.......zE
..............................
......4.......................
1..........aA..........CE.....
e.2......4.3...........h......
..............................
..............................
.......................h......
e.2......6.3..........t..q....
5..........c..........s.......
......6..................q....
......................s..t....
...x.5c....y.......z..........
]]


-- caffeine replacement
local caffeine = hs.menubar.new()

function setCaffeineDisplay(state)
    if state then
        caffeine:setIcon(ampOnIcon)
    else
        caffeine:setIcon(ampOffIcon)
    end
end

function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

caffeine:setClickCallback(caffeineClicked)
setCaffeineDisplay(hs.caffeinate.get("displayIdle"))

tpadHereIcon = [[ASCII:
a==========d
=..........=
=.f......i.=
=..........=
=.k......l.=
=..........=
=..........=
=..........=
=..........=
=..........=
=..........=
=.g......h.=
=..........=
b==========c
]]

tpadGoneIcon = [[ASCII:
a==========d
=..........=
=.f......i.=
=..........=
=.k......l.=
=..........=
=...A..B...=
=..........=
=..........=
=...D..C...=
=..........=
=.g......h.=
=..........=
b==========c
]]

-- local tpadLocation = hs.menubar.new()

function toggleTPadLocation()
    cmd = "/usr/local/bin/blueutil "
    local handle = io.popen(cmd .. "-p")
    local result = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
    handle:close()

    if result == "0" then
        os.execute("ssh 192.168.102.6 " .. cmd .. "-p 0")
        os.execute(cmd .. "-p 1")
        tpadLocation:setIcon(tpadHereIcon)
    else
        os.execute(cmd .. "-p 0")
        os.execute("ssh 192.168.102.6 " .. cmd .. "-p 1")
        tpadLocation:setIcon(tpadGoneIcon)
    end
end


-- tpadLocation:setIcon(tpadGoneIcon)
-- tpadLocation:setClickCallback(toggleTPadLocation)
