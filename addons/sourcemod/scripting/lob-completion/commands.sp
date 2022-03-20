static float lastCommandTime[MAXPLAYERS + 1];



void RegisterCommands()
{
	RegConsoleCmd("sm_ctop", CommandCompletionTop, "[KZ] Open the completion leaderboards.");
}

public Action CommandCompletionTop(int client, int args)
{
	if (IsSpammingCommands(client))
	{
		return Plugin_Handled;
	}

	DB_DisplayCompletionTop(client);
	return Plugin_Handled;
}



// =====[ PRIVATE ]=====

bool IsSpammingCommands(int client, bool printMessage = true)
{
	float currentTime = GetEngineTime();
	float cooldown = 2.5;
	float timeSinceLastCommand = currentTime - lastCommandTime[client];
	if (timeSinceLastCommand < cooldown)
	{
		if (printMessage)
		{
			GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command", cooldown - timeSinceLastCommand + 0.1);
		}
		return true;
	}

	// Not spamming commands - all good!
	lastCommandTime[client] = currentTime;
	return false;
}