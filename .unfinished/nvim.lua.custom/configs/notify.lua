local present, notify = pcall(require, "notify")
if not present then
  return
end

dofile(vim.g.base46_cache .. "notify")
vim.notify = notify
notify.setup {
  render = "minimal",
  stages = "fade_in_slide_out",
  timeout = 2000,
  top_down = true,
  max_width = 300,
  max_height = 500,
  animate = true,
}
