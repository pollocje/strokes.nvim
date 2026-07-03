local strokes = require('strokes')

local M = {}

local BLOCKS = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }

local RANKS = {
  { threshold = 0, title = 'Fresh Fingers' },
  { threshold = 1000, title = 'Warm-Up Act' },
  { threshold = 10000, title = 'Apprentice Clacker' },
  { threshold = 50000, title = 'Journeyman Clacker' },
  { threshold = 150000, title = 'Keyboard Warrior' },
  { threshold = 500000, title = 'Clack Lord' },
  { threshold = 1000000, title = 'Ascended Typist' },
}

local function rank_for(total)
  local title = RANKS[1].title
  for _, entry in ipairs(RANKS) do
    if total >= entry.threshold then
      title = entry.title
    else
      break
    end
  end
  return title
end

local function comma(n)
  local s = tostring(math.floor(n))
  local sign = ''
  if s:sub(1, 1) == '-' then
    sign, s = '-', s:sub(2)
  end
  local grouped = s:reverse():gsub('(%d%d%d)', '%1,')
  grouped = grouped:reverse()
  if grouped:sub(1, 1) == ',' then
    grouped = grouped:sub(2)
  end
  return sign .. grouped
end

local function sparkline(series)
  local max = 0
  for _, d in ipairs(series) do
    max = math.max(max, d.total)
  end
  if max == 0 then
    max = 1
  end
  local chars = {}
  for _, d in ipairs(series) do
    local idx = math.floor((d.total / max) * (#BLOCKS - 1)) + 1
    table.insert(chars, BLOCKS[idx])
  end
  return table.concat(chars)
end

local function top_buffers(buffers, limit)
  local list = {}
  for name, count in pairs(buffers) do
    table.insert(list, { name = name, count = count })
  end
  table.sort(list, function(a, b)
    return a.count > b.count
  end)
  local out = {}
  for i = 1, math.min(limit, #list) do
    out[i] = list[i]
  end
  return out
end

local function short_name(name)
  if name == '[No Name]' then
    return name
  end
  return vim.fn.fnamemodify(name, ':~:.')
end

function M.open()
  local today = strokes.today_stats()
  local week = strokes.range_stats(7)
  local month = strokes.range_stats(30)
  local all_time = strokes.all_time_stats()
  local series = strokes.daily_series(14)

  local lines = {}
  local function push(l)
    table.insert(lines, l)
  end

  push('  strokes.nvim')
  push('')
  push(string.format('  Rank: %s  (%s keys all-time)', rank_for(all_time.total), comma(all_time.total)))
  push(string.format('  Last 14 days: %s', sparkline(series)))
  push('')
  push(string.format('  Today         %10s', comma(today.total)))
  push(string.format('  Last 7 days   %10s', comma(week.total)))
  push(string.format('  Last 30 days  %10s', comma(month.total)))
  push(string.format('  All time      %10s', comma(all_time.total)))
  push('')
  push('  Top buffers (all time)')

  local top = top_buffers(all_time.buffers, 10)
  if #top == 0 then
    push('    (nothing recorded yet)')
  else
    for _, entry in ipairs(top) do
      push(string.format('    %-10s  %s', comma(entry.count), short_name(entry.name)))
    end
  end

  push('')
  push('  q / <Esc> to close')

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = width + 2
  local height = #lines

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'strokes'
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Strokes ',
    title_pos = 'center',
  })

  vim.wo[win].winhighlight = 'NormalFloat:Normal'

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true, silent = true })
end

return M
