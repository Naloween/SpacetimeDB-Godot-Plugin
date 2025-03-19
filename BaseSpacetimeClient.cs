
#nullable enable

using Godot;
using System;
using SpacetimeDB;
using SpacetimeDB.Types;

public partial class BaseSpacetimeClient : Node
{
	const string HOST = "http://localhost:3000";
	const string MODULE = "";

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
