--
-- _xcode8.lua
-- Define the Apple XCode 8.0 action and support functions.
--

	local premake = premake
	premake.xcode8 = { }

	local xcode  = premake.xcode
	local xcode4 = premake.xcode4
	local xcode8 = premake.xcode8

	function xcode8.workspace_generate(sln)
		return xcode4.workspace_generate(sln)
	end

	function xcode8.XCBuildConfiguration_Project(tr, prj, cfg)
		local options = xcode4.XCBuildConfiguration_Project(tr, prj, cfg)

		-- By not setting the ARCHS option to anything, Xcode will pick it
		-- based on the selected build target.
		if cfg.platform == "Native" then
			options.ARCHS = nil
		end

		return table.merge(options, {
			CLANG_WARN_BOOL_CONVERSION = "YES",
			CLANG_WARN_CONSTANT_CONVERSION = "YES",
			CLANG_WARN_EMPTY_BODY = "YES",
			CLANG_WARN_ENUM_CONVERSION = "YES",
			CLANG_WARN_INFINITE_RECURSION = "YES",
			CLANG_WARN_INT_CONVERSION = "YES",
			CLANG_WARN_SUSPICIOUS_MOVE = "YES",
			CLANG_WARN_UNREACHABLE_CODE = "YES",
			CLANG_WARN__DUPLICATE_METHOD_MATCH = "YES",
			ENABLE_STRICT_OBJC_MSGSEND = "YES",
			ENABLE_TESTABILITY = "YES",
			GCC_NO_COMMON_BLOCKS = "YES",
			GCC_WARN_64_TO_32_BIT_CONVERSION = "YES",
			GCC_WARN_UNDECLARED_SELECTOR = "YES",
			GCC_WARN_UNINITIALIZED_AUTOS = "YES",
			GCC_WARN_UNUSED_FUNCTION = "YES",
			ONLY_ACTIVE_ARCH = "YES",
		})
	end

	function xcode8.project(prj)
		local tr = xcode.buildprjtree(prj)
		xcode.Header(tr, 48)
		xcode.PBXBuildFile(tr)
		xcode.PBXContainerItemProxy(tr)
		xcode.PBXFileReference(tr,prj)
		xcode.PBXFrameworksBuildPhase(tr)
		xcode.PBXGroup(tr)
		xcode.PBXNativeTarget(tr)
		xcode.PBXProject(tr, "8.0")
		xcode.PBXReferenceProxy(tr)
		xcode.PBXResourcesBuildPhase(tr)
		xcode.PBXShellScriptBuildPhase(tr)
		xcode.PBXSourcesBuildPhase(tr,prj)
		xcode.PBXVariantGroup(tr)
		xcode.PBXTargetDependency(tr)
		xcode.XCBuildConfiguration(tr, prj, {
			ontarget = xcode4.XCBuildConfiguration_Target,
			onproject = xcode8.XCBuildConfiguration_Project,
		})
		xcode.XCBuildConfigurationList(tr)
		xcode.Footer(tr)
	end


--
-- xcode8 action
--

	newaction
	{
		trigger         = "xcode8",
		shortname       = "Xcode 8",
		description     = "Generate Apple Xcode 8 project files (experimental)",
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
			Universal = "Universal",
		},

		default_platform = "Native",

		onsolution = function(sln)
			premake.generate(sln, "%%.xcworkspace/contents.xcworkspacedata", xcode8.workspace_generate)
		end,

		onproject = function(prj)
			premake.generate(prj, "%%.xcodeproj/project.pbxproj", xcode8.project)
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
