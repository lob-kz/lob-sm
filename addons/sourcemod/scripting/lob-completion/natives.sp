void CreateNatives()
{
	CreateNative("GOKZ_LOB_Completion_GetClientName", Native_GOKZ_LOB_Completion_GetClientName);
}

public int Native_GOKZ_LOB_Completion_GetClientName(Handle plugin, int numParams)
{
	int size = GetNativeCell(3);
	char[] buffer = new char[size];
	GetNativeString(2, buffer, size);
	Completion_GetClientName(GetNativeCell(1), buffer, size);
	SetNativeString(2, buffer, size, false);
}


public int Native_SetChatTag(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	char str[64];
	GetNativeString(2, str, sizeof(str));
	FormatEx(gC_PlayerTags[client], sizeof(gC_PlayerTags[]), "[%s %s] ", gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)], str);
	
	GetNativeString(3, gC_PlayerTagColors[client], sizeof(gC_PlayerTagColors[]));
}