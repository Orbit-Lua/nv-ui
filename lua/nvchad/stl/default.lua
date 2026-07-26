---@type NvStatusLineConfig
local config = require("nvconfig").ui.statusline
---@type NvStatuslineSeparatorStyle|NvStatuslineSeparator
local sep_style = config.separator_style
local utils = require "nvchad.stl.utils"
local icons_utils = require "nvchad.icons.utils"

local sep_icons = utils.separators
local separators = (type(sep_style) == "table" and sep_style) or sep_icons[sep_style]

local sep_l = separators["left"]
local sep_r = separators["right"]

---@type NvStatuslineModule
local M = {}

---@param path string
---@return boolean
local function is_absolute_path(path)
  return path:sub(1, 1) == "/" or path:match "^%a:[/\\]" ~= nil or path:match "^[/\\][/\\]" ~= nil
end

---@return string?
local function current_file_path()
  local bufnr = utils.stbufnr()

  if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "NvimTree" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(bufnr)

  if path == "" or not is_absolute_path(path) then
    return nil
  end

  return path
end

---@return string
M.mode = function()
  if not utils.is_activewin() then
    return ""
  end

  local modes = utils.modes

  local m = vim.api.nvim_get_mode().mode

  local current_mode = "%#St_" .. modes[m][2] .. "Mode# " .. modes[m][1]
  local mode_sep_hl = "%#St_" .. modes[m][2] .. "ModeSep#"
  return mode_sep_hl .. sep_l .. current_mode .. mode_sep_hl .. sep_r
end

---@return string
M.file = function()
  local x = utils.file()
  local name = " " .. x[2] .. (sep_style == "default" and " " or "")
  return "%#St_file# " .. x[1] .. name .. "%#St_file_sep#" .. sep_r
end

---@return string
M.git = function()
  return "%#St_gitIcons#" .. utils.git()
end

---@return string
M.lsp_msg = function()
  return "%#St_LspMsg#" .. utils.lsp_msg()
end

M.diagnostics = utils.diagnostics

---@return string
M.macro_recording = function()
  if not utils.is_activewin() then
    return ""
  end

  local reg = vim.fn.reg_recording()

  if reg == "" then
    return ""
  end

  return "%#St_lspWarning#󰑊 " .. reg .. " "
end

---@return string
M.lsp = function()
  return "%#St_Lsp#" .. utils.lsp()
end

---@param bufnr integer
---@return boolean
local function has_copilot(bufnr)
  if not rawget(vim, "lsp") then
    return false
  end

  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.name == "copilot" and client.attached_buffers and client.attached_buffers[bufnr] then
      return true
    end
  end

  return false
end

---@return string
M.ai = function()
  local ai = config.ai or {}
  local bufnr = utils.stbufnr()
  local available = has_copilot(bufnr)

  if not available and type(ai.is_available) == "function" then
    local ok, result = pcall(ai.is_available, bufnr)
    available = ok and result
  end

  if not available then
    return ""
  end

  return "%#" .. (ai.hl or "St_copilot") .. "#" .. (ai.icon or "  ")
end

-- Compatibility alias for custom statusline orders using the old module name.
M.copilot = M.ai

---@return string
M.file_path = function()
  local path = current_file_path()

  if path == nil then
    return ""
  end

  local relative_path = utils.pretty_file_path(path, { only_cwd = true, length = config.truncation_length or 3 })
  local dir = vim.fs.dirname(relative_path)
  local filename = vim.fn.fnamemodify(relative_path, ":t")
  local icon = "%#St_file_open#" .. "󰈚"

  if filename ~= "" then
    icon = icons_utils.get_file_icon(filename, { colored = true })
  end

  filename = (filename == "" and "Empty") or filename

  icon = icon .. " "
  filename = "%#St_file_open#" .. filename

  if dir == "." then
    return icon .. filename
  end

  return icon .. "%#St_file_path#" .. dir .. "/" .. filename
end

---@return string
M.symbols = function()
  utils.init_symbols()

  if utils.state.get_symbols == nil then
    return ""
  end

  local ok, symbols = pcall(utils.state.get_symbols)

  if not ok then
    utils.state.get_symbols = nil
    return ""
  end

  if symbols == nil or symbols == "" then
    return ""
  end

  return "%#St_symbols_sep#" .. utils.symbols_sep .. utils.pretty_symbols_path(symbols, config.truncation_length or 3)
end

---@return string
M.cwd = function()
  local icon = "%#St_cwd_icon#" .. "󰉋 "
  local name = vim.uv.cwd()
  if name == nil then
    return ""
  end
  name = "%#St_cwd_text#" .. " " .. (name:match "([^/\\]+)[/\\]*$" or name) .. " "
  return (vim.o.columns > 85 and ("%#St_cwd_sep#" .. sep_l .. icon .. name)) or ""
end

M.cursor = function()
  local sep_l_hl = "%#St_pos_sep#"

  if vim.o.columns > 85 then
    sep_l_hl = "%#St_pos_sep_mid#"
  end

  return sep_l_hl .. sep_l .. "%#St_pos_icon# %#St_pos_text# %l/%v "
end

M["%="] = "%="
M.truncation_point = "%<"

---@return string
return function()
  return utils.generate("default", M)
end
