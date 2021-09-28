#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>


static MRESReturn Detour_PreventBunnyJumping(Address self)
{
    LogMessage("return pbj");
    return MRES_Supercede;
    // return MRES_Ignored;
}

