local map = vim.keymap.set

map("n", "<C-s>", "<cmd> w <CR>")
map("i", "jk", "<ESC>")
map("n", "<C-c>", "<cmd> %y+ <CR>")

map("n", "<C-n>", function()
  Snacks.explorer()
end)

map("n", "<Tab>", "<cmd> BufferLineCycleNext <CR>")
map("n", "<S-Tab>", "<cmd> BufferLineCyclePrev <CR>")
map("n", "<C-q>", "<cmd> bd <CR>")

map(
  "n",
  "<c-S-Enter>",
  "<cmd> exe 'silent !kitty --directory=' . expand('%:p:h') . ' &' | redraw! <CR>",
  { desc = "new Kitty Terminal" }
)
