/*
	Loads a player's completion.
*/

void DB_LoadCompletion(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	char query[1024];

	Transaction txn = SQL_CreateTransaction();

	// Get main courses completed
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedanymode, GetSteamAccountID(client));
	txn.AddQuery(query);
	// Get amount of main courses
	txn.AddQuery(sql_getcount_maincourses);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_LoadCompletion, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_Normal);
}

public void DB_TxnSuccess_LoadCompletion(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);

	if (client == 0 || !IsClientAuthorized(client))
	{
		return;
	}

	if (!SQL_FetchRow(results[0]) || !SQL_FetchRow(results[1]))
	{
		return;
	}

	int completedCourses = SQL_FetchInt(results[0], 0);
	int totalCourses = SQL_FetchInt(results[1], 0);
 
	float completion = (completedCourses / float(totalCourses)) * 100.0;

	gF_Completion[client] = completion;
	gI_CompletionCount[client] = completedCourses;
	OnCompletionLoaded(client, completion);
}
