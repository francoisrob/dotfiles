return {
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            { id = "breakpoints", size = 0.2 },
            { id = "scopes", size = 0.3 },
            { id = "stacks", size = 0.5 },
          },
          position = "right",
          size = 40,
        },
        {
          elements = {
            { id = "repl", size = 1 },
          },
          position = "bottom",
          size = 10,
        },
      },
      render = {
        indent = 1,
        max_type_length = 10,
        max_value_lines = 100,
      },
    },
  },
}
