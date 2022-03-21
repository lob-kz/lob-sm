/*
	Include file for lob completion.
*/

#if defined _lob_completion_included_
#endinput
#endif
#define _lob_completion_included_

#define LOB_CHATCOLOR_COUNT 9

#define LOB_CHATCOLOR_OWNER 0x10 // gold
#define LOB_CHATCOLOR_ADMIN 0x04 // green
#define LOB_CHATCOLOR_DONOR 0x07 // red
#define LOB_CHATCOLOR_VIP 0x0C // dark blue
#define LOB_COMPLETION_CATEGORY "LoB - Completion"

enum CompletionOption:
{
	COMPLETIONOPTION_INVALID = -1, 
	CompletionOption_ChatTag,
	COMPLETIONOPTION_COUNT
};

enum
{
	ChatTag_Owner = 0,
	ChatTag_Admin,
	ChatTag_DONOR,
	ChatTag_VIP,
	ChatTag_None,
	CHATTAG_COUNT
}

stock int gI_ChatColors[LOB_CHATCOLOR_COUNT] =
{
	0x01, // default
	0x0A, // bluegrey
	0x0B, // blue
	0x09, // yellow
	0x10, // gold
	0x05, // light green
	0x06, // lime
	0x07, // light red
	0x02, // dark red
	// + rainbow at 1000 maps
};

stock char gI_ChatColorsSMColors[LOB_CHATCOLOR_COUNT][] =
{
	"{default}",
	"{bluegrey}",
	"{blue}",
	"{yellow}",
	"{gold}",
	"{lightgreen}",
	"{lime}",
	"{lightred}",
	"{darkred}",
}

stock float gF_ChatColorCompletionRequired[LOB_CHATCOLOR_COUNT] =
{
	0.0,
	2.5,
	5.0,
	10.0,
	15.0,
	22.5,
	30.0,
	40.0,
	50.0,
	// + rainbow at 1000 maps
};

stock char gC_CompletionOptionNames[COMPLETIONOPTION_COUNT][] = 
{
	"LOB Completion - Chat Tag",
};

stock char gC_CompletionOptionDescriptions[COMPLETIONOPTION_COUNT][] = 
{
	"Chat Tag - 0 = Owner, 1 = Admin, 2 = Donor, 3 = VIP, 4 = None"
};

stock char gC_CompletionOptionPhrases[COMPLETIONOPTION_COUNT][] = 
{
	"Options Menu - Chat Tag"
};

stock int gI_CompletionOptionCounts[COMPLETIONOPTION_COUNT] = 
{
	CHATTAG_COUNT
};

stock int gI_CompletionOptionDefaults[COMPLETIONOPTION_COUNT] = 
{
	ChatTag_Owner
};

stock char gC_CompletionChatTagPhrases[CHATTAG_COUNT][] = 
{
	"Options Menu - OWNER",
	"Options Menu - ADMIN",
	"Options Menu - DONOR",
	"Options Menu - VIP",
	"Options Menu - None"
};

stock void GOKZ_LOB_FormatChatName(char[] buffer, int maxlength, const char[] name, float completionPercent, int completionCount, bool smColors = false)
{
	if (completionCount >= 1000)
	{
		static const int rainbowChars[] = { 15, 16, 9, 5, 6, 10, 11, 12, 3, 14 };

		int j = 0;
		for (int i = 0; name[i]; i++, j += 2)
		{
			if (j > maxlength - 3)
				break;

			buffer[j] = rainbowChars[(completionCount + i) % sizeof(rainbowChars)];
			buffer[j + 1] = name[i];
		}
		buffer[j] = 0;
		return;
	}

	for (int i = LOB_CHATCOLOR_COUNT; i-- > 0;) 
	{
		if (completionPercent >= gF_ChatColorCompletionRequired[i])
		{
			if (!smColors)
			{
				Format(buffer, maxlength, "%c%s", gI_ChatColors[i], name);
			}
			else
			{
				Format(buffer, maxlength, "%s%s", gI_ChatColorsSMColors[i], name);
			}
			return;
		}
	}

	// default
	if (!smColors)
	{
		Format(buffer, maxlength, "%c%s", 0x01, name);
	}
	else
	{
		Format(buffer, maxlength, "%s%s", "{default}", name);
	}
}

enum
{
	WhiteListMode_Off,
	WhiteListMode_CompletionAndVipOnly,
	WhiteListMode_VipOnly
}

// =====[ NATIVES ]=====

/**
 * Gets the client name colored by their completion.
 * To be used by CPrintToChat.
 *
 * @param client	Client index.
 * @param buffer	Buffer to store client name.
 * @param size		Buffer size.
 */
native void GOKZ_LOB_Completion_GetClientName(int client, char[] buffer, int size);


// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_lob_completion = 
{
	name = "lob-completion", 
	file = "lob-completion.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_lob_completion_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_LOB_Completion_GetClientName");
}
