--
-- swift.lua
-- Provides Swift-specific configuration strings.
--


	premake.swift = { }


--
-- Set default tools
--

	premake.swift.swiftc = "swiftc"
	premake.swift.cc     = "gcc"
	premake.swift.ar     = "ar"
	premake.swift.ld     = "ld"


--
-- Translation of Premake flags into Swift flags
--

local swiftflags =
{
	Symbols                   = "-g",                             -- Produce debug information
	DisableWarnings           = "--suppress-warnings",            -- Disable warnings
	FatalWarnings             = "--warnings-as-errors",           -- Treat warnings as fatal
	Optimize                  = "-O",
	OptimizeSize              = "-O",
	OptimizeSpeed             = "-Ounchecked",
}

premake.swift.platforms = {}

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

function premake.swift.getswiftflags(cfg)
	return table.translate(cfg.flags, swiftflags)
end

function premake.swift.getlibdirflags(cfg)
	return premake.gcc.getlibdirflags(cfg)
end

function premake.swift.getldflags(cfg)
	return premake.gcc.getldflags(cfg)
end

function premake.swift.getlinkflags(cfg)
	return premake.gcc.getlinkflags(cfg)
end
