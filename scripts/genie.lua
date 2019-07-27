--
-- Premake 4.x build configuration script
--

--
-- Define the project. Put the release configuration first so it will be the
-- default when folks build using the makefile. That way they don't have to
-- worry about the /scripts argument and all that.
--
	premake.make.override = { "TARGET" }

--
-- Experimental option to use LuaJIT 2.1.x instead of regular Lua 5.x
-- default is off.
--
	newoption {
		trigger = "with-luajit",
		description = "Enable usage of LuaJIT instead of regular Lua.",
	}

	solution "genie"
		configurations {
			"Release",
			"Debug"
		}
		location (_OPTIONS["to"])

	project "genie"
		targetname "genie"
		language "C"
		kind "ConsoleApp"
		flags {
			"ExtraWarnings",
			"No64BitChecks",
			"StaticRuntime"
		}

		if _OPTIONS["with-luajit"] ~= nil then
			includedirs {
				"../src/host/luajit-2.1.0-beta3/src",
			}
		else
			includedirs {
				"../src/host/lua-5.3.0/src",
			}
		end

		files {
			"../**.lua",
			"../src/**.h",
			"../src/**.c",
			"../src/**.S",
			"../src/host/scripts.c",
		}

		excludes {
			"../src/premake.lua",
		}

		if _OPTIONS["with-luajit"] ~= nil then
			defines {
				"LUAJIT_ENABLE_LUA52COMPAT",
				"WITH_LUAJIT=1",
			}
			excludes {
				"../src/host/luajit-2.1.0-beta3/src/lua.c",
				"../src/host/luajit-2.1.0-beta3/src/luac.c",
				"../src/host/luajit-2.1.0-beta3/**.lua",
				"../src/host/luajit-2.1.0-beta3/etc/*.c",
				"../src/host/luajit-2.1.0-beta3/src/ljamalg.c",
				"../src/host/luajit-2.1.0-beta3/src/host/*.c",
				"../src/host/luajit-2.1.0-beta3/src/luajit.c",
			}
			removefiles {
				"../src/host/lua-5.3.0/**.*",
			}
		else
			excludes {
				"../src/host/lua-5.3.0/src/lua.c",
				"../src/host/lua-5.3.0/src/luac.c",
				"../src/host/lua-5.3.0/**.lua",
				"../src/host/lua-5.3.0/etc/*.c",
			}
			removefiles {
				"../src/host/luajit-2.1.0-beta3/**.*",
			}
		end

		buildoptions {
			"-m64",
		}

		configuration "Debug"
			defines     { "_DEBUG", "LUA_COMPAT_MODULE" }
			flags       { "Symbols" }

		configuration "Release"
			defines     { "NDEBUG", "LUA_COMPAT_MODULE" }
			flags       { "OptimizeSize" }

		configuration "vs*"
			defines     { "_CRT_SECURE_NO_WARNINGS" }

		configuration "windows"
			targetdir   "../bin/windows"
			links { "ole32" }

		configuration "linux"
			targetdir   "../bin/linux"
			links       { "dl" }

		configuration "bsd"
			targetdir   "../bin/bsd"

		configuration "linux or bsd"
			defines      { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
			buildoptions { "-Wno-implicit-fallthrough" }
			links        { "m" }
			linkoptions  { "-rdynamic" }

		configuration "macosx"
			targetdir    "../bin/darwin"
			defines      { "LUA_USE_MACOSX" }
			links        { "CoreServices.framework" }

			if _OPTIONS["with-luajit"] ~= nil then
				linkoptions  { "-pagezero_size 10000", "-image_base 100000000" }
			end

		configuration { "macosx", "gmake" }
			buildoptions { "-mmacosx-version-min=10.6" }
			linkoptions  { "-mmacosx-version-min=10.6" }

		configuration {}


--
-- A more thorough cleanup.
--

	if _ACTION == "clean" then
		os.rmdir("bin")
		os.rmdir("build")
	end



--
-- Use the --to=path option to control where the project files get generated. I use
-- this to create project files for each supported toolset, each in their own folder,
-- in preparation for deployment.
--

	newoption {
		trigger = "to",
		value   = "path",
		description = "Set the output location for the generated files"
	}



--
-- Use the embed action to convert all of the Lua scripts into C strings, which
-- can then be built into the executable. Always embed the scripts before creating
-- a release build.
--

	dofile("embed.lua")

	newaction {
		trigger     = "embed",
		description = "Embed scripts in scripts.c; required before release builds",
		execute     = doembed
	}


--
-- Use the release action to prepare source and binary packages for a new release.
-- This action isn't complete yet; a release still requires some manual work.
--


	dofile("release.lua")

	newaction {
		trigger     = "release",
		description = "Prepare a new release (incomplete)",
		execute     = dorelease
	}
