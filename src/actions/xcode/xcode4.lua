--
-- _xcode4.lua
-- Define the Apple XCode 4.0 action and support functions.
--

	local premake = premake
	premake.xcode4 = { }

	local xcode   = premake.xcode
	local xcode4  = premake.xcode4

	function xcode4.XCBuildConfiguration_Target(tr, target, cfg)
		local cfgname = xcode.getconfigname(cfg)
		local installpaths = {
			ConsoleApp = "/usr/local/bin",
			WindowedApp = "$(HOME)/Applications",
			SharedLib = "/usr/local/lib",
			StaticLib = "/usr/local/lib",
			Bundle    = "$(LOCAL_LIBRARY_DIR)/Bundles",
		}

		-- options table to return
		local options = {
			ALWAYS_SEARCH_USER_PATHS = "NO",
			GCC_DYNAMIC_NO_PIC = "NO",
			GCC_MODEL_TUNING = "G5",
			INSTALL_PATH = installpaths[cfg.kind],
			PRODUCT_NAME = cfg.buildtarget.basename,
		}

		if not cfg.flags.Symbols then
			options.DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"
		end

		if cfg.kind ~= "StaticLib" and cfg.buildtarget.prefix ~= "" then
			options.EXECUTABLE_PREFIX = cfg.buildtarget.prefix
		end

		if cfg.targetextension then
			local ext = cfg.targetextension
			options.EXECUTABLE_EXTENSION = iif(ext:startswith("."), ext:sub(2), ext)
		end

		if cfg.flags.ObjcARC then
			options.CLANG_ENABLE_OBJC_ARC = "YES"
		end

		local outdir = path.getdirectory(cfg.buildtarget.bundlepath)
		if outdir ~= "." then
			options.CONFIGURATION_BUILD_DIR = outdir
		end

		if tr.infoplist then
			options.INFOPLIST_FILE = tr.infoplist.cfg.name
		end

		local infoplist_file = nil

		for _, v in ipairs(cfg.files) do
			-- for any file named *info.plist, use it as the INFOPLIST_FILE
			if (string.find (string.lower (v), 'info.plist') ~= nil) then
				infoplist_file = string.format('$(SRCROOT)/%s', v)
			end
		end

		if infoplist_file ~= nil then
			options.INFOPLIST_FILE = infoplist_file
		end

		local action = premake.action.current()
		local get_opt = function(opt, def)
			return (opt and #opt > 0) and opt or def
		end

		local iosversion = get_opt(cfg.iostargetplatformversion, action.xcode.iOSTargetPlatformVersion)
		local macosversion = get_opt(cfg.macostargetplatformversion, action.xcode.macOSTargetPlatformVersion)
		local tvosversion = get_opt(cfg.tvostargetplatformversion, action.xcode.tvOSTargetPlatformVersion)

		if iosversion then
			options.IPHONEOS_DEPLOYMENT_TARGET = iosversion
		elseif macosversion then
			options.MACOSX_DEPLOYMENT_TARGET = macosversion
		elseif tvosversion then
			options.TVOS_DEPLOYMENT_TARGET = tvosversion
		end

		if cfg.kind == "Bundle" and not cfg.options.SkipBundling then
			options.PRODUCT_BUNDLE_IDENTIFIER = "genie." .. cfg.buildtarget.basename:gsub("%s+", ".") --replace spaces with .
			options.WRAPPER_EXTENSION = "bundle"
		end

		return options
	end

	function xcode4.XCBuildConfiguration_Project(tr, prj, cfg)
		local cfgname = xcode.getconfigname(cfg)
		local archs = {
			Native      = "$(NATIVE_ARCH_ACTUAL)",
			x32         = "i386",
			x64         = "x86_64",
			Universal32 = "$(ARCHS_STANDARD_32_BIT)",
			Universal64 = "$(ARCHS_STANDARD_64_BIT)",
			Universal   = "$(ARCHS_STANDARD_32_64_BIT)",
		}

		-- build list of "other" C/C++ flags
		local checks = {
			["-ffast-math"]          = cfg.flags.FloatFast,
			["-ffloat-store"]        = cfg.flags.FloatStrict,
			["-fomit-frame-pointer"] = cfg.flags.NoFramePointer,
		}

		local cflags = { }
		for flag, check in pairs(checks) do
			if check then
				table.insert(cflags, flag)
			end
		end

		-- build list of "other" linked flags. All libraries that aren't frameworks
		-- are listed here, so I don't have to try and figure out if they are ".a"
		-- or ".dylib", which Xcode requires to list in the Frameworks section
		local ldflags = { }
		for _, lib in ipairs(premake.getlinks(cfg, "system")) do
			if not xcode.isframework(lib) then
				table.insert(ldflags, "-l" .. lib)
			end
		end

		-- options table to return
		local options = {
			ARCHS                           = archs[cfg.platform],
			CONFIGURATION_TEMP_DIR          = "$(OBJROOT)",
			GCC_C_LANGUAGE_STANDARD         = "gnu99",
			GCC_PREPROCESSOR_DEFINITIONS    = cfg.defines,
			GCC_SYMBOLS_PRIVATE_EXTERN      = "NO",
			GCC_WARN_ABOUT_RETURN_TYPE      = "YES",
			GCC_WARN_UNUSED_VARIABLE        = "YES",
			HEADER_SEARCH_PATHS             = table.join(cfg.includedirs, cfg.systemincludedirs),
			LIBRARY_SEARCH_PATHS            = cfg.libdirs,
			OBJROOT                         = cfg.objectsdir,
			ONLY_ACTIVE_ARCH                = iif(premake.config.isdebugbuild(cfg), "YES", "NO"),
			OTHER_CFLAGS                    = table.join(cflags, cfg.buildoptions, cfg.buildoptions_c),
			OTHER_CPLUSPLUSFLAGS            = table.join(cflags, cfg.buildoptions, cfg.buildoptions_cpp),
			OTHER_LDFLAGS                   = table.join(ldflags, cfg.linkoptions),
			SDKROOT                         = xcode.toolset,
			USER_HEADER_SEARCH_PATHS        = cfg.userincludedirs,
		}

		if tr.entitlements then
			options.CODE_SIGN_ENTITLEMENTS = tr.entitlements.cfg.name
		end

		local targetdir = path.getdirectory(cfg.buildtarget.bundlepath)
		if targetdir ~= "." then
			options.CONFIGURATION_BUILD_DIR = "$(SYMROOT)"
			options.SYMROOT = targetdir
		end

		if cfg.flags.Symbols then
			options.COPY_PHASE_STRIP = "NO"
		end

		local excluded = xcode.cfg_excluded_files(prj, cfg)
		if #excluded > 0 then
			options.EXCLUDED_SOURCE_FILE_NAMES = excluded
		end

		if cfg.flags.NoExceptions then
			options.GCC_ENABLE_CPP_EXCEPTIONS = "NO"
		end

		if cfg.flags.NoRTTI then
			options.GCC_ENABLE_CPP_RTTI = "NO"
		end

		if cfg.flags.Symbols and not cfg.flags.NoEditAndContinue then
			options.GCC_ENABLE_FIX_AND_CONTINUE = "YES"
		end

		if cfg.flags.NoExceptions then
			options.GCC_ENABLE_OBJC_EXCEPTIONS = "NO"
		end

		if cfg.flags.Optimize or cfg.flags.OptimizeSize then
			options.GCC_OPTIMIZATION_LEVEL = "s"
		elseif cfg.flags.OptimizeSpeed then
			options.GCC_OPTIMIZATION_LEVEL = 3
		else
			options.GCC_OPTIMIZATION_LEVEL = 0
		end

		if cfg.pchheader and not cfg.flags.NoPCH then
			options.GCC_PRECOMPILE_PREFIX_HEADER = "YES"

			-- Visual Studio requires the PCH header to be specified in the same way
			-- it appears in the #include statements used in the source code; the PCH
			-- source actual handles the compilation of the header. GCC compiles the
			-- header file directly, and needs the file's actual file system path in
			-- order to locate it.

			-- To maximize the compatibility between the two approaches, see if I can
			-- locate the specified PCH header on one of the include file search paths
			-- and, if so, adjust the path automatically so the user doesn't have
			-- add a conditional configuration to the project script.

			local pch = cfg.pchheader
			for _, incdir in ipairs(cfg.includedirs) do

				-- convert this back to an absolute path for os.isfile()
				local abspath = path.getabsolute(path.join(cfg.project.location, incdir))

				local testname = path.join(abspath, pch)
				if os.isfile(testname) then
					pch = path.getrelative(cfg.location, testname)
					break
				end
			end

			options.GCC_PREFIX_HEADER = pch
		end

		if cfg.flags.FatalWarnings then
			options.GCC_TREAT_WARNINGS_AS_ERRORS = "YES"
		end

		if cfg.kind == "Bundle" then
			options.MACH_O_TYPE = "mh_bundle"
		end

		if cfg.flags.StaticRuntime then
			options.STANDARD_C_PLUS_PLUS_LIBRARY_TYPE = "static"
		end

		if cfg.flags.PedanticWarnings or cfg.flags.ExtraWarnings then
			options.WARNING_CFLAGS = "-Wall"
		end

		for _, val in ipairs(premake.xcode.parameters) do
			local eqpos = string.find(val, "=")
			if eqpos ~= nil then
				local key = string.trim(string.sub(val, 1, eqpos - 1))
				local value = string.trim(string.sub(val, eqpos + 1))
				options[key] = value
			end
		end

		return options
	end

	function xcode4.project(prj)
		local tr = xcode.buildprjtree(prj)
		xcode.Header(tr, 45)
		xcode.PBXBuildFile(tr)
		xcode.PBXContainerItemProxy(tr)
		xcode.PBXFileReference(tr,prj)
		xcode.PBXFrameworksBuildPhase(tr)
		xcode.PBXGroup(tr)
		xcode.PBXNativeTarget(tr)
		xcode.PBXProject(tr, "3.2")
		xcode.PBXReferenceProxy(tr)
		xcode.PBXResourcesBuildPhase(tr)
		xcode.PBXShellScriptBuildPhase(tr)
		xcode.PBXSourcesBuildPhase(tr,prj)
		xcode.PBXVariantGroup(tr)
		xcode.PBXTargetDependency(tr)
		xcode.XCBuildConfiguration(tr, prj, {
			ontarget = xcode4.XCBuildConfiguration_Target,
			onproject = xcode4.XCBuildConfiguration_Project,
		})
		xcode.XCBuildConfigurationList(tr)
		xcode.Footer(tr)
	end


--
-- xcode4 action
--

	newaction
	{
		trigger         = "xcode4",
		shortname       = "Xcode 4",
		description     = "Generate Apple Xcode 4 project files (experimental)",
		os              = "macosx",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib", "Bundle" },

		valid_languages = { "C", "C++" },

		valid_tools     = {
			cc     = { "gcc" },
		},

		valid_platforms = {
			Native = "Native",
			x32 = "Native 32-bit",
			x64 = "Native 64-bit",
			Universal32 = "32-bit Universal",
			Universal64 = "64-bit Universal",
			Universal = "Universal",
		},

		default_platform = "Universal",

		onsolution = function(sln)
			premake.generate(sln, "%%.xcworkspace/contents.xcworkspacedata", xcode.workspace_generate)
		end,

		onproject = function(prj)
			premake.generate(prj, "%%.xcodeproj/project.pbxproj", xcode4.project)
		end,

		oncleanproject = function(prj)
			premake.clean.directory(prj, "%%.xcodeproj")
			premake.clean.directory(prj, "%%.xcworkspace")
		end,

		oncheckproject = xcode.checkproject,

		xcode = {
			iOSTargetPlatformVersion = nil,
			macOSTargetPlatformVersion = nil,
			tvOSTargetPlatformVersion = nil,
		},
	}
