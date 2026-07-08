---@type NvStatusLineConfig
local config = require("nvconfig").ui.statusline
---@type NvStatuslineSeparatorStyle|NvStatuslineSeparator
local sep_style = config.separator_style
local utils = require "nvchad.stl.utils"

sep_style = (sep_style ~= "round" and sep_style ~= "block") and "block" or sep_style

local sep_icons = utils.separators
local separators = (type(sep_style) == "table" and sep_style) or sep_icons[sep_style]

local sep_l = separators["left"]
local sep_r = "%#St_sep_r#" .. separators["right"] .. " %#ST_EmptySpace#"

---@param icon string
---@param txt string
---@param sep_l_hlgroup string
---@param iconHl_group string
---@param txt_hl_group string
---@return string
local function gen_block(icon, txt, sep_l_hlgroup, iconHl_group, txt_hl_group)
  return sep_l_hlgroup .. sep_l .. iconHl_group .. icon .. " " .. txt_hl_group .. " " .. txt .. sep_r
end

local is_activewin = utils.is_activewin

---@type NvStatuslineModule
local M = {}

---@return string
M.mode = function()
  if not is_activewin() then
    return ""
  end

  local modes = utils.modes
  local m = vim.api.nvim_get_mode().mode

  return gen_block(
    "",
    modes[m][1],
    "%#St_" .. modes[m][2] .. "ModeSep#",
    "%#St_" .. modes[m][2] .. "Mode#",
    "%#St_" .. modes[m][2] .. "ModeText#"
  )
end

---@return string
M.file = function()
  local x = utils.file()
  return gen_block(x[1], x[2], "%#St_file_sep#", "%#St_file_bg#", "%#St_file_txt#")
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
M.lsp = function()
  return "%#St_Lsp#" .. utils.lsp()
end

---@return string
M.cwd = function()
  local name = vim.uv.cwd()
  name = name:match "([^/\\]+)[/\\]*$" or name
  return gen_block("", name, "%#St_cwd_sep#", "%#St_cwd_bg#", "%#St_cwd_txt#")
end

---@return string
M.cursor = function()
  return gen_block("", "%l/%v", "%#St_Pos_sep#", "%#St_Pos_bg#", "%#St_Pos_txt#")
end

M["%="] = "%="

---@return string
return function()
  return utils.generate("minimal", M)
end
