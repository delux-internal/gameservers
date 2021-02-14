#pragma semicolon 1
#pragma newdecls required

#include <cecon_items>
#include <sdktools>

public Plugin myinfo =
{
	name = "Give Creators.TF Item",
	author = "Creators.TF Team",
	description = "Gives Creators.TF Item",
	version = "1.00",
	url = "https://creators.tf"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_jetpack", cGive, "Gives a jetpack");
	HookEvent("post_inventory_application", post_inventory_application);
}

public Action cGive(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] Doesn't work in the console.");
		return Plugin_Handled;
	}
		
	CEItem xItem;
	if(CEconItems_CreateNamedItem(xItem, "Space Jumper", 6, null))
	{
		CEconItems_GiveItemToClient(client, xItem);
		ReplyToCommand(client, "[SM] Given Jetpack to you");
	}
	
	return Plugin_Handled;
}

public Action post_inventory_application(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	RequestFrame(RF_LoadoutApplication, client);
}

public void GiveJetpack(int client)
{
	CEItem xItem;
	if(CEconItems_CreateNamedItem(xItem, "Space Jumper", 6, null))
	{
		CEconItems_GiveItemToClient(client, xItem);
		PrintToChat(client, "[SM] Given Jetpack to you");
		PrintToServer("[SM] Given Jetpack to %N", client);
	}
}

public void RF_LoadoutApplication(int client)
{
	GiveJetpack(client);
}