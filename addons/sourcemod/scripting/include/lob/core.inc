#if defined _lob_core_included_
#endinput
#endif
#define _lob_core_included_



// =====[ FORWARDS ]=====

/**
 * Called when this server recieves a message.
 *
 * @param type		Type of the message.
 * @param arg1		Optional 1st argument.
 * @param arg2		Optional 2nd argument.
 * @param arg3		Optional 3rd argument.
 * @param arg4		Optional 4th argument.
 */
forward void LOB_OnMessageReceived(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4);



// =====[ NATIVES ]=====

/**
 * Posts a message for other servers to recieve.
 *
 * @param type		Type of the message.
 * @param arg1		Optional 1st argument.
 * @param arg2		Optional 2nd argument.
 * @param arg3		Optional 3rd argument.
 * @param arg4		Optional 4th argument.
 */
native void LOB_PostMessage(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4);



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_lob_core = 
{
	name = "lob-core", 
	file = "lob-core.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_lob_core_SetNTVOptional()
{
	MarkNativeAsOptional("LOB_PostMessage");
}
#endif
