local ninja = premake.ninja
local p = premake
local solution = p.solution

-- generate solution that will call ninja for projects

	local generate
	
	local function getconfigs(sln, name, plat)
		local cfgs = {}
		for prj in solution.eachproject(sln) do
			prj = ninja.get_proxy("prj", prj)
			for cfg in p.eachconfig(prj, plat) do
				if cfg.name == name then
					table.insert(cfgs, cfg)
				end
			end
		end
		return cfgs
	end

	function ninja.generate_solution(sln)
		-- create a shortcut to the compiler interface
		local cc = premake[_OPTIONS.cc]
		
		sln.getlocation = function(cfg, plat)
			return path.join(sln.location, premake.getconfigname(cfg, plat, true))
		end
		
		-- build a list of supported target platforms that also includes a generic build
		local platforms = premake.filterplatforms(sln, cc.platforms, "Native")
		
		for _,plat in ipairs(platforms) do
			for _,name in ipairs(sln.configurations) do
				p.generate(sln, ninja.get_solution_name(sln, name, plat), function(sln)
					generate(sln, plat, getconfigs(sln, name, plat))
				end)
			end
		end
	end
	
	function ninja.get_solution_name(sln, cfg, plat)
		return path.join(sln.getlocation(cfg, plat), "build.ninja")
	end
	
	function generate(sln, plat, prjcfgs)
		local cfgs          = {}
		local cfg_first     = nil
		local cfg_first_lib = nil
		
		_p("# solution build file")
		_p("# generated with GENie ninja")
		_p("")

		_p("# build projects")
		for _,cfg in ipairs(prjcfgs) do
			local name = cfg.name
			local key  = cfg.project.name

			-- fill list of output files
			if not cfgs[key] then cfgs[key] = "" end
			cfgs[key] = cfg:getoutputfilename() .. " "

			if not cfgs["all"] then cfgs["all"] = "" end
			cfgs["all"] = cfgs["all"] .. cfg:getoutputfilename() .. " "

			-- set first configuration name
			if (cfg_first == nil) and (cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp") then
				cfg_first = key
			end
			if (cfg_first_lib == nil) and (cfg.kind == "StaticLib" or cfg.kind == "SharedLib") then
				cfg_first_lib = key
			end

			-- include other ninja file
			_p("subninja " .. cfg:getprojectfilename())
		end
		
		_p("")

		_p("# targets")
		for cfg, outputs in iter.sortByKeys(cfgs) do
			_p("build " .. cfg .. ": phony " .. outputs)
		end
		_p("")

		_p("# default target")
		_p("default " .. (cfg_first or cfg_first_lib))
		_p("")
	end
