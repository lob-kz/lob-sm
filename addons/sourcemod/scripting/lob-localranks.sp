#include <sourcemod>

#include <gokz/core>
#include <gokz/localdb>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#include <gokz/profile>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo =
{
	name = "LOB LocalRanks",
	author = "Szwagi",
	version = "v1.0.1",
};

bool gB_GOKZProfile;
Database gH_DB = null;

#include "lob-localranks/sql.sp"
#include "lob-localranks/helpers.sp"
#include "lob-localranks/profile.sp"
#include "lob-localranks/map_completion.sp"



// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	LoadTranslations("lob-localranks.phrases");
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	gB_GOKZProfile = LibraryExists("gokz-profile");

	gH_DB = GOKZ_DB_GetDatabase();
	if (gH_DB == null)
	{
		SetFailState("No database");
	}
}



// =====[ COMMANDS ]=====

void RegisterCommands()
{
	RegConsoleCmd("sm_profile", CommandProfile, "[LOB] Open the local profile menu.");
	RegConsoleCmd("sm_mc", CommandMapCompletion, "[LOB] Open the map completion menu.");
}

public Action CommandProfile(int client, int args)
{
	if (args < 1)
	{
		DB_OpenProfile(client, GetSteamAccountID(client));
	}
	else if (args >= 1)
	{
		char argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argPlayer, sizeof(argPlayer));
		DB_OpenProfile_FindPlayer(client, argPlayer);
	}
	return Plugin_Handled;
}

public Action CommandMapCompletion(int client, int args)
{
	if (args < 1)
	{
		DB_OpenMapCompletionModeMenu(client, GetSteamAccountID(client));
	}
	else if (args >= 1)
	{
		char argPlayer[MAX_NAME_LENGTH];
		GetCmdArg(1, argPlayer, sizeof(argPlayer));
		DB_OpenMapCompletionModeMenu_FindPlayer(client, argPlayer);
	}
	return Plugin_Handled;
}
