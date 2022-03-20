#define GLOBAL_TIMEOUT_DURATION 10.0
#define SERVER_RECORD_MESSAGE_TYPE "ServerRecord"
#define GLOBAL_RECORD_MESSAGE_TYPE "GlobalRecord"

#define GL_SOUND_NEW_RECORD_GLOBAL "gokz/holyshit.mp3"
#define GL_SOUND_NEW_RECORD_SERVER "lob/bonk.mp3"


enum struct Record
{
	char name[MAX_NAME_LENGTH * 2];
	int userid;
	int course;
	int mode;
	int recordType;
	int timestamp;
	char mapName[32];
	
	void InitRecord(int client, int course, int mode, int recordType)
	{
		if (gB_LoBCompletion)
		{
			GOKZ_LOB_Completion_GetClientName(client, this.name, sizeof(Record::name));
		}
		else
		{
			GetClientName(client, this.name, sizeof(Record::name));
		}
		this.userid = GetClientUserId(client);
		this.course = course;
		this.mode = mode;
		this.recordType = recordType;
		this.timestamp = GetTime();
		GetCurrentMapDisplayName(this.mapName, sizeof(Record::mapName));
	}

	bool MatchGlobal(int client, int course, int mode, int recordType)
	{
		return (this.userid == GetClientUserId(client) && this.course == course && this.mode == mode && this.recordType == recordType);
	}
}

void InitAnnounceTimer()
{
	CreateTimer(5.0, Timer_CheckRecord, INVALID_HANDLE, TIMER_REPEAT);
}

public Action Timer_CheckRecord(Handle timer)
{
	Record record;
	for (int i = 0; i < gA_Records.Length; i++)
	{
		gA_Records.GetArray(i, record, sizeof(Record));
		if (record.timestamp + GLOBAL_TIMEOUT_DURATION < GetTime())
		{
			if (gCV_ListenRecord.BoolValue)
			{
				AnnounceRecord(record, false);
			}
			gA_Records.Erase(i);
		}
	}
}

void AnnounceRecord(Record record, bool global)
{
	// Server prefix
	static char serverPrefix[33];
	gCV_ServerPrefix.GetString(serverPrefix, sizeof(serverPrefix));
	CProcessVariables(serverPrefix, sizeof(serverPrefix));

	// Course
	char courseString[32];
	if (record.course > 0)
	{
		FormatEx(courseString, sizeof(courseString), "{bluegrey}Bonus %i{grey}", record.course);
	}

	// Record type
	char recordTypeString[64];
	switch (record.recordType)
	{
		case RecordType_Nub:
		{
			FormatEx(recordTypeString, sizeof(recordTypeString), "%s", global ? "{red}GLOBAL NUB RECORD{grey}" : "{yellow}NUB RECORD{grey}");
		}
		case RecordType_NubAndPro:
		{
			FormatEx(recordTypeString, sizeof(recordTypeString), "%s", global ? "{darkred}GLOBAL PRO RECORD{grey}" :"{yellow}NUB{grey}/{blue}PRO RECORD{grey}");
		}
		case RecordType_Pro:
		{
			FormatEx(recordTypeString, sizeof(recordTypeString), "%s", global ? "{darkred}GLOBAL PRO RECORD{grey}": "{blue}PRO RECORD{grey}");
		}
	}

	// LoB 1: Bob set a new Bonus 1 PRO RECORD on kz_map [KZT]!
	char output[512];
	FormatEx(output, sizeof(output), "{orchid}%s{grey} | %s{grey} set a new %s %s on {default}%s{grey} [{purple}%s{grey}]", serverPrefix, record.name, courseString, recordTypeString, record.mapName, gC_ModeNamesShort[record.mode]);
	
	if (!global)
	{
		LOB_PostMessage(SERVER_RECORD_MESSAGE_TYPE, output, "", "", "");
	}
	else
	{
		LOB_PostMessage(GLOBAL_RECORD_MESSAGE_TYPE, output, "", "", "");
	}
}