using Godot;

namespace Pokedot;

public partial class Main : Node2D
{
	public override void _Ready() =>
		CallDeferred(nameof(StartApp));

	private void StartApp() =>
		GetTree().ChangeSceneToFile("res://src/app/App.tscn");
}
