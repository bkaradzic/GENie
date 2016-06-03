local ninja = premake.ninja
local p = premake
local solution = p.solution

-- generate solution that will call ninja for projects

	local generate
	
	local function getconfigs(sln, name)
		local cfgs = {}
		for prj in solution.eachproject(sln) do
			for cfg in p.eachconfig(prj) do
				if cfg.name == name then
					table.insert(cfgs, cfg)
				end
			end
		end
		return cfgs
	end

	function ninja.generate_solution(sln)
		for _,name in ipairs(sln.configurations) do
			p.generate(sln, ninja.get_solution_name(sln, name), function(sln)
				generate(sln, getconfigs(sln, name))
			end)
		end
	end
	
	function ninja.get_solution_name(sln, name)
		return "build_" .. name .. ".ninja"
	end
	
	function generate(sln, prjs)
		local cfgs          = {}
		local cfg_first     = nil
		local cfg_first_lib = nil
		
		_p("# solution build file")
		_p("# generated with GENie ninja")
		_p("")

		_p("# build projects")
		for _,cfg in ipairs(prjs) do
			local name = cfg.name
			local key = cfg.project.name .. "_" .. name

			if cfg.platform ~= nil then key = key .. "_" .. cfg.platform end

			-- fill list of output files
			if not cfgs[key] then cfgs[key] = "" end
			cfgs[key] = p.esc(ninja.outputFilename(cfg)) .. " "

			if not cfgs[cfg.name] then cfgs[cfg.name] = "" end
			cfgs[cfg.name] = cfgs[cfg.name] .. p.esc(ninja.outputFilename(cfg)) .. " "

			-- set first configuration name
			if (cfg_first == nil) and (cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp") then
				cfg_first = key
			end
			if (cfg_first_lib == nil) and (cfg.kind == "StaticLib" or cfg.kind == "SharedLib") then
				cfg_first_lib = key
			end

			-- include other ninja file
			_p("subninja " .. p.esc(ninja.projectCfgFilename(cfg, true)))
		end
		
		_p("")

		_p("# targets")
		for cfg, outputs in iter.sortByKeys(cfgs) do
			_p("build " .. p.esc(cfg) .. ": phony " .. outputs)
		end
		_p("")

		_p("# default target")
		_p("default " .. p.esc(cfg_first or cfg_first_lib))
		_p("")
	end
