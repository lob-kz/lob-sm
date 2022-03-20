
public void GOKZ_GL_OnPointsUpdated(int client, int mode)
{
	int points = GOKZ_GL_GetRankPoints(client, mode);
	int rank;
	for (rank = 1; rank < RANK_COUNT; rank++)
	{
		if (points < gI_rankThreshold[mode][rank])
		{
			break;
		}
	}
	rank--;
	
	if (GOKZ_GetCoreOption(client, Option_Mode) == mode)
	{
		if (points == -1)
		{
			UpdateTags(client, -1);
		}
		else
		{
			UpdateTags(client, rank);
		}
	}
}

void UpdateTags(int client, int rank)
{
	if (rank != -1 &&
		GOKZ_GetOption(client, gC_ProfileOptionNames[ProfileOption_ShowRankChat]) == ProfileOptionBool_Enabled)
	{
		SetChatTag(client, gC_rankName[rank], gC_rankColor[rank]);
	}
	else
	{
		SetChatTag(client, "", "{default}");
	}
}

void SetChatTag(int client, const char[] tag, const char[] color)
{
	FormatEx(gC_PlayerTags[client], sizeof(gC_PlayerTags[]), "[%s %s] ", gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)], tag);
	FormatEx(gC_PlayerTagColors[client], sizeof(gC_PlayerTagColors[]), "%s", color);
}