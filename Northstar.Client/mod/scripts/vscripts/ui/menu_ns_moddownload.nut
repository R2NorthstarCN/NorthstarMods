global function DownloadMod
global function DisplayModDownloadErrorDialog
global function FetchVerifiedModsManifesto

global enum eModInstallStatus
{
	IDLE,
    MANIFESTO_FETCHING,
    DOWNLOADING,
    CHECKSUMING,
    EXTRACTING,
    DONE,
    FAILED,
    FAILED_READING_ARCHIVE,
    FAILED_WRITING_TO_DISK,
    MOD_FETCHING_FAILED,
    MOD_CORRUPTED,
    NO_DISK_SPACE_AVAILABLE,
    NOT_FOUND
}

const int MB = 1024*1000;


void function FetchVerifiedModsManifesto()
{
	print("Start fetching verified mods manifesto from the Internet")

	// Fetching UI
	DialogData dialogData
	dialogData.header = Localize( "#MANIFESTO_FETCHING_TITLE" )
	dialogData.message = Localize( "#MANIFESTO_FETCHING_TEXT" )
	dialogData.showSpinner = true;

	// Prevent user from closing dialog
	dialogData.forceChoice = true;
	OpenDialog( dialogData )

	// Do the actual fetching
	NSFetchVerifiedModsManifesto()

	ModInstallState state = NSGetModInstallState()
	while ( state.status == eModInstallStatus.MANIFESTO_FETCHING )
	{
		state = NSGetModInstallState()
		WaitFrame()
	}

	// Close dialog when manifesto has been received
	CloseActiveMenu()
}


bool function DownloadMod( string modname, string modversion )
{
	
	// Downloading mod UI
	DialogData dialogData
	dialogData.header = Localize( "#DOWNLOADING_MOD_TITLE" )
	dialogData.message = Localize( "#DOWNLOADING_MOD_TEXT", modname, modversion )
	dialogData.showSpinner = true;

	// Prevent user from closing dialog
	dialogData.forceChoice = true;
	OpenDialog( dialogData )

	// Save reference to UI elements, to update their content
	var menu = GetMenu( "Dialog" )
	var header = Hud_GetChild( menu, "DialogHeader" )
	var body = GetSingleElementByClassname( menu, "DialogMessageClass" )

	// Start actual mod downloading
	ModInstallState state = NSGetModInstallState()
	state.status = eModInstallStatus.IDLE
	NSDownloadMod( modname, modversion )
	while ( state.status < eModInstallStatus.DONE )
	{
		state = NSGetModInstallState()
		UpdateModDownloadDialog( modname, modversion, state, menu, header, body )
		WaitFrame()
	}

	printt( "Mod status:", state.status )

	// Close loading dialog
	CloseActiveMenu()

	return state.status == eModInstallStatus.DONE
}

void function UpdateModDownloadDialog( string modname, string modversion, ModInstallState state, var menu, var header, var body )
{
	switch ( state.status )
	{
	case eModInstallStatus.IDLE:
		Hud_SetText( header, Localize( "#MANIFESTO_FETCHING_TITLE") )
		Hud_SetText( body, Localize( "#MANIFESTO_FETCHING_TEXT" ) )
	case eModInstallStatus.MANIFESTO_FETCHING:
		Hud_SetText( header, Localize( "#MANIFESTO_FETCHING_TITLE" ) )
		Hud_SetText( body, Localize( "#MANIFESTO_FETCHING_TEXT" ) )
		break
	case eModInstallStatus.DOWNLOADING:
		Hud_SetText( header, Localize( "#DOWNLOADING_MOD_TITLE_W_PROGRESS", string( state.ratio ) ) )
		Hud_SetText( body, Localize( "#DOWNLOADING_MOD_TEXT_W_PROGRESS", modname, modversion, floor( state.progress / MB ), floor( state.total / MB ) ) )
		break
	case eModInstallStatus.CHECKSUMING:
		Hud_SetText( header, Localize( "#CHECKSUMING_TITLE" ) )
		Hud_SetText( body, Localize( "#CHECKSUMING_TEXT", modname, modversion ) )
		break
	case eModInstallStatus.EXTRACTING:
		Hud_SetText( header, Localize( "#EXTRACTING_MOD_TITLE", string( state.ratio ) ) )
		Hud_SetText( body, Localize( "#EXTRACTING_MOD_TEXT", modname, modversion, floor( state.progress / MB ), floor( state.total / MB ) ) )
		break
	default:
		break
	}
}

void function DisplayModDownloadErrorDialog( string modName )
{
	ModInstallState state = NSGetModInstallState()

	DialogData dialogData
	dialogData.header = Localize( "#FAILED_DOWNLOADING", modName )
	dialogData.image = $"ui/menu/common/dialog_error"

	switch ( state.status )
	{
    case eModInstallStatus.FAILED_READING_ARCHIVE:
		dialogData.message = Localize( "#FAILED_READING_ARCHIVE" )
		break
    case eModInstallStatus.FAILED_WRITING_TO_DISK:
		dialogData.message = Localize( "#FAILED_WRITING_TO_DISK" )
		break
    case eModInstallStatus.MOD_FETCHING_FAILED:
		dialogData.message = Localize( "#MOD_FETCHING_FAILED" )
		break
    case eModInstallStatus.MOD_CORRUPTED:
		dialogData.message = Localize( "#MOD_CORRUPTED" )
		break
    case eModInstallStatus.NO_DISK_SPACE_AVAILABLE:
		dialogData.message = Localize( "#NO_DISK_SPACE_AVAILABLE" )
		break
    case eModInstallStatus.NOT_FOUND:
		dialogData.message = Localize( "#NOT_FOUND" )
		break
	case eModInstallStatus.FAILED:
	default:
		dialogData.message = Localize( "#MOD_FETCHING_FAILED_GENERAL" )
		break
	}

	AddDialogButton( dialogData, "#DISMISS" )
	AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
	AddDialogFooter( dialogData, "#B_BUTTON_DISMISS_RUI" )

	OpenDialog( dialogData )
}
