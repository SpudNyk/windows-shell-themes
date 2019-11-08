-- Match my powershell prompt
local function powershell_prompt_filter()
    local l, r, path = clink.prompt.value:find("in (([a-zA-Z]:|~)\\.*)$")
    if path ~= nil then
        clink.chdir(path)
    end
end

-- only apply if it's powershell and ensure it runs after the other powershell
if clink.get_host_process() == "powershell.exe" then
    clink.prompt.register_filter(powershell_prompt_filter, -490)
end
