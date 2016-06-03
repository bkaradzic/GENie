--
-- Name:        ninja_base.lua
-- Purpose:     Define the ninja action.
-- Author:      Stuart Carnie (stuart.carnie at gmail.com)
--

local ninja = premake.ninja

local p = premake

function ninja.esc(value)
	value = value:gsub("%$", "$$") -- TODO maybe there is better way
	value = value:gsub(":", "$:")
	value = value:gsub("\n", "$\n")
	value = value:gsub(" ", "$ ")
	return value
end

-- in some cases we write file names in rule commands directly
-- so we need to propely escape them
function ninja.shesc(value)
	if type(value) == "table" then
		local result = {}
		local n = #value
		for i = 1, n do
			table.insert(result, ninja.shesc(value[i]))
		end
		return result
	end

	if value:find(" ") then
		return "\"" .. value .. "\""
	end

	return value
end

function ninja.list(value)
	if #value > 0 then
		return " " .. table.concat(value, " ")
	else
		return ""
	end
end

-- return name of output binary relative to build folder
function ninja.outputFilename(cfg)
	return path.join(cfg.buildtarget.directory, cfg.buildtarget.name)
end

function ninja.cfg_location(cfg, relative)
	
end

-- return name of build file for configuration
function ninja.projectCfgFilename(cfg, relative)
	if relative ~= nil then
		relative = path.getrelative(cfg.solution.location, cfg.location) .. "/"
	else
		relative = ""
	end
	
	local ninjapath = relative .. "build_" .. cfg.project.name  .. "_" .. cfg.name
	
	if cfg.platform ~= nil then ninjapath = ninjapath .. "_" .. cfg.platform end
	
	return ninjapath .. ".ninja"
end

-- check if string starts with string
function ninja.startsWith(str, starts)
	return str:sub(0, starts:len()) == starts
end

-- check if string ends with string
function ninja.endsWith(str, ends)
	return str:sub(-ends:len()) == ends
end

-- removes extension from string
function ninja.noext(str, ext)
	return str:sub(0, str:len() - ext:len())
end

-- generate all build files for every project configuration
function ninja.generate_project(prj)
	ninja.generate_cpp(prj)
end
