local function get_git_meta_folder(dir)
    if clink.is_dir(dir .. '/.git') then return dir .. '/.git' end
    local gitfile = io.open(dir .. '/.git')
    if not gitfile then return nil end
    local git_dir = gitfile:read():match('gitdir: (.*)')
    gitfile:close()
    return git_dir
end

local function get_git_folder_info(dir)
    local meta = get_git_meta_folder(dir)
    if not meta then return nil end
    return {root = dir, meta = meta, name = FILE_basename(dir)}
end

-- Get the git folder information meta and root
function GIT_get_dir_info(path)
    return FILE_closest_parent_info(path, get_git_folder_info)
end

---
-- Finds out the name of the current branch
-- @return {nil|git branch name}
---
function GIT_get_branch(git_meta)
    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_meta and io.open(git_meta .. '/HEAD')
    if not head_file then return nil end

    local HEAD = head_file:read()
    head_file:close()

    -- if HEAD matches branch expression, then we're on named branch
    -- otherwise it is a detached commit
    local branch_name = HEAD:match('ref: refs/heads/(.+)')

    return branch_name or ('HEAD detached at ' .. HEAD:sub(1, 7))
end

---
-- Gets the .git directory
-- copied from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
-- @return {bool} indicating there's a git directory or not
---
-- function get_git_dirGIT(path)
-- MOVED INTO CORE

---
-- Gets the status of working dir
-- @return {bool} indicating true for clean, false for dirty
---
function GIT_get_clean()
    local file = io.popen("git --no-optional-locks status --porcelain 2>nul")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()
    return true
end

---
-- Gets the conflict status
-- @return {bool} indicating true for conflict, false for no conflicts
---
function GIT_get_conflict()
    local file = io.popen("git diff --name-only --diff-filter=U 2>nul")
    for line in file:lines() do
        file:close()
        return true
    end
    file:close()
    return false
end

function CONTEXT_git_dir_info(context)
    local git_info = context.git_dir_info
    if git_info == false then return nil end
    if git_info ~= nil then return git_info end
    local dir_info = GIT_get_dir_info(context.cwd)
    if dir_info == nil then
        context.git_dir_info = false
    else
        context.git_dir_info = dir_info
    end
    return dir_info
end

function CONTEXT_git_branch(context)
    local git_branch = context.git_branch
    if git_branch == false then return nil end
    if git_branch ~= nil then return git_branch end
    local git_dir_info = CONTEXT_git_dir_info(context)
    if not git_dir_info then
        context.git_branch = false
        return nil
    end
    local branch = GIT_get_branch(git_dir_info.meta)
    if branch == nil then
        context.git_branch = false
    else
        context.git_branch = branch
    end
    return branch
end

function CONTEXT_git_status(context)
    local git_status = context.git_status
    if git_status == false then return nil end
    if git_status ~= nil then return git_status end
    if CONTEXT_git_branch(context) then
        if GIT_get_conflict() then
            context.git_status = "conflict"
        else
            if GIT_get_clean() then
                context.git_status = "clean"
            else
                context.git_status = "dirty"
            end
        end
        return context.git_status
    else
        context.git_status = false
    end
    return nil
end
