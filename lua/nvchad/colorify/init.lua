local M = {}
local api = vim.api

local state = require "nvchad.colorify.state"
state.ns = api.nvim_create_namespace "Colorify"

---@type fun(buf: NvBufnr, event: string)
M.attach = require "nvchad.colorify.attach"

M.run = function()
  api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
    "VimResized",
    "LspAttach",
    "WinScrolled",
    "BufEnter",
  }, {
    ---@param args NvAutocmdCallbackArgs
    callback = function(args)
      if vim.bo[args.buf].bl then
        M.attach(args.buf, args.event)
      end
    end,
  })
end

return M
