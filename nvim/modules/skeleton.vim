lua << EOF
local load_template = function()
  local file_name = vim.fn.expand('%:p:t')
  local template_path = '~/.config/nvim/skeletons/' .. file_name
  if vim.fn.filereadable(vim.fn.expand(template_path)) == 1 then
    vim.b.template_path = template_path
    vim.cmd([[execute ':0r' b:template_path]])
  end
end

local augroup = vim.api.nvim_create_augroup('load_template', { clear = true })

vim.api.nvim_create_autocmd({ 'BufCreate', 'BufNewFile' }, {
  pattern = '*',
  callback = function()
    if vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()):match(".*://") then
      return
    end
    vim.schedule(load_template)
  end,
  group = augroup
})
EOF
