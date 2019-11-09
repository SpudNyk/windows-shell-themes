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

local function getColorEscape(foreground, background, bold)
    local sequence = ""
    local fgColor = colorNames[foreground]
    local bgColor = colorNames[background]
    if fgColor then sequence = ansiEscape .. fgColor.foreground end
    if bold then sequence = sequence .. ";1" end
    if bgColor then sequence = sequence .. ";" .. bgColor.background end
    if sequence ~= "" then return sequence .. "m" end
    return ""
end

local defaultColor = {foreground = COLOR_Cyan, background = nil}
local baseColor = {
    foreground = defaultColor.foreground,
    background = defaultColor.background
}

local function promptColor(color, context)
    local escape = getColorEscape(color.foreground, color.background)
    -- if the currently prompted color doesn't match
    -- return the escape sequence
    if escape ~= context.prompt_color then
        context.prompt_color = escape
        return escape
    end
    return ""
end

local function promptContent(content, context, useLeader)
    if content then
        local text = content.text
        if text and text ~= "" then
            local prompt = promptColor(baseColor, context)
            if useLeader and content.leader and content.leader ~= "" then
                prompt = prompt .. content.leader
            end
            return prompt .. promptColor(content, context) .. text
        end
    end
    return ""
end

-- create the core context with some commonly used values
local function createContext()
    return {cwd = clink.get_cwd(), home = clink.get_env("HOME")}
end

local prompt_sections = {}

-- reset the prompt to empty
function PROMPT_reset() prompt_sections = {} end

local function noop() end
-- change the base prompt color after this
function PROMPT_color(foreground, background)
    local function updateColor()
        baseColor.foreground = foreground
        baseColor.background = background
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
    -- base color can change throughout rendering ensure it starts at the default
    baseColor.foreground = defaultColor.foreground
    baseColor.background = defaultColor.background
    for index, section in pairs(prompt_sections) do
        prompt = prompt ..
                     promptContent(section.content(context), context, index > 1)
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