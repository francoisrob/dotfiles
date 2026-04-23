-- Smart formatter selection: use biome when a project has biome config, otherwise prettier.
local function has_biome_config(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return false
  end

  local biome_conf = vim.fs.find(
    { "biome.json", "biome.jsonc" },
    { path = bufname, upward = true, stop = vim.uv.os_homedir() }
  )
  if #biome_conf > 0 then
    return true
  end

  local pkg = vim.fs.find("package.json", { path = bufname, upward = true, stop = vim.uv.os_homedir() })
  if #pkg > 0 then
    local ok, lines = pcall(vim.fn.readfile, pkg[1])
    if ok and table.concat(lines, "\n"):find('"@biomejs/biome"') then
      return true
    end
  end

  return false
end

local function biome_or_prettier(bufnr)
  if has_biome_config(bufnr) then
    return { "biome" }
  end
  return { "prettier" }
end

local biome_ft = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "json",
  "jsonc",
}

local by_ft = {}
for _, ft in ipairs(biome_ft) do
  by_ft[ft] = biome_or_prettier
end

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = by_ft,
    },
  },
}
