--
-- Generates Ninja project file for Swift
-- Copyright (c) 2016 Stuart Carnie and the GENie project
--

premake.ninja.swift = { }
local ninja = premake.ninja
local swift = premake.ninja.swift
local p     = premake

-- generate project + config build file
	function ninja.generate_swift(prj)
		local pxy = ninja.get_proxy("prj", prj)
		local tool = premake.gettool(prj)
		
		-- build a list of supported target platforms that also includes a generic build
		local platforms = premake.filterplatforms(prj.solution, tool.platforms, "Native")

		for _, platform in ipairs(platforms) do
			for cfg in p.eachconfig(pxy, platform) do
				p.generate(cfg, cfg:getprojectfilename(), function() swift.generate_config(prj, cfg) end)
			end
		end
	end
	
	function swift.generate_config(prj, cfg)
		local tool = premake.gettool(prj)
		
		_p("# Swift project build file")
		_p("# generated with GENie ninja")
		_p("")

		-- needed for implicit outputs, introduced in 1.7
		_p("ninja_required_version = 1.7")
		_p("")
		
		_p("target=".."")
		local sdk = tool.get_sdk_path(cfg)
		if sdk then
			_p("toolchain_path = "..tool.get_toolchain_path(cfg))
			_p("sdk_path = "..sdk)
			_p("platform_path = "..tool.get_sdk_platform_path(cfg))
			_p("sdk = -sdk $sdk_path")
			_p("ld_baseflags = -syslibroot $sdk_path -F $platform_path/Developer/Library/Frameworks -lSystem -L $toolchain_path/usr/lib/swift/macosx -rpath $toolchain_path/usr/lib/swift/macosx -macosx_version_min 10.10.0")
		else
			_p("sdk_path =")
			_p("sdk =")
			_p("ld_baseflags =")
		end
		
		_p("out_dir = "..cfg.buildtarget.directory)
		_p("obj_dir = "..path.join(cfg.objectsdir, prj.name .. ".build"))
		_p("module_name = "..prj.name)
		_p("flags = -g -Onone")
		
		local flags = {
			-- defines    = ninja.list(tool.getdefines(cfg.defines)),
			-- includes   = ninja.list(table.join(tool.getincludedirs(cfg.includedirs), tool.getquoteincludedirs(cfg.userincludedirs))),
			swiftflags = ninja.list(tool.getswiftflags(cfg)),
		}

		_p("")
			
		_p("# core rules for " .. cfg.name)
		_p("rule swiftc")
		_p("  command = " .. tool.swiftc .. " -frontend -c -primary-file $in $files $target $sdk -module-cache-path $out_dir/ModuleCache -emit-module-doc-path $obj_dir/$basename~partial.swiftdoc -module-name $module_name $flags -emit-module-path $obj_dir/$basename~partial.swiftmodule -emit-dependencies-path $out.d -emit-reference-dependencies-path $obj_dir/$basename.swiftdeps -o $out ")
		_p("  description = swiftc $out")
		_p("  depfile = $out.d")
		_p("  deps = gcc")
		_p("")
		_p("")
		_p("rule ar")
		_p("  command = " .. tool.ar .. " $flags $out $in $libs " .. (os.is("MacOSX") and " 2>&1 > /dev/null | sed -e '/.o) has no symbols$$/d'" or ""))
		_p("  description = ar $out")
		_p("")
		
		
		local link = "ld"
		_p("rule link")
		_p("  command = " .. tool.ld .. " -o $out $in $ld_baseflags $all_ldflags $libs")
		_p("  description = link $out")
		_p("")

		swift.file_rules(cfg, flags)
		
		local objfiles = {}
		
		for _, file in ipairs(cfg.files) do
			if path.isSourceFile(file) then
				table.insert(objfiles, swift.objectname(cfg, file))
			end
		end
		_p('')
		
		swift.linker(prj, cfg, objfiles, tool, flags)

		_p("")
	end
	
	function swift.objectname(cfg, file)
		return path.join("$obj_dir", path.getname(file)..".o")
	end

	function swift.file_rules(cfg, flags)
		_p("# build files")
		local sfiles = Set(cfg.files)
		
		for _, file in ipairs(cfg.files) do
			if path.isSourceFile(file) then
				local objfilename = swift.objectname(cfg, file)
				
				if path.isswiftfile(file) then
					_p("build " .. objfilename .. ": swiftc " .. file)
					_p(1, "basename = "..path.getbasename(file))
					_p(1, "files = ".. ninja.list(sfiles - {file}))
					cflags = "swiftflags"
				end
				
				_p(1, "flags    = " .. flags[cflags])
			elseif path.isresourcefile(file) then
				-- TODO
			end
		end
		
		_p("")
	end
	
	function swift.linker(prj, cfg, objfiles, tool)
		local all_ldflags = ninja.list(table.join(tool.getlibdirflags(cfg), tool.getldflags(cfg), cfg.linkoptions))
		local lddeps      = ninja.list(premake.getlinks(cfg, "siblings", "fullpath")) 
		local libs        = lddeps .. " " .. ninja.list(tool.getlinkflags(cfg))
		
		local function writevars()
			_p(1, "all_ldflags = " .. all_ldflags)
			_p(1, "libs        = " .. libs)
		end
		
		if cfg.kind == "StaticLib" then
			local ar_flags = ninja.list(tool.getarchiveflags(cfg, cfg, false))
			_p("# link static lib")
			_p("build " .. cfg:getoutputfilename() .. ": ar " .. table.concat(objfiles, " ") .. " | " .. lddeps)
			_p(1, "flags = " .. ninja.list(tool.getarchiveflags(cfg, cfg, false)))
		elseif cfg.kind == "SharedLib" then
			local output = cfg:getoutputfilename()
			_p("# link shared lib")
			_p("build " .. output .. ": link " .. table.concat(objfiles, " ") .. " | " .. libs)
			writevars()
		elseif (cfg.kind == "ConsoleApp") or (cfg.kind == "WindowedApp") then
			_p("# link executable")
			_p("build " .. cfg:getoutputfilename() .. ": link " .. table.concat(objfiles, " ") .. " | " .. lddeps)
			writevars()
		else
			p.error("ninja action doesn't support this kind of target " .. cfg.kind)
		end

	end
