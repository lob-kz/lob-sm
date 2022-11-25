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

bool gB_LateLoad;

bool gB_BaseComm;
bool gB_Profile;
bool gB_ClientTagLoaded[MAXPLAYERS + 1];
char gC_PlayerTags[MAXPLAYERS + 1][32];
char gC_PlayerTagColors[MAXPLAYERS + 1][16];

Database gH_DB;

bool gB_ClientColorLoaded[MAXPLAYERS + 1];
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
#include "lob-completion/gokz-options.sp"

// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("lob-completion");
	gB_LateLoad = late;
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
	if (gB_LateLoad)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
			{
				CheckClientTag(client);
				DB_LoadCompletion(client);
			}
		}
	}
	
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
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

public void GOKZ_OnOptionsMenuCreated(TopMenu topMenu)
{
	OnOptionsMenuCreated_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionsMenuReady(TopMenu topMenu)
{
	OnOptionsMenuReady_Options();
	OnOptionsMenuReady_OptionsMenu(topMenu);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CompletionOptionNames[CompletionOption_ChatTag], true))
	{
		CheckClientTag(client);
	}
	if (StrEqual(option, gC_CompletionOptionNames[CompletionOption_ChatColor], true))
	{
		CheckClientNameColor(client);
	}
}

public void GOKZ_OnOptionsLoaded(int client)
{
	if (IsClientInGame(client) && IsClientAuthorized(client))
	{
		CheckClientTag(client);
		CheckClientNameColor(client);
	}
}

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
	CheckClientTag(client);
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


public void OnCompletionLoaded(int client, float completion)
{
	CheckClientNameColor(client);
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
	if (gB_ClientTagLoaded[client])
	{
		GetClientChatTags(client, tags, sizeof(tags));
		StrCat(tags, sizeof(tags), " "); // Add space
	}

	char coloredName[MAX_NAME_LENGTH * 2];
	Completion_GetClientName(client, coloredName, sizeof(coloredName));

	if (IsSpectating(client))
	{
		SendChatFilter(client, "%s{default}*%s{default}: %s", tags, coloredName, sanitisedMessage);
		PrintToConsoleAll("%s*%s: %s", tags, sanitisedName, sanitisedMessage);
		PrintToServer("%s*%s: %s", tags, sanitisedName, sanitisedMessage);
	}
	else
	{
		SendChatFilter(client, "%s %s{default}: %s", tags, coloredName, sanitisedMessage);
		PrintToConsoleAll("%s%s: %s", tags, sanitisedName, sanitisedMessage);
		PrintToServer("%s%s: %s", tags, sanitisedName, sanitisedMessage);
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

// Chat tags
void CheckClientTag(int client)
{
	// This can break if the plugin is late loaded right in between OnClientAuthorized and OnClientPostAdminCheck.
	// But that is extremely unlikely anyway, considering late loading very rarely happens anyway.
	gB_ClientTagLoaded[client] = true;
	int flags = GetUserFlagBits(client);
	int value = GOKZ_GetOption(client, gC_CompletionOptionNames[CompletionOption_ChatTag]);
	switch (value)
	{
		case ChatTag_Owner:
		{
			if (!(flags & ADMFLAG_ROOT))
			{
				GOKZ_CycleOption(client, gC_CompletionOptionNames[CompletionOption_ChatTag]);
			}
		}
		case ChatTag_Admin:
		{
			if (!(flags & (ADMFLAG_ROOT | ADMFLAG_KICK)))
			{
				GOKZ_CycleOption(client, gC_CompletionOptionNames[CompletionOption_ChatTag]);
			}
		}
		case ChatTag_DONOR:
		{
			if (!(flags & (ADMFLAG_ROOT | ADMFLAG_CUSTOM2)))
			{
				GOKZ_CycleOption(client, gC_CompletionOptionNames[CompletionOption_ChatTag]);
			}
		}
		case ChatTag_VIP:
		{
			if (!(flags & (ADMFLAG_ROOT | ADMFLAG_CUSTOM1)))
			{
				GOKZ_CycleOption(client, gC_CompletionOptionNames[CompletionOption_ChatTag]);
			}
		}
	}
}

void GetClientChatTags(int client, char[] buffer, int maxlength)
{
	int tag = GOKZ_GetOption(client, gC_CompletionOptionNames[CompletionOption_ChatTag]);
	FormatEx(buffer, maxlength, "%c%s", gC_CompletionChatTagColors[tag], gC_CompletionChatTagNames[tag]);
}

// Chat color
void CheckClientNameColor(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	gB_ClientColorLoaded[client] = true;
	int value = GOKZ_GetOption(client, gC_CompletionOptionNames[CompletionOption_ChatColor]);
	switch (value)
	{
		case ChatColor_Rainbow:
		{
			if (gI_CompletionCount[client] < 1000)
			{
				int maxColor;
				for (int i = 0; i < LOB_CHATCOLOR_COUNT; i++)
				{
					if (gF_Completion[client] < gF_ChatColorCompletionRequired[i])
					{
						maxColor = i;
					}
					else
					{
						break;
					}
				}
				GOKZ_SetOption(client, gC_CompletionOptionNames[CompletionOption_ChatColor], maxColor);
			}
		}
		default:
		{
			if (gF_Completion[client] < gF_ChatColorCompletionRequired[value])
			{
				int maxColor;
				for (int i = 0; i < LOB_CHATCOLOR_COUNT; i++)
				{
					if (gF_Completion[client] < gF_ChatColorCompletionRequired[i])
					{
						maxColor = i;
					}
					else
					{
						break;
					}
				}
				GOKZ_SetOption(client, gC_CompletionOptionNames[CompletionOption_ChatColor], maxColor);
			}
		}
	}
}

void Completion_GetClientName(int client, char[] buffer, int size)
{
	char sanitisedName[MAX_NAME_LENGTH];
	GetClientName(client, sanitisedName, sizeof(sanitisedName));
	SanitiseChatInput(sanitisedName, sizeof(sanitisedName));
	if (gB_ClientColorLoaded[client])
	{
		GOKZ_LOB_FormatChatName(buffer, size, sanitisedName, GOKZ_GetOption(client, gC_CompletionOptionNames[CompletionOption_ChatColor]), gI_CompletionCount[client], true);
	}
}


// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (CompletionOption option; option < COMPLETIONOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_CompletionOptionNames[option], gC_CompletionOptionDescriptions[option], 
			OptionType_Int, gI_CompletionOptionDefaults[option], 0, gI_CompletionOptionCounts[option] - 1);
	}
}
