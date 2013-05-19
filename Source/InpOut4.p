{ Segments: InpOut4_1 }
unit inpOut4;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, Aliases, TCPTypes, Initial, NodePrefs2, NodePrefs, SystemPrefs, User, Terminal;

	procedure OutLine (goingOut: str255; NLatBegin: boolean; typeLine: integer);
	procedure OutLineC (goingOut: str255; NLatBegin: boolean; typeLine: integer);
	procedure AnsiCode (theCode: str255);
	procedure DoM (typeL: integer);
	procedure BufferIt (goingOut: str255; NLatBegin: boolean; typeLine: integer);
	procedure ReleaseBuffer;
	procedure BufClearScreen;
	procedure bufferbcr;
	procedure bCR;
	procedure DecodeM (typeL: integer; nowStyle: CharStyle; var ts: str255);
	procedure GiveTime (tickstoGive: longint; multiplier: real; tellUser: boolean);
	procedure OutChr (theChar: char);
	procedure ClearScreen;
	procedure OutLineSysop (goingOut: str255; NLatBegin: boolean);
	procedure ReprintPrompt;
	procedure PromptUser (whichNode: integer);
	procedure LettersPrompt (prompt, accepted: str255; sizeLimit: integer; auto, wrap, capital: boolean; replace: char);
	procedure YesNoQuestion (prompt: Str255; yesIsDefault: boolean);
	procedure AnsiPrompt (prompt, accepted: str255; sizeLimit: integer; auto, wrap, capital: boolean; replace: char);
	procedure MainMenuPrompt (prompt: str255);
	procedure NewYesNoQuestion (prompt: STR255);
	procedure NumbersPrompt (prompt, accepted: STR255; high, low: longint);
	procedure PAUSEPrompt (prompt: str255);
	procedure ANSIprompter (numch: integer);
	procedure printSysopStats;
	procedure HangupAndReset;
	procedure GoWaitMode;
	procedure AnswerCall;
	procedure DoLogon (isANSI: boolean);
	procedure DoHangup;
	procedure CallUserExternal (message, whichOne: integer);
	procedure ConnectMade (serKe: char);
	procedure MultinodeOutput (whatString: str255);
	procedure SingleNodeOutput (whatString: Str255; i: integer);
	procedure ListLine (whichLine: integer);
	procedure BackSpace (howMany: integer);
	function ReadTextFile (fileName: str255; storedAs: integer; insertPath: boolean): boolean;
	procedure ListTextFile;
	procedure BroadCast (whatString: str255; color: integer);
	procedure scanfile (texthnd: TextHand);

implementation

{$S InpOut4_1}
	procedure CheckText (tofind: str255);
		var
			x, y: longint;
			orgfind, temp, replace: str255;
	begin
		orgfind := tofind;
		replace := '';
	end;

	procedure ReplaceText (tofind, toreplace: str255);
		var
			x, y: longint;
			orgfind, temp, replace: str255;
	begin
		orgfind := tofind;
		with CurGlobs^ do
			repeat
				replace := stringOf(toreplace : 0);
				x := Munger(handle(texthnd), 0, Pointer(Ord(@orgfind) + 1), length(orgfind), nil, 0);
				if (x < 0) then
					exit(ReplaceText);
				if (texthnd^^[x + length(orgfind)] = '<') then
				begin
					temp := concat(textHnd^^[x + length(orgfind) + 1], textHnd^^[x + length(orgfind) + 2]);
					StringToNum(temp, y);
					if length(toreplace) > y then
						delete(toreplace, 1, y);
					replace := StringOf(' ' : y - length(replace), replace);
					tofind := StringOf(orgfind, '<', temp);
					x := Munger(handle(texthnd), 0, Pointer(Ord(@tofind) + 1), length(tofind), Pointer(Ord(@replace) + 1), length(replace));
				end
				else if (texthnd^^[x + length(orgfind)] = '>') then
				begin
					temp := concat(textHnd^^[x + length(orgfind) + 1], textHnd^^[x + length(orgfind) + 2]);
					StringToNum(temp, y);
					if length(toreplace) > y then
						delete(toreplace, 1, y);
					replace := stringOf(toreplace : 0, ' ' : y - length(toReplace));
					tofind := StringOf(orgfind, '>', temp);
					x := Munger(handle(texthnd), 0, Pointer(Ord(@tofind) + 1), length(tofind), Pointer(Ord(@replace) + 1), length(replace));
				end
				else
					x := Munger(handle(texthnd), 0, Pointer(Ord(@orgfind) + 1), length(orgfind), Pointer(Ord(@replace) + 1), length(replace));
			until (x < 0);
	end;

	procedure ReplaceNumber (tofind: str255; toreplace: longint);
		var
			x, y: longint;
			replace, orgFind, temp: str255;
	begin
		orgfind := tofind;
		with CurGlobs^ do
			repeat
				replace := stringOf(toreplace : 0);
				x := Munger(handle(texthnd), 0, Pointer(Ord(@orgfind) + 1), length(orgfind), nil, 0);
				if (x < 0) then
					exit(ReplaceNumber);
				if (texthnd^^[x + length(orgfind)] = '<') then
				begin
					temp := concat(textHnd^^[x + length(orgfind) + 1], textHnd^^[x + length(orgfind) + 2]);
					StringToNum(temp, y);
					replace := stringOf(toreplace : y);
					tofind := StringOf(orgfind, '<', temp);
					x := Munger(handle(texthnd), 0, Pointer(Ord(@tofind) + 1), length(tofind), Pointer(Ord(@replace) + 1), length(replace));
				end
				else if (texthnd^^[x + length(orgfind)] = '>') then
				begin
					temp := concat(textHnd^^[x + length(orgfind) + 1], textHnd^^[x + length(orgfind) + 2]);
					StringToNum(temp, y);
					replace := stringOf(toreplace : 0, ' ' : y - length(stringOf(toReplace : 0)));
					tofind := StringOf(orgfind, '>', temp);
					x := Munger(handle(texthnd), 0, Pointer(Ord(@tofind) + 1), length(tofind), Pointer(Ord(@replace) + 1), length(replace));
				end
				else
					x := Munger(handle(texthnd), 0, Pointer(Ord(@orgfind) + 1), length(orgfind), Pointer(Ord(@replace) + 1), length(replace));
			until (x < 0);
	end;

	function TSex (theUser: userRec): str255;
	begin
		if TheUser.sex then
			Tsex := 'Male'
		else
			Tsex := 'Female';
	end;

	procedure scanfile (texthnd: TextHand);
		var
			SearchString, Replace, TempString, myTempStr: Str255;
			x: longint;
	begin
		with CurGlobs^ do
		begin
			SearchString := '%';
			if Munger(handle(texthnd), 0, Pointer(Ord(@searchString) + 1), length(searchString), nil, 0) >= 0 then
			begin
				searchstring := '%novars';
				if Munger(handle(texthnd), 0, Pointer(Ord(@searchString) + 1), length(searchString), nil, 0) >= 0 then
				begin
					replace := '';
					searchString := '%novars';
					x := Munger(handle(texthnd), 0, Pointer(Ord(@searchString) + 1), length(searchString), Pointer(Ord(@replace) + 1), length(replace));
				end
				else
				begin
					ReplaceText('%vers', stringof(HERMES_VERSION));
					ReplaceNumber('%tcall', InitSystHand^^.numcalls);
					ReplaceNumber('%nodes', InitSystHand^^.numnodes);
					ReplaceNumber('%tctdy', TotalCalls);
					ReplaceNumber('%tcnod', InitSystHand^^.callsToday[activeNode]);
					ReplaceNumber('%ttmin', TotalMins);
					ReplaceNumber('%tnmin', InitSystHand^^.MinsToday[ActiveNode]);
					ReplaceNumber('%tptdy', TotalPosts);
					ReplaceNumber('%tpnod', InitSystHand^^.mPostedToday[activeNode]);
					ReplaceNumber('%tetdy', TotalEmail);
					ReplaceNumber('%tenod', InitSystHand^^.emailToday[ActiveNode]);
					ReplaceNumber('%tutdy', TotalUls);
					ReplaceNumber('%tkutdy', TotalKUl);
					ReplaceNumber('%tunod', InitSystHand^^.uploadsToday[ActiveNode]);
					ReplaceNumber('%tkunod', InitSystHand^^.kuploaded[ActiveNode]);
					ReplaceNumber('%tuftdy', TotalFUls);
					ReplaceNumber('%tdtdy', TotalDLs);
					ReplaceNumber('%tkdtdy', TotalKDl);
					ReplaceNumber('%tdnod', InitSystHand^^.dlsToday[ActiveNode]);
					ReplaceNumber('%tkdnod', InitSystHand^^.kDownloaded[ActiveNode]);
					ReplaceNumber('%tdftdy', TotalFDls);
					ReplaceText('%lstul', getDate(InitSystHand^^.lastUL));
					ReplaceText('%lstdl', getDate(InitSystHand^^.lastDL));
					ReplaceText('%lstpt', getDate(InitSystHand^^.lastPost));
					ReplaceText('%lstem', getDate(InitSystHand^^.lastEmail));
					ReplaceText('%messcomp', stringof(thisUser.messcomp : 3 : 2));
					ReplaceText('%xfercomp', stringof(thisUser.xfercomp : 3 : 2));
					ReplaceNumber('%u.num', thisUser.UserNum);
					ReplaceText('%u.name', thisUser.UserName);
					ReplaceText('%u.real', thisUser.RealName);
					ReplaceText('%u.lston', getDate(thisUser.lastOn));
					ReplaceText('%u.fston', getDate(thisUser.firstOn));
					ReplaceText('%u.sex', tsex(thisUser));
					ReplaceNumber('%u.age', thisUser.age);
					ReplaceNumber('%u.slvl', thisUser.SL);
					ReplaceNumber('%u.tlvl', thisUser.DSL);
					ReplaceNumber('%u.tmsg', thisUser.MessagesPosted);
					ReplaceNumber('%u.dmsg', thisUser.mPostedToday);
					ReplaceNumber('%u.teml', thisUser.EmailSent);
					ReplaceNumber('%u.deml', thisUser.EMsentToday);
					ReplaceNumber('%u.tul', thisUser.numuploaded);
					ReplaceNumber('%u.dul', thisUser.NumULToday);
					ReplaceNumber('%u.tupk', thisUser.uploadedK);
					ReplaceNumber('%u.dupk', thisUser.KBULToday);
					ReplaceNumber('%u.tdl', thisUser.numDownloaded);
					ReplaceNumber('%u.ddl', thisUser.NumDLToday);
					ReplaceNumber('%u.ktdl', thisUser.DownloadedK);
					ReplaceNumber('%u.kddl', thisUser.KBDLToday);
					ReplaceNumber('%u.swdth', thisUser.ScrnWdth);
					ReplaceNumber('%u.shght', thisUser.ScrnHght);
					ReplaceNumber('%u.tcl', thisUser.TotalLogons);
					ReplaceNumber('%u.ill', thisUser.IllegalLogons);
					ReplaceNumber('%u.dcl', thisUser.onToday);
					ReplaceNumber('%u.tmin', thisUser.totalTimeOn);
					ReplaceNumber('%u.dmin', thisUser.MinonToday + ((tickCount - timeBegin) div 60 div 60) + 1);
{ReplaceText('%u.lstul', getDate(thisUser.lastUL));}
{ReplaceText('%u.lstdl', getDate(thisUser.lastDL));}
{ReplaceText('%u.lstpt', getDate(thisuser.lastPost));}
{ReplaceText('%u.lstem', getDate(thisUser.lastEmail));}
					ReplaceText('%u.cpu', thisUser.computerType);
					ReplaceNumber('%u.dlcr', thisUser.DLCredits);
					ReplaceText('%u.baud', thisUser.LastBaud);
					DLRatioStr(tempString, ActiveNode);
					ReplaceText('%u.udr', tempString);
					GoodRatioStr(tempString);
					ReplaceText('%u.rdr', tempString);
					ReplaceText('%u.class', SecLevels^^[thisUser.SL].class);
					ReplaceText('%u.misc1', thisUser.miscField1);
					ReplaceText('%u.misc2', thisUser.miscField2);
					ReplaceText('%u.misc3', thisUser.miscField3);
					ReplaceText('%u.dphon', thisUser.dataphone);
					ReplaceText('%u.company', thisUser.company);
					ReplaceText('%u.street', thisUser.street);
					ReplaceText('%u.city', thisUser.city);
					ReplaceText('%u.state', thisUser.state);
					ReplaceText('%u.zip', thisUser.zip);
					ReplaceText('%u.country', thisUser.country);
					ReplaceText('%u.donation', thisUser.donation);
					ReplaceText('%u.lastdonation', thisUser.lastdonation);
					ReplaceText('%u.expiration', thisUser.ExpirationDate);
					ReplaceText('%date', getdate(-1));
					ReplaceText('%time', whattime(-1));

					ReplaceText('%u.pcr', stringOf((thisUser.messagesPosted / thisUser.totalLogons) : 0 : 2));
					ReplaceText('%u.rpcr', stringOf((1 / thisUser.postRatioOneTo) : 0 : 2));
					ReplaceText('%bbs', bbsname);
				end;
			end;
		end;
	end;

	function ReadTextFile (fileName: str255; storedAs: integer; insertPath: boolean): boolean;
		var
			myHParmer: HParmBlkPtr;
			myParmer: ParmBlkPtr;
			myOSerr: OSerr;
			SharedRef: integer;
			fullResult: boolean;
			SearchString, ReplaceString, TempString, myTempStr: Str255;
	begin
		with curglobs^ do
		begin
			listingHelp := false;
			fullResult := false;
			if textHnd <> nil then
			begin
				HPurge(handle(texthnd));
				DisposHandle(handle(textHnd));
				textHnd := nil;
			end;
			if (storedAs = 0) or (storedAs = 2) then
			begin
				if insertPath then
					myTempStr := concat(sharedPath, filename)		{Misc:}
				else
					myTempStr := fileName;
				myHParmer := HParmBlkPtr(NewPtr(SizeOf(HParamBlockRec)));
				myHParmer^.ioCompletion := nil;
				myHParmer^.ioNamePtr := @myTempStr;
				myHParmer^.ioVRefNum := 0;
				myHParmer^.ioPermssn := fsRdPerm;
				myHParmer^.ioMisc := nil;
				myHParmer^.ioDirID := 0;
				myOSerr := PBHOpen(myHParmer, false);
				OpenTextRef := myHParmer^.ioRefNum;
				if myHParmer^.ioResult = noErr then
				begin
					result := GetEOF(OpenTextRef, openTextSize);
					result := SetFPos(OpenTextRef, fsFromStart, 0);
					TextHnd := TextHand(NewHandle(openTextSize));
					if memError = noErr then
					begin
						MoveHHi(handle(TextHnd));
						HNoPurge(handle(TextHnd));
						Result := FSRead(OpenTextRef, OpenTextSize, pointer(TextHnd^));
					end
					else
						OpenTextSize := 0;
					if storedAs = 2 then
					begin
						scanFile(textHnd);
						OpenTextSize := GetHandleSize(handle(textHnd));
					end;
					myParmer := ParmBlkPtr(NewPtr(sizeOf(ParamBlockRec)));
					myParmer^.ioCompletion := nil;
					myParmer^.ioRefNum := OpenTextRef;
					myOSerr := PBClose(myParmer, false);
					DisposPtr(ptr(myParmer));
					fullResult := True;
				end
				else
					fullResult := false;
				DisposPtr(ptr(myHParmer));
			end
			else if storedAs = 1 then
			begin
				UseResFile(TextRes);
				myTempStr := concat('ANSI ', fileName);
				if thisUser.TerminalType = 1 then
				begin
					if not thisUser.AlternateText then
						textHnd := TextHand(GetNamedResource('HTxt', myTempStr))
					else
						textHnd := TextHand(GetNamedResource('ATxt', myTempStr));
					if textHnd = nil then
						if not thisUser.AlternateText then
							textHnd := TextHand(GetNamedResource('HTxt', fileName))
						else
							textHnd := TextHand(GetNamedResource('ATxt', fileName));
				end
				else if not thisUser.AlternateText then
					textHnd := TextHand(GetNamedResource('HTxt', fileName))
				else
					textHnd := TextHand(GetNamedResource('ATxt', fileName));
				if (ResError = noErr) and (TextHnd <> nil) then
				begin
					ScanFile(textHnd);
					OpenTextSize := SizeResource(handle(textHnd));
					DetachResource(handle(texthnd));
					MoveHHi(handle(texthnd));
					HNoPurge(handle(textHnd));
					fullResult := true;
				end
				else
					fullResult := false;
				UseResFile(myResourceFile);
			end;
			if fullResult then
			begin
				CurTextPos := 0;
				InPause := false;
				SysopStop := false;
			end;
		end;
		readtextFile := FullResult;
	end;

	procedure ListTextFile;
		const
			speed = 400;
		var
			tBuf: CharsPtr;
			built, i, simLnsPause: integer;
			nowStyle: CharStyle;
			num: longint;
			tANSI, searchString1, searchString2: str255;
			ForcedSysopPause: boolean;
	begin
		with curGlobs^ do
		begin
			ForcedSysopPause := false;
			nowStyle := gBBSwindows[activeNode]^.curStyle;
			tBuf := CharsPtr(NewPtr(speed * 2));
			built := 0;
			simLnsPause := LnsPause;
			if listingHelp then
				lnsPause := 0;
			while ((simLnsPause < (thisUser.scrnHght - 1)) or not thisUser.pauseScreen or noPause) and (built < speed - 1) and (curTextPos < OpenTextSize) and not sysopStop and (simLnsPause < 29999) do
			begin
				if (textHnd^^[curTextPos] = char(13)) then
				begin
					simLnsPause := simLnsPause + 1;
					tBuf^[built] := char(13);
					tBuf^[built + 1] := char(10);
					built := built + 2;
				end
				else if (textHnd^^[curTextPos] = char(3)) then
				begin
					if thisUser.TerminalType = 1 then
					begin
						curTextPos := curTextPos + 1;
						StringToNum(textHnd^^[curTextPos], num);
						thisUser.foregrounds[17] := num;
						curTextPos := curTextPos + 1;
						if (textHnd^^[curTextPos] >= '0') and (textHnd^^[curTextPos] <= '8') then
						begin		(* New Style; the only style supported now *)
							StringToNum(textHnd^^[curTextPos], num);
							thisUser.backgrounds[17] := num;
							curTextPos := curTextPos + 1;
							if textHnd^^[curTextPos] = 'T' then
								thisUser.intense[17] := true
							else
								thisUser.intense[17] := false;
							curTextPos := curTextPos + 1;
							if textHnd^^[curTextPos] = 'T' then
								thisUser.underlines[17] := true
							else
								thisUser.underlines[17] := false;
							curTextPos := curTextPos + 1;
							if textHnd^^[curTextPos] = 'T' then
								thisUser.blinking[17] := true
							else
								thisUser.blinking[17] := false;

							DecodeM(17, nowStyle, tANSI);
							nowStyle.fCol := thisUser.foregrounds[17];
							nowStyle.bCol := thisUser.backgrounds[17];
							nowStyle.Intense := thisUser.Intense[17];
							nowStyle.underline := thisUser.underlines[17];
							nowStyle.Blinking := thisUser.Blinking[17];
							for i := 1 to length(tANSI) do
							begin
								tBuf^[built] := tANSI[i];
								built := built + 1;
							end;
						end;
					end
					else {No ANSI}
					begin
						curTextPos := curTextPos + 2;
						if (textHnd^^[curTextPos] >= '0') and (textHnd^^[curTextPos] <= '8') then
							curTextPos := curTextPos + 3
						else
							curTextPos := curTextPos - 1;
					end;
				end
				else if (textHnd^^[curTextPos] = char(9)) and (InitSystHand^^.usePauses) then
				begin
					ForcedSysopPause := true;
					LnsPause := thisUser.ScrnHght + 1;
					simLnsPause := thisUser.ScrnHght + 1;
				end
				else if (textHnd^^[curTextPos] = char(11)) and (InitSystHand^^.usePauses) then
				begin
					ForcedSysopPause := true;
					LnsPause := 29999;
					simLnsPause := 29999;
				end
				else if (textHnd^^[curTextPos] = char(27)) then
				begin
					if thisUser.TerminalType = 1 then
					begin
						tBuf^[built] := textHnd^^[curTextPos];
						built := built + 1;
					end;
				end
				else if (textHnd^^[curTextPos] > char(31)) or (textHnd^^[curTextPos] >= char(14)) or (textHnd^^[curTextPos] <= char(6)) then
				begin
					tBuf^[built] := textHnd^^[curTextPos];
					built := built + 1;
				end;
				curTextPos := curTextPos + 1;
			end;
			if built > 0 then
			begin
				if not sysopLogon then
					result := AsyncMWrite(outputRef, built, ptr(tBuf));
				ProcessData(activeNode, ptr(tBuf), built);
			end;
			if ((noPause) and (not ForcedSysopPause)) then
				lnsPause := 0;
			if inZScan then
				lnsPause := 0;
			if curTextPos >= openTextSize then
			begin
				if textHnd <> nil then
				begin
					HPurge(handle(TextHnd));
					DisposHandle(handle(TextHnd));
				end;
				noPause := false;
				TextHnd := nil;
				BoardAction := none;
				if thisUser.TerminalType = 1 then
					doM(0);
				bCR;
				if listingHelp then
				begin
					listingHelp := false;
					ReprintPrompt;
				end;
			end;
			DisposPtr(ptr(tBuf));
		end;
	end;

	procedure UserExternal (theHermStuff: UserXIPtr; PP: procptr);
	inline
		$205f,  	{   movea.l (a7)+,a0  }
		$4e90;	{	jsr(a0)			   }

	procedure CallUserExternal (message, whichOne: integer);
	begin
		theExtRec^.privates := handle(theNodes[activeNode]^.ExternVars);
		theExtRec^.extID := whichOne;
		theExtRec^.message := message;
		theExtRec^.HSystPtr := pointer(InitSystHand^);
		theExtRec^.HMForumPtr := pointer(MForum^);
		theExtRec^.HMConfPtr := @MConference;
		theExtRec^.HTForumPtr := pointer(Forums^);
		theExtRec^.HTDirPtr := pointer(forumIdx^);
		theExtRec^.HGFilePtr := pointer(intGFileRec^);
		theExtRec^.HSecLevelsPtr := pointer(SecLevels^);
		theExtRec^.HMailerPtr := pointer(Mailer^);
		theExtRec^.HFeedbackPtr := pointer(InitFBHand^);
		theExtRec^.HermUsers := myUsers;
		if myExternals^^[whichOne].runtimeExternal then
		begin
			if runtimeExternalNum <> 0 then
			begin
				theExtRec^.prefs := handle(myExternals^^[runtimeExternalNum].privatesNum);
				UseResFile(myExternals^^[runtimeExternalNum].UResoFile);
				UserExternal(theExtRec, pointer(myExternals^^[runtimeExternalNum].codeHandle^));
				myExternals^^[runtimeExternalNum].privatesNum := ord4(theExtRec^.prefs);
			end
			else
			begin
				OutLine('The runtime environment for that external is missing.', true, 6);
				if message = ACTIVEEXT then
					theNodes[activeNode]^.activeUserExternal := -1;
			end;
		end
		else
		begin
			theExtRec^.prefs := handle(myExternals^^[whichOne].privatesNum);
			UseResFile(myExternals^^[whichOne].UResoFile);
			UserExternal(theExtRec, pointer(myExternals^^[whichOne].codeHandle^));
			myExternals^^[whichOne].privatesNum := ord4(theExtRec^.prefs);
		end;
		UseResFile(myResourceFile);
		if message <> DOINITILIZE then
			theNodes[activeNode]^.ExternVars := ord4(theExtRec^.privates);
	end;

	procedure BackSpace (howMany: integer);
		var
			result: OSerr;
			count: longint;
			dumRect: rect;
			ts: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			ts := '';
			for i := 1 to (3 * howMany) do
				ts := concat(' ', ts);
			ts := '';
			count := 3 * howMany;
			for i := 1 to howmany do
				ts := concat(ts, char(8));
			for i := 1 to howmany do
				ts := concat(ts, char(32));
			for i := 1 to howmany do
				ts := concat(ts, char(8));
			if not sysopLogon then
				result := AsyncMWrite(outputRef, count, @ts[1]);
			ProcessData(activeNode, @ts[1], count);
		end;
	end;

	procedure ListLine (whichLine: integer);
		var
			s, holdOut: str255;
			i: integer;
			templong: longint;
	begin
		with curglobs^ do
		begin
			s := curMessage^^[whichline];
			s := concat(s, char(3), '0', CHAR(13));
			i := 1;
			holdOut := '';
			if length(s) > 0 then
			begin
				while (s[i] <> char(13)) and (i <= length(s)) do
				begin
					if s[i] = char(3) then
					begin
						if length(holdOut) > 0 then
						begin
							OutLine(holdOut, false, -1);
							holdOut := '';
						end;
						i := i + 1;
						StringToNum(s[i], templong);
						thisUser.foregrounds[17] := templong;
						i := i + 1;
						if (s[i] >= '0') and (s[i] <= '8') then
						begin		(* New Style; the only style supported now *)
							StringToNum(s[i], templong);
							thisUser.backgrounds[17] := templong;
							i := i + 1;
							if s[i] = 'T' then
								thisUser.intense[17] := true
							else
								thisUser.intense[17] := false;
							i := i + 1;
							if s[i] = 'T' then
								thisUser.underlines[17] := true
							else
								thisUser.underlines[17] := false;
							i := i + 1;
							if s[i] = 'T' then
								thisUser.blinking[17] := true
							else
								thisUser.blinking[17] := false;
							templong := 17;
						end;
						if thisUser.TerminalType = 1 then
							doM(tempLong);
					end
					else if (s[i] = char(8)) then
					begin
						if length(holdOut) > 0 then
						begin
							OutLine(holdOut, false, -1);
							holdOut := '';
						end;
						backspace(1);
					end
					else if (s[i] > char(31)) then
						holdOut := concat(holdOut, s[i]);
					i := i + 1;
				end;
				if length(holdOut) > 0 then
				begin
					OutLine(holdOut, false, -1);
					holdOut := '';
				end;
			end;
		end;
	end;

	procedure ChatroomSingle (ToNode: integer; OutputHeader, Beep: boolean; OverrideMsg: str255);
	external;

	procedure SingleNodeOutput (whatString: Str255; i: integer);
		var
			savedNode: integer;
			t1, t2: str255;
			mySavedBD: BDact;
	begin
		if (theNodes[i]^.BoardMode = User) and not theNodes[i]^.myTrans.active and (theNodes[i]^.logonstage > checkstuff) and (theNodes[i]^.boardSection <> offStage) and (theNodes[i]^.boardAction <> chat) and (theNodes[i]^.boardAction <> writing) and (i <> activeNode) then
		begin
			curGlobs := theNodes[i];
			savedNode := activeNode;
			activeNode := i;
			with curglobs^ do
			begin
				mySavedBD := BoardAction;
				BoardAction := none;
				if (theNodes[activeNode]^.BoardSection = ChatRoom) then
				begin
					ChatRoomSingle(activeNode, false, false, whatString);
					BoardAction := mySavedBD;
				end
				else
				begin
					if thisUser.TerminalType = 1 then
					begin
						ANSICode(stringOf(gBBSwindows[activeNode]^.cursor.h + 1 : 0, 'D'));
						ANSICode('K');
					end
					else
						bCR;
					OutLine(whatString, false, 1);
					BoardAction := mySavedBD;
					bCR;
					if BoardAction = Writing then
						ListLine(online)
					else if boardAction = Prompt then
						ReprintPrompt;
				end;
			end;
			curGlobs := theNodes[savedNode];
			activeNode := savedNode;
		end;
	end;

	procedure BroadCast (whatString: str255; color: integer);
		var
			savedNode, i: integer;
			t1, t2: str255;
			mySavedBD: BDact;
	begin
		for i := 1 to InitSystHand^^.numNodes do
		begin
			if (theNodes[i]^.BoardMode = User) and not theNodes[i]^.myTrans.active and (theNodes[i]^.logonstage > checkstuff) and (theNodes[i]^.boardSection <> offStage) and (theNodes[i]^.boardAction <> chat) and (theNodes[i]^.boardAction <> writing) then
			begin
				curGlobs := theNodes[i];
				savedNode := activeNode;
				activeNode := i;
				with curglobs^ do
				begin
					mySavedBD := BoardAction;
					BoardAction := none;
					if (theNodes[activeNode]^.BoardSection = ChatRoom) then
					begin
						ChatRoomSingle(activeNode, false, false, whatString);
						BoardAction := mySavedBD;
					end
					else
					begin
						if thisUser.TerminalType = 1 then
						begin
							ANSICode(stringOf(gBBSwindows[activeNode]^.cursor.h + 1 : 0, 'D'));
							ANSICode('K');
						end
						else
							bCR;
						OutLine(whatString, false, color);
						BoardAction := mySavedBD;
						bCR;
						if BoardAction = Writing then
							ListLine(online)
						else if boardAction = Prompt then
							ReprintPrompt;
					end;
				end;
				curGlobs := theNodes[savedNode];
				activeNode := savedNode;
			end;
		end;
	end;

	procedure MultinodeOutput (whatString: str255);
		var
			savedNode, i: integer;
			t1, t2: str255;
			mySavedBD: BDact;
	begin
		for i := 1 to InitSystHand^^.numNodes do
			if (theNodes[i]^.BoardMode = User) and not theNodes[i]^.myTrans.active and (theNodes[i]^.logonstage > checkstuff) and (theNodes[i]^.boardSection <> offStage) and (theNodes[i]^.boardSection <> ListFiles) and (theNodes[i]^.boardAction <> chat) and (theNodes[i]^.boardAction <> writing) and (i <> activeNode) then
			begin
				if (theNodes[i]^.thisUser.notifyLogon) then
				begin
					curGlobs := theNodes[i];
					savedNode := activeNode;
					activeNode := i;
					with curglobs^ do
					begin
						mySavedBD := BoardAction;
						BoardAction := none;
						if (theNodes[i]^.BoardSection = ChatRoom) then
						begin
							begin
								ChatRoomSingle(i, false, true, whatString);
								BoardAction := mySavedBD;
							end
						end
						else
						begin
							if thisUser.TerminalType = 1 then
							begin
								ANSICode(stringOf(gBBSwindows[activeNode]^.cursor.h + 1 : 0, 'D'));
								ANSICode('K');
							end
							else
								bCR;
							OutLine(concat(char(7), whatString), false, 1);
							BoardAction := mySavedBD;
							bCR;
							if BoardAction = Writing then
								ListLine(online)
							else if boardAction = Prompt then
								ReprintPrompt;
						end;
					end;
					curGlobs := theNodes[savedNode];
					activeNode := savedNode;
				end;
			end;
	end;

	procedure toggleDTR (s: Boolean);
		var
			x: byte;
			IOError: OSErr;
	begin
		x := 17;
		if not s then
			x := 18;
		IOError := Control(curglobs^.outputRef, x, nil);
	end;

	procedure DoHangup;
		var
			ts: str255;
			i: integer;
	begin
		with curGlobs^ do
		begin
			case hangingUp of
				0: 
				begin
					if (activeUserExternal > 0) and (BoardSection = External) then
						CallUserExternal(closeNode, activeUserExternal);
					if not sysopLogon then
					begin
						if (nodeType = 1) then
						begin
							ClearInBuf;
							if useDTR then
								toggleDTR(false);
							crossLong := tickCount;
							hangingUp := 1;
						end
						else if (nodeType = 2) then
						begin
							CloseADSPConnection;
							hangingUp := 4;
						end
						else if (nodeType = 3) then
						begin
							hangingUp := 29;
						end;
						if sendLogOff then
							MultinodeOutput(concat('< ', thisUser.userName, RetInStr(42), ' >'));
					end
					else
						hangingUp := 4;
					if visibleNode = activeNode then
					begin
						DisableItem(GetMHandle(mUser), 0);
						DrawMenuBar;
					end;
				end;
				1: 
				begin
					if useDTR and ((crossLong + 30) < tickCount) then
					begin
						toggleDTR(true);
						TellModem('AT');
						hangingUp := 4;
					end
					else if ((crossLong + 100) < tickCount) then
					begin
						ts := '   ';
						for i := 1 to 3 do
							ts[i] := char(1);
						i := 3;
						result := AsyncMWrite(outputRef, i, ptr(ord4(@ts) + 1));
						hangingUp := 2;
						crossLong := tickCount;
					end;
				end;
				2: 
				begin
					if (crossLong + 100) < tickCount then
					begin
						TellModem('ATH0');
						hangingUp := 4;
					end;
				end;
				29: 
				begin
					{ Only close the connection if all outstanding sends have completed. }
					if ((nodeTCP.tcpPBPtr^.ioResult <> 1) and (toBeSent = nil)) then
					begin
						CloseTCPConnection(@nodeTCP, 5);
						hangingUp := 3;
					end;
				end;
				3: 
				begin
					if (nodeTCP.tcpPBPtr^.ioResult <> 1) then
						hangingUp := 4;
				end;
				4: 
				begin
					if sysopLogon and goOffInLocal and (nodeType = 1) then
						TellModem('ATH0');
					hangingUp := 5;
					EndUser;
				end;
				5: 
				begin
					if (nodeType = 3) then
						StartTCPListener(@nodeTCP);
					result := FlushVol(nil, homeVol);
					BoardMode := Failed;
				end;
				otherwise
			end;
		end;
	end;

	procedure ConnectMade (serKe: char);
		var
			yaba, ts, noCarrier, t1: str255;
			connected, i: integer;
			count, tl, tempLong: longint;
			tempANSI: boolean;
			tempChar: char;
	begin
		with curglobs^ do
		begin
			if FrontCharElim = 1 then
			begin
				if serKe = char(13) then
				begin
					connected := -1;
					NoCarrier := '3';
					ts := AnsInProgress;
					AnsInProgress := '';
					for i := 1 to modemDrivers^^[modemID].numResults do
					begin
						NumToString(modemDrivers^^[modemID].rs[i - 1].num, t1);
						if EqualString(t1, ts, false, false) then
							connected := i;
					end;
					if connected = -1 then
					begin
						if EqualString(noCarrier, ts, false, false) then
							connected := 10000;
					end;
					if (connected < 0) or (connected = 10000) then
					begin
						HangupAndReset;
					end
					else
					begin
						rsIndex := connected - 1;
						currentBaud := modemDrivers^^[modemID].rs[rsIndex].portRate;
						if matchInterface then
							DoBaudReset(currentBaud);
						curBaudNote := modemDrivers^^[modemID].rs[rsIndex].desc;
						OutLineSysop(concat(RetInStr(507), curBaudNote), true);	{Logging on at }
						sysopLogon := false;
						GetDateTime(tl);
						IUTimeString(tl, true, ts);
						LogThis(stringOf(RetInStr(506), curBaudNote, ' at ', ts, ' - Node #', activeNode : 0), 0);	{Carrier detected: }
  					(* ANSI Detect *)
						tempANSI := false;
						if not InitSystHand^^.NoANSIDetect then
						begin
							OutLine(concat(char(27), '[6n'), false, 0);
							tempLong := tickCount + 180;
							repeat
								tempChar := Get1ComPort;
								giveBBSSpecialTime;
							until ((tempChar = 'R') or (tempChar = 'r')) or (tickCount > tempLong);
							if (tempChar = 'r') or (tempChar = 'R') then
								tempANSI := true
							else
								tempANSI := false;
						end;
						DoLogon(tempANSI);
					end;
				end
				else
					ansInProgress := concat(ansInProgress, serKe);
			end
			else
			begin
				Delay(40, count);
				yaba := concat(modemDrivers^^[modemID].ansModem, char(13));
				count := length(yaba);
				result := AsyncMWrite(outputRef, count, ptr(ord4(@yaba) + 1));
				frontCharElim := 1;
				ansInprogress := '';
			end;
		end;
	end;


	procedure AnswerCall;
		var
			count: longInt;
			yaba: str255;
			connected, i: integer;
	begin
		with curglobs^ do
		begin
			if numrings >= rings then
			begin
				OutLineSysop(RetInStr(501), false);	{*Call detected...press ''H'' to abort answering.}
				BoardMode := Answering;
				frontcharElim := 0;
				lastKeyPressed := tickCount;
			end
			else
				numrings := numrings + 1;
		end;
	end;

	procedure DoLogon (isANSI: boolean);
		var
			q: longInt;
			ReadItIn: boolean;
			WelcomeName, tempString: str255;
			tempInt, templong: longint;
			tempChar: char;
	begin
		with curglobs^ do
		begin
			NumToBaud(minBaud, tempInt);
			if (currentBaud >= tempInt) or sysopLogon then
			begin
				if visibleNode = activeNode then
				begin
					EnableItem(GetMHandle(mUser), 0);
					DrawMenuBar;
				end;
				lastKeyPressed := TickCount;
				if not sysopLogon and (nodeType = 1) then
				begin
					repeat
					until not UserHungUp or ((lastKeyPressed + 80) < tickCount);
					if UserHungUp then
					begin
						HangupAndReset;
						exit(doLogon);
					end
					else
					begin
						result := KillIO(inputRef);
						result := KillIO(outputRef);
					end;
				end;
				gettingANSI := isANSI;
				readItIn := false;
				boardmode := user;
				WelcomeName := '';
				thisUser.AlternateText := WelcomeAlternate;

				if isANSI then
				begin
					thisUser.TerminalType := 1;
					thisUser.ColorTerminal := true;
					noPause := true;
					readItIn := ReadTextFile('ANSI Welcome', 1, false);
				end
				else
					readItIn := ReadTextFile('Welcome', 1, false);
				bCR;
				bCR;
				BoardSection := Logon;
				BoardAction := ListText;
				LogonStage := Welcome;
				ClearScreen;
				if readItIn then
					ListTextFile
				else
				begin
					BoardAction := none;
					OutLine('Welcome file not found.', true, 0);
				end;
				NumRptPrompt := 3;
			end
			else
			begin
				boardmode := user;
				sysopLogon := false;
				delay(67, q);
				bCR;
				bCR;
				NumToString(tempInt, tempString);
				OutLine(RetInStr(502), true, 0);	{This baud rate not supported.}
				OutLine(concat(RetInStr(503), tempString, RetInStr(504)), true, 0);	{Please upgrade your modem to at least }
				NumToString(currentBaud, tempString);
				LogThis(concat(RetInStr(505), tempString, RetInStr(504)), 0);	{Attempted logon at }
				Delay(40, q);
				HangupAndReset;
			end;
		end;
	end;

	procedure HangupAndReset;
		var
			i, savedNode: integer;
			okay: boolean;
			s1: str255;
			t1: longint;
	begin
		with curglobs^ do
		begin
			for i := 1 to InitSystHand^^.NumNodes do
				if (theNodes[i]^.amSpying) and (spying = i) then
				begin
					spying := 0;

					curGlobs := theNodes[i];
					savedNode := activeNode;
					activeNode := i;
					with curGlobs^ do
					begin
						OutLine(RetInStr(420), true, 1);	{Exiting spy mode...}
						NodeDo := NodeOne;
						amSpying := false;
						if myQuote.wasSeg then
							thisUser.PauseScreen := true;
						myQuote.wasSeg := false;
					end;
					curGlobs := theNodes[savedNode];
					activeNode := savedNode;
					leave;
				end;

			if (amSpying) then
			begin
				amSpying := false;
				for i := 1 to InitSystHand^^.NumNodes do
					if theNodes[i]^.spying = activeNode then
					begin
						theNodes[i]^.spying := 0;
						leave;
					end;
			end;

			if (BoardMode = User) then
			begin
				if hangingUp < 0 then
					hangingUp := 0;
				DoHangup;
			end
			else
			begin
				hangingUp := -1;
				InitAllVars;
				if (nodeType = 3) then
				begin
					BoardMode := Waiting;
					OutLineSysop(concat(char(12), RetInStr(820)), false);	{Waiting for TCP connection.}
					statChanged := true;
				end
				else if (nodeType = 2) then
				begin
					BoardMode := Waiting;
					OutLineSysop(concat(char(12), RetInStr(466)), false);	{Waiting for ADSP connection.}
					statChanged := true;
				end
				else
				begin
					OutLineSysop(concat(char(12), RetInStr(467)), false);	{Waiting for modem, hold Command-. to abort...}
					i := 0;
					okay := false;
					if PrepModem then
						okay := true;
					if okay then
						goWaitMode
					else
					begin
						if inits >= 3 then
						begin
							Delay(30, t1);
							TellModem(modemDrivers^^[modemID].reset);
							Delay(30, t1);
							NumFails := NumFails + 1;
							inits := 1;
						end;
						BoardMode := Failed;
						bCR;
						OutLineSysop(RetInStr(468), false);{There seems to be a problem with the modem...}
						OutLineSysop(RetInStr(469), true); {It will be rechecked every 30 seconds, or press return.}
						for i := 1 to 2 do
							SysBeep(1);
						Delay(60, t1);
						for i := 1 to 2 do
							SysBeep(1);
						statChanged := true;
					end;
				end;
				if not answerCalls then
				begin
					if not held[activeNode] then
					begin
						if (nodeType = 1) then
						begin
							Delay(30, t1);
							TellModem('ATM0H1');
							held[activeNode] := true;
						end;
					end;
				end;
				lastTry := tickCount;
			end;
		end;
	end;

	procedure GoWaitMode;
	begin
		with curglobs^ do
		begin
			BoardMode := Waiting;
			NumFails := 0;
			inits := 1;
			gBBSwindows[activeNode]^.curStyle := defaultStyle;
			if TabbyPaused then
				OutLineSysop(concat(char(27), '[H', char(27), '[K', RetInStr(499)), false) {Waiting for mailer...}
			else
				OutLineSysop(concat(char(27), '[H', char(27), '[K', RetInStr(500)), false);	{Waiting...}
			statChanged := true;
		end;
	end;

	procedure ANSIprompter (numch: integer);
		var
			t1: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			if (thisUser.TerminalType = 1) and thisUser.ColorTerminal then
			begin
				OutLine(stringOf(' ' : numch), false, 4);
				ANSIcode(StringOf(numch : 0, 'D'));
				myPrompt.inputColor := 4;
			end;
		end;
	end;

	procedure printSysopStats;
		var
			tempString, tempString2: str255;
			templong: longInt;
			i: integer;
	begin
		ClearScreen;
		OutLine(concat('New User Pass   : ', InitSystHand^^.newUserPass), true, 3);
		if InitSystHand^^.closed then
			tempString := 'Board is        : Closed'
		else
			tempString := 'Board is        : Open';
		OutLine(tempString, true, 3);
		OutLine(StringOf('Number Users    : ', InitSystHand^^.NumUsers : 0), true, 3);
		OutLine(StringOf('Free Memory     : ', FreeMem div 1024 : 0, 'k'), true, 3);
		OutLine(StringOf('Disk Free Space : ', (FreeK(SharedPath) div 1024) : 0, 'k'), true, 3);
		bCR;
		OutLine('##  Calls  Posts  Email  Minutes  Uploads  Downloads', true, 1);
		OutLine('==  =====  =====  =====  =======  =======  =========', true, 1);
		for i := 1 to InitSystHand^^.NumNodes do
		begin
			NumToString(InitSystHand^^.FailedUls[i], tempString);
			if not theNodes[i]^.SysOpNode then
			begin
				OutLine(stringOf(i : 2, '  ', InitSystHand^^.CallsToday[i] : 5, '  ', InitSystHand^^.mPostedToday[i] : 5, '  ', InitSystHand^^.EmailToday[i] : 5, '  '), true, 2);
				OutLine(stringOf(InitSystHand^^.minsToday[i] : 7, '  ', InitSystHand^^.uploadsToday[i] : 3, '/', InitSystHand^^.FailedUls[i] : 0), false, 2);
				OutLine(stringOf(' ' : 3 - length(tempString), '  ', InitSystHand^^.dlsToday[i] : 4, '/', InitSystHand^^.FailedDls[i] : 0), false, 2);
			end;
		end;
		NumToString(TotalFUls, tempString);
		OutLine('==  =====  =====  =====  =======  =======  =========', true, 1);
		OutLine(stringof(' T  ', TotalCalls : 5, '  ', TotalPosts : 5, '  ', TotalEmail : 5, '  ', TotalMins : 7, '  ', TotalUls : 3, '/', TotalFUls : 0, ' ' : 3 - length(tempString), '  ', TotalDls : 4, '/', TotalFDls : 0), true, 2);
	end;

	procedure PromptUser (whichNode: integer);
	begin
		with theNodes[whichNode]^ do
		begin
			with myPrompt do
			begin
				lnsPause := 0;
				if LogonStage < CheckStuff then
				begin
					HermesColor := -1;
					InputColor := -1;
				end;
				CountTimeWarn := CountTimeWarn + 1;
				if (CountTimeWarn > 4) and (ticksLeft(whichNode) <= 18000) and (BoardSection <> MainMenu) and (BoardSection <> NewUser) and (BoardSection <> Logon) then
				begin
					OutChr(char(7));
					OutLine(concat(RetInStr(207), tickToTime(ticksLeft(whichNode)), RetInStr(208)), true, 6);
					OutLine('', false, 0);
					CountTimeWarn := 0;
					if inPause then
						bCR;
				end;
				OutLine(promptLine, false, HermesColor);
				BoardAction := Prompt;
				Prompting := true;
				CurPrompt := '';
			end;
		end;
	end;

	procedure PAUSEPrompt (prompt: str255);
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				inPause := true;
				promptLine := prompt;
				allowedChars := '';
				replaceChar := char(0);
				Capitalize := true;
				enforceNumeric := false;
				ansiAllowed := False;
				autoAccept := true;
				wrapAround := false;
				wrapsonCR := false;
				breakChar := char(0);
				HermesColor := 3;
				InputColor := 0;
				numericLow := 0;
				numericHigh := 0;
				maxChars := 0;
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure MainMenuPrompt (prompt: str255);
		var
			t1: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				statChanged := true;
				promptLine := prompt;
				AllowedChars := '';
				if not inTransfer then
				begin
					for i := 1 to length(menucmds) do
					begin
						if (Menuhand^^.SecLevel[i] <= ThisUser.SL) and (Menuhand^^.OnOff[i]) then
							AllowedChars := concat(allowedchars, menucmds[i]);
					end;
				end
				else
					for i := 1 to length(menucmds) do
					begin
						if (TransHand^^.SecLevel[i] <= ThisUser.SL) and (TransHand^^.OnOff[i]) then
							AllowedChars := concat(allowedchars, menucmds[i]);
					end;
				replaceChar := char(0);
				ansiAllowed := False;
				Capitalize := true;
				enforceNumeric := true;
				autoAccept := true;
				wrapAround := false;
				wrapsonCR := true;
				breakChar := '/';
				HermesColor := 2;
				InputColor := 0;
				numericLow := 1;
				if inTransfer then
					numericHigh := HowManySubs(inRealDir)
				else
					numericHigh := MForum^^[inForum].NumConferences + 1;
				maxChars := 16;
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure NewYesNoQuestion (prompt: STR255);
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				promptLine := prompt;
				ansiAllowed := False;
				allowedChars := 'YN';
				replaceChar := char(13);
				Capitalize := true;
				enforceNumeric := true;
				autoAccept := true;
				wrapAround := false;
				wrapsonCR := true;
				breakChar := char(0);
				HermesColor := 5;
				InputColor := 1;
				numericLow := -1;
				numericHigh := -1;
				maxChars := 1;
				KeyString1 := 'Yes';
				KeyString2 := 'No';
				KeyString3[1] := char(0);
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure YesNoQuestion (prompt: STR255; yesIsDefault: boolean);
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				promptLine := prompt;
				ansiAllowed := False;
				allowedChars := 'YN';
				replaceChar := char(0);
				Capitalize := true;
				enforceNumeric := true;
				autoAccept := true;
				wrapAround := false;
				wrapsonCR := true;
				breakChar := char(0);
				HermesColor := 5;
				InputColor := 1;
				numericLow := -1;
				numericHigh := -1;
				maxChars := 1;
				KeyString1 := 'Yes';
				if yesisDefault then
					KeyString1 := concat(char(13), keyString1);
				KeyString2 := 'No';
				if not yesisDefault then
					KeyString2 := concat(char(13), keyString2);
				KeyString3[1] := char(0);
				PromptUser(activeNode);
			end;
		end;
	end;


	procedure NumbersPrompt (prompt, accepted: STR255; high, low: longint);
		var
			temp: str255;
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				promptLine := prompt;
				allowedChars := accepted;
				replaceChar := char(0);
				Capitalize := true;
				enforceNumeric := true;
				autoAccept := true;
				wrapAround := false;
				wrapsonCR := true;
				breakChar := char(0);
				ansiAllowed := False;
				HermesColor := 2;
				InputColor := 0;
				numericLow := low;
				numericHigh := high;
				NumToString(high, temp);
				maxChars := Length(temp);
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure LettersPrompt (prompt, accepted: str255; sizeLimit: integer; auto, wrap, capital: boolean; replace: char);
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				promptLine := prompt;
				allowedChars := accepted;
				replaceChar := replace;
				ansiAllowed := False;
				Capitalize := capital;
				enforceNumeric := false;
				autoAccept := auto;
				wrapAround := wrap;
				wrapsonCR := true;
				breakChar := char(0);
				HermesColor := 2;
				InputColor := 0;
				numericLow := 0;
				numericHigh := 0;
				maxChars := sizeLimit;
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure AnsiPrompt (prompt, accepted: str255; sizeLimit: integer; auto, wrap, capital: boolean; replace: char);
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				promptLine := prompt;
				allowedChars := accepted;
				replaceChar := replace;
				Capitalize := capital;
				enforceNumeric := false;
				autoAccept := auto;
				wrapAround := wrap;
				wrapsonCR := true;
				breakChar := char(0);
				HermesColor := 2;
				InputColor := 0;
				numericLow := 0;
				numericHigh := 0;
				maxChars := sizeLimit;
				ansiAllowed := true;
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure ReprintPrompt;
		var
			i: integer;
	begin
		with curGlobs^ do
		begin
			with myPrompt do
			begin
				lnsPause := 0;
				if LogonStage < CheckStuff then
				begin
					HermesColor := -1;
					InputColor := -1;
				end;
				OutLine(promptLine, false, HermesColor);
				BoardAction := Prompt;
				Prompting := true;
				if replaceChar = char(0) then
					OutLine(curPrompt, false, inputColor)
				else
				begin
					OutLine('', false, inputColor);
					for i := 1 to length(curPrompt) do
						OutLine(replaceChar, false, -1);
				end;
			end;
		end;
	end;

	procedure OutLineSysop (goingOut: str255; NLatBegin: boolean);
		var
			count: longint;
			i: integer;
			tempRect: rect;
			savePort: grafPtr;
			yaba: Str255;
	begin
		with curglobs^ do
		begin
			if NLatBegin then
			begin
				yaba := concat(char(13), char(10));
				ProcessData(activeNode, @yaba[1], 2);
			end;
			ProcessData(activeNode, @goingOut[1], length(goingOut));
		end;
	end;

	procedure ClearScreen;
		var
			t1: str255;
			c: longint;
	begin
		with curGlobs^ do
		begin
			if (thisUser.screenClears) or (BoardSection = ChatRoom) then
			begin
				if thisUser.TerminalType = 1 then
					t1 := concat(char(27), '[2J', char(27), '[H')
				else
				begin
					t1 := ' ';
					t1[1] := char(12);
				end;
				c := length(t1);
				if not sysopLogon then
					result := AsyncMWrite(outputRef, c, ptr(ord4(@t1) + 1));
				ProcessData(activeNode, @t1[1], c);
			end;
		end;
	end;

	procedure OutChr (theChar: char);
		var
			count: longInt;
			result: OSerr;
			tempString: str255;
	begin
		with curglobs^ do
		begin
			if (theChar <> char(12)) or thisUser.screenClears then
			begin
				if (theChar = char(12)) and (thisUser.TerminalType = 1) then
				begin
					OutLine(concat(char(27), '[2J', char(27), '[H'), false, -1);
				end
				else
				begin
					count := 1;
					tempString := ' ';
					tempString[1] := theChar;
					if not sysopLogon then
						result := AsyncMWrite(outputRef, count, @tempString[1]);
					ProcessData(activeNode, @tempstring[1], count);
				end;
			end;
		end;
	end;

	procedure GiveTime (tickstoGive: longint; multiplier: real; tellUser: boolean);
		var
			myReal: real;
			templong: longint;
	begin
		with curglobs^ do
		begin
			if (multiplier > 0) and not shutdownsoon then
			begin
				if (ticksLeft(activeNode) < NextDownticks) or (nextDownTicks < 0) then
				begin
					myReal := ticksToGive * multiplier;
					tempLong := trunc(myReal);
					extraTime := extraTime + tempLong;
					if tellUser then
					begin
						OutLine(concat(RetInStr(512), tickToTime(tempLong), RetInStr(513)), true, 1);{compensation time}
						bCR;
						bCR;
					end;
				end;
			end;
		end;
	end;

	procedure AnsiCode (theCode: str255);
		var
			t1: str255;
			count: longInt;
			Result: OSerr;
			tempInt, i: integer;
	begin
		with curglobs^ do
		begin
			t1 := theCode;
			if t1[1] <> '[' then
				t1 := concat(' [', theCode)
			else
				t1 := concat(' ', t1);
			t1[1] := char(27);
			count := length(t1);
			if not sysopLogon then
				result := AsyncMWrite(outputRef, count, @t1[1]);
			ProcessData(activeNode, @t1[1], count);
		end;
	end;

	procedure DecodeM (typeL: integer; nowStyle: CharStyle; var ts: str255);
		var
			t1, t2: str255;
			hadToInit: boolean;
			fg, bg: byte;
			intense, underlines: boolean;
	begin
		with curglobs^ do
		begin
			if (typeL = 16) or (typeL = 17) then
			begin
				fg := thisUser.foregrounds[typeL];
				bg := thisUser.backgrounds[typeL];
				intense := thisUser.intense[typeL];
				underlines := thisUser.underlines[typeL];
			end
			else if (typeL < USERCOLORBASE) then
			begin
				fg := InitSystHand^^.foregrounds[typeL];
				bg := InitSystHand^^.backgrounds[typeL];
				intense := InitSystHand^^.intense[typeL];
				underlines := InitSystHand^^.underlines[typeL];
			end
			else
			begin
				fg := thisUser.foregrounds[typeL - USERCOLORBASE];
				bg := thisUser.backgrounds[typeL - USERCOLORBASE];
				intense := thisUser.intense[typeL - USERCOLORBASE];
				underlines := thisUser.underlines[typeL - USERCOLORBASE];
			end;
			t1 := '';
			t2 := '';
			if ((nowStyle.intense) and not intense) or ((nowStyle.underLine) and not underlines) then
				hadtoInit := true
			else
				hadToInit := false;
			if thisUser.ColorTerminal and ((fg <> nowStyle.fCol) or hadToInit) then
			begin
				NumToString(fg + 30, t1);
			end;
			if thisUser.ColorTerminal and ((bg <> nowStyle.bCol) or hadToInit) then
			begin
				NumToString(bg + 40, t2);
			end;
			if (length(t2) > 0) and (length(t1) > 0) then
				t1 := concat(';', t1);
			t1 := concat(t2, t1);
			if not nowStyle.intense and intense then
			begin
				if length(t1) > 0 then
					t1 := concat('1;', t1)
				else
					t1 := '1';
			end;
			if not nowStyle.underLine and underlines then
				if length(t1) > 0 then
					t1 := concat('4;', t1)
				else
					t1 := '4';
			if hadToInit then
				t1 := concat('0;', t1);
			if length(t1) > 0 then
				ts := concat(char(27), '[', t1, 'm')
			else
				ts := '';
		end;
	end;

	procedure DoM (typeL: integer);
		var
			t1, t2: str255;
			hadToInit: boolean;
			fg, bg: byte;
			intense, underlines: boolean;
	begin
		with curglobs^ do
		begin
			if (typeL = 16) or (typeL = 17) then
			begin
				fg := thisUser.foregrounds[typeL];
				bg := thisUser.backgrounds[typeL];
				intense := thisUser.intense[typeL];
				underlines := thisUser.underlines[typeL];
			end
			else if (typeL < USERCOLORBASE) then
			begin
				fg := InitSystHand^^.foregrounds[typeL];
				bg := InitSystHand^^.backgrounds[typeL];
				intense := InitSystHand^^.intense[typeL];
				underlines := InitSystHand^^.underlines[typeL];
			end
			else
			begin
				fg := thisUser.foregrounds[typeL - USERCOLORBASE];
				bg := thisUser.backgrounds[typeL - USERCOLORBASE];
				intense := thisUser.intense[typeL - USERCOLORBASE];
				underlines := thisUser.underlines[typeL - USERCOLORBASE];
			end;
			with gBBSwindows[activeNode]^ do
			begin
				if not sysopLogon then
				begin
					t1 := '';
					t2 := '';
					if ((curStyle.intense) and not intense) or ((curStyle.underLine) and not underlines) then
						hadtoInit := true
					else
						hadToInit := false;
					if (thisUser.ColorTerminal) and ((fg <> curStyle.fCol) or hadToInit) then
					begin
						NumToString(fg + 30, t1);
						if not thisUser.ColorTerminal then
							NumToString(defaultStyle.fCol, t1);
					end;
					if (thisUser.ColorTerminal) and ((bg <> curStyle.bCol) or hadToInit) then
					begin
						NumToString(bg + 40, t2);
						if not thisUser.ColorTerminal then
							NumToString(defaultStyle.bCol, t2);
					end;
					if (length(t2) > 0) and (length(t1) > 0) then
						t1 := concat(';', t1);
					t1 := concat(t2, t1);
					if not curStyle.intense and intense then
					begin
						if length(t1) > 0 then
							t1 := concat('1;', t1)
						else
							t1 := '1';
					end;
					if not curStyle.underLine and underlines then
						if length(t1) > 0 then
							t1 := concat('4;', t1)
						else
							t1 := '4';
					if hadToInit then
						t1 := concat('0;', t1);
					if length(t1) > 0 then
					begin
						t1 := concat(char(27), '[', t1, 'm');
						result := AsyncMWrite(outputRef, length(t1), pointer(ord4(@t1) + 1));
					end;
				end;
				if thisUser.ColorTerminal then
				begin
					curStyle.fCol := fg;
					curStyle.bCol := bg;
				end;
				curStyle.intense := intense;
				curStyle.underline := underlines;
			end;
		end;
	end;

	procedure BufferIt (goingOut: str255; NLatBegin: boolean; typeLine: integer);
		var
			ts: str255;
	begin
		with curGlobs^ do
		begin
			if optBuffer = nil then
				gBBSwindows[activeNode]^.bufStyle := gBBSwindows[activeNode]^.curStyle;
			if (typeLine >= 0) and (thisUser.TerminalType = 1) then
			begin
				DecodeM(typeLine, gBBSwindows[activeNode]^.bufStyle, ts);
				if (typeLine = 16) or (typeLine = 17) then
				begin
					gBBSwindows[activeNode]^.bufStyle.fCol := thisUser.foregrounds[typeLine];
					gBBSwindows[activeNode]^.bufStyle.bCol := thisUser.backgrounds[typeLine];
					gBBSwindows[activeNode]^.bufStyle.intense := thisUser.intense[typeLine];
					gBBSwindows[activeNode]^.bufStyle.underline := thisUser.underlines[typeLine];
				end
				else if (typeLine < USERCOLORBASE) then
				begin
					gBBSwindows[activeNode]^.bufStyle.fCol := InitSystHand^^.foregrounds[typeLine];
					gBBSwindows[activeNode]^.bufStyle.bCol := InitSystHand^^.backgrounds[typeLine];
					gBBSwindows[activeNode]^.bufStyle.intense := InitSystHand^^.intense[typeLine];
					gBBSwindows[activeNode]^.bufStyle.underline := InitSystHand^^.underlines[typeLine];
				end
				else
				begin
					gBBSwindows[activeNode]^.bufStyle.fCol := thisUser.foregrounds[typeLine - USERCOLORBASE];
					gBBSwindows[activeNode]^.bufStyle.bCol := thisUser.backgrounds[typeLine - USERCOLORBASE];
					gBBSwindows[activeNode]^.bufStyle.intense := thisUser.intense[typeLine - USERCOLORBASE];
					gBBSwindows[activeNode]^.bufStyle.underline := thisUser.underlines[typeLine - USERCOLORBASE];
				end;
				goingOut := concat(ts, goingOut);
			end;
			if NLatBegin and not negatebCR then
				goingOut := concat(char(13), char(10), goingOut)
			else if negatebCR then
				negatebCR := false;
			if optBuffer = nil then
			begin
				optBuffer := CharsHandle(NewHandle(length(goingOut)));
				HNoPurge(handle(optBuffer));
			end
			else
				SetHandleSize(handle(optBuffer), GetHandleSize(handle(optBuffer)) + length(goingOut));
			HLock(handle(optBuffer));
			BlockMove(ptr(ord4(@goingOut) + 1), pointer(ord4(pointer(optBuffer^)) + GetHandleSize(handle(optBuffer)) - length(goingOut)), length(goingOut));
			HUnlock(handle(optBuffer));
		end;
	end;

	procedure bufferbcr;
	begin
		if not curGlobs^.negateBCR then
		begin
			bufferIt('', true, -1);
		end
		else
			curGlobs^.negateBCR := false;
	end;

	procedure BufClearScreen;
		var
			t1: str255;
			c: longint;
	begin
		with curGlobs^ do
		begin
			if thisUser.screenClears then
			begin
				if thisUser.TerminalType = 1 then
					t1 := concat(char(27), '[2J', char(27), '[H')
				else
				begin
					t1 := ' ';
					t1[1] := char(12);
				end;
				bufferIt(t1, false, -1);
			end;
		end;
	end;

	procedure ReleaseBuffer;
		var
			count: longint;
	begin
		with curGlobs^ do
		begin
			if optBuffer <> nil then
			begin
				count := GetHandleSize(handle(optBuffer));
				HLock(Handle(optBuffer));
				if not sysopLogon then
					result := asyncMWrite(outputRef, count, pointer(optBuffer^));
				ProcessData(activeNode, pointer(optBuffer^), count);
				HUnlock(Handle(optBuffer));
				HPurge(handle(optBuffer));
				DisposHandle(handle(optBuffer));
				optBuffer := nil;
			end;
		end;
	end;

	procedure OutLine (goingOut: str255; NLatBegin: boolean; typeLine: integer);
		var
			count: longint;
			i: integer;
			ts: str255;
	begin
		with curglobs^ do
		begin
			if NLatBegin then
				bCR;
			if (thisUser.TerminalType = 1) and (typeLine >= 0) then
				doM(typeLine);
			if not sysopLogon then
			begin
				count := length(GoingOut);
				result := asyncMWrite(outputRef, count, ptr(ord4(@goingOut) + 1));
			end;
			ProcessData(activeNode, ptr(ord4(@goingOut) + 1), length(goingOut));
		end;
	end;

	procedure OutLineC (goingOut: str255; NLatBegin: boolean; typeLine: integer);
		var
			count: longint;
			i: integer;
			ts: str255;
	begin
		with curglobs^ do
		begin
			i := 40 - (Length(GoingOut) div 2);
			GoingOut := StringOf(' ' : i, GoingOut);
			if (NLatBegin) then
				bCR;
			if (thisUser.TerminalType = 1) and (typeLine >= 0) then
				doM(typeLine);
			if not sysopLogon then
			begin
				count := length(GoingOut);
				result := asyncMWrite(outputRef, count, ptr(ord4(@goingOut) + 1));
			end;
			ProcessData(activeNode, ptr(ord4(@goingOut) + 1), length(goingOut));
		end;
	end;

	procedure bCR;
		var
			count: Longint;
			yaba: str255;
	begin
		with curglobs^ do
		begin
			if not negateBCR then
			begin
				yaba := concat(char(13), char(10));
				if not sysopLogon then
					result := AsyncMWrite(outputRef, 2, ptr(ord4(@yaba) + 1));
				ProcessData(activeNode, ptr(ord4(@yaba) + 1), 2);
			end
			else
				negateBCR := false;
		end;
	end;
end.