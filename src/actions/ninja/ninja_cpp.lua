premake.ninja.cpp = { }
local ninja = premake.ninja
local cpp   = premake.ninja.cpp
local p     = premake
local tree  = p.tree

-- generate project + config build file
	function ninja.generate_cpp(prj)
		for cfg in p.eachconfig(prj) do
			p.generate(cfg, ninja.projectCfgFilename(cfg), function(cfg) cpp.generate_config(prj, cfg) end)
		end
	end
	
	function cpp.generate_config(prj, cfg)
		local tool = premake.gettool(prj)

		_p("# project build file")
		_p("# generated with GENie ninja")
		_p("")

		-- needed for implicit outputs, introduced in 1.7
		_p("ninja_required_version = 1.7")
		_p("")
		
		local flags = {
			defines   = ninja.list(tool.getdefines(cfg.defines)),
			includes  = ninja.list(table.join(tool.getincludedirs(cfg.includedirs), tool.getquoteincludedirs(cfg.userincludedirs))),
			cppflags  = ninja.list(tool.getcppflags(cfg)),
			cflags    = ninja.list(table.join(tool.getcflags(cfg), cfg.buildoptions, cfg.buildoptions_c)),
			cxxflags  = ninja.list(table.join(tool.getcflags(cfg), tool.getcxxflags(cfg), cfg.buildoptions, cfg.buildoptions_cpp)),
			objcflags = ninja.list(table.join(tool.getcflags(cfg), tool.getcxxflags(cfg), cfg.buildoptions, cfg.buildoptions_objc)),
		}

		_p("")
			
		_p("# core rules for " .. cfg.name)
		_p("rule cc")
		_p("  command = " .. tool.cc .. " $defines $includes $flags -MMD -MF $out.d -c -o $out $in")
		_p("  description = cc $out")
		_p("  depfile = $out.d")
		_p("  deps = gcc")
		_p("")
		_p("rule cxx")
		_p("  command = " .. tool.cxx .. " $defines $includes $flags -MMD -MF $out.d -c -o $out $in")
		_p("  description = cxx $out")
		_p("  depfile = $out.d")
		_p("  deps = gcc")
		_p("")
		_p("rule ar")
		_p("  command = " .. tool.ar .. " $flags $out $in $libs " .. (os.is("MacOSX") and " 2>&1 > /dev/null | sed -e '/.o) has no symbols$$/d'" or ""))
		_p("  description = ar $out")
		_p("")
		
		
		local link = iif(cfg.language == "C", "cc", "cxx")
		_p("rule link")
		_p("  command = " .. link .. " -o $out $in $all_ldflags $libs")
		_p("  description = link $out")
		_p("")

		cpp.file_rules(prj, cfg, flags)
		
		local objfiles = {}
		
		for _, file in ipairs(prj.files) do
			if path.isSourceFile(file) then
				-- check if file is excluded.
				if not table.icontains(cfg.excludes, file) then
					table.insert(objfiles, cpp.objectname(cfg, file))
				end
			end
		end
		_p('')
		
		cpp.linker(prj, cfg, objfiles, tool, flags)

		_p("")
	end
	
	function cpp.objectname(cfg, file)
		return path.join(cfg.objectsdir, path.trimdots(path.removeext(file)) .. ".o")
	end

	function cpp.file_rules(prj, cfg, flags)
		table.sort(prj.files)
		
		_p("# build files")
		
		for _, file in ipairs(prj.files or {}) do
			if path.isSourceFile(file) then
				local objfilename = cpp.objectname(cfg, file)
				
				local cflags = "cflags"
				if path.isobjcfile(file) then
					_p("build " .. p.esc(objfilename) .. ": cxx " .. p.esc(file))
					cflags = "objcflags"
				elseif path.iscfile(file) then
					_p("build " .. p.esc(objfilename) .. ": cc " .. p.esc(file))
				else
					_p("build " .. p.esc(objfilename) .. ": cxx " .. p.esc(file))
					cflags = "cxxflags"
				end
				
				_p(1, "flags    = " .. flags[cflags])
				_p(1, "includes = " .. flags.includes)
				_p(1, "defines  = " .. flags.defines)
			elseif path.isresourcefile(file) then
				-- TODO
			end
		end
		
		_p("")
	end
	
	function cpp.linker(prj, cfg, objfiles, tool)
		local all_ldflags = ninja.list(table.join(tool.getlibdirflags(cfg), tool.getldflags(cfg), cfg.linkoptions))
		local lddeps      = ninja.list(p.esc(premake.getlinks(cfg, "siblings", "fullpath"))) 
		local libs        = lddeps .. " " .. ninja.list(tool.getlinkflags(cfg))
		
		local function writevars()
			_p(1, "all_ldflags = " .. all_ldflags)
			_p(1, "libs        = " .. libs)
		end
		
		if cfg.kind == "StaticLib" then
			local ar_flags = ninja.list(tool.getarchiveflags(prj, cfg, false))
			_p("# link static lib")
			_p("build " .. p.esc(ninja.outputFilename(cfg)) .. ": ar " .. table.concat(p.esc(objfiles), " ") .. " | " .. libs)
			_p(1, "flags = " .. ninja.list(tool.getarchiveflags(prj, cfg, false)))
		elseif cfg.kind == "SharedLib" then
			local output = ninja.outputFilename(cfg)
			_p("# link shared lib")
			_p("build " .. p.esc(output) .. ": link " .. table.concat(p.esc(objfiles), " ") .. " | " .. libs)
			writevars()
		elseif (cfg.kind == "ConsoleApp") or (cfg.kind == "WindowedApp") then
			_p("# link executable")
			_p("build " .. p.esc(ninja.outputFilename(cfg)) .. ": link " .. table.concat(p.esc(objfiles), " ") .. " | " .. libs)
			writevars()
		else
			p.error("ninja action doesn't support this kind of target " .. cfg.kind)
		end

	end

	

