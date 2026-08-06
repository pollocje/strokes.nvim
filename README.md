# strokes.nvim

I like when the number go up. I really like weird apps like Procrastitracker and such.
I thought I'd try my hand at making something simple in nvim and I thought maybe we could make number go up.

So here it is! When you type, the number go up.
Ty

```
  strokes.nvim

  Rank: Apprentice Clacker  (12,845 keys all-time)
  Last 14 days: ▁▂▃▅▇█▆▃▂▁▁▂▃▅

  Today          1,204
  Last 7 days    6,532
  Last 30 days  12,845
  All time      12,845

  Top buffers (all time)
    4,821       lua/strokes/init.lua
    3,102       README.md
    2,004       ~/notes/scratch.md

  q / <Esc> to close
```

## Install

**lazy.nvim**

```lua
{
  "pollocje/strokes.nvim",
  event = "VeryLazy", -- tracking should start early, don't lazy-load on cmd
  opts = {},
}
```

**packer.nvim**

```lua
use({
  "pollocje/strokes.nvim",
  config = function()
    require("strokes").setup({})
  end,
})
```

Calling `setup()` is optional - tracking starts with default settings as
soon as the plugin loads. Zero config needed to start watching the
number go up.

## Commands

- `:StrokesStats` - open the stats window
- `:StrokesSave` - force-write the current counts to disk

## Configuration

```lua
require("strokes").setup({
  -- keypresses to accumulate before flushing to disk
  save_every = 50,
  -- filetypes to exclude from counting
  ignore_filetypes = {},
})
```

## Statusline

```lua
require("strokes").statusline() -- "⌨ 128" (today's count for the current buffer)
```

Drop that into a lualine component or a statusline expression.

## How it works

Every keypress is captured globally via `vim.on_key()`, tagged with the
current buffer's file path and today's date, and accumulated in memory.
Counts are flushed to a JSON file under `stdpath('data')/strokes.nvim/`
every `save_every` keys (default 50), and on exit / focus loss. Weekly
and monthly figures are rolling windows (last 7 / last 30 days), not
calendar weeks or months.
