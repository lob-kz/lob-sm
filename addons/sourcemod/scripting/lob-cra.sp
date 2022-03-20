#include <sourcemod>

#include <lob/version>
#include <lob/core>
#include <lob/cra>

#include <autoexecconfig>
#include <sourcemod-colors>

#include <gokz>
#include <gokz/core>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#include <gokz/localdb>
#include <gokz/localranks>
#include <gokz/global>
#include <basecomm>
#include <lob/completion>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo =
{
	name = "LoB Cross Server Record Announcement",
	author = "zer0.k",
	version = LOB_VERSION
};

ConVar gCV_ServerPrefix;
ConVar gCV_ListenRecord;
ConVar gCV_RecordSoundCooldownGlobal;
ConVar gCV_RecordSoundCooldownLocal;
bool gB_PlayedRecentlyGlobal;
bool gB_PlayedRecentlyLocal;
bool gB_LoBCompletion;
bool gB_GOKZGlobal;
bool gB_GOKZLocal;
ArrayList gA_Records;

#include "lob-cra/records.sp"
#include "lob-cra/gokz-forwards.sp"
#include "lob-cra/gokz-options.sp"

// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("lob-cra");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("lob-cra.phrases");

	gA_Records = new ArrayList(sizeof(Record));
	CreateConVars();
	InitAnnounceTimer();
}

public void OnMapStart()
{
	LoadSounds();
}

public void LOB_OnMessageReceived(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4)
{
	if (StrEqual(type, SERVER_RECORD_MESSAGE_TYPE) || StrEqual(type, GLOBAL_RECORD_MESSAGE_TYPE) && gCV_ListenRecord.BoolValue)
	{
		CSkipNextPrefix();
		CPrintToChatAll("%s", arg1);

		PlayRecordSoundToAll(StrEqual(type, GLOBAL_RECORD_MESSAGE_TYPE));
	}
}

public void OnAllPluginsLoaded()
{
	gB_LoBCompletion = LibraryExists("lob-completion");
	gB_GOKZGlobal = LibraryExists("gokz-global");
	gB_GOKZLocal = LibraryExists("gokz-localranks");
	
	TopMenu topMenu;
	if (LibraryExists("gokz-core") && ((topMenu = GOKZ_GetOptionsTopMenu()) != null))
	{
		GOKZ_OnOptionsMenuReady(topMenu);
	}
}

public void OnLibraryAdded(const char[] name)
{
	gB_LoBCompletion = gB_LoBCompletion || StrEqual(name, "lob-completion");
	gB_GOKZGlobal = gB_GOKZGlobal || StrEqual(name, "gokz-global");
	gB_GOKZLocal = gB_GOKZLocal || StrEqual(name, "gokz-localranks");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_LoBCompletion = gB_LoBCompletion && !StrEqual(name, "lob-completion");
	gB_GOKZGlobal = gB_GOKZGlobal && !StrEqual(name, "gokz-global");
	gB_GOKZLocal = gB_GOKZLocal && !StrEqual(name, "gokz-localranks");
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

// =====[ GENERAL ]=====

void CreateConVars()
{
	AutoExecConfig_SetFile("lob-cra", "sourcemod/lob");
	AutoExecConfig_SetCreateFile(true);

	gCV_ServerPrefix = AutoExecConfig_CreateConVar("lob_cra_server_prefix", "LoB", "Server prefix for record Announcement.");
	gCV_ListenRecord = AutoExecConfig_CreateConVar("lob_cra_listen", "1", "Listen and announce records from other servers");
	gCV_RecordSoundCooldownGlobal = AutoExecConfig_CreateConVar("lob_cra_sound_cooldown_global", "2.0", "Cooldown between record sounds");
	gCV_RecordSoundCooldownLocal = AutoExecConfig_CreateConVar("lob_cra_sound_cooldown_local", "5.0", "Cooldown between record sounds");
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

void PlayRecordSoundToAll(bool global)
{
	if (global && !gB_PlayedRecentlyGlobal)
	{
		for (int client = 1; client < MaxClients; client++)
		{
			if (IsValidClient(client) && !IsFakeClient(client))
			{
				float volume = float(GOKZ_GetOption(client, gC_CRAOptionNames[RecordAnnounceOption_Volume])) / 10.0;
				if (volume != 0 && GOKZ_GetOption(client, gC_CRAOptionNames[RecordAnnounceOption_Type]) & 2)
				{
					EmitSoundToClient(client, GL_SOUND_NEW_RECORD_GLOBAL, .volume = volume);
				}
			}
		}
		gB_PlayedRecentlyGlobal = true;
		CreateTimer(gCV_RecordSoundCooldownGlobal.FloatValue, Timer_EndAnnounceCooldownGlobal);
	}
	else if (!gB_PlayedRecentlyLocal)
	{
		for (int client = 1; client < MaxClients; client++)
		{
			if (IsValidClient(client) && !IsFakeClient(client))
			{
				float volume = float(GOKZ_GetOption(client, gC_CRAOptionNames[RecordAnnounceOption_Volume])) / 10.0;
				if (volume != 0 && GOKZ_GetOption(client, gC_CRAOptionNames[RecordAnnounceOption_Type]) & 1)
				{
					EmitSoundToClient(client, GL_SOUND_NEW_RECORD_SERVER, .volume = volume);
				}
			}
		}
		gB_PlayedRecentlyLocal = true;
		CreateTimer(gCV_RecordSoundCooldownLocal.FloatValue, Timer_EndAnnounceCooldownLocal);
	}
}

Action Timer_EndAnnounceCooldownGlobal(Handle timer)
{
	gB_PlayedRecentlyGlobal = false;
}

Action Timer_EndAnnounceCooldownLocal(Handle timer)
{
	gB_PlayedRecentlyLocal = false;
}

void LoadSounds()
{
	char downloadPath[PLATFORM_MAX_PATH];
	FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", GL_SOUND_NEW_RECORD_GLOBAL);
	AddFileToDownloadsTable(downloadPath);
	PrecacheSound(GL_SOUND_NEW_RECORD_GLOBAL, true);

	FormatEx(downloadPath, sizeof(downloadPath), "sound/%s", GL_SOUND_NEW_RECORD_SERVER);
	AddFileToDownloadsTable(downloadPath);
	PrecacheSound(GL_SOUND_NEW_RECORD_SERVER, true);
}


// =====[ OPTIONS ]=====

void OnOptionsMenuReady_Options()
{
	RegisterOptions();
}

void RegisterOptions()
{
	for (RecordAnnounceOption option; option < RECORDANNOUNCEOPTION_COUNT; option++)
	{
		GOKZ_RegisterOption(gC_CRAOptionNames[option], gC_CRAOptionDescriptions[option], 
			OptionType_Int, gI_CRAOptionDefaults[option], 0, gI_CRAOptionCounts[option] - 1);
	}
}
