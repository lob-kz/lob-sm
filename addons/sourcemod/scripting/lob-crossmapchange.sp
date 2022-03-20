#include <sourcemod>

#include <lob/version>
#include <lob/core>

#include <autoexecconfig>
#include <sourcemod-colors>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "LoB Crossmapchange", 
	author = "Szwagi", 
	version = LOB_VERSION
};

#define CROSSMAPCHANGE_MESSAGE_TYPE "mapchange"

ConVar gCV_server_prefix;
char gC_PrevMapname[128];



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("lob-crossmapchange");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVars();
}

public void OnMapStart()
{
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));

	if (StrEqual(mapname, gC_PrevMapname))
	{
		return;
	}

	bool firstTime = (gC_PrevMapname[0] == 0);

	strcopy(gC_PrevMapname, sizeof(gC_PrevMapname), mapname);

	// We don't want to print a message if the server just started up.
	// Mainly because the configs for message prefixes isn't loaded yet for some reason.
	if (firstTime)
	{
		return;
	}

	static char serverPrefix[33];
	gCV_server_prefix.GetString(serverPrefix, sizeof(serverPrefix));
	CProcessVariables(serverPrefix, sizeof(serverPrefix));

	LOB_PostMessage(CROSSMAPCHANGE_MESSAGE_TYPE, serverPrefix, mapname, "", "");
}

public void LOB_OnMessageReceived(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4)
{
	if (!StrEqual(type, CROSSMAPCHANGE_MESSAGE_TYPE))
	{
		return;
	}

	CSkipNextPrefix();
	CPrintToChatAll("{orchid}%s changed map to {purple}%s{orchid}.", arg1, arg2);
}



// =====[ GENERAL ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("lob-crossmapchange", "sourcemod/lob");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_server_prefix = AutoExecConfig_CreateConVar("lob_crossmapchange_server_prefix", "LoB", "Server prefix for messages.");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}
