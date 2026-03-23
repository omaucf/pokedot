bump-deps:
	@pnpx npm-check-updates --deep -u

# ----------------------------------------
# C#/Godot commands
# ----------------------------------------
dotnet.format:
	@dotnet csharpier format .

dotnet.dry:
	@git clean -xdf .generated .godot .import

# ----------------------------------------
# Turbo commands
# ----------------------------------------
turbo.boundaries:
	@pnpm turbo boundaries

turbo.dry:
	@pnpm run-s clean && git clean -xdf .turbo node_modules

%:
	@:
