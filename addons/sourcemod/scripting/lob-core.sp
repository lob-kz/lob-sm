#include <sourcemod>

#include <lob/version>
#include <lob/core>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "LoB Core", 
	author = "Szwagi", 
	version = LOB_VERSION
};

Database gH_DB;
char gC_Source[32];

int gI_PlayerCount;
int gI_LastMessageID;
bool gB_ResetLastMessageID;
bool gB_LockQueryMessages;

ConVar gCV_lob_message_loopback;

#define INVALID_MESSAGE_ID -1

#include "lob-core/api.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("lob-core");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateGlobalForwards();
	CreateConVars();
	DB_SetupDatabase();
	InitSourceString();
}

public void OnMapStart()
{
	gI_PlayerCount = 0;
	gI_LastMessageID = INVALID_MESSAGE_ID;
	gB_ResetLastMessageID = true;
	gB_LockQueryMessages = true;

	CreateTimer(1.2, TimerQueryMessages, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerQueryMessages(Handle timer, any data)
{
	if (gI_PlayerCount > 0)
	{
		if (gB_ResetLastMessageID)
		{
			gI_LastMessageID = INVALID_MESSAGE_ID;
			gB_ResetLastMessageID = false;
			DB_ResetLastMessageID();
		}
		else if (gI_LastMessageID != INVALID_MESSAGE_ID && !gB_LockQueryMessages)
		{
			gB_LockQueryMessages = true;
			DB_QueryMessages();
		}
	}
	else
	{
		gB_ResetLastMessageID = true;
	}
	return Plugin_Continue;
}



// =====[ CLIENT EVENTS ]=====

public void OnClientConnected(int client)
{
	if (!IsFakeClient(client))
	{
		gI_PlayerCount++;
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client))
	{
		gI_PlayerCount--;
	}
}



// =====[ GENERAL ]=====

void InitSourceString()
{
	char ip[16];
	FindConVar("ip").GetString(ip, sizeof(ip));

	int port = FindConVar("hostport").IntValue;

	gH_DB.Format(gC_Source, sizeof(gC_Source), "%s:%d", ip, port);
}

void CreateConVars()
{
	gCV_lob_message_loopback = CreateConVar("lob_message_loopback", "0", "Server sending messages will recieve his own messages. For testing purposes.", _, true, 0.0, true, 1.0);
}



// =====[ DATABASE ]=====

char sql_messages_create[] = "\
CREATE TABLE IF NOT EXISTS Messages ( \
	ID INTEGER NOT NULL AUTO_INCREMENT, \
	Type VARCHAR(31) NOT NULL, \
	Source VARCHAR(31) NOT NULL, \
	Arg1 VARCHAR(255), \
	Arg2 VARCHAR(255), \
	Arg3 VARCHAR(255), \
	Arg4 VARCHAR(255), \
	PRIMARY KEY (ID))";

char sql_messages_gethighestid[] = "\
SELECT MAX(ID) From Messages";

char sql_messages_deleteolderthan[] = "\
DELETE FROM Messages \
	WHERE ID < (SELECT 1+MAX(ID) FROM (SELECT ID FROM Messages) AS x) - %d";

char sql_messages_insert[] = "\
INSERT INTO Messages (Type, Source, Arg1, Arg2, Arg3, Arg4) \
	VALUES ('%s', '%s', '%s', '%s', '%s', '%s')";

char sql_messages_get[] = "\
SELECT Type, Arg1, Arg2, Arg3, Arg4 \
	FROM Messages \
	WHERE \
	(ID > %d) AND \
	(Source <> '%s')";

char sql_messages_get_loopback[] = "\
SELECT Type, Arg1, Arg2, Arg3, Arg4 \
	FROM Messages \
	WHERE \
	(ID > %d)";

void DB_SetupDatabase()
{
	char error[255];
	gH_DB = SQL_Connect("loafofbread", true, error, sizeof(error));
	if (gH_DB == null)
	{
		SetFailState("Database connection failed. Error: \"%s\".", error);
	}

	DB_CreateTables();
}

void DB_CreateTables()
{
	Transaction txn = SQL_CreateTransaction();

	txn.AddQuery(sql_messages_create);

	// No error logs for this transaction as it will always throw an error
	// if the column already exists, which is more annoying than helpful.
	SQL_ExecuteTransaction(gH_DB, txn, _, _, _, DBPrio_High);
}

void DB_ResetLastMessageID()
{
	Transaction txn = SQL_CreateTransaction();

	txn.AddQuery(sql_messages_gethighestid);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_ResetLastMessageID, DB_TxnFailure_Generic, _, DBPrio_High);
}

void DB_QueryMessages()
{
	static char query[512];

	Transaction txn = SQL_CreateTransaction();

	if (!gCV_lob_message_loopback.BoolValue)
	{
		gH_DB.Format(query, sizeof(query), sql_messages_get, gI_LastMessageID, gC_Source);
	}
	else
	{
		gH_DB.Format(query, sizeof(query), sql_messages_get_loopback, gI_LastMessageID);
	}
	txn.AddQuery(query);

	gH_DB.Format(query, sizeof(query), sql_messages_deleteolderthan, 100);
	txn.AddQuery(query);

	txn.AddQuery(sql_messages_gethighestid);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_QueryMessages, DB_TxnFailure_QueryMessages, _, DBPrio_High);
}

void DB_PostMessage(const char[] type, const char[] arg1, const char[] arg2, const char[] arg3, const char[] arg4)
{
	static char query[4096];

	Transaction txn = SQL_CreateTransaction();

	gH_DB.Format(query, sizeof(query), sql_messages_insert, type, gC_Source, arg1, arg2, arg3, arg4);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_Normal);
}

public void DB_TxnSuccess_ResetLastMessageID(Database db, DataPack data, int numQueries, DBResultSet[] results, any[] queryData)
{
	if (!results[0].FetchRow())
	{
		LogError("DB_TxnSuccess_ResetLastMessageID couldn't fetch row (unexpected)");
		return;
	}

	gI_LastMessageID = results[0].FetchInt(0);
	gB_LockQueryMessages = false;
}

public void DB_TxnSuccess_QueryMessages(Database db, DataPack data, int numQueries, DBResultSet[] results, any[] queryData)
{
	static char type[32];
	static char args[4][256];

	gB_LockQueryMessages = false;

	if (!results[2].FetchRow())
	{
		LogError("DB_TxnSuccess_QueryMessages couldn't fetch row (unexpected)");
		return;
	}

	gI_LastMessageID = results[2].FetchInt(0);

	while (results[0].FetchRow())
	{
		results[0].FetchString(0, type, sizeof(type));

		results[0].FetchString(1, args[0], sizeof(args[]));
		results[0].FetchString(2, args[1], sizeof(args[]));
		results[0].FetchString(3, args[2], sizeof(args[]));
		results[0].FetchString(4, args[3], sizeof(args[]));

		Call_OnMessageReceived(type, args[0], args[1], args[2], args[3]);
	}
}

public void DB_TxnFailure_QueryMessages(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	gB_LockQueryMessages = false;

	LogError("Database transaction error: %s", error);
}

public void DB_TxnFailure_Generic(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("Database transaction error: %s", error);
}
