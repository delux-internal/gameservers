#include <sourcemod>
#include <regex>


public void GetPrettyMapName(const char[] map, char[] prettymap, int size)
{
    // copy our mapname into our prettymapname
    strcopy(prettymap, size, map);

    // re/init our regex
    Regex normalizeMapNameRegex = null;
    normalizeMapNameRegex       = CompileRegex("(_(a|b|beta|u|r|v|rc|f|final|comptf|ugc)?[0-9]*[a-z]?$)|([0-9]+[a-z]?$)", 0);

    if (normalizeMapNameRegex == null)
    {
        ThrowError("[prettymap] Couldn't compile regex!");
        return;
    }

    // our match goes in here
    char match[128];

    // get the num of captures for this string
    int caps = MatchRegex(normalizeMapNameRegex, prettymap);
    // if we have 1 or more captures
    if (caps > 0)
    {
        // if we find a substring
        if (GetRegexSubString(normalizeMapNameRegex, 0, match, sizeof(match)))
        {
            LogMessage("match %s", match);
            // hack for refresh maps
            if (StrContains(match, "_f", false) != -1 && StrContains(match, "_final", false) == -1)
            {
                ReplaceString(prettymap, size, match, " refresh", true);
            }
            else
            {
                ReplaceString(prettymap, size, match, "", true);
            }
        }
    }

    //capitalize gamemode prefixes
    ReplaceString(prettymap, size, "cp_", "CP_");
    ReplaceString(prettymap, size, "pl_", "PL_");
    ReplaceString(prettymap, size, "plr_", "PLR_");
    ReplaceString(prettymap, size, "ctf_", "CTF_");
    ReplaceString(prettymap, size, "koth_", "KOTH_");
    ReplaceString(prettymap, size, "arena_", "Arena_");
    ReplaceString(prettymap, size, "pd_", "PD_");
    ReplaceString(prettymap, size, "sd_", "SD_");
    ReplaceString(prettymap, size, "tc_", "TC_");
    ReplaceString(prettymap, size, "rd_", "RD_");

    //upper case the first letter of the name
    bool upper = false;
    for (int i = 0; i < strlen(prettymap); i++)
    {
        if (upper)
        {
            prettymap[i] = CharToUpper(prettymap[i]);
            upper = false;
        }
        else if (prettymap[i] == '_' || IsCharNumeric(prettymap[i])) upper = true;
    }

    // remove underlines and replace with spaces
    ReplaceString(prettymap, size, "_", " ", true);

    LogMessage("Prettymap %s.", prettymap);
}
