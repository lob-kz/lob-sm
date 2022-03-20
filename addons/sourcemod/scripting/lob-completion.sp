#include <sourcemod>

#include <cstrike>

#include <gokz>
#include <gokz/core>
#include <gokz/localdb>

#include <lob/version>
#include <lob/completion>

#include <sourcemod-colors>
#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <basecomm>
#include <gokz/global>
#include <gokz/profile>

#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN
#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo =             
{
	name = "LOB Completion", 
	author = "Szwagi", 
	version = LOB_VERSION
};

bool gB_BaseComm;

bool gB_Profile;
char gC_PlayerTags[MAXPLAYERS + 1][32];
char gC_PlayerTagColors[MAXPLAYERS + 1][16];

Database gH_DB;

float gF_Completion[MAXPLAYERS + 1];
int gI_CompletionCount[MAXPLAYERS + 1];

ConVar gCV_chat_processing;
ConVar gCV_whitelist_mode;
ConVar gCV_whitelist_completion;

#include "lob-completion/natives.sp"
#include "lob-completion/commands.sp"
#include "lob-completion/db/sql.sp"
#include "lob-completion/db/helpers.sp"
#include "lob-completion/db/load_completion.sp"
#include "lob-completion/db/completion_top.sp"
#include "lob-completion/profiles.sp"


// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("lob-completion");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gokz-common.phrases");
	LoadTranslations("lob-completion.phrases");

	RegisterCommands();
	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	gB_Profile = LibraryExists("gokz-profile");
	gB_BaseComm = LibraryExists("basecomm");

	gH_DB = GOKZ_DB_GetDatabase();

	for (int client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client) && !IsFakeClient(client))
		{
			UpdateTags(client, GOKZ_GetCoreOption(client, Option_Mode));
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	gB_Profile = gB_Profile || StrEqual(name, "gokz-profile");
	gB_BaseComm = gB_BaseComm || StrEqual(name, "basecomm");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_Profile = gB_Profile && !StrEqual(name, "gokz-profile");
	gB_BaseComm = gB_BaseComm && !StrEqual(name, "basecomm");
}



// =====[ OTHER EVENTS ]=====

public void GOKZ_DB_OnDatabaseConnect(DatabaseType DBType)
{
	gH_DB = GOKZ_DB_GetDatabase();
}

public void OnConfigsExecuted()
{
	gCV_chat_processing = FindConVar("gokz_chat_processing");
	if (gCV_chat_processing != null)
	{
		gCV_chat_processing.BoolValue = false;
		gCV_chat_processing.AddChangeHook(OnConVarChanged);
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] intValue)
{
	if (convar == gCV_chat_processing)
	{
		gCV_chat_processing.BoolValue = false;
	}
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	gF_Completion[client] = -1.0;
	gI_CompletionCount[client] = -1;
}

public void OnClientConnected(int client)
{
	gC_PlayerTags[client][0] = '\0';
	gC_PlayerTagColors[client][0] = '\0';
}

public void OnClientPostAdminCheck(int client)
{
	DB_LoadCompletion(client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (IsClientInGame(client))
	{
		OnClientSayCommand_ChatProcessing(client, command, sArgs);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void GOKZ_OnOptionsLoaded(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && gB_Profile)
	{
		int mode = GOKZ_GetCoreOption(client, Option_Mode);
		UpdateTags(client, GOKZ_PF_GetRank(client, mode));
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	Option coreOption;
	if (GOKZ_IsCoreOption(option, coreOption) && coreOption == Option_Mode)
	{
		UpdateTags(client, newValue);
	}
	else if (StrEqual(option, gC_ProfileOptionNames[ProfileOption_ShowRankChat], true))
	{
		UpdateTags(client, GOKZ_GetCoreOption(client, Option_Mode));
	}
}

public void OnCompletionLoaded(int client, float completion)
{
	int mode = gCV_whitelist_mode.IntValue;
	if (mode == WhiteListMode_Off)
	{
		return;
	}

	bool vip = (GetUserFlagBits(client) != 0);
	if (mode == WhiteListMode_CompletionAndVipOnly)
	{
		float minCompletion = gCV_whitelist_completion.FloatValue;
		if (completion < minCompletion && !vip)
		{
			KickClient(client, "%t", "Kick - Completion And VIP", minCompletion);
		}
	}
	else if (mode == WhiteListMode_VipOnly)
	{
		if (!vip)
		{
			KickClient(client, "%t", "Kick - VIP");
		}
	}
}



// =====[ ConVars ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("lob-completion", "sourcemod/lob");
	AutoExecConfig_SetCreateFile(true);

	gCV_whitelist_mode = AutoExecConfig_CreateConVar("lob_whitelist_mode", "0", "Whitelist Mode: 0 = Off, 1 = Completion and VIP, 2 = VIP", _, true, 0.0, true, 2.0);
	gCV_whitelist_completion = AutoExecConfig_CreateConVar("lob_whitelist_completion", "40", "Percent of maps to complete on the server to join", _, true, 0.0, true, 100.0);
	
	ConVar CV_auto_mute = FindConVar("sv_mute_players_with_social_penalties");
	CV_auto_mute.BoolValue = false;
	CV_auto_mute.Flags = CV_auto_mute.Flags & ~FCVAR_DEVELOPMENTONLY;

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}



// =====[ CHAT PROCESSING ]=====

void OnClientSayCommand_ChatProcessing(int client, const char[] command, const char[] message)
{
	if (gB_BaseComm && BaseComm_IsClientGagged(client) || UsedBaseChat(client, command, message))
	{
		return;
	}

	// Resend messages that may have been a command with capital letters
	if ((message[0] == '!' || message[0] == '/') && IsCharUpper(message[1]))
	{
		char loweredMessage[128];
		String_ToLower(message, loweredMessage, sizeof(loweredMessage));
		FakeClientCommand(client, "say %s", loweredMessage);
		return;
	}

	char sanitisedMessage[128];
	strcopy(sanitisedMessage, sizeof(sanitisedMessage), message);
	SanitiseChatInput(sanitisedMessage, sizeof(sanitisedMessage));

	char sanitisedName[MAX_NAME_LENGTH];
	GetClientName(client, sanitisedName, sizeof(sanitisedName));
	SanitiseChatInput(sanitisedName, sizeof(sanitisedName));

	if (TrimString(sanitisedMessage) == 0)
	{
		return;
	}

	char tags[32];
	GetClientChatTags(client, tags, sizeof(tags));
	StrCat(tags, sizeof(tags), " "); // Add space

	char coloredName[MAX_NAME_LENGTH * 2];
	Completion_GetClientName(client, coloredName, sizeof(coloredName));

	if (IsSpectating(client))
	{
		SendChatFilter(client, "%s%s%s {default}*%s{default}: %s",
							gC_PlayerTagColors[client], gC_PlayerTags[client], tags, coloredName, sanitisedMessage);
		PrintToConsoleAll("%s%s *%s : %s", gC_PlayerTags[client], tags, sanitisedName, sanitisedMessage);
		PrintToServer("%s%s *%s : %s", gC_PlayerTags[client], tags, sanitisedName, sanitisedMessage);
	}
	else
	{
		SendChatFilter(client, "%s%s%s %s{default}: %s",
							gC_PlayerTagColors[client], gC_PlayerTags[client], tags, coloredName, sanitisedMessage);
		PrintToConsoleAll("* %s%s %s : %s", gC_PlayerTags[client], tags, sanitisedName, sanitisedMessage);
		PrintToServer("* %s%s %s : %s", gC_PlayerTags[client], tags, sanitisedName, sanitisedMessage);
	}
}

void SendChatFilter(int sender, const char[] format, any...)
{
	char buffer[1024];
	for (int client = 1; client <= MaxClients; client++)
	{
		int flags = GetUserFlagBits(sender);
		if (IsClientInGame(client) && (!IsClientMuted(client, sender) || flags & ADMFLAG_ROOT))
		{
			VFormat(buffer, sizeof(buffer), format, 3);
			GOKZ_PrintToChat(client, false, buffer);
		}
	}
}

void GetClientChatTags(int client, char[] buffer, int maxlength)
{
	int flags = GetUserFlagBits(client);
	if (flags & ADMFLAG_ROOT)
	{
		FormatEx(buffer, maxlength, "%cOWNER", LOB_CHATCOLOR_OWNER);
	}
	else if (flags & ADMFLAG_KICK)
	{
		FormatEx(buffer, maxlength, "%cADMIN", LOB_CHATCOLOR_ADMIN);
	}
	else if (flags & ADMFLAG_CUSTOM2)
	{
		FormatEx(buffer, maxlength, "%cDONOR", LOB_CHATCOLOR_DONOR);
	}
	else if (flags & ADMFLAG_CUSTOM1)
	{
		FormatEx(buffer, maxlength, "%cVIP", LOB_CHATCOLOR_VIP);
	}
}

bool UsedBaseChat(int client, const char[] command, const char[] message)
{
	// Assuming base chat is in use, check if message will get processed by basechat
	if (message[0] != '@')
	{
		return false;
	}
	
	if (strcmp(command, "say_team", false) == 0)
	{
		return true;
	}
	else if (strcmp(command, "say", false) == 0 && CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT))
	{
		return true;
	}
	
	return false;
}

void SanitiseChatInput(char[] message, int maxlength)
{
	Color_StripFromChatText(message, message, maxlength);
	CRemoveColors(message, maxlength);
	// Chat gets double formatted, so replace '%' with '%%%%' to end up with '%'
	ReplaceString(message, maxlength, "%", "%%%%");
}

void Completion_GetClientName(int client, char[] buffer, int size)
{
	char sanitisedName[MAX_NAME_LENGTH];
	GetClientName(client, sanitisedName, sizeof(sanitisedName));
	SanitiseChatInput(sanitisedName, sizeof(sanitisedName));
	GOKZ_LOB_FormatChatName(buffer, size, sanitisedName, gF_Completion[client], gI_CompletionCount[client], true);
}

