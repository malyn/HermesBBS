unit TCPTypes;

{ TCPTypes © Peter Lewis, Oct 1991 }
{ This source is Freeware }

interface

{ Hacks }
	type
		unsignedword = INTEGER;
		unsignedlong = LONGINT;

{ Stolen from MacTypes.p }
	type
		SInt8 = -128..127;
		SInt16 = INTEGER;
		SInt32 = LONGINT;
		UInt8 = 0..255;
		UInt16 = INTEGER;
		UInt32 = LONGINT;

{$PUSH}
{$ALIGN MAC68K}

{ MacTCP return Codes in the range -23000 through -23049 }
	const
		ipBadLapErr = -23000;					{ bad network configuration }
		ipBadCnfgErr = -23001;				{ bad IP configuration error }
		ipNoCnfgErr = -23002;					{ missing IP or LAP configuration error }
		ipLoadErr = -23003;					{ error in MacTCP load }
		ipBadAddrErr = -23004;					{ error in getting address }
		connectionClosingErr = -23005;			{ connection is closing }
		invalidLengthErr = -23006;
		connectionExistsErr = -23007;			{ request conflicts with existing connection }
		connectionDoesntExistErr = -23008;		{ connection does not exist }
		insufficientResourcesErr = -23009;		{ insufficient resources to perform request }
		invalidStreamPtrErr = -23010;
		streamAlreadyOpenErr = -23011;
		connectionTerminatedErr = -23012;
		invalidBufPtrErr = -23013;
		invalidRDSErr = -23014;
		invalidWDSErr = -23014;
		openFailedErr = -23015;
		commandTimeoutErr = -23016;
		duplicateSocketErr = -23017;

{ Error codes from internal IP functions }
		ipDontFragErr = -23032;				{ Packet too large to send w/o fragmenting }
		ipDestDeadErr = -23033;				{ destination not responding }
		icmpEchoTimeoutErr = -23035;		{ ICMP echo timed-out }
		ipNoFragMemErr = -23036;			{ no memory to send fragmented pkt }
		ipRouteErr = -23037;					{ can't route packet off-net }

		nameSyntaxErr = -23041;
		cacheFaultErr = -23042;
		noResultProcErr = -23043;
		noNameServerErr = -23044;
		authNameErrErr = -23045;
		noAnsErr = -23046;
		dnrErr = -23047;
		outOfMemoryErr = -23048;

{ connectionState }
	const
		CState_Closed = 0;
		CState_Listening = 2;
		CState_Opening1 = 4;
		CState_Opening2 = 6;
		CState_Established = 8;
		CState_Closing1 = 10;
		CState_Closing2 = 12;
		CState_Closing3 = 16;
		CState_Closing4 = 18;
		CState_Closing5 = 20;
		CState_PleaseClose = 14;

	type
		AddrClasses = integer;
	const
		AC_A = 1;
		AC_NS = 2;
		AC_CNAME = 5;
		AC_HINFO = 13;
		AC_MX = 15;

	const
		CTRUE = $FF;
		CFALSE = $00;

	type
		C_BOOLEAN = SignedByte;
		CSTRING = Ptr;
		CStr30 = packed array[0..29] of char;
		CStr255 = packed array[0..255] of char;
		ipAddr = unsignedlong;
		ipAddrArray = array[1..1000] of ipAddr;
		ipAddrArrayPtr = ^ipAddrArray;
		ipPort = unsignedword;
		StreamPtr = Ptr;

	type
		wdsType = record			{ Write block for TCP driver. }
				size: UInt16;				{ Number of bytes. }
				buffer: Ptr;				{ Pointer to bytes. }
				term: UInt16;				{ Zero for end of blocks. }
			end;
		wdsPtr = ^wdsType;
		wdsEntry = record
				size: UInt16;				{ Number of bytes. }
				buffer: Ptr;				{ Pointer to bytes. }
			end;

	type
		HInfoRec = record
				cpuType: CStr30;
				osType: CStr30;
			end;

	type
		MXRec = record
				preference: integer; { unsigned! }
				exchange: CStr255;
			end;

	type
		hostInfo = record
				rtnCode: longint;
				rtnHostName: CStr255;
				case integer of
					1: (
							addrs: array[1..4] of ipAddr;
					);
					2: (
							hinfo: HInfoRec;
					);
					3: (
							mx: MXRec;
					);
			end;
		hostInfoPtr = ^hostInfo;
{}
{		hostInfo = record}
{				rtnCode: longint;}
{				rtnHostName: Str255;}
{				addrs: array[1..4] of ipAddr;}
{			end;}
{		hostInfoPtr = ^hostInfo;}
{}

	type
		cacheEntryRecord = record
				cname: CSTRING;
				typ: integer;
				class: integer;
				ttl: longint;
				case integer of
					1: (
							name: CSTRING;
					);
					2: (
							addr: ipAddr;
					);
			end;
		cacheEntryRecordPtr = ^cacheEntryRecord;

	const { csCodes for the TCP driver: }
		TCPcsGetMyIP = 15;
		TCPcsEchoICMP = 17;
		TCPcsLAPStats = 19;
		TCPcsCreate = 30;
		TCPcsPassiveOpen = 31;
		TCPcsActiveOpen = 32;
{    TCPcsActOpenWithData = 33;}
		TCPcsSend = 34;
		TCPcsNoCopyRcv = 35;
		TCPcsRcvBfrReturn = 36;
		TCPcsRcv = 37;
		TCPcsClose = 38;
		TCPcsAbort = 39;
		TCPcsStatus = 40;
		TCPcsExtendedStat = 41;
		TCPcsRelease = 42;
		TCPcsGlobalInfo = 43;

		UDPcsCreate = 20;
		UDPcsRead = 21;
		UDPcsBfrReturn = 22;
		UDPcsWrite = 23;
		UDPcsRelease = 24;
		UDPcsMaxMTUSize = 25;
		UDPcsStatus = 26;
		UDPcsMultiCreate = 27;
		UDPcsMultiSend = 28;
		UDPcsMultiRead = 29;

	type
		TCPEventCode = integer;
	const
		TEC_Closing = 1;
		TEC_ULPTimeout = 2;
		TEC_Terminate = 3;
		TEC_DataArrival = 4;
		TEC_Urgent = 5;
		TEC_ICMPReceived = 6;
		TEC_last = 32767;

	type
		UDPEventCode = integer;
	const
		UDPDataArrival = 1;
		UDPICMPReceived = 2;
		lastUDPEvent = 32767;

	type
		TCPTerminateReason = integer;
	const {TCPTerminateReasons: }
		TTR_RemoteAbort = 2;
		TTR_NetworkFailure = 3;
		TTR_SecPrecMismatch = 4;
		TTR_ULPTimeoutTerminate = 5;
		TTR_ULPAbort = 6;
		TTR_ULPClose = 7;
		TTR_ServiceError = 8;
		TTR_last = 32767;

	type
		ICMPMsgType = integer;
	const
		ICMP_NetUnreach = 0;
		ICMP_HostUnreach = 1;
		ICMP_ProtocolUnreach = 2;
		ICMP_PortUnreach = 3;
		ICMP_FragReqd = 4;
		ICMP_SourceRouteFailed = 5;
		ICMP_TimeExceeded = 6;
		ICMP_ParmProblem = 7;
		ICMP_MissingOption = 8;

	type
		TCPNotifyProc = ProcPtr;
{ procedure TCPNotifyProc(tcpStream:StreamPtr; event:TCPEventCode; userDataPtr:Ptr; }
{                                   terminReason:TCPTerminateReason; icmpMsg:ICMPReportPtr); }

	type
		TCPIOCompletionProc = ProcPtr;
{ C procedure TCPIOCompletionProc(iopb:TCPControlBlockPtr); - WHY IS THIS A C PROC???? }

	type
		UDPNotifyProc = ProcPtr;
{ procedure UDPProc(udpStream:StreamPtr ; eventCode:integer;userDataPtr:Ptr; icmpMsg:ICMPReportPtr) }

	type
		UDPIOCompletionProc = ProcPtr;
{ C procedure UDPIOCompletionProc(iopb:UDPiopb Ptr) }

	type
		ICMPEchoNotifyProc = ProcPtr;
{ C procedure ICMPEchoNotifyProc(iopb:IPControlBlockPtr) }
{ WARNING: Ignore the docs, its a C proceudre no matter what they say }

	type
		ICMPReport = record
				stream: StreamPtr;
				localhost: ipAddr;
				localport: ipPort;
				remotehost: ipAddr;
				remoteport: ipPort;
				reporttype: ICMPMsgType;
				optionalAddlInfo: integer;
				optionalAddlInfoPtr: Ptr;
			end;

	const
		NBP_TABLE_SIZE = 20;			{ number of NBP table entries }
		NBP_MAX_NAME_SIZE = 16 + 10 + 2;
		ARP_TABLE_SIZE = 20;			{ number of ARP table entries }

	type
		nbpEntry = record
				ip_address: ipAddr;				{ IP address }
				at_address: longint;				{ matching AppleTalk address }
				gateway: Boolean;				{ TRUE if entry for a gateway }
				valid: Boolean;					{ TRUE if LAP address is valid }
				probing: Boolean;				{ TRUE if NBP lookup pending }
				age: integer;					{ ticks since cache entry verified }
				access: integer;					{ ticks since last access }
				filler: packed array[1..116] of Byte;			{ for internal use only !!! }
			end;
		EnetAddr = record
				en_hi: integer;
				en_lo: longint;
			end;
		arpEntry = record
				age: integer;			{ cache aging field }
				protocol: integer;		{ Protocol type }
				ip_address: ipAddr;		{ IP address }
				en_address: EnetAddr;		{ matching Ethernet address }
			end;
		AddrXlation = record
				case integer of
					0: (
							arp_table: ^arpEntry
					);
					1: (
							nbp_entry: ^nbpEntry
					)
			end;
		LAPStats = record
				ifType: integer;
				ifString: CSTRING;
				ifMaxMTU: integer;
				ifSpeed: longint;
				ifPhyAddrLength: integer;
				ifPhysicalAddress: CSTRING;
				addr: AddrXlation;
				slotNumber: integer;
			end;
		IPEchoPB = record
				dest: ipAddr;				{ echo to IP address }
				data: wdsEntry;
				timeout: integer;
				options: Ptr;
				optlength: integer;
				icmpCompletion: ICMPEchoNotifyProc;
				userDataPtr: Ptr;
			end;
		LAPStatsPB = record
				lapStatsPtr: ^LAPStats;
			end;
		ICMPEchoInfo = record
				params: array[1..11] of integer;
				echoRequestOut: longint;	{ time in ticks of when the echo request went out }
				echoReplyIn: longint;		{ time in ticks of when the reply was received }
				data: wdsEntry;		{ data received in responce }
				options: Ptr;
				userDataPtr: Ptr;
			end;
		IPGetMyIPPB = record
				ourAddress: ipAddr;			{ our IP address }
				ourNetMask: ipAddr;			{ our IP net mask }
			end;

		IPControlBlock = record
				qLink: QElemPtr;
				qType: INTEGER;
				ioTrap: INTEGER;
				ioCmdAddr: Ptr;
				ioCompletion: TCPIOCompletionProc; {completion routine, or NIL if none}
				ioResult: OSErr; {result code}
				ioNamePtr: StringPtr;
				ioVRefNum: INTEGER;
				ioCRefNum: INTEGER; {device refnum}
				case csCode : integer of
					TCPcsGetMyIP: (
							getmyip: IPGetMyIPPB;
					);
					TCPcsEchoICMP: (
							echo: IPEchoPB
					);
					9999: (
							echoinfo: ICMPEchoInfo
					);
					TCPcsLAPStats: (
							lapstat: LAPStatsPB
					);
			end;
		IPControlBlockPtr = ^IPControlBlock;

	type
		UDPCreatePB = record { for create and release calls }
				rcvBuff: Ptr;
				rcvBuffLen: longint;
				notifyProc: UDPNotifyProc;
				localport: ipPort;
				userDataPtr: Ptr;
				endingPort: ipPort;
			end;

	type
		UDPSendPB = record
				reserved: integer;
				remoteip: ipAddr;
				remoteport: ipPort;
				wds: wdsPtr;
				checksum: SignedByte;
				sendLength: integer;
				userDataPtr: Ptr;
				localport: ipPort;
			end;

	type
		UDPReceivePB = record
				timeout: integer;
				remoteip: ipAddr;
				remoteport: ipPort;
				rcvBuff: Ptr;
				rcvBuffLen: integer;
				secondTimeStamp: integer;
				userDataPtr: Ptr;
				destHost: ipAddr;
				destPort: ipPort;
			end;

	type
		UDPMTUPB = record
				mtuSize: integer;
				remoteip: ipAddr;
				userDataPtr: Ptr;
			end;

	type
		UDPControlBlock = record
				qLink: QElemPtr;
				qType: INTEGER;
				ioTrap: INTEGER;
				ioCmdAddr: Ptr;
				ioCompletion: UDPIOCompletionProc;
				ioResult: OSErr;
				ioNamePtr: StringPtr;
				ioVRefNum: integer;
				ioCRefNum: integer;
				csCode: integer;
				udpStream: StreamPtr;
				case integer of
					UDPcsCreate, UDPcsMultiCreate, UDPcsRelease: (
							create: UDPCreatePB
					);
					UDPcsWrite, UDPcsMultiSend: (
							send: UDPSendPB
					);
					UDPcsRead, UDPcsMultiRead: (
							receive: UDPReceivePB
					);
					UDPcsBfrReturn: (
							return: UDPReceivePB
					);
					UDPcsMaxMTUSize: (
							mtu: UDPMTUPB
					);
			end;
		UDPControlBlockPtr = ^UDPControlBlock;

	const { Validity Flags }
		timeOutValue = $80;
		timeOutAction = $40;
		typeOfService = $20;
		precedence = $10;

	const { TOSFlags }
		lowDelay = $01;
		throughPut = $02;
		reliability = $04;

	type
		TCPCreatePB = packed record
				rcvBuff: Ptr;
				rcvBuffLen: longint;
				notifyProc: TCPNotifyProc;
				userDataPtr: Ptr;
			end;

		TCPOpenPB = packed record
				ulpTimeoutValue: Byte;
				ulpTimeoutAction: SignedByte;
				validityFlags: Byte;
				commandTimeoutValue: Byte;
				remotehost: ipAddr;
				remoteport: ipPort;
				localhost: ipAddr;
				localport: ipPort;
				tosFlags: Byte;
				precedence: Byte;
				dontFrag: C_BOOLEAN;
				timeToLive: Byte;
				security: Byte;
				optionCnt: Byte;
				options: array[0..39] of Byte;
				userDataPtr: Ptr;
			end;

		TCPSendPB = packed record
				ulpTimeoutValue: Byte;
				ulpTimeoutAction: SignedByte;
				validityFlags: Byte;
				pushFlag: Byte;
				urgentFlag: C_BOOLEAN;
				wds: wdsPtr;
				sendFree: longint;
				sendLength: integer;
				userDataPtr: Ptr;
			end;

		TCPReceivePB = packed record
				commandTimeoutValue: Byte;
				filler: Byte;
				markFlag: C_BOOLEAN;
				urgentFlag: C_BOOLEAN;
				rcvBuff: Ptr;
				rcvBuffLength: integer;
				rdsPtr: Ptr;
				rdsLength: integer;
				secondTimeStamp: integer;
				userDataPtr: Ptr;
			end;

		TCPClosePB = packed record
				ulpTimeoutValue: Byte;
				ulpTimeoutAction: SignedByte;
				validityFlags: Byte;
				userDataPtrX: Ptr;   { Thats mad!  Its not on a word boundary! Parhaps a documentation bug??? }
			end;

		HistoBucket = packed record
				value: integer;
				counter: longint;
			end;

	const
		NumOfHistoBuckets = 7;

	type
		TCPConnectionStats = packed record
				dataPktsRcvd: longint;
				dataPktsSent: longint;
				dataPktsResent: longint;
				bytesRcvd: longint;
				bytesRcvdDup: longint;
				bytesRcvdPastWindow: longint;
				bytesSent: longint;
				bytesResent: longint;
				numHistoBuckets: integer;
				sentSizeHisto: array[1..NumOfHistoBuckets] of HistoBucket;
				lastRTT: unsignedword;
				tmrRTT: unsignedword;
				rttVariance: unsignedword;
				tmrRTO: unsignedword;
				sendTries: Byte;
				sourceQuenchRcvd: Byte;
			end;
		TCPConnectionStatsPtr = ^TCPConnectionStats;

		TCPStatusPB = packed record
				ulpTimeoutValue: Byte;
				ulpTimeoutAction: SignedByte;
				unused: longint;
				remotehost: ipAddr;
				remoteport: ipPort;
				localhost: ipAddr;
				localport: ipPort;
				tosFlags: Byte;
				precedence: Byte;
				connectionState: Byte;
				filler: Byte;
				sendWindow: integer;
				rcvWindow: integer;
				amtUnackedData: integer;
				amtUnreadData: integer;
				securityLevelPtr: Ptr;
				sendUnacked: longint;
				sendNext: longint;
				congestionWindow: longint;
				rcvNext: longint;
				srtt: longint;
				lastRTT: longint;
				sendMaxSegSize: longint;
				connStatPtr: TCPConnectionStatsPtr;
				userDataPtr: Ptr;
			end;

		TCPAbortPB = packed record
				userDataPtr: Ptr;
			end;

		TCPParam = packed record
				tcpRTOA: StringPtr;
				tcpRTOMin: longint;
				tcpRTOMax: longint;
				tcpMaxSegSize: longint;
				tcpMaxConn: longint;
				tcpMaxWindow: longint;
			end;
		TCPParamPtr = ^TCPParam;

		TCPStats = packed record
				tcpConnAttempts: longint;
				tcpConnOpened: longint;
				tcpConnAccepted: longint;
				tcpConnClosed: longint;
				tcpConnAborted: longint;
				tcpOctetsIn: longint;
				tcpOctetsOut: longint;
				tcpOctetsInDup: longint;
				tcpOctetsRetrans: longint;
				tcpInputPackets: longint;
				tcpOutputPkts: longint;
				tcpDupPkts: longint;
				tcpRetransPkts: longint;
			end;
		TCPStatsPtr = ^TCPStats;

		StreamPtrArray = array[1..1000] of StreamPtr;
		StreamPtrArrayPtr = ^StreamPtrArray;

		TCPGlobalInfoPB = packed record
				tcpParamp: TCPParamPtr;
				tcpStatsp: TCPStatsPtr;
				tcpCDBTable: StreamPtrArrayPtr;
				userDataPtr: Ptr;
				maxTCPConnections: integer;
			end;

		TCPControlBlock = record
				qLink: QElemPtr;
				qType: INTEGER;
				ioTrap: INTEGER;
				ioCmdAddr: Ptr;
				ioCompletion: TCPIOCompletionProc; {completion routine, or NIL if none}
				ioResult: OSErr; {result code}
				ioNamePtr: StringPtr;
				ioVRefNum: INTEGER;
				ioCRefNum: INTEGER; {device refnum}
				csCode: integer;
				tcpStream: StreamPtr;
				case integer of
					TCPcsCreate: (
							create: TCPCreatePB
					);
					TCPcsActiveOpen, TCPcsPassiveOpen: (
							open: TCPOpenPB;
					);
					TCPcsSend: (
							send: TCPSendPB;
					);
					TCPcsNoCopyRcv, TCPcsRcvBfrReturn, TCPcsRcv: (
							receive: TCPReceivePB;
					);
					TCPcsClose: (
							close: TCPClosePB;
					);
					TCPcsAbort: (
							abort: TCPAbortPB;
					);
					TCPcsStatus: (
							status: TCPStatusPB;
					);
					TCPcsGlobalInfo: (
							globalInfo: TCPGlobalInfoPB
					);
			end;
		TCPControlBlockPtr = ^TCPControlBlock;

{$ALIGN RESET}
{$POP}

implementation

end.