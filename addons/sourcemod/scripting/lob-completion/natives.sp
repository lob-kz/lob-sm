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