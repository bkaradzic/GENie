--
-- Generates Ninja project file for Swift
-- Copyright (c) 2016 Stuart Carnie and the GENie project
--

local ninja = premake.ninja
local swift = { }
local p     = premake

-- generate project + config build using incremental approach of generating individual .o files
function ninja.generate_swift_incremental(prj)
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

	local flags = {
		swiftcflags = ninja.list(table.join(tool.getswiftcflags(cfg), cfg.buildoptions_swiftc)),
	}


	_p("# Swift project build file")
	_p("# generated with GENie ninja")
	_p("")

	-- needed for implicit outputs, introduced in 1.7
	_p("ninja_required_version = 1.7")
	_p("")

	_p("target=".."")
	_p("out_dir = "..cfg.buildtarget.directory)
	_p("obj_dir = "..path.join(cfg.objectsdir, prj.name .. ".build"))
	_p("module_name = "..prj.name)
	_p("module_maps = %s", ninja.list(tool.getmodulemaps(cfg)))
	_p("flags = %s", flags.swiftcflags)

	if (cfg.kind == "ConsoleApp") or (cfg.kind == "WindowedApp") then
		_p("parse_as_library = ")
	else
		_p("parse_as_library = -parse-as-library")
	end

	local sdk = tool.get_sdk_path(cfg)
	if sdk then
		_p("toolchain_path = "..tool.get_toolchain_path(cfg))
		_p("sdk_path = "..sdk)
		_p("platform_path = "..tool.get_sdk_platform_path(cfg))
		_p("sdk = -sdk $sdk_path")
		_p("ld_baseflags = -force_load $toolchain_path/usr/lib/arc/libarclite_macosx.a -L $out_dir -F $platform_path/Developer/Library/Frameworks -syslibroot $sdk_path -lobjc -lSystem -L $toolchain_path/usr/lib/swift/macosx -rpath $toolchain_path/usr/lib/swift/macosx -macosx_version_min 10.10.0 -no_objc_category_merging")
	else
		_p("sdk_path =")
		_p("sdk =")
		_p("ld_baseflags =")
	end
	_p("")

	_p("# core rules for " .. cfg.name)
	_p("rule swiftc")
	_p(1, "command = %s -frontend -c -primary-file $in $files $target -enable-objc-interop $sdk -I $out_dir -enable-testing -module-cache-path $out_dir/ModuleCache -D SWIFT_PACKAGE $module_maps -emit-module-doc-path $out_doc_name $flags $parse_as_library -module-name $module_name -emit-module-path $out_module_name -emit-dependencies-path $out.d -emit-reference-dependencies-path $obj_dir/$basename.swiftdeps -o $out", tool.swiftc)
	_p(1, "description = compile $out")
	_p("")

	_p("rule swiftm")
	_p(1, "command = swift -frontend -emit-module $in $parse_as_library $flags $target -enable-objc-interop $sdk -I $out_dir -F $platform_path/Developer/Library/Frameworks -enable-testing -module-cache-path $out_dir/ModuleCache -D SWIFT_PACKAGE $module_maps -emit-module-doc-path $out_dir/$module_name.swiftdoc -module-name $module_name -o $out")
	_p(1, "description = generate module")
	_p("")

	_p("rule swiftlink")
	_p(1, "command = swiftc $target $sdk $linkoptions_swift $flags -L $out_dir -o $out_dir/$module_name -F $platform_path/Developer/Library/Frameworks -emit-executable $in")
	_p(1, "description = create executable")
	_p("")

	_p("rule ar")
	_p(1, "command = " .. tool.ar .. " cr $flags $out $in $libs " .. (os.is("MacOSX") and " 2>&1 > /dev/null | sed -e '/.o) has no symbols$$/d'" or ""))
	_p(1, "description = ar $out")
	_p("")

	_p("rule link")
	_p("  command = %s $in $ld_baseflags $all_ldflags $libs -o $out", tool.ld)
	_p("  description = link $out")
	_p("")

	swift.file_rules(cfg, flags)

	local objfiles = {}
	local modfiles = {}
	local docfiles = {}

	for _, file in ipairs(cfg.files) do
		if path.isSourceFile(file) then
			table.insert(objfiles, swift.objectname(cfg, file))
			table.insert(modfiles, swift.modulename(cfg, file))
			table.insert(docfiles, swift.docname(cfg, file))
		end
	end
	_p("")

	swift.linker(prj, cfg, {objfiles, modfiles, docfiles}, tool, flags)

	_p("")
end

function swift.objectname(cfg, file)
	return path.join("$obj_dir", path.getname(file)..".o")
end

function swift.modulename(cfg, file)
	return path.join("$obj_dir", path.getname(file)..".o.swiftmodule")
end

function swift.docname(cfg, file)
	return path.join("$obj_dir", path.getname(file)..".o.swiftdoc")
end

function swift.file_rules(cfg, flags)
	_p("# build files")
	local sfiles = Set(cfg.files)

	for _, file in ipairs(cfg.files) do
		if path.isSourceFile(file) then
			if path.isswiftfile(file) then
				local objn = swift.objectname(cfg, file)
				local modn = swift.modulename(cfg, file)
				local docn = swift.docname(cfg, file)

				_p("build %s | %s %s: swiftc %s", objn, modn, docn, file)
				_p(1, "out_module_name = %s", modn)
				_p(1, "out_doc_name = %s", docn)
				_p(1, "files = ".. ninja.list(sfiles - {file}))
				build_flags = "swiftcflags"
			end

			_p(1, "flags    = " .. flags[build_flags])
		elseif path.isresourcefile(file) then
			-- TODO
		end
	end

	_p("")
end

function swift.linker(prj, cfg, depfiles, tool)
	local all_ldflags = ninja.list(table.join(tool.getlibdirflags(cfg), tool.getldflags(cfg), cfg.linkoptions))
	local lddeps      = ninja.list(premake.getlinks(cfg, "siblings", "fullpath")) 
	local libs        = lddeps .. " " .. ninja.list(tool.getlinkflags(cfg))

	local function writevars()
		_p(1, "all_ldflags = " .. all_ldflags)
		_p(1, "libs        = " .. libs)
	end

	local objfiles, modfiles, docfiles = table.unpack(depfiles)

	_p("build $out_dir/$module_name.swiftmodule | $out_dir/$module_name.swiftdoc: swiftm %s | %s", table.concat(modfiles, " "), table.concat(docfiles, " "))
	_p("")

	if cfg.kind == "StaticLib" then
		local ar_flags = ninja.list(tool.getarchiveflags(cfg, cfg, false))
		_p("build %s: ar %s | %s $out_dir/$module_name.swiftmodule $out_dir/$module_name.swiftdoc", cfg:getoutputfilename(), table.concat(objfiles, " "), lddeps)
		_p(1, "flags = %s", ninja.list(tool.getarchiveflags(cfg, cfg, false)))
	elseif cfg.kind == "SharedLib" then
		local output = cfg:getoutputfilename()
		_p("build %s : link %s | %s $out_dir/$module_name.swiftmodule $out_dir/$module_name.swiftdoc", output, table.concat(objfiles, " "), libs)
		writevars()
	elseif (cfg.kind == "ConsoleApp") or (cfg.kind == "WindowedApp") then
		--_p("build %s: link %s | %s $out_dir/$module_name.swiftmodule $out_dir/$module_name.swiftdoc", cfg:getoutputfilename(), table.concat(objfiles, " "), lddeps)
		--writevars()
		_p("build %s: swiftlink %s | %s $out_dir/$module_name.swiftmodule $out_dir/$module_name.swiftdoc", cfg:getoutputfilename(), table.concat(objfiles, " "), lddeps)
		_p(1, "linkoptions_swift = %s", ninja.list(cfg.linkoptions_swift))

	else
		p.error("ninja action doesn't support this kind of target " .. cfg.kind)
	end

end
