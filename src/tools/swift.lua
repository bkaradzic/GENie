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

function premake.swift.getswiftflags(cfg)
	return table.translate(cfg.flags, swiftflags)
end
