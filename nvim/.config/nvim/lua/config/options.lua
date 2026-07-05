-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Picker por defecto (coherente con el extra editor.fzf)
vim.g.lazyvim_picker = "fzf"

-- Ajustes IDE-friendly
vim.opt.relativenumber = true -- numeros relativos (LazyVim ya lo trae)
vim.opt.number = true
vim.opt.wrap = false -- no envolver lineas largas
vim.opt.scrolloff = 8 -- margen vertical al hacer scroll
vim.opt.sidescrolloff = 8

-- Formateo al guardar ya viene activado por LazyVim (conform.nvim)

