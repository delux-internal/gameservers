/**
 * [TF2] Item Persistence
 */
#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>
#include <tf2wearables>
#include <dhooks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
	name = "[TF2] Item Persistence Forward",
	author = "nosoop",
	description = "Provides minimal control over whether items get replaced on resupply.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFPersistItem"
}

Handle g_fwdOnReplaceItem;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("tf_persist_item");
	
	g_fwdOnReplaceItem = CreateGlobalForward("TF2_OnReplaceItem", ET_Hook, Param_Cell,
			Param_Cell);
}

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.persist_item");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.persist_item).");
	}
	
	// y'know, I'm not 100% sure this is sane
	Handle dtGetLoadoutItem = DHookCreateFromConf(hGameConf, "CTFPlayer::GetLoadoutItem()");
	DHookEnableDetour(dtGetLoadoutItem, true, OnGetLoadoutItemPost);
	
	delete hGameConf;
}

public MRESReturn OnGetLoadoutItemPost(int client, Handle hReturn, Handle hParams) {
	TFClassType playerClass = DHookGetParam(hParams, 1);
	int loadoutSlot = DHookGetParam(hParams, 2);
	
	if (playerClass != TF2_GetPlayerClass(client)) {
		return MRES_Ignored;
	}
	
	if (loadoutSlot < 0) {
		return MRES_Ignored;
	}
	
	int item = TF2_GetPlayerLoadoutSlot(client, loadoutSlot);
	if (!IsValidEntity(item)) {
		// may be killed if not valid for class??
		return MRES_Ignored;
	}
	
	Action result;
	
	Call_StartForward(g_fwdOnReplaceItem);
	Call_PushCell(client);
	Call_PushCell(item);
	Call_Finish(result);
	
	if (result < Plugin_Handled) {
		return MRES_Ignored;
	}
	
	Address itemView = TF2_GetEconItemView(item);
	DHookSetReturn(hReturn, itemView);
	return MRES_Supercede;
}

/**
 * Returns a pointer to an item entity's `CEconItemView`.
 */
Address TF2_GetEconItemView(int item) {
	if (!IsValidEntity(item) || !HasEntProp(item, Prop_Send, "m_Item")) {
		// we should probably throw an error here
		return Address_Null;
	}
	return GetEntityAddress(item) + view_as<Address>(GetEntSendPropOffs(item, "m_Item", true));
}

// forward concepts
// Action TF2_ShouldPersistItem(int client, int item, bool &persist);
// Action TF2_OnReplaceItem(int client, int item);