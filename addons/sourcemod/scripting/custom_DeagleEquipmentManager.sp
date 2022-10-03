// List of Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

// The code formatting rules we wish to follow
#pragma semicolon 1;
#pragma newdecls required;


// The retrievable information about the plugin itself 
public Plugin myinfo =
{
	name		= "[CS:GO] Deagle Equipment Manager",
	author		= "Manifest @Road To Glory",
	description	= "Changes the player's equipment to align with aim deagle gameplay.",
	version		= "V. 1.0.0 [Beta]",
	url			= ""
};



//////////////////////////
// - Global Variables - //
//////////////////////////

int WeaponHasOwner;


//////////////////////////
// - Forwards & Hooks - //
//////////////////////////


// This happens when the plugin is loaded
public void OnPluginStart()
{
	WeaponHasOwner = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	// Hooks the events we intend to use
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	// Allows the modification to be loaded while the server is running, without giving gameplay issues
	LateLoadSupport();
}


// This happens after a playr has had their admin flags checked
public void OnClientPostAdminCheck(int client)
{
	// If the client meets our validation criteria then execute this section
	if(IsValidClient(client))
	{
		// Hooks the WeaponCanUse function to check when the player is eligible to pick up a weapon
		SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);

	}
}


// This happens when a player can pick up a weapon
public Action Hook_WeaponCanUse(int client, int weapon)
{
	// If the weapon that was picked up our entity criteria of validation then execute this section
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	// Creates a variable called ClassName which we will store the weapon entity's name within
	char ClassName[64];

	// Obtains the classname of the weapon entity and store it within our ClassName variable
	GetEntityClassname(weapon, ClassName, sizeof(ClassName));

	// If the weapon's entity name is the same as weapon_knife then execute this section
	if(StrEqual(ClassName, "weapon_knife", false))
	{
		return Plugin_Continue;
	}

	// If the weapon's entity name is the same as weapon_knife then execute this section
	if(StrEqual(ClassName, "weapon_deagle", false))
	{
		return Plugin_Continue;
	}

	// If the weapon's entity name is the same as weapon_knife then execute this section
	if(StrEqual(ClassName, "weapon_hegrenade", false))
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}


////////////////
// - Events - //
////////////////


// This happens when a player spawns
public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// Removes all the weapons from the client
	RemoveAllWeapons(client);

	// Gives the player some waepons aftr 0.5 seconds has passed
	CreateTimer(0.5, Timer_GiveWeapons, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}


// This happens when a player death
public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	// removes all weapons that are currently lying on the ground
	RemoveAllDroppedWeapons();

	return Plugin_Continue;
}


// This happens when a new round starts
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Removes all of the c4 bombs from the map
	RemoveEntityC4();

	// Removes all of the bombsites from the map
	RemoveEntityBombSite();

	// Removes all of the hostages from the map
	RemoveEntityHostage();

	// Removes all of the rescue zones from the map
	RemoveEntityHostageRescue();

	// Removes all of the buy zones from the map
	RemoveEntityBuyzones();

	// Removes all of the game player equips from the map
	RemoveGamePlayerEquip();

	// removes all weapons that are currently lying on the ground
	RemoveAllDroppedWeapons();
}



///////////////////////////
// - Regular Functions - //
///////////////////////////


// This happens when a player dies or a new round starts
public Action RemoveAllDroppedWeapons()
{
	char ClassName[64];

	for (int entity = MaxClients; entity < 2049; entity++)
	{
		if(!IsValidEdict(entity))
		{
			continue;
		}

		if(!IsValidEntity(entity))
		{
			continue;
		}

		if(GetEntDataEnt2(entity, WeaponHasOwner) != -1)
		{
			continue;
		}

		GetEdictClassname(entity, ClassName, sizeof(ClassName));

		if((StrContains(ClassName, "weapon_") != -1 || StrContains(ClassName, "item_") != -1))
		{
			if(StrEqual(ClassName, "weapon_hegrenade", false))
			{
				continue;
			}

			if(StrEqual(ClassName, "weapon_deagle", false))
			{
				continue;
			}

			if(StrEqual(ClassName, "weapon_knife", false))
			{
				continue;
			}

			RemoveEdict(entity);
		}
	}

	return Plugin_Continue;
}



// This happens when the modification is being loaded
public Action LateLoadSupport()
{
	// Loops through all of the clients
	for (int client = 1; client <= MaxClients; client++)
	{
		// If the client does not meet our validation criteria then execute this section
		if(!IsValidClient(client))
		{
			continue;
		}

		// Hooks the WeaponCanUse function to check when the player is eligible to pick up a weapon
		SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	}

	return Plugin_Continue;
}


// This happens when all players are stripped of their weapons
public void RemoveAllWeapons(int client)
{
	for(int loop3 = 0; loop3 < 4 ; loop3++)
	{
		for(int WeaponNumber = 0; WeaponNumber < 24; WeaponNumber++)
		{
			int WeaponSlotNumber = GetPlayerWeaponSlot(client, WeaponNumber);

			if (WeaponSlotNumber != -1)
			{
				if (IsValidEdict(WeaponSlotNumber) && IsValidEntity(WeaponSlotNumber))
				{
					RemovePlayerItem(client, WeaponSlotNumber);

					AcceptEntityInput(WeaponSlotNumber, "Kill");
				}
			}
		}
	}
}


// This happens shortly after a player spawns
public void GivePlayerCreatedItem(int client, const char[] WeaponName)
{
	int WeaponEntity = CreateEntityByName(WeaponName);

	if(IsValidEntity(WeaponEntity))
	{
		float PlayerLocation[3];

		GetClientAbsOrigin(client, PlayerLocation);

		DispatchSpawn(WeaponEntity);

		TeleportEntity(WeaponEntity, PlayerLocation, NULL_VECTOR, NULL_VECTOR);
	}
}


// This happens when a new round starts 
public void RemoveEntityC4()
{
	// Creates an integer named entity and sets it to INVALID_ENT_REFERENCE;
	int entity = INVALID_ENT_REFERENCE;
	
	// Loops through all of the entities and tries to find any matching the specified criteria
	while ((entity = FindEntityByClassname(entity, "weapon_c4")) != INVALID_ENT_REFERENCE)
	{
		// If the entity meets the criteria of validation then execute this section
		if(IsValidEntity(entity))
		{
			// Kills the entity, removing it from the game
			AcceptEntityInput(entity, "Kill");
		}
	}
}


// This happens when a new round starts 
public void RemoveEntityBombSite()
{
	// Creates an integer named entity and sets it to INVALID_ENT_REFERENCE;
	int entity = INVALID_ENT_REFERENCE;
	
	// Loops through all of the entities and tries to find any matching the specified criteria
	while ((entity = FindEntityByClassname(entity, "func_bomb_target")) != INVALID_ENT_REFERENCE)
	{
		// If the entity meets the criteria of validation then execute this section
		if(IsValidEntity(entity))
		{
			// Kills the entity, removing it from the game
			AcceptEntityInput(entity, "Kill");
		}
	}
}


// This happens when a new round starts 
public void RemoveEntityHostage()
{
	// Creates an integer named entity and sets it to INVALID_ENT_REFERENCE;
	int entity = INVALID_ENT_REFERENCE;
	
	// Loops through all of the entities and tries to find any matching the specified criteria
	while ((entity = FindEntityByClassname(entity, "hostage_entity")) != INVALID_ENT_REFERENCE)
	{
		// If the entity meets the criteria of validation then execute this section
		if(IsValidEntity(entity))
		{
			// Kills the entity, removing it from the game
			AcceptEntityInput(entity, "Kill");
		}
	}
}


// This happens when a new round starts 
public void RemoveEntityHostageRescue()
{
	// Creates an integer named entity and sets it to INVALID_ENT_REFERENCE;
	int entity = INVALID_ENT_REFERENCE;
	
	// Loops through all of the entities and tries to find any matching the specified criteria
	while ((entity = FindEntityByClassname(entity, "func_hostage_rescue")) != INVALID_ENT_REFERENCE)
	{
		// If the entity meets the criteria of validation then execute this section
		if(IsValidEntity(entity))
		{
			// Kills the entity, removing it from the game
			AcceptEntityInput(entity, "Kill");
		}
	}
}


// This happens when a new round starts 
public void RemoveEntityBuyzones()
{
	// Creates an integer named entity and sets it to INVALID_ENT_REFERENCE;
	int entity = INVALID_ENT_REFERENCE;
	
	// Loops through all of the entities and tries to find any matching the specified criteria
	while ((entity = FindEntityByClassname(entity, "func_buyzone")) != INVALID_ENT_REFERENCE)
	{
		// If the entity meets the criteria of validation then execute this section
		if(IsValidEntity(entity))
		{
			// Kills the entity, removing it from the game
			AcceptEntityInput(entity, "Kill");
		}
	}
}


// This happens when a new round starts 
public void RemoveGamePlayerEquip()
{
	// Creates an integer named entity and sets it to INVALID_ENT_REFERENCE;
	int entity = INVALID_ENT_REFERENCE;
	
	// Loops through all of the entities and tries to find any matching the specified criteria
	while ((entity = FindEntityByClassname(entity, "game_player_equip")) != INVALID_ENT_REFERENCE)
	{
		// If the entity meets the criteria of validation then execute this section
		if(IsValidEntity(entity))
		{
			// Kills the entity, removing it from the game
			AcceptEntityInput(entity, "Kill");
		}
	}
}



///////////////////////////////
// - Timer Based Functions - //
///////////////////////////////


public Action Timer_GiveWeapons(Handle timer, int client)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	GivePlayerItem(client, "weapon_knife");

	GivePlayerCreatedItem(client, "weapon_deagle");


	return Plugin_Continue;
}



////////////////////////////////
// - Return Based Functions - //
////////////////////////////////


// Returns true if the client meets the validation criteria. elsewise returns false
public bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}

	return true;
}

