local map = vim.keymap.set

-- general mappings
map("n", "<C-s>", "<cmd> w <CR>")
map("i", "jk", "<ESC>")
map("n", "<C-c>", "<cmd> %y+ <CR>") -- copy whole filecontent

-- nvimtree
map("n", "<C-n>", "<cmd> Neotree toggle <CR>")
map("n", "<leader>/", function()
  require("Comment.api").toggle.linewise.current()
end)

-- map("n", "<C-h>", "<cmd> NvimTreeFocus <CR>")

-- telescope
map("n", "<leader>ff", "<cmd> Telescope find_files <CR>")
map("n", "<leader>fo", "<cmd> Telescope oldfiles <CR>")
map("n", "<leader>fw", "<cmd> Telescope live_grep <CR>")
map("n", "<leader>gt", "<cmd> Telescope git_status <CR>")

-- bufferline, cycle buffers
map("n", "<Tab>", "<cmd> BufferLineCycleNext <CR>")
map("n", "<S-Tab>", "<cmd> BufferLineCyclePrev <CR>")
map("n", "<C-q>", "<cmd> bd <CR>")

-- format
map("n", "<leader>fm", function()
  require("conform").format()
end)

map(
  "n",
  "<c-S-Enter>",
  "<cmd> exe 'silent !kitty --detach --directory ' . expand('%:p:h') | redraw! <CR>",
  { desc = "new Kitty Terminal" }
)
