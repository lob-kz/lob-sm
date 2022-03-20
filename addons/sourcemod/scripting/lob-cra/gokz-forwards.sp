public void GOKZ_LR_OnNewRecord(int client, int steamID, int mapID, int course, int mode, int style, int recordType)
{
	if (mapID != GOKZ_DB_GetCurrentMapID())
	{
		return;
	}
	Record record;
	record.InitRecord(client, course, mode, recordType);
	// Server is not global? Announce the record immediately.
	if (!gB_GOKZGlobal)
	{
		AnnounceRecord(record, false);
		return;
	}
	
	gA_Records.PushArray(record);
}

public void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall, float runTime)
{
	// Not a record? Don't care.
	if (rank != 1 && rankOverall != 1)
	{
		return;
	}

	int recordType;
	if (timeType == TimeType_Nub)
	{
		if (rankOverall == 1)
		{
			recordType = RecordType_Nub;
		}
	}
	else if (timeType == TimeType_Pro)
	{
		if (rankOverall == 1)
		{
			recordType = RecordType_NubAndPro;
		}
		else if (rank == 1)
		{
			recordType = RecordType_Pro;
		}
	}
	// No LocalDB? Just announce it immediately.
	if (!gB_GOKZLocal)
	{	
		Record record;
		record.InitRecord(client, course, mode, recordType);
		AnnounceRecord(record, true);
		return;
	}

	for (int i = 0; i < gA_Records.Length; i++)
	{
		Record record;
		gA_Records.GetArray(i, record);
		if (record.MatchGlobal(client, course, mode, recordType))
		{
			AnnounceRecord(record, true);
			gA_Records.Erase(i);
			break;
		}
	}
}

