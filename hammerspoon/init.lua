hs.application.runningApplications()
hs.allowAppleScript(true);

log = hs.logger.new('init','debug')
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

function findScreen(name)
  return hs.fnutils.find(
    hs.screen.allScreens(),
    function (screen) return screen:name() == name end
  )
end

function setupMonitors()
  local samsung_32 = findScreen("U32J59x")
  local macbook = findScreen("Built-in Retina Display")
  local benq_27 = findScreen("Benq Gw2765")
  local lg_27 = findScreen("LG HDR 4K")
  local screen_layout = {}

  if samsung_32 and macbook and benq_27 and lg_27 then
    screen_layout[samsung_32:id()] = { N=nil, S=nil, E=lg_27, W=benq_27 }
    screen_layout[macbook:id()] = { N=lg_27, S=nil, E=samsung_32, W=lg_27 }
    screen_layout[benq_27:id()] = { N=nil, S=macbook, E=samsung_32, W=lg_27 }
    screen_layout[lg_27:id()] = { N=nil, S=nil, E=benq_27, W=samsung_32 }

  elseif samsung_32 and macbook and lg_27 then
    local center_top = samsung_32
    local left = macbook
    local right = lg_27

    screen_layout[center_top:id()] = { N=nil, S=nil, E=right, W=left }
    screen_layout[left:id()] = { N=nil, S=nil, E=center_top, W=nil }
    screen_layout[right:id()] = { N=nil, S=nil, E=nil, W=center_top }

  elseif samsung_32 and macbook then
    screen_layout[samsung_32:id()] = { N=nil, S=macbook, E=macbook, W=nil }
    screen_layout[macbook:id()] = { N=samsung_32, S=nil, E=nil, W=samsung_32 }
  end

  return screen_layout
end

SCREEN_LAYOUT = setupMonitors()

function moveToScreenFactory(dir)
  return function()
    local win = hs.window.focusedWindow()
    if win == nil then
      log.i("windows was nil so not moving") 
      return
    end
    local targetScreen = SCREEN_LAYOUT[win:screen():id()][dir]
    if targetScreen ~= nil then
      win:moveToScreen(targetScreen, false, true, 0) 
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

function typeClipboard()
  local s = hs.pasteboard.readString()
  for i = 1, #s do
    local c = s:sub(i, i)
    hs.eventtap.keyStrokes(c)
    hs.timer.usleep(50000)
  end
end

function foo()
    co = coroutine.create(function ()
      local url = "http://192.168.102.5:5000/smart-next/" .. HOSTNAME
      log.i(url)
      status, body, headers = hs.http.get(url)
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

function collectAllWindows()
  local targetScreen = hs.mouse.getCurrentScreen()
  for _, win in ipairs(hs.window.allWindows()) do
    win:moveToScreen(targetScreen)
  end
end

MOUSE_NEXT_SCREEN = hs.fnutils.cycle(hs.screen.allScreens())
function moveMouseToNextScreen()
  local screen = MOUSE_NEXT_SCREEN()
  local r = screen:frame()
  local centerX = r.w / 2
  local centerY = r.h / 2
  hs.mouse.setRelativePosition({x=centerX, y=centerY}, screen)
end

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

hs.hotkey.bind(HYPER0, hs.keycodes.map["pad1"], baseMove(0.00, 0.00, 1.00, 0.25)) -- first fourth
hs.hotkey.bind(HYPER0, hs.keycodes.map["pad2"], baseMove(0.00, 0.25, 1.00, 0.25)) -- second fourth

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

hs.hotkey.bind({'ctrl', 'cmd', 'alt'}, 'V', typeClipboard);
hs.hotkey.bind(HYPER0, 'F', focusWindow);
hs.hotkey.bind(HYPER1, 'F', unfocusWindow);

hs.hotkey.bind(HYPER0, 'y', moveMouseToNextScreen)
hs.hotkey.bind(HYPER1, 'y', collectAllWindows)

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

function organize()
  local benq27 = findScreen("Benq Gw2765")

  local CAL = "📅"
  local PIN = "📌"

  local layout = {
    {app="Google Chrome", window="Dashboard", frame={x=-1440.0,y=-1008.0,w=1440.0,h=190.0}, unit={x=0,y=0.000,h=0.073,w=1.0}, height=0.073},
    {app="Google Chrome", window=CAL, frame={x=-1440.0,y=-817.0,w=1440.0,h=644.0},          unit={x=0,y=0.073,h=0.257,w=1.0}, height=0.257},
    {app="Google Chrome", window=PIN, frame={x=-1440.0,y=-172.0,w=1440.0,h=836.0},          unit={x=0,y=0.257,h=0.330,w=1.0}, height=0.330},
    {app="Slack", window=".*", frame={x=-1440.0,y=665.0,w=1440.0,h=861.0},                  unit={x=0,y=0.660,h=0.340,w=1.0}, height=0.340},
  }

  local accumHeight = 0.0
  for _, appwin in ipairs(layout) do
      -- hs.application(appwin["app"]):findWindow(appwin["window"]):setFrame(appwin["frame"])
      -- hs.application(appwin["app"]):findWindow(appwin["window"]):move({x=0,y=0,w=1.0h=0.5}, benq_27)
      local win = hs.application(appwin["app"]):findWindow(appwin["window"])
      win:moveToScreen(benq27)
      win:moveToUnit({x=0,y=accumHeight,w=1,h=appwin["height"]})
      accumHeight = accumHeight + appwin["height"]
  end
end