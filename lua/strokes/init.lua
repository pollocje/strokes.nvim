local storage = require('strokes.storage')

local M = {}

M.config = {
  -- how many keypresses to accumulate before flushing to disk
  save_every = 50,
  -- filetypes to exclude from counting, e.g. { 'TelescopePrompt' }
  ignore_filetypes = {},
}

M.data = nil
M._dirty = 0
M._started = false

local function today()
  return os.date('%Y-%m-%d')
end

local function date_n_days_ago(n)
  return os.date('%Y-%m-%d', os.time() - n * 86400)
end

local function buf_name(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return '[No Name]'
  end
  return name
end

local function record_key()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  for _, ignored in ipairs(M.config.ignore_filetypes) do
    if ft == ignored then
      return
    end
  end

  local date = today()
  local day = M.data.days[date]
  if not day then
    day = { total = 0, buffers = {} }
    M.data.days[date] = day
  end

  local name = buf_name(buf)
  day.total = day.total + 1
  day.buffers[name] = (day.buffers[name] or 0) + 1

  M._dirty = M._dirty + 1
  if M._dirty >= M.config.save_every then
    M.save()
  end
end

function M.save()
  storage.save(M.data)
  M._dirty = 0
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  if M._started then
    return
  end
  M._started = true

  M.data = storage.load()

  vim.on_key(function()
    record_key()
  end)

  local group = vim.api.nvim_create_augroup('Strokes', { clear = true })
  vim.api.nvim_create_autocmd({ 'VimLeavePre', 'FocusLost' }, {
    group = group,
    callback = function()
      M.save()
    end,
  })
end

-- Aggregation -----------------------------------------------------------

--- Sums totals and per-buffer counts over the last `n` days, including today.
function M.range_stats(n)
  local total = 0
  local buffers = {}
  for i = 0, n - 1 do
    local day = M.data.days[date_n_days_ago(i)]
    if day then
      total = total + day.total
      for name, count in pairs(day.buffers) do
        buffers[name] = (buffers[name] or 0) + count
      end
    end
  end
  return { total = total, buffers = buffers }
end

function M.today_stats()
  return M.range_stats(1)
end

function M.all_time_stats()
  local total = 0
  local buffers = {}
  for _, day in pairs(M.data.days) do
    total = total + day.total
    for name, count in pairs(day.buffers) do
      buffers[name] = (buffers[name] or 0) + count
    end
  end
  return { total = total, buffers = buffers }
end

--- Returns { { date = 'YYYY-MM-DD', total = n }, ... } for the last n days, oldest first.
function M.daily_series(n)
  local series = {}
  for i = n - 1, 0, -1 do
    local date = date_n_days_ago(i)
    local day = M.data.days[date]
    table.insert(series, { date = date, total = day and day.total or 0 })
  end
  return series
end

--- Keypress count for the given buffer today (current buffer by default).
function M.buffer_today(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local day = M.data.days[today()]
  if not day then
    return 0
  end
  return day.buffers[buf_name(buf)] or 0
end

--- Handy for statusline plugins: require('strokes').statusline()
function M.statusline()
  local n = M.buffer_today()
  if n == 0 then
    return ''
  end
  return string.format('⌨ %d', n)
end

return M
