{Segments: NodePrefs_1, NodePrefs_2}
unit NodePrefs;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, CommResources, CRMSerialDevices, TCPTypes, Initial, NodePrefs2;

	procedure ClickInNodePrefs (theEvent: EventRecord; itemHit: integer);
	procedure OpenNodePrefs;
	procedure UpdateNodePrefs;
	procedure AnalyzeProtocols;
	procedure DoCapsName (var doName: str255);
	procedure ConOpt2Con (var key: char);
	function ConOpt2Num (key: char): integer;
	procedure CloseNodePrefs;
	function SysopAvailable: boolean;
	function UserAllowed: boolean;
	function isMyTextWindow (theWind: windowPtr): integer;
	procedure AdjustViewRect (docTE: TEHandle);
	procedure AdjustScrollbars (whichw: integer; needsResize: BOOLEAN);
	procedure AdjustTE (whichW: integer);
	procedure OpenTextWindow (path, name: str255; isResource: boolean; canEdit: boolean);
	procedure CloseTextWindow (accessWind: integer);
	procedure SaveTextWindow (accessWind: integer);
	function doGetDirectory: str255;
	function doGetApplication: str255;
	function FidoNetAccount (toBeParsed: str255): boolean;
	function InternetAccount (toBeParsed: str255): boolean;
	procedure KillXFerRec;
	procedure InitXFerRec;
	function copy1File (inputPath, outputPath: str255): OSErr;
	procedure SelectDirectory (var dir, sub: integer);
	procedure LoadDirectories;
	procedure LoadModemDrivers;
	procedure CloseComPort;
	procedure OpenComPort;
	procedure CloseADSPConnection;
	function ADSPBytesToRead: integer;
	procedure StartADSPListener;
	procedure OpenADSPListener;
	procedure CloseADSPListener;
	procedure OpenModemFile (name: str255);
{ TCP functions. }
	function CreateTCPStream (tcpPtr: HermesTCPPtr): OSErr;
	procedure DestroyTCPStream (tcpPtr: HermesTCPPtr);
	procedure InitiateTCPConnection (tcpPtr: HermesTCPPtr; remoteAddress: ipAddr; remotePort: ipPort; timeout: Byte);
	procedure StartTCPListener (tcpPtr: HermesTCPPtr);
	function TCPBytesToRead (tcpPtr: HermesTCPPtr): integer;
	procedure AbortTCPConnection (tcpPtr: HermesTCPPtr);
	procedure CloseTCPConnection (tcpPtr: HermesTCPPtr; timeout: Byte);
	procedure IPAddrToString (ip: longint; var addrStr: Str255);


implementation
	var
		modDrivList, ListPorts, SDList, SDDList: ListHandle;
		wasDouble: boolean;
		rcList: ListHandle;
		csize, selectThis: point;

{$S NodePrefs_1}

	function CreateTCPStream (tcpPtr: HermesTCPPtr): OSErr;
		var
			err: OSErr;
			cb: TCPControlBlock;
	begin
	{ Create the TCP control block for this stream. }
		tcpPtr^.tcpPBPtr := TCPControlBlockPtr(NewPtr(SizeOf(TCPControlBlock)));

	{ Create the TCP buffer for this stream. }
		tcpPtr^.tcpBuffer := NewPtr(TCPBUFSIZE);

	{ Create the WDS pointer for this stream. }
		tcpPtr^.tcpWDSPtr := wdsPtr(NewPtr(SizeOf(wdsType)));

	{ Issue the create call. }
		with cb do
		begin
			ioResult := 1;
			ioCompletion := nil;

			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsCreate;

			create.rcvBuff := tcpPtr^.tcpBuffer;
			create.rcvBuffLen := TCPBUFSIZE;
			create.notifyProc := nil;
			create.userDataPtr := nil;
		end;
		err := PBControl(ParmBlkPtr(@cb), false);
		if (err = noErr) then
			tcpPtr^.tcpStreamPtr := Ptr(cb.tcpStream)
		else
			tcpPtr^.tcpStreamPtr := nil;

	{ Return. }
		CreateTCPStream := err;
	end;

	procedure DestroyTCPStream (tcpPtr: HermesTCPPtr);
		var
			err: OSErr;
			cb: TCPControlBlock;
	begin
	{ Close the stream. }
		with cb do
		begin
			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsRelease;
			tcpStream := StreamPtr(tcpPtr^.tcpStreamPtr);
		end;
		err := PBControl(ParmBlkPtr(@cb), false);

	{ Destroy all of our pointers. }
		DisposPtr(Ptr(tcpPtr^.tcpWDSPtr));
		DisposPtr(tcpPtr^.tcpBuffer);
		DisposPtr(Ptr(tcpPtr^.tcpPBPtr));
		tcpPtr^.tcpPBPtr := nil;
	end;

	procedure InitiateTCPConnection (tcpPtr: HermesTCPPtr; remoteAddress: ipAddr; remotePort: ipPort; timeout: Byte);
		var
			err: OSErr;
	begin
		with tcpPtr^.tcpPBPtr^ do
		begin
			ioResult := 1;
			ioCompletion := nil;

			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsActiveOpen;
			tcpStream := tcpPtr^.tcpStreamPtr;

			open.ulpTimeoutValue := timeout;
			open.ulpTimeoutAction := 1;
			open.validityFlags := 0;
			open.remotehost := remoteAddress;
			open.remoteport := remotePort;
			open.localport := 0;
			open.tosFlags := 0;
			open.precedence := 0;
			open.dontFrag := 0;
			open.timeToLive := 0;
			open.security := 0;
			open.optionCnt := 0;
			open.userDataPtr := nil;
		end;
		err := PBControl(ParmBlkptr(tcpPtr^.tcpPBPtr), true);
	end;

	procedure StartTCPListener (tcpPtr: HermesTCPPtr);
		var
			err: OSErr;
	begin
		with TCPControlBlockPtr(tcpPtr^.tcpPBPtr)^ do
		begin
			ioResult := 1;
			ioCompletion := nil;

			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsPassiveOpen;
			tcpStream := tcpPtr^.tcpStreamPtr;

			open.validityFlags := 0;
			open.commandTimeoutValue := 0;
			open.remotehost := 0;
			open.remoteport := 0;
			open.localport := 23;
			open.dontFrag := 0;
			open.timeToLive := 0;
			open.security := 0;
			open.optionCnt := 0;
			open.userDataPtr := nil;
		end;
		err := PBControl(ParmBlkptr(tcpPtr^.tcpPBPtr), true);
	end;

	function TCPBytesToRead (tcpPtr: HermesTCPPtr): integer;
		var
			err: OSErr;
			cb: TCPControlBlock;
	begin
		with cb do
		begin
			ioResult := 1;
			ioCompletion := nil;

			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsStatus;
			tcpStream := tcpPtr^.tcpStreamPtr;

			status.userDataPtr := nil;
		end;
		err := PBControl(ParmBlkPtr(@cb), false);
		if (err = noErr) then
			TCPBytesToRead := cb.status.amtUnreadData
		else
			TCPBytesToRead := 0;
	end;

	procedure AbortTCPConnection (tcpPtr: HermesTCPPtr);
		var
			err: OSErr;
			cb: TCPControlBlock;
	begin
		with cb do
		begin
			ioResult := 1;
			ioCompletion := nil;

			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsAbort;
			tcpStream := tcpPtr^.tcpStreamPtr;

			abort.userDataPtr := nil;
		end;
		err := PBControl(ParmBlkPtr(@cb), false);
	end;

	procedure CloseTCPConnection (tcpPtr: HermesTCPPtr; timeout: Byte);
		var
			err: OSErr;
	begin
		with TCPControlBlockPtr(tcpPtr^.tcpPBPtr)^ do
		begin
			ioResult := 1;
			ioCompletion := nil;

			ioCRefNum := ippDrvrRefNum;
			csCode := TCPcsClose;
			tcpStream := tcpPtr^.tcpStreamPtr;

			close.ulpTimeoutValue := timeout;
			close.ulpTimeoutAction := -1;
			close.validityFlags := $c0;
			close.userDataPtrX := nil;
		end;
		err := PBControl(ParmBlkPtr(tcpPtr^.tcpPBPtr), true);
	end;

	procedure IPAddrToString (ip: longint; var addrStr: Str255);
		function GetByte (ip: longint; bits: integer): Str255;
			var
				t: Str255;
		begin
			NumToString(band(bsr(ip, bits), $00FF), t);
			GetByte := t;
		end;
	begin
		addrStr := GetByte(ip, 24);
		addrStr := concat(addrStr, '.', GetByte(ip, 16));
		addrStr := concat(addrStr, '.', GetByte(ip, 8));
		addrStr := concat(addrStr, '.', GetByte(ip, 0));
	end;

	procedure OpenModemFile (name: str255);
		var
			tr, i, mdm: integer;
			newModem, tempModem: ModemDriverHand;
	begin
		tr := OpenResFile(name);
		mdm := OpenRFPerm(concat(sharedFiles, 'Modem Drivers'), 0, fsRdWrPerm);
		if (tr <> -1) and (mdm <> -1) then
		begin
			newModem := ModemDriverHand(GetResource('MoDr', 1000));
			if (newModem <> nil) and (GetHandleSize(handle(NewModem)) = sizeOf(modemDriver)) then
			begin
				DetachResource(handle(newModem));
				UseResFile(mdm);
				tempModem := ModemDriverHand(Get1NamedResource('MoDr', newModem^^.name));
				if tempModem <> nil then
				begin
					RmveResource(handle(tempModem));
					DisposHandle(handle(tempModem));
					for i := 0 to numModemDrivers - 1 do
						if EqualString(modemDrivers^^[i].name, newModem^^.name, false, false) then
							modemDrivers^^[i] := newModem^^;
				end
				else
				begin
					SetHandleSize(handle(modemDrivers), GetHandleSize(handle(modemDrivers)) + SizeOf(modemDriver));
					modemDrivers^^[numModemDrivers] := newModem^^;
					numModemDrivers := numModemDrivers + 1;
				end;
				AddResource(handle(newModem), 'MoDr', UniqueID('MoDr'), newModem^^.name);
			end;
			CloseResFile(tr);
			CloseResFile(mdm);
		end;
	end;

	procedure CloseADSPListener;
		var
			t1: str255;
			dspPB: DSPParamBlock;
	begin
		if appletalk then
		begin
			gMPP.entityPtr := Ptr(ord4(@gNTE.nteData) + 1);
			result := PRemoveName(@gMPP, false);
			if result <> noErr then
				ProblemRep(StringOf(RetInStr(558), result : 0));	{AppleTalk error, RemoveName: }
			with dspPB do
			begin
				csCode := dspCLRemove;
				ioCRefNum := dspDrvrRefNum;
				ccbRefNum := gCCBRef;
				abort := 1;
			end;
			result := PBControl(ParmBlkPtr(@dspPB), false);
			if result <> noErr then
				ProblemRep(StringOf(RetInStr(559), result : 0));	{AppleTalk error, CloseADSP: }
		end;
	end;

	procedure StartADSPListener;
	begin
		if appletalk then
		begin
			with gDSP do
			begin
				ioCompletion := nil;
				csCode := dspCLListen;
				ioCRefNum := dspDrvrRefNum;
				ccbRefNum := gCCBRef;
				filterAddress := AddrBlock(0);
			end;
			result := PBControl(ParmBlkPtr(@gDSP), true);
		end;
	end;

	procedure OpenADSPListener;
	begin
		if appletalk then
		begin
			if (mppDrvrRefNum = -1) then
			begin
				result := OpenDriver('.MPP', mppDrvrRefNum);
				if result <> noErr then
					exit(OpenADSPListener);
				result := OpenDriver('.DSP', dspDrvrRefNum);
				if result <> noErr then
				begin
					ProblemRep(RetInStr(560));	{ADSP not installed.  A null port will be created instead.}
					exit(OpenADSPListener);
				end;
				with gDSP do
				begin
					csCode := dspCLInit;
					ioCRefNum := dspDrvrRefNum;
					ccbPtr := @gCCB;
					localSocket := 0;
				end;
				result := PBControl(ParmBlkPtr(@gDSP), false);
				gCCBRef := gDSP.ccbRefNum;
				NBPSetNTE(@gNTE, BBSName, 'ADSP', '*', gDSP.localSocket);
				with gMPP do
				begin
					interval := 7;
					count := 3;
					entityPtr := @gNTE;
					verifyFlag := 0;
				end;
				result := PRegisterName(@gMPP, false);
				if result <> noErr then
					SysBeep(10);
				StartADSPListener;
			end;
		end;
	end;

	function ADSPBytesToRead: integer;
	begin
		if appletalk then
		begin
			with curGlobs^ do
			begin
				with nodeDSPPBPtr^ do
				begin
					csCode := dspStatus;
					ioCompletion := nil;
					ioCRefNum := dspDrvrRefNum;
					ccbRefNum := nodeCCBRefNum;
				end;
				result := PBControl(ParmBlkPtr(nodeDSPPBPtr), false);
				ADSPBytesToRead := nodeDSPPBPtr^.recvQPending;
			end;
		end;
	end;

	procedure CloseADSPConnection;
	begin
		if appletalk then
		begin
			with curGlobs^ do
			begin
				with nodeDSPPBPtr^ do
				begin
					csCode := dspClose;
					ioCompletion := nil;
					ioCRefNum := dspDrvrRefNum;
					ccbRefNum := nodeCCBRefNum;
					abort := 1;
				end;
				result := PBControl(ParmBlkPtr(nodeDSPPBPtr), false);
				if (result <> noErr) then
					SysBeep(10);
			end;
		end;
	end;

	procedure CloseComPort;
		var
			dontDropDTR: Byte;
	begin
		with curglobs^ do
		begin
			case nodeType of
				1: 
				begin
					result := KillIO(inputRef);
					result := KillIO(outputRef);
					result := SerSetBuf(inputRef, @rawBuffer, 0);
					if TabbyQuit = CrashMail then
					begin
						dontDropDTR := $F0;
						result := Control(outputRef, 16, @dontDropDTR);
					end;
					result := CloseDriver(inputref);
					result := CloseDriver(outputRef);
				end;
				2: 
				begin
					if (nodeCCBPtr^.state = sOpen) then
						CloseADSPConnection;
					with nodeDSPPBPtr^ do
					begin
						csCode := dspRemove;
						ioCompletion := nil;
						ioCRefNum := dspDrvrRefNum;
						ccbRefNum := nodeCCBRefNum;
						abort := 1;
					end;
					result := PBControl(ParmBlkPtr(nodeDSPPBPtr), false);
					if (result <> noErr) then
						SysBeep(10);
					DisposPtr(Ptr(nodeSendCCBPtr));
					DisposPtr(Ptr(nodeRecCCBPtr));
					DisposPtr(Ptr(nodeAttnCCBPtr));
					DisposPtr(Ptr(nodeDSPPBPtr));
					DisposPtr(Ptr(nodeDSPWritePtr));
					DisposPtr(Ptr(nodeMPPPtr));
					DisposPtr(Ptr(nodeCCBPtr));
					nodeCCBPtr := nil;
				end;
				3: 
				begin
					DestroyTCPStream(@nodeTCP);
				end;
				otherwise
			end;
		end;
	end;

	procedure OpenComPort;
		label
			100;
		var
			tempInt: integer;
			tempLong: longint;
			t1: str255;
			myEvent: EventRecord;
			errorStr: Str255;
	begin
		with curglobs^ do
		begin
			if (inPortName = TCPNAME) and (tcpSupported) then
				nodeType := 3
			else if (inPortName = ADSPNAME) and (appletalk) then
				nodeType := 2
			else if (inportname <> 'None') and (length(inPortName) > 0) then
				nodeType := 1
			else
				nodeType := -1;
			case nodeType of
				1: 
				begin
					result := OpenDriver(inPortName, inputRef);
					if tabbyPaused then
						result := noErr;
					if result <> noErr then
					begin
						NumToString(result, errorStr);
						ProblemRep(Concat('Port: "', inPortName, '" is currently in use.  Please free it or select another.  Error #', errorStr));
						nodeType := -1;
						inPortName := 'None';
						inputRef := -1;
						outputref := -1;
					end
					else
					begin
						result := OpenDriver(outPortName, outputRef);
						result := SerSetBuf(inputRef, @rawBuffer, 4096);
						result := SerReset(inputRef, data8 + stop10 + noParity + baud19200);
					end;
				end;
				2: 
				begin
					if nodeCCBPtr = nil then
					begin
						OpenADSPListener;
						nodeCCBPtr := TPCCB(NewPtr(SizeOf(TRCCB)));
						nodeSendCCBPtr := NewPtr(ADSPSENDBUFSIZE);
						nodeRecCCBPtr := NewPtr(ADSPRECBUFSIZE);
						nodeAttnCCBPtr := NewPtr(attnBufSize);
						nodeDSPPBPtr := DSPPBPtr(NewPtr(SizeOf(DSPParamBlock)));
						nodeDSPWritePtr := DSPPBPtr(NewPtr(SizeOf(DSPParamBlock)));
						nodeDSPWritePtr^.ioResult := noErr;
						nodeMPPPtr := MPPPBPtr(NewPtr(SizeOf(MPPParamBlock)));
						with nodeDSPPBPtr^ do
						begin
							ioCompletion := nil;
							ioCRefNum := dspDrvrRefNum;
							csCode := dspInit;
							ccbPtr := nodeCCBPtr;
							userRoutine := nil;
							sendQSize := ADSPSENDBUFSIZE;
							recvQSize := ADSPRECBUFSIZE;
							sendQueue := nodeSendCCBPtr;
							recvQueue := nodeRecCCBPtr;
							attnPtr := nodeAttnCCBPtr;
							localSocket := 0;
						end;
						result := PBControl(ParmBlkPtr(nodeDSPPBPtr), false);
						if (result <> noErr) then
							goto 100;
						nodeCCBRefNum := nodeDSPPBPtr^.ccbRefNum;
					end;
				end;
				3: 
				begin
					if nodeTCP.tcpPBPtr = nil then
					begin
						result := CreateTCPStream(@nodeTCP);
						if (result <> noErr) then
							goto 100;
						StartTCPListener(@nodeTCP);
					end;
				end;
				-1: 
				begin
100:
					nodeType := -1;
					inportname := 'None';
					inputRef := -1;
					outputref := -1;
				end;
				otherwise
			end;
		end;
	end;


	procedure LoadDirectories;
		var
			i, Dirs, NumDirs: integer;
			DirHand: ReadDirHandle;
	begin
		Dirs := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
		if Dirs = -1 then
		begin
			result := Create(concat(sharedFiles, 'Directories'), 0, 'HRMS', 'DATA');
			CreateResFile(concat(sharedFiles, 'Directories'));
			Dirs := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
		end;
		forums := DirListHand(NewHandleClear(0));
		HNoPurge(handle(forums));
		if forumIdx^^.numforums > 0 then
		begin
			for i := 1 to forumIdx^^.numforums do
			begin
				DirHand := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[i - 1]));
				SetHandleSize(handle(forums), GetHandleSize(handle(forums)) + sizeOf(DirDataFile));
				forums^^[i - 1] := DirHand^^;
			end;
		end;
		closeResFile(Dirs);
	end;

	procedure LoadModemDrivers;
		var
			numMoDr, i, mdm: integer;
			moDrHand: ModemDriverHand;
	begin
		mdm := OpenRFPerm(concat(SharedFiles, 'Modem Drivers'), 0, fsRdWrPerm);
		if (mdm <> -1) then
		begin
			modemDrivers := MoDrListHand(NewHandleClear(0));
			HNoPurge(handle(modemDrivers));
			numModemDrivers := 0;
			numMoDr := Count1Resources('MoDr');
			if numMoDr > 0 then
				for i := 1 to numMoDr do
				begin
					moDrHand := ModemDriverHand(Get1IndResource('MoDr', i));
					if GetHandleSize(handle(moDRHand)) = sizeOf(modemDriver) then
					begin
						SetHandleSize(handle(modemDrivers), GetHandleSize(handle(modemDrivers)) + SizeOf(modemDriver));
						modemDrivers^^[numModemDrivers] := moDrHand^^;
						numModemDrivers := numModemDrivers + 1;
					end;
				end;
			closeResFile(mdm);
		end
		else
			ProblemRep(RetInStr(561));	{Modem Drivers file not found.}
	end;

	procedure AddListItem (theList: ListHandle; theString: Str255);
		var
			theRow: integer;
			sTemp: str255;
	begin
		cSize.h := 0;
		theRow := LAddRow(1, 200, theList);
		cSize.v := theRow;
		sTemp := theString;
		LSetCell(pointer(ord(@sTemp) + 1), length(sTemp), cSize, theList);
	end;

	function myMDFilter (theDialog: dialogPtr; var ev: EventRecord; var it: integer): boolean;
		var
			localPt: point;
			t: integer;
	begin
		if (ev.what = mouseDown) then
		begin
			wasDouble := false;
			SetPort(theDialog);
			localPt := ev.where;
			GlobalToLocal(localPt);
			if LClick(localPt, ev.modifiers, rcList) then
			begin
				wasDouble := true;
				selectThis.h := 0;
				selectThis.v := 0;
				if LGetSelect(true, selectThis, rcList) then
					;
			end;
		end;
		myMDFilter := false;
	end;

	function EditModemDriver (var sdr: modemDriver): boolean;
		var
			dType, a, i, edr: integer;
			dItem: handle;
			tempRect, dataBounds: rect;
			tempCell: cell;
			md: dialogPtr;
			td: dialogPeek;
			dr: modemDriver;
			done, selectNew: boolean;
			inp: resultCode;
			tte: TEHandle;
			t1, t2, t3: str255;
		procedure InResult;
		begin
			SetTextBox(md, 21, stringOf(inp.num : 0));
			SetTextBox(md, 22, stringOf(inp.portRate : 0));
			SetTextBox(md, 23, stringOf(inp.effRate : 0));
			SetTextBox(md, 24, inp.desc);
		end;
		procedure GetResult;
			var
				tl: longint;
		begin
			t1 := GetTextBox(md, 21);
			t2 := GetTextBox(md, 22);
			t3 := GetTextBox(md, 23);
			inp.desc := GetTextBox(md, 24);
			StringToNum(t1, tl);
			inp.num := tl;
			StringToNum(t2, inp.portRate);
			StringToNum(t3, inp.effRate);
		end;
		procedure ResetModemDriverList;
			var
				i: integer;
				tc: cell;
		begin
			LDoDraw(false, rcList);
			tc.h := 0;
			tc.v := 0;
			if LGetSelect(true, tc, rcList) then
				;
			LDelRow(0, 0, rcList);
			if dr.numResults > 0 then
				for i := 0 to dr.numResults - 1 do
				begin
					AddListItem(rcList, StringOf(dr.rs[i].num : 0, ',', dr.rs[i].portRate : 0, ',', dr.rs[i].effRate, ',', dr.rs[i].desc));
				end;
			if selectNew then
				tc.v := dr.numResults - 1;
			selectNew := false;
			LSetSelect(true, tc, rcList);
			LAutoScroll(rcList);
			LDoDraw(true, rcList);
			GetDItem(md, 15, dType, dItem, tempRect);
			tempRect.right := tempRect.right - 15;
			InsetRect(tempRect, -1, -1);
			EraseRect(tempRect);
			FrameRect(tempRect);
			LUpdate(rcList^^.port^.visRgn, rcList);
		end;
	begin
		done := false;
		edr := -1;
		md := GetNewDialog(1542, nil, pointer(-1));
		SetPort(md);
		SetGeneva(md);
		dr := sdr;
		SetTextBox(md, 1, dr.name);
		SetTextBox(md, 6, dr.bbsInit);
		SetTextBox(md, 7, dr.termInit);
		SetTextBox(md, 8, dr.hwOn);
		SetTextBox(md, 9, dr.hwOff);
		SetTextBox(md, 13, dr.lockOn);
		SetTextBox(md, 14, dr.lockOff);
		SetTextBox(md, 10, dr.ansModem);
		SetTextBox(md, 16, dr.reset);
		GetDItem(md, 15, dType, dItem, tempRect);
		tempRect.right := tempRect.right - 15;
		InsetRect(tempRect, -1, -1);
		FrameRect(tempRect);
		InsetRect(tempRect, 1, 1);
		SetRect(dataBounds, 0, 0, 1, 0);
		tempCell.h := tempRect.Right - tempRect.Left;
		tempCell.v := 12;
		rcList := LNew(tempRect, dataBounds, tempCell, 0, md, TRUE, FALSE, FALSE, TRUE);
		rcList^^.selFlags := lOnlyOne + lNoNilHilite;
		ShowWindow(md);
		ResetModemDriverList;
		repeat
			ModalDialog(@myMDFilter, a);
			case a of
				21, 22, 23, 24: 
				begin
					if edr <> -1 then
					begin
						GetResult;
						dr.rs[edr] := inp;
						ResetModemDriverList;
					end;
				end;
				15: 
				begin
					if wasDouble then
					begin
						if (edr <> -1) then
						begin
							GetResult;
							dr.rs[edr] := inp;
							ResetModemDriverList;
						end;
						edr := selectThis.v;
						inp := dr.rs[selectThis.v];
						InResult;
					end;
				end;
				25: 
				begin
					if (edr <> -1) then
					begin
						GetResult;
						dr.rs[edr] := inp;
						ResetModemDriverList;
					end;
					if dr.numResults < 100 then
					begin
						edr := dr.numResults;
						dr.numResults := dr.numResults + 1;
						inp.num := 1;
						inp.portRate := 300;
						inp.effRate := 300;
						inp.desc := '300';
						dr.rs[edr] := inp;
						InResult;
						selectNew := true;
					end
					else
						ProblemRep(RetInStr(562));	{Sorry, no more than 50 result codes are allowed.}
				end;
				26: 
				begin
					tempCell.h := 0;
					tempCell.v := 0;
					if LGetSelect(true, tempCell, rcList) then
					begin
						if dr.numResults > tempCell.v + 1 then
							for i := tempCell.v + 1 to dr.numResults do
								dr.rs[i - 1] := dr.rs[i];
						dr.numResults := dr.numResults - 1;
						ResetModemDriverList;
						edr := -1;
					end;
				end;
				17: 
				begin
					if (edr <> -1) then
					begin
						GetResult;
						dr.rs[edr] := inp;
					end;
					done := true;
					dr.name := getTextBox(md, 1);
					dr.bbsInit := getTextBox(md, 6);
					dr.termInit := getTextBox(md, 7);
					dr.hwOn := getTextBox(md, 8);
					dr.hwOff := getTextBox(md, 9);
					dr.lockOn := getTextBox(md, 13);
					dr.lockOff := getTextBox(md, 14);
					dr.ansModem := getTextBox(md, 10);
					dr.reset := getTextBox(md, 16);
					sdr := dr;
					EditModemDriver := true;
				end;
				18: 
				begin
					done := true;
					EditModemDriver := false;
				end;
				otherwise
			end;
		until done;
		LDispose(rcList);
		DisposDialog(md);
	end;

	function DirSelectModal (theDialog: DialogPtr; var theEvent: EventRecord; var itemHit: integer): boolean;
		var
			localPt: point;
			tempCell: Cell;
			i, Dtype: integer;
			Ditem: Handle;
			tempRect: Rect;
	begin
		if theEvent.what = mouseDown then
		begin
			localPt := theEvent.where;
			GlobalToLocal(localPt);
			if LClick(localPt, theEvent.modifiers, SDDList) then
			begin
				curglobs^.crossint := 8888;
			end;
			if LClick(localPt, theEvent.modifiers, SDList) then
			begin
			end;
		end;
		DirSelectModal := false;
	end;


	procedure SelectDirectory (var dir, sub: integer);
		var
			DType, theRow, a, i: integer;
			DItem: handle;
			tempRect, dataBounds: rect;
			cSize, tempcell: cell;
			sTemp: str255;
			SDDilog: DialogPtr;
	begin
		curglobs^.crossint := 0;
		SDDilog := GetNewDialog(228, nil, pointer(-1));
		SetPort(SDDilog);
		SetGeneva(SDDilog);
		GetDItem(SDDilog, 2, DType, DItem, tempRect);
		tempRect.Right := tempRect.Right - 15;
		InsetRect(tempRect, -1, -1);
		FrameRect(tempRect);
		InsetRect(tempRect, 1, 1);
		SetRect(dataBounds, 0, 0, 1, 0);
		cSize.h := tempRect.Right - tempRect.Left;
		cSize.v := 11;
		SDList := LNew(tempRect, dataBounds, cSize, 0, SDDilog, TRUE, FALSE, FALSE, TRUE);
		SDLIst^^.selFlags := lOnlyOne + lNoNilHilite;
		for i := 1 to ForumIdx^^.numforums do
		begin
			cSize.h := 0;
			theRow := LAddRow(1, 200, SDLIst);
			cSize.v := theRow;
			sTemp := forumIdx^^.name[i - 1];
			LSetCell(Pointer(ord(@sTemp) + 1), length(sTemp), cSize, SDLIst);
		end;
		LDoDraw(TRUE, SDLIst);
		ShowWindow(SDDilog);
		LUpdate(SDDilog^.visRgn, SDLIst);
		GetDItem(SDDilog, 2, DType, DItem, tempRect);
		tempRect.Right := tempRect.Right - 15;
		InsetRect(tempRect, -1, -1);
		FrameRect(tempRect);
		GetDItem(SDDilog, 3, DType, DItem, tempRect);
		tempRect.Right := tempRect.Right - 15;
		InsetRect(tempRect, -1, -1);
		FrameRect(tempRect);
		InsetRect(tempRect, 1, 1);
		SetRect(dataBounds, 0, 0, 1, 0);
		cSize.h := tempRect.Right - tempRect.Left;
		cSize.v := 11;
		SDDList := LNew(tempRect, dataBounds, cSize, 0, SDDilog, TRUE, FALSE, FALSE, TRUE);
		SDDLIst^^.selFlags := lOnlyOne + lNoNilHilite;
		for i := 1 to ForumIdx^^.numdirs[0] do
		begin
			cSize.h := 0;
			theRow := LAddRow(1, 200, SDDLIst);
			cSize.v := theRow;
			sTemp := forums^^[0].dr[i].dirname;
			LSetCell(Pointer(ord(@sTemp) + 1), length(sTemp), cSize, SDDLIst);
		end;
		LDoDraw(TRUE, SDDLIst);
		ShowWindow(SDDilog);
		LUpdate(SDDilog^.visRgn, SDDLIst);
		GetDItem(SDDilog, 3, DType, DItem, tempRect);
		tempRect.Right := tempRect.Right - 15;
		InsetRect(tempRect, -1, -1);
		FrameRect(tempRect);
		csize.v := 0;
		csize.h := 0;
		LSetSelect(True, cSize, SDList);
		repeat
			modalDialog(@DirSelectModal, a);
			if a = 2 then
			begin
				tempCell.h := 0;
				tempCell.v := 0;
				if LGetSelect(True, tempCell, SDLIST) then
				begin
					LDoDraw(false, SDDList);
					LDelRow(0, 0, SDDList);
					if ForumIdx^^.numDirs[tempcell.v] > 0 then
					begin
						for i := 1 to ForumIdx^^.numDirs[tempcell.v] do
						begin
							AddListString(forums^^[tempcell.v].dr[i].dirName, SDDLIST);
						end;
					end;
					LdoDraw(TRUE, SDDLIST);
					GetDItem(SDDilog, 3, DType, DItem, tempRect);
					tempRect.Right := tempRect.Right - 15;
					InsetRect(tempRect, -1, -1);
					EraseRect(tempRect);
					FrameRect(tempRect);
					LUpdate(SDDLIST^^.port^.visRgn, SDDLIST);
				end;
			end;
		until (a = 1) or (a = 4) or (curglobs^.crossInt = 8888);
		if (a = 1) or (curglobs^.crossint = 8888) then
		begin
			cSize.h := 0;
			cSize.v := 0;
			if LGetSelect(true, cSize, SDList) then
			begin
				dir := cSize.v;
			end
			else
				dir := -1;
			cSize.h := 0;
			cSize.v := 0;
			if LGetSelect(true, cSize, SDDList) then
			begin
				sub := cSize.v + 1;
			end
			else
				sub := -1;
		end
		else
		begin
			dir := -1;
			sub := -1;
		end;
		LDispose(SDLIst);
		DisposDialog(SDDilog);
	end;

	function SysopAvailable: boolean;
		var
			tempLong: LongInt;
			tempDate, tempDate2, tempDate3: DateTimeRec;
			tempbool: boolean;
	begin
		tempBool := false;
		GetTime(tempDate3);
		Secs2Date(InitSystHand^^.opStartHour, tempdate);
		Secs2Date(InitSystHand^^.opEndHour, tempdate2);
		if not ((tempDate.hour = tempDate2.hour) and (tempDate.minute = tempDate2.minute)) then
		begin
			if (tempDate2.hour < tempDate.hour) then
			begin
				if (tempDate3.hour >= tempDate.hour) or (tempDate3.hour <= tempDate2.hour) then
					tempBool := true;
			end
			else
			begin
				if (tempDate3.hour >= tempDate.hour) and (tempDate3.hour < tempDate2.hour) then
					tempBool := true;
			end;
		end;
		if SysopAvailC then
			tempBool := not tempBool;
		SysopAvailable := tempBool;
	end;

	function UserAllowed: boolean;
		var
			tempLong: LongInt;
			tempDate, tempDate2, tempDate3: DateTimeRec;
			tempbool: boolean;
	begin
		with CurGlobs^ do
		begin
			tempBool := true;
			if thisUser.RestrictHours then
			begin
				GetTime(tempDate3);
				Secs2Date(thisUser.StartHour, tempdate);
				Secs2Date(thisUser.endHour, tempdate2);
				if not ((tempDate.hour = tempDate2.hour) and (tempDate.minute = tempDate2.minute)) then
				begin
					if (tempDate2.hour < tempDate.hour) then
					begin
						if (tempDate3.hour >= tempDate.hour) or (tempDate3.hour <= tempDate2.hour) then
							tempBool := false;
					end
					else
					begin
						if (tempDate3.hour >= tempDate.hour) and (tempDate3.hour < tempDate2.hour) then
							tempBool := false;
					end;
				end;
			end;
			UserAllowed := tempBool;
		end;
	end;

	procedure SaveTextWindow (accessWind: integer);
		var
			tempint, fileRef: integer;
			name: str255;
			myTEH: handle;
			tempChars, myTChars: CharsHandle;
			tempLong: longint;
	begin
		with textWinds[accessWind] do
		begin
			GetWTitle(w, name);
			dirty := false;
			if wasResource then
			begin
				UseResFile(TextRes);
				SetResLoad(false);
				myTEH := GetNamedResource(origPath, name);
				SetResLoad(true);
				RmveResource(myTEH);
				DisposHandle(myTEH);
				tempChars := TEGetText(t);
				myTChars := CharsHandle(NewHandle(t^^.teLength));
				if memerror = noErr then
				begin
					BlockMove(pointer(tempChars^), pointer(myTChars^), t^^.teLength);
					AddResource(handle(myTChars), origPath, UniqueID(origPath), name);
					if resError <> noErr then
						SysBeep(10);
					WriteResource(handle(myTChars));
					ReleaseResource(handle(myTChars));
				end
				else
					SysBeep(10);
				UseResFile(myResourceFile);
			end
			else
			begin
				result := FSDelete(concat(origPath, name), 0);
				result := Create(concat(Origpath, name), 0, 'HRMS', 'TEXT');
				if result = noErr then
				begin
					result := FSOpen(concat(Origpath, name), 0, fileRef);
					if result = noErr then
					begin
						tempLong := t^^.teLength;
						tempChars := TEGetText(t);
						result := FSWrite(fileRef, tempLong, pointer(tempChars^));
						result := FSClose(fileRef);
					end
					else
						SysBeep(10);
				end
				else
					SysBeep(10);
			end;
		end;
	end;

	procedure CloseTextWindow (accessWind: integer);
		var
			tempint: integer;
			name: str255;
	begin
		with textWinds[accessWind] do
		begin
			if editable then
			begin
				getWTitle(w, name);
				if dirty then
				begin
					tempInt := ModalQuestion(concat(RetInStr(563), name, '''?'), true, false);	{Save changes to }
					if tempint = 1 then
						SaveTextWindow(accessWind)
					else if tempInt = 0 then
						exit(closeTextWindow);
				end;
			end;
			TEDispose(t);
			DisposeControl(s);
			DisposeWindow(w);
			if (accessWind + 1) < numTextWinds then
			begin
				for tempint := accessWind to (numTextWinds - 1) do
				begin
					textWinds[tempint] := textWinds[tempint + 1];
				end;
			end;
			numTextWinds := numTextWinds - 1;
		end;
	end;

	function isMyTextWindow (theWind: windowPtr): integer;  {returns -1 if not}
		var
			i: integer;
	begin
		isMyTextWindow := -1;
		if numTextWinds > 0 then
		begin
			for i := 1 to numTextWinds do
				if textWinds[i - 1].w = theWind then
					isMyTextWindow := i - 1;
		end;
	end;

{$D-}
	procedure AdjustTE (whichW: integer);
{Scroll the TERec around to match up to the potentially updated scrollbar}
{values. This is really useful when the window resizes such that the}
{scrollbars become inactive and the TERec had been previously scrolled.}
		var
			value: INTEGER;
	begin
		with textWinds[whichW] do
		begin
			TEScroll(0, (t^^.viewRect.top - t^^.destRect.top) - (GetCtlValue(s) * t^^.lineHeight), t);
		end;
	end; {AdjustTE}

	procedure AdjustHV (isVert: BOOLEAN; control: ControlHandle; docTE: TEHandle; canRedraw: BOOLEAN);
{Calculate the new control maximum value and current value, whether it is the horizontal or}
{vertical scrollbar. The vertical max is calculated by comparing the number of lines to the}
{vertical size of the viewRect. The horizontal max is calculated by comparing the maximum document}
{width to the width of the viewRect. The current values are set by comparing the offset between}
{the view and destination rects. If necessary and we canRedraw, have the control be re-drawn by}
{calling ShowControl.}
		var
			value, lines, max: INTEGER;
			oldValue, oldMax: INTEGER;
	begin
		oldValue := GetCtlValue(control);
		oldMax := GetCtlMax(control);
		if isVert then
		begin
			lines := docTE^^.nLines;
		{since nLines isn’t right if the last character is a return, check for that case}
			if Ptr(ORD(docTE^^.hText^) + docTE^^.teLength - 1)^ = 13 then
				lines := lines + 1;
			max := lines - ((docTE^^.viewRect.bottom - docTE^^.viewRect.top) div docTE^^.lineHeight);
		end
		else
			max := kMaxDocWidth - (docTE^^.viewRect.right - docTE^^.viewRect.left);
		if max < 0 then
			max := 0;			{check for negative values}
		SetCtlMax(control, max);
		if isVert then
			value := (docTE^^.viewRect.top - docTE^^.destRect.top) div docTE^^.lineHeight
		else
			value := docTE^^.viewRect.left - docTE^^.destRect.left;
		if value < 0 then
			value := 0
		else if value > max then
			value := max;					{pin the value to within range}
		SetCtlValue(control, value);
		if canRedraw & ((max <> oldMax) | (value <> oldValue)) then
			ShowControl(control);			{check to see if the control can be re-drawn}
	end; {AdjustHV}

	procedure AdjustScrollbars (whichw: integer; needsResize: BOOLEAN);
{Turn off the controls by jamming a zero into their contrlVis fields (HideControl erases them}
{and we don't want that). If the controls are to be resized as well, call the procedure to do that,}
{then call the procedure to adjust the maximum and current values. Finally re-enable the controls}
{by jamming a $FF in their contrlVis fields.}
		var
			oldMax, oldVal: INTEGER;
	begin
		with textWinds[whichW] do
		begin
			s^^.contrlVis := 0;
{    if needsResize then								}
{    AdjustScrollSizes(whichW);}

			AdjustHV(TRUE, s, t, not needsResize);

			if ((t^^.viewRect.bottom - t^^.viewRect.top) div 11) > t^^.nLines then
				HiLiteControl(s, 255)
			else
				HiliteControl(s, 0);
			s^^.contrlVis := $FF;
		end;
	end;



	procedure MyCaretHook;
	inline
		$4FEF, $0004, $4E75;

	procedure FakeTEHook;
	begin
		myCaretHook;
	end;

	procedure AdjustViewRect (docTE: TEHandle);

{Update the TERec's view rect so that it is the greatest multiple of}
{the lineHeight and still fits in the old viewRect.}

	begin
		with docTE^^ do
		begin
			viewRect.bottom := (((viewRect.bottom - viewRect.top) div lineHeight) * lineHeight) + viewRect.top;
		end;
	end; {AdjustViewRect}

	procedure PascalClikLoop;
{Gets called from our assembly language routine, AsmClikLoop, which is in}
{ turn called by the TEClick toolbox routine. Saves the windows clip region,}
{ sets it to the portRect, adjusts the scrollbar values to match the TE scroll}
{ amount, then restores the clip region.}
		var
			window: WindowPtr;
			region: RgnHandle;
			i: integer;
	begin
		window := FrontWindow;
		region := NewRgn;
		GetClip(region);					{save the old clip}
		ClipRect(window^.portRect);			{set the new clip}
		i := isMyTextWindow(window);
		AdjustHV(TRUE, textWinds[i].s, textWinds[i].t, true);
		SetClip(region);					{restore the old clip}
		DisposeRgn(region);
	end; {PascalClikLoop}
	procedure SaveRegisters;
	inline
		$48E7, $6040;                        {   MOVEM.L D1/D2/A1,-(A7)  ;Registers _FrontWindow}
	procedure CallOldClikLoop (ProcAddr: ProcPtr);
 {Modified to work with THINK Pascal}
	inline
		$205F,              {   MOVEA.L (A7)+, A0       ;Get address of function}
		$4CDF, $0206, {   MOVEA.L (A7)+,D1/D2/A1  ;Restore registers}
		$4E5E,               {   UNLK A6                 ;Restore A6 register}
		$4E90,              {   JSR     (A0)            ;Do function}
		$4E56, $0000; {   LINK A6,#$0000          ;Restore stack frame}
	procedure SetD0;
	inline
		$7001;                          {   MOVEQ   #1,D0                     ;Return 1 in D0}
	function AsmClikLoop: BOOLEAN;
	begin
		SaveRegisters;
		CallOldClikLoop(textWinds[0].docClik);
		PascalClikLoop;
		SetD0;
	end; {AsmClikLoop}
{$D+}

	procedure OpenTextWindow (path, name: str255; isResource: boolean; canEdit: boolean);
		label
			500;
		var
			myRect, sbarRect, texRect: rect;
			myTHand: handle;
			tempLong: longint;
			fileRef: integer;
	begin
		if numTextWinds < 10 then
		begin
			numTextWinds := numTextWinds + 1;
			with textWinds[numTextWinds - 1] do
			begin
				wasResource := isResource;
				editable := canEdit;
				origPath := path;
				dirty := false;
				SetRect(myRect, 5, 40 + (20 * numTextWinds), 505, screenBits.bounds.bottom - 20);
				w := NewWindow(nil, myRect, name, false, 0, pointer(-1), true, 0);
				if w = nil then
					goto 500;
				SetPort(w);
				SetRect(sBarRect, w^.portRect.right - 15, -1, w^.portRect.right + 1, w^.portRect.bottom - 14);
				s := NewControl(w, sBarRect, '', true, 0, 0, 0, 16, 0);
				if s = nil then
					goto 500;
				SetRect(texRect, 2, 2, w^.portRect.right - 18, w^.portRect.bottom - 18);
				t := TENew(texRect, texRect);  {this is DestRect,viewrect}
				if t = nil then
					goto 500;
				windowPeek(w)^.refCon := longint(t);
				t^^.crOnly := 1;
				t^^.txFont := 150;
				t^^.txSize := 9;
				t^^.lineHeight := 11;
				t^^.fontAscent := 9;
				docClik := t^^.clikLoop;
				t^^.clikLoop := @AsmClikLoop;
				if not editable then
					t^^.caretHook := @FakeTEHook;
				if isResource then
				begin
					UseResFile(TextRes);
					myTHand := GetNamedResource(path, name);
					if myTHand <> nil then
					begin
						HLock(handle(myTHand));
						tempLong := SizeResource(myTHand);
						TESetText(ptr(myTHand^), tempLong, t);
						HUnlock(handle(myTHand));
						ReleaseResource(myTHand);
					end
					else
						SysBeep(10);
					UseResFile(myResourceFile);
				end
				else
				begin
					result := FSOpen(concat(path, name), 0, fileRef);
					if result = noErr then
					begin
						result := GetEOF(fileRef, templong);
						if tempLong > 32000 then
							tempLong := 32000;
						myTHand := NewHandle(tempLong);
						HLock(handle(myTHand));
						result := FSRead(fileRef, tempLong, pointer(myTHand^));
						TESetText(ptr(myTHand^), tempLong, t);
						HUnlock(handle(myTHand));
						DisposHandle(handle(myTHand));
						result := FSClose(fileRef);
					end
					else
						SysBeep(10);
				end;
				SetCtlMax(s, t^^.nLines - ((t^^.viewRect.bottom - t^^.viewRect.top) div 11));
				if ((t^^.viewRect.bottom - t^^.viewRect.top) div 11) > t^^.nLines then
					HiLiteControl(s, 255);
				TEAutoView(true, t);
				AdjustViewRect(t);
				ShowWindow(w);
				TEActivate(t);
			end;
		end
		else
			ProblemRep(RetInStr(564));	{Sorry, only ten text windows may be open at once.}
		exit(OpenTextWindow);
500:
		ProblemRep(RetInStr(565));	{Memory is running low, please close some windows.}
	end;

	function copy1File (inputPath, outputPath: str255): OSErr;
		label
			5;
		var
			errorCode, ignore: OSErr;
			inputFlInfo: FInfo;

		function copyFork (inputFN: str255; outputFN: str255; forkType: char): OSErr;
			label
				5, 10, 15;
			const
				MaxBuff = 32000;
			var
				myParamBlk: paramBlockRec;
				errorCode, holdErr: OSErr;
				filesize: longint;
				blocks: longint;
				blkIndex: longint;
				bytes: longint;
				DataBuffer: ptr;
				inRefNum, outRefNum: integer;
		begin
			with myParamBlk do
			begin
				ioCompletion := nil;			{ no follow-on routine				}
				ioNamePtr := @inputFN;	{ pointer to path:file name	}
				ioVRefNum := 0;					{ dummy volume number		}
				ioVersNum := 0;					{ version always = 0				}
				ioPermssn := fsRdPerm;	{ request read-only					}
				ioMisc := nil;						{ use volume i/o buffer			}
			end; {with}

			case forkType of			{open input file, whichever fork we need}
				'd': 
					errorCode := PBOpen(@myParamBlk, false);		{ data fork }
				'r': 
					errorCode := PBOpenRF(@myParamBlk, false);	{ resource fork }
			end;

			if errorCode <> noErr then
				goto 5		{ some problem opening the file, bail out now }
			else
				inRefNum := myParamBlk.ioRefNum;	{ success so far, remember the file's refNum }

			{ set up a buffer for data transfer from the source to the destination }
			dataBuffer := NewPtr(MaxBuff);
			errorCode := MemError;
			if errorCode <> noErr then
				goto 10;

			case forkType of			{open output file, whichever fork we need}
				'd': 		{ data fork }
					errorCode := FSOpen(outputFN, 0, outRefNum);
				'r': 		{ resource fork }
					errorCode := OpenRF(outputFN, 0, outRefNum);
			end;
			if errorCode <> noErr then
				goto 15;

			{ make sure we are pointing at the end of the file so as not to overwrite anything already here, }
			{  ie. the other fork }
			errorCode := SetFPos(outRefNum, fsFromStart, maxInt);
			if (errorCode <> noErr) and (errorCode <> eofErr) then
				goto 15;

			{ find the size of the input file }
			errorCode := GetEOF(inRefNum, filesize);
			if (errorCode <> noErr) or (filesize <= 0) then
				goto 15;

			{ allocate as much disk space as we need for this fork }
			errorCode := Allocate(outRefNum, fileSize);
			if errorCode <> noErr then
				goto 15;

			{ now do the actual copy, one chunk at a time to keep our memory requirements down }
			blocks := (fileSize + MaxBuff - 1) div MaxBuff;
			bytes := MaxBuff;		{ our xfer buffer size }
			for blkIndex := 1 to blocks do
			begin
				errorCode := FSRead(inRefNum, bytes, dataBuffer);		{ read a chunk… }
				if (errorCode <> noErr) and (errorCode <> eofErr) then
					goto 15;		{ fail with any error other than 'end of file' }

				errorCode := FSWrite(outRefNum, bytes, dataBuffer);		{ and write it }
				if errorCode <> noErr then
					goto 15
			end; { looping throught the input file }

15:
			holdErr := FSClose(outRefNum);	{ close the new file					}
10:
			disposPtr(dataBuffer);						{ throw out the xfer buffer	}
5:
			holdErr := FSClose(inRefNum);		{ close the source file				}
			copyFork := errorCode;						{ report any errors 				}
		end;	{copyFork}

	begin	{copy1File}
		errorCode := GetFInfo(inputPath, 0, inputFlInfo);
		if errorCode <> noErr then
			goto 5;

		errorCode := Create(outputPath, 0, inputFlInfo.fdCreator, inputFlInfo.fdType);
		if errorCode <> noErr then
			goto 5;

		inputFlInfo.fdLocation := Point($00000000);
		inputFlInfo.fdFldr := 0;
		inputFlInfo.fdFlags := BAND(inputFlInfo.fdFlags, $F8FE); {mask out desktop,inited,changed,busy}
		errorCode := SetFInfo(outputPath, 0, inputFlInfo);
		if errorCode <> noErr then
			goto 5;

		errorCode := copyFork(inputPath, outputPath, 'd');
		if errorCode <> noErr then
		begin
			ignore := FSDelete(outputPath, 0);
			goto 5;
		end;

		errorCode := copyFork(inputPath, outputPath, 'r');
		if errorCode <> noErr then
		begin
			ignore := FSDelete(outputPath, 0);
			goto 5;
		end;

5:
		copy1File := errorCode;
	end;		{copy1File}


	procedure DoCapsName;
		var
			i: integer;
			inWord: boolean;
			key: char;
			tempString: str255;
	begin
		tempString := doName;
		inWord := false;
		i := 0;
		repeat
			i := i + 1;
			if (tempString[i] < 'A') or (tempString[i] > 'Z') then
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

	function FidoNetAccount (toBeParsed: str255): boolean;
		var
			tempbool: boolean;
			tempint: integer;
			t1: str255;
	begin
		with curglobs^ do
		begin
			tempBool := false;
			if Mailer^^.MailerAware then
			begin
				tempint := pos(', ', toBeParsed);
				if tempint > 2 then
				begin
					t1 := copy(toBeParsed, 1, tempint - 1);
					delete(toBeParsed, 1, tempint + 1);
					if (length(toBeParsed) >= 3) and (length(toBeParsed) < 16) then
					begin
						if pos('/', tobeParsed) > 1 then
						begin
							doCapsName(t1);
							myFido.name := t1;
							myFido.atNode := toBeParsed;
							tempBool := true;
						end;
					end;
				end;
			end;
		end;
		fidoNetAccount := tempbool;
	end;

	procedure OutLine (goingOut: str255; NLatBegin: boolean; typeLine: integer);
	external;

	function InternetAccount (toBeParsed: str255): boolean;
		var
			tempbool: boolean;
			tempint, i: integer;
			ts: str255;
	begin
		with curglobs^ do
		begin
			tempBool := false;
			if (Mailer^^.MailerAware) and ((Mailer^^.InternetMail = FidoGated) or (Mailer^^.InternetMail = Direct)) then
			begin
				if (length(toBeParsed) > 5) then
				begin
					tempint := pos('@', toBeParsed);
					if tempint > 1 then
					begin
						ts := copy(toBeParsed, tempint, length(toBeParsed) - tempInt);
						if pos('.', ts) <> 0 then
						begin
							myFido.name := toBeParsed;
							myFido.atNode := '-100';
							tempBool := true;
						end;
					end;
				end;
			end;
		end;
		InternetAccount := tempbool;
	end;

	procedure KillXFerRec;
		var
			i: integer;
	begin
		with curglobs^ do
		begin
			if extTrans <> nil then
			begin
				if extTrans^^.fileCount > 0 then
				begin
					for i := 1 to extTrans^^.fileCount do
					begin
						if extTrans^^.fPaths[i].fName <> nil then
							DisposHandle(handle(extTrans^^.fPaths[i].fName));
						if extTrans^^.fPaths[i].mbName <> nil then
							DisposHandle(handle(extTrans^^.fPaths[i].mbName));
					end;
				end;
				HUnlock(handle(extTrans));
				HPurge(handle(extTrans));
				DisposHandle(handle(extTrans));
				extTrans := nil;
			end;
		end;
	end;


	procedure InitXFerRec;
	begin
		with curglobs^ do
		begin
			if extTrans <> nil then
				KillXFERRec;
			ExtTrans := XFERStuffHand(NewHandle(SizeOf(XFERStuff)));
			MoveHHi(handle(extTrans));
			HLock(handle(extTrans));
			HNoPurge(handle(ExtTrans));
			with extTrans^^ do
			begin
				if (nodeType = 3) then
				begin
					modemInput := ippDrvrRefNum;
					errorReason := StringHandle(nodeTCP.tcpStreamPtr);
					flags[usingTCP] := true;
				end
				else if (nodeType = 2) then
				begin
					modemInput := dspDrvrRefNum;
					modemOutput := nodeCCBRefNum;
					flags[usingADSP] := true;
				end
				else
				begin
					modemInput := inputRef;
					modemOutput := outputRef;
					flags[usingADSP] := false
				end;
				procID := theProts^^.prots[activeProtocol].resID;
				protocolData := nil;
				if (nodeType <> 3) then
					errorReason := nil;
				timeOut := InitSystHand^^.ProtocolTime;
				fileCount := 0;
				filesDone := 0;
				curBytesDone := 0;
				CurBytesTotal := 0;
				curStartTime := 0;
				if (BoardMode = User) then
					flags[transMode] := true
				else
					flags[transMode] := false;
				flags[stoptrans] := false;
				flags[carrierloss] := false;
				flags[usemacbinary] := true;
				flags[newMBName] := false;
				flags[newError] := false;
				flags[newfile] := false;
				flags[recovering] := false;
				fPaths[1].fName := nil;
				fPaths[1].mbName := nil;
			end;
		end;
	end;

	function ConOpt2Num (key: char): integer;
		const
			theOptionKeys = '¡™£¢∞§¶•ªº';
		var
			i: integer;
	begin
		for i := 1 to 10 do
			if (key = theOptionKeys[i]) then
			begin
				conopt2num := i;
				exit(conopt2num);
			end;
		conopt2num := 0;
	end;

	procedure ConOpt2Con (var key: char);
		const
			theOptionKeys = 'å∫ç∂´ƒ©˙ˆ∆˚¬µ˜øπœ®ß†¨√∑≈¥Ω';
			capsOptionKeys = 'ÅıÇÎ´Ï©ÓˆÔ˚ÒÂ˜Ø∏Œ®Í†¨√∑≈ÁΩ';
		var
			i: integer;
	begin
		i := length(theoptionkeys);
		for i := 1 to 26 do
			if (key = theOptionKeys[i]) or (key = capsOptionKeys[i]) then
			begin
				key := char(i);
				exit(conopt2con);
			end;
		key := ' ';
	end;

	procedure AnalyzeProtocols;
		var
			i, curID, subCount, b, sfPos, c, index: integer;
			pHand: handle;
			SF: protocolo;
			SFP: ProcSubPtr;
			sCount: integer;
			thePtr: Ptr;
			flagPtr: IntPtrType;
	begin
		TheProts := ProtocolsHand(NewHandle(4));
		HNoPurge(handle(theprots));
		theProts^^.numProtocols := 0;
		i := 0;
		while (i < 10) do
		begin
			curID := i * 100 + 1000;
			pHand := GetResource('PInf', curID);
			if pHand <> nil then
			begin
				sfPos := 2;
				BlockMove(pointer(pHand^), @subCount, 2);
				for b := 1 to subCount do
				begin
					index := b;
					theProts^^.numprotocols := theProts^^.numProtocols + 1;
					SetHandleSize(handle(theProts), GetHandleSize(handle(theProts)) + SizeOf(protocolo));
					SFP := @SF;
					flagPtr := IntPtrType(@SFP^.pFlags);
					flagPtr^ := 0;
					SFP^.refCon := 0;
					SFP^.protoName := '';
					thePtr := pHand^;
					sCount := IntPtrType(thePtr)^;
					if (sCount > 0) and (sCount >= index) then
					begin
						thePtr := Ptr(ord4(thePtr) + 2);
						while index <> 1 do
						begin
							thePtr := Ptr(ord4(thePtr) + 6);
							thePtr := Ptr(ord4(thePtr) + thePtr^ + 2 - BAND(thePtr^, 1));
							thePtr := Ptr(ord4(thePtr) + thePtr^ + 2 - BAND(thePtr^, 1));
							index := index - 1;
						end;
						flagPtr^ := IntPtrType(thePtr)^;
						thePtr := Ptr(ord4(thePtr) + 2);
						SFP^.refCon := LongPtrType(thePtr)^;
						thePtr := Ptr(ord4(thePtr) + 4);
						SFP^.protoName := Str255PtrType(thePtr)^;
						thePtr := Ptr(ord4(thePtr) + thePtr^ + 2 - BAND(thePtr^, 1));
						SFP^.autoCom := Str255PtrType(thePtr)^;
						SFP^.protHand := nil;
						SFP^.protMode := 0;
						SFP^.resID := curID;
					end;
					theProts^^.prots[theProts^^.numprotocols] := SF;
				end;
				ReleaseResource(handle(pHand));
			end;
			i := i + 1;
		end;
		MoveHHi(handle(theProts));
	end;

	function MyGetAppHook (item: integer; dPtr: DialogPtr): integer;

		const
			{ Equates for the items that I've added }
			getDirButton = 11;
			getDirNowButton = 12;
			getDirMessage = 13;

		var
			messageTitle: str255;
			h: Handle;
			kind: integer;
			r: rect;

	begin
		{ By default, return the item passed to us. }
		MyGetAppHook := item;

		case item of
			-1: 
			begin
				SetTextBox(dPtr, getDirMessage, globalStr);
				CurDirValid := FALSE;
			end;
			getDirButton: 
			begin
				if LONGINT(replySF.fType) <> 0 then
				begin
					MyCurDir := LONGINT(replySF.fType);
					myGetAppHook := getCancel;
					CurDirValid := TRUE;
				end;
			end;
			getDirNowButton: 
			begin
				MyCurDir := CurDirStore^;
				MyGetAppHook := getCancel;
				CurDirValid := TRUE;
			end;
		end;
	end;

	function MyGetDirHook (item: integer; dPtr: DialogPtr): integer;

		const
			{ Equates for the items that I've added }
			getDirButton = 11;
			getDirNowButton = 12;
			getDirMessage = 13;

		var
			messageTitle: str255;
			h: Handle;
			kind: integer;
			r: rect;

	begin
		{ By default, return the item passed to us. }
		MyGetDirHook := item;

		case item of
			-1: 
			begin
				SetTextBox(dPtr, getDirMessage, globalStr);
				CurDirValid := FALSE;
			end;
			getDirButton: 
			begin
				if LONGINT(replySF.fType) <> 0 then
				begin
					MyCurDir := LONGINT(replySF.fType);
					myGetDirHook := getCancel;
					CurDirValid := TRUE;
				end;
			end;
			getDirNowButton: 
			begin
				MyCurDir := CurDirStore^;
				myGetDirHook := getCancel;
				CurDirValid := TRUE;
			end;
		end;
	end;


	function FoldersOnly (p: ParmBlkPtr): BOOLEAN;

	{ Normally, folders are ALWAYS shown, and aren't even passed to				}
	{ this file filter for judgement. Under such circumstances, it is			}
	{ only necessary to blindly return TRUE (allow no files whatsoever).	}
	{ However, Standard File is not documented in such a manner, and			}
	{ this feature may not be TRUE in the future. Therefore, we DO check	}
	{ to see if the entry passed to us describes a file or a directory.		}

	begin
		FoldersOnly := TRUE;
		if BTst(p^.ioFlAttrib, 4) then
			FoldersOnly := FALSE;
	end;

	function doGetDirectory: str255;
		var
			typeList: SFTypeList;
	begin
		SFPGetFile(Point($00400040), 'Space for Rent', @FoldersOnly, -1, typeList, @MyGetDirHook, replySF, 4002, nil);	{location}
		if CurDirValid then
		begin
			doGetDirectory := PathnameFromDirID(MyCurDir, -(SFSaveDisk^));
		end
		else
			doGetDirectory := '';
	end;

	function doGetApplication: str255;
		var
			typeList: SFTypeList;
			tstring: Str255;
	begin
		typeList[0] := 'APPL';
		SFGetFile(Point($00400040), 'Space for Rent', nil, 1, typeList, nil, replySF);	{location}
		if replysf.good then
			doGetApplication := concat(PathNamefromWD(replySF.vRefNum), replySF.fname)
		else
			doGetApplication := '';
	end;

	procedure GetInOutNames (deviName: str255; var inName, outName: str255);
		var
			theCRM: CRMRecPtr;
			theCRMRec: CRMRec;
			TheErr: CRMErr;
			therow: integer;
			theSerial: CRMSerialPtr;
			Old, i: integer;
	begin
		theErr := 0;
		old := 0;
		while (theErr = noErr) do
		begin
			with theCRMRec do
			begin
				crmDeviceType := crmSerialDevice;
				crmDeviceID := old;
			end;
			theCRM := @theCRMrec;
			theCRM := CRMRecPtr(CRMSearch(QElemPtr(theCRM)));
			if theCRM <> nil then
			begin
				theSerial := CRMSerialPtr(theCRM^.crmAttributes);
				old := theCRM^.crmdeviceID;
				with theSerial^ do
				begin
					if name^^ = deviName then
					begin
						inName := inputDriverName^^;
						Outname := outputDriverName^^;
					end;
				end;
			end
			else
			begin
				theErr := 1;
			end;
		end;
	end;

	procedure EraseBuffer (theBuf: scrnKeysPtr; numLines: integer);
		var
			i, b: integer;
	begin
		for i := 0 to (numLines - 1) do
		begin
			for b := 0 to 79 do
				theBuf^[i][b] := char(32);
		end;
	end;

	procedure CloseNodePrefs;
		type
			stuffLDEF = record
					oldIC: array[0..31] of LONGINT;
					oldMk: array[0..31] of LONGINT;
					name: str255;
				end;
		var
			tempString, t1: str255;
			tempCell: cell;
			TempData: ptr;
			TempLen: integer;
			tempLong: longInt;
			savePort: windowPtr;
			tempRect: rect;
			DType, i, NodesRes: Integer;
			DItem: Handle;
			CItem, CTempItem: controlhandle;
			stuffer: stuffLDEF;
	begin
		if (nodeDilg <> nil) then
		begin
			with theNodes[visibleNode]^ do
			begin
				tempCell.h := 0;
				tempCell.v := 0;
				if LGetSelect(true, tempCell, modDrivList) then
				begin
					tempLen := 40;
					LGetCell(@tempString[1], TempLen, tempCell, modDrivList);
					tempString[0] := char(TempLen);
					mDriverName := TempString;
					theNodes[activeNode]^.modemID := tempCell.v;
				end;
				GetDItem(NodeDilg, 5, DType, DItem, tempRect);
				CItem := Pointer(DItem);
				MaxBaud := GetCtlValue(CItem);
				if buflns <> NodeHnd^^.BufferLines then
				begin
					DisposPtr(ptr(gBBSwindows[visibleNode]^.bigBuffer));
					gBBSwindows[visibleNode]^.sNumLines := buflns;
					gBBSwindows[visibleNode]^.bigBuffer := scrnKeysPtr(NewPtr(SizeOf(aLine) * gBBSwindows[visibleNode]^.sNumLines));
					if gBBSwindows[visibleNode]^.bigBuffer <> nil then
						EraseBuffer(gBBSwindows[visibleNode]^.bigBuffer, gBBSwindows[visibleNode]^.sNumLines);
					if gBBSwindows[visibleNode]^.ansiPort <> nil then
					begin
						SetCtlMax(gBBSwindows[visibleNode]^.ansiVScroll, gBBSwindows[visibleNode]^.sNumLines + gBBSwindows[visibleNode]^.scrnTop);
						SetCtlValue(gBBSwindows[visibleNode]^.ansiVScroll, gBBSwindows[visibleNode]^.sNumLines + gBBSwindows[visibleNode]^.scrnTop);
					end;
				end;
				GetDItem(NodeDilg, 6, DType, DItem, tempRect);
				CItem := Pointer(DItem);
				MinBaud := GetCtlValue(CItem);
				NodeName := GetTextBox(NodeDilg, 38);
				t1 := GetTextBox(NodeDilg, 53);
				if (length(t1) > 0) and ((t1[1] >= 'A') and (t1[1] <= 'Z')) then
					NodeRest := t1[1]
				else
					NodeRest := char(0);
				NodesRes := OpenRFPerm(concat(SharedFiles, 'Nodes'), 0, fsRdWrPerm);
				NodeHnd := NodeHand(GetResource('Node', visibleNode - 1));
				HNoPurge(handle(NodeHnd));
				GetDItem(NodeDilg, 57, DType, DItem, tempRect);
				CItem := Pointer(DItem);
				NewSL := GetSecurity(GetCtlValue(CItem));
				nodeHnd^^.DTRHangup := useDTR;
				nodeHnd^^.BufferLines := bufLns;
				NodeHnd^^.BaudMax := MaxBaud;
				NodeHnd^^.BaudMin := MinBaud;
				nodeHnd^^.timeoutIn := timeout;
				nodeHnd^^.hardShake := HWHH;
				NodeHnd^^.ModDrivName := MDriverName;
				nodeHnd^^.carDet := carrierDetect;
				nodeHnd^^.rings := Rings;
				nodeHnd^^.NodeName := NodeName;
				nodeHnd^^.SecLevel := SecLevel;
				nodeHnd^^.NodeRest := NodeRest;
				nodeHnd^^.WelcomeAlternate := WelcomeAlternate;
				nodeHnd^^.NewSL := NewSL;
				tempCell.h := 0;
				tempCell.v := 0;
				if LGetSelect(true, tempCell, ListPorts) then
				begin
					TempLen := 512;
					LGetCell(@stuffer, tempLen, tempCell, ListPorts);
					tempString := stuffer.name;
					NodeHnd^^.myInPort := 'None';
					NodeHnd^^.myOutPort := 'None';
					if (tempString = TCPNAME) then
					begin
						theNodes[activeNode]^.inPortName := TCPNAME;
						NodeHnd^^.myinPort := TCPNAME;
						NodeHnd^^.myOutPort := TCPNAME;
					end
					else if (tempString = ADSPNAME) then
					begin
						theNodes[activeNode]^.inPortName := ADSPNAME;
						NodeHnd^^.myinPort := ADSPNAME;
						NodeHnd^^.myOutPort := ADSPNAME;
					end
					else
					begin
						GetInOutNames(tempString, NodeHnd^^.myinPort, NodeHnd^^.myoutPort);
						theNodes[activeNode]^.inPortName := NodeHnd^^.myInPort;
						theNodes[activeNode]^.outPortName := nodeHnd^^.myOutPort;
					end;
				end;
				nodeHnd^^.localHook := goOffInLocal;
				nodeHnd^^.matchSpeed := matchInterface;
				nodehnd^^.uptime := uptime;
				nodehnd^^.downtime := downtime;
				nodehnd^^.sysOpNode := SysOpNode;
				ChangedResource(handle(NodeHnd));
				WriteResource(handle(NodeHnd));
				CloseResFile(NodesRes);
				UseResFile(myResourceFile);
				HPurge(handle(NodeHnd));
				LDispose(listPorts);
				LDispose(modDrivList);
				DisposDialog(nodeDilg);
				NodeDilg := nil;
				GetPort(savePort);
				CloseComPort;
				OpenComPort;
				if nodeType = 1 then
					EnableItem(getMHandle(mSysop), 14)
				else
					DisableItem(getMHandle(mSysop), 14);
				with curglobs^ do
				begin
					if (boardMode = Waiting) then
						lastTry := lastTry - 80000;
				end;
				SetPort(savePort);
			end;
		end;
	end;

	procedure UpDateNodePrefs;
		var
			SavePort: WindowPtr;
			sTemp: Str255;
			tempHandle: handle;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
			CItem, CTempItem: controlhandle;
	begin
		if (nodeDilg <> nil) then
		begin
			GetPort(SavePort);
			SetPort(nodeDilg);

					{Update a List, Connection Types }
			GetDItem(NodeDilg, 10, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (modDrivList <> nil) then
				LUpdate(nodeDilg^.visRgn, modDrivList);

			GetDItem(NodeDilg, 3, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (ListPorts <> nil) then
				LUpdate(nodeDilg^.visRgn, ListPorts);

			FrameIt(NodeDilg, 46);
			FrameIt(NodeDilg, 45);

			DrawDialog(nodeDilg);
			SetPort(SavePort);
		end;
	end;

	procedure OpenNodePrefs;
		var
			Index, NumSTRRes, dyke, TempSndID: Integer;
			dataBounds, tempRect: Rect;
			cSize: Point;
			STRname, sTemp: str255;
			TempHand: handle;
			WhicTyp: ResType;
			theDialogPtr: DialogPeek;
			DType, i, hm, wid, wm: Integer;
			DItem: Handle;
			CItem, CTempItem: controlhandle;
			tempLong: longint;
			myPop: popupHand;

		procedure AddListString (theString: Str255; theList: ListHandle);
			var
				theRow: integer;
				sTemp: str255;
		begin
			if (theList <> nil) then
			begin
				cSize.h := 0;
				theRow := LAddRow(1, 200, theList);
				cSize.v := theRow;
				sTemp := theString;
				if sTemp = theNodes[activeNode]^.mDriverName then
					selectThis := cSize;
				LSetCell(Pointer(ord(@sTemp) + 1), length(sTemp), cSize, theList);
			end;
		end;

		procedure InsertSerialPorts;
			type
				stuffLDEF = record
						oldIC: array[0..31] of LONGINT;
						oldMk: array[0..31] of LONGINT;
						name: str255;
					end;
			var
				theCRM: CRMRecPtr;
				theCRMRec: CRMRec;
				TheErr: CRMErr;
				therow: integer;
				theSerial: CRMSerialPtr;
				Old, i: integer;
				stuffer: stuffLDEF;
				myHandle: handle;
		begin
			theErr := 0;
			old := 0;
			while (theErr = noErr) do
			begin
				with theCRMRec do
				begin
					crmDeviceType := crmSerialDevice;
					crmDeviceID := old;
				end;
				theCRM := @theCRMrec;
				theCRM := CRMRecPtr(CRMSearch(QElemPtr(theCRM)));
				if theCRM <> nil then
				begin
					theSerial := CRMSerialPtr(theCRM^.crmAttributes);
					old := theCRM^.crmdeviceID;
					with theSerial^ do
					begin
						stemp := name^^;
						stuffer.name := sTemp;
						BlockMove(pointer(deviceIcon^), @stuffer, 256);
						cSize.h := 0;
						theRow := LAddRow(1, 200, listports);
						cSize.v := theRow;
						if inputdrivername^^ = theNodes[activeNode]^.inportname then
							SelectThis := cSize;
						LSetCell(@stuffer, 257 + length(sTemp), cSize, listports);
					end;
				end
				else
				begin
					theErr := 1;
				end;
			end;
			if adspSupported then
			begin
				cSize.h := 0;
				theRow := LAddRow(1, 200, listports);
				cSize.v := theRow;
				stemp := ADSPNAME;
				if sTemp = theNodes[activeNode]^.inportname then
					selectThis := cSize;
				myHandle := GetResource('ICN#', 6003);
				HLock(myHandle);
				BlockMove(pointer(myHandle^), @stuffer, 256);
				HUnlock(myHandle);
				ReleaseResource(myHandle);
				stuffer.name := sTemp;
				LSetCell(pointer(@stuffer), 257 + length(sTemp), cSize, listports);
			end;
			if tcpSupported then
			begin
				cSize.h := 0;
				theRow := LAddRow(1, 200, listports);
				cSize.v := theRow;
				stemp := TCPNAME;
				if sTemp = theNodes[activeNode]^.inportname then
					selectThis := cSize;
				myHandle := GetResource('ICN#', 6004);
				HLock(myHandle);
				BlockMove(pointer(myHandle^), @stuffer, 256);
				HUnlock(myHandle);
				ReleaseResource(myHandle);
				stuffer.name := sTemp;
				LSetCell(pointer(@stuffer), 257 + length(sTemp), cSize, listports);
			end;
			cSize.h := 0;
			theRow := LAddRow(1, 200, listports);
			cSize.v := theRow;
			stemp := 'None';
			if sTemp = theNodes[activeNode]^.inportname then
				selectThis := cSize;
			myHandle := GetResource('ICN#', 6002);
			HLock(myHandle);
			BlockMove(pointer(myHandle^), @stuffer, 256);
			HUnlock(myHandle);
			ReleaseResource(myHandle);
			stuffer.name := sTemp;
			LSetCell(pointer(@stuffer), 261, cSize, listports);
		end;

	begin
		if (nodeDilg = nil) then
		begin
			nodeDilg := GetNewDialog(745, nil, Pointer(-1));
			SetPort(nodeDilg);
			SetWTitle(nodeDilg, StringOf('Node ', visibleNode : 0));
			SetGeneva(nodeDilg);

			GetDItem(NodeDilg, 5, DType, DItem, tempRect);
			CItem := Pointer(DItem);
			SetCtlValue(citem, curglobs^.maxBaud);

			GetDItem(NodeDilg, 6, DType, DItem, tempRect);
			CItem := Pointer(DItem);
			SetCtlValue(citem, curglobs^.minbaud);

			GetDItem(NodeDilg, 10, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			cSize.h := tempRect.Right - tempRect.Left;
			cSize.v := 12;
			modDrivList := LNew(tempRect, dataBounds, cSize, 0, nodeDilg, false, FALSE, FALSE, TRUE);
			modDrivList^^.selFlags := lOnlyOne + lNoNilHilite;
			HLock(handle(modDrivList));
			if numModemDrivers > 0 then
				for i := 1 to numModemDrivers do
				begin
					AddListString(modemDrivers^^[i - 1].name, modDrivList);
				end;
			LSetSelect(true, selectThis, modDrivList);
			LDoDraw(true, modDrivList);

					{Make a List, Connection Types }
			GetDItem(NodeDilg, 3, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			cSize.h := tempRect.Right - tempRect.Left;
			cSize.v := 52;
			ListPorts := LNew(tempRect, dataBounds, cSize, 10000, nodeDilg, TRUE, FALSE, FALSE, TRUE);
			ListPorts^^.selFlags := lOnlyOne + lNoNilHilite;
			HLock(handle(ListPorts));
			cSize.h := 0;
			cSize.v := 0;
			InsertSerialPorts;
			LSetSelect(TRUE, SelectThis, listports);

			SetTextBox(NodeDilg, 7, stringOf(theNodes[visibleNode]^.timeout : 0));

			SetTextBox(NodeDilg, 17, stringOf(theNodes[visibleNode]^.bufLns : 0));

			SetCheckBox(NodeDilg, 2, theNodes[visibleNode]^.goOffinLocal);

			SetCheckBox(NodeDilg, 24, theNodes[visibleNode]^.SysOpNode);

			SetTextBox(NodeDilg, 48, stringof(theNodes[visibleNode]^.SecLevel : 0));

			SetTextBox(NodeDilg, 4, DrawTime(theNodes[visibleNode]^.uptime));
			SetTextBox(NodeDilg, 13, DrawTime(theNodes[visibleNode]^.downtime));
			SetTextBox(NodeDilg, 38, theNodes[visibleNode]^.NodeName);
			SetTextBox(NodeDilg, 40, stringOf(theNodes[visibleNode]^.rings : 0));

			if theNodes[visibleNode]^.NodeRest <> char(0) then
				SetTextBox(NodeDilg, 53, theNodes[visibleNode]^.NodeRest);

			FrameIt(NodeDilg, 46);
			FrameIt(NodeDilg, 45);

			GetDItem(NodeDilg, 57, DType, DItem, tempRect);
			Citem := Pointer(DItem);
			myPop := popupHand(Citem^^.contrlData);
			wid := CountMItems(myPop^^.mHandle);
			for i := wid downto 1 do
			begin
				DelMenuItem(myPop^^.mHandle, i);
			end;
			hm := 0;
			for i := 1 to 255 do
			begin
				if SecLevels^^[i].active then
				begin
					hm := hm + 1;
					AppendMenu(myPop^^.mHandle, SecLevels^^[i].Class);
					if i = theNodes[visibleNode]^.NewSL then
						wm := hm;
				end;
			end;
			SetCtlValue(Citem, wm);
			InsertMenu(myPop^^.mHandle, -1);

			if theNodes[visibleNode]^.WelcomeAlternate then
				SetCheckBox(nodeDilg, 56, true)
			else
				SetCheckBox(nodeDilg, 55, true);

			if theNodes[visibleNode]^.MatchInterface then
				SetCheckBox(NodeDilg, 18, true)
			else if theNodes[visibleNode]^.HWHH then
				SetCheckBox(NodeDilg, 15, true)
			else if (not theNodes[visibleNode]^.HWHH) and (not theNodes[visibleNode]^.MatchInterface) then
				SetCheckBox(NodeDilg, 14, true);

			if theNodes[visibleNode]^.carrierDetect = DCDdriver then
				SetCheckBox(NodeDilg, 20, true);

			LAutoScroll(listPorts);
			LAutoScroll(modDrivList);
			ShowWindow(nodeDilg);
			SelectWindow(NodeDilg);
		end
		else
			SelectWindow(nodeDilg);
	end;

{$S NodePrefs_2}
	procedure ClickInNodePrefs (theEvent: EventRecord; itemHit: integer);
		var
			RefCon: longint;
			code, tempInt, mdm: integer;
			theValue: integer;
			whichWindow: WindowPtr;
			myPt: Point;
			MyErr: OSErr;
			DoubleClick: boolean;
			tempRect: rect;
			DType, i: Integer;
			newDriver: ModemDriverHand;
			DItem: Handle;
			CItem, CTempItem: controlhandle;
			tempCell, tc2: cell;
			t1: str255;
			reply: SFReply;
			adder, adder3: integer;
			QuestionDlg: dialogPtr;
	begin
		if (NodeDilg <> nil) and (frontWindow = NodeDilg) then
		begin
			setPort(nodeDilg);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			adder := 10;
			adder3 := 3600;
			if optiondown then
			begin
				adder := 1;
				adder3 := 60;
			end;
			case itemHit of
				1: 
					CloseNodePrefs;
				41, 42: 
				begin
					adder := 1;
					if (itemHit = 41) then
						adder := -1;
					theNodes[visibleNode]^.rings := UpDown(NodeDilg, 40, theNodes[visibleNode]^.rings, Adder, 9, 1);
				end;
				55, 56: 
				begin
					SetCheckBox(NodeDilg, 55, False);
					SetCheckBox(NodeDilg, 56, False);
					if theNodes[visibleNode]^.WelcomeAlternate then
					begin
						theNodes[visibleNode]^.WelcomeAlternate := false;
						SetCheckBox(NodeDilg, 55, True);
					end
					else
					begin
						theNodes[visibleNode]^.WelcomeAlternate := true;
						SetCheckBox(NodeDilg, 56, True);
					end;
				end;
				32: 
				begin
					if ((theNodes[visibleNode]^.uptime + adder3) < 86400) then
					begin
						theNodes[visibleNode]^.uptime := theNodes[visibleNode]^.uptime + adder3
					end
					else
						theNodes[visibleNode]^.uptime := (theNodes[visibleNode]^.uptime + adder3) - 86400;
					SetTextBox(NodeDilg, 4, DrawTime(theNodes[visibleNode]^.uptime));
				end;
				31: 
				begin
					if ((theNodes[visibleNode]^.uptime - adder3) > 0) then
					begin
						theNodes[visibleNode]^.uptime := theNodes[visibleNode]^.uptime - adder3
					end
					else
						theNodes[visibleNode]^.uptime := (theNodes[visibleNode]^.uptime - adder3) + 86400;
					SetTextBox(NodeDilg, 4, DrawTime(theNodes[visibleNode]^.uptime));
				end;
				35: 
				begin
					if ((theNodes[visibleNode]^.downtime + adder3) < 86400) then
					begin
						theNodes[visibleNode]^.downtime := theNodes[visibleNode]^.downtime + adder3
					end
					else
						theNodes[visibleNode]^.downtime := (theNodes[visibleNode]^.downtime + adder3) - 86400;
					SetTextBox(NodeDilg, 13, DrawTime(theNodes[visibleNode]^.downtime));
				end;
				34: 
				begin
					if ((theNodes[visibleNode]^.downtime - adder3) > 0) then
					begin
						theNodes[visibleNode]^.downtime := theNodes[visibleNode]^.downtime - adder3
					end
					else
						theNodes[visibleNode]^.downtime := (theNodes[visibleNode]^.downtime - adder3) + 86400;
					SetTextBox(NodeDilg, 13, DrawTime(theNodes[visibleNode]^.downtime));
				end;
				5: 
				begin
					GetDItem(NodeDilg, 6, DType, DItem, tempRect);
					CItem := Pointer(DItem);
					tempInt := GetCtlValue(CItem);
					GetDItem(NodeDilg, 5, DType, DItem, tempRect);
					CItem := Pointer(DItem);
					code := GetCtlValue(CItem);
					if code < tempInt then
					begin
						SysBeep(10);
						SetCtlValue(Citem, tempInt);
					end;
				end;
				6: 
				begin
					GetDItem(NodeDilg, 5, DType, DItem, tempRect);
					CItem := Pointer(DItem);
					code := GetCtlValue(CItem);
					GetDItem(NodeDilg, 6, DType, DItem, tempRect);
					CItem := Pointer(DItem);
					tempInt := GetCtlValue(CItem);
					if tempInt > code then
					begin
						SysBeep(10);
						SetCtlValue(Citem, code);
					end;
				end;
				49, 50: 
				begin
					if (itemHit = 49) then
						adder := adder * (-1);
					theNodes[visibleNode]^.secLevel := UpDown(NodeDilg, 48, theNodes[visibleNode]^.secLevel, Adder, 255, 0);
				end;
				28, 29: 
				begin
					if (itemHit = 28) then
						adder := adder * (-1);
					theNodes[visibleNode]^.buflns := UpDown(NodeDilg, 17, theNodes[visibleNode]^.buflns, Adder, 400, 64);
				end;
				25, 26: 
				begin
					if (itemHit = 25) then
						adder := adder * (-1);
					theNodes[visibleNode]^.timeout := UpDown(NodeDilg, 7, theNodes[visibleNode]^.timeout, Adder, 900, 1);
				end;
				2: 
				begin
					if theNodes[visibleNode]^.goOffInLocal then
						theNodes[visibleNode]^.goOffInLocal := False
					else
						theNodes[visibleNode]^.goOffInLocal := True;
					SetCheckBox(NodeDilg, 2, theNodes[visibleNode]^.goOffinLocal);
				end;
				18: 
				begin
					if adder <> 1 then {Option Key is not down}
					begin
						SysBeep(0);
						QuestionDlg := GetNewDialog(179, nil, pointer(-1));
						SetPort(QuestionDlg);
						SetGeneva(QuestionDlg);
						SetTextBox(QuestionDlg, 5, 'NO FLOW CONTROL');
						ParamText('1. USE: This selection only used for 2400 baud and slower modems.', '2. CABLE: Cable ID #1 required to reset node for hangup without logoff.', '3. PORT SPEED: Serial port speed changes to modem connect speed.', '4. FLOW CONTROL: No flow control settings appended to basic modem initilization.');
						DrawDialog(QuestionDlg);
						repeat
							ModalDialog(@useModalTime, i)
						until (i = 1) or (i = 3);
						DisposDialog(QuestionDlg);
						SetPort(NodeDilg);
						if i = 1 then
						begin
							SetCheckBox(NodeDilg, 14, false);
							SetCheckBox(NodeDilg, 15, false);
							SetCheckBox(NodeDilg, 18, true);
							theNodes[visibleNode]^.MatchInterface := true;
							theNodes[visibleNode]^.useDTR := true;
							theNodes[visibleNode]^.carrierDetect := CTS5;
							theNodes[visibleNode]^.HWHH := false;
						end;
					end
					else
					begin
						SetCheckBox(NodeDilg, 14, false);
						SetCheckBox(NodeDilg, 15, false);
						SetCheckBox(NodeDilg, 18, true);
						theNodes[visibleNode]^.MatchInterface := true;
						theNodes[visibleNode]^.useDTR := true;
						theNodes[visibleNode]^.carrierDetect := CTS5;
						theNodes[visibleNode]^.HWHH := false;
					end;
				end;
				14: 
				begin
					if adder <> 1 then {Option Key is not down}
					begin
						SysBeep(0);
						QuestionDlg := GetNewDialog(179, nil, pointer(-1));
						SetPort(QuestionDlg);
						SetGeneva(QuestionDlg);
						SetTextBox(QuestionDlg, 5, 'XON/XOFF FLOW CONTROL');
						ParamText('1. USE: This selection can be used for any high speed modem.', '2. CABLE: Cable ID #1 required to reset node for hangup without logoff.', '3. PORT SPEED: Serial port speed locked at selected "Port Speed".', '4. FLOW CONTROL: XON/XOFF settings appended to basic modem initilization.');
						DrawDialog(QuestionDlg);
						repeat
							ModalDialog(@useModalTime, i)
						until (i = 1) or (i = 3);
						DisposDialog(QuestionDlg);
						SetPort(NodeDilg);
						if i = 1 then
						begin
							SetCheckBox(NodeDilg, 14, true);
							SetCheckBox(NodeDilg, 15, false);
							SetCheckBox(NodeDilg, 18, false);
							theNodes[visibleNode]^.MatchInterface := false;
							theNodes[visibleNode]^.useDTR := true;
							theNodes[visibleNode]^.carrierDetect := CTS5;
							theNodes[visibleNode]^.HWHH := false;
						end;
					end
					else
					begin
						SetCheckBox(NodeDilg, 14, true);
						SetCheckBox(NodeDilg, 15, false);
						SetCheckBox(NodeDilg, 18, false);
						theNodes[visibleNode]^.MatchInterface := false;
						theNodes[visibleNode]^.useDTR := true;
						theNodes[visibleNode]^.carrierDetect := CTS5;
						theNodes[visibleNode]^.HWHH := false;
					end;
				end;
				15: 
				begin
					if adder <> 1 then {Option Key is not down}
					begin
						SysBeep(0);
						QuestionDlg := GetNewDialog(179, nil, pointer(-1));
						SetPort(QuestionDlg);
						SetGeneva(QuestionDlg);
						SetTextBox(QuestionDlg, 5, 'HARDWARE HANDSHAKE FLOW CONTROL (RTS/CTS)');
						ParamText(concat('1. USE: This selection can only be used with high speed modems.', char(13), '    Some Mac models cannot support this selection (See Docs).'), '2. CABLE: Cable ID #3 required to reset node for hangup without logoff.', '3. PORT SPEED: Serial port speed locked at selected "Port Speed".', '4. FLOW CONTROL: Hardware handshake settings appended to basic modem initilization.');
						DrawDialog(QuestionDlg);
						repeat
							ModalDialog(@useModalTime, i)
						until (i = 1) or (i = 3);
						DisposDialog(QuestionDlg);
						SetPort(NodeDilg);
						if i = 1 then
						begin
							SetCheckBox(NodeDilg, 14, false);
							SetCheckBox(NodeDilg, 15, true);
							SetCheckBox(NodeDilg, 18, false);
							theNodes[visibleNode]^.MatchInterface := false;
							theNodes[visibleNode]^.useDTR := false;
							if GetCheckBox(NodeDilg, 20) then
								theNodes[visibleNode]^.carrierDetect := DCDdriver
							else
								theNodes[visibleNode]^.carrierDetect := DCDchip;
							theNodes[visibleNode]^.HWHH := true;
						end;
					end
					else
					begin
						SetCheckBox(NodeDilg, 14, false);
						SetCheckBox(NodeDilg, 15, true);
						SetCheckBox(NodeDilg, 18, false);
						theNodes[visibleNode]^.MatchInterface := false;
						theNodes[visibleNode]^.useDTR := false;
						if GetCheckBox(NodeDilg, 20) then
							theNodes[visibleNode]^.carrierDetect := DCDdriver
						else
							theNodes[visibleNode]^.carrierDetect := DCDchip;
						theNodes[visibleNode]^.HWHH := true;
					end;
				end;
				20: 
				begin
					if theNodes[visibleNode]^.HWHH then
					begin
						if theNodes[visibleNode]^.carrierDetect = DCDchip then
						begin
							theNodes[visibleNode]^.carrierDetect := DCDdriver;
							SetCheckBox(NodeDilg, 20, true);
						end
						else if theNodes[visibleNode]^.carrierDetect = DCDdriver then
						begin
							theNodes[visibleNode]^.carrierDetect := DCDchip;
							SetCheckBox(NodeDilg, 20, false);
						end
					end
					else
					begin
						if GetCheckBox(NodeDilg, 20) then
							SetCheckBox(NodeDilg, 20, false)
						else
							SetCheckBox(NodeDilg, 20, true);
					end;
				end;
				24: 
				begin
					if theNodes[visibleNode]^.SysOpNode then
						theNodes[visibleNode]^.SysOpNode := False
					else
						theNodes[visibleNode]^.SysOpNode := True;
					SetCheckBox(NodeDilg, 24, theNodes[visibleNode]^.SysOpNode);
				end;
				23: 
				begin
					tempCell.h := 0;
					tempCell.v := 0;
					if LGetSelect(true, tempCell, modDrivList) then
					begin
						SetPt(myPt, 50, 50);
						SFPutFile(myPt, RetInStr(568), modemDrivers^^[tempCell.v].name, nil, reply);
						if reply.good then
						begin
							result := Create(reply.fName, reply.vrefnum, 'HRMS', 'MODR');
							HCreateResFile(reply.vrefnum, 0, reply.fName);
							tempInt := HOpenResFile(reply.vrefnum, 0, reply.fName, 0);
							if (tempInt <> -1) then
							begin
								newDriver := ModemDriverHand(NewHandle(SizeOf(modemdriver)));
								HLock(handle(newDriver));
								newDriver^^ := modemDrivers^^[tempCell.v];
								AddResource(handle(newDriver), 'MoDr', 1000, newDriver^^.name);
								WriteResource(handle(newDriver));
								DetachResource(handle(newDriver));
								DisposHandle(handle(newDriver));
								CloseResFile(tempInt);
							end
							else
								SysBeep(10);
						end;
					end;
				end;
				21: 
				begin
					newDriver := ModemDriverHand(NewHandle(SizeOf(modemdriver)));
					HLock(handle(newDriver));
					newDriver^^.name := 'Name';
					newDriver^^.bbsInit := 'ATS0=0Q0V0E0M0S2=1X1';
					newDriver^^.termInit := 'ATV1E1S2=43M1S11=70';
					newDriver^^.hwOn := '';
					newDriver^^.hwOff := '';
					newDriver^^.lockOn := '';
					newDriver^^.lockOff := '';
					newDriver^^.ansModem := 'ATA';
					newDriver^^.numResults := 0;
					newDriver^^.Reset := 'AT&F';
					if EditModemDriver(newDriver^^) then
					begin
						mdm := OpenRFPerm(concat(SharedFiles, 'Modem Drivers'), 0, fsRdWrPerm);
						if (mdm = -1) then
						begin
							result := Create(concat(SharedFiles, 'Modem Drivers'), 0, 'HRMS', 'DATA');
							CreateResFile(concat(SharedFiles, 'Modem Drivers'));
							mdm := OpenResFile(concat(SharedFiles, 'Modem Drivers'));
						end;
						AddResource(handle(newDriver), 'MoDr', UniqueID('MoDr'), newDriver^^.name);
						WriteResource(handle(newDriver));
						DetachResource(handle(newDriver));
						AddListString(newDriver^^.name, modDrivList);
						SetHandleSize(handle(modemDrivers), GetHandleSize(handle(modemDrivers)) + SizeOf(modemDriver));
						modemDrivers^^[numModemDrivers] := newDriver^^;
						numModemDrivers := numModemDrivers + 1;
						CloseResFile(mdm);
					end;
					HUnlock(handle(newDriver));
					DisposHandle(handle(newDriver));
				end;
				22: 
				begin
					tempCell.h := 0;
					tempCell.v := 0;
					if LGetSelect(true, tempCell, modDrivList) then
					begin
						if (ModalQuestion(concat('Are you sure you want to delete the modem driver ''', modemDrivers^^[tempCell.v].name, '''?'), false, true) = 1) then
						begin
							mdm := OpenRFPerm(concat(SharedFiles, 'Modem Drivers'), 0, fsRdWrPerm);
							newDriver := ModemDriverHand(GetNamedResource('MoDr', modemDrivers^^[tempCell.v].name));
							RmveResource(handle(newDriver));
							if numModemDrivers > tempCell.v + 1 then
								for i := tempCell.v + 1 to numModemDrivers do
									modemDrivers^^[i - 1] := modemDrivers^^[i];
							numModemDrivers := numModemDrivers - 1;
							HPurge(handle(modemDrivers));
							HUnLock(handle(modemDrivers));
							SetHandleSize(handle(modemDrivers), GetHandleSize(handle(modemDrivers)) - SizeOf(modemDriver));
							if memerror <> 0 then
								problemRep(stringOf('Memory Error: ', memerror : 0));
							HNoPurge(handle(modemDrivers));
							LDoDraw(false, modDrivList);
							LDelRow(0, 0, modDrivList);
							if numModemDrivers > 0 then
								for i := 1 to numModemDrivers do
									AddListString(modemDrivers^^[i - 1].name, modDrivList);
							LSetSelect(true, selectThis, modDrivList);
							LDoDraw(true, modDrivList);
							GetDItem(NodeDilg, 10, DType, DItem, tempRect);
							tempRect.Right := tempRect.Right - 15;
							InsetRect(tempRect, -1, -1);
							EraseRect(tempRect);
							FrameRect(tempRect);
							LUpdate(modDrivList^^.port^.visRgn, modDrivList);
							CloseResFile(mdm);
						end;
					end;
				end;
				3: 
				begin
					tempCell := cell($00000000);
					if LGetSelect(true, tempCell, listPorts) then
						;
					DoubleClick := LClick(myPt, theEvent.modifiers, ListPorts);
					tc2 := cell($00000000);
					if not LGetSelect(true, tc2, listPorts) then
						LSetSelect(true, tempCell, listPorts);
				end;
				10: 
				begin
					DoubleClick := LClick(myPt, theEvent.modifiers, modDrivList);
					if doubleClick then
					begin
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, modDrivList) then
						begin
							t1 := modemDrivers^^[tempCell.v].name;
							if EditModemDriver(modemDrivers^^[tempCell.v]) then
							begin
								mdm := OpenRFPerm(concat(SharedFiles, 'Modem Drivers'), 0, fsRdWrPerm);
								newDriver := ModemDriverHand(GetNamedResource('MoDr', t1));
								RmveResource(handle(newDriver));
								DisposeHandle(handle(newDriver));
								newDriver := ModemDriverHand(NewHandle(SizeOf(modemdriver)));
								HLock(handle(newDriver));
								newDriver^^ := modemDrivers^^[tempCell.v];
								AddResource(handle(newDriver), 'MoDr', UniqueID('MoDr'), newDriver^^.name);
								WriteResource(handle(newDriver));
								DetachResource(handle(newDriver));
								HUnlock(handle(newDriver));
								DisposHandle(handle(newDriver));
								SetPort(nodeDilg);
								LDoDraw(false, modDrivList);
								LDelRow(0, 0, modDrivList);
								if numModemDrivers > 0 then
									for i := 1 to numModemDrivers do
										AddListString(modemDrivers^^[i - 1].name, modDrivList);
								LSetSelect(true, tempCell, modDrivList);
								LDoDraw(true, modDrivList);
								GetDItem(NodeDilg, 10, DType, DItem, tempRect);
								tempRect.Right := tempRect.Right - 15;
								InsetRect(tempRect, -1, -1);
								EraseRect(tempRect);
								FrameRect(tempRect);
								LUpdate(modDrivList^^.port^.visRgn, modDrivList);
								CloseResFile(mdm);
							end;
						end;
					end;
				end;
				otherwise
			end;
		end;
	end;
end.