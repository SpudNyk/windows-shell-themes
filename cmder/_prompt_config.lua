PROMPT_reset()
PROMPT_include("time")
PROMPT_include("path")
PROMPT_include("git-branch")
-- PROMPT_color(COLOR_Red, COLOR_Blue)
PROMPT_include("git-status")
-- PROMPT_color(COLOR_White)
PROMPT_include("npm", {
    showName = false
})
PROMPT_include("end")
-- set the window title and path
PROMPT_include("window")