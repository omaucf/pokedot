using Godot;

namespace Pokedot.App;

public partial class App : Node3D
{
	public override void _Ready() =>
		GD.PrintRich("Pokedot");
}
