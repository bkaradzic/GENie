--
-- vstudio_slnx.lua
-- Generate a Visual Studio 2026+ solution.
--

premake.vstudio.slnx = {}
local vstudio = premake.vstudio
local slnx = premake.vstudio.slnx


function slnx.generate(sln)
    io.eol = '\r\n'

    -- Precompute Visual Studio configurations
    sln.vstudio_configs = premake.vstudio.buildconfigs(sln)
    -- Prepare imported projects
    premake.vstudio.bakeimports(sln)

    -- Mark the file as Unicode
    _p('\239\187\191')

    slnx.reorderProjects(sln)

    _p('<Solution>')
    slnx.configurations(sln)
    for prj in premake.solution.eachproject(sln) do
        slnx.project(prj)
    end
    _p('</Solution>')
end

--
-- If a startup project is specified, move it to the front of the project list.
-- This will make Visual Studio treat it like a startup project.
--

function slnx.reorderProjects(sln)
    if sln.startproject then
        for i, prj in ipairs(sln.projects) do
            if sln.startproject == prj.name then
                -- Move group tree containing the project to start of group list
                local cur = prj.group
                while cur ~= nil do
                    -- Remove group from array
                    for j, group in ipairs(sln.groups) do
                        if group == cur then
                            table.remove(sln.groups, j)
                            break
                        end
                    end

                    -- Add back at start
                    table.insert(sln.groups, 1, cur)
                    cur = cur.parent
                end

                -- Move the project itself to start
                table.remove(sln.projects, i)
                table.insert(sln.projects, 1, prj)
                break
            end
        end
    end
end

--
-- Write out an entry for a project
--

function slnx.project(prj)
    -- Build a relative path from the solution file to the project file
    local projpath = path.translate(
    path.getrelative(prj.solution.location, vstudio.projectfile(prj)), "\\")

    _p('  <Project Path="%s" />', projpath)
end

--
-- Write out the contents of the Configurations section, which lists
-- every platform used by at least one project in the slnx.
--

function slnx.configurations(sln)
    local platforms = {}

    for _, cfg in ipairs(sln.vstudio_configs) do
        local platform = cfg.platform

        if platform == "Any CPU" or platform == "Mixed Platforms" then
            if not table.contains(platforms, "Any CPU") then
                table.insert(platforms, "Any CPU")
            end
        else
            if not table.contains(platforms, platform) then
                table.insert(platforms, platform)
            end
        end
    end

    for prj in premake.solution.eachproject(sln) do
        if premake.isdotnetproject(prj) then
            if not table.contains(platforms, "Any CPU") then
                table.insert(platforms, "Any CPU")
            end
        end
    end

    table.sort(platforms)

    _p('  <Configurations>')
    for _, platform in ipairs(platforms) do
        _p('    <Platform Name="%s" />', platform)
    end
    _p('  </Configurations>')
end
