---@type Base46HLGroupsList
return {
  override = {
    Comment = {
      italic = true,
    },
    Search = { fg = "black", bg = "blue" },
    IncSearch = { fg = "black", bg = "red" },
    CurSearch = { fg = "black", bg = "blue" },
    Substitute = { fg = "black", bg = "green" },
    NvDashAscii = { bg = "NONE", fg = "green" },
    -- NvDashButtons = { bg = "NONE" },
  },
  add = {
    NvimTreeFileNew = { fg = "green" },
    NvimTreeFileDirty = { fg = "yellow" },
    NvimTreeGitNew = { fg = "green" },
  },
}
