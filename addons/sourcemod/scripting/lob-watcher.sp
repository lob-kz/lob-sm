#include <sourcemod>
#include <autoexecconfig>

#include <lob/version>
#include <gokz/core>
ConVar gCV_AutoReloadTime;
public Plugin myinfo =
{
	name = "LOB Server Watcher", 
	author = "zer0.k", 
	version = LOB_VERSION
};

public void OnPluginStart()
{
	LoadTranslations("lob-watcher.phrases");
	RegConsoleCmd("sm_uptime", CommandUptime, "Check map uptime");
	CreateConVars();
}

public Action CommandUptime(int client, int args)
{
	char formattedTime[16];
	
	int roundedTime = RoundFloat(GetGameTickCount()*GetTickInterval() * 100); // Time rounded to number of centiseconds
	
	int centiseconds = roundedTime % 100;
	roundedTime = (roundedTime - centiseconds) / 100;
	int seconds = roundedTime % 60;
	roundedTime = (roundedTime - seconds) / 60;
	int minutes = roundedTime % 60;
	roundedTime = (roundedTime - minutes) / 60;
	int hours = roundedTime;
	
	if (hours == 0)
	{
		FormatEx(formattedTime, sizeof(formattedTime), "%d:%02d", minutes, seconds);
	}
	else
	{
		FormatEx(formattedTime, sizeof(formattedTime), "%d:%02d:%02d", hours, minutes, seconds);
	}
	GOKZ_PrintToChat(client, true, "%t", "Uptime", formattedTime);
	return Plugin_Handled;
}

public void OnGameFrame()
{
	if (!IsServerEmpty())
	{
		return;
	}
	if (GetGameTickCount() > gCV_AutoReloadTime.IntValue)
	{
		char map[PLATFORM_MAX_PATH];
		GetCurrentMap(map, sizeof(map))
		GetMapDisplayName(map, map, sizeof(map));
		ServerCommand("map %s", map);
	}
}
// =====[ ConVars ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("lob-watcher", "sourcemod/lob");
	AutoExecConfig_SetCreateFile(true);

	gCV_AutoReloadTime = AutoExecConfig_CreateConVar("lob_autorestarttime", "4608000", "", _, true, 5.0, false, _);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}


int IsServerEmpty()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			return false;
		}
	}
	return true;
}