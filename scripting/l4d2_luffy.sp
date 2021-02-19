#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required
#include <l4d2_luffy_stock.sp>

#define PLUGIN_NAME			"l4d2_luffy"
#define PLUGIN_VERSION		"0.9.1"
/*
v0.9.1
	  - corrected dummy and skin flipped.
	  - shield and rocket body part now use entity ref instead of index for lookup.
	  - old l4d2 default model included in. some commented out because its extras.
	  - entity rotation moved into the timer itself. for human readability. i make your life easy.
	  - fixed pickup animation scale problem.
	  - added cvar to enable/disable ammobox tweak to give flexibility to use other ammobox plugin.
	  - new cvar homing missile number
	  - new cvar homing missile damage
	  - new cvar shield damage
	  - cvar tank damage no longer tie to missile damage. its now saperated.
	  - new cvar health amount we steal during strength ability active when killing infected, tank or witch.
	  - fixed the life steal amount dosent subtract health and health buff properly.
	  - sheld ability timer merge into single timer.
	  - clock ability merged into single timer.
	  - homing missile targeting system updated. it now can bypass entity already in target list.
	  - added admin command to spawn model for debugging only.
	  - added admin command to reload map for debugging/refresh all plugins only.
	  - new cvar is homing missile allowed to target survivor if it idle( no damage done, its in cvar.. just for fun ).
	  - shield radius is now also the shield damage radius. probably cvar? but that dont make any sense to me.
	  -	added reset client if the player died
	  - Freeze/Unfreeze and player ability no longer interfere each other.
	  - new cvar animate healthbar from using medkit on/off.
	  - new cvar allow countdown hint message. this message kinda annoying.
	  - removed sprite follow player.
	  - beam sprite now hardcoded and changed to dorm looking type, old one annoying.
	  - new cvar allow witch drop luffy item.
	  - fixed the shield wont remove from world. << i forgot this guy was parented to player.
	  - updated bunce of varible poorly named and left bunch more. << i m out of sexy name. this rised my OCD level. no longer care :(
	  - removed the witch and common infected health check. this will crash the server.
	  - reinvented color system.. << now simplified and hardcoded.
	  - re-invented the model selection dice and ammobox dice. roll the dice ahead of time << we should have gained a small preformance improvement if i didnt re-invent new bug.
	  - new cvar missile allow golowing.
	  - added check for health animation will stop on ledge grab and continue after ledge revive succsess( untested ).
	  - added timer to remove the ammobox from world if no player pickup. Dont flood our server.
	  - added dash for the strength ability to make it less useless.
	  -	tried to address the issue where player get black screen death animation loop during shield active. << not much i can do other than make those player almost in god mode.
	  - added bool check for round end and force everything to terminate themself. hopefuly. this plugins grow even larger for me to stress test it on my own.
	  - i v decided there will be no wall check in between explosion and the target. we are done with the plugins size.
	  - no wall check between player shield and the target either. if you woke the witch next room on a narrow path, deal with it and good luck.
	  - re-invent the missile shooting function to easyly manipulate the desired direction and reuseablity.
	  - invented new function PCMasterRace_Render_ARGB() at 4K @260 fps for homing missile and airstrike. That right, you read that correctly, except the 4k things if your GC low end. :)
	  - reinvent the trace ray function for re-useability. useful to check wall and/or obstacle between 2 points in the future( if i change my mind somehow)
	  - 
	  - 
*/

///////////////// this is l4d2 ingame vanila model ////////////////
#define MDL_CLOCK			"models/props_fairgrounds/giraffe.mdl"
#define MDL_SPEED			"models/editor/air_node_hint.mdl"
#define MDL_POISON			"models/props_collectables/flower.mdl"
#define MDL_REGENHP			"models/props_collectables/mushrooms.mdl"
#define MDL_SHIELD			"models/props_fairgrounds/alligator.mdl"
#define MDL_STRENGTH		"models/props_fairgrounds/elephant.mdl"
#define MDL_GIFT			"models/items/l4d_gift.mdl"

//////////// this is custom model from the luffy_item.vpk ///////////
#define MDL2_CLOCK			"models/player/slow/amberlyn/sm_galaxy/star/slow.mdl"
#define MDL2_SPEED			"models/player/slow/amberlyn/sm_galaxy/star/slow_2.mdl"
#define MDL2_POISON			"models/player/slow/amberlyn/sm_galaxy/goomba/slow.mdl"
#define MDL2_REGENHP		"models/player/slow/amberlyn/sm_galaxy/life_mushroom/slow.mdl"
#define MDL2_SHIELD			"models/player/slow/amberlyn/sm_galaxy/koopa_troopa/slow.mdl"	//<< this guys wont scale
#define MDL2_STRENGTH		"models/props_fairgrounds/elephant.mdl"				//<< custom model except this one. i lost my chain chomp model :(
#define MDL2_GIFT			"models/player/slow/amberlyn/sm_galaxy/luma/slow.mdl"

/////////////////////////////////////////////////////////////
// incase you miss the old default l4d2 model .. its here. //
// replace file path from below to the #define l4d2 above. //
/////////////////////////////////////////////////////////////
// "models/editor/axis_helper_thick.mdl"
// "models/editor/air_node_hint.mdl"
// "models/editor/air_node.mdl"
// "models/editor/overlay_helper.mdl"
// "models/props_unique/airport/atlas_break_ball.mdl"
////////////////////////////////////////////////////////////

// dont replace this model below. its a default model.
#define MDL_JETF18				"models/f18/f18.mdl"							//<< the mother of all weapon + shield decoration. << dont change.
#define MDL_HOMING				"models/props_fairgrounds/mr_mustachio.mdl"		//<< this for homing missile base << you may change this, not critical.
#define	DMY_SDKHOOK				"models/props_fairgrounds/mr_mustachio.mdl"		//<< this for sdkhook dummy touch detection, wont visible ingame. << dont change this.

#define MDL_AMMO				"models/props/terror/ammo_stack.mdl"
#define MDL_RIOTSHIELD			"models/weapons/melee/w_riotshield.mdl"			// ability shield decoration model << i fall in love with this guy

#define SND_REWARD				"level/gnomeftw.wav"
#define SND_HEALTH				"ui/bigreward.wav"
#define SND_SPEED				"ui/pickup_guitarriff10.wav"
#define SND_CLOCK				"level/startwam.wav"
#define SND_STRENGTH			"ui/critical_event_1.wav"
#define SND_SUPERSHIELD			"ambient/alarms/klaxon1.wav"
#define SND_TIMEOUT				"ambient/machines/steam_release_2.wav"
#define SND_TELEPORT			"ui/menu_horror01.wav"
#define SND_ZAP_1				"ambient/energy/zap1.wav"
#define SND_ZAP_2				"ambient/energy/zap3.wav"
#define SND_ZAP_3				"ambient/energy/spark5.wav"
#define SND_FREEZE				"physics/glass/glass_impact_bullet4.wav"
#define SND_AIRSTRIKE1			"npc/soldier1/misc05.wav"
#define SND_AIRSTRIKE2			"npc/soldier1/misc06.wav"
#define SND_AIRSTRIKE3			"npc/soldier1/misc10.wav"
#define SND_JETPASS				"animation/jets/jet_by_01_lr.wav"
#define SND_TANK				"player/tank/voice/attack/tank_attack_03.wav"
#define SND_WITCH				"npc/witch/voice/attack/female_distantscream1.wav"
#define SND_AMMOPICKUP			"sound/items/itempickup.wav"
#define SND_GETHIT				"sound/npc/infected/hit/hit_punch_02.wav"

#define DMY_MISSILE				"models/w_models/weapons/w_eq_molotov.mdl"		//<< our missile projectile dummy. dont change this
#define MDL_MISSILE				"models/missiles/f18_agm65maverick.mdl"
#define SND_MISSILE1			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SND_MISSILE2			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav"

#define BEAMSPRITE_BLOOD		"materials/sprites/bloodspray.vmt"
#define BEAMSPRITE_BUBBLE		"materials/sprites/bubble.vmt"

// fine tune our missile
#define HOMING_HEIGHT_MIN		250.0	// min altitude vertical missile start to look for enemy << cvar probably???? no...
#define HOMING_EXPIRE			8.0		// if targeting rocket still survive longer than this, remove him from world.
#define HOMING_INTERVAL			0.5		// homing missile interval between missile shooting.
#define MISSILE_RADIUS			100.0	// missile damage radius and point push radius
#define MISSILE_TARGET_SPEED	1000.0	// targeting missile speed
#define MISSILE_IDLE_SPEED		200.0	// verticle idle missile speed

// fine tune our shield
#define SHIELD_RADIUS			70.0	// width opening of our shield also the damage radius effect.
#define SHIELD_PUSHSHIELD		300.0	// push value for the luffy shield ability
#define SHIELD_PUSHCLOCK		800.0	// push force for the luffy clock ability
#define SHIELD_DORM_RADIUS		200		// radius of our decoration/fake dorm shield
#define SHIELD_DORM_ALPHA		60		// color alpha of the fake dorm shield

// fine tune our strength midair dash/movement
#define DASH_FORCE				400.0	// force to propel player at desired direction during strength ability. << new problem.. he might chicken out and run to saferoom :(
#define DASH_HEIGHT				100.0	// only allow midair dash after reach this height.
#define DASH_HEIGHT				100.0	// only allow midair dash after reach this height.
#define STRENGTH_GRAVITY		0.3		// gravity mult for strength ability.

#define ANIMATION_COUNT			12		// play pickup animation this much to emulate small to big model. control the final animation size here.
#define AMMOBOX_LIFE			40.0	// ammobox stay on ground longer than this, remove him.

ConVar
g_ConVarLuffyEnable, g_ConVarLuffyChance, g_ConVarLuffyMax, g_ConVarSpeedCoolDown, g_ConVarClockCoolDown, g_ConVarStrengthCoolDown,
g_ConVarSpeedMax, g_ConVarMessage, g_ConVarHPregenMax, g_ConVarTankDrop, g_ConVarBotPickUp, g_ConVarBotDrop, g_ConVarItemGlow,
g_ConVarAirStrikeNum, g_ConVarHomingNum, g_ConVarMissaleSelf, g_ConVarMissaleDmg, g_ConVarTankDamage, g_ConVarItemStay, g_ConVarTankMax,
g_ConVarWitchMax, g_ConVarHinttext, g_ConVarShieldCoolDown, g_ConVarAmmoBoxUse, g_ConVarSuperShield, g_ConVarLifeSteal, g_ConVarShieldType,
g_ConVarAllowTargetSelf, g_ConVarAllowMedkitTweak, g_ConVarEnableCountdownMsg, g_ConVarWitchDrop, g_ConVarAllowPickAnime, g_ConVarAllowMissileColor;

bool
g_bLuffyEnable, g_bAllowMessage, g_bAllowTankDrop, g_bAllowBotPickUp, g_bAllowBotKillDrop, g_bAirStrikeSelf, g_bAllowTargetSelf,
g_bHinttext, g_bAllowAmmoboxTweak, g_bAllowHealAnimate, g_bAllowCountdownMsg, g_bAllowWitchDrop, g_bAllowPickupPlay, g_bAllowMissileColor;

int
g_iLuffyChance, g_iLuffySpawnMax, g_iSpeedCoolDown, g_iClockCoolDown, g_iStrengthCoolDown, g_iSuperSpeedMax,
g_iHPregenMax, g_iItemGlowType, g_iAirStrikeNum, g_iHomingNum, g_iHomeMissaleDmg, g_iTankDamage, g_iSuperShieldDamage,
g_iShieldType, g_iLifeStealAmount, g_iTankMax, g_iWitchMax, g_iShieldCoolDown;

float	g_fLuffyItemLife;

float	g_fHomingBaseHeight[SIZE_ENTITYBUFF];
int		g_iHomingBaseOwner[SIZE_ENTITYBUFF] = { -1, ... };
int		g_iHomingBaseTarget[SIZE_ENTITYBUFF][SIZE_ENTITYBUFF];

int		g_iBeamSprite_Blood;
int		g_iBeamSprite_Bubble;
int		g_iWeaponDropBuffer[SIZE_DROPBUFF] = { -1, ... };

int		g_iDropSelectionType[3];
int		g_iLuffyModelSelection[5];
int		g_iLuffySpawnCount;

char	g_sModelBuffer[ePOS_SIZE][128];
float	g_fModelScale[ePOS_SIZE];

bool	g_bSafeToRollNextDiceModel = true;
bool	g_bIsParticlePrecached;
bool	g_bIsRoundStart;

float	g_fSkinAnimeScale[SIZE_ENTITYBUFF];		// buffer to store our pickup animation model scale
int		g_iSkinAnimeCount[SIZE_ENTITYBUFF];		// buffer to store our pickup animation count

char	g_sCURRENT_MAP[128];

////// debugging var only
bool	g_bDeveloperMode 	= true;			// if true = enable cheat for admin to use Air Strike and Homing Missile.. knock youself out.
bool	g_bBypassMissileCap	= false;			// if true, max number of missile cap 1000 bypassed. for debugging.
bool	g_bIsDebugMode		= false;			// if true, luffy drop body part, missile part and jet part highlighted. for debug.
bool	g_bShowDummyModel	= false;			// if true, sdkhook dummy will visible. for debug.



//////////////////////////////////////////////////////////////////////////////////////////////////////////
// if true, will precached custom model																	//
// (vpk must present in client addons folder aka the actual l4d2 addons game folder, not server folder).//
// if true but vpk addons not present, the game will automaticly precached the big red error model.		//
// if false, use default l4d2 model.																	//
//////////////////////////////////////////////////////////////////////////////////////////////////////////
bool g_bWithCustomModel = true;

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "GsiX",
	description	= "Si dead drop luffy item.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=1819303#post1819303"
}

public void OnPluginStart()
{
	char plName[16];
	Format( plName, sizeof( plName ), "%s_version", PLUGIN_NAME );
	
	CreateConVar( plName, PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
	g_ConVarLuffyEnable			= CreateConVar( "l4d2_luffy_enabled",			"1",		"0:Off, 1:On,  Toggle plugin on/off", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarLuffyChance			= CreateConVar( "l4d2_luffy_chance",			"100",		"0% - 100%,  Chance SI drop luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarLuffyMax			= CreateConVar( "l4d2_luffy_max",				"6",		"Number of luffy item droped at once ( Max 20 Luffy ).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarSpeedCoolDown		= CreateConVar( "l4d2_luffy_speed_cooldown",	"60",		"Time in seconds for Luffy Speed cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarClockCoolDown		= CreateConVar( "l4d2_luffy_clock_cooldown",	"60",		"Time in seconds for Luffy Clock cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarStrengthCoolDown	= CreateConVar( "l4d2_luffy_strength_cooldown",	"60",		"Time in seconds for Luffy Strength cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarShieldCoolDown		= CreateConVar( "l4d2_luffy_shield_cooldown",	"60",		"Time in seconds for Luffy Shield cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarSpeedMax			= CreateConVar( "l4d2_luffy_speedmax",			"100",		"0% - 100%, Max super speed added to normal speed.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarMessage				= CreateConVar( "l4d2_luffy_announce",			"1",		"0:Off, 1:On, Toggle announce to chat when Luffy item acquired.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarHPregenMax			= CreateConVar( "l4d2_luffy_regen_max",			"100",		"How much max HP we regenerate.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarTankDrop			= CreateConVar( "l4d2_luffy_tank_drop",			"1",		"0:Off, 1:On, If on tank will drop luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarBotPickUp			= CreateConVar( "l4d2_luffy_bot_pickup",		"0",		"0:Off, 1:On, If on Survivor Bot allowed to pick up Luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarBotDrop				= CreateConVar( "l4d2_luffy_bot_kill",			"1",		"0:Off, 1:On, If off, luffy item will not drop if SI killed by Survivor Bot.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarItemGlow			= CreateConVar( "l4d2_luffy_item_glow",			"6",		"0:off, 1:Light blue, 2:Pink, 3:Yellow, 4:Red, 5:Blue, 6:Random.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAirStrikeNum		= CreateConVar( "l4d2_luffy_airstrike_num",		"100",		"How many air strike missile we launch ( Max=1000, This effect pc performance).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarHomingNum			= CreateConVar( "l4d2_luffy_homing_num",		"100",		"How many homing missile we launch ( Max=1000, This effect pc performance).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarMissaleSelf			= CreateConVar( "l4d2_luffy_airstrike_self",	"0",		"0:Off, 1:On, If on, missile allowed friendly fire.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarMissaleDmg			= CreateConVar( "l4d2_luffy_missile_damage",	"20",		"How much damage our missile done", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarTankDamage			= CreateConVar( "l4d2_luffy_tank_damage",		"60",		"How much damage our missile done to the Tank", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarItemStay			= CreateConVar( "l4d2_luffy_item_life",			"60",		"How long luffy item droped stay on the ground. Min: 10 sec, Max:300 sec.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarTankMax				= CreateConVar( "l4d2_luffy_tank_max",			"3",		"If number of Tank more than this, reward replaced with somting else.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarWitchMax			= CreateConVar( "l4d2_luffy_witch_max",			"6",		"If number of Witch more than this, reward replaced with somting else.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarHinttext			= CreateConVar( "l4d2_luffy_hint_msg",			"1",		"0:Off, 1:On, Toggel hint text announce", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAmmoBoxUse			= CreateConVar( "l4d2_luffy_ammobox",			"1",		"0:Off, 1:On, Enable ammobox use", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarSuperShield			= CreateConVar( "l4d2_luffy_shield_damage",		"30",		"How much damage our shield done", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarLifeSteal			= CreateConVar( "l4d2_luffy_steal_health",		"5",		"Amout of life we gain if we kill SI during super strength.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarShieldType			= CreateConVar( "l4d2_luffy_shield_type",		"1",		"0:Shield follow body motion, 1:Shield allign to world plane", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowTargetSelf		= CreateConVar( "l4d2_luffy_homing_self",		"0",		"0: Off, 1: On, Homing rocket may target Survivor if no other target found(no damage)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowMedkitTweak	= CreateConVar( "l4d2_luffy_medkit_tweak",		"1",		"0: Off, 1: On, Allow plugin to animate healthbar from Medkit use.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarEnableCountdownMsg	= CreateConVar( "l4d2_luffy_count_msg",			"0",		"0: Off, 1: On, If on and l4d2_luffy_announce is on, countdown hint will be display.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarWitchDrop			= CreateConVar( "l4d2_luffy_witch_drop",		"1",		"0: Off, 1: On, Allow witch death drop luffy item.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowPickAnime		= CreateConVar( "l4d2_luffy_animepickup",		"1",		"0: Off, 1: On, If on, play pick up animation when pickup luffy item.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ConVarAllowMissileColor	= CreateConVar( "l4d2_luffy_missile_color",		"1",		"0: Off, 1: On, If on, missile get color base on l4d2_luffy_item_glow.)", FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig( true, PLUGIN_NAME );
	
	HookEvent( "round_start",			EVENT_RoundStartEnd );
	HookEvent( "round_end",				EVENT_RoundStartEnd );
	HookEvent( "map_transition",		EVENT_RoundStartEnd );
	HookEvent( "player_death",			EVENT_PlayerDeath,			EventHookMode_Post );
	HookEvent( "player_hurt",			EVENT_PlayerHurt,			EventHookMode_Post );
	HookEvent( "infected_hurt",			EVENT_InfectedHurt,			EventHookMode_Post );
	HookEvent( "witch_killed",			EVENT_WitchDeath,			EventHookMode_Post );
	HookEvent( "player_team",			EVENT_PlayerSpawn );
	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "heal_begin",			EVENT_HealBegin,			EventHookMode_Post );
	HookEvent( "heal_success",			EVENT_HealSuccess,			EventHookMode_Post );
	HookEvent( "player_use",			EVENT_PlayerUse,			EventHookMode_Post );
	HookEvent( "survivor_rescued",		EVENT_SurvivorRescued );
	HookEvent( "upgrade_pack_used",		EVENT_UpgradePackUsed );
	HookEvent( "upgrade_pack_added",	EVENT_UpgradePackAdded );
	HookEvent( "revive_success",		EVENT_ReviveSuccsess );
	HookEvent( "player_jump",			EVENT_PlayerJump );
	
	g_ConVarLuffyEnable.AddChangeHook( CVAR_Changed );
	g_ConVarLuffyChance.AddChangeHook( CVAR_Changed );
	g_ConVarLuffyMax.AddChangeHook( CVAR_Changed );
	g_ConVarSpeedCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarClockCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarStrengthCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarShieldCoolDown.AddChangeHook( CVAR_Changed );
	g_ConVarSpeedMax.AddChangeHook( CVAR_Changed );
	g_ConVarMessage.AddChangeHook( CVAR_Changed );
	g_ConVarHPregenMax.AddChangeHook( CVAR_Changed );
	g_ConVarTankDrop.AddChangeHook( CVAR_Changed );
	g_ConVarBotPickUp.AddChangeHook( CVAR_Changed );
	g_ConVarBotDrop.AddChangeHook( CVAR_Changed );
	g_ConVarItemGlow.AddChangeHook( CVAR_Changed );
	g_ConVarAirStrikeNum.AddChangeHook( CVAR_Changed );
	g_ConVarHomingNum.AddChangeHook( CVAR_Changed );
	g_ConVarMissaleSelf.AddChangeHook( CVAR_Changed );
	g_ConVarMissaleDmg.AddChangeHook( CVAR_Changed );
	g_ConVarTankDamage.AddChangeHook( CVAR_Changed );
	g_ConVarItemStay.AddChangeHook( CVAR_Changed );
	g_ConVarTankMax.AddChangeHook( CVAR_Changed );
	g_ConVarWitchMax.AddChangeHook( CVAR_Changed );
	g_ConVarHinttext.AddChangeHook( CVAR_Changed );
	g_ConVarAmmoBoxUse.AddChangeHook( CVAR_Changed );
	g_ConVarSuperShield.AddChangeHook( CVAR_Changed );
	g_ConVarLifeSteal.AddChangeHook( CVAR_Changed );
	g_ConVarShieldType.AddChangeHook( CVAR_Changed );
	g_ConVarAllowTargetSelf.AddChangeHook( CVAR_Changed );
	g_ConVarAllowMedkitTweak.AddChangeHook( CVAR_Changed );
	g_ConVarEnableCountdownMsg.AddChangeHook( CVAR_Changed );
	g_ConVarWitchDrop.AddChangeHook( CVAR_Changed );
	g_ConVarAllowPickAnime.AddChangeHook( CVAR_Changed );
	g_ConVarAllowMissileColor.AddChangeHook( CVAR_Changed );
	
	RegAdminCmd( "luffy_bazoka",	AdminMissileCheat,	ADMFLAG_GENERIC );
	RegAdminCmd( "luffy_model",		AdminModelSpawn,	ADMFLAG_GENERIC );
	RegAdminCmd( "luffy_ability",	AdminCheatAbility,	ADMFLAG_GENERIC );
	
	UpdateCVar();
}

public void OnConfigsExecuted()
{
	UpdateCVar();
}

public void OnClientPutInServer( int client )
{
	PDClientLuffy[client].iPlayerShield	= -1;
	PDClientLuffy[client].iClientMissile	= -1;
	PDClientLuffy[client].iHintCountdown	= 0;
	PDClientLuffy[client].iCleintHPHealth	= 0;
	PDClientLuffy[client].fCleintHPBuffer	= 0.0;
	PDClientLuffy[client].iLuffyType		= TYPE_NONE;
	
	PDClientLuffy[client].bAirStrike		= false;
	PDClientLuffy[client].bHomingBTN		= false;
	PDClientLuffy[client].hHealthRegen	= null;
	PDClientLuffy[client].hMoveFreeze		= null;
}

public void OnMapStart()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		PDClientLuffy[i].TimerReset();
	}
	
	g_bIsParticlePrecached = false;
	GetCurrentMap( g_sCURRENT_MAP, sizeof( g_sCURRENT_MAP ));
	CreateTimer( 0.1, Timer_PrecacheModel );
}

public void OnMapEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		PDClientLuffy[i].TimerDelete();
	}
	
	for( int i = 0; i < SIZE_ENTITYBUFF; i++ )
	{
		delete EMLuffyDrop[i].hTimer;
	}
}

/// if you change the model to your own liking... each model scaled individualy in here.
public Action Timer_PrecacheModel( Handle timer, any data )
{
	if( g_bWithCustomModel )
	{
		PrecacheModel( MDL2_CLOCK );
		g_fModelScale[ePOS_CLOCK] = 1.2;
		Format( g_sModelBuffer[ePOS_CLOCK], sizeof( g_sModelBuffer[] ), MDL2_CLOCK );
		
		PrecacheModel( MDL2_SPEED );
		g_fModelScale[ePOS_SPEED] = 1.0;
		Format( g_sModelBuffer[ePOS_SPEED], sizeof( g_sModelBuffer[] ), MDL2_SPEED );
		
		PrecacheModel( MDL2_POISON );
		g_fModelScale[ePOS_POISON] = 0.7;
		Format( g_sModelBuffer[ePOS_POISON], sizeof( g_sModelBuffer[] ), MDL2_POISON );
		
		PrecacheModel( MDL2_REGENHP );
		g_fModelScale[ePOS_REGEN] = 1.0;
		Format( g_sModelBuffer[ePOS_REGEN], sizeof( g_sModelBuffer[] ), MDL2_REGENHP );
		
		PrecacheModel( MDL2_SHIELD );
		g_fModelScale[ePOS_SHIELD] = 1.0;
		Format( g_sModelBuffer[ePOS_SHIELD], sizeof( g_sModelBuffer[] ), MDL2_SHIELD );
		
		PrecacheModel( MDL2_STRENGTH );
		g_fModelScale[ePOS_STRENGTH] = 1.0;
		Format( g_sModelBuffer[ePOS_STRENGTH], sizeof( g_sModelBuffer[] ), MDL2_STRENGTH );
		
		PrecacheModel( MDL2_GIFT );
		g_fModelScale[ePOS_GIFT] = 1.2;
		Format( g_sModelBuffer[ePOS_GIFT], sizeof( g_sModelBuffer[] ), MDL2_GIFT );
		
		PrintToServer( "" );
		PrintToServer( "|LUFFY| Custom Luffy Model Precached |LUFFY|" );
		PrintToServer( "" );

	}
	else
	{
		PrecacheModel( MDL_CLOCK );
		g_fModelScale[ePOS_CLOCK] = 1.0;
		Format( g_sModelBuffer[ePOS_CLOCK], sizeof( g_sModelBuffer[] ), MDL_CLOCK );
		
		PrecacheModel( MDL_SPEED );
		g_fModelScale[ePOS_SPEED] = 1.0;
		Format( g_sModelBuffer[ePOS_SPEED], sizeof( g_sModelBuffer[] ), MDL_SPEED );
		
		PrecacheModel( MDL_POISON );
		g_fModelScale[ePOS_POISON] = 2.5;
		Format( g_sModelBuffer[ePOS_POISON], sizeof( g_sModelBuffer[] ), MDL_POISON );
		
		PrecacheModel( MDL_REGENHP );
		g_fModelScale[ePOS_REGEN] = 3.0;
		Format( g_sModelBuffer[ePOS_REGEN], sizeof( g_sModelBuffer[] ), MDL_REGENHP );
		
		PrecacheModel( MDL_SHIELD );
		g_fModelScale[ePOS_SHIELD] = 1.0;
		Format( g_sModelBuffer[ePOS_SHIELD], sizeof( g_sModelBuffer[] ), MDL_SHIELD );
		
		PrecacheModel( MDL_STRENGTH );
		g_fModelScale[ePOS_STRENGTH] = 1.0;
		Format( g_sModelBuffer[ePOS_STRENGTH], sizeof( g_sModelBuffer[] ), MDL_STRENGTH );
		
		PrecacheModel( MDL_GIFT );
		g_fModelScale[ePOS_GIFT] = 1.0;
		Format( g_sModelBuffer[ePOS_GIFT], sizeof( g_sModelBuffer[] ), MDL_GIFT );
		
		PrintToServer( "" );
		PrintToServer( "|LUFFY| Switched To Default L4D2 Model |LUFFY|" );
		PrintToServer( "" );
	}
	
	PrecacheModel( MDL_HOMING );
	g_fModelScale[ePOS_HOMING] = 1.4;
	Format( g_sModelBuffer[ePOS_HOMING], sizeof( g_sModelBuffer[] ), MDL_HOMING );
	
	PrecacheModel( MDL_JETF18 );
	g_fModelScale[ePOS_JETF18] = 0.05;
	Format( g_sModelBuffer[ePOS_JETF18], sizeof( g_sModelBuffer[] ), MDL_JETF18 );

	PrecacheModel( DMY_SDKHOOK );
	g_fModelScale[ePOS_SDKHOOK] = 1.0;
	Format( g_sModelBuffer[ePOS_SDKHOOK], sizeof( g_sModelBuffer[] ), DMY_SDKHOOK );
	
	PrecacheModel( MDL_AMMO );
	PrecacheModel( MDL_RIOTSHIELD );
	
	PrecacheModel( DMY_MISSILE );
	PrecacheModel( MDL_MISSILE );
	PrecacheModel( PARTICLE_CREATEFIRE );

	g_iBeamSprite_Blood		= PrecacheModel( BEAMSPRITE_BLOOD );
	g_iBeamSprite_Bubble	= PrecacheModel( BEAMSPRITE_BUBBLE );
	
	PrecacheSound( SND_REWARD, true );
	PrecacheSound( SND_HEALTH, true );
	PrecacheSound( SND_SPEED, true );
	PrecacheSound( SND_CLOCK, true );
	PrecacheSound( SND_STRENGTH, true );
	PrecacheSound( SND_TIMEOUT, true );
	PrecacheSound( SND_TELEPORT, true );
	PrecacheSound( SND_ZAP_1, true );
	PrecacheSound( SND_ZAP_2, true );
	PrecacheSound( SND_ZAP_3, true );
	PrecacheSound( SND_FREEZE, true );
	PrecacheSound( SND_AIRSTRIKE1, true );
	PrecacheSound( SND_AIRSTRIKE2, true );
	PrecacheSound( SND_AIRSTRIKE3, true );
	PrecacheSound( SND_MISSILE1, true );
	PrecacheSound( SND_MISSILE2, true );
	PrecacheSound( SND_JETPASS, true );
	PrecacheSound( SND_TANK, true );
	PrecacheSound( SND_WITCH, true );
	PrecacheSound( SND_SUPERSHIELD, true );
	PrecacheSound( SND_AMMOPICKUP, true );
	PrecacheSound( SND_GETHIT, true );
	
	// scramble our selection dice buffer. This dont really give random but still better choice.
	float interval = 0.0;
	for( int i = 0; i < sizeof( g_iLuffyModelSelection ); i++ )
	{
		CreateTimer( interval, Timer_ScrambleModelSelectionDice, 0 );
		interval += 0.1;
	}
}

public void CVAR_Changed( Handle convar, const char[] oldValue, const char[] newValue )
{
	UpdateCVar();
	
	// in theory this will bug the luffy item, timer and bunch more if the plugins is disabled in the middle of the game.
	// dont care... its a massive headache.. do it on your own risk. or why would you want to do this in the middle of the game anyway.
	if ( !g_bLuffyEnable ) 	
	{
		g_bIsRoundStart = false;	//<< this check help all active timer to kill themself if the plugin disable in midgame. The least i can do to fix things
	}
}

void UpdateCVar()
{
	g_bLuffyEnable			= g_ConVarLuffyEnable.BoolValue;
	g_iLuffyChance			= g_ConVarLuffyChance.IntValue;
	g_iLuffySpawnMax		= g_ConVarLuffyMax.IntValue;
	g_iSpeedCoolDown		= g_ConVarSpeedCoolDown.IntValue;
	g_iClockCoolDown		= g_ConVarClockCoolDown.IntValue;
	g_iStrengthCoolDown		= g_ConVarStrengthCoolDown.IntValue;
	g_iShieldCoolDown		= g_ConVarShieldCoolDown.IntValue;
	g_iSuperSpeedMax		= g_ConVarSpeedMax.IntValue;
	g_bAllowMessage			= g_ConVarMessage.BoolValue;
	g_iHPregenMax			= g_ConVarHPregenMax.IntValue;
	g_bAllowTankDrop		= g_ConVarTankDrop.BoolValue;
	g_bAllowBotPickUp		= g_ConVarBotPickUp.BoolValue;
	g_bAllowBotKillDrop		= g_ConVarBotDrop.BoolValue;
	g_iItemGlowType			= g_ConVarItemGlow.IntValue;
	g_iAirStrikeNum			= g_ConVarAirStrikeNum.IntValue;
	g_iHomingNum			= g_ConVarHomingNum.IntValue;
	g_bAirStrikeSelf		= g_ConVarMissaleSelf.BoolValue;
	g_iHomeMissaleDmg		= g_ConVarMissaleDmg.IntValue;
	g_iTankDamage			= g_ConVarTankDamage.IntValue;
	g_fLuffyItemLife		= g_ConVarItemStay.FloatValue;
	g_iTankMax				= g_ConVarTankMax.BoolValue;
	g_iWitchMax				= g_ConVarWitchMax.IntValue;
	g_bHinttext				= g_ConVarHinttext.BoolValue;
	g_bAllowAmmoboxTweak	= g_ConVarAmmoBoxUse.BoolValue;
	g_iSuperShieldDamage	= g_ConVarSuperShield.IntValue;
	g_iLifeStealAmount		= g_ConVarLifeSteal.IntValue;
	g_iShieldType			= g_ConVarShieldType.IntValue;
	g_bAllowTargetSelf		= g_ConVarAllowTargetSelf.BoolValue;
	g_bAllowHealAnimate		= g_ConVarAllowMedkitTweak.BoolValue;
	g_bAllowCountdownMsg	= g_ConVarEnableCountdownMsg.BoolValue;
	g_bAllowWitchDrop		= g_ConVarWitchDrop.BoolValue;
	g_bAllowPickupPlay		= g_ConVarAllowPickAnime.BoolValue;
	g_bAllowMissileColor	= g_ConVarAllowMissileColor.BoolValue;
}

// admin cheat command.. intended for testing.
public Action AdminMissileCheat( int client, any args )
{
	if ( IsValidSurvivor( client ) && g_bDeveloperMode )
	{
		PDClientLuffy[client].bAirStrike	= true;
		PDClientLuffy[client].bHomingBTN 	= true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE1 );
			}
			case 2:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE2 );
			}
			case 3:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE3 );
			}
		}
		PrintHintText( client, "++ Press 'RELOAD + FIRE' to launch Air Strike ++" );
	}
	return Plugin_Handled;
}

// admin spawn command to test spawn model..
public Action AdminModelSpawn( int client, any args )
{
	if ( IsValidSurvivor( client ) && g_bDeveloperMode )
	{
		// Show client usage explanation if args less than 2
		if ( args < 2 )
		{
			ReplyToCommand( client, "[LUFFY]: Usage: luffy_model 1 3" );
			ReplyToCommand( client, "[LUFFY]: luffy_model 1(model type) 3(life = how long it stay on ground)" );
			return Plugin_Handled;
		}
		
		// Get first arg
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		int type = StringToInt( arg1 );
		
		int size = sizeof( g_sModelBuffer ) - 1;
		if( type < 0 || type > size )
		{
			ReplyToCommand( client, "[LUFFY]: valid model index >= 0 and index <= %d", size );
			return Plugin_Handled;
		}
		
		char arg2[8];
		GetCmdArg( 2, arg2, sizeof( arg2 ));
		float life = StringToFloat( arg2 );
		if( life < 1.0 || life > 120.0 )
		{
			ReplyToCommand( client, "[LUFFY]: second Args between 1 secs to 120 secs" );
			return Plugin_Handled;
		}
		
		float pos_start[3];
		float ang_start[3];
		float pos_end[3];
		
		GetClientEyePosition( client, pos_start );
		GetClientEyeAngles( client, ang_start );
		bool gotpos = TraceRayGetEndpoint( pos_start, ang_start, client, pos_end );
		if( gotpos )
		{
			pos_end[2] += 20.0;
			ang_start[0] = 0.0;
			int dummy	= CreatEntRenderModel( PROPTYPE_DYNAMIC, g_sModelBuffer[type], pos_end, ang_start, g_fModelScale[type] );
			if ( dummy != -1 )
			{
				PrintToChat( client, "[LUFFY]: Model spawn succsess..!!" );
				PrintToChat( client, "** %s **", g_sModelBuffer[type] );
				CreateTimer( 0.1, Timer_TestRotate, EntIndexToEntRef( dummy ), TIMER_REPEAT );
				CreateTimer( life, Timer_DeletIndex, EntIndexToEntRef( dummy ));
			}
		}
	}
	return Plugin_Handled;
}

public Action Timer_TestRotate( Handle timer, any entref )
{
	int ent = EntRefToEntIndex( entref );
	if( ent > MaxClients && IsValidEntity( ent ) && g_bIsRoundStart )
	{
		float ang[3];
		GetEntAngle( ent, ang, 20.0, AXIS_YAW );
		TeleportEntity( ent, NULL_VECTOR, ang, NULL_VECTOR );
		//PrintToChatAll( "ang[0]: %f | ang[1]: %f | ang[2]: %f", ang[0], ang[1], ang[2] );
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

// admin cheat command to get instant ability
public Action AdminCheatAbility( int client, any args )
{
	if ( client > 0 && g_bDeveloperMode )
	{
		// Show client usage explanation if args less than 2
		if ( args < 1 )
		{
			ReplyToCommand( client, "[LUFFY]: Usage: luffy_ability 1(ability type)" );
			ReplyToCommand( client, "ability type: 1=Clock, 2=Speed, 3=Shield, 4=Strength, 5=Health, 6=Punishment" );
			return Plugin_Handled;
		}
		
		// Get first arg
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		int type = StringToInt( arg1 );
		if( type > TYPE_NONE && type < TYPE_HEALTH && PDClientLuffy[client].iLuffyType != TYPE_NONE )
		{
			ReplyToCommand( client, "[LUFFY]: Luffy ability still active!!" );
			return Plugin_Handled;
		}
		
		if( type < TYPE_CLOCK || type > TYPE_FREEZE )
		{
			ReplyToCommand( client, "[LUFFY]: ability type: 1=Clock, 2=Speed, 3=Shield, 4=Strength, 5=Health, 6=Punishment, 7=Freeze" );
			return Plugin_Handled;
		}
		
		if( type == TYPE_CLOCK )
		{
			if( PDClientLuffy[client].fAbilityCountdown == 0.0 )
			{
				SetLuffyClock( client );
			}
		}
		else if( type == TYPE_SPEED )
		{
			if( PDClientLuffy[client].fAbilityCountdown == 0.0 )
			{
				SetLuffySpeed( client );
			}
		}
		else if( type == TYPE_SHIELD )
		{
			if( PDClientLuffy[client].fAbilityCountdown == 0.0 )
			{
				SetLuffyShield( client );
			}
		}
		else if( type == TYPE_STRENGTH )
		{
			if( PDClientLuffy[client].fAbilityCountdown == 0.0 )
			{
				SetLuffyStrength( client );
			}
		}
		else if( type == TYPE_HEALTH )
		{
			if( PDClientLuffy[client].hHealthRegen == null )
			{
				SetLuffyHealth( client );
			}
		}
		else if( type == TYPE_POISON )
		{
			SetLuffyPunishment( client );
		}
		else if( type == TYPE_FREEZE )
		{
			SetFreeze( client );
		}
	}
	return Plugin_Handled;
}

public void EVENT_RoundStartEnd ( Event event, const char[] name, bool dontBroadcast )
{
	if( StrEqual( name, "round_start", false ))
	{
		g_bIsRoundStart = true;
		g_bSafeToRollNextDiceModel = true;
		g_iLuffySpawnCount = 0;

		int j;
		for( int i = 0; i < SIZE_ENTITYBUFF; i++ )
		{
			delete EMLuffyDrop[i].hTimer;
			
			EMLuffyDrop[i].fLife		= 0.0;
			g_fHomingBaseHeight[i]		= 0.0;
			if ( i < SIZE_DROPBUFF )
			{
				g_iWeaponDropBuffer[i]	= -1;
			}

			for( j = 0; j < SIZE_ENTITYBUFF; j++ )
			{
				g_iHomingBaseTarget[i][j] = -1;
			}
		}
	}
	else
	{
		g_bIsRoundStart = false;
	}
}

public void EVENT_PlayerSpawn( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;
	
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		PDClientLuffy[client].bAirStrike	= false;
		PDClientLuffy[client].bHomingBTN	= false;
		PDClientLuffy[client].hAirStrike	= null;
		PDClientLuffy[client].hHealthRegen	= null;
		PDClientLuffy[client].iLuffyType	= TYPE_NONE;
		
		ResetLuffyAbility( client );
		PDClientLuffy[client].ButtonUnfreeze( client );
		
		if( !g_bIsParticlePrecached )
		{
			g_bIsParticlePrecached = true;
			CreateTimer( 0.1, Timer_PrecacheEntity, userid );
		}
	}
}

public void EVENT_SurvivorRescued( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;
	
	int  client = GetClientOfUserId( event.GetInt( "victim" ));
	if ( IsValidSurvivor( client ))
	{
		PDClientLuffy[client].bAirStrike	= false;
		PDClientLuffy[client].bHomingBTN	= false;
		PDClientLuffy[client].hAirStrike	= null;
		PDClientLuffy[client].hHealthRegen	= null;
		PDClientLuffy[client].iLuffyType	= TYPE_NONE;
		ResetLuffyAbility( client );
		PDClientLuffy[client].ButtonUnfreeze( client );
	}
}

public void EVENT_PlayerDeath( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;

	int  client = GetClientOfUserId( event.GetInt( "userid" ));
	if( IsValidSurvivor( client ))
	{
		PDClientLuffy[client].iLuffyType = TYPE_NONE;
	}
	else if ( IsValidInfected( client ))
	{
		int  attacker = GetClientOfUserId( event.GetInt( "attacker" ));
		if( IsValidSurvivor( attacker ))
		{
			if( ( IsFakeClient( attacker ) && !g_bAllowBotKillDrop ))
			{
				return;
			}
			
			// life steal during super strength.
			if ( PDClientLuffy[attacker].iLuffyType == TYPE_STRENGTH )
			{
				float bff[3];
				float pos[3];
				GetEntOrigin( client, pos, 10.0 );
				
				for( int i = 1; i <= 5; i++ )
				{
					CopyArray3DF( pos, bff );
					bff[0] + GetRandomFloat( -50.0, 50.0 );
					bff[1] + GetRandomFloat( -50.0, 50.0 );
					CreatePointParticle( bff, PARTICLE_ELECTRIC1, 0.2 );
					
					CopyArray3DF( pos, bff );
					bff[0] + GetRandomFloat( -50.0, 50.0 );
					bff[1] + GetRandomFloat( -50.0, 50.0 );
					CreatePointParticle( bff, PARTICLE_ELECTRIC2, 0.2 );
				}
				switch( GetRandomInt( 1, 3 )) {
					case 1: {
						EmitSoundToAll( SND_ZAP_1, client, SNDCHAN_AUTO );
					}
					case 2: {
						EmitSoundToAll( SND_ZAP_2, client, SNDCHAN_AUTO );
					}
					case 3: {
						EmitSoundToAll( SND_ZAP_3, client, SNDCHAN_AUTO );
					}
				}
				
				int health	= GetPlayerHealth( attacker ) + g_iLifeStealAmount;
				if( health > 100 )
				{
					health = 100;					// make sure our healt plus stolen health dont exceed 100.
				}
				
				float buffer = GetPlayerHealthBuffer( attacker );
				float newbuff = float(health) + buffer;
				if( newbuff > 100.0 )				// make sure our healt plus buffer dont exceed 100.
				{
					newbuff = 100.0 - float(health);
				}
				SetPlayerHealth( attacker, health );
				SetPlayerHealthBuffer( attacker, newbuff );
			}
		}


		if ( GetZclass( client ) == ZOMBIE_TANK && !g_bAllowTankDrop )
		{
			return;
		}

		// we only roll 1 model dice at a time because we have a while loop in a timer
		// if not safe to roll, consider this kill a waste.
		if( g_bSafeToRollNextDiceModel && g_iLuffySpawnCount < g_iLuffySpawnMax )
		{
			RollLuffyDropDice( client );
		}
	}
}

public void EVENT_WitchDeath( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable || !g_bAllowWitchDrop ) return;

	int witch = event.GetInt( "witchid" );
	if ( witch > 0 && IsValidEntity( witch ))
	{
		char className[16];
		GetEntityClassname( witch, className, sizeof( className ));
		if( StrEqual( className, "witch", false ))
		{
			int attacker = GetClientOfUserId( event.GetInt( "userid" ));
			if( IsValidSurvivor( attacker ))
			{
				// life steal during super strength.
				if ( PDClientLuffy[attacker].iLuffyType == TYPE_STRENGTH )
				{
					float bff[3];
					float pos[3];
					GetEntOrigin( witch, pos, 10.0 );
					
					for( int i = 1; i <= 5; i++ )
					{
						CopyArray3DF( pos, bff );
						bff[0] + GetRandomFloat( -50.0, 50.0 );
						bff[1] + GetRandomFloat( -50.0, 50.0 );
						CreatePointParticle( bff, PARTICLE_ELECTRIC1, 0.2 );
						
						CopyArray3DF( pos, bff );
						bff[0] + GetRandomFloat( -50.0, 50.0 );
						bff[1] + GetRandomFloat( -50.0, 50.0 );
						CreatePointParticle( bff, PARTICLE_ELECTRIC2, 0.2 );
					}
					switch( GetRandomInt( 1, 3 )) {
						case 1: {
							EmitSoundToAll( SND_ZAP_1, witch, SNDCHAN_AUTO );
						}
						case 2: {
							EmitSoundToAll( SND_ZAP_2, witch, SNDCHAN_AUTO );
						}
						case 3: {
							EmitSoundToAll( SND_ZAP_3, witch, SNDCHAN_AUTO );
						}
					}
					
					int health	= GetPlayerHealth( attacker ) + g_iLifeStealAmount;
					if( health > 100 )
					{
						health = 100;					// make sure our healt plus stolen health dont exceed 100.
					}
					
					float buffer = GetPlayerHealthBuffer( attacker );
					float newbuff = float(health) + buffer;
					if( newbuff > 100.0 )				// make sure our healt plus buffer dont exceed 100.
					{
						newbuff = 100.0 - float(health);
					}
					SetPlayerHealth( attacker, health );
					SetPlayerHealthBuffer( attacker, newbuff );
				}
			}
			
			// we only roll 1 model dice at a time because we have a while loop in a timer
			// if not safe to roll, consider this kill a waste.
			if( g_bSafeToRollNextDiceModel && g_iLuffySpawnCount < g_iLuffySpawnMax )
			{
				RollLuffyDropDice( witch );
			}
		}
	}
}

public Action OnPlayerRunCmd( int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon ) //<< ok == launch airstrike and dashing here
{
	// this guy launching airstrike
	if (( buttons & IN_RELOAD ) && ( buttons & IN_ATTACK ))
	{
		if( ( PDClientLuffy[client].bAirStrike ) && PDClientLuffy[client].hAirStrike == null )
		{
			PDClientLuffy[client].bAirStrike	= false;
			PrintHintTextToAll( "++ %N Launched Air Strike ++", client );
			
			switch( GetRandomInt( 1, 3 ))
			{
				case 1:
				{
					EmitSoundToAll( SND_AIRSTRIKE1, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
				}
				case 2:
				{
					EmitSoundToAll( SND_AIRSTRIKE2, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
				}
				case 3:
				{
					EmitSoundToAll( SND_AIRSTRIKE3, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
				}
			}
			
			float jet_pos[3];
			float jet_ang[3];
			GetEntOrigin( client, jet_pos, 130.0 );				// always above player head
			GetEntAngle( client, jet_ang, 10.0, AXIS_PITCH );	// jet nose always pitch down 
			
			int jetf18 = CreatEntRenderModel( "prop_dynamic_override", g_sModelBuffer[ePOS_JETF18], jet_pos, jet_ang, g_fModelScale[ePOS_JETF18] );
			if( jetf18 != -1 )
			{
				SetOwner( jetf18, client );
				ToggleGlowEnable( jetf18, true );
				
				float flmOri[3] = { 0.0, 0.0, 0.0 };		// exaust pos relative to parent attachment
				float flmAng[3] = { 0.0, 180.0, 0.0 };		// exaust ang relative to parent attachment
				int exaust = CreateExaust( jetf18, flmOri, flmAng, g_iColor_Exaust );
				if( exaust != -1 )
				{
					int  miss = g_iAirStrikeNum;
					if( !g_bBypassMissileCap )
					{
						if ( miss < 1 ) miss = 1;
						if ( miss > 1000 ) miss = 1000;
					}
					
					PDClientLuffy[client].iClientMissile = miss + 1;	// plus 1 because we cutdown 1 missile before actually fire any
					PDClientLuffy[client].hAirStrike = CreateTimer( 0.1, Timer_JetF18Life, EntIndexToEntRef( jetf18 ), TIMER_REPEAT );
				}
			}
		}
	}
	
	// this guy using his dash to change position midair.
	if ( PDClientLuffy[client].iLuffyType == TYPE_STRENGTH )
	{
		if( !PDClientLuffy[client].bIsDoubleDashPaused )
		{
			// pressing 3 button, forward, left and space wont detected. :(
			float direction = -1.0;
			if( (buttons & IN_FORWARD) && (buttons & IN_JUMP))
			{
				direction = 0.0;									
			}
			else if( (buttons & IN_BACK) && (buttons & IN_JUMP))
			{
				direction = 180.0;
			}
			else if( (buttons & IN_MOVELEFT) && (buttons & IN_JUMP))
			{
				direction = 90.0;
			}
			else if( (buttons & IN_MOVERIGHT) && (buttons & IN_JUMP))
			{
				direction = -90.0;
			}
			
			if( direction != -1.0 )
			{
				// roughly this is how we make our line of code longer and scared people away.
				// i mean calculate our next endpoint and get the final post based on known distance and angle.
				float pos_start[3];
				float pos_new[3];
				float ang_start[3];
				GetEntOrigin( client, pos_start, 0.0 );								// get our initial world pos for checking height, lift it 10 unit so it not on the ground.
				float height = pos_start[2] - PDClientLuffy[client].fPosJump[2];
				
				// check our distance from the ground, acuracy not matter so we ignore the inital 10 unit
				if( height >= DASH_HEIGHT )											// our distance is safe to dash around
				{
					CopyArray3DF( pos_start, pos_new );								// copy or just get our initial world pos again so that we can manipulate later
					GetEntAngle( client, ang_start, direction, AXIS_YAW );			// get our inital forward world angle plus the manipulated direction at yaw angle.
					float radius = 100.0;											// roughly known/desired radius/distance surrounding us.
					
					// calculate where the intersection between known radius and known angle. final result is new endpoint/pos_new
					pos_new[0] += radius * Cosine( DegToRad( ang_start[1] ));
					pos_new[1] += radius * Sine( DegToRad( ang_start[1] ));
					
					float vec_new[3];
					MakeVectorFromPoints( pos_start, pos_new, vec_new );			// get vector from the 2 points. location where we start to our new location.
					NormalizeVector( vec_new, vec_new );							// always normalize when it is a vector.
					ScaleVector( vec_new, DASH_FORCE );								// scale it to create force.
					TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, vec_new );	// push the guy.. walla... we dashing in midair.. :)
					PDClientLuffy[client].bIsDoubleDashPaused = true;				// we dashed once, wait until we touch the ground. the check inside the strength timer.
				}
			}
		}
	}
	return Plugin_Continue;
}

int CreateMissileProjectile( int client, float pos_world_start[3], float pos_world_end[3] )
{
	// NOTE: We need the initial world position so the child entity created wont appear at world origin zero
	// and teleport to his parent origin attachment. firing hundred of missile make the child moving from world origin 
	// to his parent attachmen and it appear as if it was bagged.
	
	//// create projectile with physic so it interact with gravity and SDKHook function. act as a parent.
	float vecBuf[3];
	float vecAng[3];
	MakeVectorFromPoints( pos_world_start, pos_world_end, vecBuf );
	GetVectorAngles( vecBuf, vecAng );
	vecAng[0] -= 90.0;		// -90.0 = adjustment for the molotov orientation always facing target position.
	
	int body = -1;
	int exaust = -1;
	
	int head = CreatEntRenderModel( PROPTYPE_MOLOTOVE, DMY_MISSILE, pos_world_start, vecAng, 0.01 );
	if( head != -1 )
	{
		SetOwner( head, client );
		SetEntityGravity( head, 0.01 );
		SetEntPropFloat( head, Prop_Send,"m_flModelScale", 0.01 );
		
		// attach missile model to make it appealing and scared the bot infected away.	
		float pos_parent[3] = { 0.0, 2.0, -2.0 };		// center the model relative to molotov/parent
		float ang_parent[3] = { 90.0, 0.0, 0.0 };		// rotate the model relative to molotov/parent
		body = CreatEntChild( head, MDL_MISSILE, pos_world_start, pos_parent, ang_parent, 0.1 );
		if( body != -1 )
		{
			// attach exaust to make it look real rocket projectile.
			float pos_flm[3] = { 0.0, 2.0, 0.0 };		// origin relative to molotov/parent
			float ang_flm[3] = { -90.0, 0.0, 0.0 };		// angle relative to molotov/parent
			exaust = CreateExaust( head, pos_flm, ang_flm, g_iColor_Exaust );
			if( exaust != -1 )
			{
				if( g_bAllowMissileColor )
				{
					ToggleGlowEnable( head, true );
				}
				
				// if i cant read this next time, note to self >>> retire from coding.
				SDKHook( head, SDKHook_StartTouchPost, OnMissileTouch );
				
				ToggleGlowEnable( body, true );
				return head;
			}
		}
	}
	
	if ( exaust == -1 )
	{
		RemoveEntity_Kill( exaust );
		RemoveEntity_Kill( body );
		RemoveEntity_Kill( head );
	}
	return -1;
}

void ChangeDirectionAndShoot( int entity, float pos_target[3], float speed, float pitch_angle_correction )
{
	float pos_start[3];
	float vecVel[3];
	float ang_start[3];
	GetEntOrigin( entity, pos_start, 0.0 );
	MakeVectorFromPoints( pos_start, pos_target, vecVel );
	GetVectorAngles( vecVel, ang_start );
	NormalizeVector( vecVel, vecVel );
	ScaleVector( vecVel, speed );					
	
	ang_start[0] += pitch_angle_correction;
	TeleportEntity( entity, pos_start, ang_start, NULL_VECTOR );
	TeleportEntity( entity, NULL_VECTOR, NULL_VECTOR, vecVel );
}

public Action Timer_MissileExplode( Handle timer, any entref )
{
	// our missile didnt hit anything, kill him.
	int missile = EntRefToEntIndex( entref );
	if( IsEntityValid( missile ))
	{
		// if missile not SDKHook-ed it suppost not to error out.
		SDKUnhook( missile, SDKHook_StartTouchPost, OnMissileTouch );
		
		//missile explosion sound.
		switch( GetRandomInt( 1, 2 ))
		{
			case 1:	{ EmitSoundToAll( SND_MISSILE1, missile, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE )	;}
			case 2:	{ EmitSoundToAll( SND_MISSILE2, missile, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE )	;}
		}
		
		float missilePos[3];
		GetEntOrigin( missile, missilePos, 10.0 ); 
		
		int attacker = -1;
		int client = GetOwner( missile );
		if( IsValidSurvivor( client ))
		{
			attacker = client;
		}
		
		CreatePointParticle( missilePos, PARTICLE_EXPLOSIVE, 0.01 );
		CreatePointPush( 200.0, MISSILE_RADIUS, missilePos, 0.1 );
		RemoveEntity_KillHierarchy( missile );
		
		int base = EntRefToEntIndex( g_iHomingBaseOwner[missile] );
		if( base > MaxClients )
		{
			g_iHomingBaseTarget[base][missile] = -1;
		}
		
		g_iHomingBaseOwner[missile] = -1;
		g_fHomingBaseHeight[missile] = 0.0;
		
		// this is important, i should check if there is wall between the missile and the target
		// befor hurt/damage and/or push them. I m not gonna do that.. this plugin once reached 5k line of code so ya..
		char clname[64];
		float victimPos[3];
		int	cnt = GetEntityCount();
		for ( int i = 1; i <= cnt; i++ )
		{
			if ( i <= MaxClients )
			{
				if ( IsValidSurvivor( i ) && IsPlayerAlive( i ) && g_bAirStrikeSelf )
				{
					GetEntOrigin( i, victimPos, 10.0 );
					if ( GetVectorDistance( missilePos, victimPos ) <= MISSILE_RADIUS )
					{
						CreatePointHurt( attacker, i, 0, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
					}
				}
				else if ( IsValidInfected( i ) && IsPlayerAlive( i ))
				{
					GetEntOrigin( i, victimPos, 10.0 );
					if ( GetVectorDistance( missilePos, victimPos ) <= MISSILE_RADIUS )
					{
						if( GetZclass( i ) == ZOMBIE_TANK )
						{
							CreatePointHurt( attacker, i, g_iTankDamage, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
						}
						else
						{
							CreatePointHurt( attacker, i, g_iHomeMissaleDmg, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
						}
					}
				}
			}
			else
			{
				if ( IsValidEntity( i ))
				{
					GetEntityClassname( i, clname, sizeof( clname ));
					if ( StrContains( clname, "infected", false ) != -1 || StrContains( clname, "witch", false ) != -1 ) // hurt and push only normal infected and witch
					{
						GetEntOrigin( i, victimPos, 10.0 );
						if ( GetVectorDistance( missilePos, victimPos ) <= MISSILE_RADIUS )
						{
							CreatePointHurt( attacker, i, g_iHomeMissaleDmg, DAMAGE_EXPLOSIVE, missilePos, MISSILE_RADIUS );
						}
					}
				}
			}
		}
	}
}

public Action OnMissileTouch( int hooked_ent, int toucher )
{
	if( IsValidSurvivor( toucher ))
	{
		return Plugin_Continue;
	}
	
	// free this sdkhook from the expensive damage computation
	if( hooked_ent > MaxClients && IsValidEntity( hooked_ent ))
	{
		SDKUnhook( hooked_ent, SDKHook_StartTouchPost, OnMissileTouch );
		CreateTimer( 0.0, Timer_MissileExplode, EntIndexToEntRef( hooked_ent ));
	}
	return Plugin_Continue;
}

public Action OnLuffyObjectTouch( int hooked_ent, int toucher ) 
{
	if( IsValidSurvivor( toucher ))
	{
		if ( IsFakeClient( toucher ) && !g_bAllowBotPickUp )
		{
			return;
		}
		
		int child = GetEntityChild( hooked_ent );
		if( child > 0 && IsValidEntity( child ))
		{
			char modelName[128];
			GetEntPropString( child, Prop_Data, "m_ModelName", modelName, sizeof( modelName ));
			if( StrEqual( modelName, g_sModelBuffer[ePOS_JETF18], false ))
			{
				if( PDClientLuffy[toucher].bAirStrike )
				{
					PrintHintText( toucher, "++ Already Aquired Air Strike ++" );
					return;
				}
				else if( PDClientLuffy[toucher].hAirStrike != null )
				{
					PrintHintText( toucher, "++ Air Strike In Progress ++" );
					return;
				}
			}
			else if( StrEqual( modelName, g_sModelBuffer[ePOS_HOMING], false ) && PDClientLuffy[toucher].bHomingBTN )
			{
				PrintHintText( toucher, "++ Already aquired Homing Missile ++" );
				return;
			}
			else if ( StrEqual( modelName, g_sModelBuffer[ePOS_REGEN], false))
			{
				if( GetPlayerHealth( toucher ) >= g_iHPregenMax )
				{
					PrintHintText( toucher, "-- You are healthy for Luffy Health --" );
					return;
				}
				else if(  PDClientLuffy[toucher].hHealthRegen != null )
				{
					PrintHintText( toucher, "-- You Still On Luffy Drug --" );
					return;
				}
			}
			else if( StrEqual( modelName, g_sModelBuffer[ePOS_CLOCK], false) || StrEqual( modelName, g_sModelBuffer[ePOS_SPEED], false) ||
					 StrEqual( modelName, g_sModelBuffer[ePOS_SHIELD], false) || StrEqual( modelName, g_sModelBuffer[ePOS_STRENGTH], false ))
			{
				if ( PDClientLuffy[toucher].iLuffyType != TYPE_NONE )
				{
					PrintHintText( toucher, "-- Luffy Ability Still Active --" );
					return;
				}
			}
			
			g_iLuffySpawnCount--;
			if( g_iLuffySpawnCount < 0 )
			{
				g_iLuffySpawnCount = 0;
			}
			
			delete EMLuffyDrop[hooked_ent].hTimer;
			
			SDKUnhook( hooked_ent, SDKHook_StartTouchPost, OnLuffyObjectTouch );
			RemoveEntity_KillHierarchy( hooked_ent );
			RewardPicker( toucher, modelName );
		}
	}
}

// all ability listed here
void RewardPicker( int client, const char[] mName )
{
	if ( StrEqual( mName, g_sModelBuffer[ePOS_CLOCK], false ))			// clock device
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_CLOCK];
		SetLuffyClock( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_SPEED], false ))		// super speed
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_SPEED];
		SetLuffySpeed( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_POISON], false ))	// luffy poison
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_POISON];
		SetLuffyPunishment( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_REGEN], false))		// player HP
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_REGEN];
		SetLuffyHealth( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_SHIELD], false))		// player shield
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_SHIELD];
		SetLuffyShield( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_STRENGTH], false))	//super strength
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_STRENGTH];
		SetLuffyStrength( client );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_GIFT], false ))		// reward T2 weapon and give his primary weapon double ammo << now that sound rewarding.
	{																	// not rewarding enough? Drop also random health buff. Still not rewarding? you greed af.
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_GIFT];
		DropRandomWeapon( client, WEAPON_TIER2 );
		RestockPrimaryAmmo( client, 2 );
		switch( GetRandomInt( 0, 2 ))
		{
			case 0:	{ GivePlayerItems( client, "weapon_pain_pills" );	}
			case 1:	{ GivePlayerItems( client, "weapon_defibrillator" );}
			case 2:	{ GivePlayerItems( client, "weapon_adrenaline" );	}
		}
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_HOMING], false))		// homing missile
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_HOMING];
		PDClientLuffy[client].bHomingBTN = true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE1 );
			}
			case 2:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE2 );
			}
			case 3:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE3 );
			}
		}
		if ( g_bHinttext )
		{
			PrintToChatAll( "\x04[\x05LUFFY\x04]: %N \x05 acquired \x04Homing Missile", client );
		}
		PrintHintText( client, "++ Get Ammo Box And Deploy It ++" );
	}
	else if ( StrEqual( mName, g_sModelBuffer[ePOS_JETF18], false))		// air strike
	{
		PDClientLuffy[client].fScale = g_fModelScale[ePOS_JETF18];
		PDClientLuffy[client].bAirStrike = true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE1 );
			}
			case 2:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE2 );
			}
			case 3:
			{
				EmitSoundToClient( client, SND_AIRSTRIKE3 );
			}
		}
		
		if ( g_bHinttext )
		{
			PrintToChatAll( "\x04[\x05LUFFY\x04]: %N \x05 acquired \x04Air Strike.", client );
		}
		PrintHintText( client, "++ Press 'RELOAD + FIRE' to launch Air Strike ++" );
	}
	
	if( g_bAllowPickupPlay )
	{
		float pos[3];
		float ang[3] = { 0.0, 0.0, 0.0 };
		GetEntOrigin( client, pos, 20.0 );
		GetEntAngle( client, ang, 0.0, AXIS_PITCH );
		ang[0] = 0.0;
		
		// just ordinary model animation. hacky way but it works. we emulate model scaling
		int skin = CreatEntRenderModel( PROPTYPE_DYNAMIC, mName, pos, ang, PDClientLuffy[client].fScale );
		if ( skin != -1 )
		{
			SetRenderColour( skin, g_iColor_White, 80 );
			g_fSkinAnimeScale[skin] = PDClientLuffy[client].fScale;
			g_iSkinAnimeCount[skin] = 1;
			CreateTimer( 0.1, Timer_PlayLuffyPickupAnimation, EntIndexToEntRef( skin ), TIMER_REPEAT );
		}
	}
}

// new and old melee weapon still not available.
public void EVENT_UpgradePackUsed( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;
	
	int  userid	= event.GetInt( "userid" );
	int  client	= GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		bool destroy = true;
		
		if( !PDClientLuffy[client].bHomingBTN )
		{
			if( g_bAllowAmmoboxTweak )
			{
				// for first time usage, value always zero mean let player have the ammobox.
				switch( PDClientLuffy[client].iClientDice[0] )
				{
					case 1:  { DropRandomWeapon( client, WEAPON_TIER1 );					}
					case 2:	 { SetFreeze( client );									}
					case 3:	 { GivePlayerItems( client, "weapon_pipe_bomb" );				}
					case 4:	 { GivePlayerItems( client, "weapon_molotov" );					}
					case 5:	 { GivePlayerItems( client, "weapon_vomitjar" );				}
					case 6:  { CheatCommand( client, "z_spawn_old", "tank auto" );			}
					case 7:  { GivePlayerItems( client, "weapon_first_aid_kit" );			}
					case 8:	 { GivePlayerItems( client, "weapon_defibrillator" );			}
					case 9:  { GivePlayerItems( client, "weapon_pain_pills" );				}
					case 10: { DropRandomWeapon( client, WEAPON_TIER1 );					}
					case 11: { GivePlayerItems( client, "weapon_adrenaline" );				}
					case 12: { CheatCommand( client, "z_spawn_old", "witch auto" );			}
					case 13: { CheatCommand( client, "director_force_panic_event", "" );	}
					case 14: { GivePlayerItems( client, "upgrade_laser_sight" );			}
					case 15: { GivePlayerItems( client, "weapon_ammo_spawn" );				}
					case 16: { SetTeleport( client, "Survivor" );						}
					case 17: { SetTeleport( client, "Witch" );							}
					case 18: { SetTeleport( client, "Tank" );							}
					case 19: { SetLuffyHealth( client );									}
					case 20: { DropRandomWeapon( client, WEAPON_TIER1 );					}
					case 21: { if ( g_bAllowMessage == true ) { PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You got empty box!!" ); }}
					default : {	destroy = false; }  /*<< give him the ammobox*/
				}
				
				// roll the next dice ahead of ammobox use after we are done doing things above... this should be a bit faster
				// also we free this EVENT_UpgradePackUsed from the huge while loop. 
				CreateTimer( 0.1, Timer_RollAmmoboxDice, userid );
			}
			else
			{
				destroy = false;
			}
		}
		else
		{
			int ammobox = event.GetInt( "upgradeid" );
			if( ammobox > MaxClients && IsValidEntity( ammobox ))
			{
				RunHomingMissile( client, ammobox );
				PrintHintTextToAll( "++ %N Launched Homing Missile ++", client );
			}
		}
		
		if( destroy )
		{
			RemoveEntity_Kill( event.GetInt( "upgradeid" ));
		}
	}
}

public Action Timer_HomingBaseLife( Handle timer, any entref )
{
	int base = EntRefToEntIndex( entref );
	if( base > MaxClients )
	{
		RemoveEdict( base );
	}
}

public Action Timer_HomingBaseLaunch( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if( entity > MaxClients )
	{
		if( g_bIsRoundStart )
		{
			float pos_launcher[3];
			GetEntOrigin( entity, pos_launcher, 30.0 );		// 30.0 always above launcher base.
			pos_launcher[0] += GetRandomFloat( -10.0, 10.0 );
			pos_launcher[1] += GetRandomFloat( -10.0, 10.0 );
			
			float pos_target[3];
			SetArray3DF( pos_target, pos_launcher[0], pos_launcher[1], ( pos_launcher[2] + 1000.0 )); // verticle position so the missile inital start verticly 
			
			int missile, client = GetOwner( entity );
			if( IsValidSurvivor( client ))
			{
				PCMasterRace_Render_ARGB( client, 130 );	// 0.5 interval between rendering is too slow.. so we render it at 4K 260hz resolution. I mean higher alpha.
				missile = CreateMissileProjectile( client, pos_launcher, pos_target );
			}
			else
			{
				missile = CreateMissileProjectile( entity, pos_launcher, pos_target );
			}
			
			if( missile != -1 )
			{
				// value 160.0 is the speed of our verticle missile. fly slower to buy time for the shooting/targeting missile to empty its target array
				ChangeDirectionAndShoot( missile, pos_target, MISSILE_IDLE_SPEED, -90.0 );	// -90.0 is the molotov body pitch correction 
				
				// track which 1 is our base.
				g_iHomingBaseOwner[missile] = EntIndexToEntRef( entity );
				g_iHomingBaseTarget[entity][missile] = -1;
				
				// track our HomingBase z pos.
				g_fHomingBaseHeight[missile] = g_fHomingBaseHeight[entity];
				
				//SDKHook( missile, SDKHook_Think, OnMissileThink );	// <<< operation too expensive.
				CreateTimer( 0.1, Timer_HomingMissileHoming, EntIndexToEntRef( missile ), TIMER_REPEAT );
				CreateTimer( HOMING_EXPIRE, Timer_MissileExplode, EntIndexToEntRef( missile ), TIMER_FLAG_NO_MAPCHANGE );	//<< safety just incase our missile stuck
			}
		}
		else
		{
			RemoveEntity_Kill( entity );
		}
	}
}

public Action Timer_HomingMissileHoming( Handle timer, any entref )
{
	int missile = EntRefToEntIndex( entref );
	if( missile > MaxClients )
	{
		if( !g_bIsRoundStart )
		{
			// round is end, kill this guy.
			CreateTimer( 0.0, Timer_MissileExplode, EntIndexToEntRef( missile ));
			return Plugin_Stop;
		}
		
		int base = EntRefToEntIndex( g_iHomingBaseOwner[missile] );
		if( base > MaxClients )
		{
			if( g_iHomingBaseTarget[base][missile] == -1 )
			{
				float pos[3];
				GetEntOrigin( missile, pos, 0.0 );

				// distance between the vertical missile to his own HomingBase on the ground.
				float dist = pos[2] - g_fHomingBaseHeight[missile];
				
				// min height reached, search for target
				if( dist >= HOMING_HEIGHT_MIN )
				{
					int target = -1;
					int entcount = GetEntityCount();
					int i;
					char clname[32];
					
					for( i = 1; i <= entcount; i++ )
					{
						if( i <= MaxClients )
						{
							if( IsValidInfected( i ) && IsPlayerAlive( i ))
							{
								// find SI and tank first and check if has been targeted
								if( GetZclass( i ) == ZOMBIE_TANK		|| GetZclass( i ) == ZOMBIE_SMOKER ||
									GetZclass( i ) == ZOMBIE_BOOMER		|| GetZclass( i ) == ZOMBIE_HUNTER ||
									GetZclass( i ) == ZOMBIE_SPITTER	|| GetZclass( i ) == ZOMBIE_JOCKEY ||
									GetZclass( i ) == ZOMBIE_CHARGER )
								{
									target = HomingCompareTarget( missile, i );
								}
								
								if( target != -1 )
								{
									break;
								}
							}
						}
						else
						{
							if( IsValidEntity( i ))
							{
								// no SI either.. so look for Witch or infected.
								GetEntityClassname( i, clname, sizeof( clname ));
								if( StrEqual( clname, "witch", false ) || StrEqual( clname, "infected", false ))
								{
									target = HomingCompareTarget( missile, i );
								}
								
								if( target != -1 )
								{
									break;
								}
							}
						}
					}
					
					if( target == -1 && g_bAllowTargetSelf )
					{
						// still no target, we sent the missile to the owner
						int client = GetOwner( missile );
						if( IsValidSurvivor( client ) && IsPlayerAlive( client ))
						{
							target = client;
						}
						else
						{
							// missile owner died, rage quit, disconnect? we sent the missile to the random survivor.
							// this always true because the round end if all survivor died or gone.
							int count = 0;
							int bff[MAXPLAYERS+1];
							
							for( i = 1; i <= MaxClients; i++ )
							{
								if( IsValidSurvivor( i ) && IsPlayerAlive( i ))
								{
									bff[count] = i;
									count++;
								}
							}
							count--;
							target = bff[ GetRandomInt( 0, count ) ];
						}
					}
					
					if( target != -1 )
					{
						// Store our target in the missile own base buffer so we can keep track
						// this particular base target and bypass it for another missile originated from the same base/family.
						// At the same time other base with it own missile family will not see this target and may populate it
						// for his own family taget collection. This is useful if multiple homing missile deployed.
						// Note to self: GsiX << dont fix or change something that aint broken. if it work as intended, it work << you bug producer.
						g_iHomingBaseTarget[base][missile] = target;
						
						//PrintToChatAll( "[MISSILE%d]: Found a target \x04%d", missile, target );
						
						// found a target, change direction and shoot it.
						float pos_target[3];
						GetEntOrigin( target, pos_target, 10.0 );				// 10.0 we dont target his leg
						ChangeDirectionAndShoot( missile, pos_target, MISSILE_TARGET_SPEED, -90.0 ); // -90.0 is the molotov body pitch correvtion 
						return Plugin_Stop;
					}
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Stop;
}

public void EVENT_ReviveSuccsess( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable || !g_bAllowHealAnimate ) return;

	int userid = event.GetInt( "subject" );
	int client = GetClientOfUserId( userid );
	if( IsValidSurvivor( client ))
	{
		bool isledge = event.GetBool( "ledge_hang" );
		if( isledge && PDClientLuffy[client].bIsHPInterrupted )
		{
			PDClientLuffy[client].bIsHPInterrupted = false;
			SetPlayerHealth( client, PDClientLuffy[client].iCleintHPHealth );
			SetPlayerHealthBuffer( client, PDClientLuffy[client].fCleintHPBuffer );
			PDClientLuffy[client].hHealthRegen = CreateTimer( 0.1, Timer_LuffyHealth, userid, TIMER_REPEAT );
		}
	}
}

public void EVENT_PlayerUse( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;
	
	int  client = GetClientOfUserId( event.GetInt( "userid" ));
	if ( IsValidSurvivor( client ) && !IsFakeClient( client ) && g_bAllowAmmoboxTweak )
	{
		int  item = event.GetInt( "targetid" );
		if( item > MaxClients && IsValidEntity( item ))
		{
			char entname[64];
			int pos = CompareWeaponDropBuffer( item );
			if( pos != -1 )
			{
				GetEntityClassname( item, entname, sizeof( entname ));
				if ( StrEqual( entname, "upgrade_laser_sight", false ))
				{
					RemoveEntity_Kill( item );
					g_iWeaponDropBuffer[pos] = -1;
				}
				else if ( StrEqual( entname, "weapon_ammo_spawn", false ) && RestockPrimaryAmmo( client, 1 ))
				{
					RemoveEntity_Kill( item );
					g_iWeaponDropBuffer[pos] = -1;
				}
			}
		}
	}
}

public void EVENT_UpgradePackAdded( Event event, const char[] name, bool dontBroadcast ) //<< ok  ====================== this need fix, destroy only our own spawn ent.
{
	if ( !g_bLuffyEnable ) return;
	
	int  client	= GetClientOfUserId( event.GetInt( "userid" ));
	if ( IsValidSurvivor( client ) && !IsFakeClient( client ))
	{
		// destroy ammo explosive, fire and laser after human player pickup.
		int  item = event.GetInt( "upgradeid" );
		if ( item != -1 )
		{
			RemoveEntity_Kill( item );
		}
	}
}

public void EVENT_PlayerHurt( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;
	
	int  client		= GetClientOfUserId( event.GetInt( "userid" ));
	int  attacker	= GetClientOfUserId( event.GetInt( "attacker" ));
	if ( IsValidInfected( client ) && IsValidSurvivor( attacker ))
	{
		if ( PDClientLuffy[attacker].iLuffyType == TYPE_SHIELD )
		{
			SetupBloodSpark( client );
		}
	}
}

public void EVENT_InfectedHurt( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable ) return;
	
	int  infected = GetClientOfUserId( event.GetInt( "entityid" ));
	int  attacker = GetClientOfUserId( event.GetInt( "attacker" ));
	if ( IsValidSurvivor( attacker ) && infected > MaxClients && IsValidEntity( infected ))
	{
		if ( PDClientLuffy[attacker].iLuffyType == TYPE_SHIELD )
		{
			char className[16];
			GetEntityClassname( infected, className, sizeof( className ));
			if( StrEqual( className, "witch", false ))
			{
				SetupBloodSpark( infected );
			}
			else if( StrEqual( className, "infected", false ))
			{
				EmitSoundToAll( SND_GETHIT, infected, SNDCHAN_AUTO );
			}
		}
	}
}

public void EVENT_PlayerJump( Event event, const char[] name, bool dontBroadcast )
{
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if( IsValidSurvivor( client ))
	{
		GetEntOrigin( client, PDClientLuffy[client].fPosJump, 0.0 );
	}
}

public void EVENT_HealBegin( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable || !g_bAllowHealAnimate ) return;
	
	int  client = GetClientOfUserId( event.GetInt( "subject" ));
	if ( IsValidSurvivor( client ))
	{
		// lets animate the heal.
		// capture player health and health buffer from pill or syrange
		PDClientLuffy[client].bIsHPInterrupted = false;
		PDClientLuffy[client].iCleintHPHealth = GetPlayerHealth( client );
		PDClientLuffy[client].fCleintHPBuffer = GetPlayerHealthBuffer( client );
		if ( PDClientLuffy[client].iCleintHPHealth < 10 )
		{
			PDClientLuffy[client].iCleintHPHealth = 10;
		}
	}
}

public void EVENT_HealSuccess( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_bLuffyEnable || !g_bAllowHealAnimate ) return;
	
	int userid = event.GetInt( "subject" );
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if ( PDClientLuffy[client].iCleintHPHealth > 0 )
		{
			// restore the health and healt buffer we capture earlier
			SetPlayerHealth( client, PDClientLuffy[client].iCleintHPHealth );
			SetPlayerHealthBuffer( client, PDClientLuffy[client].fCleintHPBuffer );
			
			PDClientLuffy[client].bIsHPInterrupted = false;
			PDClientLuffy[client].hHealthRegen	= CreateTimer( 0.1, Timer_LuffyHealth, userid, TIMER_REPEAT );
			PDClientLuffy[client].iCleintHPHealth	= 0;
			PDClientLuffy[client].fCleintHPBuffer	= 0.0;
		}
	}
}


/////////////////////////////////////////////////////////////
//======================= Function ========================//
/////////////////////////////////////////////////////////////
void RunHomingMissile( int client, int ammobox )
{
	float boxpos[3];
	float boxang[3];
	GetEntOrigin( ammobox, boxpos, 0.0 );
	GetEntAngle( ammobox, boxang, 0.0, 0 );

	// lunch missile.....
	int entity = CreatEntRenderModel( PROPTYPE_DYNAMIC, g_sModelBuffer[ePOS_HOMING], boxpos, boxang, 2.0 );
	if( entity != -1 )
	{
		SetOwner( entity, client );
		
		int  miss = g_iHomingNum;
		if( !g_bBypassMissileCap )
		{
			if ( miss < 1 ) miss = 1;
			if ( miss > 1000 ) miss = 1000;
		}
		
		float diff = 0.0;
		for( int i = 1; i <= miss; i ++ )
		{
			CreateTimer( diff, Timer_HomingBaseLaunch, EntIndexToEntRef( entity ), TIMER_FLAG_NO_MAPCHANGE );
			diff += HOMING_INTERVAL;
		}
		
		diff += 2.0;
		CreateTimer( diff, Timer_HomingBaseLife, EntIndexToEntRef( entity ), TIMER_FLAG_NO_MAPCHANGE );
		
		// track our HomingBase z pos.
		g_fHomingBaseHeight[entity] = boxpos[2];
		PDClientLuffy[client].bHomingBTN = false;
	}
}

void RollLuffyDropDice( int client )
{
	int drop = true;
	float pos_infected[3];
	float pos_survivor[3];
	GetEntOrigin( client, pos_infected, 0.0 );
	
	// drop luffy item unless its too close to survivor
	for ( int  i = 1; i <= MaxClients; i ++ )
	{
		if ( IsValidSurvivor( i ))
		{
			GetEntOrigin( i, pos_survivor, 0.0 );
			if ( GetVectorDistance( pos_infected, pos_survivor ) <= 30.0 )
			{
				if( IsFakeClient( i ) && !g_bAllowBotPickUp ) { continue ;}

				drop = false;
				break;
			}
		}
	}

	if ( drop && GetRandomInt( 1, 100 ) <= g_iLuffyChance )
	{
		// option 1 = drop luffy item with selected model type.
		// option 2 = drop luffy item with random model type.
		// option 3 = drop ammobox. << this should have lifespan to prevent our server from flooded with ammobox.

		int modeltype		= 0;
		bool israndommodel	= true;
		bool candropluffy	= false;
		
		// determind which luffy drop type we get.
		// this while loop with GetRandomInt inside is damn expensive.
		// to avoid this we need timer to free this death event from while loop. 
		// but that gonna drag our drop interval chance between kill a bit longer. << not gonna do timer for this. i m done saving just a fraction of server preformance improvement.
		// update: for fakkk shake just do a random interger without while loop.... << Note to self >> do this next time you make an update.
		// update2: problem is we getting almost same chances every time. the random interger is not really random. << get a decision on this.
		
		while( g_iDropSelectionType[0] == g_iDropSelectionType[1] || g_iDropSelectionType[0] == g_iDropSelectionType[2] )
		{
			g_iDropSelectionType[0] = GetRandomInt( 1, 5 );
		}
		g_iDropSelectionType[2] = g_iDropSelectionType[1];
		g_iDropSelectionType[1] = g_iDropSelectionType[0];
		
		if( g_iDropSelectionType[0] > 3 )
		{
			modeltype		= g_iLuffyModelSelection[0];
			israndommodel	= false;	// this drop type not a random model
			candropluffy	= true;		// we allowed to drop luffy item
		}
		else if( g_iDropSelectionType[0] == 3 )
		{
			// model selection dont matter here. its random in timer
			candropluffy = true;	//we can drop
		}
		else
		{
			char ammoname[64];
			if( GetRandomInt( 1, 2 ) == 1 )
			{
				Format( ammoname, sizeof( ammoname ), "weapon_upgradepack_explosive" );
			}
			else
			{
				Format( ammoname, sizeof( ammoname ), "weapon_upgradepack_incendiary" );
			}
			
			int ammobox = GivePlayerItems( client, ammoname );
			if( ammobox != -1 )
			{
				// kill this ammobox to prevent out server flooded.
				CreateTimer( AMMOBOX_LIFE, Timer_AmmoBoxlife, EntIndexToEntRef( ammobox ), TIMER_FLAG_NO_MAPCHANGE );
			}
		}
		
		if( candropluffy )
		{
			float pos_world[3];
			float ang_world[3] = { 0.0, 0.0, 0.0 };
			GetEntOrigin( client, pos_world, 20.0 );

			// a dummy detect player touch
			int dummy = CreateEntParent( DMY_SDKHOOK, pos_world, ang_world, g_fModelScale[ePOS_SDKHOOK] );
			if( dummy > MaxClients && IsValidEntity( dummy ))
			{
				float pos_parent[3] = { 0.0, 0.0, 0.0 };
				
				// a decoy skin.. what player actualy see but cant touch
				int skin = CreatEntChild( dummy, g_sModelBuffer[modeltype], pos_world, pos_parent, ang_world, g_fModelScale[modeltype] );
				if( skin > MaxClients && IsValidEntity( skin ))
				{
					EMLuffyDrop[dummy].iSelf = EntIndexToEntRef( dummy );
					EMLuffyDrop[dummy].iChild = EntIndexToEntRef( skin );
					EMLuffyDrop[dummy].SaveModel( g_sModelBuffer[modeltype], g_fModelScale[modeltype] );

					if( g_bShowDummyModel )
					{
						ToggleGlowEnable( dummy, true );
					}
					else
					{
						SetRenderColour( dummy, g_iColor_White, 0 );	// make our dummy invisible
					}
					
					ToggleGlowEnable( skin, true );
					SDKHook( dummy, SDKHook_StartTouchPost, OnLuffyObjectTouch );
					
					float life = g_fLuffyItemLife;
					if ( life > 300.0 ) life = 300.0;
					if ( life < 10.0 ) life = 10.0;
				
					g_iLuffySpawnCount++;
					EMLuffyDrop[dummy].bIsRandom	= israndommodel;
					EMLuffyDrop[dummy].fLife = life;
					EMLuffyDrop[dummy].hTimer = CreateTimer( 0.1, Timer_LuffySpawnLife, EntIndexToEntRef( dummy ), TIMER_REPEAT );
					
					if( !israndommodel )
					{
						// determine which model to drop next ahead of time after
						
						g_bSafeToRollNextDiceModel = false;
						// create this timer to free EVENT_PlayerDeath and EVENT_WitchDeath out of while loop;
						CreateTimer( 0.05, Timer_ScrambleModelSelectionDice, 0, TIMER_FLAG_NO_MAPCHANGE );
					}
				}
				else
				{
					RemoveEntity( dummy );
				}
			}
		}
	}
}

int HomingCompareTarget( int missile, int target )
{
	int base = EntRefToEntIndex( g_iHomingBaseOwner[missile] );
	if( base > MaxClients )
	{
		// check if the target not targeted. return -1 for already targeted.
		for( int j = 0; j < sizeof( g_iHomingBaseTarget[] ); j++ )
		{
			if( g_iHomingBaseTarget[base][j] != -1 )
			{
				if( g_iHomingBaseTarget[base][j] == target )
				{
					return -1;
				}
			}
		}
	}
	return target;
}

void ResetLuffyAbility( int client )
{
	DeletePlayerShield( client );
	
	PDClientLuffy[client].fAbilityCountdown = 0.0;
	PDClientLuffy[client].fClientTimeBuffer = 0.0;
	PDClientLuffy[client].iHintCountdown = 0;
	
	SetEntityGravity( client, 1.0 );
	SetEntProp( client, Prop_Data, "m_takedamage", 2, 1 );
	SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0 );

	SetRenderColour( client, g_iColor_White, 255 );
}

void DropRandomWeapon( int client, int selection )
{
	int  r;
	switch( selection )
	{
		case 0:
		{
			r = GetRandomInt( 1, 6 ); // t1 selection
		}
		case 1:
		{
			r = GetRandomInt( 7, 17 ); // t2 selection
		}
		case 2:
		{
			r = GetRandomInt( 1, 17 ); // t1 and t2 selection
		}
	}
	
	switch( r )
	{
		// T1 weapon
		case 1:
		{
			GivePlayerItems( client, "weapon_smg" );
		}
		case 2:
		{
			GivePlayerItems( client, "weapon_smg_silenced" );
		}
		case 3:
		{
			GivePlayerItems( client, "weapon_smg_mp5" );
		}
		case 4:
		{
			GivePlayerItems( client, "weapon_pumpshotgun" );
		}
		case 5:
		{
			GivePlayerItems( client, "weapon_shotgun_chrome" );
		}
		case 6:
		{
			GivePlayerItems( client, "weapon_hunting_rifle" );
		}
		// T2 weapon
		case 7:
		{
			GivePlayerItems( client, "weapon_rifle_m60" );
		}
		case 8:
		{
			GivePlayerItems( client, "weapon_grenade_launcher" );
		}
		case 9:
		{
			GivePlayerItems( client, "weapon_rifle" );
		}
		case 10:
		{
			GivePlayerItems( client, "weapon_rifle_ak47" );
		}
		case 11:
		{
			GivePlayerItems( client, "weapon_rifle_desert" );
		}
		case 12:
		{
			GivePlayerItems( client, "weapon_rifle_sg552" );
		}
		case 13:
		{
			GivePlayerItems( client, "weapon_shotgun_spas" );
		}
		case 14:
		{
			GivePlayerItems( client, "weapon_autoshotgun" );
		}
		case 15:
		{
			GivePlayerItems( client, "weapon_sniper_scout" );
		}
		case 16:
		{
			GivePlayerItems( client, "weapon_sniper_military" );
		}
		default:
		{
			GivePlayerItems( client, "weapon_sniper_awp" );
		}
	}
}

int GivePlayerItems( int client, const char[] item_name )
{
	bool glow = true;
	char name_buffer[32];
	float z_pos = 30.0;
	
	if ( StrEqual( item_name, "weapon_rifle_m60", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle M60" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, SND_REWARD );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_grenade_launcher", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Grenade Launcher" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, SND_REWARD );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_rifle", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle M16" );
	}
	else if ( StrEqual( item_name, "weapon_rifle_ak47", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle AK47" );
	}
	else if ( StrEqual( item_name, "weapon_rifle_desert", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle Desert" );
	}
	else if ( StrEqual( item_name,"weapon_rifle_sg552", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Rifle SG552" );
	}
	else if ( StrEqual( item_name, "weapon_shotgun_spas", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Shotgun SPAS" );
	}
	else if ( StrEqual( item_name, "weapon_autoshotgun", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Auto Shotgun" );
	}
	else if ( StrEqual( item_name, "weapon_sniper_awp", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Sniper AWP" );
	}
	else if ( StrEqual( item_name, "weapon_sniper_military", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Sniper Military" );
	}
	else if ( StrEqual( item_name, "weapon_sniper_scout", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Sniper Scout" );
	}
	else if ( StrEqual( item_name, "weapon_hunting_rifle", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Hunting Rifle" );
	}
	else if ( StrEqual( item_name, "weapon_shotgun_chrome", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Shotgun Chrome" );
	}
	else if ( StrEqual( item_name, "weapon_pumpshotgun", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "Pump Shotgun" );
	}
	else if ( StrEqual( item_name, "weapon_smg", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "SMG" );
	}
	else if ( StrEqual( item_name, "weapon_smg_silenced", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "SMG Silenced" );
	}
	else if ( StrEqual( item_name, "weapon_smg_mp5", false ))
	{
		glow = false;
		Format( name_buffer, sizeof( name_buffer ), "SMG MP5" );
	}
	else if ( StrEqual( item_name, "weapon_upgradepack_explosive", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Explosive Box" );
	}
	else if ( StrEqual( item_name, "weapon_upgradepack_incendiary", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Incendiary Box" );
	}
	else if ( StrEqual( item_name, "weapon_first_aid_kit", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "First Aid Kit" );
	}
	else if ( StrEqual( item_name, "weapon_defibrillator", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Defibrillator" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, SND_REWARD );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_pipe_bomb", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Pipe Bomb" );
	}
	else if ( StrEqual( item_name, "weapon_molotov", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Molotove" );
	}
	else if ( StrEqual( item_name, "weapon_vomitjar", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Vomit Jar" );
	}
	else if ( StrEqual( item_name, "weapon_pain_pills", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Pain Pill" );
	}
	else if ( StrEqual( item_name, "weapon_adrenaline", false ))
	{
		Format( name_buffer, sizeof( name_buffer ), "Adrenaline Syrange" );
	}
	else if ( StrEqual( item_name, "upgrade_laser_sight", false ))
	{
		z_pos = 0.0;
		Format( name_buffer, sizeof( name_buffer ), "Upgrade Laser Sight" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, SND_REWARD );	// the witch cant hear this
		}
	}
	else if ( StrEqual( item_name, "weapon_ammo_spawn", false ))
	{
		z_pos = 0.0;
		Format( name_buffer, sizeof( name_buffer ), "Ammo Pile" );
		if( client <= MaxClients )
		{
			EmitSoundToClient( client, SND_REWARD );	// the witch cant hear this
		}
	}
	
	float pos[3];
	float ang[3];
	GetEntOrigin( client, pos, z_pos );
	GetEntAngle( client, ang, 0.0, 0 );
	
	int  entity = CreateWeaponEntity( item_name, pos, ang );
	if( entity != -1 )
	{
		int  wp = GetEmptyWeaponDropBuffer();
		if ( wp != -1 )
		{
			g_iWeaponDropBuffer[wp] = EntIndexToEntRef( entity );
		}
		
		if ( glow )
		{
			ToggleGlowEnable( entity, true );
		}
		
		if ( g_bHinttext && client <= MaxClients )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04%s", name_buffer );	// the witch cant read this
		}
	}
	else
	{
		PrintToServer( "|LUFFY| GivePlayerItems() failed.. check your spelling |LUFFY|" );
	}
	return entity;
}

int GetEmptyWeaponDropBuffer()
{
	for( int  i = 0; i < SIZE_DROPBUFF; i++ )
	{
		if ( g_iWeaponDropBuffer[i] == -1 )
		{
			return i;
		}
	}
	return -1;
}

int CompareWeaponDropBuffer( int entity )
{
	int item;
	for( int  i = 0; i < SIZE_DROPBUFF; i++ )
	{
		if ( g_iWeaponDropBuffer[i] != -1 )
		{
			item = EntRefToEntIndex( g_iWeaponDropBuffer[i] );
			if( item != -1 && item == entity )
			{
				return i;
			}
		}
	}
	return -1;
}

void SetupBloodSpark( int client )
{
	float pos[3];
	for ( int  i = 0; i <= 5; i++ )
	{
		// make our sprite appear random position near player
		GetEntOrigin( client, pos, GetRandomFloat( 10.0, 80.0 ));
		pos[0] += GetRandomFloat( -30.0, 30.0 );
		pos[1] += GetRandomFloat( -30.0, 30.0 );
		
		int color[4];
		int alpha = 80;
		switch( GetRandomInt( 1, 6 ))
		{
			case 1:
			{
				CopyColor_SetAlpha( g_iColor_Red, color, alpha );
			}
			case 2:
			{
				CopyColor_SetAlpha( g_iColor_Green, color, alpha );
			}
			case 3:
			{
				CopyColor_SetAlpha( g_iColor_Blue, color, alpha );
			}
			case 4:
			{
				CopyColor_SetAlpha( g_iColor_LGreen, color, alpha );
			}
			case 5:
			{
				CopyColor_SetAlpha( g_iColor_Pinky, color, alpha );
			}
			case 6:
			{
				CopyColor_SetAlpha( g_iColor_Yellow, color, alpha );
			}
		}
		
		TE_SetupBloodSprite( pos, NULL_VECTOR, color, GetRandomInt( 20, 60 ), g_iBeamSprite_Blood, g_iBeamSprite_Blood );
		TE_SendToAll();
		
		// random to make it sound appealing
		switch( GetRandomInt( 1, 3 )) {
			case 1: {
				EmitSoundToAll( SND_ZAP_1, client, SNDCHAN_AUTO );
			}
			case 2: {
				EmitSoundToAll( SND_ZAP_2, client, SNDCHAN_AUTO );
			}
			case 3: {
				EmitSoundToAll( SND_ZAP_3, client, SNDCHAN_AUTO );
			}
		}
	}
}

void ToggleGlowEnable( int entity, bool enable )
{
	int  m_glowtype = 0;
	int  m_glowcolor = 0;
	
	if ( enable )
	{
		m_glowtype = 3;
		
		int select;
		int color_rgb[3];

		int glow_type = g_iItemGlowType;
		if ( glow_type < 1 || glow_type > 6 )
		{
			glow_type = 6;
		}
		
		if ( glow_type == 6 )
		{
			select = GetRandomInt( 1, 5 );
		}
		else
		{
			select = glow_type;
		}
		
		switch( select )
		{
			case 1:
			{
				CopyColor( g_iColor_Red, color_rgb );
			}
			case 2:
			{
				CopyColor( g_iColor_Green, color_rgb );
			}
			case 3:
			{
				CopyColor( g_iColor_Blue, color_rgb );
			}
			case 4:
			{
				CopyColor( g_iColor_Pinky, color_rgb );
			}
			case 5:
			{
				CopyColor( g_iColor_Yellow, color_rgb );
			}
		}
		m_glowcolor = color_rgb[0] + ( color_rgb[1] * 256 ) + ( color_rgb[2] * 65536 );
	}
	SetEntProp( entity, Prop_Send, "m_iGlowType", m_glowtype );
	SetEntProp( entity, Prop_Send, "m_nGlowRange", 0 );
	SetEntProp( entity, Prop_Send, "m_glowColorOverride", m_glowcolor );
}

void CheatCommand( int client, const char[] cheats, const char[] command )
{
	if ( StrContains( command, "witch auto", false ) != -1 )
	{
		if( FindEntityAndCount( -1, "Witch" ) < g_iWitchMax )
		{
			EmitSoundToClient( client, SND_WITCH );
			if ( g_bAllowMessage == true ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Luffy Witch!!", client );
		}
		else
		{
			return;
		}
	}
	else if ( StrContains( command, "tank auto", false ) != -1 )
	{
		if( FindEntityAndCount( -1, "Tank" ) < g_iTankMax )
		{
			EmitSoundToClient( client, SND_TANK );
			if ( g_bAllowMessage == true ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Luffy Tank!!", client );
		}
		else
		{
			return;
		}
	}
	else if ( StrContains( cheats, "director_force_panic_event", false ) != -1 )
	{
		if ( g_bAllowMessage == true ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Luffy Panic!!", client );
	}
	
	int  userflags = GetUserFlagBits( client );
	int  cmdflags = GetCommandFlags( cheats );
	
	
	SetUserFlagBits( client, ADMFLAG_ROOT );
	SetCommandFlags( cheats, cmdflags & ~FCVAR_CHEAT );
	FakeClientCommand( client,"%s %s", cheats, command );
	SetCommandFlags( cheats, cmdflags );
	SetUserFlagBits( client, userflags );
}

int FindEntityAndCount( int client, const char[] _findWhat )
{
	int  scan = 0;
	if ( StrEqual( _findWhat, "Tank", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetZclass( i ) == ZOMBIE_TANK )
				{
					scan += 1;
				}
			}
		}
	}
	else if ( StrEqual( _findWhat, "Witch", false ))
	{
		char _name[64];
		int  _max	= GetEntityCount();
		for ( int  i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEntityClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != -1 )
				{
					//if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )	//<< this check will crash the server
					//{
						scan += 1;
					//}
				}
			}
		}
	}
	else if ( StrEqual( _findWhat, "Survivor", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidSurvivor( i ) && i != client )
			{
				scan += 1;
				break;
			}
		}
	}
	return scan;
}

bool RestockPrimaryAmmo( int client, int multiplayer )
{
	char weapon_name[64];
	int weapon = GetPlayerWeaponSlot( client, 0 );
	if( weapon > MaxClients && IsValidEntity( weapon ))
	{
		GetEntityClassname( weapon, weapon_name, sizeof( weapon_name ));
		int  ammoStock	= GetGameMaxAmmo( weapon );
		if ( ammoStock > 0 )
		{
			ammoStock *= multiplayer;
			int  iPrimType = GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType");
			SetEntProp( client, Prop_Send, "m_iAmmo", ammoStock, _, iPrimType );
			EmitSoundToClient( client, SND_AMMOPICKUP );
			return true;
		}
	}
	return false;
}

int GetGameMaxAmmo( int weapon )
{
	char weapon_name[64];
	GetEntityClassname( weapon, weapon_name, sizeof( weapon_name ));
	int  ammoStock	= -1;

	if ( StrEqual( weapon_name, "weapon_rifle_m60", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_m60_max" ));
	}
	else if ( StrEqual( weapon_name, "weapon_grenade_launcher", false )) {
		ammoStock = GetConVarInt( FindConVar("ammo_grenadelauncher_max"));
	}
	else if ( StrEqual( weapon_name, "weapon_rifle", false ) || StrEqual( weapon_name, "weapon_rifle_ak47", false ) || StrEqual( weapon_name, "weapon_rifle_desert", false ) || StrEqual( weapon_name,"weapon_rifle_sg552", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_assaultrifle_max" ));
	}
	else if ( StrEqual( weapon_name, "weapon_shotgun_spas", false ) || StrEqual( weapon_name, "weapon_autoshotgun", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_autoshotgun_max" ));
	}
	else if ( StrEqual( weapon_name, "weapon_sniper_awp", false ) || StrEqual( weapon_name, "weapon_sniper_military", false ) || StrEqual( weapon_name, "weapon_sniper_scout", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_sniperrifle_max" ));
	}
	else if ( StrEqual( weapon_name, "weapon_hunting_rifle", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_huntingrifle_max" ));
	}
	else if ( StrEqual( weapon_name, "weapon_shotgun_chrome", false ) || StrEqual( weapon_name, "weapon_pumpshotgun", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_shotgun_max" ));
	}
	else if ( StrEqual( weapon_name, "weapon_smg", false ) || StrEqual( weapon_name, "weapon_smg_silenced", false ) || StrEqual( weapon_name, "weapon_smg_mp5", false )) {
		ammoStock = GetConVarInt( FindConVar( "ammo_smg_max" ));
	}
	return ammoStock;
}

void PCMasterRace_Render_ARGB( int client, int alpha )
{
	// gamers.. i give ya a real rgb in l4d2 special for that expensive pc build..
	switch( GetRandomInt( 1, 3 ))
	{
		case 1:
		{
			SetupShieldDorm( client, g_iColor_Blue, (SHIELD_DORM_RADIUS - 100), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Green, (SHIELD_DORM_RADIUS - 50), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Red, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, alpha );
		}
		case 2:
		{
			SetupShieldDorm( client, g_iColor_Red, (SHIELD_DORM_RADIUS - 100), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Blue, (SHIELD_DORM_RADIUS - 50), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Green, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, alpha );
		}
		case 3:
		{
			SetupShieldDorm( client, g_iColor_Green, (SHIELD_DORM_RADIUS - 100), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Red, (SHIELD_DORM_RADIUS - 50), g_iBeamSprite_Bubble, alpha );
			SetupShieldDorm( client, g_iColor_Blue, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, alpha );
		}
	}
}

void CreateShieldPush( int client, int target, float force )
{
	float pos_client[3];
	float pos_target[3];
	float vel_target[3];
	float ang_target[3];
	GetEntOrigin( client, pos_client, 0.0 );
	GetEntOrigin( target, pos_target, 0.0 );
	
	MakeVectorFromPoints( pos_client, pos_target, vel_target );
	GetVectorAngles( vel_target, ang_target );
	ang_target[0] -= 20.0;												// redirect him to the air, slightly
	GetAngleVectors( ang_target, vel_target, NULL_VECTOR, NULL_VECTOR );	// recalculate the velocity.
	NormalizeVector( vel_target, vel_target );
	ScaleVector( vel_target, force );
	TeleportEntity( target, NULL_VECTOR, NULL_VECTOR, vel_target );
	
	if( target <= MaxClients )
	{
		// if we cant push them, then kill the attacker
		bool isluck = false;
		if ( GetEntProp( client, Prop_Send, "m_tongueOwner" ) > 0 && GetZclass( target ) == ZOMBIE_SMOKER )
		{
			isluck = true;
			SetEntityMoveType( target, MOVETYPE_NOCLIP );
			CreateTimer( 0.1, Timer_RestoreCollution, GetClientUserId( target ));
		}
		else if( GetEntPropEnt( client, Prop_Send, "m_pounceAttacker" ) > 0 && GetZclass( target ) == ZOMBIE_CHARGER )
		{
			isluck = true;
			CheatCommand( target, "kill", "" );
		}
		else if ( GetEntPropEnt( client, Prop_Send, "m_jockeyAttacker" ) > 0 && GetZclass( target ) == ZOMBIE_JOCKEY )
		{
			isluck = true;
			CheatCommand( target, "dismount", "" );
		}
		
		if( isluck )
		{
			EmitSoundToClient( client, SND_HEALTH );
			if ( g_bHinttext )
			{
				PrintHintText( client, "++ You freed from %N ++", target );
			}
		}
	}
	
	// this is the section causing player screen to black out for the dying animation loop and cause them stuck with it untill client game restart.
	// never occour to me that someone actualy have the balls to stand on top of 10 boxes of fire cracker next to 10 gallon of gascan stack together.
	// we are going to fix him with 200 health buff aka half god mode. << in theory, this bug only happen to clock ability since the shield practilly immortal/god mode.
	if ( IsPlayerIncap( client ))
	{
		ResetPlayerIncap( client );
		CheatCommand( client, "give", "health" );
		SetPlayerHealthBuffer( client, 200.0 );		// give himm 200 health buff to break the incap loop. 100 buff will do but 20 flameable prop give us a lil concern.
		SetPlayerHealth( client, 1 );
		PrintHintText( client, "++ You recovered from Incap ++" );
	}
	else if(  IsPlayerLedge( client ))
	{
		ResetPlayerLedge( client );
	}
}

void SetTeleport( int client, const char[] who )
{
	// if my memory serve me well, the witch and/or Tank in the map cause problem to our plugin. Cant recall what it is.
	// comment this out and debug yourself to findout.
	if ( StrContains( g_sCURRENT_MAP, "c5m2", false ) != -1 )
	{
		if ( StrEqual( who, "Witch", false ) || StrEqual( who, "Tank", false ))
		{
			if ( g_bHinttext )
			{
				PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You found \x05Empty Luffy!!" );
			}
			return;
		}
	}
	
	int  scan = -1;
	
	if ( StrEqual( who, "Tank", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetZclass( i ) == ZOMBIE_TANK )
				{
					scan = i;
					break;
				}
			}
		}
	}
	else if ( StrEqual( who, "Witch", false ))
	{
		char _name[64];
		int  _max	= GetEntityCount();
		for ( int  i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEntityClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != -1 )
				{
					//if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )	//<< this could be wrong/crashing the server <<< note to self >> test this
					//{														// update: ya.. checked my witch plugins, it will crash the server.
						scan = i;											// so we dont check her health... just teleport.
						break;
					//}
				}
			}
		}
	}
	else if ( StrEqual( who, "Infected", false ))
	{
		for ( int  i = MaxClients; i <= 1; i-- )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				scan = i;
				break;
			}
		}
	}
	else if ( StrEqual( who, "Survivor", false ))
	{
		for ( int  i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidSurvivor( i ) && i != client )
			{
				scan = i;
				break;
			}
		}
	}

	if ( scan == -1 )
	{
		
		if ( StrContains( who, "Survivor", false ) != -1 )
		{
			switch( GetRandomInt( 1, 3 ))
			{
				case 1: { GivePlayerItems( client, "weapon_defibrillator" );	}
				case 2: { GivePlayerItems( client, "weapon_pain_pills" );		}
				case 3: { GivePlayerItems( client, "weapon_adrenaline" );		}
			}
		}
		// we cant teleport him to tank, witch or infected, give him 1 instead.
		else if ( StrContains( who, "Tank", false ) != -1 )
		{
			CheatCommand( client, "z_spawn", "tank auto" );						// we cant teleport him to the tank, then give tank next to him.
		}
		else if ( StrContains( who, "Witch", false ) != -1 )
		{
			CheatCommand( client, "z_spawn", "witch auto" );					// we cant teleport him to the witch, then give witch next to him.
		}
		else if ( StrContains( who, "Infected", false ) != -1 )
		{
			switch( GetRandomInt( 1, 6 ))
			{
				case 1: { CheatCommand( client, "z_spawn", "smoker auto" ); }	// we cant teleport him to any SI, then give 1 next to him.
				case 2: { CheatCommand( client, "z_spawn", "boomer auto" ); }
				case 3: { CheatCommand( client, "z_spawn", "hunter auto" ); }
				case 4: { CheatCommand( client, "z_spawn", "spitter auto" ); }
				case 5: { CheatCommand( client, "z_spawn", "jockey auto" ); }
				case 6: { CheatCommand( client, "z_spawn", "charger auto" ); }
			}
		}
	}
	else
	{
		float _location[3];
		GetEntOrigin( scan, _location, 10.0 );
		TeleportEntity( client, _location, NULL_VECTOR, NULL_VECTOR );
		EmitSoundToClient( client, SND_TELEPORT );
		
		if ( g_bHinttext )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy %s Teleport.", who );
		}
	}
}

void SetLuffyClock( int client )	// yellow
{
	int shield = SetupShield( client, SHIELD_TYPE_PUSH, 1 );
	if( shield != -1 )
	{
		EmitSoundToClient( client, SND_CLOCK );
		PDClientLuffy[client].iHintCountdown = g_iClockCoolDown;
		PDClientLuffy[client].fAbilityCountdown = float( g_iClockCoolDown );
		PDClientLuffy[client].fClientTimeBuffer = GetGameTime();
		SetRenderColour( client, g_iColor_Yellow, 220 );
		
		PDClientLuffy[client].iLuffyType = TYPE_CLOCK;
		PDClientLuffy[client].hLuffyTimer = CreateTimer( 0.1, Timer_LuffyClock, GetClientUserId( client ), TIMER_REPEAT );
		
		if ( g_bHinttext )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Clock" );
			PrintHintText( client, "++ Luffy Clock last in %d sec ++", g_iClockCoolDown );
		}
	}
}

void SetLuffySpeed( int client )	// blue
{
	EmitSoundToClient( client, SND_SPEED );
	PDClientLuffy[client].iHintCountdown = g_iSpeedCoolDown;
	PDClientLuffy[client].fAbilityCountdown = float( g_iSpeedCoolDown );
	PDClientLuffy[client].fClientTimeBuffer = GetGameTime();
	
	float speed = ( float( g_iSuperSpeedMax ) / 100.0 ) + 1.0;
	if ( speed > 2.0 ) speed = 2.0;
	if ( speed < 1.0 ) speed = 1.0;
	
	SetEntityGravity( client, 0.8 );
	SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", speed );
	SetRenderColour( client, g_iColor_LBlue, 220 );

	PDClientLuffy[client].iLuffyType = TYPE_SPEED;
	PDClientLuffy[client].hLuffyTimer = CreateTimer( 0.1, Timer_LuffySpeed, GetClientUserId( client ), TIMER_REPEAT );
	
	if ( g_bHinttext )
	{
		PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Speed" );
		PrintHintText( client, "++ Luffy Speed last in %d sec ++", g_iSpeedCoolDown );
	}
}

void SetLuffyShield( int client )	// red
{
	int shield = SetupShield( client, SHIELD_TYPE_DAMAGE, -1 );
	if( shield != -1 )
	{
		SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 ); //<<<< i forget what is this, should be not taking damage. but setting it here is just wrong
		EmitSoundToClient( client, SND_CLOCK );
		
		PDClientLuffy[client].iHintCountdown = g_iShieldCoolDown;
		PDClientLuffy[client].fAbilityCountdown = float( g_iShieldCoolDown );
		PDClientLuffy[client].fClientTimeBuffer = GetGameTime();
		SetRenderColour( client, g_iColor_LRed, 220 );
		
		PDClientLuffy[client].iLuffyType = TYPE_SHIELD;
		PDClientLuffy[client].hLuffyTimer = CreateTimer( 0.1, Timer_LuffyShield, GetClientUserId( client ), TIMER_REPEAT );

		if ( g_bHinttext )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Shield" );
			PrintHintText( client, "++ Luffy Shield last in %d sec ++", g_iShieldCoolDown );
		}
	}
}

void SetLuffyStrength( int client )	// green
{
	EmitSoundToClient( client, SND_STRENGTH );
	PDClientLuffy[client].iHintCountdown = g_iStrengthCoolDown;
	PDClientLuffy[client].fAbilityCountdown = float( g_iStrengthCoolDown );
	SetEntityGravity( client, STRENGTH_GRAVITY );
	SetRenderColour( client,g_iColor_Green, 220 );
	
	float time = GetGameTime();
	PDClientLuffy[client].fClientTimeBuffer		= time;		// check how long since we display message to him
	PDClientLuffy[client].fDoubleDashTimeLast	= time;			// check his double dash key frame
	PDClientLuffy[client].bIsDoubleDashPaused	= false;
	
	PDClientLuffy[client].iLuffyType = TYPE_STRENGTH;
	PDClientLuffy[client].hLuffyTimer = CreateTimer( 0.1, Timer_LuffyStrength, GetClientUserId( client ), TIMER_REPEAT );
	
	if ( g_bHinttext )
	{
		PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Strength" );
		PrintHintText( client, "++ Luffy Strength, press 'MOVE + SPACE' to Dash in midair ++", g_iStrengthCoolDown );
	}
}

void SetLuffyHealth( int client )
{
	EmitSoundToClient( client, SND_HEALTH );
	PDClientLuffy[client].bIsHPInterrupted = false;
	PDClientLuffy[client].hHealthRegen = CreateTimer( 0.1, Timer_LuffyHealth, GetClientUserId( client ), TIMER_REPEAT );
	if ( g_bHinttext )
	{
		PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Luffy Health" );
	}
}

void SetLuffyPunishment( int client )
{
	switch( GetRandomInt( 1, 5 ))
	{
		case 1 : { SetTeleport( client, "Tank" );		}
		case 2 : { SetTeleport( client, "Witch" );		}
		case 3 : { SetTeleport( client, "Infected" );	}
		case 4 : { SetFreeze( client );				}
		case 5 : { SetFreeze( client );				}
	}
}

void SetFreeze( int client )
{
	// froze his button
	PDClientLuffy[client].ButtonFreeze( client );
	
	float playerPos[3];
	GetEntOrigin( client, playerPos, 10.0 );
	switch( GetRandomInt( 1, 2 ))
	{
		case 1:
		{
			// freeze him for 10 second and give him explosion
			PDClientLuffy[client].iUnfreezCountdown = 10;
			switch( GetRandomInt( 1, 2 ))
			{
				case 1: { CreatPointDamageRadius( playerPos, PARTICLE_ELECTRIC1, 30, 300, client ); }
				case 2: { CreatPointDamageRadius( playerPos, PARTICLE_ELECTRIC2, 30, 300, client );	}
			}
			if( PDClientLuffy[client].fAbilityCountdown == 0.0 )		// if player ability still active, we dont spoil/overwrite the color
			{
				SetRenderColour( client, g_iColor_LBlue, 180 );
			}
		}
		case 2:
		{
			// freeze him and give him fire for 3 second
			PDClientLuffy[client].iUnfreezCountdown = 3;
			if( PDClientLuffy[client].fAbilityCountdown == 0.0 )		// if player ability still active, we dont spoil/overwrite the color
			{
				SetRenderColour( client, g_iColor_LRed, 180 );
			}
			CreatPointDamageRadius( playerPos, PARTICLE_CREATEFIRE, 20, 300, client );
		}
	}

	PDClientLuffy[client].hMoveFreeze = CreateTimer( 1.0, Timer_RestoreFrozenButton, GetClientUserId( client ), TIMER_REPEAT );
	EmitSoundToAll( SND_FREEZE, client, SNDCHAN_AUTO );
	PrintHintText( client, "-- You will be unfreze in %d sec --", PDClientLuffy[client].iUnfreezCountdown );
}

int SetupShield( int client, int type, int color )
{
	// shield type 1 = damage
	// shield type 2 = decoration
	// shield type 3 = push
	
	float wPos[3];
	float wAng[3];
	GetEntOrigin( client, wPos, 30.0 );
	GetEntAngle( client, wAng, 0.0, 0 );

	int  wingcenter = CreatEntRenderModel( PROPTYPE_DYNAMIC, DMY_SDKHOOK, wPos, wAng, 0.01 );
	if( wingcenter != -1 )
	{
		if ( g_iShieldType == 0 )
		{
			SetVariantString( "!activator" );
			AcceptEntityInput( wingcenter, "SetParent", client );
			SetVariantString( "spine" );
			AcceptEntityInput( wingcenter, "SetParentAttachment" );
			
			float pos[3] = { 0.0, 0.0, 0.0 };
			float ang[3] = { 0.0, 0.0, -90.0 };
			TeleportEntity( wingcenter, ang, pos, NULL_VECTOR);
		}
		
		SetRenderColour( wingcenter, g_iColor_White, 0 );
		PDClientLuffy[client].iPlayerShield = EntIndexToEntRef( wingcenter );
		
		/// attach the wing here
		int  numberWing;
		if ( type == SHIELD_TYPE_DAMAGE || type == SHIELD_TYPE_PUSH )
		{
			numberWing = 6;		// any number will do. it depend on our taste
			EmitSoundToClient( client, SND_SUPERSHIELD );
		}
		else
		{
			numberWing = 4;		// any number will do. it depend on our taste. this serve as decoration only.
		}
		
		float wingRadius		= SHIELD_RADIUS;				// wide of our wing opening, wing type 1 and 2 may not show correct distance due to its own orientation from parent.
		float incRadius			= 360.0 / float( numberWing );	// calculate space between our wing.
		float wingAngle			= 0.0;							// wing attachment start angle
		float wingFacing		= 90.0;							// manipulate which side of our wing facing
		float wingPosition[3]	= { 0.0, 0.0, 0.0 };			// position of our wing relative to the parent/center/body. whatever the name
		
		bool iswingsuccsess = true;								// check if our creation fully assemble
		int wing;
		// we draw a circle and determine each intersection point/distance for attachment
		for ( int i = 1; i <= numberWing; i ++ )
		{
			wingPosition[0] = wingRadius * Cosine( DegToRad( wingAngle ));	// calculate the intersect between radius and angle
			wingPosition[1] = wingRadius * Sine( DegToRad( wingAngle ));	// calculate the intersect between radius and angle
			
			wing = AttachWing( wingcenter, wPos, wingPosition, wingFacing, type, color );
			if ( wing == -1 )
			{
				PrintToServer( "" );
				PrintToServer( "|LUFFY| Error, wing creation failed |LUFFY|" );
				PrintToServer( "" );
				iswingsuccsess = false;
				break;
			}
			wingAngle	+= incRadius;	// next point attachment
			wingFacing	+= incRadius;	// where should our next wing facing.
		}
		
		// wing creation failed. delete all garbage
		if( !iswingsuccsess )
		{
			// for fail safe check. dont flood our server with garbage.
			DeletePlayerShield( client );
			wingcenter = -1;
		}
	}
	return wingcenter;
}

int AttachWing( int parent, float pos_world[3], float pos_parent[3], float ang_adjustment, int type, int color )
{
	char model[128];
	float scale = g_fModelScale[ePOS_JETF18];
	Format( model, sizeof( model ), g_sModelBuffer[ePOS_JETF18] );

	float buffAng[3] = { 0.0, 0.0, 0.0 };
	if ( type == 1 )
	{
		buffAng[1] = ang_adjustment;
	}
	else if ( type == 2 )
	{
		buffAng[0] = -90.0;
		buffAng[1] = ( ang_adjustment + 90.0 );
	}
	else if ( type == 3 )
	{
		scale = 1.0;
		Format( model, sizeof( model ), MDL_RIOTSHIELD );
		buffAng[1] = ( ang_adjustment - 90.0 );
	}
	
	int  shield = CreatEntChild( parent, model, pos_world, pos_parent, buffAng, scale );
	if ( shield != -1 )
	{
		if ( type == 1 )
		{
			SetRenderColour( shield, g_iColor_White, 100 );
			ToggleGlowEnable( shield, true );
		}
		else if ( type == 2 )
		{
			if ( color == 1 ) SetRenderColour( shield, g_iColor_LRed, 70 );
			if ( color == 2 ) SetRenderColour( shield, g_iColor_LBlue, 70 );
			if ( color == 3 ) SetRenderColour( shield, g_iColor_LGreen, 70 );
		}
		else if ( type == 3 )
		{
			SetRenderColour( shield, g_iColor_Dark, 100 );
			ToggleGlowEnable( shield, true );
		}
	}
	return shield;
}

void DeletePlayerShield( int client )
{
	int shield = EntRefToEntIndex( PDClientLuffy[client].iPlayerShield );
	RemoveEntity_ClearParent( shield );
	PDClientLuffy[client].iPlayerShield = -1;
}



/////////////////////////////////////////////////////////////
//======================== Timers =========================//
/////////////////////////////////////////////////////////////

public Action Timer_JetF18Life( Handle timer, any entref )
{
	int jetf18 = EntRefToEntIndex( entref );
	if( IsEntityValid( jetf18 ))
	{
		int client = GetOwner( jetf18 );
		if ( IsValidSurvivor( client ))
		{
			if( g_bIsRoundStart )
			{
				PDClientLuffy[client].iClientMissile -= 1;
				if( PDClientLuffy[client].iClientMissile > 0 )
				{
					PCMasterRace_Render_ARGB( client, SHIELD_DORM_ALPHA );	// that right.. you read that correctly
					
					float pos_client[3];
					float clAng[3];
					GetEntOrigin( client, pos_client, 130.0 );
					GetEntAngle( client, clAng, 15.0, AXIS_PITCH );
					TeleportEntity( jetf18, pos_client,  clAng , NULL_VECTOR );
					
					// launch missile here
					float pos_start[3];
					float pos_end[3];
					float ang_start[3];
					
					GetClientEyePosition( client, pos_start );		// start pos of the missile
					GetClientEyeAngles( client, ang_start );		// start angle of the missile
					
					bool gotpos = TraceRayGetEndpoint( pos_start, ang_start, client, pos_end );
					if ( gotpos )
					{
						/// random missile start firing pos >>> near survivor owner of the missile
						pos_start[0] += GetRandomFloat( -30.0, 30.0 );		//<<< random pos around player location.
						pos_start[1] += GetRandomFloat( -30.0, 30.0 );		//<<< random pos around player location.
						pos_start[2] += GetRandomFloat( 100.0, 130.0 );		//<<< always above player head
						
						/// random missile target pos
						pos_end[0] += GetRandomFloat( -100.0, 100.0 );		//<<< scramble target pos. << for more accuracy zero the value
						pos_end[1] += GetRandomFloat( -100.0, 100.0 );		//<<< scramble target pos. << for more accuracy zero the value
						pos_end[2] += GetRandomFloat( -50.0, 50.0 );		//<<< scramble target pos. << for more accuracy zero the value
						
						int missile = CreateMissileProjectile( client, pos_start, pos_end );	// create a missile and shoot it.
						if( missile != -1 )
						{
							ChangeDirectionAndShoot( missile, pos_end, MISSILE_TARGET_SPEED, -90.0 );	// -90.0 is the molotove body pitch correction
						}
						// if this missile dont hit anything, we kill it.
						CreateTimer( HOMING_EXPIRE, Timer_MissileExplode, EntIndexToEntRef( missile ), TIMER_FLAG_NO_MAPCHANGE );
					}
					else
					{
						PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05Null aimed location!!" );
					}
					return Plugin_Continue;
				}
			}
			EmitSoundToClient( client, SND_JETPASS );
			PDClientLuffy[client].hAirStrike = null;
		}
		RemoveEntity_KillHierarchy( jetf18 );
	}
	return Plugin_Stop;
}

public Action Timer_ScrambleModelSelectionDice( Handle timer, any data )
{
	while(	g_iLuffyModelSelection[0] == g_iLuffyModelSelection[1] || g_iLuffyModelSelection[0] == g_iLuffyModelSelection[2] ||
			g_iLuffyModelSelection[0] == g_iLuffyModelSelection[3] || g_iLuffyModelSelection[0] == g_iLuffyModelSelection[4] ) {
			g_iLuffyModelSelection[0] = GetRandomInt( 0, 8 );
	}
	
	g_iLuffyModelSelection[4] = g_iLuffyModelSelection[3];
	g_iLuffyModelSelection[3] = g_iLuffyModelSelection[2];
	g_iLuffyModelSelection[2] = g_iLuffyModelSelection[1];
	g_iLuffyModelSelection[1] = g_iLuffyModelSelection[0];
	
	g_bSafeToRollNextDiceModel = true;
}

public Action Timer_LuffySpawnLife( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if( IsEntityValid( entity ))
	{
		int child = GetEntityChild( entity );
		if( IsEntityValid( child ))
		{
			if ( EMLuffyDrop[entity].bThinkLife( entity ))
			{
				if( EMLuffyDrop[entity].bIsRandom )
				{
					int rand = EMLuffyDrop[entity].RollModelDice();
					EMLuffyDrop[entity].SetModel( entity, g_sModelBuffer[rand], g_fModelScale[rand] );
				}
				
				return Plugin_Continue;
			}
	
			g_iLuffySpawnCount--;
			if( g_iLuffySpawnCount < 0 )
			{
				g_iLuffySpawnCount = 0;
			}
			
			SDKUnhook( entity, SDKHook_StartTouchPost, OnLuffyObjectTouch );
			RemoveEntity_KillHierarchy( entity );
		}
		EMLuffyDrop[entity].hTimer = null;
	}
	return Plugin_Stop;
}

public Action Timer_AmmoBoxlife( Handle timer, any entref )
{
	int ammobox = EntRefToEntIndex( entref );
	if( IsEntityValid( ammobox ))
	{
		int client = GetOwner( ammobox );
		if( !IsValidSurvivor( client ))
		{
			RemoveEntity_Kill( ammobox );
		}
	}
}

public Action Timer_PlayLuffyPickupAnimation( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if( entity > MaxClients )
	{
		if( g_bIsRoundStart && g_iSkinAnimeCount[entity] > 0 && g_iSkinAnimeCount[entity] <= ANIMATION_COUNT )
		{
			SetEntPropFloat( entity, Prop_Send, "m_flModelScale", g_fSkinAnimeScale[entity] );
			g_fSkinAnimeScale[entity] *= 1.2;
			g_iSkinAnimeCount[entity] += 1;
			return Plugin_Continue;
		}
		
		g_iSkinAnimeCount[entity] = 0;
		g_fSkinAnimeScale[entity] = 0.0;
		RemoveEntity_Kill( entity );
	}
	return Plugin_Stop;
}

public Action Timer_RollAmmoboxDice( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if( IsValidSurvivor( client ))
	{
		PDClientLuffy[client].iRollRandomDice();
	}
}

public Action Timer_LuffyHealth( Handle timer, any userid ) //<< check legde grab and incap( we not entirely sure what happen during the animation )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ))
		{
			int health = GetPlayerHealth( client );
			if( g_bIsRoundStart && health < g_iHPregenMax )
			{
				// // player not incap or ledge grab during animation, safe to continue
				if( !IsPlayerLedge( client ) && !IsPlayerIncap( client ))
				{
					PDClientLuffy[client].iCleintHPHealth = health + 1;
					PDClientLuffy[client].fCleintHPBuffer = 100.0 - float( PDClientLuffy[client].iCleintHPHealth );			// make sure our health dont exceed 100
					SetPlayerHealthBuffer( client, PDClientLuffy[client].fCleintHPBuffer );
					SetPlayerHealth( client, PDClientLuffy[client].iCleintHPHealth );
					return Plugin_Continue;
				}
				
				if( IsPlayerIncap( client ))
				{
					// mark player as hp regen intruppted
					PDClientLuffy[client].bIsHPInterrupted = true;
				}
			}
			
			if( !PDClientLuffy[client].bIsHPInterrupted )
			{
				SetPlayerHealthBuffer( client, 0.0 );
				SetPlayerHealth( client, 100 );
				ResetPlayerLifeCount( client );
				EmitSoundToClient( client, SND_TIMEOUT );
				PDClientLuffy[client].iCleintHPHealth = 0;
				PDClientLuffy[client].fCleintHPBuffer = 0.0;
			}
		}
		PDClientLuffy[client].hHealthRegen = null;
	}
	return Plugin_Stop;
}

public Action Timer_RestoreCollution( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client )) 
	{
		SetEntityMoveType( client, MOVETYPE_WALK );
	}
}

public Action Timer_LuffyClock( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ))
		{
			PDClientLuffy[client].fAbilityCountdown -= 0.1 ;
			if( PDClientLuffy[client].fAbilityCountdown > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Yellow, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				float pos_client[3];
				GetEntOrigin( client, pos_client, 20.0 );

				int shield = EntRefToEntIndex( PDClientLuffy[client].iPlayerShield );
				if( shield != -1 )
				{
					float currAng[3];
					GetEntAngle( shield, currAng, 20.0, AXIS_YAW );
					BoundAngleValue( currAng, currAng, 360.0, AXIS_YAW );			// prevent number from going huge
					
					if ( g_iShieldType == 1 )
					{
						TeleportEntity( shield, pos_client, currAng, NULL_VECTOR );
					}
					else
					{
						TeleportEntity( shield, NULL_VECTOR, currAng, NULL_VECTOR );
					}
				}
				
				float pos_target[3];
				char className[128];
				int  count_mdl = GetEntityCount();
				for ( int  i = 1; i <= count_mdl; i++ )
				{
					if ( i <= MaxClients )
					{
						if ( IsValidInfected( i ) && IsPlayerAlive( i ))
						{
							GetEntOrigin( i, pos_target, 20.0 );
							if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
							{
								CreatePointHurt( client, i, 1, DAMAGE_EXPLOSIVE, pos_target, SHIELD_RADIUS );	// do 1 damage to tell the infected who is responsible for tackling his armpits.
								CreateShieldPush( client, i, SHIELD_PUSHCLOCK );								// we dont kill him, just push him harder
							}
						}
					}
					else
					{
						if ( IsValidEntity( i ))
						{
							GetEntityClassname( i, className, sizeof( className ));
							if ( StrEqual( className, "infected", false ) || StrEqual( className, "witch", false ))
							{
								GetEntOrigin( i, pos_target, 20.0 );
								if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
								{
									CreatePointHurt( client, i, 1, DAMAGE_EXPLOSIVE, pos_target, SHIELD_RADIUS ); 	// do 1 damage to tell the witch who is responsible for tackling his armpits.
									CreateShieldPush( client, i, SHIELD_PUSHCLOCK );								// we dont kill him, just push him harder
								}
							}
						}
					}
				}
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - PDClientLuffy[client].fClientTimeBuffer;
					if( shif >= 1.0 )
					{
						PDClientLuffy[client].iHintCountdown -= 1;
						PDClientLuffy[client].fClientTimeBuffer = time;
					}
					
					if( g_bAllowCountdownMsg || PDClientLuffy[client].iHintCountdown == 3 || PDClientLuffy[client].iHintCountdown == 10 || PDClientLuffy[client].iHintCountdown == 20 )
					{
						PrintHintText( client, "++ Luffy Clock last in %d sec ++", PDClientLuffy[client].iHintCountdown );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, SND_TIMEOUT );
		ResetLuffyAbility( client );
		
		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Clock time out --" );
		}
		PDClientLuffy[client].iLuffyType = TYPE_NONE;
		PDClientLuffy[client].hLuffyTimer = null;
	}
	return Plugin_Stop;
}

public Action Timer_LuffySpeed( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			PDClientLuffy[client].fAbilityCountdown -= 0.1 ;
			if( PDClientLuffy[client].fAbilityCountdown > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Blue, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - PDClientLuffy[client].fClientTimeBuffer;
					if( shif >= 1.0 )
					{
						PDClientLuffy[client].iHintCountdown -= 1;
						PDClientLuffy[client].fClientTimeBuffer = time;
					}
					
					if( g_bAllowCountdownMsg || PDClientLuffy[client].iHintCountdown == 3 || PDClientLuffy[client].iHintCountdown == 10 || PDClientLuffy[client].iHintCountdown == 20 )
					{
						PrintHintText( client, "++ Luffy Speed last in %d sec ++", PDClientLuffy[client].iHintCountdown );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, SND_TIMEOUT );
		ResetLuffyAbility( client );

		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Speed time out --" );
		}
		PDClientLuffy[client].iLuffyType = TYPE_NONE;
		PDClientLuffy[client].hLuffyTimer = null;
	}
	return Plugin_Stop;
}

public Action Timer_LuffyStrength( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			if( (GetEntityFlags(client) & FL_ONGROUND) )
			{
				PDClientLuffy[client].bIsDoubleDashPaused = false;
			}
			
			PDClientLuffy[client].fAbilityCountdown -= 0.1 ;
			if( PDClientLuffy[client].fAbilityCountdown > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Green, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - PDClientLuffy[client].fClientTimeBuffer;
					if( shif >= 1.0 )
					{
						PDClientLuffy[client].iHintCountdown -= 1;
						PDClientLuffy[client].fClientTimeBuffer = time;
					}
					
					if( g_bAllowCountdownMsg || PDClientLuffy[client].iHintCountdown == 3 || PDClientLuffy[client].iHintCountdown == 10 || PDClientLuffy[client].iHintCountdown == 20 )
					{
						PrintHintText( client, "++ Luffy Strength last in %d sec ++", PDClientLuffy[client].iHintCountdown );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, SND_TIMEOUT );
		ResetLuffyAbility( client );
		
		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Strength time out --" );
		}
		PDClientLuffy[client].iLuffyType = TYPE_NONE;
		PDClientLuffy[client].hLuffyTimer = null;
	}
	return Plugin_Stop;
}

public Action Timer_LuffyShield( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			PDClientLuffy[client].fAbilityCountdown -= 0.1 ;
			if( PDClientLuffy[client].fAbilityCountdown > 0.0 )
			{
				SetupShieldDorm( client, g_iColor_Red, SHIELD_DORM_RADIUS, g_iBeamSprite_Bubble, SHIELD_DORM_ALPHA );
				
				float pos_client[3];
				GetEntOrigin( client, pos_client, 0.0 );

				int shield = EntRefToEntIndex( PDClientLuffy[client].iPlayerShield );
				if( shield != -1 )
				{
					float currAng[3];
					GetEntAngle( shield, currAng, 20.0, AXIS_YAW );
					BoundAngleValue( currAng, currAng, 360.0, AXIS_YAW );		// prevent number from going huge
					
					if ( g_iShieldType == 1 )
					{
						float temp = pos_client[2];
						pos_client[2] += 30.0;
						TeleportEntity( shield, pos_client, currAng, NULL_VECTOR );
						pos_client[2] = temp;
					}
					else
					{
						TeleportEntity( shield, NULL_VECTOR, currAng, NULL_VECTOR );
					}
				}
				
				float pos_target[3];
				char className[64];
			
				int  eCount = GetEntityCount();
				for ( int  i = 1; i <= eCount; i++ )
				{
					if ( i <= MaxClients )
					{
						if ( IsValidInfected( i ) && IsPlayerAlive( i ))
						{
							GetEntOrigin( i, pos_target, 0.0 );
							if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
							{
								if ( GetZclass( i ) == ZOMBIE_TANK )
								{
									CreatePointHurt( client, i, g_iTankDamage, DMG_GENERIC, pos_target, SHIELD_RADIUS );		// we give him some serious hits
									CreateShieldPush( client, i, SHIELD_PUSHSHIELD );											// but we dont push that hard
								}
								else
								{
									CreatePointHurt( client, i, g_iSuperShieldDamage, DMG_GENERIC, pos_target, SHIELD_RADIUS );	// we give him some serious hits
									CreateShieldPush( client, i, SHIELD_PUSHSHIELD );											// but we dont push that hard
								}
							}
						}
					}
					else
					{
						if ( IsValidEntity( i ))
						{
							GetEntityClassname( i, className, sizeof( className ));
							if ( StrEqual( className, "infected", false ) || StrEqual( className, "witch", false ))
							{
								GetEntOrigin( i, pos_target, 0.0 );
								if ( GetVectorDistance( pos_client, pos_target ) <= SHIELD_RADIUS )
								{
									CreatePointHurt( client, i, g_iSuperShieldDamage, DMG_GENERIC, pos_target, SHIELD_RADIUS );
									CreateShieldPush( client, i, SHIELD_PUSHSHIELD );
								}
							}
						}
					}
				}
				
				if( g_bHinttext )
				{
					//calculate how long time has pass since we display our hint message
					float time = GetGameTime();
					float shif = time - PDClientLuffy[client].fClientTimeBuffer;
					if( shif >= 1.0 )
					{
						PDClientLuffy[client].iHintCountdown -= 1;
						PDClientLuffy[client].fClientTimeBuffer = time;
					}
					
					if( g_bAllowCountdownMsg || PDClientLuffy[client].iHintCountdown == 3 || PDClientLuffy[client].iHintCountdown == 10 || PDClientLuffy[client].iHintCountdown == 20 )
					{
						PrintHintText( client, "++ Luffy Shield last in %d sec ++", PDClientLuffy[client].iHintCountdown );
					}
				}
				return Plugin_Continue;
			}
		}
		
		EmitSoundToClient( client, SND_TIMEOUT );
		ResetLuffyAbility( client );

		if ( g_bHinttext )
		{
			PrintHintText( client, "-- Luffy Shield time out --" );
		}
		PDClientLuffy[client].iLuffyType = TYPE_NONE;
		PDClientLuffy[client].hLuffyTimer = null;
	}
	return Plugin_Stop;
}

public Action Timer_RestoreFrozenButton( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if( IsValidSurvivor( client ))
	{
		if( IsPlayerAlive( client ) && g_bIsRoundStart )
		{
			PDClientLuffy[client].iUnfreezCountdown--;
			if( PDClientLuffy[client].iUnfreezCountdown > 0 )
			{
				if( !IsPlayerIncap( client ) && !IsPlayerLedge( client ))
				{
					if ( g_bHinttext  && PDClientLuffy[client].fAbilityCountdown == 0.0 || !g_bAllowCountdownMsg )
					{
						PrintHintText( client, "-- You will be unfreze in %d sec --", PDClientLuffy[client].iUnfreezCountdown );
					}
					return Plugin_Continue;
				}
			}
		}
		
		// unfroze his button
		PDClientLuffy[client].ButtonUnfreeze( client );
		
		EmitSoundToClient( client, SND_FREEZE );
		PDClientLuffy[client].hMoveFreeze = null;
		
		if( PDClientLuffy[client].fAbilityCountdown == 0.0 )
		{
			SetRenderColour( client, g_iColor_White, 255 );
		}
		
		if ( g_bHinttext )
		{
			PrintHintText( client, "++ You were unfrezed ++" );
		}
	}
	return Plugin_Stop;
}

public Action Timer_PrecacheEntity( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if( IsValidSurvivor( client ))
	{
		int count_prt = 0;
		bool missileshoot = false;

		float pos1[3];
		float pos2[3];
		GetEntOrigin( client, pos1, 3000.0 );
		GetEntOrigin( client, pos2, 5000.0 );
		
		if( CreatPointDamageRadius( pos1, PARTICLE_CREATEFIRE, 0, 0, -1 )) { count_prt += 1; }
		if( CreatePointParticle( pos1, PARTICLE_EXPLOSIVE, 0.1 )) { count_prt += 1; }
		if( CreatePointParticle( pos1, PARTICLE_ELECTRIC1, 0.1 )) { count_prt += 1; }
		if( CreatePointParticle( pos1, PARTICLE_ELECTRIC2, 0.1 )) { count_prt += 1; }
		
		int missile = CreateMissileProjectile( -1, pos1, pos2 );
		if( missile != -1 )
		{
			ChangeDirectionAndShoot( missile, pos2, MISSILE_TARGET_SPEED, -90.0 ); //-90.0 is the molotov body pitch correction
			CreateTimer( 1.0, Timer_MissileExplode, EntIndexToEntRef( missile ));
			missileshoot = true;
		}
		
		if( g_bIsDebugMode )
		{
			if( count_prt < 4 )
			{
				PrintToServer( "" );
				PrintToServer( "|LUFFY| Error Precache particle | less %d particle |LUFFY|", ( 4 - count_prt ));
				PrintToServer( "" );
			}
			else
			{
				PrintToServer( "|LUFFY| All Particle Precached Succsessfuly |LUFFY|" );
			}
			
			if( missileshoot )
			{
				PrintToServer( "|LUFFY| Missile has beed precached :) |LUFFY|" );
			}
		}
	}
}

public Action Timer_DeletIndex( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if( IsEntityValid( entity ))
	{
		AcceptEntityInput( entity, "Kill" );
	}
}




