#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Creators.TF Team"
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

char CITADEL_MODEL  [96]    = "models/props_combine/combine_citadel_animated.mdl";
char MVM_MODEL      [96]    = "models/bots/boss_bot/carrier.mdl";

public Plugin myinfo =
{
    name        = "Skybox Prop Spawner",
    author      = PLUGIN_AUTHOR,
    description = "Spawns Props in Map's Skyboxes",
    version     = PLUGIN_VERSION,
    url         = "https://creators.tf"
};

public void OnPluginStart()
{
    HookEvent("teamplay_round_start", evRoundStart);
    RegAdminCmd("sm_skyprop_test", sm_skyprop_test, ADMFLAG_GENERIC);
}

// todo: traceray this so clients can do @aim
public Action sm_skyprop_test(int client, int args)
{
    int iProp = -1;
    while ((iProp = FindEntityByClassname(iProp, "prop_dynamic")) != -1)
    {
        char tName[16];
        GetEntPropString(iProp, Prop_Data, "m_iName", tName, 16);
        if (StrEqual(tName, "tf_skyprop"))
        {
            RemoveEntity(iProp);
        }
    }

    float flRotation = 0.0;
    float flScale = 0.1;

    char sBuff[11];
    GetCmdArg(1, sBuff, sizeof(sBuff));
    flRotation = StringToFloat(sBuff);
    GetCmdArg(2, sBuff, sizeof(sBuff));
    flScale = StringToFloat(sBuff);

    char model[96];
    GetCmdArg(3, model, sizeof(model));

    if (StrEqual("1", model))
    {
        strcopy(model, sizeof(model), CITADEL_MODEL);
    }
    else if (StrEqual("2", model))
    {
        strcopy(model, sizeof(model), MVM_MODEL);
    }

    if (flScale < 0.1)
    {
        flScale = 0.1;
    }

    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));
    if (StrContains(sMap, "workshop") != -1)
    {
        GetMapDisplayName(sMap, sMap, sizeof sMap);
    }

    float flPos[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", flPos);
    // ?????
    PrintToConsole(client, "\"%s\"\n{\n     \"x\" \"%f\"\n  \"y\" \"%f\"\n  \"z\" \"%f\"\n  \"r\" \"%f\"\n  \"s\" \"%f\"\n}", sMap, flPos[0], flPos[1], flPos[2], flRotation, flScale);
    Prop_Create(flPos, flRotation, flScale, model);
}

bool shouldSpawnCitadel = false;
bool shouldSpawnCarrier = false;

public void OnMapStart()
{
    PrecacheModel(MVM_MODEL);
    PrecacheModel(CITADEL_MODEL);

    shouldSpawnCitadel = false;
    shouldSpawnCarrier = false;
    int rand =  GetRandomInt(1, 3);
    // B4DC0DE
    if (rand == 1)
    {
        shouldSpawnCitadel = true;
        shouldSpawnCarrier = false;
    }
    else if (rand == 2)
    {
        shouldSpawnCitadel = false;
        shouldSpawnCarrier = true;
    }
}

public Action evRoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    char type[16];
    char model[64];

    if (shouldSpawnCitadel || shouldSpawnCarrier)
    {
        LogMessage("Should spawn something");
        if (shouldSpawnCitadel)
        {
            LogMessage("should spawn citadel");
            type = "citadel";
            strcopy(model, sizeof(model), CITADEL_MODEL);
        }
        else if (shouldSpawnCarrier)
        {
            LogMessage("should spawn carrier");
            type = "carrier";
            strcopy(model, sizeof(model), MVM_MODEL);
        }
        char sLoc[96];
        BuildPath(Path_SM, sLoc, sizeof(sLoc), "configs/skybox_props_%s.cfg", type);
        LogMessage("sloc = %s", sLoc);
        KeyValues kv = new KeyValues("Props");
        kv.ImportFromFile(sLoc);



        char sMap[96];
        char realMap[96];
        GetCurrentMap(sMap, sizeof(sMap));
        GetMapDisplayName(sMap, realMap, sizeof(realMap));


        LogMessage("sMap %s = realMap %s", sMap, realMap);

        if (kv.JumpToKey(realMap))
        {
            float flPos[3];
            float flScale   = kv.GetFloat("s", 0.1);
            flPos[0]        = kv.GetFloat("x", 0.0);
            flPos[1]        = kv.GetFloat("y", 0.0);
            flPos[2]        = kv.GetFloat("z", 0.0);
            float flRotate  = kv.GetFloat("r", 0.0);

            LogMessage("model = %s", model);
            Prop_Create(flPos, flScale, flRotate, model);
        }
        delete kv;
    }
}

public void Prop_Create(float flPos[3], float flScale, float flRotate, char[] model)
{
    int prop_ent;
    prop_ent = CreateEntityByName("prop_dynamic_override");
    if  (prop_ent > 0)
    {
        float flAng[3];
        flAng[1] = flRotate;
        TeleportEntity  (prop_ent, flPos, flAng, NULL_VECTOR);
        SetEntityModel  (prop_ent, model);
        SetEntPropFloat (prop_ent, Prop_Send, "m_flModelScale", flScale);
        DispatchKeyValue(prop_ent, "targetname", "tf_skyprop");
        DispatchSpawn   (prop_ent);
        ActivateEntity  (prop_ent);
    }
}

