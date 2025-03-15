local map = vim.keymap.set

-- general mappings
map("n", "<C-s>", "<cmd> w <CR>")
map("i", "jk", "<ESC>")
map("n", "<C-c>", "<cmd> %y+ <CR>") -- copy whole filecontent

-- nvimtree
-- map("n", "<C-n>", "<cmd> Neotree toggle <CR>")
map("n", "<C-n>", function()
  if Snacks.explorer ~= nil then
    Snacks.explorer()
  end
end)

-- bufferline, cycle buffers
map("n", "<Tab>", "<cmd> BufferLineCycleNext <CR>")
map("n", "<S-Tab>", "<cmd> BufferLineCyclePrev <CR>")
map("n", "<C-q>", "<cmd> bd <CR>")

map(
  "n",
  "<c-S-Enter>",
  "<cmd> exe 'silent !kitty --detach --directory ' . expand('%:p:h') . ' fish' | redraw! <CR>",
  { desc = "new Kitty Terminal" }
)
