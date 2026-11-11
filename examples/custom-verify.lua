-- Use the key menu with any key system: pass your own `verify`.
local KeyMenu = loadstring(game:HttpGet("https://protect.blackair.dev/keymenu.lua"))()

KeyMenu.new({
  title = "My Hub",
  subtitle = "Paste your key to continue",
  colors = { bg = "#0A0A0A", accent = "#7C5CFF", text = "#FFFFFF" },
  getKeyUrl = "https://example.com/get-key",
  autoLoad = false,
  verify = function(key)
    -- return true, or false and a message the player sees
    if key == "TEST-KEY" then return true end
    return false, "That key is not valid."
  end,
  onSuccess = function(key)
    print("key ok, start your hub here")
  end,
})
