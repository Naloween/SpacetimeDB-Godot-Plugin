@tool
extends Control

var config;
var default_config;

func _ready() -> void:
	default_config = {"server_path": $ServerPath.text, "Host": $Host.text, "Module": $Module.text}
	var config_file = FileAccess.open(OS.get_user_data_dir() + "/spacetime_client_config.json", FileAccess.READ);
	if config_file == null:
		config = default_config
	else:
		config = JSON.parse_string(config_file.get_as_text());
		if config == null:
			config = default_config
	
	$ServerPath.text = config["server_path"]
	$Host.text = config["Host"]
	$Module.text = config["Module"]

func _on_generate_client_btn_pressed() -> void:
	upate_spacetime_client()
	save_config()

func _on_generate_bindings_btn_pressed() -> void:
	update_module_bindings()
	save_config()

func save_config():
	config["server_path"] = $ServerPath.text
	config["Host"] = $Host.text
	config["Module"] = $Module.text
	var config_file = FileAccess.open(OS.get_user_data_dir() + "/spacetime_client_config.json", FileAccess.WRITE);
	config_file.store_string(JSON.stringify(config))

func upate_spacetime_client():
	print("\nModifying the BaseSpacetimeClient...");
	var spacetime_classes = [];
	for file_name in DirAccess.open("res://module_bindings/Tables/").get_files():
		if file_name.substr(len(file_name)-3, 3) == ".cs":
			var spacetime_type_name = file_name.substr(0, len(file_name)-5);
			spacetime_classes.append(spacetime_type_name);
	
	#	Generating base content
	var content = SPACETIME_CLIENT_CONTENT;
	
	content = insert_at_pattern(content, "HOST", " = \"" + $Host.text+"\"");
	content = insert_at_pattern(content, "MODULE", " = \"" + $Module.text+"\"");
	
	for spdb_class in spacetime_classes:
		# Adding signals
		content = insert_at_pattern(content, "// Insert Signals", "\n	[Signal]\n	public delegate void "+spdb_class+"InsertedEventHandler("+spdb_class+" inserted_row);");
		content = insert_at_pattern(content, "// Update Signals", "\n	[Signal]\n	public delegate void "+spdb_class+"UpdatedEventHandler("+spdb_class+" old_row, "+spdb_class+" new_row);");
		content = insert_at_pattern(content, "// Delete Signals", "\n	[Signal]\n	public delegate void "+spdb_class+"DeletedEventHandler("+spdb_class+" deleted_row);");
			
#		Adding callbacks
		content = insert_at_pattern(content, "// Add Insert Callbacks", "\n		conn.Db."+spdb_class+".OnInsert += "+spdb_class+"_OnInsert;");
		content = insert_at_pattern(content, "// Add Update Callbacks", "\n		conn.Db."+spdb_class+".OnUpdate += "+spdb_class+"_OnUpdate;");
		content = insert_at_pattern(content, "// Add Delete Callbacks", "\n		conn.Db."+spdb_class+".OnDelete += "+spdb_class+"_OnDelete;");
			
#		Creating callbacks
		content = insert_at_pattern(content, "// Insert Callbacks", "\n	void "+spdb_class+"_OnInsert(EventContext ctx, "+spdb_class+" inserted_row){\n		EmitSignal(SignalName."+spdb_class+"Inserted, inserted_row);\n	}");
		content = insert_at_pattern(content, "// Update Callbacks", "\n	void "+spdb_class+"_OnUpdate(EventContext ctx, "+spdb_class+" old_row, "+spdb_class+" new_row){\n		EmitSignal(SignalName."+spdb_class+"Updated, old_row, new_row);\n	}");
		content = insert_at_pattern(content, "// Delete Callbacks", "\n	void "+spdb_class+"_OnDelete(EventContext ctx, "+spdb_class+" deleted_row){\n		EmitSignal(SignalName."+spdb_class+"Deleted, deleted_row);\n	}");
		
		var file = FileAccess.open("res://addons/spacetime_client/BaseSpacetimeClient.cs", FileAccess.WRITE);
		file.store_string(content);
		
func update_module_bindings():
	print("\nUpdating module bindings...");
	var server_path = $ServerPath.text;
	var output = []
	var exite_code = OS.execute("spacetime", ["generate", "--lang", "csharp", "-p", server_path, "-o", "./module_bindings"], output, true, true)
	for out in output:
		print(out)
	
	print("\nAdding godot bindings...");
	for file_name in DirAccess.open("res://module_bindings/Types/").get_files():
		if file_name.substr(len(file_name)-3, 3) == ".cs":
			print("Updating "+ file_name)
			var spacetime_type_name = file_name.substr(0, len(file_name)-5);
			var file = FileAccess.open("res://module_bindings/Types/"+file_name, FileAccess.READ);
			var content = file.get_as_text();
			file = FileAccess.open("res://module_bindings/Types/"+file_name, FileAccess.WRITE);
			
#			Adding the import
			content = insert_at_pattern(content, "using System.Runtime.Serialization;", "\nusing Godot;");
#			Adding the GodotObject extension class
			content = insert_at_pattern(content, "class "+ spacetime_type_name, ": GodotObject");
			
			file.store_string(content)

func insert_str(content: String, start_idx: int, value: String) -> String:
	var new_content = content.substr(0, start_idx) + value + content.substr(start_idx, len(content)-start_idx);
	return new_content

func insert_at_pattern(content: String, pattern: String, value: String) -> String:
	var index = content.find(pattern)
	var new_content = content;
	if index > 0:
		var start_idx = index + len(pattern)
		new_content = insert_str(content, start_idx, value);
	
	return new_content

const SPACETIME_CLIENT_CONTENT = """
#nullable enable

using Godot;
using System;
using SpacetimeDB;
using SpacetimeDB.Types;

public partial class BaseSpacetimeClient : Node
{
	const string HOST;
	const string MODULE;

	public Identity? local_identity = null;
	public DbConnection? conn = null;

	[Signal]
	public delegate void SubscriptionAppliedEventHandler();
	[Signal]
	public delegate void DisconnectedEventHandler();

	// Insert Signals
	// Update Signals
	// Delete Signals

	public override void _Ready()
	{
		AuthToken.Init("spacetime_db", "token.txt", OS.GetUserDataDir());
		conn = DbConnection.Builder()
			.WithUri(HOST)
			.WithModuleName(MODULE)
			.WithToken(AuthToken.Token)
			.OnConnect(OnConnected)
			.OnConnectError(OnConnectError)
			.OnDisconnect(OnDisconnected)
			.Build();
		RegisterCallbacks(conn);
	}

	public override void _PhysicsProcess(double delta)
	{
		conn?.FrameTick();
	}

	// Connection callbacks

	void OnConnected(DbConnection conn, Identity identity, string authToken)
	{
		local_identity = identity;
		AuthToken.SaveToken(authToken);

		conn.SubscriptionBuilder()
			.OnApplied(OnSubscriptionApplied)
			.SubscribeToAllTables();
	}
	void OnConnectError(Exception e)
	{
		GD.PrintErr($"Error while connecting: {e}");
	}
	void OnDisconnected(DbConnection conn, Exception? e)
	{
		if (e != null)
		{
			GD.PrintErr($"Disconnected abnormally: {e}");
		}
		else
		{
			GD.Print($"Disconnected normally.");
			EmitSignal(SignalName.Disconnected, []);
		}

	}

	void RegisterCallbacks(DbConnection conn)
	{
		// Add Insert Callbacks
		// Add Update Callbacks
		// Add Delete Callbacks
	}

	// Insert Callbacks
	// Update Callbacks
	// Delete Callbacks

	/// On sync data
	void OnSubscriptionApplied(SubscriptionEventContext ctx)
	{
		EmitSignal(SignalName.SubscriptionApplied, []);
	}

	// Closing connection

	public void CloseConnection()
	{
		if (conn == null)
		{
			return;
		}
		if (conn.IsActive)
		{
			conn.Disconnect();
			GD.Print("connection closed");
		}
	}


	public override void _Notification(int what)
	{
		if (what == Node.NotificationWMCloseRequest)
		{
			GD.Print("Game is exiting...");
			CloseConnection();
		}
		if (what == Node.NotificationCrash)
		{
			GD.Print("Game is crashed...");
			CloseConnection();
		}
		if (what == Node.NotificationExitTree)
		{
			GD.Print("Node Exited Tree...");
			CloseConnection();
		}

	}
}
"""
