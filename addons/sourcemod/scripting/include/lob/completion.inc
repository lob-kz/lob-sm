/*
	Include file for lob completion.
*/

#if defined _lob_completion_included_
#endinput
#endif
#define _lob_completion_included_

#define LOB_COMPLETION_CATEGORY "LoB - Completion"

// =====[ ENUMS ]=====
enum CompletionOption:
{
	COMPLETIONOPTION_INVALID = -1, 
	CompletionOption_ChatTag,
	CompletionOption_ChatColor,
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

enum
{
	ChatColor_Default = 0,
	ChatColor_BlueGrey,
	ChatColor_Blue,
	ChatColor_Yellow,
	ChatColor_Gold,
	ChatColor_LightGreen,
	ChatColor_Lime,
	ChatColor_LightRed,
	ChatColor_DarkRed,
	ChatColor_Rainbow,
	LOB_CHATCOLOR_COUNT
}

enum
{
	WhiteListMode_Off,
	WhiteListMode_CompletionAndVipOnly,
	WhiteListMode_VipOnly
}

// =====[ STOCKS ]=====

// General options
stock char gC_CompletionOptionNames[COMPLETIONOPTION_COUNT][] = 
{
	"LOB Completion - Chat Tag",
	"LOB Completion - Chat Color",
};

stock char gC_CompletionOptionDescriptions[COMPLETIONOPTION_COUNT][] = 
{
	"Chat Tag - 0 = Owner, 1 = Admin, 2 = Donor, 3 = VIP, 4 = None",
	"Chat Color - 0 = default, 1 = bluegrey, 2 = blue, 3 = yellow, 4 = gold, 5 = lightgreen, 6 = lime, 7 = lightred, 8 = darkred, 9 = rainbow"
};

stock char gC_CompletionOptionPhrases[COMPLETIONOPTION_COUNT][] = 
{
	"Options Menu - Chat Tag",
	"Options Menu - Chat Name Color"
};

stock int gI_CompletionOptionCounts[COMPLETIONOPTION_COUNT] = 
{
	CHATTAG_COUNT,
	LOB_CHATCOLOR_COUNT
};

stock int gI_CompletionOptionDefaults[COMPLETIONOPTION_COUNT] = 
{
	ChatTag_Owner,
	ChatColor_Default
};

// Chat tags
stock char gC_CompletionChatTagPhrases[CHATTAG_COUNT][] = 
{
	"Options Menu - OWNER",
	"Options Menu - ADMIN",
	"Options Menu - DONOR",
	"Options Menu - VIP",
	"Options Menu - None"
};

stock int gC_CompletionChatTagColors[CHATTAG_COUNT][] = 
{
	0x10,
	0x04,
	0x07,
	0x0C,
	0x00
}

stock char gC_CompletionChatTagNames[CHATTAG_COUNT][] = 
{
	"OWNER",
	"ADMIN",
	"DONOR",
	"VIP",
	""
}

// Chat colors
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
	0 // + rainbow at 1000 maps
};

stock char gC_ChatColorsSMColors[LOB_CHATCOLOR_COUNT][] =
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
	""	// Rainbow treated differently
}

stock char gC_CompletionChatColorPhrases[LOB_CHATCOLOR_COUNT][] = 
{
	"Options Menu - Default",
	"Options Menu - Blue Grey",
	"Options Menu - Blue",
	"Options Menu - Yellow",
	"Options Menu - Gold",
	"Options Menu - Light Green",
	"Options Menu - Lime",
	"Options Menu - Light Red",
	"Options Menu - Dark Red",
	"Options Menu - Rainbow"
};

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
	1000.0 // + rainbow at 1000 maps (unused!)
};

stock void GOKZ_LOB_FormatChatName(char[] buffer, int maxlength, const char[] name, int color, int completionCount, bool smColors = false)
{
	if (color == ChatColor_Rainbow)
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
	else
	{
		if (!smColors)
		{
			Format(buffer, maxlength, "%c%s", gI_ChatColors[color], name);
		}
		else
		{
			Format(buffer, maxlength, "%s%s", gC_ChatColorsSMColors[color], name);
		}
		return;
	}
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
