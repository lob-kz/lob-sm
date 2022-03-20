static GlobalForward H_OnMessageReceived;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnMessageReceived = new GlobalForward("LOB_OnMessageReceived", ET_Ignore, Param_String, Param_String, Param_String, Param_String, Param_String);
}

void Call_OnMessageReceived(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4)
{
	Call_StartForward(H_OnMessageReceived);
	Call_PushString(type);
	Call_PushString(arg1);
	Call_PushString(arg2);
	Call_PushString(arg3);
	Call_PushString(arg4);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("LOB_PostMessage", Native_PostMessage);
}

public int Native_PostMessage(Handle plugin, int numParams)
{
	static char type[32];
	static char arg1[512];
	static char arg2[512];
	static char arg3[512];
	static char arg4[512];

	GetNativeString(1, type, sizeof(type));
	GetNativeString(2, arg1, sizeof(arg1));
	GetNativeString(3, arg2, sizeof(arg2));
	GetNativeString(4, arg3, sizeof(arg3));
	GetNativeString(5, arg4, sizeof(arg4));

	DB_PostMessage(type, arg1, arg2, arg3, arg4);
}
