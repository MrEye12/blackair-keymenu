-- Check a key without showing a window, for example inside your own UI.
local KeyMenu = loadstring(game:HttpGet("https://protect.blackair.dev/keymenu.lua"))()

local ok, message, info = KeyMenu.check("YOUR-SCRIPT-ID", getgenv().script_key)
if ok then
  print("key valid, seconds left:", info and info.seconds_left)
else
  warn("key problem:", message)
end
