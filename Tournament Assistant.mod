return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Tournament Assistant` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Tournament Assistant", {
			mod_script       = "scripts/mods/Tournament Assistant/Tournament Assistant",
			mod_data         = "scripts/mods/Tournament Assistant/Tournament Assistant_data",
			mod_localization = "scripts/mods/Tournament Assistant/Tournament Assistant_localization",
		})
	end,
	packages = {
		"resource_packages/Tournament Assistant/Tournament Assistant",
	},
}
