#define PLUGIN_NAME           "projectile trails"
#define PLUGIN_AUTHOR         "Ciallo"
#define PLUGIN_DESCRIPTION    "Trails color for projectile."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            "https://space.bilibili.com/2988883"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_EXTENSIONS

enum
{
	Red,
	Yellow,
	Green,
	Cyan,
	Blue,
	Magenta,
	Max_Colors
};

int Colors[Max_Colors][4] = 
{
	{255, 0, 0, 255}, //red
	{255, 255, 0, 255}, //yellow
	{0, 255, 0, 255}, //green
	{0, 255, 255, 255}, //cyan
	{0, 0, 255, 255}, //blue
	{255, 0, 255, 255} //magenta
};

char gS_ColorsName[][] = 
{
	"None",
	"Red",
	"Yellow",
	"Green",
	"Cyan",
	"Blue",
	"Magenta"
};

int gI_BeamSprite;
int gI_Color[MAXPLAYERS+1][4];
char gS_ColorChoice[MAXPLAYERS+1][16];

Cookie gC_ClientColorChoise;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_trail", Command_Trail, "Open trails menu");
	RegConsoleCmd("sm_trails", Command_Trail, "Open trails menu. Alias of sm_trail");

	gC_ClientColorChoise = new Cookie("GetColorChoice", "Get client's color choice", CookieAccess_Protected);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	if(!IsValidClient(client))
	{
		return;
	}

	char[] sChoiceCookie = new char[16];
	gC_ClientColorChoise.Get(client, sChoiceCookie, 16);

	if(sChoiceCookie[0] == '\0')
	{
		gC_ClientColorChoise.Set(client, "None");
		strcopy(gS_ColorChoice[client], 16, "None");
	}

	else
	{
		InsertColor(gI_Color[client], Colors[StringToInt(sChoiceCookie)]);
	}
}

public void OnMapStart()
{
	gI_BeamSprite = PrecacheModel("materials/trails/beam_01.vmt", true);
	
	AddFileToDownloadsTable("materials/trails/beam_01.vmt");
	AddFileToDownloadsTable("materials/trails/beam_01.vtf");
}

public Action Command_Trail(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	OpenTrailsMenu(client);

	return Plugin_Handled;
}

void OpenTrailsMenu(int client)
{
	Menu menu = new Menu(TrailsMenu_Handler);
	menu.SetTitle("Choose your color:\n");

	for(int i = 0; i < sizeof(gS_ColorsName); i++)
	{
		if(StrEqual(gS_ColorChoice[client], gS_ColorsName[i]))
		{
			menu.AddItem(gS_ColorsName[i], gS_ColorsName[i], ITEMDRAW_DISABLED);
			continue;
		}

		menu.AddItem(gS_ColorsName[i], gS_ColorsName[i]);
	}
	
	menu.Display(client, -1);
}

public int TrailsMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sInfo[16];
		menu.GetItem(param2, sInfo, 16);

		if(StrEqual(sInfo, "None"))
		{
			strcopy(gS_ColorChoice[param1], 16, "None");
			gC_ClientColorChoise.Set(param1, "None");
		}

		else if(StrEqual(sInfo, "Red"))
		{
			InsertColor(gI_Color[param1], Colors[Red]);
			strcopy(gS_ColorChoice[param1], 16, "Red");
			gC_ClientColorChoise.Set(param1, "0");
		}
		
		else if(StrEqual(sInfo, "Yellow"))
		{
			InsertColor(gI_Color[param1], Colors[Yellow]);
			strcopy(gS_ColorChoice[param1], 16, "Yellow");
			gC_ClientColorChoise.Set(param1, "1");
		}

		else if(StrEqual(sInfo, "Green"))
		{
			InsertColor(gI_Color[param1], Colors[Green]);
			strcopy(gS_ColorChoice[param1], 16, "Green");
			gC_ClientColorChoise.Set(param1, "2");
		}

		else if(StrEqual(sInfo, "Cyan"))
		{
			InsertColor(gI_Color[param1], Colors[Cyan]);
			strcopy(gS_ColorChoice[param1], 16, "Cyan");
			gC_ClientColorChoise.Set(param1, "3");
		}
		
		else if(StrEqual(sInfo, "Blue"))
		{
			InsertColor(gI_Color[param1], Colors[Blue]);
			strcopy(gS_ColorChoice[param1], 16, "Blue");
			gC_ClientColorChoise.Set(param1, "4");
		}

		else if(StrEqual(sInfo, "Magenta"))
		{
			InsertColor(gI_Color[param1], Colors[Magenta]);
			strcopy(gS_ColorChoice[param1], 16, "Magenta");
			gC_ClientColorChoise.Set(param1, "5");
		}

		OpenTrailsMenu(param1);
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void InsertColor(int[] array, int[] color)
{
	array[0] = color[0];
	array[1] = color[1];
	array[2] = color[2];
	array[3] = color[3];
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity))
    	{
		if(StrContains(classname, "_projectile", false) != -1)
		{
			SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
		}
	}
}

public void ProjectileSpawned(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if(IsValidClient(client) && !StrEqual(gS_ColorChoice[client], "None"))
	{
		TE_SetupBeamFollow(entity, gI_BeamSprite, 0, 1.0, 3.0, 3.0, 1, gI_Color[client]);
		TE_SendToAll();
	}
}

bool IsValidClient(int client)
{
	return 1 <= client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}
