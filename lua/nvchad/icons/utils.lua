local M = {}

local function hl_has_fg(hl_name)
  if hl_name == nil or hl_name == "" then
    return false
  end

  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_name, link = false })
  return ok and hl.fg ~= nil
end

local function fallback_hl(hl_name)
  if hl_has_fg(hl_name) then
    return hl_name
  end

  if hl_has_fg "DevIconDefault" then
    return "DevIconDefault"
  end

  return "Normal"
end

local function format_icon(icon, hl_name, colored)
  if icon == nil or icon == "" then
    return ""
  end

  if colored then
    return string.format("%%#%s#", fallback_hl(hl_name)) .. icon .. "%*"
  end

  return icon
end

local function get_mini_icon(path)
  local ok, mini_icons = pcall(require, "mini.icons")
  if not ok then
    return nil, nil
  end

  if _G.MiniIcons == nil then
    mini_icons.setup()
  end

  return mini_icons.get("file", path)
end

local function get_web_devicon(path)
  local ok, web_devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return nil, nil
  end

  local filename = vim.fn.fnamemodify(path, ":t")
  if filename == "" then
    return nil, nil
  end

  return web_devicons.get_icon(filename, filename:match "%.([^%.]+)$", { default = true })
end

---@param path string
---@return string?, string?
M.get_file_icon_data = function(path)
  local icon, icon_hl_name = get_mini_icon(path)

  if icon == nil or icon == "" then
    icon, icon_hl_name = get_web_devicon(path)
  end

  return icon, icon_hl_name
end

---@param path string
---@param opts? {colored?: boolean}
---@return string
M.get_file_icon = function(path, opts)
  opts = opts or {}

  local icon, icon_hl_name = M.get_file_icon_data(path)
  return format_icon(icon, icon_hl_name, opts.colored)
end

return M
