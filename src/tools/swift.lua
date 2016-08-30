--
-- swift.lua
-- Provides Swift-specific configuration strings.
--


	premake.swift = { }


--
-- Set default tools
--

	premake.swift.swiftc = "swiftc"
	premake.swift.swift  = "swift"
	premake.swift.cc     = "gcc"
	premake.swift.ar     = "ar"
	premake.swift.ld     = "ld"


--
-- Translation of Premake flags into Swift flags
--

local swiftcflags =
{
	Symbols                   = "-g",                             -- Produce debug information
	DisableWarnings           = "--suppress-warnings",            -- Disable warnings
	FatalWarnings             = "--warnings-as-errors",           -- Treat warnings as fatal
	Optimize                  = "-O -whole-module-optimization",
	OptimizeSize              = "-O -whole-module-optimization",
	OptimizeSpeed             = "-Ounchecked -whole-module-optimization",
	MinimumWarnings           = "-minimum-warnings",
}

local swiftlinkflags = {
	StaticRuntime             = "-static-stdlib",
}

premake.swift.platforms = {
	Native = {
		swiftcflags    = "",
		swiftlinkflags = "",
		ldflags        = "-arch x86_64",
	},
	x64 = {
		swiftcflags    = "",
		swiftlinkflags = "",
		ldflags        = "-arch x86_64",
	}
}

local platforms = premake.swift.platforms

--
-- Returns a list of compiler flags, based on the supplied configuration.
--

function premake.swift.get_sdk_path(cfg)
	return string.trim(os.outputof("xcrun --show-sdk-path"))
end

function premake.swift.get_sdk_platform_path(cfg)
	return string.trim(os.outputof("xcrun --show-sdk-platform-path"))
end

function premake.swift.get_toolchain_path(cfg)
	return string.trim(os.outputof("xcode-select -p")) .. "/Toolchains/XcodeDefault.xctoolchain"
end

function premake.swift.gettarget(cfg)
	return "-target x86_64-apple-macosx10.11"
end

function premake.swift.getswiftcflags(cfg)
	local result = table.translate(cfg.flags, swiftcflags)
	table.insert(result, platforms[cfg.platform].swiftcflags)
	return result
end

function premake.swift.getswiftlinkflags(cfg)
	local result = table.translate(cfg.flags, swiftlinkflags)
	table.insert(result, platforms[cfg.platform].swiftlinkflags)
	return result
end

function premake.swift.getmodulemaps(cfg)
	local maps = {}
	if next(cfg.swiftmodulemaps) then
		for _, mod in ipairs(cfg.swiftmodulemaps) do
			table.insert(maps, string.format("-Xcc -fmodule-map-file=%s", mod))
		end
	end
	return maps
end

function premake.swift.getlibdirflags(cfg)
	return premake.gcc.getlibdirflags(cfg)
end

function premake.swift.getldflags(cfg)
	local result = { platforms[cfg.platform].ldflags }
	return result
end

function premake.swift.getlinkflags(cfg)
	return premake.gcc.getlinkflags(cfg)
end

function premake.swift.getarchiveflags(cfg)
	return ""
end
