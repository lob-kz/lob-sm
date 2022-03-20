/*
	Displays the top map completion menu.
*/

void DB_DisplayCompletionTop(int client)
{
	char query[1024];

	Transaction txn = SQL_CreateTransaction();

	// Query aliases and completed main courses
	FormatEx(query, sizeof(query), sql_maincoursecompletiontop, 50);
	txn.AddQuery(query);    
	// Get amount of main courses
	txn.AddQuery(sql_getcount_maincourses);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_DisplayCompletionTop, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_Low);
}

public void DB_TxnSuccess_DisplayCompletionTop(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client))
	{
		return;
	}

	if (!SQL_FetchRow(results[1]))
	{
		return;
	}

	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Completion Top - No Times");
		return;
	}

	int totalCourses = SQL_FetchInt(results[1], 0);

	Menu menu = new Menu(MenuHandler_CompletionTop);
	menu.Pagination = 5;
	menu.SetTitle("%t", "Completion Top Menu - Title");

	char display[256];
	int rank = 0;
	while (SQL_FetchRow(results[0]))
	{
		rank++;

		char alias[33];
		SQL_FetchString(results[0], 0, alias, sizeof(alias));

		int completedCourses = SQL_FetchInt(results[0], 1);
		float completion = (completedCourses / float(totalCourses)) * 100.0;

		FormatEx(display, sizeof(display), "#%-2d  %2.1f%%   %s", rank, completion, alias);
		menu.AddItem("", display, ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_CompletionTop(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
}
