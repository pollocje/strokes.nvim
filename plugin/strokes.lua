if vim.g.loaded_strokes then
  return
end
vim.g.loaded_strokes = true

require('strokes').setup()

vim.api.nvim_create_user_command('StrokesStats', function()
  require('strokes.ui').open()
end, { desc = 'Open the strokes.nvim stats window' })

vim.api.nvim_create_user_command('StrokesSave', function()
  require('strokes').save()
  vim.notify('strokes.nvim: saved', vim.log.levels.INFO)
end, { desc = 'Force-save strokes.nvim data to disk' })
