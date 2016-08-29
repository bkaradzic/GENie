--
-- GENie - Project generator tool
-- https://github.com/bkaradzic/GENie#license
--

local qbs = premake.qbs

local function is_excluded(prj, cfg, file)
	if table.icontains(prj.excludes, file) then
		return true
	end

	if table.icontains(cfg.excludes, file) then
		return true
	end

	return false
end

function qbs.generate_project(prj)

	local indent = 0

	_p(indent, '/*')
	_p(indent, ' * QBS project file autogenerated by GENie')
	_p(indent, ' * https://github.com/bkaradzic/GENie')
	_p(indent, ' */')
	_p(indent, '')
	_p(indent, 'import qbs')
	_p(indent, '')

	if prj.kind == "ConsoleApp" then
		_p(indent, 'CppApplication {')
		_p(indent, 'consoleApplication: true')
	elseif prj.kind == "WindowedApp" then
		_p(indent, 'CppApplication {')
	elseif prj.kind == "StaticLib" then
		_p(indent, 'StaticLibrary {')
	elseif prj.kind == "SharedLib" then
		_p(indent, 'DynamicLibrary {')
	end

	indent = indent + 1
	_p(indent, 'name: "' .. prj.name .. '"')

	_p(indent, 'cpp.cxxLanguageVersion: "c++11"')
	_p(indent, 'cpp.enableReproducibleBuilds: true')

	_p(indent, 'Depends { name: "cpp" }')

	-- List dependencies, if there are any
	local deps = premake.getdependencies(prj)
	if #deps > 0 then
		for _, depprj in ipairs(deps) do
			_p(indent, 'Depends { name: "%s" }', depprj.name)
		end
	end

	local cc = premake.gettool(prj)
	local platforms = premake.filterplatforms(prj.solution, cc.platforms, "Native")

	_p('');
	for _, platform in ipairs(platforms) do
		for cfg in premake.eachconfig(prj, platform) do

			if cfg.platform ~= "Native" then

				_p(indent, 'Properties { /* %s */', premake.getconfigname(cfg.name, cfg.platform, true))

				indent = indent + 1

				local arch = ""

				if cfg.platform == "x32" then
					_p(indent, 'architectures: [ "x86" ]')
					arch = '&& qbs.architecture == "x86"'
				elseif cfg.platform == "x64" then
					_p(indent, 'architectures: [ "x86_64" ]')
					arch = '&& qbs.architecture == "x86_64"'
				end

				if cfg.name == "Debug" then
					_p(indent, 'condition: qbs.buildVariant == "debug" %s', arch)
				else
					_p(indent, 'condition: qbs.buildVariant == "release" %s', arch)
				end

				_p(indent, 'targetName: "%s"', cfg.buildtarget.name)
--				_p(indent, 'fileTagsFilter: "application"')
--				_p(indent, 'qbs.install: true')
--				_p(indent, 'qbs.installDir: "%s"', cfg.buildtarget.directory)
--				_p(indent, 'buildDirectory: "%s"', cfg.objectsdir)

--				qbs.list(
--					  indent
--					, "cpp.cppFlags"
--					, cc.getcppflags(cfg)
--					)

				qbs.list(
					  indent
					, "cpp.commonCompilerFlags"
					, cfg.buildoptions
					)

				qbs.list(
					  indent
					, "cpp.cFlags"
					, cfg.buildoptions_c
					)

				qbs.list(
					  indent
					, "cpp.cxxFlags"
					, cfg.buildoptions_cpp
					)

				qbs.list(
					  indent
					, "cpp.objcFlags"
					, cfg.buildoptions_objc
					)

				qbs.list(
					  indent
					, "cpp.objcxxFlags"
					, cfg.buildoptions_objc
					)

				if cfg.flags.StaticRuntime then
					_p(indent, 'cpp.runtimeLibrary: "static"')
				else
					_p(indent, 'cpp.runtimeLibrary: "dynamic"')
				end

				if cfg.flags.ExtraWarnings then
					_p(indent, 'cpp.warningLevel: "all"')
				end

				if cfg.flags.FatalWarnings then
					_p(indent, 'cpp.treatWarningsAsErrors: true')
				end

				if cfg.flags.NoRTTI then
					_p(indent, 'cpp.enableRtti: false')
				end

				if cfg.flags.Symbols then
					_p(indent, 'cpp.debugInformation: true')
				end

				for _, value in ipairs(cfg.flags) do
					if (value == "Optimize") then
					elseif (value == "OptimizeSize") then
						_p(indent, 'cpp.optimization: "small"')
					elseif (value == "OptimizeSpeed") then
						_p(indent, 'cpp.optimization: "fast"')
					end
				end

				qbs.list(
					  indent
					, "cpp.defines"
					, cfg.defines
				)

				local sortedincdirs = {}
				for _, includedir in ipairs(cfg.userincludedirs) do
					if includedir ~= nil then
						table.insert(sortedincdirs, includedir)
					end
				end
				for _, includedir in ipairs(cfg.includedirs) do
					if includedir ~= nil then
						table.insert(sortedincdirs, includedir)
					end
				end

				table.sort(sortedincdirs, includesort)
				qbs.list(
					  indent
					, "cpp.includePaths"
					, sortedincdirs
				)

				qbs.list(
					  indent
					, "cpp.staticLibraries"
					, premake.getlinks(cfg, "system", "fullpath")
				)

				qbs.list(
					  indent
					, "cpp.libraryPath"
					, cfg.libdirs
				)

				table.sort(prj.files)
				if #prj.files > 0 then
					_p(indent, 'files: [')
					for _, file in ipairs(prj.files) do
						if path.isSourceFile(file) then
							if not is_excluded(prj, cfg, file) then
								_p(indent+1, '"%s",', file)
							end
						end
					end
					_p(indent+1, ']')
				end

				if #prj.excludes > 0 then
					_p(indent, 'excludeFiles: [')
					table.sort(prj.excludes)
					for _, file in ipairs(prj.excludes) do
						if path.isSourceFile(file) then
							_p(indent+1, '"%s",', file)
						end
					end
					_p(indent+1, ']')
				end

				indent = indent - 1
				_p(indent, '}');
			end
		end
	end

	indent = indent - 1

	_p(indent, '}')
end
