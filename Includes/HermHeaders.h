/*-------------------------------------------------------------------------------

Hermes BBS interface file - updated for using Hermes II 3.5.2 and Metrowerks.

Originally Converted to C by Steve Ramsey of Lucena Systems.

Changes 07/31/97 - added filler bytes to make records same size for pascal
                       and C versions.  Added those missing records 
                       necessary for test program to compare against pascal 
                       v3.5.  The chatroom callbacks for v3.5 are still 
                       missing.
                       
Warning!  This version of this header file has only been tested with 
          the 68k C++ compiler included with CodeWarrior Pro 1 and the 68k
          C++ compiler included with Symantec Project Manager 8.1.

Hermes is ©1989-1997 by Arachnoware
All rights reserved.

You may use these interfaces only for programs designed
specifically to be used with Hermes BBS.

“Pascal is a dead language.”
			
-------------------------------------------------------------------------------*/


#ifndef __HERMHEADERS_H__
#define __HERMHEADERS_H__

#include <Dialogs.h>
#include <Menus.h>
#include <TextEdit.h>
#include <Lists.h>
#include <Files.h>
#include <AppleTalk.h>
#include <ADSP.h>

/* 	values for message field to user external */

#define EXTERNALS_VERSION	330

#define DOINITIALIZE		1		/* 	values for message field to user external */
#define CREATENODEVARS		2
#define DOMAINTENANCE		3
#define CALLLOGON			4
#define CALLMENU			5
#define IDLE				6
#define GAMEIDLE			7
#define ACTIVEEXT			8
#define CLOSENODE			9
#define CLOSEEXTERNAL		10
#define CONFERENCECHANGE	11 /* message forums/conferences have changed */
#define RAWCHAR				12

/*
	Welp!  These are the procs number, I've made them
	in <gasp> macro's so that you don't have to type
	"HermSetup->procs[vbCr]" all out, you only need to
	write "vbCr"  nifty eh?  yah, I thought so <G>
*/

#define vbCr				0
#define vOutln				1
#define vOutLineC			2
#define vOutLineSysop		3
#define vBufferIt			4
#define vBufferbCr			5
#define vBufClearScreen		6
#define vReleaseBuffer		7
#define vOutChr				8
#define vANSICode			9
#define vDoM				10
#define vClearScreen		11
#define vBackSpace			12
#define vSingleNodeOutput	13
#define vBroadCast			14

#define vLettersPrompt		15
#define vNumbersPrompt		16
#define vYesNoQuestion		17
#define vPromptUser			18
#define vPAUSEPrompt		19
#define vANSIPrompter		20
#define vRePrintPrompt		21

#define vFindUser			22
#define sFindUser			25
#define vWriteUser			23
#define sWriteUser			26
#define vInitUserRec		24
#define vUserAllowed		25
#define vResetUserColors	26
#define vPrintUserStuff		27
#define vyearsOld			28
#define vUserOnSystem		29
#define vWhatNode			30
#define vWhatUser			31
#define vGiveTime			32
#define vTicksLeft			33
#define vTickToTime			34

#define vDoSystRec			35
#define sDoSystRec			14
#define vDoMenuRec			36
#define sDoMenuRec			15
#define vDoTransRec			37
#define sDoTransRec			16
#define vDoForumRec			38
#define sDoForumRec			17
#define vDoGFileRec			39
#define sDoGFileRec			18
#define vDoMailerRec		40
#define sDoMailerRec		19
#define vDoSecRec			41
#define sDoSecRec			20
#define vLoadNewUser		42
#define sLoadNewUser		21
#define vDoFBRec			43
#define sDoFBRec			22
#define vDoMForumRec		44
#define sDoMForumRec		23
#define vDoMConferenceRec	45
#define sDoMConferenceRec	24

#define vPrintConfList		46
#define vprintForumList		47
#define vFindConference		48
#define vFigureDisplayConf	49
#define vOpenMData			50
#define vSaveMessage		51
#define vReadMessage		52
#define vPrintCurMessage	53
#define vRemoveMessage		54
#define vSavePost			55
#define vSaveNetPost		56
#define vAddLine			57
#define vDeletePost			58
#define vtakeMsgTop			59
#define vEnterMessage		60
#define vMForumOp			61
#define vMConferenceOp		62
#define vMForumOk			63
#define vMConferenceOk		64
#define vOpenBase			65
#define vSaveBase			66
#define vCloseBase			67
#define vLoadFileAsMsg		68
#define vReadTextFile		69
#define visPostRatioOK		70
#define vReadAutoMessage	71

#define vOpenEmail			72
#define vCloseEmail			73
#define vFindMyEmail		74
#define vSaveMessAsEmail	75
#define vSaveEmailData		76
#define vHeReadIt			77
#define vDeleteMail			78
#define vDeleteFileAttachment	79

#define vAreaOp				80
#define vDirOp				81
#define vForumOk			82
#define vSubDirOk			83
#define vDownloadOk			84
#define vFindSub			85
#define vFindArea			86
#define vHowManySubs		87
#define vprintDirList		88
#define vprintSubDirList	89
#define vPrintTree			90
#define vPrintExtended		91
#define vReadExtended		92
#define vAddExtended		93
#define vDeleteExtDesc		94
#define vOpenDirectory		95
#define vSaveDirectory		96
#define vCloseDirectory		97
#define vSortDir			98
#define vGetNextFile		99
#define vFileEntry			100
#define vPrintFileInfo		101
#define vFExist				102
#define vListFil			103
#define vFileOKMask			104
#define vDoUpload			105
#define vDoDownload			106
#define vDoRename			107
#define vDLRatioOK			108

#define vOpenComPort		109
#define vCloseComPort		110
#define vGet1ComPort		111
#define vTellModem			112
#define vClearInBuf			113
#define vAppleTalk			114
#define vADSPBytesToRead	115
#define vStartADSPListener	116
#define vOpenADSPListener	117
#define vCloseADSPListener	118

#define vLogError			119
#define vGoHome				120
#define vHangUpAndReset		121
#define vEndUser			122
#define vLogThis			123
#define vgetdate			124
#define vwhattime			125
#define vsecs2Time			126
#define vDoCapsName			127
#define vDoNumber			128
#define vAsyncMWrite		129
#define vmySDGetBuf			130
#define vmySyncRead			131

#define vcopy1File			132
#define scopy1File			27
#define vOpenCapture		133
#define vCloseCapture		134
#define vInTrash			135
#define vSaveText			136
#define sSaveText			29
#define vAgeOk				137
#define vRetInStr			138
#define vMakeADir			139
#define vStartMySound		140
#define sStartMySound		28
#define vOutANSItest		141
#define vSysopAvailable		142
#define vFreeK				143
#define vprintSysopStats	144
#define vdoMailerImport		145
#define vdoDetermineZMH		146
#define vLaunchMailer		147
#define vDecodeM			148
#define vMakeColorSequence	149
#define vGetCharPrompt		175

#define sSetGeneva			0
#define sSetTextBox			1
#define sGetTextBox			2
#define sSetCheckBox		3
#define sGetCheckBox		4
#define sSetControlBox		5
#define sUpDown				6
#define sUpDownReal			7
#define sOptionDown			8
#define sCmdDown			9
#define sAddListString		10
#define sModalQuestion		11
#define sframeit			12
#define sProblemRep			13

/*
	The following symbolic constants are defined to give easy access
	to the Hermes access letters (restrictions). The access letters
	data structure is defined in the Pascal headers as a packed array
	of Booleans. In the C headers, it is an unsigned long. Bitwise
	operators may be used to extract specific values. This method was
	chosen over bit fields for compatibility among C compilers.
*/

#define alA		0x01000000UL
#define alB		0x02000000UL
#define alC		0x04000000UL
#define alD		0x08000000UL
#define alE		0x10000000UL
#define alF		0x20000000UL
#define alG		0x40000000UL
#define alH		0x80000000UL
#define alI		0x00010000UL
#define alJ		0x00020000UL
#define alK		0x00040000UL
#define alL		0x00080000UL
#define alM		0x00100000UL
#define alN		0x00200000UL
#define alO		0x00400000UL
#define alP		0x00800000UL
#define alQ		0x00000100UL
#define alR		0x00000200UL
#define alS		0x00000400UL
#define alT		0x00000800UL
#define alU		0x00001000UL
#define alV		0x00002000UL
#define alW		0x00004000UL
#define alX		0x00008000UL
#define alY		0x00000001UL
#define alZ		0x00000002UL


#pragma options align=mac68k

typedef struct {
	Boolean handle;
	Boolean gender;
	Boolean realName;
	Boolean birthDay;
	Boolean city;
	Boolean country;
	Boolean dataPN;
	Boolean company;
	Boolean street;
	Boolean computer;
	Boolean sysOp [4];					/* 	Boolean [3] - 4th Boolean forces alignment */
	unsigned char sysopText [3] [62];
	Boolean noVFeedback;
	short qScanBack;
	Boolean noAutoCapital;
	short reserved [997];
}	NewUserRec, *NewUserPtr, **NewUserHand;


typedef struct {
	unsigned char name [50] [42];
	Boolean onOff [50];
	short secLevel [50];
	short secLevel2 [50];
	short secLevel3 [50];
	Boolean options [50] [10];
	short reserved [100];
}	NodeMenuRec, *NodeMenuPtr, **NodeMenuHand;


typedef struct {
	unsigned char name [50] [42];
	Boolean onOff [50];
	short secLevel [50];
	short secLevel2 [50];
	short secLevel3 [50];
	Boolean options [50] [10];
	short reserved [100];
}	TransMenuRec, *TransMenuPtr, **TransMenuHand;


typedef struct {
	unsigned char class_name [32];	/* 	What is this security level called? */
	Boolean useDayorCall;			/* 	minutes per day is true, min/call is false */
	Boolean readAnon;				/* 	read Anonymous */
	short timeAllowed;				/* 	minutes allowed on per day/call */
	short mesgDay;					/* 	maximum messages per day */
	short dlRatioOneTo;				/* 	download ratio 1 to ? */
	short postRatioOneTo;			/* 	post call ratio 1 to ? */
	short callsPrDay;				/* 	calls per day */
	short lnsMessage;				/* 	maximum lines per message */
	Boolean postMessage;			/* 	post message yes/no */
	Boolean bbsList;				/* 	add to BBS list yes/no */
	Boolean uploader;				/* 	see uploader on files yes/no */
	Boolean udRatio;				/* 	enforce upload/download ratio yes/no */
	Boolean chat;					/* 	allow user to page the sysOp yes/no */
	Boolean email;					/* 	allow user to send email yes/no */
	Boolean listUser;				/* 	allow user to list other users yes/no */
	Boolean autoMsg;				/* 	allow user to change auto message yes/no */
	Boolean anonMsg;				/* 	allow user to post anonymous messages yes/no */
	Boolean pcRatio;				/* 	enforce post call ratio yes/no */
	short transLevel;				/* 	transfer level */
	unsigned long restrics;			/* 	these may be accessed using the earlier */
									/* 		defined symbolic constants */
	unsigned short notUsed;			/* 	was whichForums */
	unsigned short nodes;			/* 	which nodes; packed array of Booleans with padding */
	Boolean active;					/* 	Is this level active? */
	float xferComp;					/* 	multiplier; compensates for uploading time */
	float messComp;					/* 	multiplier; compensates for posting time */
	Boolean mustRead;				/* 	force user to read posts to get to transfers */
	Boolean ppFile;					/* 	person-to-person file transfer */
	Boolean enableHours;			/* 	restrict hours */
	Boolean alternateText;			/* 	Does this user see the alternate text? */
	Boolean cantNetMail;			/* 	Is this user allowed to net mail? */
	short extra [23];
}	NewSecLevRec;

typedef NewSecLevRec NewSecurity [255];
typedef	NewSecurity *SecLevPtr, **SecLevHand;
	

/* 	The following structure is found in the 'Sprf' resource in the System Prefs file. */

typedef enum {UseNormal, UseAnonAndNormal, NoHeaderInAnon} QuoteHeaderOptionsType;

typedef struct {
	unsigned char bbsName [42];					/* 	BBS name */
	unsigned char overridePass [10];			/* 	sysop override password */
	unsigned char newUserPass [10];				/* 	new user password */
	long numCalls;								/* 	number of total calls to system */
	short numUsers;								/* 	number of users on system (not including deleted) */
	long opStartHour;							/* 	sysop’s starting hour */
	long opEndHour;								/* 	sysop’s ending hour */
	Boolean closed;								/* 	Is the board closed? */
	short numNodes;								/* 	number of nodes board has */
	short mouseDelay;							/* 	keeps track of mouse ticks */
	DateTimeRec lastMaint;						/* 	date of last maintenance */
	long lastUL;								/* 	date of last upload */
	long lastDL;								/* 	date of last download */
	long lastPost;								/* 	date of last post */
	long lastEmail;								/* 	date of last email */
	short anonyUser;							/* 	auto message user number */
	Boolean anonyAuto;							/* 	Is the auto message anonymous? */
	unsigned char PAD_BYTE;
	unsigned char serialNumber [42];			/* 	•	apparently unused */
	Str255 gfilePath;							/* 	path to g-files data */
	Str255 msgsPath;							/* 	path to message data */
	Str255 dataPath;							/* 	path to all data */
	Boolean mailAttachments;					/* 	allow mail attachments */
	float mailDLCost;
	Boolean freeMailDL;							/* 	Do attachment DLs affect ratios? */
	short numMForums;							/* 	number of message forums */
	short numNNodes;
	unsigned char bbsNames [10][42];			/* 	names in BBS list */
	unsigned char bbsNumbers [10][42];			/* 	numbers in BBS list */
	unsigned short bbsDialIt;					/* 	packed array of Booleans plus padding */
	unsigned short bbsDialed;					/* 	packed array of Booleans plus padding */
	Rect wNodesStd [10];
	Rect wNodesUser [10];
	unsigned char wIsOpen [2];
	Rect wStatus;
	Rect wUsers;
	Boolean wUserOpen;
	Byte filler;                                /*   padding byte for compatibility */
	unsigned char restrictions [26] [22];		/* 	names given to access letters */
	short callsToday [10];						/* 	calls posted today, by node */
	short mPostedToday [10];					/* 	messages posted today, by node */
	short emailToday [10];						/* 	email sent today, by node */
	short uploadsToday [10];					/* 	uploads today, by node */
	long kUploaded [10];						/* 	kbytes uploaded today, by node */
	short minsToday [10];						/* 	minutes on today, by node */
	short dlsToday [10];						/* 	downloads today, by node */
	long kDownloaded [10];						/* 	kbytes downloaded today, by node */
	short failedULs [10];						/* 	failed UL’s today, by node */
	short failedDLs [10];						/* 	failed DL’s today, by node */
	unsigned char lastUser [32];				/* 	name of last user to log on */
	long unused1;
	Boolean twoWayChat;							/* 	two-way chat */
	Boolean useXWind;							/* 	use transfer window */
	Boolean ninePoint;							/* 	nine or twelve point */
	Boolean freePhone;							/* 	phone format; if true, then ###-###-#### */
	Boolean closedTransfers;					/* 	Is the transfer section closed? */
	short protocolTime;							/* 	protocol time slice */
	short blackOnWhite;							/* 	mapped to old-style quickdraw 8-colors */
	short mailDeleteDays;						/* 	number of days auto deletion is set to */
	Boolean twoColorChat;						/* 	two-color chat (if ANSI) */
	Boolean usePauses;							/* 	check for sysop-defined pauses */
	long dlCredits;								/* 	DL credits given to new users */
	short logDays;								/* 	how many days to save logs */
	short logDetail;							/* 	degree of log detail (by node, by BBS) */
	unsigned char realSerial [82];				/* 	full Hermes serial number */
	long startDate;								/* 	date BBS first went up */
	Byte screenSaver [2];
	Boolean totals;								/* 	log by totals or by node */
	Byte filler2;                               /*   padding byte for compatibility */
	unsigned char endString [82];
	Boolean useBold;							/* 	bold or intense in local views? */
	short version;								/* 	Hermes version number */
	Boolean quoter;								/* 	Is quoter active? */
	Boolean ssLock;
	Boolean noANSIDetect;
	Boolean noXFerPathChecking;
	Str255 quoteHeader;
	Str255 quoteHeaderAnon;
	Boolean useQuoteHeader;
	QuoteHeaderOptionsType quoteHeaderOptions;
/* Added in 3.5.9b1; reserved was 508 */
	unsigned char foregrounds[7];
		unsigned char _pad1;
	unsigned char backgrounds[7];
		unsigned char _pad2;
	unsigned char intense[7];
		unsigned char _pad3;
	unsigned char underlines[7];
		unsigned char _pad4;
	unsigned char blinking[7];
		unsigned char _pad5;
	Boolean debugTelnet, debugTelnetToFile;
	unsigned char reserved[464];
}	SystRec, *SystPtr, **SystHand;


typedef struct {
	unsigned char dirName [42];
	Str255 path;
	short minDSL;
	short dslToUL;
	short dslToDL;
	short maxFiles;
	char restriction;
	short nonMacFiles;				/* 	0 = allow MacBinary; 1 = never MacBinary */
	short mode;						/* 	-1 = never new; 0 = normal; 1 = always new */
	short minAge;
	short fileNameLength;
	Boolean freeDir;
	Boolean allowUploads;
	Boolean handles;
	Boolean showUploader;
	short color;
	Boolean tapeVolume;
	Boolean slowVolume;
	short operators [3];
	float dlCost;
	float ulCost;
	float dlCreditor;
	short howLong;
	Boolean uploadOnly;
	Byte filler;
	char reserved [46];
}	DirInfoRec;


typedef struct {
	DirInfoRec dr [64];
}	DirDataFile, *ReadDirPtr, **ReadDirHandle;

typedef DirDataFile  DirList [65];
typedef DirList *DirListPtr, **DirListHand;


typedef struct {
	short numForums;
	unsigned char name [65] [32];
	short minDsl [65];
	short restriction [65];
	short numDirs [65];
	short age [65];
	short ops [65] [3];
	long lastUpload [65] [64];
	short reserved [1000];
}	ForumIdxRec, *ForumIdxPtr, **ForumIdxHand;


/* 	In the Pascal headers, the following struct is a packed record. */

typedef struct {
	unsigned char fcol : 4;
	unsigned char bcol : 4;
	Boolean intense    : 1;
	Boolean underLine  : 1;
	Boolean blinking   : 1;
	unsigned char      : 5;		/* 	padding bits */
}	CharStyle, *CharStylePtr;


typedef enum {NoMail, FidoGated, Direct} InternetMailType;


typedef struct {
		char _pad1[512];
	Boolean mailerAware;
		char _pad2[290];
	Boolean useRealNames;
		char _pad3[259];
/* Added in 3.5.9b2; reserved was 736. */
	short version;
	short mailerProcessingNode;
		short _pad4;
	long zone, net, node, point;
	Str31 domain;
	Str255 originLine;
	char reserved [426];
}	MailerRec, *MailerPtr, **MailerHand;


typedef struct {
	unsigned char name [42];	/* 	name of message conference */
	short slToRead;				/* 	minimum SL to read messages */
	short slToPost;				/* 	minimum SL to post messages */
	short maxMessages;			/* 	maximum messages allowed in this sub */
	short anonID;				/* 	status of anonymous posting in this conference: */
								/* 		0 = never; 1 = force; -1 = allow */
	short minAge;				/* 	minimum age to access sub */
	short accessLetter;			/* 	required access letter to see the conference */
	Boolean threading;			/* 	Is threading allowed in this conference? */
	char confType;				/* 	conference type: 0 = local; 1 = Fido; 2 = UseNet */
	Boolean realNames;
	Boolean showCity;			/* 	show city (also state if using real names) */
	Boolean fileAttachments;
	float dlCost;
	Str255 echoName;
	short moderators [3];
	Boolean newUserRead;
	Byte filler;
	short nextForum, nextConference;
	char reserved[21];
} 	ConferenceRec;


typedef struct {
	unsigned char name [42];
	short numConferences;
	short minSL;
	short minAge;
	short accessLetter;			/* 	required access letter to see the forum */
	short moderators [3];		/* 	user numbers of forum moderators */
	char reserved [26];
}	ForumRec;

typedef ForumRec MForumArray [20];
typedef MForumArray *MForumPtr, **MForumHand;

typedef ConferenceRec FiftyConferences [50];
typedef FiftyConferences *FiftyConferencesPtr, **FiftyConferencesHand;
typedef FiftyConferencesHand MConferencesArray [20];


/* 	The following struct is stored as 'Gfil' ID 2 in the Gfiles file. */

typedef struct {
	unsigned char secName [52];
	short minSL;
	short minAge;
	char restrict;
	Byte filler;
	char reserved [13];
}	GFileSec;


typedef struct {
	short numSecs;
	GFileSec sections [99];
}	GFileSecRec, *GFileSecPtr, **GFileSecHand;


/*	The following struct represents the user records
	stored in the data fork of the Users file.	*/

typedef enum {MessOn, MessOff, MessOnNoNew} MessHeaderType;
typedef enum {TransOn, TransOff, TransOnNoNew} TransHeaderType;

typedef struct {
	short userNum;
	short SL;
	short DSL;
	unsigned char userName [32];
	unsigned char realName [22];
	unsigned char alias [32];
	unsigned char phone [14];
	unsigned char password [10];
	unsigned char dataPhone [14];
	unsigned char company [32];
	unsigned char street [32];
	unsigned char city [32];
	unsigned char state [8];
	unsigned char zip [12];
	unsigned char country [12];
	unsigned char computerType [24];
	unsigned char sysopNote [42];
	unsigned char miscField1 [62];
	unsigned char miscField2 [62];
	unsigned char miscField3 [62];
	unsigned char lastBaud [20];
	unsigned long accessLetter;						/* 	these may be accessed using the earlier */
													/* 		defined symbolic constants */
	Boolean cantPost;								/* 	Restriction #1 */
	Boolean cantChat;								/* 	Restriction #2 */
	Boolean udRatioOn;								/* 	Restriction #3 */
	Boolean pcRatioOn;								/* 	Restriction #4 */
	Boolean cantPostAnon;							/* 	Restriction #5 */
	Boolean cantSendEmail;							/* 	Restriction #6 */
	Boolean cantChangeAutoMsg;						/* 	Restriction #7 */
	Boolean cantListUser;							/* 	Restriction #8 */
	Boolean cantAddToBBSList;						/* 	Restriction #9 */
	Boolean cantSeeULInfo;							/* 	Restriction #10 */
	Boolean cantReadAnon;							/* 	Restriction #11 */
	Boolean restrictHours;							/* 	Restriction #12 */
	Boolean cantSendPPFile;							/* 	Restriction #13 */
	Boolean cantNetMail;							/* 	Restriction #14 */
	Boolean readBeforeDL;							/* 	Restriction #15 */
	Byte filler;
	Boolean reservedForRestricts [4];				/* 	Reserved space for 4 more Restricts */
	Boolean deletedUser;							/* 	True = User Deleted */
	long lastOn;
	long firstOn;
	Boolean sex;									/* 	0 = female; 1 = male */
	short birthDay;
	short birthMonth;
	short birthYear;
	short age;
	short onToday;
	short totalLogons;
	short minutesOnToday;
	long totalTimeOn;
	short illegalLogons;
	short messagesPosted;
	short mPostedToday;
	short emailSent;
	short emSentToday;
	short numUploaded;
	short numULToday;
	short numDownloaded;
	short numDLToday;
	long uploadedK;
	long kbULToday;
	long downloadedK;
	long kbDLToday;
	short scrnWdth;
	short scrnHght;
	short terminalType;
	Boolean colorTerminal;
	Boolean useDayOrCall;
	short timeAllowed;
	short callsPrDay;
	short mesgDay;
	short lnsMessage;
	short dlRatioOneTo;
	short postRatioOneTo;
	long dlCredits;
	Boolean coSysop;
	Boolean alertOn;
	long lastPWChange;
	unsigned char donation [22];
	unsigned char lastDonation [22];
	unsigned char expirationDate [22];
	Boolean alternateText;
	long startHour;
	long endHour;
	unsigned char foregrounds [18];
	unsigned char backgrounds [18];
	unsigned long intense;						/* 	packed array of Booleans plus padding */
	unsigned long underlines;					/* 	packed array of Booleans plus padding */
	unsigned long blinking;						/* 	packed array of Booleans plus padding */
	unsigned char whatTNScan [8];
	unsigned char whatNScan [20] [8];
	long lastMsgs [20] [50];
	long lastFileScan;
	Boolean pauseScreen;
	short defaultProtocol;
	Boolean mailbox;
	Byte filler2;
	unsigned char forwardedTo [46];
	Boolean expert;
	Boolean nTransAfterMess;
	short extendedLines;
	Boolean extDesc;
	Boolean screenClears;
	Boolean notifyLogon;
	Boolean scanAtLogon;
	Boolean allowInterruptions;
	long dlsByOther;
	unsigned char signature [82];
	Boolean columns;
	float messComp;
	float xferComp;
	long bonusTime;
	Boolean autoSense;
	Boolean chatANSI;
	MessHeaderType messHeader;
	TransHeaderType transHeader;
	unsigned char reserved [50];
}	UserRec, *UserPtr, **UserHand;

typedef unsigned char AddressBook [18] [46];
typedef AddressBook *AddressBookPtr, **AddressBookHand;


typedef enum {ListText, Prompt, None, Chat, Writing, Repeating} BDact;

typedef char aLine [80];

typedef struct {
	unsigned char name [82];
	unsigned char atNode [16];
}	FidoAddress;


typedef unsigned char *HermesMesg [300];
typedef HermesMesg *MessgPtr, **MessgHand;

typedef aLine *ScrnKeys;
typedef ScrnKeys *ScrnKeysPtr, **ScrnKeysHnd;

typedef long *PtrToLong;
typedef short *PtrToWord;

typedef short *MessIndexArray;
typedef MessIndexArray *MessIndexPtr, **MessIndexHand;


typedef struct {
	unsigned char title [82];			/* 	message title */
	short fromUserNum;					/* 	from user number */
	unsigned char fromUserName [42];	/* 	from user name */
	short toUserNum;					/* 	to user number */
	unsigned char toUserName [42];		/* 	to user name */
	Boolean anonyFrom; 					/* 	0 = not anonymous; 1 = anonymous */
	Boolean anonyTo;					/* 	Was the message responding to anonymous? */
	Boolean deletable;					/* 	Is the message deletable? */
	long dateWritten;
	long dateEntered;
	long storedAs;
	Boolean fileAttached;
	Byte filler;
	unsigned char fileName [32];		/* 	name of attached file */
	Boolean isMacFile;					/* 	send with or without MacBinary header */
	Boolean hasRead;
	unsigned char reserved [22];
}	MesgRec;

typedef MesgRec *SubDyPtr, **SubDyHand;


typedef struct {
	short numfeedbacks;					/* 	number of users available for feedback */
	short usernum [20];					/* 	user numbers of feedback users */
	unsigned char speciality [20] [42];	/* 	areas of expertise */
}	FeedbackRec, *FeedbackPtr, **FeedbackHand;


typedef struct {
	unsigned char fileName [32];		/* 	file name used in listings */
	Str255 realFName;					/* 	explicit file path */
	unsigned char flDesc [80];			/* 	file description */
	long whenUL;						/* 	exact time uploaded in seconds */
										/* 		from Jan 1, 1904 (Mac standard) */
	short uploaderNum;					/* 	user number of uploader */
	short numDLoads;					/* 	how many times this file has been DL’d */
	long byteLen;						/* 	length of file in bytes */
	Boolean hasExtended;				/* 	Is there an extended description? */
	short fileStat;
	long lastDL;						/* 	time and date of last DL in seconds */
										/* 		from Jan 1, 1904 (Mac standard) */
	unsigned char version [12];
	unsigned char fileType [6];
	unsigned char fileCreator [6];
	long fileNumber;
	unsigned char reserved [52];
}	FilEntryRec;

typedef FilEntryRec *aDirFile;
typedef aDirFile *aDirPtr, **aDirHand;


typedef struct {
	unsigned char title [42];		/* 	title of email */
	short fromUser;					/* 	from user number */
	short toUser;					/* 	to user number */
	Boolean anonyFrom;				/* 	true if from anonymous */
	Boolean anonyTo;				/* 	true if responding to anonymous */
	long dateSent;					/* 	date sent in seconds from  */
									/* 		Jan 1, 1904 (Mac standard) */
	long storedAs;
	short mType;					/* 	0 = message read; 1 = message unread */
	Boolean multiMail;				/* 	true if it is /E */
	Boolean fileAttached;			/* 	Is there a file attached? */
	unsigned char fileName [32];	/* 	name of attached file */
	Boolean hasRead;				/* 	• Has the message been read? */
	Boolean isAMacFile;				/* 	Is the attached file a Mac file? */
	char reserved [16];
}	EmailRec;

typedef EmailRec *EMDynamicRec;
typedef EMDynamicRec *MesgPtr, **MesgHand;


typedef struct {
	StringHandle fName;
	StringHandle mbName;
	short myvRef;
	long myDirID;
	long myFileID;
}	PathsFilesRec;


/* 	In the Pascal headers, the following struct is a packed record. */

typedef struct {
	short modemInput;				/* 	ADSP driver ref */
	short modemOutput;				/* 	CCB ref */
	short procID;
	Handle protocolData;
	StringHandle errorReason;
	short timeOut;
	short fileCount;
	short filesDone;
	long curBytesDone;
	long curBytesTotal;
	long curStartTime;
	unsigned short flags;			/* 	packed array of Booleans plus padding */
	PathsFilesRec fPaths [1];
}	XFERStuff, *XFERStufPtr, **XFERStuffHand;


typedef struct {
	short procID;
	short itemID;
	short hMenuID;
	short hItemID;
	StringHandle subName;
	short pFlags;
	short funcMask;
	long refCon;
}	ProcList;


typedef struct {
	short mode;
	MenuHandle pMenu;
	ProcPtr Updater;
	short transIndex;
	short transMessage;
	long transRefCon;
	XFERStuffHand Proto;
	short pCount;
	short firstID;
	short foldID;
	short autoCount;
	Handle autoComs;
	ProcList theProcList [6];
}	ProcMenu, *ProcMenuPtr, **ProcMenuHandle;


typedef struct {
	FilEntryRec theFile;
	short fromDir;			/* 	transfer directory for file */
}	BatFileRec;


typedef struct {
	short numFiles;			/* 	max batch is 50 arbitrarily  */
	Boolean sendingBatch;	/* 	true if this is a batch DL */
	long batchTime;			/* 	used internally, approximation of transfer */
							/* 		time in seconds */
	long batchKBytes;		/* 	used internally */
	BatFileRec filesGoing [50];
}	FLSRec, *FLSPtr, **FLSHand;


typedef char *HermesTextRec;
typedef HermesTextRec *HermesTextPtr, **HermesTextHand;


typedef struct {
	unsigned char resultCode [16];
	short portRateID;
	unsigned char connectType [34];
}	ConOne;

typedef ConOne *ConRec;
typedef ConRec *ConPtr, **ConHand;


typedef struct {
	Boolean active;
	Boolean sending;
	long starttime;
}	InternalTransfer;


/*	The following record is used as a quick look up table, and serves as a faster,
	smaller alternative to keeping the entire user list in memory. */

typedef struct {
	unsigned char uName [32];
	Boolean dlTD;
	char PAD_BYTE;
	long last;
	long first;
	short SL;
	short DSL;
	unsigned char real [22];
	unsigned long accessLetter;		/* 	these may be accessed using the earlier */
									/* 		defined symbolic constants */
	short age;
	unsigned char city [32];
	unsigned char state [4];
}	ULR;

typedef ULR UListRec;
typedef UListRec *UListPtr, **UListHand;


typedef enum {CTS5, DCDchip, DCDdriver} CarDetType;


typedef struct {
	unsigned char promptLine [82];		/* 	prompt text */
	unsigned char allowedChars [102]; 	/* 	Which characters may be entered? */
										/* 		Set to "\p" to accept everything. */
	short replaceChar;					/* 	replacement character for password entry */
										/* 		Set to "\p" for none. */
	Boolean capitalize;					/* 	Force capitalization? */
	Boolean enforceNumeric; 			/* 	Allow numeric entries? */
										/* 		Overrides allowedChars. */
	Boolean autoAccept;					/* 	Should a correct input character be */
										/* 		automatically accepted? */
	Boolean wrapAround;					/* 	Should input wrap at the end of the line? */
										/* 		Excess characters will be stored in */
										/* 		the “excess” variable in the */
										/* 		HermUserGlobs for this node. */
	Boolean wrapsonCR;					/* 	Is the carriage return a valid input */
										/* 		or does it terminate entry? */
	short breakChar;					/* 	alternate entry termination character */
	short hermesColor;					/* 	number of Hermes ANSI color for */
										/* 		displaying the prompt line */
	short inputColor;					/* 	number of Hermes ANSI color for */
										/* 		displaying user input */
	long numericLow;					/* 	lowest acceptable numeric input */
	long numericHigh;					/* 	highest acceptable numeric input */
	short maxChars;						/* 	max length of input string */
	Boolean ansiAllowed; 				/* 	Is the Ctrl-P color escape sequence allowed? */
	Byte filler;
	unsigned char keyString1 [12];		/* 	String to be automatically output when the */
										/* 		first charcter has been entered. */
	unsigned char keyString2 [12];
	unsigned char keyString3 [12];
}	HermesPrompt;


typedef struct {
	unsigned char name [42];
	Boolean sysopExternal;
	Boolean userExternal;
	Handle iconHandle;
	Boolean allTheTime;
	Boolean gameIdle;
	Boolean checkLogon;
	Boolean checkMenu;
	unsigned char menuCommand [18];
	short minSLforMenu;
	short accessLetter;					/* 	required access letter to see the external */
	long privatesNum;
	Handle codeHandle;
	short uResoFile;
	short reserved [15];
}	HermesExDef;

typedef HermesExDef ExternalList [20];
typedef ExternalList *ExternListPtr, **ExternListHand;


typedef struct {
	Boolean allTime;					/* 	call the external during idle loops */
	Boolean gameIdle;					/* 	call the external during game idle loops */
	Boolean checkLogon;					/* 	call the external at logon */
	Boolean checkMenu;					/* 	drop into the external at a proper menu command */
	unsigned char menuCommand [18];		/* 	‘//xxx’ menu command for this external */
	short minSLforMenu;					/* 	minimum SL to see the external in menus */
	short accessLetter;					/* 	required access letter to see the external */
	short compiledForVers;				/* 	latest version of Hermes tested */
	short minVersReq;					/* 	earliest version of Hermes that works */
	short reserved [15];
}	eInfoRec, *eInfoPtr, **eInfoHand;


typedef short intListArr [1];
typedef intListArr *intListPtr, **intListHand;


typedef struct {
	char buf [710];
}	MyQuoteRec;


typedef struct {
	long quoteMark;
	long quoteEnd;
	MessgHand quotingText;
	unsigned char initials[6];           /*   includes extra padding byte */
	Str255 header;
	Boolean gaveHeader;
} QuoteRec;


typedef struct {
	unsigned char actionWord[16];        /*   includes extra padding byte */
	Str255 targetUser;
	Str255 otherUser;
	Str255 initiating;
	Str255 unspecified;
} ActionWordRec;


typedef struct {
	unsigned char actionWord[15];
	long offset;
} ActionWordListRec;


typedef struct {
	Boolean active;
	Byte filler;
	unsigned char channelName[41];
	short numInChannel;
} ChannelRec;


typedef struct {
	short numActionWords;
	short numChannels;
	ChannelRec channels[1];
} ChatRec, *ChatPtr, **ChatHandle;


typedef unsigned char BufferStr135[136];
typedef BufferStr135 BufferArray[180];
typedef BufferArray *BufferPtr, **BufferHand;


typedef struct {
	short whoRequested;
	unsigned char reason[81];
	HermesPrompt savedPrompt;
	Str255 savedCurPrompt;
	short savedSection;
	BDact savedAction;
} PrivateDataRec;


typedef enum {ANSIChat, TextChat} ChatModeType;
typedef enum {NoWhere, InChatroom, SomeWhere, AlreadyIn} WhereFromType;
typedef unsigned char TheMessageStr80[82];
typedef enum {Chatting, SendingMessage, ActionWord} StatusType;

typedef struct {
	ChatModeType chatMode;
	short toNode;
	short privateRequest;
	PrivateDataRec privateData;
	WhereFromType whereFrom;
	Byte filler;
	TheMessageStr80 theMessage[3];
	StatusType status;
	short channelNumber;
	Point inputPos;
	short outputPos;
	short blockWho;
	short bufferSize;
	BufferHand buffer;
	Boolean scrolling;
	short scrollPosition;
	Boolean lastScrollBack;
} UserChatRec;


typedef struct {
	Boolean searchTo;
	Boolean searchFrom;
	Boolean searchSubject;
	Boolean searchText;
	Boolean searchAll;
	Byte filler;
	Boolean searchForums[22];             /*   includes extra padding byte */
	unsigned char keyWord[42];            /*   includes extra padding byte */
	Boolean matchedMessage;
	long matchedDate;
	short numFound;
	short messageArray[1];
} MessageSearchRec, *MessageSearchPtr, **MessageSearchHand;


typedef enum {Waiting, Terminal, User, Answering, Failed} BoardModetype;
typedef enum {Logon, NewUser, MainMenu, TransferMenu, MessageMenu, ChatStage,
		Defaults, Email, GFiles, Utilities, EXTERNAL, rmv, MoveFiles, killMail,
		Batch, MultiChat, tranDef, MultiMail, Noder, messUp, renFiles, readAll,
		RmvFiles, UEdit, USList, BBSlist, chUser, limdate, Quote, Download, Sort,
		Upload, OffStage, ListFiles, post, QScan, ReadMail, Amsg, Ext, ScanNew,
		ListMail, ListDirs, CatchUp, AskQuestions, AttachFile, DetachFile,
		SysopComm, FindDesc, SlowDevice} BoardSectiontype;
typedef enum {AutoOne, AutoTwo, AutoThree, AutoFour, AutoFive, AutoSix, AutoSeven} AutoDotype;
typedef enum {ReadOne, ReadTwo, ReadThree, ReadFour, ReadFive, ReadSix, ReadSeven,
		ReadEight, JumpForum, ReadNine, ReadTen, ReadEleven, ReadTwelve, Read13,
		Read14, Read15, Read16} ReadDotype;
typedef enum {WhichUser, EmailCheck, EmailOne, EmailTwo, EmailThree, EmailFour,
		EmailFive, EmailSix, EmailSeven, EmailEight, EmailNine, EMailTen} EmailDotype;
typedef enum {MultiOne, MultiTwo, MultiThree, MultiFour} MultiDotype;
typedef enum {Mult1, Mult2} MultiChatDotype;
typedef enum {BatOne, BatTwo, BatThree, BatFour, BatFive, BatSix, BatSeven, BatEight} BatDotype;
typedef enum {KillOne, KillTwo, KillThree, KillFour, KillFive} KillDotype;
typedef enum {TrOne, TrTwo, TrThree, TrFour} TransDotype;
typedef enum {SlowOne, SlowTwo, SlowThree, SlowFour, SlowFive, SlowSix, SlowSeven} SlowDotype;
typedef enum {Bone, BTwo, BThree, BFour, BFive, bSix, bSeven} bbsLdotype;
typedef enum {MessUpOne, MessUpTwo, MessUpThree} upMesstype;
typedef enum {AllOne, AllOneA, AllTwo, AllThree} AllDotype;
typedef enum {G1, G2, G3, G4, G5, G6} GFileDotype;
typedef enum {ex1, ex2, ex3, EX4} ExtenDotype;
typedef enum {DownOne, Down2, DownTwo, DownThree, DownRequest, DownFour,
		DownFive, DownSix, DownSeven} DownDotype;
typedef enum {RenOne, RenTwo, RenThree, RenFour, RenFive, RenSix, RenRob,
		RenSeven, RenEight} RenDotype;
typedef enum {SortOne, SortTwo, SortThree} SortDotype;
typedef enum {RFOne, RFTwo, RFThree, RFFour, RFFive, RFSix, RFSeven, RFEight} RFDotype;
typedef enum {ChatOne, ChatTwo, ChatThree} ChatDotype;
typedef enum {NodeOne, NodeTwo, NodeThree, NodeFour, NodeFive, NodeSix, NodeSeven} NodeDotype;
typedef enum {PostOne, PostTwo, PostThree, PostFour, PostFive} PostDotype;
typedef enum {UpOne, UpTwo, UpRob, UpThree, UpFour, UpFive, UpSix, UpSeven,
		UpEight} UploadDotype;
typedef enum {ListOne, ListTwo, ListThree, ListFour, ListFive, ListSix,
		ListSeven} ListDotype;
typedef enum {Qone, QTwo, QThree, QFour, QFive, QSix, QMove, QMove2} QDotype;
typedef enum {EnterUE, UOne, UTwo, UThree, UFour, UFive, USix, USeven, UEight, UNine,
		UTen, UEleven, UTwelve, U13, U14, U15, U16, U17, U18, U19, U20, U21, U22,
		U23, U24, U25, U26, U27, U28, U29, U30} UEdotype;
typedef enum {RmvOne, RmvTwo} rmvDotype;
typedef enum {DefaultOne, DefaultTwo, DefaultThree, DefaultFour, DefaultFive, DefaultSix,
		DefaultSeven, DefaultEight, DefaultNine, DefaultTen, DefaultEleven, DefaultTwelve,
		DefaultThrt, def14, def15, def16, def17, def18, D18, D19, D20, D21, D22, D24, D23,
		D25, D26, D27, D28, D29, D30, D31, D32, D33, D34, D35} DefaultDotype;
typedef enum {MenuText, MainPrompt, TextForce} MainStagetype;
typedef enum {NUP, CheckNUP, GetAlias, CheckAlias, GetReal, CheckReal, GetVoice,
		CheckVoice, GetData, CheckData, GetGender, CheckGender, GetCompany,
		CheckCompany, GetStreet, CheckStreet, GetCity, CheckCity, GetState,
		CheckState, GetZip, CheckZip, GetCountry, CheckCountry, GetMF1, CheckMF1,
		GetMF2, CheckMF2, GetMF3, CheckMF3, GetBirthdate, CheckBirthDate,
		GetComputer, CheckComputer, GetWidth, CheckWidth, GetHght, CheckHght,
		GetAnsi, CheckAnsi, CheckAnsiColor, GetClearing, CheckClearing, GetPause,
		CheckPause, GetColumns, CheckColumns, ShowEntries, CheckEntries, CheckPass,
		EnterPass, ShowInfo, NewTrans, NewTwoTrans, Q53, Q54, Q55, Q56, Q57,
		Q58, Q59, Q60} Quiztype;
typedef enum {Welcome, Name, CheckName, Password, Phone, SysPass, ChkSysPass,
		CheckStuff, Hello, CheckInfo, Stats, StatAuto, Transition, Trans1,
		DoExternalStage, Trans2, Trans3, Trans4} LogonStagetype;
typedef enum {KeepNew, SureQuest, OffText, Hanger} OffDotype;
typedef enum {Attach0, Attach1, Attach2, Attach3, Attach4, Attach5, Attach6,
		Attach7, Attach8, Attach9, Attach10, Attach11} AttachDotype;
typedef enum {Detach1, Detach2, Detach3, Detach4, Detach5} DetachDotype;
typedef enum {FDesc1, FDesc2, FDesc3, FDesc4, FDesc5, FDesc6, FDesc7, FDesc8, FDesc9} FDescDotype;
typedef enum {moveOne, MoveTwo, MoveThree, MoveFour, MoveFive, MoveSix, MoveSeven} MoveDotype;
typedef enum {external1, external2, theExternal} ExternalDotype;
typedef enum {Scan1, Scan2, Scan3, Scan4, Scan5} ScanNewDotype;
typedef enum {Quote1, Quote2, Quote3, Quote4, Quote5, Quote6, Quote7, Quote8, Quote9,
		Quote10} QuoterDotype;
typedef enum {EnterMain, ChatAEM1, ChatAEM2, ChatAEM3, ChatAEM4, ChatEM1, ChatEM2, ChatEM3, 
        ChatEM4, ChatCheckPrompt, ChatSendTo, ChatSysop1, ChatSysop2, ChatSysop3, ChatBlockWho, 
        ChatScroll, ChatScrollCheckP, ChatPrivate1, ChatPrivate2, ChatPrivate3} ChatroomDoType;
typedef enum {AB1, AB2, AB3, AB4, AB5, AB6, AB7, AB8, AB9, AB10, AB11, AB12} ABDoType;
typedef enum {PR1, PR2, PR3} PrivateDoType;
typedef enum {MSearch1, MSearch2, MSearch3, MSearch4, MSearch5, MSearch6, MSearch7, MSearch8, 
        MSearch9, MSearch10, MSearch11, MSearch12, MSearch13, MSearch14, MSearch15, MSearch16, 
        MSearch17, MSearch18, MSearch19, MSearch20, MSearch21, MSearch22, MSearch23, MSearch24, 
        MSearch25} MessSearchDoType;
			


typedef struct {
	unsigned char rawBuffer [4098];		/* 	used by the driver; “Don’t touch it!” */
	unsigned char incoming [4098];		/* 	“Don’t touch this either.” */
	short activeUserExternal;			/* 	if > 0 then external will be called */
	BoardModetype BoardMode;
	BoardSectiontype BoardSection;
	BDact boardAction, savedBDaction, savedBD2;
	AutoDotype AutoDo;
	ReadDotype ReadDo;
	EmailDotype EmailDo;
	MultiDotype MultiDo;
	MultiChatDotype MultiChatDo;
	BatDotype BatDo;
	KillDotype KillDo;
	TransDotype TransDo;
	SlowDotype SlowDo;
	bbsLdotype bbsLdo;
	upMesstype upMess;
	AllDotype AllDo;
	GFileDotype GFileDo;
	ExtenDotype ExtenDo;
	DownDotype DownDo;
	RenDotype RenDo;
	SortDotype SortDo;
	RFDotype RFDo;
	ChatDotype ChatDo;
	NodeDotype NodeDo;
	PostDotype PostDo;
	UploadDotype UploadDo;
	ListDotype ListDo;
	QDotype QDo;
	UEdotype UEdo;
	rmvDotype rmvDo;
	DefaultDotype DefaultDo;
	MainStagetype MainStage;
	Quiztype Quiz;
	LogonStagetype LogonStage;
	OffDotype OffDo;
	AttachDotype AttachDo;
	DetachDotype DetachDo;
	FDescDotype FDescDo;
	MoveDotype MoveDo;
	ExternalDotype ExternalDo;
	ScanNewDotype ScanNewDo;
	QuoterDotype QuoterDo;


	ProcMenuHandle myProcMenu;
	HermesPrompt myPrompt;
	Str255 replyStr, menuCommands, ansInProgress, curPrompt, mDriverName, enteredPass, curBaudNote, enteredPass2, typeBuffer, fileMask, excess, inportName, outportname, replyToStr, lastTransError, savedInPort, chatreason;
	long inits, openTextSize, lastKeyPressed, startedChat, lastTry, lastFTUpdate, currentBaud, lastLastPressed, lastCurBytes, crossLong, curTextPos, subtractOn, lastBlink, timeBegin, extraTime, uptime, downtime, lastLeft, timeout, startCPS;
	short nodeType, headMessage, lnsPause, inputRef, outputRef, frontCharElim, openTextRef, maxPromptChars, atEMail, endAnony, totalEMails, onBatchNumber;
	Boolean sysopLogOn, prompting, stopRemote, retob, inTransfer, inHalfDuplex, continuous, inZScan, inNScan, fromQScan, endQScan, newFeed, timeFlagged, single, doCheckMessage, inPause, allDirSearch, aborted, in8BitTerm, ansiTerm, callFMail, chatKeySysop, sentAnon, batchTrans, wrapPrompt, promptHide, sysopStop, triedChat, threadmode, reply, validLogon, readMsgs;
	Boolean gettingANSI, HWHH, dirUpload, goOffinLocal, shutDownSoon, wasMadeTempSysop, negateBCR, tabbyPaused, inScroll, countingDown, netMail, blinkOn, useDTR, capturing, amSpying, doCrashmail, matchInterface, replyToAnon, descSearch, goBackToLogon, listedOneFile, returnafterprompt, afterHangup, listingHelp;
	Handle toBeSent, protCodeHand;
	Ptr sendingNow;
	HermesTextHand curWriting, curQuoting;
	CharsHandle sysopKeyBuffer, optBuffer;
	FLSHand fileTransit;
	ParamBlockRec myBlocker;
	HermesTextHand textHnd;
	long bUploadCompense;
	DSPPBPtr nodeDSPPBPtr;
	TPCCB nodeCCBPtr;
	MPPPBPtr nodeMPPPtr;
	Ptr nodeSendCCBPtr, nodeRecCCBPtr, nodeAttnCCBPtr;
	short modemID, maxBaud, minBaud, inMessage, mesRead, maxLines, onLine, savedLine, configForum, inForum, inConf, numRptPrompt, realSL, inDir, tempDir, flsListed, fListedCurDir, curDirPos, tempInDir, crossInt, crossInt2, crossInt3, dirOpenNum, curNumFiles, xFerAutoStart, hangingUp, nodeCCBRefNum, useWorkspace, saveInForum, saveInSub, helpNum, captureRef, curNumMess, activeProtocol, lastBatch;
	UserRec thisUser, tempUser, mailingUser;
	CarDetType carrierDetect;
	MessgHand curmessage;
	long lastFScan;
	intListHand myEmailList;
	XFERStuffHand extTrans;
	InternalTransfer myTrans;
	SubDyHand curBase;
	DialogPtr transDilg;
	aDirHand curOpenDir;
	RgnHandle blinkRgn;
	MessIndexHand curIndex;
	FidoAddress myFido;
	short multiUsers [20], numMultiUsers, spying, bufLns, rsIndex, replyToNum;
	EmailRec curEmailRec;
	MesgRec curMesgRec;
	Boolean fromMsgScan, dialing, waitDialResponse, alerted, gameIdleOn;
	long dialDelay;
	Handle invalidSerialJump, expiredJump;
	Ptr serialBinary, dataBuffer;
	SystPtr mySystNode;
	FilEntryRec curFil;
	DSPPBPtr nodeDSPWritePtr;
	short savecolor;
	Boolean sysOpNode;
	short rings, numRings, displayConf;
	unsigned char nodeName [32];
	short secLevel;
	short nodeRest, lastKey;
	Boolean inner, fromBeg, fromDetach;
	Byte filler;
	Str255 msgLine, myline, qname, attachFName;
	short inSubDir, tempSubDir, subDirOpenNum;
	Boolean newMsg, wasAttach, wasAttachMac, wasBatch, wasAMsg;
	short inRealDir, inRealSubDir;
	MyQuoteRec myQuote;
	short w, tempPos, newSL, numFails, mailOp, countTimeWarn;
	Boolean wasEmail, waswrapped, sendLogoff, welcomeAlternate, rawStdin, useNode;
	short crossint1, crossint4, crossint5, crossint6, crossint7, crossint8, crossint9;
	Boolean wasAnonymous, isMM;
	long externVars, callno;
	AddressBookHand addressBook;
	QuoteRec theQuote;
	Boolean inetMail;
	UserChatRec theChat;
	ChatroomDoType chatroomDo;
	ABDoType abDo;
	PrivateDoType privateDo;
	MessSearchDoType messSearchDo;
	MessageSearchHand messageSearch;
	Boolean wasSearching;
	Boolean noPause;
} 	HermUserGlobs, *HermUserGlobPtr, **HermUserGlobHand;


/*	Comment out the MySysPrivs and put it into your
	headers file if you’re writing a sysop external.	*/

typedef struct {
	long dummy;
} MySysPrivs;

typedef MySysPrivs *MySysPrivsPtr, **MySysPrivsHand;


typedef struct {
	MySysPrivsHand sysPrivates;
	SystPtr hSystPtr;
	MForumPtr hMForumPtr;
	MConferencesArray *hMConfPtr;
	MesgHand hEmail;
	DirListPtr hTForumPtr;
	ForumIdxPtr hTDirPtr;
	GFileSecPtr hGFilePtr;
	SecLevPtr hSecLevelsPtr;
	MailerPtr hMailerPtr;
	PtrToWord numHermUsers;
	StringPtr filesPath;
	PtrToWord extantEmails;
	PtrToWord emailUnclean;
	ProcPtr procs [1];
} HermDataRec, *HermDataPtr;


/*
typedef struct {
	long dummy;
} MyPrefs;	

typedef MyPrefs *MyPrefsPtr, **MyPrefsHand;


typedef struct {
	Boolean activeOn;
	Boolean smellsLikeCabbage;
	short stage;
} MyPrivs;
	
typedef MyPrivs *MyPrivsPtr, **MyPrivsHand;
*/

typedef struct {
	Handle prefsHandle;
	Handle privatesHandle;
	short extID;
	short totalNodes;
	short message;
	PtrToWord curNode;
	PtrToLong curUGlobs;
	SystPtr hSystPtr;
	MForumPtr hMForumPtr;
	MConferencesArray *hMConfPtr;
	MesgHand hEmail;
	DirListPtr hTForumPtr;
	ForumIdxPtr hTDirPtr;
	GFileSecPtr hGFilePtr;
	SecLevPtr hSecLevelsPtr;
	MailerPtr hMailerPtr;
	FeedbackPtr hFeedbackPtr;
	StringPtr filesPath;
	UListHand hermUsers;
	PtrToWord numHermUsers;
	PtrToWord extantEmails;
	PtrToWord emailUnclean;
	short numExternal;
	ExternListHand externals;
	HermUserGlobPtr n [10];
	ProcPtr procs [1];
}	UserXInfoRec, *UserXIPtr;


#pragma options align=reset

#if !powerc && !noHermesProcs

/*-------------------------------------------------------------------------------

	Hermes Procedures

-------------------------------------------------------------------------------*/

/* 	Outline Stuff */

pascal void bCr (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 0 */

pascal void Outln (Str255 goingOut, Boolean NLatBegin, short typeLine,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 1 */

pascal void OutLineC (Str255 goingOut, Boolean NLatBegin, short typeLine,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 2 */

pascal void OutLineSysop (Str255 goingOut, Boolean NLatBegin, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 3 */

pascal void BufferIt (Str255 goingOut, Boolean NLatBegin, short typeLine,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 4 */

pascal void BufferbCr (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 5 */

pascal void BufClearScreen (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 6 */

pascal void ReleaseBuffer (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 7 */

pascal void OutChr (short theChar, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 8 */

pascal void ANSICode (Str255 theCode, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 9 */

pascal void DoM (short typeL, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 10 */

pascal void ClearScreen (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 11 */

pascal void BackSpace (short howMany, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 12 */

pascal void SingleNodeOutput (Str255 whatString, short i, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 13 */

pascal void BroadCast (Str255 whatString, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 14 */


/* 	Prompt Stuff */

pascal void LettersPrompt (Str255 prompt, Str255 accepted, short sizeLimit,
	Boolean auto_accept, Boolean wrap, Boolean capital, short replace, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 15 */

pascal void NumbersPrompt (Str255 prompt, Str255 accepted, long high, long low,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 16 */

pascal void YesNoQuestion (Str255 prompt, Boolean yesIsDefault,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 17 */

pascal void PromptUser (short whichNode, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 18 */

pascal void PAUSEPrompt (Str255 prompt, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 19 */

pascal void ANSIPrompter (short numChars, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 20 */

pascal void RePrintPrompt (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 21 */


/* 	User Stuff */

pascal Boolean FindUser (Str255 searchString, UserRec *userFound,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 22, sysop selector = 25 */

pascal Boolean WriteUser (UserRec *theUser, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 23, sysop selector = 26 */

pascal void InitUserRec (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 24 */

pascal Boolean UserAllowed (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 25 */

pascal void ResetUserColors (UserRec *theUser, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 26 */

pascal void PrintUserStuff (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 27 */

pascal void YearsOld (UserRec *theUser, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 28 */

pascal Boolean UserOnSystem (Str255 name, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 29 */

pascal short WhatNode (Str255 name, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 30 */

pascal unsigned char *WhatUser (short node, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 31 */

pascal void GiveTime (long tickstoGive, float multiplier, Boolean tellUser,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 32 */
	
pascal long TicksLeft (short whichNode, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 33 */

pascal unsigned char *TickToTime (long whichTicks, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 34 */


/* 	Load and Save Stuff */

pascal void DoSystRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 35, sysop selector = 14 */

pascal void DoMenuRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 36, sysop selector = 15 */

pascal void DoTransRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 37, sysop selector = 16 */

pascal void DoForumRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 38, sysop selector = 17 */

pascal void DoGFileRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 39, sysop selector = 18 */

pascal void DoMailerRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 40, sysop selector = 19 */

pascal void DoSecRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 41, sysop selector = 20 */

pascal void LoadNewUser (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 42, sysop selector = 21 */

pascal void DoFBRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 43, sysop selector = 22 */

pascal void DoMForumRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 44, sysop selector = 23 */

pascal void DoMConferenceRec (Boolean save, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 45, sysop selector = 24 */


/* 	Message Stuff */

pascal void PrintConfList (short whichFor, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 46 */

pascal void PrintForumList (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 47 */

pascal void FindConference (short whichFor, short selected, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 48 */

pascal void FindDisplayConf (short whichFor, short theConf, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 49 */

pascal short OpenMData (short wForum, short wConf, Boolean index, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 50 */

pascal long SaveMessage (HermesTextHand charsToSave, short wForum, short wConf, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 51 */

pascal HermesTextHand ReadMessage (long storedAs, short wForum, short wConf, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 52 */

pascal void PrintCurMessage (Boolean updateQPtrs, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 53 */

pascal void RemoveMessage (long storedAs, short wForum, short wConf, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 54 */

pascal Boolean SavePost (short wForum, short wConf, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 55 */

pascal void SaveNetPost (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 56 */

pascal void AddLine (Str255 toAdd, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 57 */

pascal void DeletePost (short wForum, short wCong, short wMesg,
	Boolean delePost, ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 58 */

pascal unsigned char *TakeMsgTop (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 59 */

pascal void EnterMessage (short maxLines, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 60 */

pascal Boolean MForumOp (short forum, UserRec dirUser, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 61 */

pascal Boolean MConferenceOp (short forum, short conference, UserRec dirUser,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 62 */

pascal Boolean MForumOk (short which, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 63 */

pascal Boolean MConferenceOk (short wForum, short wConference, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 64 */

pascal void OpenBase (short whichForum, short whichSub, Boolean extraRec,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 65 */

pascal void SaveBase (short wForum, short wSub, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 66 */

pascal void CloseBase (ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 67 */

pascal void LoadFileAsMsg (Str255 name, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 68 */

pascal Boolean ReadTextFile (const StringPtr fileName, short storedAs, Boolean insertPath,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 69 */

pascal Boolean IsPostRatioOK (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 70 */

pascal void ReadAutoMessage (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 71 */


/* 	Email Stuff */

pascal void OpenEmail (ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 72 */

pascal void CloseEmail (ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 73 */

pascal void FindMyEmail (short userNum, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 74 */

pascal Boolean SaveMessAsEmail (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 75 */

pascal Boolean SaveEmailData (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 76 */

pascal void HeReadIt (EmailRec readMa, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 77 */

pascal void DeleteMail (long whichNum, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 78 */

pascal void DeleteFileAttachment (short whichMail, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 79 */


/* 	Transfer Stuff */

pascal Boolean AreaOp (short WhichDir, UserRec dirUser, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 80 */

pascal Boolean DirOp (short whichDir, short SubDir, UserRec dirUser,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 81 */

pascal Boolean ForumOk (short dir, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 82 */

pascal Boolean SubDirOk (short dir, short sub, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 83 */

pascal Boolean DownloadOk (short dir, short sub, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 84 */

pascal short FindSub (short dir, short sub, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 85 */

pascal short FindArea (short dir, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 86 */

pascal short HowManySubs (short dir, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 87 */

pascal void PrintDirList (Boolean prompt, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 88 */

pascal void PrintSubDirList (short whichDir, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 89 */

pascal void PrintTree (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 90 */

pascal void PrintExtended (short howMuch, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 91 */

pascal void ReadExtended (FilEntryRec theFil, short whichDir, short whichSub,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 92 */

pascal void AddExtended (FilEntryRec theFil, short whichDir, short whichSub,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 93 */

pascal void DeleteExtDesc (FilEntryRec theFile, short whichDir, short whichSub,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 94 */

pascal Boolean OpenDirectory (short whichDir, short SubDir, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 95 */

pascal void SaveDirectory (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 96 */

pascal void CloseDirectory (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 97 */

pascal short SortDir (short whichDir, short whichSub, Boolean which,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 98 */

pascal void GetNextFile (short temDir, short temSub, Str255 fileMsk,
	short *curposDir, FilEntryRec *tmpFile, long afterDate,
	ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 99 */

pascal void FileEntry (FilEntryRec theFil, short theDir, short theSub,
	short *sizeinK, short atDirPos, ProcPtr theRout) = {0x205f, 0x4e90};
	/* 	selector = 100 */

pascal short PrintFileInfo (FilEntryRec theFl, short fromDir, short fromSubDir,
	Boolean doOther, ProcPtr theRout) = {0x205f, 0x4e90};	/* 	selector = 101 */

pascal Boolean FExist (const StringPtr FNmPth, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 102 */

pascal void ListFil (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 103 */

pascal Boolean FileOKMask (Str255 fileNm, Str255 fileMsk, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 104 */

pascal void DoUpload (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 105 */

pascal void DoDownload (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 106 */

pascal void DoRename (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 107 */

pascal Boolean DLRatioOK (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 108 */


/* 	Serial Port Stuff */

pascal void OpenComPort (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 109 */

pascal void CloseComPort (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 110 */

pascal short Get1ComPort (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 111 */

pascal void TellModem (Str255 what, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 112 */

pascal void ClearInBuf (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 113 */

pascal Boolean AppleTalk (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 114 */

pascal short ADSPBytesToRead (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 115 */

pascal void StartADSPListener (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 116 */

pascal void OpenADSPListener (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 117 */

pascal void CloseADSPListener (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 118 */


/* 	Utility Procs */

pascal void LogError (Str255 error, Boolean inFore, short numBeeps, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 119 */

pascal void GoHome (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 120 */

pascal void HangUpAndReset (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 121 */

pascal void EndUser (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 122 */

pascal void LogThis (Str255 logIt, short rsrv, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 123 */

pascal unsigned char *GetDate (long well, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 124 */

pascal unsigned char *WhatTime (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 125 */

pascal unsigned char *Secs2Time (long howManySecs, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 126 */

pascal void DoCapsName (Str255 doName, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 127 */

pascal unsigned char *DoNumber (long t2, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 128 */

pascal OSErr AsyncMWrite (short myRefNum, long lengthWrite, Ptr whatWrite, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 129 */

pascal OSErr MySDGetBuf (long *returned, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 130 */

pascal OSErr MySyncRead (short modemRef, long lengthWrite, Ptr myBufPtr, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 131 */


/* 	Miscellaneous Stuff */

pascal OSErr Copy1File (Str255 inputPath, Str255 outputPath, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 132, sysop selector = 27 */

pascal void OpenCapture (Str255 path, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 133 */

pascal void CloseCapture (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 134 */

pascal Boolean InTrash (Str255 trashedName, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 135 */

pascal Boolean SaveText (Str255 thePath, Str255 theText, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 136, sysop selector = 29  */
	
pascal Boolean AgeOk (short howOld, short isit, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 137 */

pascal unsigned char *RetInStr (short index, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 138 */

pascal OSErr MakeADir (Str255 path, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 139 */

pascal void StartMySound (Str255 soundName, Boolean async, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 140, sysop selector = 28 */

pascal void OutANSItest (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 141 */

pascal Boolean SysopAvailable (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 142 */

pascal long FreeK (Str255 pathOn, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 143 */

pascal void PrintSysopStats (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 144 */

pascal void DoMailerImport (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 145 */

pascal void DoDetermineZMH (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 146 */

pascal void LaunchMailer (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 147 */

pascal void DecodeM (short typeL, CharStyle nowStyle, Str255 *ts, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 148 */

pascal void MakeColorSequence (short which, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 149 */

pascal void GetCharPrompt (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	selector = 175 */


/* 	Mac Interface / Sysop External Stuff */

pascal void SetGeneva (DialogPtr dialog, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 0 */

pascal void SetTextBox (DialogPtr dialog, short item, Str255 text, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 1 */

pascal unsigned char *GetTextBox (DialogPtr dialog, short item, ProcPtr theProc) =
	{0x205f, 0x4e90};	/* 	sysop selector = 2 */

pascal void SetCheckBox (DialogPtr dialog, short item, Boolean up, ProcPtr theProc) =
	{0x205f, 0x4e90};	/* 	sysop selector = 3 */

pascal Boolean GetCheckBox (DialogPtr dialog, short item, ProcPtr theProc) =
	{0x205f, 0x4e90};	/* 	sysop selector = 4 */

pascal void SetControlBox (DialogPtr dialog, short p, Str255 tempString, Boolean toof,
	ProcPtr theProc) = {0x205f, 0x4e90};	/* 	sysop selector = 5 */

pascal long UpDown (DialogPtr dialog, short Box, long Value, long Adder, long Hi, long Lo,
	ProcPtr theProc) = {0x205f, 0x4e90};	/* 	sysop selector = 6 */

pascal float UpDownReal (DialogPtr dialog, short Box, long Value, long Adder, long Hi, long Lo,
	ProcPtr theProc) = {0x205f, 0x4e90};	/* 	sysop selector = 7 */

pascal Boolean OptionDown (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 8 */

pascal Boolean CmdDown (ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 9 */

pascal void AddListString (Str255 theString, ListHandle theList, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 10 */
	
pascal short ModalQuestion (Str255 askWhat, Boolean saveBox, Boolean yesNo, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 11 */

pascal void FrameIt (DialogPtr dialog, short item, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 12 */

pascal void ProblemRep (Str255 tellUser, ProcPtr theRout) =
	{0x205f, 0x4e90};	/* 	sysop selector = 13 */

#endif /*  !powerc */

#endif
