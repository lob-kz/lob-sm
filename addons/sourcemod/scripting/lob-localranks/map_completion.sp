/*
	Displays completed/uncompleted maps.
*/



int mcTargetSteamID[MAXPLAYERS + 1];
char mcTargetAlias[MAXPLAYERS + 1][MAX_NAME_LENGTH];
int mcMode[MAXPLAYERS + 1];



// =====[ MAP COMPLETION MODE ]=====

void DB_OpenMapCompletionModeMenu(int client, int targetSteamID)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(targetSteamID);

	Transaction txn = SQL_CreateTransaction();

	// Retrieve name of target
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenMapCompletionModeMenu, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_OpenMapCompletionModeMenu(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int targetSteamID = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	// Get name of target
	if (!SQL_FetchRow(results[0]))
	{
		return;
	}
	SQL_FetchString(results[0], 0, mcTargetAlias[client], sizeof(mcTargetAlias[]));
	
	mcTargetSteamID[client] = targetSteamID;
	DisplayMapCompletionModeMenu(client);
}

void DB_OpenMapCompletionModeMenu_FindPlayer(int client, const char[] target)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(target);
	
	DB_FindPlayer(target, DB_TxnSuccess_OpenMapCompletionModeMenu_FindPlayer, data, DBPrio_Low);
}


public void DB_TxnSuccess_OpenMapCompletionModeMenu_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char playerSearch[33];
	data.ReadString(playerSearch, sizeof(playerSearch));
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	else if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{
		DB_OpenMapCompletionModeMenu(client, SQL_FetchInt(results[0], 0));
	}
} 



// =====[ MENUS ]=====

static void DisplayMapCompletionModeMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MapCompletionMode);
	menu.SetTitle("%T\n \n%T\n ", 
		"Map Completion", client,
		"Player - ?", client, mcTargetAlias[client]);

	GOKZ_MenuAddModeItems(client, menu, false);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void DisplayMapCompletionMenu(int client, int mode)
{
	mcMode[client] = mode;

	Menu menu = new Menu(MenuHandler_MapCompletion);
	menu.SetTitle("%T\n \n%T\n%T\n ", 
		"Map Completion", client,
		"Player - ?", client, mcTargetAlias[client],
		"Mode - ?", client, gC_ModeNames[mcMode[client]]);

	MapCompletionMenuAddItems(client, menu);
	menu.Display(client, MENU_TIME_FOREVER);
}

static void MapCompletionMenuAddItems(int client, Menu menu)
{
	char display[64];
	
	FormatEx(display, sizeof(display), "%T", "Completed Maps", client);
	menu.AddItem("", display);
	FormatEx(display, sizeof(display), "%T", "Completed Maps (PRO)", client);
	menu.AddItem("", display);

	FormatEx(display, sizeof(display), "%T", "Uncompleted Maps", client);
	menu.AddItem("", display);
	FormatEx(display, sizeof(display), "%T", "Uncompleted Maps (PRO)", client);
	menu.AddItem("", display);
}



// =====[ MAP COMPLETION ]=====

void DB_OpenMapCompletion(int client, int targetSteamID, int mode, int timeType, bool completed)
{
	char query[1024];
	Transaction txn = SQL_CreateTransaction();

	// Get target name
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);

	if (completed)
	{
		if (timeType == TimeType_Nub)
		{
			FormatEx(query, sizeof(query), sql_getcompletedmainmapcourses, targetSteamID, mode);
		}
		else
		{
			FormatEx(query, sizeof(query), sql_getcompletedmainmapcourses_pro, targetSteamID, mode);
		}
	}
	else
	{
		if (timeType == TimeType_Nub)
		{
			FormatEx(query, sizeof(query), sql_getuncompletedmainmapcourses, targetSteamID, mode);
		}
		else
		{
			FormatEx(query, sizeof(query), sql_getuncompletedmainmapcourses_pro, targetSteamID, mode);
		}	
	}	
	txn.AddQuery(query);

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientUserId(client));
	datapack.WriteCell(mode);
	datapack.WriteCell(timeType);
	datapack.WriteCell(completed);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_OpenMapCompletion, DB_TxnFailure_Generic_DataPack, datapack, DBPrio_Low);
}

public void DB_TxnSuccess_OpenMapCompletion(Handle db, DataPack datapack, int numQueries, Handle[] results, any[] queryData)
{
	datapack.Reset();
	int client = GetClientOfUserId(datapack.ReadCell());
	int mode = datapack.ReadCell();
	int timeType = datapack.ReadCell();
	bool completed = datapack.ReadCell();
	delete datapack;

	if (!IsValidClient(client))
	{
		return;
	}

	// Get target name
	if (!SQL_FetchRow(results[0]))
	{
		return;
	}
	char alias[MAX_NAME_LENGTH];
	SQL_FetchString(results[0], 0, alias, sizeof(alias));

	if (SQL_GetRowCount(results[1]) == 0)
	{
		if (timeType == TimeType_Nub)
		{
			if (completed)
			{
				GOKZ_PrintToChat(client, true, "%T", "Chat - No Maps Completed", client, alias);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%T", "Chat - All Maps Completed", client, alias);
			}
		}
		else
		{
			if (completed)
			{
				GOKZ_PrintToChat(client, true, "%T", "Chat - No Maps Completed (PRO)", client, alias);
			}
			else
			{
				GOKZ_PrintToChat(client, true, "%T", "Chat - All Maps Completed (PRO)", client, alias);
			}
		}
		DisplayMapCompletionMenu(client, mode);
		return;
	}

	Menu menu = new Menu(MenuHandler_MapCompletionSubmenu);
	if (completed)
	{
		if (timeType != TimeType_Pro)
		{
			menu.SetTitle("%T\n \n%T\n%T\n ", 
				"Completed Maps", client,
				"Player - ?", client, alias,
				"Mode - ?", client, gC_ModeNames[mode]);
		}
		else
		{
			menu.SetTitle("%T\n \n%T\n%T\n ", 
				"Completed Maps (PRO)", client,
				"Player - ?", client, alias,
				"Mode - ?", client, gC_ModeNames[mode]);
		}
	}
	else
	{
		if (timeType != TimeType_Pro)
		{
			menu.SetTitle("%T\n \n%T\n%T\n ", 
				"Uncompleted Maps", client,
				"Player - ?", client, alias,
				"Mode - ?", client, gC_ModeNames[mode]);
		}
		else
		{
			menu.SetTitle("%T\n \n%T\n%T\n ", 
				"Uncompleted Maps (PRO)", client,
				"Player - ?", client, alias,
				"Mode - ?", client, gC_ModeNames[mode]);
		}
	}

	char buffer[128];
	while (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, buffer, sizeof(buffer));
		menu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}



// =====[ MENU HANDLERS ]=====

public int MenuHandler_MapCompletionMode(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = mode
		DisplayMapCompletionMenu(param1, param2);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_MapCompletion(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		// param1 = client, param2 = idx
		switch(param2)
		{
			case 0: DB_OpenMapCompletion(param1, mcTargetSteamID[param1], mcMode[param1], TimeType_Nub, true);
			case 1: DB_OpenMapCompletion(param1, mcTargetSteamID[param1], mcMode[param1], TimeType_Pro, true);
			case 2: DB_OpenMapCompletion(param1, mcTargetSteamID[param1], mcMode[param1], TimeType_Nub, false);
			case 3: DB_OpenMapCompletion(param1, mcTargetSteamID[param1], mcMode[param1], TimeType_Pro, false);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayMapCompletionModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public int MenuHandler_MapCompletionSubmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel && param2 == MenuCancel_Exit)
	{
		DisplayMapCompletionMenu(param1, mcMode[param1]);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

