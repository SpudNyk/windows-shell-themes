-- Configurations: Provide default values in case config file is missing
-- Config file is "_powerline_config.lua"
-- Sample config file is "_powerline_config.lua.sample"
------
-- Core file, and addon files
------
-- Prompt consists of multiple sections
-- ANSI Foreground Colors
local ansiFgClrBlack = "30"
local ansiFgClrRed = "31"
local ansiFgClrGreen = "32"
local ansiFgClrYellow = "33"
local ansiFgClrBlue = "34"
local ansiFgClrMagenta = "35"
local ansiFgClrCyan = "36"
local ansiFgClrWhite = "37"
-- ANSI Background Colors
local ansiBgClrBlack = "40"
local ansiBgClrRed = "41"
local ansiBgClrGreen = "42"
local ansiBgClrYellow = "43"
local ansiBgClrBlue = "44"
local ansiBgClrMagenta = "45"
local ansiBgClrCyan = "46"
local ansiBgClrWhite = "47"

-- Color Name Constants
COLOR_Black = "black"
COLOR_Red = "red"
COLOR_Green = "green"
COLOR_Yellow = "yellow"
COLOR_Blue = "blue"
COLOR_Magenta = "magenta"
COLOR_Cyan = "cyan"
COLOR_White = "white"

local colorNames = {
    [COLOR_Black] = {foreground = ansiFgClrBlack, background = ansiBgClrBlack},
    [COLOR_Red] = {foreground = ansiFgClrRed, background = ansiBgClrRed},
    [COLOR_Green] = {foreground = ansiFgClrGreen, background = ansiBgClrGreen},
    [COLOR_Yellow] = {
        foreground = ansiFgClrYellow,
        background = ansiBgClrYellow
    },
    [COLOR_Blue] = {foreground = ansiFgClrBlue, background = ansiBgClrBlue},
    [COLOR_Magenta] = {
        foreground = ansiFgClrMagenta,
        background = ansiBgClrMagenta
    },
    [COLOR_Cyan] = {foreground = ansiFgClrCyan, background = ansiBgClrCyan},
    [COLOR_White] = {foreground = ansiFgClrWhite, background = ansiBgClrWhite}
}

-- ANSI Escape Character
local ansiEscChar = "\x1b"
local ansiEscape = ansiEscChar .. "["
local resetEscape = ansiEscape .. "0m"
-- OSC (Operating System Commands)
-- see https://conemu.github.io/en/AnsiEscapeCodes.html#OSC_Operating_system_commands
-- Note CLINK does not handle \x07 (BELL) as the end char
local oscBegin = ansiEscChar .. "]";
local oscFinish = ansiEscChar .. "\\";

local function promptTitle(title)
    if title and title ~= "" then
        return oscBegin .. "2;" .. title .. oscFinish
    end
    return ""
end

local function promptPath(path)
    if path and path ~= "" then
        return oscBegin .. "9;9;\"" .. path .. "\"" .. oscFinish
    end
    return ""
end

local function getColorEscape(foreground, background, bold)
    local sequence = ""
    local fgColor = colorNames[foreground]
    local bgColor = colorNames[background]
    if fgColor then sequence = fgColor.foreground end
    if bold then sequence = sequence .. ";1" end
    if bgColor then sequence = sequence .. ";" .. bgColor.background end
    if sequence ~= "" then return ansiEscape .. sequence .. "m" end
    return ""
end

local function applyColor(dest, color, allowNil)
    if allowNil or color.foreground ~= nil then
        dest.foreground = color.foreground
    end
    if allowNil or color.background ~= nil then
        dest.background = color.background
    end
    if allowNil or color.bold ~= nil then dest.bold = color.bold end
    return dest
end

local defaultColor = {foreground = COLOR_White, background = nil, bold = false}

local function promptColor(color, context)
    if color == nil then return "" end
    local escape = resetEscape ..
                       getColorEscape(color.foreground, color.background,
                                      color.bold)

    return escape
end

local function promptContent(content, context, useLeader)
    local prompt = ""
    if content then
        local text = content.text
        if text and text ~= "" then
            prompt = prompt .. promptColor(context.baseColor, context)
            if useLeader and content.leader and content.leader ~= "" then
                prompt = prompt .. content.leader
            end
            prompt = prompt .. promptColor(content, context) .. text
        end
        prompt = prompt .. promptTitle(content.title) ..
                     promptPath(content.path)
    end
    return prompt
end

local function isAdmin()
    -- this command will fail if not in an admin shell
    local pipe = io.popen('net session 2>nul')
    pipe:read("*all")
    return pipe:close() == true
end

-- this will never change after startup so don't execute every time
local is_admin = isAdmin()

-- create the core context with some commonly used values
local function createContext()
    local cwd = clink.get_cwd()
    return {
        is_admin = is_admin,
        cwd = cwd,
        home = clink.get_env("HOME"),
        name = FILE_basename(cwd),
        baseColor = applyColor({}, defaultColor)
    }
end

local prompt_sections = {}

-- reset the prompt to empty
function PROMPT_reset() prompt_sections = {} end

local function noop() end

function PROMPT_color_default(color, ignoreNil)
    applyColor(defaultColor, color, not ignoreNil)
end

-- change the base prompt color after this
function PROMPT_color(color, ignoreNil)
    local function updateColor(_, context)
        applyColor(context.baseColor, color, not ignoreNil)
        return nil
    end
    prompt_sections[#prompt_sections + 1] =
        {prepare = noop, content = updateColor}
end

function PROMPT_include(name, options)
    prompt_sections[#prompt_sections + 1] = SECTION_compile(name, options)
end

function PROMPT_render()
    local context = createContext()

    for _, section in pairs(prompt_sections) do section.prepare(context) end

    local prompt = ""
    local prepend = false
    for index, section in pairs(prompt_sections) do
        local append = promptContent(section.content(context), context, prepend)
        -- only prepend if we have content
        prepend = (prepend or append ~= "")
        prompt = prompt .. append
    end

    return prompt .. resetEscape
end

local function promptFilter()
    clink.prompt.value = PROMPT_render()
    -- this stops any other filters running with lower priority
    return true
end

-- Register filters for resetting the prompt it stops other unused filters running after it
-- so we add it at priority 0
-- halting the other filters improves responsiveness
clink.prompt.register_filter(promptFilter, 0)
