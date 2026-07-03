local M = {}

local function data_dir()
  return vim.fn.stdpath('data') .. '/strokes.nvim'
end

local function data_file()
  return data_dir() .. '/data.json'
end

function M.default_data()
  return { days = {} }
end

function M.load()
  local path = data_file()
  if vim.fn.filereadable(path) == 0 then
    return M.default_data()
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return M.default_data()
  end

  local decode_ok, decoded = pcall(vim.fn.json_decode, table.concat(lines, '\n'))
  if not decode_ok or type(decoded) ~= 'table' or type(decoded.days) ~= 'table' then
    return M.default_data()
  end

  return decoded
end

function M.save(data)
  local dir = data_dir()
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end

  local ok, encoded = pcall(vim.fn.json_encode, data)
  if not ok then
    return
  end

  vim.fn.writefile({ encoded }, data_file())
end

return M
