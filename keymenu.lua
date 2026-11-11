--[[
  BlackAir Key Menu  v3.1
  Open source (MIT). Use it, change it, ship it in your hub.
  https://protect.blackair.dev/docs/key-menu
  https://github.com/MrEye12/blackair-keymenu

  A ready key window for Roblox scripts. It takes the colors and style you set in the
  BlackAir dashboard (Style tab), checks keys with the BlackAir Key API, remembers the key,
  and starts your script when the key is good. Works without BlackAir too: pass your own `verify`.

  -- Quick start --------------------------------------------------------------
    local KeyMenu = loadstring(game:HttpGet("https://protect.blackair.dev/keymenu.lua"))()
    KeyMenu.new({
      scriptId = "YOUR-SCRIPT-ID",       -- from the BlackAir dashboard
    })
  That is all. The player enters a key, it is checked, and your protected script loads.

  -- All options --------------------------------------------------------------
    scriptId    string   BlackAir script ID. Needed unless you pass `verify`.
    title       string   Window title. Default: your script name.
    subtitle    string   Small text under the title.
    colors      table    { bg = "#0A0A0A", accent = "#FFFFFF", text = "#FFFFFF" }. Default: from the dashboard.
    getKeyUrl   string   Link for "Get key". Default: your BlackAir key page.
    discord     string   Link for "Discord". Default: the community link of your key page.
    remember    boolean  Save the key on this device and try it next time. Default: true.
    autoLoad    boolean  Run the BlackAir loader after a good key. Default: true.
    onSuccess   function(key, info)   Called after a good key (info = expiry, executions...).
    onClose     function()            Called when the player closes the window.
    verify      function(key) -> ok, message   Your own check (any key system).
    showGet, showDiscord  boolean   Hide one of the two small buttons.
    style       table    Override look options from the dashboard, for example:
                         { kmLayout = "split", kmIcon = "game", kmSteps = true, kmCover = 1234567890 }
                         kmLayout   card | split | compact | sheet
                         kmIcon     none | letter | game | avatar | image   (kmImage = Roblox image id)
                         kmCover    Roblox image id for a picture on top (left side in split)
                         kmSteps, kmPaste, kmDim, kmBrand, kmClose   true / false
                         kmBtn      filled | outline     kmNote, kmPlaceholder   your own text
  Texts and both buttons can also be set in the dashboard (Style tab > Key menu).

  -- Other helpers ------------------------------------------------------------
    KeyMenu.check(scriptId, key)  -> ok, message, info     Check a key without a window.
    menu:Close()                                           Close the window from your code.
]]

local KeyMenu = {}
KeyMenu.__index = KeyMenu
KeyMenu.API = "https://protect.blackair.dev"
KeyMenu.Version = "3.1"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- -- small helpers -----------------------------------------------------------
local function try(fn, ...) local ok, a, b, c = pcall(fn, ...) if ok then return a, b, c end end
-- Executors cache HttpGet by URL, so every request gets a fresh r= value.
local function fresh(url) return url .. (url:find("?", 1, true) and "&" or "?") .. "r=" .. (math.floor(os.clock() * 1000000) % 1000000000) .. math.random(1, 999999) end
local function get(url) return try(function() return game:HttpGet(fresh(url)) end) end
local function decode(s) return s and try(function() return HttpService:JSONDecode(s) end) end
local function enc(s) return HttpService:UrlEncode(tostring(s or "")) end
local function tween(o, t, props, style) try(function() TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play() end) end
local function new(class, props, parent)
  local o = Instance.new(class)
  for k, v in pairs(props or {}) do o[k] = v end
  if parent then o.Parent = parent end
  return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function hex(h, fallback) return try(function() return Color3.fromHex(h) end) or Color3.fromHex(fallback) end
local function onColor(c) return (c.R * 0.299 + c.G * 0.587 + c.B * 0.114) > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1) end
local function guiParent()
  return try(function() return gethui and gethui() end) or try(function() return game:GetService("CoreGui") end) or Players.LocalPlayer:WaitForChild("PlayerGui")
end
local function hwid()
  return try(function() return gethwid and gethwid() end) or try(function() return game:GetService("RbxAnalyticsService"):GetClientId() end) or ""
end
local function copy(text) return try(function() setclipboard(text) return true end) end

local FONTS = {
  builder = { "BuilderSans", "BuilderSansMedium", "BuilderSansBold" }, gotham = { "Gotham", "GothamMedium", "GothamBold" },
  nunito = { "Nunito", "Nunito", "Nunito" }, ubuntu = { "Ubuntu", "Ubuntu", "Ubuntu" }, mono = { "RobotoMono", "RobotoMono", "RobotoMono" },
  fredoka = { "FredokaOne", "FredokaOne", "FredokaOne" }, oswald = { "Oswald", "Oswald", "Oswald" },
  montserrat = { "Montserrat", "MontserratMedium", "MontserratBold" },
  roboto = { "Roboto", "Roboto", "Roboto" },
  source = { "SourceSans", "SourceSansSemibold", "SourceSansBold" },
  arimo = { "Arimo", "Arimo", "ArimoBold" },
  titillium = { "TitilliumWeb", "TitilliumWeb", "TitilliumWeb" },
  josefin = { "JosefinSans", "JosefinSans", "JosefinSans" },
  jura = { "Jura", "Jura", "Jura" },
  michroma = { "Michroma", "Michroma", "Michroma" },
  sarpanch = { "Sarpanch", "Sarpanch", "Sarpanch" },
  merriweather = { "Merriweather", "Merriweather", "Merriweather" },
  bangers = { "Bangers", "Bangers", "Bangers" },
  luckiest = { "LuckiestGuy", "LuckiestGuy", "LuckiestGuy" },
}
local function fonts(name)
  local f = FONTS[name] or FONTS.builder
  local ok = try(function() return { r = Enum.Font[f[1]], m = Enum.Font[f[2]], b = Enum.Font[f[3]] } end)
  return ok or { r = Enum.Font.Gotham, m = Enum.Font.GothamMedium, b = Enum.Font.GothamBold }
end

-- -- key check (no window) ---------------------------------------------------
function KeyMenu.check(scriptId, key)
  key = tostring(key or ""):gsub("%s", "")
  if key == "" then return false, "Enter your key first." end
  local body = get(KeyMenu.API .. "/api/v1/check/" .. enc(scriptId) .. "?key=" .. enc(key) .. "&hwid=" .. enc(hwid()))
  local r = decode(body)
  if type(r) ~= "table" then return false, "Could not reach the key server. Try again." end
  if r.code == "KEY_VALID" then return true, "Key accepted.", r.data end
  return false, tostring(r.message or "That key does not work.")
end

-- -- the window --------------------------------------------------------------
function KeyMenu.new(opts)
  opts = opts or {}
  local self = setmetatable({ opts = opts, closed = false }, KeyMenu)
  local id = opts.scriptId

  -- Look and links from the dashboard (Style tab and key page), unless given here.
  local remote = id and decode(get(KeyMenu.API .. "/api/v1/style/" .. enc(id)))
  remote = type(remote) == "table" and remote or {}
  local c = opts.colors or remote.colors or {}
  local ui = type(remote.ui) == "table" and remote.ui or {}
  if type(opts.style) == "table" then for k, v in pairs(opts.style) do ui[k] = v end end
  local BG, ACC, TXT = hex(c.bg or "#0A0A0A", "#0A0A0A"), hex(c.accent or "#FFFFFF", "#FFFFFF"), hex(c.text or "#FFFFFF", "#FFFFFF")
  -- Haupt-Knopf, seine Schrift und Titel: eigene Farben aus dem Style-Reiter, sonst Akzent / passend / Text
  local BTN = type(ui.btn) == "string" and ui.btn ~= "" and hex(ui.btn, "#FFFFFF") or ACC
  local ON = type(ui.btnText) == "string" and ui.btnText ~= "" and hex(ui.btnText, "#000000") or onColor(BTN)
  local TITLE = type(ui.title) == "string" and ui.title ~= "" and hex(ui.title, "#FFFFFF") or TXT
  local SIDE = try(function() return BG:Lerp(TXT, 0.035) end) or BG
  local OK_C, ERR_C = hex(ui.ok or "#3DDC84", "#3DDC84"), hex(ui.err or "#FF6B6B", "#FF6B6B")
  local LINE = type(ui.line) == "string" and ui.line ~= "" and hex(ui.line, "#FFFFFF") or nil
  local F = fonts(ui.font)
  local R = tonumber(ui.radius) or 10
  local getKeyUrl = opts.getKeyUrl or remote.key_page
  local discord = opts.discord or remote.community
  local remember = opts.remember ~= false
  local file = "blackair/key_" .. tostring(id or "custom"):sub(1, 36) .. ".txt"
  local function nz(v) if type(v) == "string" and v ~= "" then return v end end
  local function flag(k, d) if ui[k] == nil then return d end return ui[k] == true end
  local saved = remember and try(function() return isfile and isfile(file) and readfile(file) end)
  saved = type(saved) == "string" and #saved > 4 and saved or nil

  local cam = workspace.CurrentCamera
  local vw = try(function() return cam.ViewportSize.X end) vw = vw and tonumber(vw) or 1280
  local vh = try(function() return cam.ViewportSize.Y end) vh = vh and tonumber(vh) or 720
  -- Groessere Bildschirme: Fenster waechst mit (Roblox-Pixel sind auf 1440p sonst winzig)
  local S = math.clamp(vh / 820, 1, 1.4) * ((tonumber(ui.zoom) or 100) / 100)
  local room = math.floor(vw / S)

  -- Layout: card (Standard), split (Seite links mit Bild/Titel/Schritten), compact (klein), sheet (unten, fuer Handys)
  local layout = ({ card = 1, split = 1, compact = 1, sheet = 1 })[ui.kmLayout] and ui.kmLayout or "card"
  if layout == "split" and room < 640 then layout = "card" end
  local split, compact, sheet = layout == "split", layout == "compact", layout == "sheet"
  local P = compact and 18 or 22
  local W
  if split then W = 620 elseif sheet then W = math.min(room, 560) elseif compact then W = math.clamp(room - 32, 260, 320) else W = math.clamp(room - 32, 280, 380) end
  if sheet then S = math.min(S, vw / W) end

  local gui = new("ScreenGui", { Name = "BlackAirKeyMenu", ResetOnSpawn = false, IgnoreGuiInset = true, AutoLocalize = false, DisplayOrder = 1100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent())
  self.gui = gui
  local fades = {}
  local function fade(o, prop, value) table.insert(fades, { o, prop, value }) o[prop] = 1 return o end

  -- The game behind gets darker, so the window is the one thing to look at (Style tab can turn it off).
  if flag("kmDim", true) then
    local back = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, gui)
    fade(back, "BackgroundTransparency", 0.4)
  end

  local hy = sheet and 1 or 0.5
  local function at(dy) return UDim2.new(0.5, 0, hy, dy) end
  local outer = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, hy), Position = at(10), Active = true }, gui)
  local scale = new("UIScale", { Scale = S }, outer)
  local card = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = BG, BorderSizePixel = 0 }, outer)
  fade(card, "BackgroundTransparency", 0)
  corner(card, R + 4)
  if sheet then -- square bottom edge, it sits on the screen edge
    fade(new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, R + 6), BackgroundColor3 = BG, BorderSizePixel = 0 }, card), "BackgroundTransparency", 0)
  else
    fade(new("UIStroke", { Color = LINE or TXT, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, card), "Transparency", LINE and 0 or 0.86)
  end

  local TS = try(function() return game:GetService("TextService") end)
  -- Every text gets its full line height: a label exactly as tall as its text gets clipped by Roblox.
  local function height(text, size, font, w)
    local h = TS and try(function() return TS:GetTextSize(text, size, font, Vector2.new(w, 2000)).Y end)
    h = h and tonumber(h)
    local lines = h and math.max(1, math.floor(h / size + 0.35)) or math.max(1, math.ceil(#text * size * 0.55 / w))
    return lines * math.floor(size * 1.35 + 0.5)
  end
  local function label(parent, text, x, y, w, size, font, alpha, align)
    local h = height(text, size, font, w)
    local l = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, h), Font = font, TextSize = size,
      TextColor3 = TXT, TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = text }, parent)
    fade(l, "TextTransparency", alpha or 0)
    return l, h
  end

  -- Picture next to the title: letter, game icon, player avatar or your own Roblox image (or none)
  local title = opts.title or nz(ui.keyTitle) or remote.name or opts.fallbackTitle or "Key required"
  local function picture(parent, x, y, size)
    local kind = ui.kmIcon or "none"
    if kind == "none" then return 0 end
    local img
    if kind == "game" then img = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
    elseif kind == "avatar" then img = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Players.LocalPlayer and Players.LocalPlayer.UserId or 1) .. "&w=150&h=150"
    elseif kind == "image" and tonumber(ui.kmImage) then img = "rbxassetid://" .. tostring(ui.kmImage) end
    local r = kind == "avatar" and size or math.max(6, R - 2)
    if img then
      local i = new("ImageLabel", { Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, size, 0, size), BackgroundColor3 = TXT, Image = img, ScaleType = Enum.ScaleType.Crop }, parent)
      fade(i, "BackgroundTransparency", 0.94) fade(i, "ImageTransparency", 0)
      corner(i, r)
    else
      local t = new("Frame", { Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, size, 0, size), BackgroundColor3 = TXT, BorderSizePixel = 0 }, parent)
      fade(t, "BackgroundTransparency", 0.93)
      corner(t, r)
      fade(new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = F.b, TextSize = math.floor(size * 0.44), TextColor3 = ACC, Text = string.upper(tostring(title):sub(1, 1)) }, t), "TextTransparency", 0)
    end
    return size
  end
  -- Cover picture: your own Roblox image, inset with round corners
  local function cover(parent, x, y, w, h)
    if not tonumber(ui.kmCover) then return 0 end
    local i = new("ImageLabel", { Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, h), BackgroundColor3 = TXT, Image = "rbxassetid://" .. tostring(ui.kmCover), ScaleType = Enum.ScaleType.Crop }, parent)
    fade(i, "BackgroundTransparency", 0.94) fade(i, "ImageTransparency", 0)
    corner(i, math.max(6, R))
    return h
  end
  -- Steps as one quiet line of text: the current one is bright, done ones turn green
  local stepLabels = {}
  local STEP = { "Get a key", "Paste it", "Play" }
  local function steps(parent, x, y, w, vertical)
    for i = 1, 3 do
      local sx, sy, sw = x, y, vertical and w or math.floor(w / 3)
      if vertical then sy = y + (i - 1) * 24 else sx = x + (i - 1) * sw end
      local l = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, sx, 0, sy), Size = UDim2.new(0, sw, 0, 20), Font = F.m, TextSize = 13, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = i .. "   " .. STEP[i] }, parent)
      fade(l, "TextTransparency", 0.6)
      stepLabels[i] = l
    end
    return vertical and 72 or 20
  end
  local function setStep(s)
    for i, l in ipairs(stepLabels) do
      tween(l, 0.2, { TextTransparency = i == s and 0 or (i < s and 0.15 or 0.6), TextColor3 = i < s and OK_C or TXT })
    end
  end

  local showSteps = flag("kmSteps", false) and not compact
  local note = not compact and nz(ui.kmNote) or nil
  local sub = opts.subtitle or nz(ui.keySub) or "Enter your key to start."
  local close = flag("kmClose", true)
  local colX, colW, y
  local SW = 0
  if split then
    -- left side: picture or cover, title, text, steps
    SW = math.floor(W * 0.42)
    local side = new("Frame", { Size = UDim2.new(0, SW, 1, 0), BackgroundColor3 = SIDE, BorderSizePixel = 0 }, card)
    fade(side, "BackgroundTransparency", 0)
    corner(side, R + 4)
    fade(new("Frame", { Position = UDim2.new(1, -(R + 4), 0, 0), Size = UDim2.new(0, R + 4, 1, 0), BackgroundColor3 = SIDE, BorderSizePixel = 0 }, side), "BackgroundTransparency", 0)
    fade(new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = LINE or TXT, BorderSizePixel = 0 }, side), "BackgroundTransparency", LINE and 0 or 0.9)
    local sy = 10
    local ch = cover(side, 10, 10, SW - 20, 110)
    sy = ch > 0 and (10 + ch + 16) or P
    local pw = picture(side, P, sy, 40)
    if pw > 0 then sy = sy + pw + 14 end
    local tl, th = label(side, title, P, sy, SW - 2 * P, 18, F.b, 0) tl.TextColor3 = TITLE sy = sy + th + 2
    local _, bh = label(side, sub, P, sy, SW - 2 * P, 13, F.r, 0.42) sy = sy + bh
    if showSteps then sy = sy + 20 steps(side, P, sy, SW - 2 * P, true) sy = sy + 72 end
    colX, colW, y = SW + P, W - SW - 2 * P, P
    local el, h1 = label(card, "Enter your key", colX, y - 1, colW - (close and 30 or 0), 16, F.b, 0) el.TextColor3 = TITLE y = y + h1 + 2
    local _, h2 = label(card, getKeyUrl and "No key yet? Get one first, then paste it here." or "Paste the key you got from the script owner.", colX, y, colW, 12, F.r, 0.45)
    y = y + h2
    if note then y = y + 6 local _, nh = label(card, note, colX, y, colW, 12, F.r, 0.55) y = y + nh end
    y = y + 16
    self.sideH = sy + P
  else
    colX, colW, y = P, W - 2 * P, P
    local ch = cover(card, 10, 10, W - 20, compact and 72 or 104)
    if ch > 0 then y = 10 + ch + 16
    else
      -- short accent line on top, like the message card
      local line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 44, 0, 3), BackgroundColor3 = ACC, BorderSizePixel = 0 }, card)
      corner(line, 2)
      fade(line, "BackgroundTransparency", 0)
    end
    local psz = compact and 32 or 40
    local pw = picture(card, colX, y, psz)
    local tx = pw > 0 and colX + pw + 12 or colX
    local tw = colW - (tx - colX) - (close and ch == 0 and 30 or 0)
    local ty = y + (pw > 0 and (compact and 6 or 0) or -1)
    local tl, th = label(card, title, tx, ty, tw, compact and 15 or 17, F.b, 0) tl.TextColor3 = TITLE ty = ty + th
    if not compact then local _, sh = label(card, sub, tx, ty + 1, tw + (close and ch == 0 and pw > 0 and 30 or 0), 13, F.r, 0.42) ty = ty + sh + 1 end
    y = math.max(y + pw, ty)
    if note then y = y + 6 local _, nh = label(card, note, colX, y, colW, 12, F.r, 0.55) y = y + nh end
    y = y + (compact and 14 or 18)
    if showSteps then steps(card, colX, y, colW, false) y = y + 20 + 14 end
  end

  -- close (on a small backing when it sits on a picture)
  local x
  if close then
    local onPic = not split and tonumber(ui.kmCover)
    x = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, onPic and -16 or -12, 0, onPic and 16 or 12), Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = onPic and BG or TXT, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5 }, card)
    corner(x, 8)
    if onPic then fade(x, "BackgroundTransparency", 0.2) end
    local xa = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 1.5), Rotation = 45, BackgroundColor3 = TXT, BorderSizePixel = 0, ZIndex = 5 }, x)
    local xb = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 1.5), Rotation = -45, BackgroundColor3 = TXT, BorderSizePixel = 0, ZIndex = 5 }, x)
    fade(xa, "BackgroundTransparency", 0.45) fade(xb, "BackgroundTransparency", 0.45)
    if not onPic then
      x.MouseEnter:Connect(function() tween(x, 0.12, { BackgroundTransparency = 0.93 }) end)
      x.MouseLeave:Connect(function() tween(x, 0.12, { BackgroundTransparency = 1 }) end)
    end
  end

  -- buttons: main one filled (or outline), the others quiet, like the ban screen
  local outline = ui.kmBtn == "outline"
  local function button(text, bx, by, bw, bh, primary)
    local fillA = primary and (outline and 1 or 0) or 0.94
    local b = new("TextButton", { Position = UDim2.new(0, bx, 0, by), Size = UDim2.new(0, bw, 0, bh), BorderSizePixel = 0, AutoButtonColor = false,
      BackgroundColor3 = primary and BTN or TXT, Font = F.b, TextSize = compact and 13 or 14, TextColor3 = primary and (outline and BTN or ON) or TXT, Text = text }, card)
    fade(b, "BackgroundTransparency", fillA) fade(b, "TextTransparency", 0)
    corner(b, R)
    if primary and outline then fade(new("UIStroke", { Color = BTN, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b), "Transparency", 0.2) end
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = primary and (outline and 0.9 or 0.12) or 0.9 }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = fillA }) end)
    return b
  end

  -- key field (+ Paste as a quiet text button, if the executor can read the clipboard)
  local clip = (type(getclipboard) == "function" and getclipboard) or (type(fromclipboard) == "function" and fromclipboard) or nil
  local paste = flag("kmPaste", true) and clip
  local fh = compact and 40 or 44
  local checkLabel = nz(ui.keyCheck) or "Check key"
  local fw = compact and (colW - 96) or colW
  local field = new("Frame", { Position = UDim2.new(0, colX, 0, y), Size = UDim2.new(0, fw, 0, fh), BackgroundColor3 = TXT, BorderSizePixel = 0 }, card)
  fade(field, "BackgroundTransparency", 0.96)
  corner(field, R)
  local fieldStroke = fade(new("UIStroke", { Color = TXT, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, field), "Transparency", 0.86)
  local box = new("TextBox", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, paste and (compact and -62 or -80) or -24, 1, 0), Font = F.m, TextSize = compact and 13 or 14, TextColor3 = TXT,
    PlaceholderText = nz(ui.kmPlaceholder) or (compact and "Your key" or "Paste your key here"), PlaceholderColor3 = try(function() return TXT:Lerp(BG, 0.55) end) or TXT, Text = "", ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true }, field)
  fade(box, "TextTransparency", 0)
  box.Focused:Connect(function() tween(fieldStroke, 0.15, { Transparency = 0.35, Color = ACC }) end)
  box.FocusLost:Connect(function() tween(fieldStroke, 0.15, { Transparency = 0.86, Color = TXT }) end)
  local pasteBtn
  if paste then
    pasteBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.new(0, compact and 48 or 60, 0, fh - 12), BackgroundColor3 = TXT, AutoButtonColor = false,
      Font = F.m, TextSize = compact and 12 or 13, TextColor3 = TXT, Text = "Paste" }, field)
    fade(pasteBtn, "BackgroundTransparency", 1) fade(pasteBtn, "TextTransparency", 0.35)
    corner(pasteBtn, math.max(4, R - 4))
    pasteBtn.MouseEnter:Connect(function() tween(pasteBtn, 0.12, { BackgroundTransparency = 0.93, TextTransparency = 0 }) end)
    pasteBtn.MouseLeave:Connect(function() tween(pasteBtn, 0.12, { BackgroundTransparency = 1, TextTransparency = 0.35 }) end)
  end
  local checkBtn
  if compact then checkBtn = button(checkLabel, colX + fw + 8, y, 88, fh, true) end
  y = y + fh + 6
  local status = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, colX, 0, y), Size = UDim2.new(0, colW, 0, 17), Font = F.m, TextSize = 12, TextColor3 = TXT,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, card)
  y = y + 17 + 8
  if not compact then checkBtn = button(checkLabel, colX, y, colW, 44, true) y = y + 44 end
  local showGet = ui.showGet ~= false and opts.showGet ~= false
  local showDc = discord and ui.showDiscord ~= false and opts.showDiscord ~= false
  local getBtn, dcBtn
  local rh = compact and 34 or 40
  if showGet or showDc then
    if not compact then y = y + 8 end
    local half = math.floor((colW - 8) / 2)
    local getText = getKeyUrl and (nz(ui.keyGet) or "Get key") or "No key page"
    if showGet and showDc then
      getBtn = button(getText, colX, y, half, rh, false)
      dcBtn = button("Discord", colX + half + 8, y, colW - half - 8, rh, false)
    elseif showGet then getBtn = button(getText, colX, y, colW, rh, false)
    else dcBtn = button("Discord", colX, y, colW, rh, false) end
    y = y + rh
  end
  if flag("kmBrand", true) then
    y = y + 14
    label(card, "Protected by BlackAir", colX, y, colW, 12, F.m, 0.72, Enum.TextXAlignment.Center)
    y = y + 16
  end
  local H = math.max(y + P - 2, self.sideH or 0)
  if sheet then H = H + 8 end
  outer.Size = UDim2.new(0, W, 0, H)
  -- Handys spielen quer: nur ~390 Pixel Hoehe. Dann das ganze Fenster so verkleinern, dass es reinpasst.
  if H * S > vh - 16 then S = math.max(0.55, (vh - 16) / H) scale.Scale = S end

  local function say(text, tone)
    status.Text = text
    status.TextColor3 = tone == "bad" and ERR_C or tone == "good" and OK_C or TXT
    status.TextTransparency = 1
    tween(status, 0.2, { TextTransparency = tone and 0 or 0.4 })
  end
  local function shake()
    local p = outer.Position
    for i, dx in ipairs({ -6, 5, -3, 2, 0 }) do task.delay(i * 0.04, function() try(function() outer.Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset) end) end) end
  end

  -- drag at the top (the bottom sheet stays put)
  local conns = {}
  if not sheet then try(function()
    local dragging, start, startPos
    card.InputBegan:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        local rel = i.Position - card.AbsolutePosition
        if split then if rel.X / S > SW then return end elseif rel.Y / S > 70 then return end
        dragging, start, startPos = true, i.Position, outer.Position
      end
    end)
    table.insert(conns, UserInputService.InputChanged:Connect(function(i)
      if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - start
        outer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
      end
    end))
    table.insert(conns, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
  end) end

  -- open: fade in and move into place, no bounce (the sheet slides up from the edge)
  outer.Position = at(sheet and math.floor(H * S) or 10)
  tween(outer, sheet and 0.35 or 0.25, { Position = at(0) }, Enum.EasingStyle.Quad)
  for _, f in ipairs(fades) do tween(f[1], 0.25, { [f[2]] = f[3] }, Enum.EasingStyle.Quad) end
  if showSteps then task.delay(0.2, function() setStep(saved and 2 or 1) end) end

  function self:Close(silent)
    if self.closed then return end
    self.closed = true
    for _, cn in ipairs(conns) do try(function() cn:Disconnect() end) end
    for _, f in ipairs(fades) do tween(f[1], 0.15, { [f[2]] = 1 }, Enum.EasingStyle.Quad) end
    tween(status, 0.15, { TextTransparency = 1 })
    tween(outer, sheet and 0.25 or 0.15, { Position = at(sheet and math.floor(H * S) or 6) }, Enum.EasingStyle.Quad)
    task.delay(0.28, function() try(function() gui:Destroy() end) end)
    if not silent and opts.onClose then task.spawn(opts.onClose) end
  end
  if x then x.MouseButton1Click:Connect(function() self:Close() end) end

  local function left(info)
    if type(info) ~= "table" then return nil end
    if info.seconds_left == nil and info.expires_at == nil then return "lifetime key" end
    local s = tonumber(info.seconds_left)
    if not s then return nil end
    if s >= 172800 then return math.floor(s / 86400) .. " days left" end
    if s >= 7200 then return math.floor(s / 3600) .. " hours left" end
    return math.max(1, math.floor(s / 60)) .. " minutes left"
  end

  local busy = false
  local function submit(key, quiet)
    if busy or self.closed then return end
    key = tostring(key or ""):gsub("%s", "")
    if key == "" then say("Enter your key first.", "bad") shake() return end
    busy = true
    checkBtn.Text = compact and "..." or "Checking..."
    if not quiet then say("Checking your key...") end
    local ok, msg, info
    if opts.verify then ok, msg = opts.verify(key) msg = msg or (ok and "Key accepted." or "That key does not work.")
    elseif id then ok, msg, info = KeyMenu.check(id, key)
    else ok, msg = false, "No scriptId or verify given." end
    busy = false
    checkBtn.Text = checkLabel
    if not ok then
      if quiet then try(function() if delfile then delfile(file) end end) say("Your saved key ran out. Enter a new one.", "bad") if showSteps then setStep(1) end return end
      say(msg, "bad") shake() return
    end
    if remember then try(function() if not isfolder("blackair") then makefolder("blackair") end writefile(file, key) end) end
    try(function() getgenv().script_key = key end)
    local l = left(info)
    say(l and ("Key accepted, " .. l .. ".") or "Key accepted.", "good")
    if showSteps then setStep(3) end
    checkBtn.Text = compact and "OK" or "Starting..."
    task.delay(0.9, function()
      self:Close(true)
      if opts.autoLoad ~= false and id and not opts.verify then
        -- Fresh URL every time: executors cache HttpGet, and an old answer holds a used-up nonce.
        task.spawn(function() loadstring(game:HttpGet(KeyMenu.API .. "/api/v1/load/" .. id .. "?r=" .. (math.floor(os.clock() * 1000000) % 1000000000) .. math.random(1, 999999)))() end)
      end
      if opts.onSuccess then task.spawn(opts.onSuccess, key, info) end
    end)
  end
  self.submit = submit

  checkBtn.MouseButton1Click:Connect(function() submit(box.Text) end)
  box.FocusLost:Connect(function(enter) if enter then submit(box.Text) end end)
  try(function() box:GetPropertyChangedSignal("Text"):Connect(function() if showSteps and not busy then setStep(box.Text ~= "" and 2 or 1) end end) end)
  if pasteBtn then pasteBtn.MouseButton1Click:Connect(function()
    local t = try(clip)
    if type(t) == "string" and t:gsub("%s", "") ~= "" then box.Text = t:gsub("%s", "") submit(box.Text) else say("Your clipboard is empty. Copy your key first.", "bad") end
  end) end
  if getBtn then getBtn.MouseButton1Click:Connect(function()
    if not getKeyUrl then say("Ask the script owner for a key.") return end
    if copy(getKeyUrl) then say("Link copied. Open it in your browser.", "good") else say(getKeyUrl) end
  end) end
  if dcBtn then dcBtn.MouseButton1Click:Connect(function()
    if copy(discord) then say("Discord link copied.", "good") else say(discord) end
  end) end

  -- remembered key: try it right away
  if saved then box.Text = saved task.spawn(submit, saved, true) end
  return self
end

return KeyMenu
