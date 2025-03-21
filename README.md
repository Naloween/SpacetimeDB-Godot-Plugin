# SpacetimeDB-Godot-Plugin

A Godot plugin wrapping around the C# SpacetimeDB client, easier binding generation and callbacks from a singleton autoload node.

## Install

This repo contains the files that should be present in your addons/ folder inside your godot project. You should also enable the plugin in your project settings.
To use the spacetimeClient properly, you should add it as an autoload singleton in your Project settings/autoloads/ and then selecting the script SpacetimeClient.cs 

## How to use

The addons adds a new dock on the top left of the godot editor. You should provide the path of the server folder containing your spacetime module. The path is relative to the res:// file in godot.
You should also provide the url of the spacetime server and the module name.
Then generate the module bindings directly with the provided button, it internally uses the `spacetime generate` command but also adds some more code inside the generated file to make everything compatible with godot.
You then can generate the C# script of the SpacetimeClient singleton using the other button, it will generate the signals for all of your table callbacks (insert, update and delete) and also wrapping all of your reducers.
If you want you can modify the SpacetimeClient.cs script as you like, because it inherits from the BaseSpacetimeClient file which is automatically generated (you can regenerate any time) and thus you shouldn't touch.

## Known issues

- The types of your tables cannot be transfered to GdScript, so all the callbacks will only refer the arguments as simple objects. (If you have a callback on PlayerInserted, then you will only access to inserted_row: Object, and will not have the typing of the row) However every data will be transfered ^roperly.
- One exception to the above is if you try to access a field of type Identity, as it cannot be directly transfered in godot it will not exist
- If you have Reducer or Table name conflicts with godot or C#. for example if you call your reducer "SetName" it will conflicts with the one from godot. Or if you call some custom stdb type "Color", the type will be godot compatible, but it will generate an error because it will not know if you refer to the Spacetime.Types.color or Godot.Color in the C# script.
