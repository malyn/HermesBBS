{Segments: Initial_1}
unit Initial;

interface

	uses
		Serial, Sound, AppleTalk, ADSP, CommResources, CRMSerialDevices, CTBUtilities, GestaltEqu, TCPTypes;
	const
		HERMES_VERSION = '3.5.11b2';
		SYSTREC_VERSION = 359;
		EXTERNALS_VERSION = 330;
		MAX_NODES = 10;
		MAX_NODES_M_1 = 9;

		DOINITILIZE = 1;	 {values for message field to user external}
		CREATENODEVARS = 2;
		DOMAINTENCE = 3;
		CALLLOGON = 4;
		CALLMENU = 5;
		IDLE = 6;
		GAMEIDLE = 7;
		ACTIVEEXT = 8;
		CLOSENODE = 9;
		CLOSEEXTERNAL = 10;
		RAWCHAR = 12;

		BUILDTMENU = 99;
		BUILDMENU = 100;
		ABLEMENU = 101;
		DOMENU = 102;
		DISPOSEPREC = 103;
		DISPOSETMENU = 104;

		CANSEND = 7;
		CANRECEIVE = 6;
		CANBSEND = 5;
		CANBRECEIVE = 4;
		SENDFLOW = 3;
		RECEIVEFLOW = 2;
		CONTINUERECEIVE = 1;
		SETTERMPREF = 0;
		SETBBSPREF = 15;
		CANTCPSEND = 14;
		CANTCPRECEIVE = 13;

		USINGTCP = 9;
		USINGADSP = 8;
		TRANSMODE = 7;
		STOPTRANS = 6;
		CARRIERLOSS = 5;
		USEMACBINARY = 4;
		NEWMBNAME = 3;
		NEWERROR = 2;
		NEWFILE = 1;
		RECOVERING = 0;

		UPLOADCALL = 1;
		DOWNLOADCALL = 0;

		TABBYTOID = -100;

		ADSPNAME = 'AppleTalk';
		ADSPSENDBUFSIZE = 4096;
		ADSPRECBUFSIZE = 2048;

		TCPNAME = 'TCP/IP';
		TCPBUFSIZE = 4096;

		SENDNOWBUFSIZE = 3072;

		HANDLE_SIZE = 30000; {This is arbitrary but doesn't really matter}

		USERCOLORBASE = 18; { Must not be less than the 'magic' 16 and 17. }

		Fido_Class = 'Fido';
		Fido_NeedNode = 'NdNd';
		Fido_NodeAvail = 'NdAv';
		Fido_ReleaseNode = 'NdRl';
		Fido_CrashMail = 'CrMl';

		SOHchar = 1;
		EOTchar = 4;
		STXchar = 2;
		CANchar = 24;
		ESCchar = 27;
		NAKchar = 21;
		ACKchar = 6;

		kOSEvent = app4Evt;                    {event used by MultiFinder				     }
		kSuspendResumeMessage = 1;		{high byte of suspend/resume event message   }
		kResumeMask = 1;		               {bit of message field for resume vs. suspend }
		kNoEvents = 0;		                    {no events mask								 }
		mApple = 1001;					     {Apple menu									 }
		iAbout = 1;

		mFile = 1002;				        {File menu									 }
		iQuit = 3;

		mTerminal = 1004;
		mLog = 70;
		mNetLog = 72;

		mEdit = 1003;				        {Edit menu									 }
		iUndo = 1;
		iCut = 3;
		iCopy = 4;
		iPaste = 5;
		iClear = 6;

		mUser = 1005;

		mSysop = 1006;

		mConfigure = 1007;

		mDisconnects = 57;

		fFeed = 12;
		lFeed = 10;
		kSFSaveDisk = $214;		{ Negative of current volume refnum [WORD]	}
		kCurDirStore = $398;		{ DirID of current directory [LONG]	   			}
		kMaxDocWidth = 480;

		kDITop = $0050;
		kDILeft = $0070;

		HiliteMode = $938;      { used for color highlighting}
		philitebit = 0;

		SPConfig = $1FB;        { config bits: 4-7 A, 0-3 B (see use type below)}
		SPPortA = $1FC;         { SCC port A configuration [word]}
		SPPortB = $1FE;         { SCC port B configuration [word]}
		SCCRd = $1D8;           { SCC base read address [pointer]}
		SCCWr = $1DC;           { SCC base write address [pointer]}

		aCtl = 2;
		bCtl = 0;
		aData = 6;
		bData = 4;
	type
		IntPtrType = ^integer;
		LongPtrType = ^longint;
		Str255PtrType = ^Str255;

		HermesTCPPtr = ^HermesTCP;
		HermesTCP = record
				tcpPBPtr: TCPControlBlockPtr;
				tcpBuffer: Ptr;
				tcpStreamPtr: StreamPtr;
				tcpWDSPtr: wdsPtr;
			end;

		PopupHand = ^PopupPtr;
		PopupPtr = ^PopupPrivateData;
		popupPrivateData = record
				mHandle: Menuhandle;
				mID: integer;
				mPrivate: array[0..0] of SignedByte;
			end;
		myPopContHand = ^myPopContPtr;
		myPopContPtr = ^myPopControl;
		myPopControl = packed record
				nextControl: controlHandle;
				contrlOwner: windowPtr;
				ContrlRect: rect;
				contrlVis: byte;
				contrlHilite: byte;
				contrlValue: integer;
				contrlMin: integer;
				contrlMax: integer;
				contrlDefProc: handle;
				contrlData: popupHand;
				contrlAction: ProcPtr;
				contrlRfCon: longint;
				contrlTitle: str255;
			end;

		FidoAddress = record
				name: string[81];
				atNode: string[15];
			end;

		TabbyHeader = record
				Flags: packed array[1..4] of char;{with trailing return}
				Category: packed array[1..4] of char;{with trailing return}
				DateMade: packed array[1..9] of char;  {with trailing return}
				TimeMade: packed array[1..9] of char;  {with trailing return}
			end;

		BBSListEntry = record
				number: packed array[0..11] of char;
				theRest: packed array[0..67] of char;
			end;
		BBSListDynamic = packed array[0..90000] of BBSListEntry;
		BBSListPtr = ^BBSListDynamic;

		pLaunchStruct = ^LaunchStruct;
		LaunchStruct = record
				pfName: StringPtr;
				param: INTEGER;
				LC: packed array[0..1] of CHAR;	{	extended parameters:								}
				extBlockLen: LONGINT; 					{	number of bytes in extension = 6					}
				fFlags: INTEGER;							{	Finder file info flags								}
				launchFlags: LONGINT; 					{	bit 31,30=1 for sublaunch, others reserved	}
			end; 											{	LaunchStruct											}

		PathsFilesRec = record
				fName: StringHandle;
				mbName: stringHandle;
				myvRef: integer;
				myDirID: longint;
				myFileID: longint;
			end;
		XFERStuffHand = ^XFERStufPtr;
		XFERStufPtr = ^XFERStuff;
		XFERstuff = packed record
				modemInput: integer;{adsp driver ref for ADSP}
				modemOutput: integer;{CCB ref for ADSP}
				procID: integer;
				protocolData: handle;
				errorReason: stringHandle;
				timeOut: integer;
				fileCount: integer;
				filesDone: integer;
				curBytesDone: longint;
				curBytesTotal: longint;
				curStartTime: longint;
				flags: packed array[0..15] of boolean;
				fPaths: packed array[1..1] of pathsFilesRec;
			end;

		myTRCCB = record
				myA5: LongInt;
				u: TRCCB
			end;

		CarDetType = (CTS5, DCDchip, DCDdriver);

		NewUserHand = ^NewUserPtr;
		NewUserPtr = ^NewUserRec;
		NewUserRec = record
				Handle: Boolean;
				Gender: Boolean;
				RealName: Boolean;
				BirthDay: Boolean;
				City: Boolean;
				Country: Boolean;
				DataPN: Boolean;
				Company: Boolean;
				Street: Boolean;
				Computer: Boolean;
				SysOp: array[1..3] of Boolean;
				SysOpText: array[1..3] of string[60];
				NoVFeedback: boolean;
				QScanBack: integer;
				NoAutoCapital: boolean;
				Reserved: array[1..997] of char;
			end;

		NodeMenuHand = ^NodeMenuPtr;
		NodeMenuPtr = ^NodeMenuRec;
		NodeMenuRec = record
				Name: array[1..50] of string[40];
				OnOff: array[1..50] of Boolean;
				SecLevel: array[1..50] of Integer;
				SecLevel2: array[1..50] of integer;
				SecLevel3: array[1..50] of integer;
				Options: array[1..50, 1..10] of Boolean;
				Reserved: array[1..100] of char;
			end;

		TransMenuHand = ^TransMenuPtr;
		TransMenuPtr = ^TransMenuRec;
		TransMenuRec = record
				Name: array[1..50] of string[40];
				OnOff: array[1..50] of Boolean;
				SecLevel: array[1..50] of Integer;
				SecLevel2: array[1..50] of integer;
				SecLevel3: array[1..50] of integer;
				Options: array[1..50, 1..10] of Boolean;
				Reserved: array[1..100] of char;
			end;

		NodeHand = ^NodePtr;
		NodePtr = ^NodeRec;
		NodeRec = record
				BaudMax: integer;  {max baud supported                      }
				BaudMin: integer;   {minimum baud for valid connection}
				MyInPort: str255;		{Name of input Port}
				myOutPort: str255;	{Name of output Port}
				ModDrivName: str255;  {STR# resource name for modem driver strings}
				LocalHook: boolean;   {true means go off hook in local, false means leave line open}
				MatchSpeed: boolean;	{Match Speed Of Modem?}
				UpTime: longint;			{When does the node start}
				DownTime: longint;		{When does the node stop}
				DTRHangup: boolean;		{Hardware Hangup}
				timeoutIn: integer;		{How many minutes to timeout in}
				HardShake: boolean;		{Hardware Handshake?}
				BufferLines: integer;	{How many lines to hold in the buffer}
				CarDet: CarDetType;		{Carrier Detection Type, CTS5, DCDchip, DCDdriver?}
				NotUsed1: boolean;
				SysOpNode: boolean;				{Is this a SysOp Node}
				SecLevel: integer;				{Security Level For This Node *(3.0)*}
				Rings: integer;
				NodeName: string[30];
				NodeRest: Char;
				WelcomeAlternate: boolean;
				NotUsed2: Integer;
				NewSL: Integer;
				reserved: array[1..14] of char;
			end;

(* NOTE: the numMFroums is stored in the SystemRec *)

		ConferenceRec = record
				Name: string[41];						{Name of  Conference}
				SLtoRead: integer;						{Minimum Security Level To Read Messages}
				SLtoPost: integer;						{Minimum Security Level To Post Messages}
				MaxMessages: integer;					{Maximum Messages Allowed In This Sub Max is 999}
				AnonID: integer;   						{0=never, 1=force, -1=allow}
				MinAge: integer;							{Minimum Age To Access Sub}
				AccessLetter: char;						{Access Letter, if one exists}
				Threading: boolean;						{Allow Threading In This Sub?}
				ConfType: SignedByte;					{Conference Type 0 - Local, 1 - Fido, 2 - UseNet }
				RealNames: Boolean;						{Use real names}
				ShowCity: boolean;						{Show City, State If Using Real Names}
				FileAttachments: boolean;			{Allow File Attachments}
				DLCost: real;									{Cost to DL a file}
				EchoName: str255;							{Name of Echo for calculating Areas.BBS file}
				Moderators: array[1..3] of integer;	{User # of Conference Moderators}
				NewUserRead: boolean;					{Set New User QPtr to 0 for this Conference}
				reserved: packed array[1..25] of char;
			end;

		ForumRec = record
				Name: string[41];										{Name of Forum}
				numConferences: byte;									{Number of Conferences in this Forum}
				MinSL: integer;												{Minimum Security Level to Access This Forum}
				MinAge: integer;											{Minimum Age to Access This Forum}
				AccessLetter: char;										{Access Letter for this Forum}
				Moderators: array[1..3] of integer;	{User # of Forum Moderators}
				reserved: packed array[1..25] of char;
			end;

		MForumHand = ^MForumPtr;
		MForumPtr = ^MForumArray;
		MForumArray = array[1..20] of ForumRec;

		FiftyConferencesHand = ^FiftyConferencesPtr;
		FiftyConferencesPtr = ^FiftyConferences;
		FiftyConferences = array[1..50] of ConferenceRec;

		MConferencesArray = array[1..20] of FiftyConferencesHand;

		MesgRec = record
				Title: string[80];							{Title Of Message}
				fromUserNum: integer;						{From User Number}
				fromUserName: string[40];			{From User Name}
				toUserNum: integer;							{To User Number}
				toUserName: string[40];				{To User Name}
				AnonyFrom: boolean; 						{for now, 0=no anony and 1=anony}
				AnonyTo: boolean;								{Was Message Anonymous To: }
				Deletable: boolean;							{Is Message Deletable?}
				UnUsed1: longint;
				DateEn: longint;								{Date Entered}
				storedAs: longint;							{Stored as flag}
				FileAttached: boolean;					{True = File is Attached}
				FileName: string[31];					{Name of Attached File}
				isAMacFile: Boolean;						{Send with or without MacBinary Header}
				HasRead: Boolean;								{Has the user read in New Scan to You?}
				reserved: packed array[0..20] of char;
			end;

		SubDynamicRec = array[0..90000] of MesgRec;
		SubDyPtr = ^SubDynamicRec;
		SubDyHand = ^SubDyPtr;

		MessIndexHand = ^MessIndexPtr;
		MessIndexPtr = ^MessIndexArray;
		MessIndexArray = array[1..15000] of integer;

		feedbackHand = ^feedbackPtr;
		feedbackPtr = ^feedbackrec;
		feedbackrec = record
				numfeedbacks: integer;					{Number Of Users To Send Feedback To}
				usernum: array[1..20] of integer;		{User Number Of Each User To Send Feedback To}
				speciality: array[1..20] of string[40];  {What "They" Specialize In}
			end;

		emailrec = record
				title: string[40];							{Title of Email}
				FromUser: integer;							{From User Number}
				ToUser: integer;								{To User Number}
				AnonyFrom: boolean;							{If From Is Anonymous, it's true}
				AnonyTo: boolean;								{If To Is Anonymous, it's true}
				DateSent: longint;							{Date Sent}
				StoredAs: longint;							{Stored As flag}
				MType: byte;  									{1=normal, 0=he read message}
				multiMail: boolean;							{True If It is /E}
				FileAttached: boolean;
				FileName: string[31];
				HasRead: Boolean;
				isAMacFile: Boolean;
				reserved: packed array[0..15] of char;
			end;

		MesgHand = ^MesgPtr;
		MesgPtr = ^EMDynamicRec;
		EMDynamicRec = array[0..100000] of EMailRec;

		NewSecLevRec = record
				Class: string[30];
				UseDayorCall: boolean;   		{minutes per day is true, min/call is false}
				ReadAnon: boolean;			 	{Read Anonymous}
				TimeAllowed: integer;    		{Minutes Allowed On Per Day/Call}
				MesgDay: integer;				 {Maximum Messages Per Day}
				DLRatioOneTo: integer;   		{Download Ratio 1:?}
				PostRatioOneTo: integer; {Post Call Ratio 1:?}
				CallsPrDay: integer;		 {Calls Per Day}
				LnsMessage: integer;     {Maximum Lines Per Message}
				PostMessage: Boolean;    {Post Message Yes/No}
				BBSList: Boolean;        {Add To BBS List Yes/No}
				Uploader: Boolean;       {See Uploader On Files Yes/No}
				UDRatio: Boolean;        {Enforce Upload/Download Ratio Yes/No}
				Chat: Boolean;					 {Allow User To Page The SysOp Yes/No}
				Email: Boolean;          {Allow User To Send Email Yes/No}
				ListUser: Boolean;       {Allow User To List Other Users Yes/No}
				AutoMsg: Boolean;        {Allow User To Change Auto Message Yes/No}
				AnonMsg: Boolean;        {Allow User To Post Anonymous Messages Yes/No}
				PCRatio: Boolean;				 {Enforce Post Call Ratio Yes/No}
				TransLevel: Integer;     {Transfer Level}
				Restrics: packed array[1..26] of boolean;  {Restrictions}
				NotUsed: packed array[1..10] of boolean;  {Which Forums}
				Nodes: packed array[1..MAX_NODES] of boolean;     {Which Nodes (3.0)}
				Active: Boolean;														 {Is This Level Active?}
				XferComp: Real;
				MessComp: Real;
				MustRead: Boolean;
				PPFile: boolean;			{Person To Person File x-fer}
				EnableHours: boolean;     {Restrict Hours}
				AlternateText: boolean;
				CantNetMail: boolean;
				Extra: array[1..23] of Char;
			end;

		SecLevHand = ^SecLevPtr;
		SecLevPtr = ^NewSecurity;
		NewSecurity = array[1..255] of NewSecLevRec;

		SystHand = ^SystPtr;
		SystPtr = ^SystRec;
		SystRec = record
				BBSName: string[40];												{ BBSName }
				OverridePass: string[9];										{ SysOp Override Password }
				NewUserPass: string[9];										{ New User Password}
				NumCalls: longint;													{Number of total calls to system}
				NumUsers: integer;													{Number of users on system (not including deleted)}
				OpStartHour: longint;												{SysOp's starting hour}
				OpEndHour: longint;													{SysOp's ending hour}
				Closed: boolean;														{If the board is closed or not (true=yes)}
				NumNodes: integer;													{Number of Nodes board has}
				unused3: integer;														{Keeps track of mouse ticks}
				LastMaint: DateTimeRec;											{Date Of Last Maintenance}
				LastUL: Longint;             					      { Date Of Last Upload }
				LastDL: Longint;														{ Date Of Last Download }
				LastPost: Longint;													{ Date Of Last Post }
				LastEmail: Longint;													{ Date Of Last EMail }
				AnonyUser: integer;													{Auto Message User Number}
				AnonyAuto: boolean;													{If Auto Message Is Anonymous}
				SerialNumber: string[40];
				GFilePath: Str255;													{Path To GFiles}
				MsgsPath: str255;														{Path To Message Data}
				DataPath: str255;														{Path To Transfer Data}
				MailAttachments: Boolean;										{Mail Attachments On/Off}
				MailDLCost: real;														{DL Cost to a Mail Attachment}
				FreeMailDL: boolean;												{Does a Mail Attachment cost}
				numMForums: integer;												{Number of Message Forums}
				NumNNodes: Byte;														{For Future Use, Networking}
				Bbsnames: array[0..MAX_NODES_M_1] of string[40];			{BBS Names For Calling Out}
				Bbsnumbers: array[0..MAX_NODES_M_1] of string[40];		{BBS Numbers For Calling Out}
				BbsdialIt: packed array[0..MAX_NODES_M_1] of boolean;	{BBS Number If User Wants Dialed}
				Bbsdialed: packed array[0..MAX_NODES_M_1] of boolean;	{BBS Number If Already Dialed}
				WnodesStd: array[1..MAX_NODES] of rect;						{Rect's Of Windows Of Each Text}
				WNodesUser: array[1..MAX_NODES] of rect;					{Rect's Of Windows Of Each Node}
				WIsOpen: packed array[0..MAX_NODES] of boolean;	{Is Window Open, true if yes}
				Wstatus: rect;															{Rect of Status window}
				Wusers: rect;																{Rect of User List}
				WuserOpen: Boolean;													{Is User List open}
				Restrictions: array[1..26] of string[20];	{Restriction Names}
				callsToday: array[1..MAX_NODES] of integer;				{Calls Posted Today, By Node}
				mPostedToday: array[1..MAX_NODES] of integer;			{Messages Posted Today, By Node}
				eMailToday: array[1..MAX_NODES] of integer;				{Email Sent Today, By Node}
				uploadsToday: array[1..MAX_NODES] of integer;			{Uploads Today, By Node}
				kuploaded: array[1..MAX_NODES] of longint;				{KBytes Uploads Today, By Node}
				minsToday: array[1..MAX_NODES] of integer;				{Minutes Today, By Node}
				dlsToday: array[1..MAX_NODES] of integer;					{Downloads Today, By Node}
				kdownloaded: array[1..MAX_NODES] of longint;			{KBytes Downloaded Today, By Node}
				failedULs: array[1..MAX_NODES] of integer;				{Failed UL's Today, By Node}
				failedDLs: array[1..MAX_NODES] of integer;				{Failed DL's Today, By Node}
				LastUser: string[31];											{Name of Last User}
				UnUsed1: longint;
				TwoWayChat: boolean;												{Two Way Chat}
				UseXWind: boolean;													{Use Transfer Window}
				ninePoint: boolean;													{Nine or Twelve Point}
				FreePhone: boolean;													{Phone Format, True if ###-###-####}
				ClosedTransfers: boolean;										{Close The Transfer Section}
				protocolTime: integer;											{Protocol Time Slice}
				BlackOnWhite: integer;  										{mapped to old style quickdraw 8-colors}
				MailDeleteDays: integer;  									{Number of Days auto deletion is set to}
				twoColorChat: boolean;											{Two Color chat (if ansi)}
				UsePauses: boolean;													{Allow sysop pauses}
				DLCredits: longint;													{DL Credits To Give To New User}
				logDays: byte;															{How Many Days To Save Logs}
				LogDetail: byte;														{What Type Of Detail, By Node, By BBS}
				realSerial: string[80];
				startDate: longint;													{BBS Start date}
				screenSaver: packed array[0..1] of byte;
				Totals: Boolean;														{Log By Totals or By Node}
				EndString: string[80];
				UseBold: Boolean;
				version: integer;														{Current version of Hermes II}
				Quoter: Boolean;														{Quoter On/Off}
				SSLock: Boolean;														{SSLock On/Off}
				NoANSIDetect: boolean;											{ANSI Detect On/Off}
				NoXFerPathChecking: boolean;								{Transfer Path Checking On/Off}
				QuoteHeader: str255;												{Header line for Quote.}
				QuoteHeaderAnon: str255;											{Header line for Quote in Anon conference}
				UseQuoteHeader: boolean;
				QuoteHeaderOptions: (UseNormal, UseAnonAndNormal, NoHeaderInAnon);
{ Added in 3.5.9b1; reserved was 0..507 }
				Foregrounds: packed array[0..6] of byte;			{Foreground Colors}
				Backgrounds: packed array[0..6] of byte;			{Background Colors}
				Intense: array[0..6] of boolean;			{Which are intense = True}
				Underlines: array[0..6] of boolean;		{Which are underlined = True}
				Blinking: array[0..6] of boolean;			{Which are blinking = True}
				DebugTelnet, DebugTelnetToFile: boolean;
				reserved: packed array[1..470] of char;
			end;

		filEntryRec = record
				flName: string[31];            {list file name}
				realFName: str255;       {real file path on desktop}
				flDesc: string[78];             {file description}
				whenUL: longInt;                   {exact time uploaded in Mac date format from Jan 1, 1904}
				uploaderNum: integer;          {user number of uploader}
				numDLoads: integer;             {how many times this has been dl'd}
				byteLen: longInt;                  {length of file in bytes}
				hasExtended: boolean;          {boolean}
				fileStat: char;
				lastDL: longint;
				Version: string[10];
				FileType: string[4];
				FileCreator: string[4];
				FileNumber: longint;
				reserved: packed array[1..52] of char;   {set to nulls for now}
			end;

		aDirHand = ^aDirPtr;
		aDirPtr = ^aDirFile;
		aDirFile = array[0..90000] of filentryrec;

		batFileRec = record
				theFile: filEntryRec;
				fromDir: integer;                                    {transfer directory for file}
				fromSub: integer;
			end;

		FLSHand = ^FLSPtr;
		FLSPtr = ^FLSRec;
		FLSRec = record
				numFiles: integer;                                  {max batch is 50 arbitrarily}
				sendingBatch: boolean;							 {true if this is a batch DL, otherwise not}
				batchTime: longint;                                {used internally, approximation of transfer time(seconds)}
				batchKBytes: longint;                             {used internally}
				filesGoing: array[1..50] of BatFileRec;
			end;

		InternalTransfer = record
				active: boolean;
				Sending: boolean;
				starttime: longint;
			end;

		TextHand = ^TextPtr;
		TextPtr = ^TextRec;
		TextRec = packed array[0..92000] of char;

		DirInfoRec = record
				DirName: string[41];
				Path: str255;
				MinDSL: integer;
				DSLtoUL: integer;
				DSLtoDL: integer;
				MaxFiles: integer;
				Restriction: char;
				NonMacFiles: integer;   {0=allow macBinary, 1= never MacBinary}
				mode: integer;   {  -1 = Never New, 0=Normal , 1= Always New  }
				MinAge: integer;
				FileNameLength: integer;
				freeDir: boolean;
				AllowUploads: boolean;
				Handles: boolean;
				ShowUploader: boolean;
				Color: integer;
				TapeVolume: boolean;
				SlowVolume: boolean;
				Operators: array[1..3] of integer;
				DLCost: Real;
				ULCost: Real;
				DLCreditor: Real;
				HowLong: Integer;
				UploadOnly: Boolean;
				reserved: packed array[0..44] of char;
			end;

		DirDataFile = record
				Dr: array[1..64] of DirInfoRec;
			end;

		ReadDirPtr = ^DirDataFile;
		ReadDirHandle = ^ReadDirPtr;

		DirList = array[0..64] of DirDataFile;
		DirListPtr = ^DirList;
		DirListHand = ^DirListPtr;

		ForumIdxHand = ^ForumIdxPtr;
		ForumIdxPtr = ^ForumIdxRec;
		ForumIdxRec = record
				NumForums: Integer;
				Name: array[0..64] of string[31];
				MinDsl: array[0..64] of Integer;
				Restriction: array[0..64] of Char;
				numDirs: array[0..64] of integer;
				age: array[0..64] of integer;
				Ops: array[0..64, 1..3] of integer;
				lastupload: array[0..64, 1..64] of longint;
				reserved: array[1..1000] of Char;
			end;

		MailerHand = ^MailerPtr;
		MailerPtr = ^MailerRec;
		MailerRec = record
				Application: Str255;
				GenericPath: Str255;
				MailerAware: Boolean;
				SubLaunchMailer: signedByte; {0 = Shutdown BBS, 1 = Single Node Shutdown, 2 = AppleEvents}
				EventPath: Str255;
				MailerNode: integer;
				AllowCrashMail: boolean;
				ImportSpeed: Integer;
				InternetMail: (NoMail, FidoGated, Direct);
				FidoAddress: string[25];
				UseRealNames: boolean;
				CrashMailPath: Str255;
				UseEMSI: boolean;
				reserved: packed array[0..735] of Char;
			end;

		ULR = record
				Uname: string[31];
				Dltd: boolean;
				last: longint;
				first: longint;
				SL: integer;
				DSL: integer;
				real: string[21];
				AccessLetter: packed array[1..26] of boolean;
				age: byte;
				City: string[30];
				State: string[2];
			end;

		UListHand = ^UListPtr;
		UListPtr = ^UListRec;
		UListRec = array[0..32000] of ULR;

		UserHand = ^UserPtr;
		UserPtr = ^UserRec;
		UserRec = record
				UserNum: integer;
				SL: Integer;																		{Security Level}
				DSL: integer;																		{Download Security Level}
				UserName: string[31];
				RealName: string[21];
				Alias: string[31];
				Phone: string[12];
				Password: string[9];
				DataPhone: string[12];
				Company: string[30];
				Street: string[30];
				City: string[30];
				State: string[6];
				Zip: string[10];
				Country: string[10];
				ComputerType: string[23];
				SysopNote: string[41];
				MiscField1: string[60];
				MiscField2: string[60];
				MiscField3: string[60];
				lastbaud: string[19];
				AccessLetter: packed array[1..26] of boolean;	{26 Access Letters A - Z}
				CantPost: Boolean;															{Restriction #1}
				CantChat: Boolean;															{Restriction #2}
				UDRatioOn: Boolean;															{Restriction #3}
				PCRatioOn: Boolean;															{Restriction #4}
				CantPostAnon: Boolean;													{Restriction #5}
				CantSendEmail: Boolean;													{Restriction #6}
				CantChangeAutoMsg: Boolean;											{Restriction #7}
				CantListUser: Boolean;													{Restriction #8}
				CantAddToBBSList: Boolean;											{Restriction #9}
				CantSeeULInfo: Boolean;													{Restriction #10}
				CantReadAnon: Boolean;													{Restriction #11}
				RestrictHours: Boolean;													{Restriction #12}
				CantSendPPFile: boolean;												{Restriction #13}
				CantNetMail: boolean;														{Restriction #14}
				ReadBeforeDL: boolean;													{Restriction #15}
				ReservedForRestricts: array[1..4] of boolean;	{Reserved space for 4 more Restricts}
				DeletedUser: boolean;														{True = User Deleted}
				LastOn: longInt;																{Date of last logon}
				FirstOn: longInt;																{Date of first logon}
				Sex: boolean; 																	{True = Male, False = Female}
				BirthDay: char;
				BirthMonth: char;
				BirthYear: char;
				Age: byte;
				OnToday: integer;																{Number of times called today}
				TotalLogons: integer;														{Total times called BBS since first logon}
				MinOnToday: integer;														{Time on today}
				totalTimeOn: longint;														{Total time on since first logon}
				illegalLogons: integer;													{Number of illegal logons today}
				MessagesPosted: integer;
				MPostedToday: integer;
				EMailSent: integer;
				EMsentToday: integer;
				NumUploaded: integer;
				NumULToday: integer;
				NumDownloaded: integer;
				NumDLToday: Integer;
				UploadedK: longint;
				KBULToday: longint;
				DownloadedK: longint;
				KBDLToday: longint;
				ScrnWdth: integer;
				ScrnHght: integer;
				TerminalType: byte;															{0 = VT100, 1 = ANSI}
				ColorTerminal: boolean;													{True = Color, False = B&W}
				UseDayOrCall: Boolean;
				TimeAllowed: Integer;
				CallsPrDay: integer;
				MesgDay: integer;
				LnsMessage: integer;
				DLRatioOneTo: Integer;
				PostRatioOneTo: Integer;
				DLCredits: longint;
				coSysop: boolean;
				alertOn: boolean;
				lastPWChange: longint;
				Donation: string[20];
				LastDonation: string[20];
				ExpirationDate: string[20];
				AlternateText: boolean;
				StartHour: longint;
				EndHour: longint;
				Foregrounds: packed array[0..17] of byte;			{Foreground Colors}
				Backgrounds: packed array[0..17] of byte;			{Background Colors}
				Intense: packed array[0..17] of boolean;			{Which are intense = True}
				Underlines: packed array[0..17] of boolean;		{Which are underlined = True}
				Blinking: packed array[0..17] of boolean;			{Which are blinking = True}
				WhatTNScan: packed array[0..63] of Boolean;		{For later use of N Scan X-Fer Areas}
				WhatNScan: packed array[1..20, 1..50] of boolean;{Message N Scan Forums/Confs}
				LastMsgs: array[1..20, 1..50] of longint;			{Message Pointer in MMDDY}
				lastFileScan: longInt;													{Last Date of Transfer Section Scan}
				PauseScreen: boolean;														{True = Pause after ScHght of lines}
				DefaultProtocol: byte;
				Mailbox: boolean;  															{False = normal, True = forwarded}
				ForwardedTo: string[45];												{User or Address Mail is forwarded to}
				Expert: boolean;																{True = No Menus}
				NTransAfterMess: boolean;												{Newscan Transfers after Messages}
				ExtendedLines: byte;														{If > 0 then Display Extended Desc.}
				ExtDesc: Boolean;																{Search Extended Description}
				ScreenClears: boolean;													{True = Screen Clears on}
				notifyLogon: boolean;														{True = Notify everyone you logged on or off}
				ScanAtLogon: Boolean;														{True = Scan New Messages to you at Logon}
				AllowInterruptions: Boolean;
				DlsByOther: longint;
				Signature: string[80];
				Columns: Boolean;																{True = 2 Column Mode}
				MessComp: Real;
				XferComp: Real;
				BonusTime: longint;
				AutoSense: boolean;
				ChatANSI: boolean;															{True = ANSI Chatroom}
				MessHeader: (MessOn, MessOff, MessOnNoNew);
				TransHeader: (TransOn, TransOff, TransOnNoNew);
				reserved: packed array[0..49] of char;
			end;

		AddressBookHand = ^AddressBookPtr;
		AddressBookPtr = ^AddressBookArray;
		AddressBookArray = array[1..40] of string[45];

		BDact = (ListText, Prompt, None, Chat, Writing, Repeating);

		aLine = packed array[0..79] of char;

		MessgHand = ^MessgPtr;
		MessgPtr = ^HermesMesg;
		HermesMesg = array[1..300] of string[161];

		ScrnKeysPtr = ^ScrnKeys;
		ScrnKeys = array[0..1000] of aLine;

		PtrToLong = ^longint;
		PtrToWord = ^integer;

		flagType = packed array[0..15] of boolean;

		resultCode = record
				num: integer;
				portRate: longint;
				effRate: longint;
				desc: string[19];
			end;
		modemDriverHand = ^modemDriverPtr;
		modemDriverPtr = ^modemDriver;
		modemDriver = record
				name: string[19];
				reset: string[21];
				bbsInit: string[79];
				termInit: string[79];
				hwOn: string[21];
				hwOff: string[21];
				lockOn: string[21];
				lockOff: string[21];
				ansModem: string[9];
				numResults: integer;
				rs: array[0..99] of resultCode;
			end;
		MoDrList = array[0..64] of modemDriver;
		MoDrListPtr = ^MoDrList;
		MoDrListHand = ^MoDrListPtr;

		ProcSubPtr = ^protocolo;
		protocolo = packed record
				pFlags: FlagType;
				refCon: longint;
				protoName: Str255;
				autoCom: Str255;
				protHand: handle;
				ProtMode: integer;
				resID: integer;
			end;
		ProtocolsHand = ^ProtocolsPtr;
		ProtocolsPtr = ^ProtocolsRec;
		ProtocolsRec = record
				numProtocols: integer;
				Prots: array[1..10] of protocolo;
			end;

		ProcList = record
				procID: integer;
				itemID: integer;
				HMenuID: integer;
				HItemID: integer;
				subName: stringHandle;
				pFlags: integer;
				funcMask: integer;
				refCon: longint;
			end;

		ProcMenuHandle = ^ProcMenuPtr;
		ProcMenuPtr = ^ProcMenu;
		ProcMenu = record
				mode: integer;
				pMenu: MenuHandle;
				Updater: ProcPtr;
				transIndex: integer;
				transMessage: integer;
				transRefCon: longint;
				Proto: XFERStuffHand;
				pCount: integer;
				firstID: integer;
				foldID: integer;
				autoCount: integer;
				autoComs: handle;
				theProcList: array[0..5] of ProcList;
			end;

		eInfoHand = ^eInfoPtr;
		eInfoPtr = ^eInfoRec;
		eInfoRec = record
				allTime: boolean;
				GameIdle: boolean;
				CheckLogon: boolean;
				CheckMenu: boolean;
				MenuCommand: string[16];
				minSLforMenu: integer;
				AccessLetter: char;
				CompiledForVers: integer;
				MinVersReq: integer;
				reserved: array[1..15] of char;
			end;

		HermesPrompt = record
				promptLine: string[80];   	{actual prompt text line}
				allowedChars: string[100]; {all other characters ignored, set to zero for full acceptance of everything}
				replaceChar: char;          {replace all input with this character for output, i.e. Password entry, set null for nothing}
				Capitalize: boolean;        {capitalize all incoming characters}
				enforceNumeric: boolean; 		{are numbers accepted?  overrides allowedChars string}
				autoAccept: boolean;    		{automatically accept on numeric/character input deemed complete}
				wrapAround: boolean;   			{at end of prompt, wrap text to next line using excess string in defs}
				wrapsonCR: boolean;
				breakChar: char;          	{this key will override autoAccept and go to the next input}
				HermesColor: integer;  			{on Hermes ANSI from 0-7...sets color on output, -1 is no ANSI}
				InputColor: integer;    		{same as above except for user input}
				numericLow: longint;				{if enforceNumeric, low range}
				numericHigh: longint;				{if enforceNumeric, high range}
				maxChars: integer;					{maximum accepted number of characters}
				ansiAllowed: Boolean;				{Ansi Allowed, Ctrl-P Basically}
				KeyString1: string[10];		{on key input, character 1 of this being received will output rest of string}
				KeyString2: string[10];		{see above}
				KeyString3: string[10];
			end;

		intListHand = ^intListPtr;
		intListPtr = ^intListArr;
		intListArr = array[0..0] of integer;

		MyQuoteRec = record
				WasSeg: boolean;		{USE THIS FOR SYSOP PAUSES IN SPY MODE}
				LastWasOld: boolean;
				LoggedOn: boolean;
				Entered: boolean;
				MesPos: longint;				{Current Position of Quoter}
				MesEndPos: longint;			{End of Message Position}
				LineAt: integer;
				wrap2: string[161];
				wrap: string[161];
				CS: string[161];
				Temp: string[161];
				This: MessgHand;				{What we've Quoted}
				AddINIT: string[40];
				curChar: char;
			end;

		QuoteRec = record
				QuoteMark: longint;			{Current Quote Mark}
				QuoteEnd: longint;			{End of Available Quoting}
				QuotingText: MessgHand;	{Original Message SetUp for Quoting}
				Initials: string[4];		{Initals of Poster}
				Header: str255;					{The configured Quote Header}
				GaveHeader: boolean;		{Was the Header attached to the message already?}
			end;

		ActionWordRec = record
				ActionWord: string[14];	{The Action Word}
				TargetUser: str255;				{Text sent to the Target User}
				OtherUser: str255;				{Text sent to other users}
				Initiating: str255;				{Text sent to Initiating User}
				Unspecified: str255;			{Text sent if there is no Target User}
			end;

		ActionWordListRec = record
				ActionWord: string[14];	{The Action Word}
				Offset: longint;					{Offset of the action word in the Action Word Shared File}
			end;

		ActionWordHandle = ^ActionWordPtr;
		ActionWordPtr = ^ActionWordArray;
		ActionWordArray = array[0..0] of ActionWordListRec;

		ChannelRec = record
				Active: boolean;												{Is this Channel Active?}
				ChannelName: string[40];								{Name of this Channel}
				NumInChannel: integer;									{Number of people in this Channel}
			end;

		ChatHandle = ^ChatPtr;
		ChatPtr = ^ChatRec;
		ChatRec = record
				NumActionWords: integer;								{Total Number of Action Words}
				NumChannels: integer;										{Total Number of Channels}
				Channels: array[0..0] of ChannelRec;		{Dynamic array of Channels}
			end;

		BufferHand = ^BufferPtr;
		BufferPtr = ^BufferArray;
		BufferArray = array[1..180] of string[135];

		PrivateDataRec = record
				WhoRequested: integer;	{Node Number of user requesting private chat}
				Reason: string[80];		{The reason for the request}
				SavedPrompt: HermesPrompt;
				SavedcurPrompt: str255;
				SavedSection: integer;
				SavedAction: BDact;
			end;

		UserChatRec = record
				ChatMode: (ANSIChat, TextChat);
				ToNode: integer;													{Message to this Node}
				PrivateRequest: integer;									{Node requesting private chat with}
				PrivateData: PrivateDataRec;
				WhereFrom: (Nowhere, InChatroom, Somewhere, AlreadyIn);
				TheMessage: array[1..3] of string[80];	{Message being sent}
				Status: (Chatting, SendingMessage, ActionWord);
				ChannelNumber: integer;										{Channel User is in}
				InputPos: Point;													{Position of Input Cursor}
				OutputPos: integer;												{Position of OutPut Cursor}
				BlockWho: integer;												{User Number, 0 = All Users, -1 = No Users}
				BufferSize: integer;											{Number of lines in Buffer, Max 180}
				Buffer: BufferHand;												{Array for scroll back buffer.}
				Scrolling: boolean;												{True if looking through buffer}
				ScrollPosition: integer;									{Mark for scrolling in Buffer}
				LastScrollBack: boolean;
			end;

		MessageSearchHand = ^MessageSearchPtr;
		MessageSearchPtr = ^MessageSearchRec;
		MessageSearchRec = record
				SearchTo: boolean;
				SearchFrom: boolean;
				SearchSubject: boolean;
				SearchText: boolean;
				SearchAll: boolean;
				SearchForums: array[1..23] of boolean;	{21 is for Search All,22 Seach This Conf, 23 Search by QScan}
				KeyWord: string[40];
				MatchedMessage: boolean;
				MatchedDate: longint;
				NumFound: integer;
				MessageArray: array[0..0] of integer;
			end;

		HermUserGlobHand = ^HermUserGlobPtr;
		HermUserGlobPtr = ^HermUserGlobs;
		HermUserGlobs = record
				rawBuffer: packed array[0..4096] of char; { used by the DRIVER -  DON'T touch it }
				incoming: packed array[0..4096] of char;   {don't touch this either}
				activeUserExternal: integer;   {if >0 then external will be called}
				BoardMode: (Waiting, Terminal, User, Answering, Failed);
				BoardSection: (Logon, NewUser, MainMenu, TransferMenu, MessageMenu, ChatStage, Defaults, Email, GFiles, Utilities, EXTERNAL, rmv, MoveFiles, killMail, Batch, MultiChat, tranDef, MultiMail, Noder, messUp, renFiles, readAll, RmvFiles, UEdit, USList, BBSlist, chUser, limdate, Quote, Download, Sort, Upload, OffStage, ListFiles, post, QScan, ReadMail, Amsg, Ext, ScanNew, ListMail, ListDirs, CatchUp, AskQuestions, AttachFile, DetachFile, SysopComm, FindDesc, SlowDevice, PrintXFerTree, ChatRoom, AddrBook, PrivateRequest, MessageSearcher, Colors, TelnetNegotiation);
				boardAction, savedBDaction, savedBD2: BDact;
				AutoDo: (AutoOne, AutoTwo, AutoThree, AutoFour, AutoFive, AutoSix, AutoSeven);
				ReadDo: (ReadOne, ReadTwo, ReadThree, ReadFour, ReadFive, ReadSix, ReadSeven, ReadEight, JumpForum, ReadNine, ReadTen, ReadEleven, ReadTwelve, Read13, Read14, Read15, Read16);
				EmailDo: (WhichUser, EmailCheck, EmailOne, EmailTwo, EmailThree, EmailFour, EmailFive, EmailSix, EmailSeven, EmailEight, EmailNine, EMailTen, EMailEleven);
				MultiDo: (MultiOne, MultiTwo, MultiThree, MultiFour);
				MultiChatDo: (Mult1, Mult2);
				BatDo: (BatOne, BatTwo, BatThree, BatFour, BatFive, BatSix, BatSeven, BatEight);
				KillDo: (KillOne, KillTwo, KillThree, KillFour, KillFive, KillSix);
				TransDo: (TrOne, TrTwo, TrThree, TrFour);
				SlowDo: (SlowOne, SlowTwo, SlowThree, SlowFour, SlowFive, SlowSix, SlowSeven);
				bbsLdo: (Bone, BTwo, BThree, BFour, BFive, bSix, bSeven);
				upMess: (MessUpOne, MessUpTwo, MessUpThree);
				AllDo: (AllOne, AllOneA, AllTwo, AllThree);
				GFileDo: (G1, G2, G3, G4, G5, G6);
				ExtenDo: (ex1, ex2, ex3, EX4);
				DownDo: (DownOne, Down2, DownTwo, DownThree, DownRequest, DownFour, DownFive, DownSix, DownSeven);
				RenDo: (RenOne, RenTwo, RenThree, RenFour, RenFive, RenSix, RenRob, RenSeven, RenEight);
				SortDo: (SortOne, SortTwo, SortThree);
				RFDo: (RFOne, RFTwo, RFThree, RFFour, RFFive, RFSix, RFSeven, RFEight);
				ChatDo: (ChatOne, ChatTwo, ChatThree);
				NodeDo: (NodeOne, NodeTwo, NodeThree, NodeFour, NodeFive, NodeSix, NodeSeven);
				PostDo: (PostOne, PostTwo, PostThree, PostFour, PostFive);
				UploadDo: (UpOne, UpTwo, UpRob, UpThree, UpFour, UpFive, UpSix, UpSeven, UpEight);
				ListDo: (ListOne, ListTwo, ListThree, ListFour, ListFive, ListSix, ListSeven, ListEight);
				QDo: (Qone, QTwo, QThree, QFour, QFive, QSix, QMove, QMove2, QSeven, QEight);
				UEdo: (EnterUE, UOne, UTwo, UThree, UFour, UFive, USix, USeven, UEight, UNine, UTen, UEleven, UTwelve, U13, U14, U15, U16, U17, U18, U19, U20, U21, U22, U23, U24, U25, U26, U27, U28, U29, U30);
				rmvDo: (RmvOne, RmvTwo);
				DefaultDo: (DefaultOne, DefaultTwo, DefaultThree, DefaultFour, DefaultFive, DefaultSix, DefaultSeven, DefaultEight, DefaultNine, DefaultTen, DefaultEleven, DefaultTwelve, DefaultThrt, def14, def15, def16, def17, def18, D18, D19, D20, D21, D22, D24, D23, D25, D26, D27, D28, D29, D30, D31, D32, D33, D34, D35);
				MainStage: (MenuText, MainPrompt, TextForce);
				Quiz: (NUP, CheckNUP, GetAlias, CheckAlias, GetReal, CheckReal, GetVoice, CheckVoice, GetData, CheckData, GetGender, CheckGender, GetCompany, CheckCompany, GetStreet, CheckStreet, GetCity, CheckCity, GetState, CheckState, GetZip, CheckZip, GetCountry, CheckCountry, GetMF1, CheckMF1, GetMF2, CheckMF2, GetMF3, CheckMF3, GetBirthdate, CheckBirthDate, GetComputer, CheckComputer, GetWidth, CheckWidth, GetHght, CheckHght, GetAnsi, CheckAnsi, CheckAnsiColor, GetClearing, CheckClearing, GetPause, CheckPause, GetColumns, CheckColumns, ShowEntries, CheckEntries, CheckPass, EnterPass, ShowInfo, NewTrans, NewTwoTrans, Q53, Q54, Q55, Q56, Q57, Q58, Q59, Q60);
				LogonStage: (Welcome, Name, CheckName, Password, Phone, SysPass, ChkSysPass, CheckStuff, Hello, CheckInfo, Stats, StatAuto, Transition, Trans1, DoExternalStage, Trans2, Trans3, Trans4);
				OffDo: (KeepNew, SureQuest, OffText, Hanger);
				AttachDo: (Attach0, Attach1, Attach2, Attach3, Attach4, Attach5, Attach6, Attach7, Attach8, Attach9, Attach10, Attach11);
				DetachDo: (Detach1, Detach2, Detach3, Detach4, Detach5);
				FDescDo: (FDesc1, FDesc2, FDesc3, FDesc4, FDesc5, FDesc6, FDesc7, FDesc8, FDesc9);
				MoveDo: (moveOne, MoveTwo, MoveThree, MoveFour, MoveFive, MoveSix, MoveSeven);
				ExternalDo: (external1, external2, theExternal);
				ScanNewDo: (Scan1, Scan2, Scan3, Scan4, Scan5);
				QuoterDo: (Quote1, Quote2, Quote3, Quote4, Quote5, Quote6, Quote7, Quote8, Quote9, Quote10, QTR1, QTR2, QTR3);
				myProcMenu: ProcMenuHandle;
				myPrompt: HermesPrompt;
				replyStr, MenuCommands, ansInProgress, curPrompt, mDriverName, enteredPass: str255;
				curBaudNote, enteredPass2, typeBuffer, fileMask, excess: str255;
				inportName, outportname, replyToStr, lastTransError, SavedInPort, chatreason: str255;
				inits, openTextSize, lastKeyPressed, startedChat, lastTry, lastFTUpdate: longint;
				currentBaud, lastLastPressed, lastCurBytes, crossLong, curTextPos, subtractOn: longInt;
				lastBlink, TimeBegin, ExtraTime, Uptime, Downtime, lastLeft, timeout, startCPS: longint;
				nodeType, headMessage, lnsPause, inputRef, outputRef, frontCharElim, openTextRef, MaxPromptChars, atEMail, EndAnony, totalEMails, onBatchNumber: integer;
				sysopLogOn, Prompting, stopRemote, retob, inTransfer, inHalfDuplex, continuous, inZScan, inNScan, fromQScan, endQScan, newFeed, timeFlagged, Single, DoCheckMessage, InPause, allDirSearch, aborted, in8BitTerm, ANSIterm: boolean;
				callFMail, chatKeySysop, sentAnon, batchTrans, wrapPrompt, promptHide, sysopStop, triedChat, threadmode, reply, validLogon, readMsgs: boolean;
				gettingANSI, HWHH, dirUpload, goOffinLocal, shutDownSoon, wasMadeTempSysop, negateBCR, tabbyPaused: boolean;
				inScroll, countingDown, netMail, blinkOn, useDTR, capturing, amSpying, doCrashmail: boolean;
				matchInterface, replyToAnon, descSearch, goBackToLogon, ListedOneFile, returnafterprompt, afterHangup, listingHelp: boolean;
				toBeSent, protCodeHand: Handle;
				sendingNow: ptr;
				curWriting, curQuoting: TextHand;
				sysopKeyBuffer: charsHandle;
				optBuffer: CharsHandle;
				fileTransit: FLSHand;
				myBlocker: paramBlockRec;
				TextHnd: TextHand;
				bUploadCompense: longint;
				nodeDSPPBPtr: DSPPBPtr;
				nodeCCBPtr: TPCCB;
				nodeMPPPtr: MPPPBPtr;
				nodeSendCCBPtr, nodeRecCCBPtr, nodeAttnCCBPtr: Ptr;
				modemID, maxBaud, minBaud, inMessage, mesRead, maxLines, onLine, savedLine, configForum, inForum, inConf, numRptPrompt, realSL, inDir, tempDir, flsListed, fListedCurDir, curDirPos, tempInDir, crossInt, crossInt2, crossInt3, dirOpenNum, curNumFiles, xFerAutoStart, hangingUp, nodeCCBRefNum, useWorkspace, saveInForum, saveInSub, helpNum: integer;
				captureRef, curNumMess, activeProtocol, lastBatch: integer;
				thisUser, tempUser, MailingUser: UserRec;
				CarrierDetect: CarDetType;
				curmessage: MessgHand;
				lastFScan: longInt;
				myEmailList: intListHand;
				extTrans: XFERstuffHand;
				myTrans: internalTransfer;
				curBase: subDyHand;
				TransDilg: dialogPtr;
				curOpenDir: aDirHand;
				blinkRgn: rgnhandle;
				curIndex: MessIndexHand;
				myFido: FidoAddress;
				multiUsers: array[1..20] of integer;
				numMultiUsers, spying: integer;
				bufLns: integer;
				rsIndex, replyToNum: integer;
				curEMailRec: EMailRec;
				curMesgRec: MesgRec;
				fromMsgScan, dialing, waitDialResponse, alerted, GameIdleOn: boolean;
				dialDelay: longint;
				InvalidSerialJump, expiredJump: handle;
				serialBinary, databuffer: ptr;
				mySystNode: SystPtr;
				curFil: FilEntryRec;
				nodeDSPWritePtr: DSPPBPtr;
				savecolor: integer;
				SysOpNode: Boolean;
				Rings, NumRings, displayConf: integer;
				NodeName: string[30];
				SecLevel: Integer;
				NodeRest, LastKey: Char;
				_unused_Inner, FromBeg, FromDetach: Boolean;
				msgLine, myline, qname, AttachFName: Str255;
				inSubDir, TempSubDir, SubDirOpenNum: Integer;
				NewMsg, WasAttach, WasAttachMac, WasBatch, WasAMsg: Boolean;
				InRealDir, InRealSubDir: Integer;
				myQuote: MyQuoteRec;
				w, tempPos, NewSL, NumFails, MailOp, CountTimeWarn: integer;
{ myTempb was renamed to rawStdin in 3.5.10b2 }
				wasEmail, waswrapped, sendLogoff, WelcomeAlternate, rawStdin, UseNode: Boolean;
				crossint1, crossint4, crossint5, crossint6, crossint7, crossint8, crossint9: integer;
				wasAnonymous, isMM: Boolean;
				ExternVars: longint;
				callno: longint;
				AddressBook: AddressBookHand;
				TheQuote: QuoteRec;
				INetMail: boolean;
				TheChat: UserChatRec;
				ChatRoomDo: (EnterMain, ChatAEM1, ChatAEM2, ChatAEM3, ChatAEM4, ChatEM1, ChatEM2, ChatEM3, ChatEM4, ChatCheckPrompt, ChatSendTo, ChatSysop1, ChatSysop2, ChatSysop3, ChatBlockWho, ChatScroll, ChatScrollCheckP, ChatPrivate1, ChatPrivate2, ChatPrivate3);
				ABDo: (AB1, AB2, AB3, AB4, AB5, AB6, AB7, AB8, AB9, AB10, AB11, AB12);
				PrivateDo: (PR1, PR2, PR3);
				MessSearchDo: (MSearch1, MSearch2, MSearch3, MSearch4, MSearch5, MSearch6, MSearch7, MSearch8, MSearch9, MSearch10, MSearch11, MSearch12, MSearch13, MSearch14, MSearch15, MSearch16, MSearch17, MSearch18, MSearch19, MSearch20, MSearch21, MSearch22, MSearch23, MSearch24, MSearch25);
				MessageSearch: MessageSearchHand;
				wasSearching, noPause: boolean;
{ Added in 3.5.9b1 }
				nodeTCP: HermesTCP;
			end;

		FullUNamesRec = record
				n: string[31];
				lo: longint;
				del: boolean;
			end;
		FullUNames = array[1..2000] of FullUNamesRec;
		FullUPtr = ^FullUNames;
		FullNameHand = ^FullUPtr;

		HermesExDef = record
				name: string[41];
				SysopExternal: boolean;
				UserExternal: boolean;
				IconHandle: handle;
				allTheTime: boolean;
				GameIdle: boolean;
				CheckLogon: boolean;
				CheckMenu: boolean;
				MenuCommand: string[16];
				minSLforMenu: integer;
				AccessLetter: char;
				privatesNum: longint;
				codeHandle: handle;
				UResoFile: integer;
				RuntimeExternal: boolean;
				reserved: array[1..14] of char;
			end;
		ExternalList = array[1..20] of HermesExDef;
		ExternListPtr = ^ExternalList;
		ExternListHand = ^ExternListPtr;

		GFileSec = record
				SecName: string[50];
				minSL: integer;
				minAge: integer;
				restrict: char;
				reserved: packed array[1..13] of char;
			end;
		GFileSecHand = ^GFileSecPtr;
		GFileSecPtr = ^GFileSecRec;
		GFileSecRec = record
				numSecs: integer;
				Sections: array[1..99] of GfileSec;
			end;

		HermDataPtr = ^HermDataRec;
		HermDataRec = record
				SysPrivates: Handle;
				HSystPtr: SystPtr;
				HMForumPtr: MForumPtr;
				HMConfPtr: ^MConferencesArray;
				HEMail: MesgHand;
				HTForumPtr: DirListPtr;
				HTDirPtr: ForumIdxPtr;
				HGFilePtr: GFileSecPtr;
				HSecLevelsPtr: SecLevPtr;
				HMailerPtr: MailerPtr;
				NumHermUsers: PtrToWord;
				filesPath: StringPtr;
				extantEmails: PtrToWord;
				emailUnclean: PtrToWord;
				procs: array[0..0] of ProcPtr;
			end;

		UserXIPtr = ^UserXInfoRec;
		UserXInfoRec = record
				prefs: Handle;
				privates: Handle;
				extID: integer;
				totalNodes: integer;
				message: integer;
				curNode: PtrToWord;
				curUGlobs: PtrToLong;
				HSystPtr: SystPtr;
				HMForumPtr: MForumPtr;
				HMConfPtr: ^MConferencesArray;
				HEMail: MesgHand;
				HTForumPtr: DirListPtr;
				HTDirPtr: ForumIdxPtr;
				HGFilePtr: GFileSecPtr;
				HSecLevelsPtr: SecLevPtr;
				HMailerPtr: MailerPtr;
				HFeedbackPtr: FeedBackPtr;
				filesPath: StringPtr;
				HermUsers: UListHand;
				NumHermUsers: PtrToWord;
				extantEmails: PtrToWord;
				emailUnclean: PtrToWord;
				numExternal: integer;
				externals: ExternListHand;
				n: array[1..MAX_NODES] of HermUserGlobPtr;
				procs: array[0..0] of ProcPtr;
			end;

		OpenExternal = record
				number: integer;
				numAddedItems: integer;
				resourceFile: integer;
				codehandle: handle;
				exRefCon: longint;
				numext: integer;
			end;

		charStyle = packed record
				fcol: 0..15;
				bcol: 0..15;
				intense: boolean;
				underLine: boolean;
				blinking: boolean;
			end;
		charStylePtr = ^charStyle;

		myANSIwindow = record
				ansiPort: windowPtr;
				ansiVScroll: ControlHandle;
				ansiRect, cursorRect, savedWPos: rect;
				Cursor, anchor, elastic: point;
				topLine: integer;
				screen: packed array[0..23, 0..79] of char;
				screenInfo: packed array[0..23, 0..79] of CharStyle;
				curStyle, bufStyle: CharStyle;
				bigBuffer: scrnKeysPtr;
				sTopLine, sNumlines: integer;
				ansiState, scrnTop, scrnBottom, scrnLines: integer;
				ansiEnable, cursorOn, scrollFreeze, selectActive: boolean;
				numAnsiParams, curParam, saveV, saveH: integer;
				ansiParams: array[0..79] of byte;
			end;
		MyANSIWindPtr = ^myANSIwindow;

		myTWindRec = record
				w: windowPtr;
				s: ControlHandle;
				t: TEHandle;
				docClik: ProcPtr;
				wasResource: boolean;
				editable: boolean;
				origpath: str255;
				dirty: boolean;
			end;

		startInfoHand = ^startInfoPtr;
		startInfoPtr = ^startInfoRec;
		startInfoRec = record
				sharedPath: str255;
				cs: array[2..29] of longint;
			end;
		ImportHeaderArray = packed array[1..27] of char; {with trailing return}

		GTextRec = record
				OnOff: boolean; 		{Option On or Off}
				Operator: integer;	{1 = or Exact, 2 ≠  or Partial, 3 <, 4 >}
				Value: str255;
			end;

		GNumRec = record
				OnOff: boolean; 		{Option On of Off}
				Operator: integer;	{1 = or Exact, 2 ≠ or Partial, 3 <, 4 >}
				Value: longint;
			end;

		GRealRec = record
				OnOff: boolean; 		{Option On of Off}
				Operator: integer;	{1 = or Exact, 2 ≠ or Partial, 3 <, 4 >}
				Value: Real;
			end;

		GCharRec = record
				OnOff: boolean; 		{Option On of Off}
				Operator: integer;	{1 = or Exact, 2 ≠ or Partial, 3 <, 4 >}
				Value: array[1..26] of char;
			end;

		GlobalSearchHdl = ^GlobalSearchPtr;
		GlobalSearchPtr = ^GlobalSearchRec;
		GlobalSearchRec = record
				SecurityLevel: GNumRec;		{1}
				DownloadSL: GNumRec;			{2}
				AccessLetters: GCharRec;	{3}
				Restrictions: GCharRec;		{4}
				TimeAllowed: GNumRec;			{5}
				FirstCall: GNumRec;				{6}
				LastCall: GNumRec;				{7}
				MessagesPosted: GNumRec;	{8}
				EMailSent: GNumRec;				{9}
				TotalCalls: GNumRec;			{10}
				NumUploads: GNumRec;			{11}
				UploadK: GNumRec;					{12}
				NumDownloads: GNumRec;		{13}
				DownloadK: GNumRec;				{14}
				KCredit: GNumRec;					{15}
				City: GTextRec;						{16}
				State: GTextRec;					{17}
				Zip: GTextRec;						{18}
				Country: GTextRec;				{19}
				Company: GTextRec;				{20}
				Age: GNumRec;							{21}
				MaleFemale: GNumRec;			{22}
				Computer: GTextRec;				{23}
				Misc1: GTextRec;					{24}
				Misc2: GTextRec;					{25}
				Misc3: GTextRec;					{26}
				NormAltText: GNumRec;			{27}
				Password: GTextRec;				{28}
				VoicePhone: GTextRec;			{29}
				DataPhone: GTextRec;			{30}
				Sysop: GNumRec;						{31}
				Alert: GNumRec;						{32}
				Delete: GNumRec;					{33}
				DLRatioOneTo: GNumRec;		{34}
				PostRatioOneTo: GNumRec;	{35}
				XferComp: GRealRec; 			{36}
				MessComp: GRealRec; 			{37}
				MesgDay: GNumRec;					{38}
				LnsMessage: GNumRec;			{39}
				CallsPrDay: GNumRec;			{40}
				UseDayOrCall: GNumRec;		{41}
				Alias: GTextRec;					{42}
				RealName: GTextRec;				{43}
			end;

	var
		GUSearchV: GlobalSearchHdl;
		sysPrivatesNum: longint;
		myTE: TEHandle;
		held: array[1..MAX_NODES] of boolean;
		MenuCmds: packed array[1..50] of Char;
		sysopOpenDir: aDirHand;
		myOpenEx: OpenExternal;
		myExternals: ExternListHand;
		textWinds: array[0..9] of myTWindRec;
		theExtRec: UserXIPtr;
		theSysExtRec: HermDataPtr;
		ChatHand: ChatHandle;
		ActionWordHand: ActionWordHandle;
		numTextWinds, myResourceFile, numExternals, sysopNumFiles, sysopDirNum, sysopSubNum: integer;
		cursorRgn: rgnhandle;
		ssWind, statWindow: WindowPtr;
		theProts: ProtocolsHand;
		replySF: SFReply;
		SFSaveDisk: PtrToWord;					{ pointer to SFSaveDisk value }
		CurDirStore: PtrToLong;					{ pointer to CurDirStore value }
		gBBSwindows: array[1..MAX_NODES] of myANSIwindPtr;
		defaultStyle: charStyle;
		fullnames: fullnamehand;
		bullBool, statChanged, adspSupported, tcpSupported, newBBS: boolean;
		editingUser: UserRec;
		SysConfig, SystPrefs, GetUSelection, DialDialog, GetULSelection, SearchSelection: DialogPtr;
		BroadDilg, NewDilg, AccessDilg, GFileSelection, GetFBSelection, GetSelection, StringDilg: DialogPtr;
		GetDSelection, GetTESelection, NodeDilg, NodeDilg5, NodeDilg6, AboutDilg, MailDilg: DialogPtr;
		ImportStatusDlg, GlobalUSearch, SSLockDlg, MessSetup, ErrorDlg, ChatroomDlg: DialogPtr;
		QuoterDlg: DialogPtr;
		gMac: SysEnvRec;
		theEmail: MesgHand;
		numUserRecs, mySaveDisk, namesDisplay, availEmails, hermesFontSize, hermesFontDescent, hermesFontWidth, hermesFontHeight: integer;
		gInBackground, curDirvalid, XFerNeedsUpdate, maskFiles: boolean;
		NodeView: boolean;
		TabbyQuit: (NotTabbyQuit, CrashMail, MailerEvent);
		result: OSErr;
		HelpFile, SysopDesc: CharsHandle;
		eMailDirty: boolean;		{make sure surrounded by longs or ints for placement in externals}
		NodeHnd: NodeHand;
		i, fbuser: integer;
		editForum, beingRenamed, numFeedbacks, homeVol, textSearchCount, quit, nameorDesc: integer;
		sysopAvailC, screenSaver: boolean;
		SharedPath, SharedFiles, globalStr, textSearch: str255;
		MForum: MForumHand;
		MConference: MConferencesArray;
		intGFileRec: GFileSecHand;
		InitSystHand: SystHand;
		InitFBHand: FeedBackHand;
		writeDirecttoLog, answerCalls, hasGPI, unused1, gSndCalledBack: boolean;
		menuHand: NodeMenuHand;
		transHand: TransMenuHand;
		newHand: NewUserHand;
		Forums: DirListHand;
		ForumIdx: ForumIdxHand;
		SecLevels: SecLevHand;
		Mailer: MailerHand;
		myUsers: UListHand;
		curGlobs: HermUserGlobPtr;
		activeNode: integer;
		UserCell: cell;
		TheNodes: array[1..MAX_NODES] of HermUserGlobPtr;
		ANSIColors: array[0..15] of RGBCOLOR;
		visibleNode, lastSelected, charNum, bitNum, unused2, setNewNodes: integer;
		gTempRect: rect;
		KBNunc: keyMap;
		myCurdir, lastIdle, dailyTabbyTime, lastSSDraw, SSLow, SSHigh, SSCount: longint;
		dragFirst: cell;
		myChannel: SndChannelPtr;
		mySound: Handle;
		UserList, XFerList, ExtList, UList, GUList, GSearchList: listHandle;
		gSerialBinary: ptr;
		SFXFerTE: TEHandle;
		mppDrvrRefNum, dspDrvrRefNum, gCCBRef, ippDrvrRefNum, numModemDrivers: integer;
		gDSP: DSPParamBlock;
		gMPP: MPPParamBlock;
		gCCB: TRCCB;
		gNTE: NamesTableEntry;
		gMBarHeight: integer;
		modemDrivers: MoDrListHand;
		EditingString, curr, whichtransfer, page, CheckUEditLength, GUSearchItem: Integer;
		newtransfer, CheckUEditN, CheckUEditAlpha: boolean;
		isUsingColor: boolean;
		BbsName: str255;
		OldAnsiColors: array[0..15] of integer;
		StringsRes, TextRes, StringSet: Integer;
		myStart: startInfoHand;
		aPict: PicHandle;
		cksms, cs: array[2..29] of longint;
(* Mailer Stuff Put Into Handle In Future *)
		FileSize: longint;					{Size of Generic Import File}
		GenericImport: CharsHandle;	{Working Data}
		PlaceInFile: longint;				{Number of Total Bytes read out of Generic Import File}
		NextRead: longint;					{Number of bytes to read into var GenericImport}
		ImportLoopTime: integer;		{Number of Cycles to Process Generic Import}
		HandleEmpty: boolean;				{True = Read More into var GenericImprt}
		NumImported: integer;				{Number of Messages Imported}
		DataLeft: longint;					{Position of Last byte Processed}
		curPlace: longint;					{Position of end of Message}
		ImportRef: integer;					{Generic Import File Reference Number}
		NetRef: integer;						{File Reference Number for Temp Net File}
		NumNets: integer;						{Number of Network Entries to Temp Net File}
		MessageLen: integer;				{Length of Message being Imported before Cleaning}
		RealLen: integer;						{Length of Message being Imported after Cleaning}
		BreakMessage: (NoBreak, FirstPass, OtherPass, LastPass);
		BreakNumber: integer;				{Number of Breaks}
		BreakTitle: string[80];
		BreakDate: string[80];
		BreakFrom: str255;
		BreakToNum: integer;
		BreakToName: str255;
		BreakInForum: integer;
		BreakInConf: integer;
		ForwardedToNet: boolean;
		MessHeader: ImportHeaderArray;
		lastGenericCheck: longint;	{Ticks of last Check for Generic Import File}
		isGeneric: boolean;	{We're Importing = True}
		GBytes: longint;	{Used to keep track and make sure Generic Import Size is not changing}
		MailerDo: (MailerOne, MailerTwo, MailerThree, MailerFour, MailerFive);
		SavedImport: boolean;				{Used for Looping through MailerDo}
(* End Mailer Import Stuff *)
{ Added in 3.5.10b2 }
		runtimeExternalNum: integer;

	procedure InitHermes;
	function QuickCheckSerial: boolean;
	procedure AlertUser;
	function PathNameFromDirID (DirID: longint; vRefnum: integer): str255;
	function PathNameFromWD (vRefNum: longint): str255;

implementation

{$S Initial_1}
	procedure AlertUser;
		var
			itemHit: INTEGER;
	begin
		SetCursor(arrow);
		itemHit := Alert(555, nil);
		ExitToShell;
	end; {AlertUser}

	procedure SetUpTheNodes;
		var
			i, NodesRes: integer;
			tempString: str255;
	begin
		NodesRes := OpenRFPerm(concat(SharedFiles, 'Nodes'), 0, fsRdWrPerm);
		for i := 1 to MAX_NODES do
			theNodes[i] := nil;
		if InitSystHand^^.numNodes < 1 then
			InitSystHand^^.numNodes := 1;
		if InitSystHand^^.numNodes > MAX_NODES then
			InitSystHand^^.numNodes := MAX_NODES;
		for i := 1 to InitSystHand^^.numNodes do
		begin
			theNodes[i] := HermUserGlobPtr(NewPtr(SizeOf(HermUserGlobs)));
			with theNodes[i]^ do
			begin
				boardMode := waiting;
				spying := 0;
				Prompting := false;
				ansInProgress := '';
				sysopLogon := false;
				quit := 0;
				realSL := -1;
				curWriting := nil;
				curQuoting := nil;
				curIndex := nil;
				TheQuote.QuotingText := nil;
				TextHnd := nil;
				protCodeHand := nil;
				nodeCCBPtr := nil;
				lastBlink := tickCount;
				BlinkRgn := NewRgn;
				FileTransit := FLSHand(newHandle(SizeOf(FLSRec)));
				MoveHHi(handle(FileTransit));
				HNoPurge(handle(fileTransit));
				FileTransit^^.numFiles := 0;
				FileTransit^^.batchTime := 0;
				FileTransit^^.batchKBytes := 0;
				curmessage := nil;
				sysopKeyBuffer := CharsHandle(NewHandle(0));
				HNoPurge(handle(sysopKeyBuffer));
				returnAfterPrompt := true;
				SysopStop := false;
				thisUser.UserNum := -1;
				CurrentBaud := 0;
				typeBuffer := '';
				optBuffer := nil;
				curOpenDir := nil;
				TheChat.Buffer := nil;
				extTrans := nil;
				activeUserExternal := -1;
				dialing := false;
				waitDialResponse := false;
				myTrans.active := false;
				capturing := false;
				tabbyPaused := false;
				savedInPort := '';
				transDilg := nil;
				curBase := nil;
				myEmailList := nil;
				MessageSearch := nil;
				nodeTCP.tcpPBPtr := nil;
				nodeTCP.tcpBuffer := nil;
				nodeTCP.tcpStreamPtr := nil;
				nodeTCP.tcpWDSPtr := nil;
				nodeHnd := NodeHand(GetResource('Node', i - 1));
				if nodeHnd <> nil then
				begin
					HNoPurge(handle(NodeHnd));
					MDriverName := NodeHnd^^.ModDrivName;
					maxBaud := NodeHnd^^.BaudMax;
					minBaud := NodeHnd^^.BaudMin;
					uptime := nodeHnd^^.uptime;
					bufLns := NodeHnd^^.bufferlines;
					HWHH := nodeHnd^^.hardShake;
					downtime := nodeHnd^^.downtime;
					useDTR := nodeHnd^^.DTRHangup;
					inportname := nodeHnd^^.myInport;
					outPortName := nodeHnd^^.myOutPort;
					nodename := nodeHnd^^.nodename;
					rings := nodeHnd^^.rings;
					if (inportname <> 'None') and (length(inPortName) > 0) then
					begin
						if (inportname = TCPNAME) then
							nodeType := 3
						else if (inportname = ADSPNAME) then
							nodeType := 2
						else
							nodeType := 1;
					end
					else
						nodeType := -1;
					goOffinLocal := NodeHnd^^.localHook;
					SysOpNode := NodeHnd^^.SysOpNode;
					NodeRest := NodeHnd^^.NodeRest;
					SecLevel := NodeHnd^^.SecLevel;
					matchInterface := nodeHnd^^.matchSpeed;
					timeout := nodeHnd^^.timeoutIn;
					carrierDetect := nodeHnd^^.carDet;
					WelcomeAlternate := NodeHnd^^.WelcomeAlternate;
					NewSL := NodeHnd^^.NewSL;
					HPurge(handle(NodeHnd));
					ReleaseResource(handle(NodeHnd));
				end;
			end;
		end;
		activeNode := 1;
		curGlobs := theNodes[1];
		visibleNode := 1;
		CloseResFile(NodesRes);
	end;

	function PathNameFromDirID (DirID: longint; vRefnum: integer): str255;
		var
			Block: CInfoPBRec;
			directoryName, FullPathName: str255;
			err: OSerr;
	begin
		FullPathName := '';
		with block do
		begin
			ioNamePtr := @directoryName;
			ioDrParID := DirId;
		end;
		repeat
			with block do
			begin
				ioVRefNum := vRefNum;
				ioFDirIndex := -1;
				ioDrDirID := block.ioDrParID;
			end;
			err := PBGetCatInfo(@Block, FALSE);
			directoryName := concat(directoryName, ':');
			fullPathName := concat(directoryName, fullPathName);
		until (block.ioDrDirID = 2);
		PathNameFromDirID := fullPathName;
	end;

	function PathNameFromWD (vRefNum: longint): str255;
		var
			myBlock: WDPBRec;
			err: OSerr;
	begin
		with myBlock do
		begin
			ioNamePtr := nil;
			ioVRefNum := vRefNum;
			ioWDIndex := 0;
			ioWDProcID := 0;
		end;
		err := PBGetWDInfo(@myBlock, FALSE);
		with myBlock do
			PathNameFromWD := PathNameFromDirID(ioWDDirID, ioWDVRefnum)
	end;

	function makeADir (path: str255): OSerr;
		var
			myHParms: HParamBlockRec;
	begin
		myHParms.ioCompletion := nil;
		myHParms.ioNameptr := @path;
		myHParms.ioVRefNum := 0;
		myHParms.ioDirID := 0;
		result := PBDirCreate(@myHParms, false);
		makeADir := result;
	end;

	procedure MakeHTxt (name: str255);
		var
			myh: handle;
			t1: str255;
	begin
		t1 := concat('This is the "', name, '" file.');
		myh := NewHandle(length(t1));
		BlockMove(pointer(@t1[1]), pointer(myH^), length(t1));
		AddResource(myh, 'HTxt', UniqueID('HTxt'), name);
	end;

	procedure DoCapsName (var doName: str255);
		var
			i, x: integer;
			inWord: boolean;
			key: char;
			tempString: str255;
	begin
		tempString := doName;
		inWord := false;
		i := 0;
		x := pos('BBS', tempString);
		repeat
			i := i + 1;
			if (tempString[i - 1] = '''') then
				inWord := true;
			if (tempString[i] < 'A') or (tempString[i] > 'Z') then
				inWord := false;
			if (x > 0) and ((x = i) or (x + 1 = i) or (x + 2 = i)) then
				inWord := false;
			if inWord then
			begin
				key := tempString[i];
				key := char(integer(key) + 32);
				tempString[i] := key;
			end;
			if ((tempString[i] >= 'A') and (tempString[i] <= 'Z')) and not inWord then
				inWord := true;
		until (i >= length(tempString));
		doName := tempString;
	end;

	procedure CreateSystemPrefs (Path, HFPath: str255);
	external;
	procedure CreateMessage (Path: str255);
	external;
	procedure CreateMailer (Path, HDPath: str255);
	external;
	procedure CreateNewUser (Path: str255);
	external;
	procedure CreateSecurityLevels (Path: str255);
	external;
	procedure CreateForumInformation (Path: str255);
	external;
	procedure CreateDirectories (Path, HFPath: str255);
	external;
	procedure CreateActionWords (Path: str255);
	external;


	function mySFGetHook (MySFitem: integer; theDialog: DialogPtr): integer;
		var
			t1, t2, t3, t4: str255;
			i, sRef, b, c, z, x, Rob: integer;
			freshSyst: SystHand;
			freshGs: GFileSecHand;
			myTH: handle;
			tl: longint;
			freshNode: NodeHand;
			rHandle: Handle;
			tempRT: ResType;
	begin
		if mySFItem = -1 then
			ParamText('Please select your ''System Prefs'' file, or click New to create a new BBS.', '', '', '')
		else if mySFItem = 12 then
		begin
			t1 := concat(PathnameFromDirID(curDirStore^, -(SFSaveDisk^)), 'Hermes Files');
			if makeADir(t1) = noErr then
			begin
				sharedPath := concat(t1, ':');
				t2 := concat(t1, ':Messages');
				result := makeADir(t2);
				result := makeADir(concat(t2, ':Forum #1'));
				result := Create(concat(t2, ':Forum #1:Forum #1 AHDR'), 0, 'HRMS', 'TEXT');
				result := Create(concat(t2, ':Forum #1:Forum #1 HDR'), 0, 'HRMS', 'TEXT');
				result := makeADir(concat(t2, ':Email'));
				result := makeADir(concat(t1, ':Logs'));
				result := makeADir(concat(t1, ':Logs:Network'));
				result := makeADir(concat(t1, ':Data'));
				result := makeADir(concat(t1, ':GFiles'));
				result := makeADir(concat(t1, ':Files'));
				result := makeADir(concat(t1, ':Shared Files'));
				result := makeADir(concat(t1, ':Externals'));
				result := makeADir(concat(t1, ':Forms'));
				result := makeADir(concat(t1, ':Misc'));
				result := makeADir(concat(t1, ':Temp'));
				result := makeADir(concat(t1, ':Temp:jython'));
				result := makeADir(concat(t1, ':Data:Sysop'));
				result := Create(concat(t1, ':Data:Sysop:Sysop AHDR'), 0, 'HRMS', 'TEXT');
				result := Create(concat(t1, ':Data:Sysop:Sysop HDR'), 0, 'HRMS', 'TEXT');
				result := makeADir(concat(t1, ':Data:Area #1'));
				result := Create(concat(t1, ':Data:Area #1:Area #1 AHDR'), 0, 'HRMS', 'TEXT');
				result := Create(concat(t1, ':Data:Area #1:Area #1 HDR'), 0, 'HRMS', 'TEXT');
				result := makeADir(concat(t1, ':Files:Sysop'));
				result := makeADir(concat(t1, ':Files:Area #1'));
				result := makeADir(concat(t1, ':Files:Sysop:01'));
				result := makeADir(concat(t1, ':Files:Sysop:02'));
				result := makeADir(concat(t1, ':Files:Sysop:03'));
				for i := 1 to 9 do
					result := makeADir(stringOf(t1, ':Files:Area #1:0', i : 0));
				for i := 10 to 15 do
					result := makeADir(stringOf(t1, ':Files:Area #1:', i : 0));
				t2 := concat(t1, ':Misc:Trash Users');
				result := Create(t2, 0, 'HRMS', 'TEXT');
				result := FSOpen(t2, 0, i);
				t2 := concat('FUCK', char(13), 'SHIT', char(13));
				tl := length(t2);
				result := FSWrite(i, tl, @t2[1]);
				result := FSClose(i);
				result := Create(concat(t1, ':Shared Files:Users'), 0, 'HRMS', 'DATA');

				result := Create(concat(t1, ':Shared Files:Address Books'), 0, 'HRMS', 'DATA');

				t2 := concat(t1, ':Shared Files:System Prefs');
				CreateSystemPrefs(t2, t1);

				t2 := concat(t1, ':Shared Files:Mailer Prefs');
				i := Pos(':', t1);
				t4 := Copy(t1, 1, i);
				CreateMailer(t2, t4);

				t2 := concat(t1, ':Shared Files:New User');
				CreateNewUser(t2);

				t2 := concat(t1, ':Shared Files:Security Levels');
				CreateSecurityLevels(t2);

				t2 := concat(t1, ':Shared Files:Directories');
				CreateForumInformation(t2);
				CreateDirectories(t2, t1);

				t2 := concat(t1, ':Shared Files:Message');
				CreateMessage(t2);

				t2 := concat(t1, ':Shared Files:Action Words');
				CreateActionWords(t2);

				t2 := concat(t1, ':Shared Files:Text');
				result := Create(t2, 0, 'HRMS', 'DATA');
				CreateResFile(t2);
				sRef := OpenRFPerm(t2, 0, fsRdWrPerm);
				if (sRef <> -1) then
				begin
					UseResFile(myResourceFile);
					b := Count1Resources('NHTx');
					for i := 1 to b do
					begin
						myTH := Get1IndResource('NHTx', i);
						GetResInfo(myTH, c, tempRT, t3);
						DetachResource(myTH);
						UseResFile(sRef);
						AddResource(myTH, 'HTxt', c, t3);
						WriteResource(myTH);
						DetachResource(myTH);
						AddResource(myTH, 'ATxt', c, t3);
						WriteResource(myTH);
						DetachResource(myTH);
						UseResFile(myResourceFile);
					end;
					UseResFile(sRef);
{    MakeHTxt('ANSI Download');   ** If The Need Ever Arises ** }
					UseResFile(myResourceFile);
					CloseResFile(sRef);
				end;

				t2 := concat(t1, ':Shared Files:Menus');
				result := Create(t2, 0, 'HRMS', 'DATA');
				CreateResFile(t2);
				sRef := OpenRFPerm(t2, 0, fsRdWrPerm);
				if (sRef <> -1) then
				begin
					UseResFile(myResourceFile);
					myth := Get1Resource('nBBS', 133);
					DetachResource(myth);
					UseResFile(sRef);
					AddResource(myth, 'MenU', 0, 'Main Menu Prefs');
					UseResFile(myResourceFile);
					myth := Get1Resource('nBBS', 134);
					DetachResource(myth);
					UseResFile(sRef);
					AddResource(myth, 'MenU', 1, 'Transfer Menu Prefs');
					CloseResFile(sRef);
				end;

				t2 := concat(t1, ':Shared Files:Modem Drivers');
				result := Create(t2, 0, 'HRMS', 'DATA');
				CreateResFile(t2);
				sRef := OpenRFPerm(t2, 0, fsRdWrPerm);
				if (sRef <> -1) then
				begin
					UseResFile(myResourceFile);
					b := Count1Resources('MoDr');
					for i := 1 to b do
					begin
						myTH := Get1IndResource('MoDr', i);
						GetResInfo(myTH, c, tempRT, t3);
						DetachResource(myTH);
						UseResFile(sRef);
						AddResource(myTH, 'MoDr', c, t3);
						UseResFile(myResourceFile);
					end;
					CloseResFile(sRef);
				end;

				t2 := concat(t1, ':Shared Files:Strings');
				result := Create(t2, 0, 'HRMS', 'DATA');
				CreateResFile(t2);
				sRef := OpenRFPerm(t2, 0, fsRdWrPerm);
				if (sRef <> -1) then
				begin
					UseResFile(myResourceFile);
					rhandle := Get1Resource('STR#', 17);
					DetachResource(rhandle);
					UseResFile(sRef);
					AddResource(rhandle, 'STR#', 1, 'Miscellaneous Strings');
					WriteResource(rhandle);
					DetachResource(rhandle);
					AddResource(rhandle, 'STR#', 3, 'Alt. Miscellaneous Strings');
					WriteResource(rhandle);
					DetachResource(rhandle);
					CloseResFile(sRef);
				end;

				t2 := concat(t1, ':Shared Files:Nodes');
				result := Create(t2, 0, 'HRMS', 'DATA');
				CreateResFile(t2);
				sRef := OpenRFPerm(t2, 0, fsRdWrPerm);
				if (sRef <> -1) then
				begin
					freshNode := NodeHand(NewHandleClear(SizeOf(NodeRec)));
					with freshNode^^ do
					begin
						baudMax := 18;
						baudMin := 9;
						myInPort := 'None';
						myOutPort := 'None';
						modDrivName := 'Generic 144/288';
						localHook := true;
						matchSpeed := false;
						timeoutIn := 4;
						BufferLines := 200;
						carDet := CTS5;
						SysOpNode := False;
						rings := 1;
						SecLevel := 0;
						WelcomeAlternate := false;
						NewSL := 10;
						NodeRest := char(0);
					end;
					for i := 0 to MAX_NODES_M_1 do
					begin
						UseResFile(sRef);
						freshNode^^.nodename := stringOf('Node #', i + 1 : 0);
						AddResource(handle(freshNode), 'Node', i, '');
						WriteResource(handle(freshNode));
						DetachResource(handle(freshNode));
					end;
					CloseResFile(sRef);
				end;

				t2 := concat(t1, ':Shared Files:GFiles');
				result := Create(t2, 0, 'HRMS', 'DATA');
				CreateResFile(t2);
				sRef := OpenRFPerm(t2, 0, fsRdWrPerm);
				if (sRef <> -1) then
				begin
					UseResFile(sRef);
					freshGs := GFileSecHand(NewHandleClear(SizeOf(GFileSecRec)));
					AddResource(handle(freshGs), 'Gfil', 0, 'GFile Data');
					CloseResFile(sRef);
				end;
				newBBS := true;
				mySFItem := 3;
			end
			else
				SysBeep(10);
		end;
		mySFGetHook := mySFItem;
	end;

	function CTBInstalled: boolean;
		const
			commToolboxTrap = $8B;
			UnimplementedTrapNumber = $9F;
	begin
		CTBInstalled := true;
		if NGetTrapAddress(unimplementedTrapNumber, OSTrap) = NGetTrapAddress(commtoolboxTrap, OSTrap) then
			CTBInstalled := false;
	end;

	procedure SetupMenus;
		var
			menuBar: handle;
			nyet: menuHandle;
			i: integer;
			tempLong: longint;
			ts1, tempstring: str255;
	begin
		menuBar := GetNewMBar(128);
		SetMenuBar(menuBar);
		DisposHandle(menuBar);
		AddResMenu(GetMHandle(mApple), 'DRVR');
		Nyet := GetMenu(10);
		InsertMenu(nyet, -1);
		AddResMenu(getMHandle(10), 'HTxt');
		nyet := GetMenu(57);
		InsertMenu(nyet, -1);
		nyet := GetMenu(55);
		InsertMenu(nyet, -1);
		nyet := GetMenu(50);
		InsertMenu(nyet, -1);
		nyet := GetMenu(53);
		InsertMenu(nyet, -1);
		nyet := GetMenu(54);
		InsertMenu(nyet, -1);
		nyet := GetMenu(70);
		InsertMenu(nyet, -1);
		nyet := GetMenu(72);
		InsertMenu(nyet, -1);
		nyet := GetMenu(11);
		InsertMenu(nyet, -1);
		AddResMenu(getMHandle(11), 'ATxt');
		nyet := GetMenu(20);
		InsertMenu(nyet, -1);
		nyet := GetMenu(12);
		InsertMenu(nyet, -1);

		DisableItem(GetMHandle(mTerminal), 0);
		DisableItem(GetMHandle(mUser), 0);
		DisableItem(getMHandle(mUser), 9);
		nyet := GetMHandle(mLog);
		for i := 1 to InitSystHand^^.logDays do
		begin
			GetDateTime(tempLong);
			IUDateString(tempLong - (86400 * i), shortDate, ts1);
			AppendMenu(nyet, ' ');
			SetItem(nyet, countMItems(nyet), ts1);
		end;
		nyet := GetMHandle(mNetLog);
		for i := 1 to InitSystHand^^.logDays do
		begin
			GetDateTime(tempLong);
			IUDateString(tempLong - (86400 * i), shortDate, ts1);
			AppendMenu(nyet, ' ');
			SetItem(nyet, countMItems(nyet), ts1);
		end;

		nyet := GetMHandle(mSysOp);
		if (theNodes[visibleNode]^.nodeType <= 0) then
			DisableItem(getMHandle(mSysop), 14)
		else
			EnableItem(getMHandle(mSysop), 14);
		for i := 1 to InitSystHand^^.numNodes do
		begin
			tempstring := stringOf(i : 0, ': ', theNodes[i]^.nodename);
			AppendMenu(nyet, ' ');
			SetItem(nyet, countMItems(nyet), tempstring);
		end;
		CheckItem(nyet, visibleNode + 15, true);
		AppendMenu(nyet, '(-');
		AppendMenu(nyet, 'Status Window/\');


		DrawMenuBar;
	end;

	function Hfilefilter (thePB: parmBlkPtr): Boolean;
	begin
		if (thePb^.ioNamePtr^ = 'System Prefs') then
			HfileFilter := false
		else
			HFileFIlter := true;
	end;

	procedure InitHermes;
		var
			i, j, sharedRef, SystemRes, x: integer;
			tyto: str255;
			repo: SFReply;
			dere: SFTypeList;
			abg: point;
			tempLong: longInt;
			initFeedbackHand: FeedBackHand;
			KBNunc: keyMap;
			rhandle, ahandle: handle;
			tempGD: GDHandle;
			myHUtils2: CharsHandle;
			len, cksm: longint;
			tempSystHand: SystHand;
	begin
		MenuCmds := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*-=+[]{}\|;:.<>/?';
		gInBackground := FALSE;
		InitCursor;
		FlushEvents(everyEvent, 0);
		result := SysEnvirons(2, gMac);
		result := GetVol(@globalStr, homeVol);
		myResourceFile := curResFile;
		sfSaveDisk := PtrToWord(kSFSaveDisk);
		curDirStore := PtrToLong(kCurDirStore);
		newBBS := false;
		if (gMac.machineType < 1) or (gMac.systemVersion < $0604) or not CTBInstalled then
			AlertUser;
		myStart := startInfoHand(Get1Resource('Node', -2));
		sharedPath := myStart^^.sharedPath;
		for x := 2 to 29 do
			cs[x] := myStart^^.cs[x];
		ReleaseResource(handle(myStart));
		SystemRes := -1;
		GetKeys(KBnunc);
		charnum := 55 div 8;
		bitnum := 7 - (55 mod 8);
		if not (BitTst(@KBNunc, 8 * charnum + bitnum)) then
			SystemRes := OpenRFPerm(concat(sharedPath, 'Shared Files:System Prefs'), 0, fsRdWrPerm);
		if SystemRes = -1 then
		begin
			SysBeep(10);
			abg.h := 50;
			abg.v := 80;
			dere[0] := 'HRMS';
			tyto := '';
			SFPGetFile(abg, tyto, @HFilefilter, -1, dere, @mySFGetHook, repo, 206, nil);
			if repo.good or newBBS then
			begin
				tyto := '';
				if not newBBS then
				begin
					sharedPath := PathNamefromWD(repo.vRefNum);
					i := length(sharedPath);
					j := 0;
					while (i > 0) do
					begin
						i := i - 1;
						if sharedPath[i] = ':' then
						begin
							j := j + 1;
							if j = 1 then
							begin
								Delete(SharedPath, i + 1, length(sharedPath));
								i := 0;
							end;
						end;
					end;
				end;
				myStart := startInfoHand(Get1Resource('Node', -2));
				myStart^^.sharedPath := sharedPath;
				ChangedResource(handle(myStart));
				WriteResource(handle(myStart));
				ReleaseResource(handle(myStart));
				SystemRes := OpenRFPerm(concat(sharedPath, 'Shared Files:System Prefs'), 0, fsRdWrPerm);
			end;
		end;
		sharedFiles := concat(SharedPath, 'Shared Files:');
		if (SystemRes = -1) then
			ExitToShell;
		tempSystHand := systHand(GetResource('Sprf', 0));
		if reserror <> noErr then
			ExitToShell;
		InitSystHand^^ := tempSystHand^^;
		ReleaseResource(handle(tempSystHand));
		CloseResFile(SystemRes);


		StringsRes := OpenRFPerm(concat(SharedFiles, 'Strings'), 0, fsRdWrPerm);
		TextRes := OpenRFPerm(concat(SharedFiles, 'Text'), 0, fsRdWrPerm);

		SetupTheNodes;
		fullnames := nil;
		TabbyQuit := NotTabbyQuit;
		dragFirst := cell($FFFFFFFE);
		myUsers := nil;
		writedirectTolog := false;
		sysopAvailC := false;
		answerCalls := true;
		gSerialBinary := nil;
		theProts := nil;
		if InitSystHand^^.blackonwhite = 1 then
		begin
			defaultstyle.fcol := 7;
			defaultstyle.bcol := 0;
		end
		else
		begin
			defaultstyle.fcol := 0;
			defaultstyle.bcol := 7;
		end;
		defaultstyle.intense := false;
		defaultstyle.underline := false;
		defaultstyle.blinking := false;

		ANSIColors[0].red := $0000;
		ANSIColors[0].green := $0000;							{ Black }
		ANSIColors[0].blue := $0000;

		ANSIColors[1].red := $A0A0;
		ANSIColors[1].green := $0000;					{ Red }
		ANSIColors[1].Blue := $0000;

		ANSIColors[2].red := $0000;
		ANSIColors[2].green := $A0A0;					{ Green }
		ANSIColors[2].blue := $0000;

		ANSIcolors[3].red := $CCCC;
		ANSIcolors[3].green := $CCCC;					{ Yellow }
		ANSIcolors[3].blue := $0000;

		ANSIcolors[4].red := $0000;
		ANSIcolors[4].green := $0000;							{ Blue }
		ANSIcolors[4].blue := $A0A0;

		ANSIColors[5].red := $A0A0;
		ANSIColors[5].green := $0000;					{ Magenta }
		ANSIColors[5].blue := $A0A0;

		ANSIColors[6].red := $0000;
		ANSIColors[6].Green := $A0A0;					{ Cyan }
		ANSIColors[6].blue := $A0A0;

		ANSIcolors[7].red := $C0C0;
		ANSIcolors[7].green := $C0C0;					{ White }
		ANSIcolors[7].blue := $C0C0;

		ANSIColors[8].red := $8080;
		ANSIColors[8].green := $8080;							{ Black }
		ANSIColors[8].blue := $8080;

		ANSIColors[9].red := $FFFF;
		ANSIColors[9].green := $0000;					{ Red }
		ANSIColors[9].Blue := $0000;

		ANSIColors[10].red := $0000;
		ANSIColors[10].green := $EEEE;					{ Green }
		ANSIColors[10].blue := $0000;

		ANSIcolors[11].red := $FFFF;
		ANSIcolors[11].green := $FFFF;					{ Yellow }
		ANSIcolors[11].blue := $0000;

		ANSIcolors[12].red := $0000;
		ANSIcolors[12].green := $0000;							{ Blue }
		ANSIcolors[12].blue := $FFFF;

		ANSIColors[13].red := $FFFF;
		ANSIColors[13].green := $0000;					{ Magenta }
		ANSIColors[13].blue := $FFFF;

		ANSIColors[14].red := $0000;
		ANSIColors[14].Green := $FFFF;					{ Cyan }
		ANSIColors[14].blue := $FFFF;

		ANSIcolors[15].red := $FFFF;
		ANSIcolors[15].green := $FFFF;					{ White }
		ANSIcolors[15].blue := $FFFF;

		OldANSIColors[0] := blackColor;
		OldANSIcolors[1] := redColor;
		OldANSIcolors[2] := greenColor;
		OldANSIcolors[3] := yellowColor;
		OldANSIcolors[4] := blueColor;
		OldANSIcolors[5] := magentacolor;
		OldANSIcolors[6] := cyanColor;
		OldANSIcolors[7] := whiteColor;
		OldANSIColors[8] := blackColor;
		OldANSIcolors[9] := redColor;
		OldANSIcolors[10] := greenColor;
		OldANSIcolors[11] := yellowColor;
		OldANSIcolors[12] := blueColor;
		OldANSIcolors[13] := magentacolor;
		OldANSIcolors[14] := cyanColor;
		OldANSIcolors[15] := whiteColor;

		for i := 1 to MAX_NODES do
			gBBSwindows[i] := nil;

		SetupMenus;
		myExternals := nil;
		nodeDilg := nil;
		SysConfig := nil;
		SystPrefs := nil;
		GetFBSelection := nil;
		MessSetUp := nil;
		getUSelection := nil;
		GetDSelection := nil;
		GetTESelection := nil;
		MailDilg := nil;
		ImportStatusDlg := nil;
		GlobalUSearch := nil;
		SSLockDlg := nil;
		NewDilg := nil;
		AccessDilg := nil;
		GFileSelection := nil;
		GetSelection := nil;
		StringDilg := nil;
		ErrorDlg := nil;
		ChatroomDlg := nil;
		QuoterDlg := nil;
		for i := 1 to MAX_NODES do
			held[i] := false;
		AboutDilg := nil;
		numTextWinds := 0;
		sslow := 0;
		sshigh := 0;
		sysopOpenDir := nil;
		sysopNumFiles := 0;
		theEmail := nil;
		emailDirty := true;
		statWindow := nil;
		DialDialog := nil;
		GetULSelection := nil;
		BroadDilg := nil;
		ChatHand := nil;
		ActionWordHand := nil;
		sysopDirNum := -1;
		nodeView := true;
		textSearch := '';
		setNewNodes := 0;
		screenSaver := false;
		lastSSDraw := 0;
		result := OSErr(initCRM);
		result := OSErr(initCTBUtilities);
		mySaveDisk := SFSaveDisk^ + 1; {so we're sure that they're different}
		randseed := tickCount;					{We'll do this for external programmers sake.}
		isUsingColor := false;
		if gMac.hasColorQD then
		begin
			if TestDeviceAttribute(getMainDevice, gdDevType) then
			begin
				tempGD := GetMaxDevice(screenBits.bounds);
				if tempGD^^.gdPMap^^.pixelSize > 1 then
					isUsingColor := true;
			end;
		end;
		if (gMac.atDrvrVersNum >= 53) then
			adspSupported := true
		else
			adspSupported := false;
		BBSName := InitSystHand^^.bbsName;
		SSCount := 0;
		mppDrvrRefNum := -1;
		if gMac.systemVersion < $0607 then
		begin
			if (gMac.machineType <> 1) and (gMac.machineType <> 2) and (gMac.machineType <> 15) and (gMac.machineType <> 17) then
				hasGPi := true
			else
				hasGPi := false;
		end
		else
		begin
			result := Gestalt(gestaltSerialAttr, tempLong);
			hasGPi := (BAnd(tempLong, bsl(1, gestaltHasGPIaToDCDa)) <> 0);
		end;

	{ Try to open the MacTCP driver.  This is the only way to find out if MacTCP is available. }
		ippDrvrRefNum := -1;
		result := OpenDriver('.IPP', ippDrvrRefNum);
		if result = noErr then
			tcpSupported := true
		else
			tcpSupported := false;
	end;
end.