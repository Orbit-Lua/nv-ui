local M = {}

---@return NvBufnr
M.stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

---@return boolean
M.is_activewin = function()
  return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

---@type table<string, string[]>
local default_order = {
  "mode",
  "macro_recording",
  "truncation_point",
  "git",
  "file_path",
  "symbols",
  "%=",
  "lsp_msg",
  "%=",
  "diagnostics",
  "ai",
  "lsp",
  "cwd",
  "cursor",
}

---@type table<string, string[]>
local default_order_no_lsp_msg = {
  "mode",
  "macro_recording",
  "truncation_point",
  "git",
  "file_path",
  "symbols",
  "%=",
  "%=",
  "diagnostics",
  "ai",
  "lsp",
  "cwd",
  "cursor",
}

---@type table<string, string[]>
local orders = {
  default = default_order,
  minimal = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cwd", "cursor" },
  vscode = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor", "cwd" },
}

---@type table<string, string[]>
local orders_no_lsp_msg = {
  default = default_order_no_lsp_msg,
  minimal = { "mode", "file", "git", "%=", "%=", "diagnostics", "lsp", "cwd", "cursor" },
  vscode = { "mode", "file", "git", "%=", "%=", "diagnostics", "lsp", "cursor", "cwd" },
}

---@param theme string
---@param modules NvStatuslineModule
---@return string
M.generate = function(theme, modules)
  local config = require("nvconfig").ui.statusline

  if config == nil then
    config = {}
  end

  local order = config.order
  local enabled_modules = config.enabled_modules

  if config.show_lsp_msg then
    order = order or orders[theme]
  else
    order = order or orders_no_lsp_msg[theme]
  end

  local result = {}

  if config.modules then
    for key, value in pairs(config.modules) do
      modules[key] = value
    end

    if config.modules.ai == nil and config.modules.copilot ~= nil and modules.ai then
      modules.ai = config.modules.copilot
    elseif config.modules.ai ~= nil and config.modules.copilot == nil and modules.copilot then
      modules.copilot = config.modules.ai
    end
  end

  for _, v in ipairs(order) do
    local enabled = enabled_modules == nil or enabled_modules[v] ~= false
    if v == "ai" and enabled_modules and enabled_modules.ai == nil and enabled_modules.copilot == false then
      enabled = false
    end

    if enabled then
      local module = modules[v]
      module = type(module) == "string" and module or module()
      table.insert(result, module)
    end
  end

  return table.concat(result)
end

---@type NvStatuslineState
M.state = {
  lsp_msg = "",
  get_symbols = nil,
}

-- Initialize symbols module if trouble is available
M.init_symbols = function()
  if type(M.state.get_symbols) == "function" then
    return
  end

  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end

  local ok_symbols, symbols = pcall(trouble.statusline, {
    mode = "symbols",
    groups = {},
    title = false,
    filter = { range = true },
    format = "{kind_icon}{symbol.name:Normal}",
    hl_group = "St_symbols",
  })

  if not ok_symbols or type(symbols) ~= "table" or type(symbols.get) ~= "function" then
    return
  end

  M.state.get_symbols = symbols.get
end

---@param symbols string
---@param length number
---@return string
M.pretty_symbols_path = function(symbols, length)
  -- symbol = icon + name (include hl)
  local parts = {}
  for s in symbols:gmatch "%%#.-%%%*%%#.-%%%*" do
    table.insert(parts, s)
  end

  if #parts <= length then
    return table.concat(parts, M.symbols_sep)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(short_parts, vim.list_slice(parts, #parts - length + 2, #parts))

  return table.concat(short_parts, M.symbols_sep)
end

---@return string
M.get_cwd = function()
  return vim.fs.normalize(vim.fn.getcwd())
end

---@param path? string
---@param opts? {length?: integer, only_cwd?: boolean, transform_home?: boolean}
---@return string
M.pretty_file_path = function(path, opts)
  opts = opts or {}

  local length = opts.length or 3
  local full_path = path or vim.fn.expand "%:p"

  if full_path == "" then
    return ""
  end

  -- Normalize and get cwd
  full_path = vim.fs.normalize(full_path)

  if opts.only_cwd then
    local cwd = M.get_cwd()

    -- remove cwd prefix
    if full_path:find(cwd, 1, true) == 1 then
      full_path = full_path:sub(#cwd + 2) -- +2 to remove slash
    end
  end

  if opts.transform_home then
    local home = vim.uv.os_homedir()
    if home and full_path:find(home, 1, true) == 1 then
      full_path = "~" .. full_path:sub(#home + 1)
    end
  end

  -- local sep = package.config:sub(1, 1)
  local sep = "/"
  local parts = vim.split(full_path, "[\\/]", { plain = false })

  if #parts <= length or length == -1 then
    return table.concat(parts, sep)
  end

  local short_parts = { parts[1], "…" }
  vim.list_extend(short_parts, vim.list_slice(parts, #parts - length + 2, #parts))

  return table.concat(short_parts, sep)
end

-- 2nd item is highlight groupname St_NormalMode
---@type table<string, NvStatuslineModeInfo>
M.modes = {
  ["n"] = { "NORMAL", "Normal" },
  ["no"] = { "NORMAL (no)", "Normal" },
  ["nov"] = { "NORMAL (nov)", "Normal" },
  ["noV"] = { "NORMAL (noV)", "Normal" },
  ["noCTRL-V"] = { "NORMAL", "Normal" },
  ["niI"] = { "NORMAL i", "Normal" },
  ["niR"] = { "NORMAL r", "Normal" },
  ["niV"] = { "NORMAL v", "Normal" },
  ["nt"] = { "NTERMINAL", "NTerminal" },
  ["ntT"] = { "NTERMINAL (ntT)", "NTerminal" },

  ["v"] = { "VISUAL", "Visual" },
  ["vs"] = { "V-CHAR (Ctrl O)", "Visual" },
  ["V"] = { "V-LINE", "Visual" },
  ["Vs"] = { "V-LINE", "Visual" },
  [""] = { "V-BLOCK", "Visual" },

  ["i"] = { "INSERT", "Insert" },
  ["ic"] = { "INSERT", "Insert" },
  ["ix"] = { "INSERT", "Insert" },

  ["t"] = { "TERMINAL", "Terminal" },

  ["R"] = { "REPLACE", "Replace" },
  ["Rc"] = { "REPLACE (Rc)", "Replace" },
  ["Rx"] = { "REPLACEa (Rx)", "Replace" },
  ["Rv"] = { "V-REPLACE", "Replace" },
  ["Rvc"] = { "V-REPLACE (Rvc)", "Replace" },
  ["Rvx"] = { "V-REPLACE (Rvx)", "Replace" },

  ["s"] = { "SELECT", "Select" },
  ["S"] = { "S-LINE", "Select" },
  [""] = { "S-BLOCK", "Select" },
  ["c"] = { "COMMAND", "Command" },
  ["cv"] = { "COMMAND", "Command" },
  ["ce"] = { "COMMAND", "Command" },
  ["cr"] = { "COMMAND", "Command" },
  ["r"] = { "PROMPT", "Confirm" },
  ["rm"] = { "MORE", "Confirm" },
  ["r?"] = { "CONFIRM", "Confirm" },
  ["x"] = { "CONFIRM", "Confirm" },
  ["!"] = { "SHELL", "Terminal" },
}

-- credits to ii14 for str:match func
---@return NvStatuslineFileInfo
M.file = function()
  local icon = "󰈚"
  local path = vim.api.nvim_buf_get_name(M.stbufnr())
  local name = (path == "" and "Empty") or path:match "([^/\\]+)[/\\]*$"

  if name ~= "Empty" then
    local ft_icon = require("nvchad.icons.utils").get_file_icon(name)
    icon = (ft_icon ~= "" and ft_icon) or icon
  end

  return { icon, name }
end

---@return string
M.git = function()
  if not vim.b[M.stbufnr()].gitsigns_head or vim.b[M.stbufnr()].gitsigns_git_status then
    return ""
  end

  local git_status = vim.b[M.stbufnr()].gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
  local branch_name = " " .. git_status.head

  return branch_name .. added .. changed .. removed .. "  "
end

---@return string
M.lsp_msg = function()
  return vim.o.columns < 120 and "" or M.state.lsp_msg
end

---@return string
M.lsp = function()
  if rawget(vim, "lsp") then
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[M.stbufnr()] and client.name ~= "copilot" then
        return (vim.o.columns > 100 and "  LSP ~ " .. client.name .. " ") or "  LSP "
      end
    end
  end

  return ""
end

---@return string
M.diagnostics = function()
  if not rawget(vim, "lsp") then
    return ""
  end

  local err = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.ERROR })
  local warn = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(M.stbufnr(), { severity = vim.diagnostic.severity.INFO })

  local err_str = (err and err > 0) and ("%#St_lspError#" .. " " .. err .. " ") or ""
  local warn_str = (warn and warn > 0) and ("%#St_lspWarning#" .. " " .. warn .. " ") or ""
  local hints_str = (hints and hints > 0) and ("%#St_lspHints#" .. "󰛩 " .. hints .. " ") or ""
  local info_str = (info and info > 0) and ("%#St_lspInfo#" .. "󰋼 " .. info .. " ") or ""

  return " " .. err_str .. warn_str .. hints_str .. info_str
end

---@type table<NvStatuslineSeparatorStyle, NvStatuslineSeparator>
M.separators = {
  default = { left = "", right = " " },
  round = { left = "", right = " " },
  block = { left = "█", right = "█ " },
  arrow = { left = "", right = " " },
}

M.symbols_sep = "  "

---@type string[]
local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥", "" }

M.autocmds = function()
  vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    ---@param args NvAutocmdCallbackArgs
    callback = function(args)
      vim.cmd.redrawstatus()

      if args.event == "RecordingLeave" then
        vim.schedule(function()
          vim.cmd.redrawstatus()
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspProgress", {
    pattern = { "begin", "report", "end" },
    ---@param args NvAutocmdCallbackArgs
    callback = function(args)
      -- Ensure params exists before accessing its fields
      if not args.data or not args.data.params then
        return
      end

      local data = args.data.params.value
      local progress = ""

      if data.percentage then
        local idx = math.max(1, math.floor(data.percentage / 10))
        local icon = spinners[idx]
        progress = icon .. " " .. data.percentage .. "%% "
      end

      local loaded_count = data.message and string.match(data.message, "^(%d+/%d+)") or ""
      local str = progress .. (data.title or "") .. " " .. (loaded_count or "")
      M.state.lsp_msg = data.kind == "end" and "" or str
      vim.cmd.redrawstatus()
    end,
  })
end

return M
