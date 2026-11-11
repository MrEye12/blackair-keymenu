# BlackAir Key Menu

A free, open source key window for Roblox scripts. Players paste their key, it is checked, the key is remembered on that device, and your script starts. One file, no assets, MIT licensed.

It works out of the box with [BlackAir Lua Protect](https://protect.blackair.dev), and with any other key system if you pass your own `verify` function.

## Quick start

```lua
local KeyMenu = loadstring(game:HttpGet("https://protect.blackair.dev/keymenu.lua"))()

KeyMenu.new({
  scriptId = "YOUR-SCRIPT-ID", -- from the BlackAir dashboard
})
```

That is all. With a BlackAir script ID, colors, texts, the "Get key" link and your Discord link come from your dashboard, and after a good key your protected script loads.

## With your own key system

```lua
local KeyMenu = loadstring(game:HttpGet("https://protect.blackair.dev/keymenu.lua"))()

KeyMenu.new({
  title = "My Hub",
  colors = { bg = "#0A0A0A", accent = "#7C5CFF", text = "#FFFFFF" },
  getKeyUrl = "https://example.com/get-key",
  autoLoad = false,
  verify = function(key)
    return key == "TEST-KEY", "That key is not valid."
  end,
  onSuccess = function(key)
    -- start your hub here
  end,
})
```

More in [`examples/`](examples).

## Options

| Option | Type | What it does |
|---|---|---|
| `scriptId` | string | BlackAir script ID. Needed unless you pass `verify`. |
| `title`, `subtitle` | string | Texts at the top of the window. |
| `colors` | table | `{ bg, accent, text }` as hex colors. |
| `getKeyUrl` | string | Link behind "Get key". Default: your BlackAir key page. |
| `discord` | string | Link behind "Discord". |
| `remember` | boolean | Save the key on this device and try it next time. Default `true`. |
| `autoLoad` | boolean | Run the BlackAir loader after a good key. Default `true`. |
| `onSuccess` | function(key, info) | Called after a good key. |
| `onClose` | function() | Called when the player closes the window. |
| `verify` | function(key) -> ok, message | Your own key check. |
| `style` | table | Layout `card`, `split`, `compact` or `sheet`, icon, cover image, dim, button style and more. See the top of `keymenu.lua`. |

Helpers: `KeyMenu.check(scriptId, key)` checks a key without a window, `menu:Close()` closes it from your code.

## Notes

- Works on common executors. It uses only standard Roblox APIs plus `writefile`/`readfile` to remember the key when they exist.
- Every request adds a fresh `r=` value, because some executors cache `HttpGet` by URL.
- The window scales with the screen and fits phones in landscape.

## About BlackAir Lua Protect

[BlackAir Lua Protect](https://protect.blackair.dev) is a platform for Roblox script developers: a [Luau obfuscator](https://protect.blackair.dev/luau-obfuscator) with its own VM, a [free key system](https://protect.blackair.dev/roblox-key-system) with ad-supported key pages and device-bound keys, a [script whitelist](https://protect.blackair.dev/roblox-script-whitelist) with bans that follow alt accounts, a Discord bot and a live dashboard. Free to start. [Docs](https://protect.blackair.dev/docs/key-menu).

## License

MIT
