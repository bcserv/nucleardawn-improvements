
// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <sdkhooks>

#include <smlib>

#define PLUGIN_VERSION "0.1"



/*****************************************************************


		P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Nuclear Dawn Improvements",
	author = "Berni",
	description = "Enhancements, tools & admin commands for Nuclear Dawn",
	version = PLUGIN_VERSION,
	url = "http://www.bcserv.eu"
}



/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:cvar_enableBugfixReload	= INVALID_HANDLE;

// Misc
new bool:enableBugfixReload = true;
new bugfixReload_unsetAttack2[MAXPLAYERS+1] = { false, ... };


/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {

	cvar_enableBugfixReload = CreateConVar("ndi_enable_bugfix_reload", "1", "", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(cvar_enableBugfixReload, ConvarChanged);

	
	HookEvent("weapon_reload", Event_WeaponReload, EventHookMode_Pre);

	LOOP_CLIENTS(client, CLIENTFILTER_INGAME) {
		decl String:weaponName[32];
		GetClientWeapon(client, weaponName, sizeof(weaponName));
		PrintToChat(client, "Weapon: %s", weaponName);
		new weapon = Client_GetWeapon(client, weaponName);
		PrintToChat(client, "weapon: %d", weapon);
		SDKHook(weapon, SDKHook_FireBulletsPost, Client_FireBulletsPost);
	}
}

public OnClientConnected(client)
{
	bugfixReload_unsetAttack2[client] = false;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_FireBulletsPost, Client_FireBulletsPost);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (bugfixReload_unsetAttack2[client]) {
		Client_RemoveButtons(client, IN_ATTACK2);

		return Plugin_Changed;
	}

	return Plugin_Continue;
}



/****************************************************************


		C A L L B A C K   F U N C T I O N S


****************************************************************/

public Event_WeaponReload(Handle:event, const String:name[], bool:broadcast)
{
	if (enableBugfixReload) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		bugfixReload_unsetAttack2[client] = true;
		PrintToChat(client, "\x04[DEBUG] bugfixReload_unsetAttack2 = true");
		CreateTimer(4.0, Timer_BugfixReloadAllowAttack2, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ConvarChanged(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	if (conVar == cvar_enableBugfixReload) {
		enableBugfixReload = bool:StringToInt(newValue);
	}
}

public Action:Timer_BugfixReloadAllowAttack2(Handle:timer, any:userId)
{
	new client = GetClientOfUserId(userId);

	if (client == 0) {
		return Plugin_Stop;
	}

	bugfixReload_unsetAttack2[client] = false;
	PrintToChat(client, "\x04[DEBUG] bugfixReload_unsetAttack2 = false");
	SetEntProp(client, Prop_Send, "m_bInReload", 0, 1);
	SetEntProp(client, Prop_Send, "m_iReloadMode", 0, 1);
	SetEntProp(client, Prop_Send, "m_bReloadedThroughAnimEvent", 0, 1);
	SetEntProp(client, Prop_Send, "m_flReloadPriorNextFire", GetGameTime());

	return Plugin_Stop;
}

public Client_FireBulletsPost(client, shots, const String:weaponname[])
{
	PrintToChat(client, "\x04Fire - shots. %d, weaponname: %s", shots, weaponname);
}



/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/

