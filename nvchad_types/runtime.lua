---@meta

---@alias NvBufnr integer
---@alias NvWinid integer
---@alias NvNamespace integer
---@alias NvUiAction '"open"'|'"redraw"'
---@alias NvUiModule string|fun(): string
---@alias NvUiModules table<string, NvUiModule>

---@class NvUiTextChunk
---@field [1] string
---@field [2]? string

---@alias NvUiVirtLine NvUiTextChunk[]
---@alias NvUiVirtLines NvUiVirtLine[]

---@class NvAutocmdCallbackArgs
---@field id integer
---@field event string
---@field group? integer
---@field match string
---@field buf NvBufnr
---@field file string
---@field data? table

---@class NvCheatsheetKeymap
---@field lhs string
---@field mode string
---@field desc? string

---@alias NvCheatsheetMapping [string, string]
---@alias NvCheatsheetSection NvCheatsheetMapping[]
---@alias NvCheatsheetMappings table<string, NvCheatsheetSection>

---@alias NvStatuslineFileInfo [string, string]
---@alias NvStatuslineModeInfo [string, string]
---@alias NvStatuslineSeparatorStyle '"default"'|'"round"'|'"block"'|'"arrow"'
---@alias NvStatuslineSeparator { left: string, right: string }
---@alias NvStatuslineModule table<string, NvUiModule>

---@class NvStatuslineState
---@field lsp_msg string
---@field get_symbols? fun(): string?

---@class NvTabuflineModule
---@field treeOffset fun(): string
---@field buffers fun(): string
---@field tabs fun(): string
---@field btns fun(): string
---@field [string] fun(): string

---@alias NvTermPosition '"sp"'|'"vsp"'|'"bo sp"'|'"bo vsp"'|'"float"'
---@alias NvTermCommand string|fun(): string

---@class NvTermPositionData
---@field resize '"height"'|'"width"'
---@field area '"lines"'|'"columns"'

---@class NvTermOptions
---@field id? string|integer
---@field pos NvTermPosition
---@field buf? NvBufnr
---@field win? NvWinid
---@field cmd? NvTermCommand
---@field size? number
---@field winopts? table<string, any>
---@field float_opts? TermFloat
---@field termopen_opts? table<string, any>
---@field clear_cmd? string

---@class NvMasonPackageSpec
---@field name string
---@field version? string

---@class NvCmpCompletionItem
---@field abbr string
---@field kind string
---@field menu? string
---@field kind_hl_group? string
---@field menu_hl_group? string

---@class NvCmpEntry
---@field completion_item { documentation?: string|table }

---@class NvBlinkContext
---@field kind string

---@class NvThemePickerOpts
---@field style? '"compact"'|'"flat"'|'"bordered"'
---@field icon? string
---@field border? boolean
---@field mappings? fun(buf: NvBufnr)

---@class NvThemePickerState
---@field scrolled boolean
---@field textchanged boolean
---@field prompt string
---@field index integer
---@field limit table<string, integer>
---@field start_row integer
---@field xpad integer
---@field word_gap integer
---@field order Base46Colors[]
---@field themes_shown string[]
---@field active_theme string
---@field icons table<string, string?>
---@field scroll_step table<string, integer>
---@field ns NvNamespace
---@field buf? NvBufnr
---@field input_buf? NvBufnr
---@field win? NvWinid
---@field input_win? NvWinid
---@field style '"compact"'|'"flat"'|'"bordered"'
---@field icon string
---@field val string[]
---@field longest_name integer
---@field w integer
---@field confirmed? boolean

---@class NvColorifyState
---@field events table
---@field ns NvNamespace

---@class NvColorifyExtmarkDetails
---@field hl_group? string
---@field virt_text? NvUiTextChunk[]

---@class NvLspColor
---@field red number
---@field green number
---@field blue number
---@field alpha number

---@class NvLspPosition
---@field line integer
---@field character integer

---@class NvLspRange
---@field start NvLspPosition
---@field ["end"] NvLspPosition

---@class NvLspPrepareRenameResult
---@field placeholder? string
---@field start? NvLspPosition
---@field ["end"]? NvLspPosition
---@field range? NvLspRange

---@class NvLspColorInformation
---@field range NvLspRange
---@field color NvLspColor
