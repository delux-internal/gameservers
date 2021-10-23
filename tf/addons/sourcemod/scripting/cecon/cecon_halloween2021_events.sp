#pragma semicolon 1
#pragma newdecls required

#include <cecon>
#include <cecon_items>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define TF_BUILDING_SAPPER 3

public Plugin myinfo =
{
	name = "Creators.TF Economy - Halloween 2021 Events",
	author = "Creators.TF Team (ZoNiCaL)",
	description = "Creators.TF Halloween 2021 Events",
	version = "1.0",
	url = "https://creators.tf"
}

/*
ZoNiCaL here! Let me quickly explain this plugin!

This plugin was made to track *very specific* stuff for certain contracts that
were released for the Halloween 2021 update for Creators.TF. Contracts currently
don't support having cosmetic restrictions, so some events have been modified
to check if a player has X cosmetic and if so, fire a special event.

This plugin is only meant to be active for the duration of the event. Move to
/disabled otherwise!

Thanks :)
*/

public void OnPluginStart()
{
	// Misc Events
	HookEvent("environmental_death", environmental_death);
	HookEvent("teamplay_win_panel", evTeamplayWinPanel);

	// Object Events
	HookEvent("object_destroyed", object_destroyed);

	// Player Events
	HookEvent("player_death", player_death);

}

public Action player_death(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int death_flags = GetEventInt(hEvent, "death_flags");

	if (!IsClientValid(client)) return Plugin_Continue;
	if (!IsClientValid(attacker)) return Plugin_Continue;

	// Item related events.
	int attackerItemCount = CEconItems_GetClientWearedItemsCount(attacker);
	for (int i = 0; i < attackerItemCount; i++)
	{
		// Grab item.
		CEItem xItem;
		CEconItems_GetClientWearedItemByIndex(attacker, i, xItem);
		
		// Does this item have "holiday restricted" set to 3?
		if (CEconItems_GetAttributeIntegerFromArray(xItem.m_Attributes, "holiday restricted") == 3)
		{
			CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_RESTRICTED_KILL", 1, hEvent);
		}
		
		// Is this item...
		switch (xItem.m_iItemDefinitionIndex)
		{
			case 185: {
				// Send basic kill event.
				CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_BODYBUILDER_KILL", 1, hEvent);
				
				// Are we dominating with this kill?
				if(death_flags & TF_DEATHFLAG_KILLERDOMINATION)
					CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_BODYBUILDER_DOMINATE", 1, hEvent);
			}
			case 190: CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_MOLTENMONITOR_KILL", 1, hEvent);
		}
	}
	
	return Plugin_Continue;
}

public Action player_hurt(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int damage = GetEventInt(hEvent, "damageamount");
	int custom = GetEventInt(hEvent, "custom");
	bool crit = GetEventBool(hEvent, "crit");
	bool mini = GetEventBool(hEvent, "minicrit");

	if(IsClientValid(attacker) && attacker != client)
	{
		// Item related events..
		int playerItemCount = CEconItems_GetClientWearedItemsCount(attacker);
		for (int i = 0; i < playerItemCount; i++)
		{
			// Grab item.
			CEItem xItem;
			CEconItems_GetClientWearedItemByIndex(attacker, i, xItem);
			
			// Custom damage types.
			if (custom & DMG_BURN)
			{
				// Is this item...
				switch (xItem.m_iItemDefinitionIndex)
				{
					case 186: CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_FIRE_AQUANAUT", damage, hEvent);
				}
			}
			
			// Are we critting or mini-critting?
			if (crit || mini)
			{
				switch (xItem.m_iItemDefinitionIndex)
				{
					case 186: CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_CRITS_AQUANAUT", damage, hEvent);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action object_destroyed(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int objecttype = GetEventInt(hEvent, "objecttype");

	if(IsClientValid(attacker) && attacker != client)
	{
		// Is this a sapper?
		if (objecttype == TF_BUILDING_SAPPER)
		{
			// Item related events.
			int playerItemCount = CEconItems_GetClientWearedItemsCount(attacker);
			for (int i = 0; i < playerItemCount; i++)
			{
				// Grab item.
				CEItem xItem;
				CEconItems_GetClientWearedItemByIndex(attacker, i, xItem);
				
				// Is this item...
				switch (xItem.m_iItemDefinitionIndex)
				{
					case 185: CEcon_SendEventToClientFromGameEvent(attacker, "CREATORS_HALLOWEEN_BODYBUILDER_SAPPER", 1, hEvent);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action environmental_death(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int killer = GetEventInt(hEvent, "killer");
	int victim = GetEventInt(hEvent, "victim");

	if(IsClientValid(killer) && killer != victim)
	{
		// Item related events.
		int playerItemCount = CEconItems_GetClientWearedItemsCount(killer);
		for (int i = 0; i < playerItemCount; i++)
		{
			// Grab item.
			CEItem xItem;
			CEconItems_GetClientWearedItemByIndex(killer, i, xItem);
			
			// Is this item...
			switch (xItem.m_iItemDefinitionIndex)
			{
				case 190: CEcon_SendEventToClientFromGameEvent(killer, "CREATORS_HALLOWEEN_MOLTENMONITOR_EJECT", 1, hEvent);
			}
		}
	}

	return Plugin_Continue;
}

public Action evTeamplayWinPanel(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int players[3];
	players[0] = GetEventInt(hEvent, "player_1");
	players[1] = GetEventInt(hEvent, "player_2");
	players[2] = GetEventInt(hEvent, "player_3");

	for (int p = 0; p < 3; p++)
	{
		int player = players[p];
		if (!IsClientValid(player)) continue;
		
		// Item related events.
		int playerItemCount = CEconItems_GetClientWearedItemsCount(player);
		for (int i = 0; i < playerItemCount; i++)
		{
			// Grab item.
			CEItem xItem;
			CEconItems_GetClientWearedItemByIndex(player, i, xItem);
			
			// Is this item...
			switch (xItem.m_iItemDefinitionIndex)
			{
				case 190: CEcon_SendEventToClientFromGameEvent(player, "CREATORS_HALLOWEEN_MOLTENMONITOR_MVP", 1, hEvent);
			}
		}
	}
	

	return Plugin_Continue;
}

public bool IsClientValid(int client)
{
	if (client <= 0 || client > MaxClients)return false;
	if (!IsClientInGame(client))return false;
	if (!IsClientAuthorized(client))return false;
	return true;
}

public bool IsClientReady(int client)
{
	if (!IsClientValid(client))return false;
	if (IsFakeClient(client))return false;
	return true;
}