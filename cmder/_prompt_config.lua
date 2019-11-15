PROMPT_reset()
PROMPT_color_default({
    foreground = COLOR_White,
    bold = false
})
PROMPT_include("time", {foreground = COLOR_Yellow, bold = true})
PROMPT_include("path", {foreground = COLOR_Cyan, bold = true})
PROMPT_include("git-branch", {foreground = COLOR_Magenta, bold = true})
PROMPT_include("git-status", {foreground = COLOR_Red, bold = true})
PROMPT_include("npm", {showName = false, foreground = COLOR_Blue, bold = true})
PROMPT_include("end", {foreground = COLOR_Green, bold = true})
-- set the window title and path
PROMPT_include("window")
