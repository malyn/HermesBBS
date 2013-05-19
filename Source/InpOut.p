{ Segments: InpOut_1 }
unit InpOut;


interface

	uses
		AppleTalk, ADSP, Serial, Sound, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs, Message_Editor, Terminal, inpOut4, inpOut3, inpOut2, Quoter;
	procedure LineChar (myChar: char);
	procedure EnterMessage (maxLins: integer);
	procedure Read_Mail;
	procedure DoChatshow (init, sysopSide: boolean; typed: char);
	procedure DoAttachFile;
	procedure DoDetachFile;

implementation

{$S InpOut_1}
	procedure MessToText (dispose: boolean);
		var
			l1, l2: longint;
			tempFoot: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			tempFoot := ' 00FFF';
			tempFoot[1] := char(3);
			tempFoot[7] := char(13);
			if curWriting <> nil then
				DisposHandle(handle(curWriting));
			curWriting := nil;
			if onLine > 1 then
			begin
				curWriting := TextHand(NewHandle(30000));
				HLock(handle(curWriting));
				l1 := 0;
				for i := 1 to (onLine - 1) do
				begin
					l2 := length(curMessage^^[i]);
					BlockMove(@curMessage^^[i][1], @curWriting^^[l1], l2);
					BlockMove(@tempfoot[7], @curWriting^^[l1 + l2], 1);
					l1 := l1 + l2 + 1;	{was l1 := l1 + l2 + 7;}
				end;
				L1 := L1 + 1;
				if not WasAMsg then
					curWriting^^[l1 - 1] := char(26)
				else
					curWriting^^[l1 - 1] := char(0);
				HNoPurge(handle(curWriting));
				HUnlock(handle(curWriting));
				SetHandleSize(handle(curWriting), l1);
				MoveHHi(handle(curWriting));
			end;
			if dispose then
			begin
				if curMessage <> nil then
					DisposHandle(handle(curmessage));
				curMessage := nil;
			end;
		end;
	end;

	function NumFilesinDir (dirNum, dirSub: integer): integer;
		var
			templong: longInt;
			tempRef: integer;
			result: OSerr;
			tempString: str255;
	begin
		NumToString(dirNum, tempString);
		result := FSOpen(concat(InitSystHand^^.DataPath, forumIdx^^.name[dirNum], ':', forums^^[dirNum].dr[dirSub].dirname), 0, tempRef);
		if result = noErr then
		begin
			result := GetEOF(tempRef, tempLong);
			result := FSClose(tempRef);
			numFilesinDir := tempLong div SizeOf(filEntryRec);
		end
		else
			NumFilesInDir := 0;
	end;

	function GetProtMenStr: str255;
	external;


	procedure DoAttachFile;
		var
			i: integer;
			tempString, tempstring2: str255;
			templong: longint;
			sysCurFil: FilEntryRec;
			b, DeleteFile: boolean;
			hhh: HparamBlockRec;
			tempFS: FSSpec;
			abg: point;
			repo: SFReply;
			dere: sfTypeList;
			s13: string[13];
			s12: string[12];
	begin
		with CurGlobs^ do
		begin
			case AttachDo of
				Attach0: 
				begin
					curPrompt := char(0);
					bCR;
					bCR;
					if wasEmail then
						tempString := 'Mail Attachments'
					else
						tempString := 'Message Attachments';
					for i := 1 to forumIdx^^.numDirs[0] do
						if (forums^^[0].dr[i].DirName = tempString) then
							tempSubDir := i;
					tempInDir := 0;
					if numFilesInDir(tempinDir, tempSubDir) >= forums^^[tempInDir].dr[tempSubDir].maxFiles then
					begin
						OutLine(RetInStr(383), true, 0);	{This directory is currently full.}
						bCR;
						GoHome;
						exit(DoAttachFile);
					end;
					if (thisUser.DSL < forums^^[tempInDir].dr[tempSubDir].DSLtoUL) or (thisUser.CantSendPPFile) then
					begin
						OutLine(RetInStr(123), true, 0);	{You do not meet the requirements to attach a file.}
						bCR;
						GoHome;
						exit(DoAttachFile);
					end;
					AttachDo := Attach1;
				end;
				Attach1: 
				begin
					savedBDaction := BoardAction;
					bCR;
					helpnum := 17;
					YesNoQuestion(RetInStr(595), true);
					AttachDo := Attach2;
				end;
				Attach2: 
				begin
					bCR;
					if (curPrompt = 'N') then
					begin
						if wasEMail then
							curEMailRec.isAMacFile := false
						else
							curMesgRec.isAMacFile := false;
					end
					else
					begin
						if wasEMail then
							curEMailRec.isAMacFile := true
						else
							curMesgRec.isAMacFile := true;
					end;
					tempLong := (FreeK(forums^^[tempInDir].dr[tempSubDir].path) div 1024);
					OutLine(concat(RetInStr(385), DoNumber(tempLong), 'K free.'), true, 0);	{Upload - }
					bCR;
					if tempLong < 250 then
					begin
						OutLine(RetInStr(64), true, 0);
						bCR;
						GoHome;
						exit(DoAttachFile);
					end;
					if not sysopLogon then
					begin
						bCR;
						if readTextFile('Upload Message', 1, false) then
						begin
							if thisUser.TerminalType = 1 then
								noPause := true;
							BoardAction := ListText;
							ListTextFile;
						end;
						AttachDo := Attach3;
					end
					else
						AttachDo := Attach8;
				end;
				Attach3: 
				begin
					bCR;
					LettersPrompt(RetInStr(386), '', forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, false, false, char(0));
					ANSIPrompter(forums^^[tempInDir].dr[tempSubDir].fileNameLength);
					AttachDo := Attach4;
				end;
				Attach4: 
				begin
					if (length(curprompt) > 0) then
					begin
						if (pos(':', curprompt) = 0) and (pos('.', curPrompt) <> 1) then
						begin
							curFil.flName := curPrompt;
							curFil.realFName := curprompt;
							GetDateTime(curFil.whenUL);
							curFil.uploaderNum := thisUser.userNum;
							curFil.numDLoads := 0;
							curFil.hasExtended := false;
							curFil.fileStat := char(0);
							curFil.lastDL := 0;
							for i := 1 to 50 do
								curFil.reserved[i] := char(0);
							curfil.Version := '';
							curfil.FileType := '';
							curfil.FileNumber := 0;
							bCR;
							if wasEMail then
								YesNoQuestion(concat('Attach ''', curprompt, ''' to ', curEMailRec.title, '? '), false)
							else
								YesNoQuestion(concat('Attach ''', curPrompt, ''' to ', curMesgRec.title, '? '), false);
							AttachDo := Attach5;
						end
						else
						begin
							GoHome;
							OutLine(RetInStr(387), true, 0);	{Illegal character in filename.}
							OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
						end;
					end
					else
					begin
						OutLine(RetInStr(388), true, 0);{File transmission aborted.}
						OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
						GoHome;
					end;
				end;
				Attach5: 
				begin
					if (curprompt = 'Y') then
					begin
						if (pos(':', curFil.realFName) = 0) then
							tempstring := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFname)
						else
							tempstring := curFil.realFName;
						if FExist(tempstring) then
						begin
							bCR;
							OutLine(RetInStr(389), true, 0);	{That file is already here.}
							AttachDo := Attach3;
						end
						else
							AttachDo := Attach6;
					end
					else
						GoHome;
				end;
				Attach6: 
				begin
					bCR;
					if wasEMail then
					begin
						if FindUser(StringOf(curEMailRec.ToUser : 0), tempUser) then
						begin
							s13 := tempUser.UserName;
							s12 := thisUser.UserName;
							curFil.flDesc := concat('#', stringOf(tempUser.UserNum : 0), ' ', s13, '/#', stringOf(thisUser.UserNum : 0), ' ', s12);
						end;
						curFil.hasExtended := false;
						curEMailRec.FileAttached := true;
						curEMailRec.FileName := curFil.flName;
					end
					else
					begin
						s13 := 'All';
						s12 := thisUser.UserName;
						curFil.flDesc := concat(s13, '/#', stringOf(thisUser.UserNum : 0), ' ', s12);
						curFil.hasExtended := false;
						curMesgRec.FileAttached := true;
						curMesgRec.FileName := curFil.flName;
					end;
					if theProts^^.numProtocols > 0 then
					begin
						crossint := theprots^^.numprotocols;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] or theProts^^.prots[i].pFlags[CANBRECEIVE] then
							begin
								crossInt := crossInt + 1;
								NumToString(crossint, tempstring2);
								tempString := concat(tempString, tempstring2);
							end;
						end;
						bCR;
						bCR;
						NumbersPrompt(getProtMenStr, 'Q?', crossInt, 0);
						AttachDo := Attach7;
					end
					else
					begin
						if wasEMail then
							curEMailRec.FileAttached := false
						else
							curMesgRec.FileAttached := false;
						OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
						GoHome;
					end;
				end;
				Attach7: 
				begin
					if curPrompt = '?' then
					begin
						OutLine(RetInStr(309), true, 0);	{Q: Abort Transfer(s)}
						OutLine(RetInStr(310), true, 0);	{0: Don't Transfer}
						crossInt := 0;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] or theProts^^.prots[i].pFlags[CANBRECEIVE] then
							begin
								crossInt := crossInt + 1;
								NumToString(crossInt, tempstring2);
								OutLine(concat(tempstring2, ': ', theProts^^.prots[i].ProtoName), true, 0);
								tempString := concat(tempString, tempstring2);
							end;
						end;
						bCR;
						bCR;
						NumbersPrompt(getProtMenStr, 'Q?', crossInt, 0);
						Exit(DoAttachFile);
					end
					else if (curPrompt = 'Q') or (curPrompt = '0') then
					begin
						if wasEmail then
							curEMailRec.FileAttached := false
						else
							curMesgRec.FileAttached := false;
						OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
						GoHome;
						Exit(DoAttachFile);
					end
					else
					begin
						StringToNum(curPrompt, tempLong);
						activeProtocol := 0;
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] or theProts^^.prots[i].pFlags[CANBRECEIVE] then
							begin
								crossInt := crossInt + 1;
								if crossInt = tempLong then
									activeProtocol := i;
							end;
						end;
						if length(curPrompt) = 0 then
							activeProtocol := thisUser.defaultProtocol;
						if (theProts^^.prots[activeProtocol].pFlags[CANRECEIVE] or theProts^^.prots[activeProtocol].pFlags[CANBRECEIVE]) and (activeProtocol > 0) then
						begin
							if not sysopLogon then
							begin
								bCR;
								bCR;
								bCR;
								if (theProts^^.prots[activeProtocol].pFlags[CANBRECEIVE]) then
								begin
									if FileTransit^^.numFiles < 50 then
									begin
										lastBatch := activeProtocol;
										if (fileTransit^^.sendingBatch and (fileTransit^^.numFiles > 0)) then
										begin
											FileTransit^^.numFiles := 0;
											FileTransit^^.batchTime := 0;
											FileTransit^^.batchKBytes := 0;
											OutLine(RetInStr(394), true, 0);	{Download batch cleared.}
											bCR;
										end;
										FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].theFile := curFil;
										FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].fromDir := tempInDir;
										FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].fromSub := tempSubDir;
										FileTransit^^.numFiles := FileTransit^^.numFiles + 1;
										OutLine(RetInStr(624), true, 0);{File added to batch queue.}
										NumToString(fileTransit^^.numFiles, tempString);
										OutLine(concat(RetInStr(393), tempstring), true, 0);{Batch UL: Files - }
										fileTransit^^.sendingBatch := false;
										bCR;
										goHome;
									end;
								end
								else
								begin
									myTrans.active := true;
									myTrans.sending := false;
									StartTrans;
								end;
							end
							else
							begin
								OutLine(RetInStr(395), true, 0);	{Cannot upload locally.}
								if wasEmail then
									curEMailRec.FileAttached := false
								else
									curMesgRec.FileAttached := false;
								OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
								GoHome;
							end;
						end
						else
						begin
							OutLine(RetInStr(396), true, 0);	{Protocol not valid for uploading.}
							if wasEmail then
								curEMailRec.FileAttached := false
							else
								curMesgRec.FileAttached := false;
							OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
							goHome;
						end;
					end;
				end;
				Attach8: 
				begin
					SetPT(abg, 40, 40);
					SFGetFile(abg, 'Attach which file?', nil, -1, dere, nil, repo);
					if repo.good then
					begin
						tempString := PathNameFromWD(repo.vRefNum);
						tempString := concat(tempString, repo.fName);
						if wasEMail then
						begin
							if FindUser(StringOf(curEMailRec.ToUser : 0), tempUser) then
							begin
								s13 := tempUser.UserName;
								s12 := thisUser.UserName;
								sysCurFil.flDesc := concat('#', stringOf(tempUser.UserNum : 0), ' ', s13, '/#', stringOf(thisUser.UserNum : 0), ' ', s12);
							end;
						end
						else
						begin
							s13 := 'All';
							s12 := thisUser.UserName;
							sysCurFil.flDesc := concat(s13, '/#', stringOf(thisUser.UserNum : 0), ' ', s12);
						end;
						GetDateTime(sysCurFil.whenUL);
						sysCurFil.uploaderNum := 1;
						sysCurFil.numDLoads := 0;
						sysCurFil.hasExtended := false;
						sysCurFil.fileStat := char(0);
						SysCurFil.Version := '';
						sysCurFil.lastDL := 0;
						SysCurFil.FileNumber := 0;
						sysCurFil.realFName := concat(forums^^[tempInDir].dr[tempSubDir].path, repo.fName);
						sysCurFil.flName := repo.fName;
						if wasEMail then
						begin
							curEMailRec.FileAttached := true;
							curEMailRec.FileName := repo.fName;
						end
						else
						begin
							curMesgRec.FileAttached := true;
							curMesgRec.FileName := repo.fName;
						end;
						if not FEXIST(concat(forums^^[tempInDir].dr[tempSubDir].path, repo.fName)) then
						begin
							DeleteFile := false;
							b := false;
							if (ModalQuestion(RetInStr(517), false, true) = 0) then	{Move file into directory path?}
							begin
								sysCurFil.realFName := tempString;
								b := true;
							end
							else if (ModalQuestion('Delete original file?', false, true) = 1) and (not b) then
								DeleteFile := true;
							if (not b) then
								result := copy1File(tempstring, sysCurFil.realFName);
							if DeleteFile then
								result := FSDelete(tempstring, 0);
							sysCurFil.byteLen := 0;
							hhh.ioCompletion := nil;
							if (gMac.systemVersion >= $0700) then
							begin
								result := FSMakeFSSpec(0, 0, sysCurFil.realFName, tempFS);
								hhh.ioVRefNum := tempFS.vrefnum;
								hhh.ioFDirIndex := 0;
								hhh.ioDirID := tempFS.parID;
								hhh.ioNamePtr := @tempFS.name;
								if (PBHGetFInfo(@hhh, false) = noErr) then
									sysCurFil.byteLen := hhh.ioFLLgLen + hhh.ioFLRLgLen;
							end
							else
							begin
								hhh.ioNamePtr := @sysCurFil.realFName;
								hhh.ioVRefNum := 0;
								hhh.ioFVersNum := 0;
								hhh.ioFDirIndex := 0;
								if PBGetFInfo(@hhh, false) = noErr then
									sysCurFil.byteLen := hhh.ioFLLgLen + hhh.ioFLRLgLen;
							end;
							if sysCurFil.byteLen < 1024 then
								sysCurFil.byteLen := 1024;
							SysCurFil.FileType := hhh.ioFlFndrInfo.fdtype;
							SysCurFil.FileCreator := hhh.ioFlFndrInfo.fdcreator;
							if (SysOpenDirectory(tempInDir, tempSubDir)) then
							begin
								SetHandleSize(handle(sysopOpenDir), GetHandleSize(handle(sysopOpenDir)) + SizeOf(filEntryRec));
								BlockMove(pointer(sysopOpenDir^), @sysopOpenDir^^[1], longInt(sysopNumFiles) * SizeOf(filEntryRec));
								sysopNumFiles := sysopNumFiles + 1;
								sysopOpenDir^^[0] := sysCurFil;
								GetDateTime(ForumIdx^^.lastupload[SysOpDirNum, SysOpSubNum]);
								DoForumRec(true);
								SysSaveDirectory;
								SysCloseDirectory;
							end
							else
							begin
								ProblemRep('Problem saving file information to directory file.');
								if wasEMail then
									curEMailRec.FileAttached := false
								else
									curMesgRec.FileAttached := false;
								OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
								goHome;
								exit(DoAttachFile);
							end;
						end
						else
						begin
							ProblemRep(RetInStr(519));	{File already exists in this directory.}
							if wasEmail then
								curEMailRec.FileAttached := false
							else
								curMesgRec.FileAttached := false;
							OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
							goHome;
							exit(DoAttachFile);
						end;
						goHome;
					end
					else
					begin
						if wasEMail then
							curEMailRec.FileAttached := false
						else
							curMesgRec.FileAttached := false;
						OutLine(RetInStr(124), true, 0);{A file was not attached successfully.}
						goHome;
					end;
				end;
				Attach9: 
				begin
				end;
				Attach10: 
				begin
				end;
				Attach11: 
				begin
				end;
				otherwise
			end;
		end;
	end;

	function PrintFileInfo (theFl: filEntryRec; fromDir, fromSubDir: integer; doOther: boolean): integer;
	external;

	function DLRatioOK: boolean;
	external;

	procedure DoDetachFile;
		var
			i: integer;
			FoundFile: boolean;
			tempString, t2: str255;
			templong: longint;
	begin
		with CurGlobs^ do
		begin
			case DetachDo of
				Detach1: 
				begin
					if wasEMail then
						tempString := 'Mail Attachments'
					else
						tempString := 'Message Attachments';
					for i := 1 to forumIdx^^.numDirs[0] do
						if (forums^^[0].dr[i].DirName = tempString) then
							tempSubDir := i;
					tempInDir := 0;

					if OpenDirectory(tempInDir, tempSubDir) then
					begin
						curDirPos := 0;
						allDirSearch := false;
						descSearch := false;
						fileMask := concat(AttachFName, '*');
						DetachDo := Detach2;
					end
					else
					begin
						OutLine(RetInStr(59), true, 1); {Memory Problem Opening Directory}
						GoHome;
					end;
				end;
				Detach2: 
				begin
					GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
					if curFil.flName <> '' then
					begin
						i := PrintFileInfo(curFil, tempInDir, tempSubDir, false);
						bCR;
						if InitSystHand^^.FreeMailDL or DLRatioOK or (not wasEMail) then
							DetachDo := Detach3
						else
						begin
							DLRatioStr(tempString, activeNode);
							GoodRatioStr(t2);
							bCR;
							OutLine(concat(RetInStr(403), tempString, RetInStr(404), t2, RetInStr(405)), true, 0); {DL Ratio too low}
							GoHome;
						end;
					end
					else
					begin
						OutLine(RetInStr(127), true, 1); {Attached file not found.}
						GoHome;
					end;
				end;
				Detach3: 
				begin
					bCR;
					bCR;
					if theprots^^.numProtocols > 0 then
					begin
						crossint := theprots^^.numprotocols;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] then
							begin
								crossInt := crossInt + 1;
								NumToString(crossint, t2);
								tempString := concat(tempString, t2);
							end;
						end;
						NumbersPrompt(getprotMenStr, 'Q?', crossInt, 0);
						DetachDo := Detach4;
					end
					else
						GoHome;
				end;
				Detach4: 
				begin
					ReadDo := ReadFour;
					if curPrompt = '?' then
					begin
						OutLine(RetInStr(309), true, 0);	{Q: Abort Transfer(s)}
						OutLine(RetInStr(310), true, 0);	{0: Don''t Transfer}
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] then
							begin
								crossInt := crossInt + 1;
								NumToString(crossInt, t2);
								OutLine(concat(t2, ': ', theProts^^.prots[i].ProtoName), true, 0);
							end;
						end;
						bCR;
						bCR;
						crossint := theprots^^.numprotocols;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] then
							begin
								crossInt := crossInt + 1;
								NumToString(crossint, t2);
								tempString := concat(tempString, t2);
							end;
						end;
						NumbersPrompt(getprotMenStr, 'Q?', crossInt, 0);
						DetachDo := Detach4;
					end
					else if (curPrompt = 'Q') or (curPrompt = 'q') or (curPrompt = '0') then
					begin
						GoHome;
						Exit(DoDetachFile);
					end
					else
					begin
						StringToNum(curPrompt, tempLong);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if (theProts^^.prots[i].pFlags[CANSEND]) then
							begin
								crossInt := crossInt + 1;
								if crossInt = tempLong then
								begin
									tempLong := i;
									Leave;
								end;
							end;
						end;
						if length(curPrompt) = 0 then
							tempLong := 2;
						if not sysopLogon then
						begin
							if ((nodeType <> 2) or ((tempLong <> 2))) and (tempLong > 0) and (theProts^^.numProtocols >= tempLong) and ((theProts^^.prots[tempLong].pFlags[CANSEND])) then {or (theProts^^.prots[tempLong].pFlags[CANBSEND])}
							begin
								activeProtocol := templong;
								bCR;
								bCR;
								bCR;
								myTrans.active := true;
								myTrans.sending := true;
								StartTrans;
							end;
						end
						else
						begin
							OutLine(RetInStr(113), true, 0);   {Cannot download locally}
							GoHome;
						end;
					end;
				end;
				Detach5: 
				begin
{A file was Detached Successfully}
					if wasEMail then
						ReadDo := ReadFour
					else if wasSearching then
						MessSearchDo := MSearch17
					else
						QDo := QTwo;
					GoHome;
				end;
				otherwise
			end;
		end;
	end;

	function ProcessSignature (sig: Str255): Str255;
		label
			1;
		var
			i: integer;
			col: longint;
			tempSig: Str255;
	begin
	{ Start with an empty signature. }
		tempSig := '';

	{ Process every character in the original signature. }
		for i := 1 to length(sig) do
		begin
			{ Don't let the signature get longer than a single line of text. }
			if length(tempSig) >= 160 then
				goto 1;

			{ Add this character if it is not a color sequence. }
			if sig[i] <> char(3) then
				tempSig := concat(tempSig, sig[i])

			{ Otherwise, we need to convert the color sequence to a new style sequence. }
			else
			begin
				{ Get the color. }
				case sig[i + 1] of
					'A': 
						col := 10;
					'B': 
						col := 11;
					'C': 
						col := 12;
					'D': 
						col := 13;
					'E': 
						col := 14;
					'F': 
						col := 15;
					otherwise
						StringToNum(sig[i + 1], col);
				end; { case }

				{ Don't add this color sequence if doing so would put us over the line length limit. }
				if (length(tempSig) + 6) >= 160 then
					goto 1;

				{ Convert the sequence and add it. }
				tempSig := concat(tempSig, char(3), MakeColorSequence(col));

				{ Skip the old style color sequence. }
				i := i + 1;
			end; { if..else }
		end; { for }

1:
	{ Return the signature line. }
		ProcessSignature := tempSig;
	end; { function ProcessSignature }

	procedure CheckLine;
		var
			s, s2, s3, s4: str255;
			done, lineNumbers, setNewLine, AvailFileAttach, ListMessage: boolean;
			i, b, Characaters, BegLine, EndLine: integer;
			l1, l2, SizeOfLine: longint;
			tempUser: UserRec;
			tempMessage: MessgHand;
	begin
		with curglobs^ do
		begin
			ListMessage := false;
			if (savedLine = -999) then
				savedLine := -99;
			done := false;
			setNewLine := false;
			if (thisUser.TerminalType = 1) then
				doM(saveColor);
			s := copy(curmessage^^[onLine], 1, 2);
			s2 := copy(curMessage^^[onLine], 1, 3);
			s3 := copy(curMessage^^[onLine], 1, 4);
			if (EqualString('/D', s, false, false)) then
			begin
				doM(0);
				if (savedLine = -1) and (onLine > 1) then
				begin
					ListMessage := true;
					SizeOfLine := SizeOf(curMessage^^[1]);	{Should be 161 bytes}
					s4 := curMessage^^[online];
					Delete(s4, 1, 2);
					if (pos('-', s4) <> 0) and (length(s4) > 1) then
					begin
						s := Copy(s4, 1, pos('-', s4) - 1);
						StringToNum(s, l1);
						BegLine := l1;
						s := Copy(s4, pos('-', s4) + 1, length(s4) - pos('-', s4));
						StringToNum(s, l1);
						EndLine := l1;
						if (BegLine <= EndLine) and (BegLine > 0) and (EndLine > 0) then
						begin
							SizeOfLine := SizeOfLine * ((online - 1) - EndLine);
							BlockMove(@curMessage^^[EndLine + 1][0], @curMessage^^[BegLine][0], SizeOfLine);
							onLine := onLine - (EndLine - BegLine) - 1;
						end;
					end
					else if (length(s4) > 0) and ((s4[1] = 'l') or (s4[1] = 'L')) then
					begin
						online := online - 1;
					end
					else if (length(s4) > 0) then
					begin
						StringToNum(s4, l1);
						if (l1 > 0) and (l1 < onLine) then
						begin
							SizeOfLine := SizeOfLine * ((onLine - 1) - l1);
							BlockMove(@curMessage^^[l1 + 1][0], @curMessage^^[l1][0], SizeOfLine);
							online := online - 1;
						end;
					end;
				end;
				Online := onLine - 1;
				if online < 0 then
					online := 0;
				doM(saveColor);
			end
			else if (EqualString('/M', s, false, false)) then
			begin
				doM(0);
				if (savedLine = -1) and (online > 1) then
				begin
					ListMessage := true;
					SizeOfLine := SizeOf(curMessage^^[1]);	{Should be 161 bytes}
					s4 := curMessage^^[onLine];
					Delete(s4, 1, 2);
					if (pos('/', s4) <> 0) and (pos('-', s4) <> 0) then
					begin
						s2 := Copy(s4, pos('/', s4) + 1, length(s4) - pos('/', s4));
						Delete(s4, pos('/', s4), length(s4) - (pos('/', s4) - 1));
						s := Copy(s4, 1, pos('-', s4) - 1);
						StringToNum(s, l1);
						BegLine := l1;
						s := Copy(s4, pos('-', s4) + 1, length(s4) - pos('-', s4));
						StringToNum(s, l1);
						EndLine := l1;
						if (EndLine > BegLine) then
						begin
							tempMessage := MessgHand(NewHandle(SizeOfLine * ((EndLine - BegLine) + 1)));
							l1 := SizeOfLine * ((EndLine - BegLine) + 1);
							BlockMove(@curMessage^^[BegLine][0], @tempMessage^^[1][0], l1);
							l1 := SizeOfLine * (online - EndLine);
							BlockMove(@curMessage^^[EndLine + 1][0], @curMessage^^[BegLine][0], l1);
							StringToNum(s2, l2);
							if (l2 < EndLine) then
							begin
								l1 := SizeOfLine * ((online - l2) - ((EndLine - BegLine) + 1));
								i := (l2 + 1) + ((EndLine - BegLine) + 1);
								BlockMove(@curMessage^^[l2 + 1][0], @curMessage^^[i][0], l1);
								l1 := SizeOfLine * ((EndLine - BegLine) + 1);
								BlockMove(@tempMessage^^[1][0], @curMessage^^[l2 + 1][0], l1);
							end
							else
							begin
								l1 := SizeOfLine * (online - l2);
								i := l2 + 1;
								BlockMove(@curMessage^^[BegLine + 1][0], @curMessage^^[i][0], l1);
								l1 := SizeOfLine * ((EndLine - BegLine) + 1);
								i := (l2 + 1) - ((EndLine - BegLine) + 1);
								BlockMove(@tempMessage^^[1][0], @curMessage^^[i][0], l1);
							end;
							DisposHandle(handle(tempMessage));
							tempMessage := nil;
						end;
					end
					else if (pos('/', s4) <> 0) then
					begin
						s := Copy(s4, pos('/', s4) + 1, length(s4) - pos('/', s4));
						Delete(s4, pos('/', s4), length(s4) - (pos('/', s4) - 1));
						StringToNum(s, l2);
						StringToNum(s4, l1);
						BegLine := l1;
						s := curMessage^^[BegLine];

						l1 := SizeOfLine * (Online - BegLine);
						BlockMove(@curMessage^^[BegLine + 1][0], @curMessage^^[BegLine][0], l1);
						if (BegLine < l2) then
						begin
							l1 := SizeOfLine * (online - l2);
							BlockMove(@curMessage^^[l2][0], @curMessage^^[l2 + 1][0], l1);
							curMessage^^[l2] := s;
						end
						else
						begin
							l1 := SizeOfLine * (online - (l2 + 1));
							BlockMove(@curMessage^^[l2 + 1][0], @curMessage^^[l2 + 2][0], l1);
							curMessage^^[l2 + 1] := s;
						end;
					end;
				end;
				online := onLine - 1;
				doM(saveColor);
			end
			else if EqualString(s3, '/RQ', false, false) then
			begin
				doM(0);
				if (reply) and (InitSystHand^^.Quoter) then
				begin
					if BoardSection = Email then
						wasEmail := True
					else
						wasEmail := false;
					if online > 0 then
						curMessage^^[online - 1] := concat(curMessage^^[online - 1], char(3), MakeColorSequence(0));
					BoardSection := Quote;
					QuoterDo := Quote1;
					boardAction := none;
					DoQuoter;
				end
				else if not InitSystHand^^.Quoter then
					OutLine(RetInStr(615), true, 0)	{Built-In Quoter Not Enabled.}
				else
					OutLine(RetInStr(616), true, 0);	{You Are Not Replying...}
				onLine := onLine - 1;
			end
			else if (EqualString('/R', s, false, false)) then
			begin
				doM(0);
				if (savedLine = -1) and (onLine > 1) then
				begin
					if (EqualString('/RL', s2, false, false)) then
					begin
						if onLine > 1 then
						begin
							OutLine(RetInStr(487), true, 0);	{Replace:}
							onLine := online - 1;
							savedLine := -999;
						end
						else
							OutLine(RetInStr(488), true, 0);	{Nothing to replace.}
					end
					else
					begin
						s4 := curMessage^^[online];
						delete(s4, 1, 2);
						StringToNum(s4, l1);
						if (l1 > 0) and (l1 < onLine) then
						begin
							OutLine(concat(RetInStr(470), s4, ':'), true, 0);	{Replace line }
							SavedLine := onLine;
							onLine := l1;
							setNewLine := true;
						end;
					end;
				end;
				Online := onLine - 1;
				doM(saveColor);
			end
			else if (EqualString('/I', s, false, false)) then
			begin
				doM(0);
				if (savedLine = -1) and (onLine > 1) then
				begin
					l1 := 0;
					s4 := curMessage^^[onLine];
					Delete(s4, 1, 2);
					StringToNum(s4, l1);
					if (l1 > 0) and (l1 < onLine) then
					begin
						SizeOfLine := SizeOf(curMessage^^[1]);	{Should be 161 bytes}
						l2 := SizeOfLine * (onLine - l1);
						BlockMove(@curMessage^^[l1 + 1][0], @curMessage^^[l1 + 2][0], l2);
						OutLine(concat('Insert text for line after line ', s4, ':'), true, 0);
						SavedLine := onLine + 1;
						onLine := l1;
						setNewLine := true;
					end;
				end;
				doM(saveColor);
			end
			else if (EqualString('/SU', s2, false, false)) then
			begin
				if onLine > 1 then
				begin
					ListMessage := true;
					BegLine := 0;
					if (curMessage^^[onLine][4] = '/') then
					begin
						BegLine := online - 1;
						Delete(curMessage^^[onLine], 1, 4);
					end
					else if (curMessage^^[onLine][4] = 'l') or (curMessage^^[onLine][4] = 'L') then
					begin
						BegLine := onLine - 1;
						Delete(curMessage^^[onLine], 1, 5);
					end
					else
					begin
						Delete(curMessage^^[onLine], 1, 3);
						i := pos('/', curMessage^^[onLine]);
						if (i > 0) then
						begin
							s4 := Copy(curMessage^^[onLine], 1, i - 1);
							StringToNum(s4, l1);
							BegLine := l1;
							Delete(curMessage^^[onLine], 1, i);
						end;
					end;
					i := pos('/', curMessage^^[online]);
					if (i > 0) and (BegLine <> 0) then
					begin
						s4 := Copy(curMessage^^[onLine], 1, i - 1);
						Delete(curMessage^^[online], 1, i);
						b := pos(s4, curMessage^^[BegLine]);
						if b > 0 then
						begin
							Delete(curMessage^^[BegLine], b, i - 1);
							s4 := curMessage^^[online];
							Insert(s4, curMessage^^[BegLine], b);
						end;
						onLine := online - 1;
					end;
				end;
			end
			else if (EqualString(s3, '/HEL', false, false)) then
			begin
				doM(0);
				bufferIt(RetInStr(471), true, 2);	{Editor Commands:}
				bufferbCR;
				bufferIt(RetInStr(472), true, 0);	{/RL  - Replace Last Line               /R#  - Replace Line #}
				bufferIt(RetInStr(473), true, 0);	{/DL  - Delete Last Line                /D#  - Delete Line # (or /D#-#)}
				bufferIt(RetInStr(474), true, 0);	{/SUL/old/new - Sub. old/new Text       /SU#/old/new - Sub. Line # old/new Text}
				bufferIt(RetInStr(475), true, 0);	{/M#/# - Move Line # after line #       /M#-#/# - Move Lines #-# after Line #}
				bufferIt(RetInStr(476), true, 0);	{/I#  - Insert a Line after Line #      /C:  - Center Rest of Line}
				bufferIt(RetInStr(477), true, 0);	{/LI  - List Message                    /LN  - List Message with Line Numbers}
				bufferIt(RetInStr(478), true, 0);	{/RQ  - Quote Text                      Cntl-P+Digit - Change Colors}
				bufferIt(RetInStr(479), true, 0);	{/CLR - Clear Text & Start Over         /BAR - Redisplay Color Bar}
				if (((BoardSection = EMail) and (InitSystHand^^.MailAttachments)) or ((BoardSection = Post) and (MConference[inForum]^^[inConf].FileAttachments))) and (not thisUser.CantSendPPFile) then
					bufferIt(RetInStr(480), true, 0); {/F   - Attach File & Save              /FSP - Attach File, Sign Name & Save}
				bufferIt(RetInStr(481), true, 0);	{/ES  - Save                            /ESY - Save Anonymous}
				bufferIt(RetInStr(482), true, 0);	{/ESP - Save & Sign Name                /ABT - Abort}
				bufferbCR;
				ReleaseBuffer;
				doM(saveColor);
				onLine := onLine - 1;
			end
			else if EqualString(s2, '/ESP', false, false) or EqualString(s2, '/ES', false, false) or EqualString(s, '/S', false, false) or (EqualString(s, '*S', false, false)) then
			begin
				doM(0);
				done := true;
				endAnony := 0;
				if length(curMessage^^[online]) > 2 then
				begin
					if EqualString(copy(curMessage^^[online], 4, 1), 'N', false, false) then
						endAnony := -1
					else if EqualString(copy(curMessage^^[online], 4, 1), 'Y', false, false) then
						endAnony := 1;
				end;
				if EqualString(copy(curMessage^^[online], 1, 4), '/ESP', false, false) then
				begin
					bCR;
					endAnony := -1;
					if (online + 1 > maxLines) then
						OutLine(RetInStr(484), true, 1)	{No Room Left In Message To Sign Your Name.}
					else
					begin
						onLine := onLine + 1;
						curMessage^^[online - 1] := ProcessSignature(thisUser.Signature);
						OutLine(RetInStr(485), true, 1);	{Signed Your Message.}
					end;
					bCR;
				end;
				MessToText(true);
			end
			else if ((EqualString('/F', s, false, false)) or EqualString(s3, '/FSP', false, false)) then
			begin
				AvailFileAttach := false;
				if (BoardSection = EMail) and (InitSystHand^^.MailAttachments) and (not netMail) and (not WasAMsg) then
				begin
					wasEMail := FindUser(StringOf(curEMailRec.ToUser : 0), tempUser);
					if (not tempUser.MailBox) then
					begin
						AvailFileAttach := true;
						wasEMail := true;
					end
					else
					begin
						OutLine(RetInStr(146), true, 6);
						curMessage^^[online] := char(0);
						online := online - 1;
					end;
				end
				else if ((BoardSection = Post) or (BoardSection = MessageSearcher)) and (MConference[inForum]^^[inConf].FileAttachments) then
				begin
					AvailFileAttach := true;
					wasEMail := false;
				end;

				if AvailFileAttach then
				begin
					doM(0);
					FromDetach := true;
					done := true;
					endAnony := -1;
					if EqualString(copy(curMessage^^[online], 1, 4), '/FSP', false, false) then
					begin
						bCR;
						if (online + 1 > maxLines) then
							OutLine(RetInStr(484), true, 1)	{No Room Left In Message To Sign Your Name.}
						else
						begin
							onLine := onLine + 1;
							curMessage^^[online - 1] := ProcessSignature(thisUser.Signature);
							OutLine(RetInStr(485), true, 1);	{Signed Your Message.}
						end;
						bCR;
					end;
					MessToText(true);
					BoardSection := AttachFile;
					AttachDo := Attach0;
					boardAction := none;
					DoAttachFile;
				end
				else
				begin
					OutLine('Sorry, that feature is not available.', true, 6);
					curMessage^^[online] := char(0);
					online := online - 1;
				end;
			end
			else if EqualString(s3, '/ABT', false, false) and ((CurEMailRec.title = RetInStr(723)) and (thisUser.EMailSent = 0)) then
			begin
				doM(0);
				Outline(RetInStr(143), true, 6);
				doM(saveColor);
				curMessage^^[online] := char(0);
				online := online - 1;
				s3 := '';
			end
			else if EqualString(s3, '/ABT', false, false) then
			begin
				curWriting := nil;
				DisposHandle(handle(curMessage));
				curmessage := nil;
				done := true;
			end
			else if (EqualString('/CLR', s3, false, false)) then
			begin
				doM(0);
				for i := 1 to maxLines do
					curMessage^^[i] := '';
				OutLine(RetInStr(486), true, 0);	{Message cleared... Start over...}
				onLine := 0;
				savedLine := -1;
				saveColor := 16;
			end
			else if (EqualString('/BAR', s3, false, false)) then
			begin
				doM(0);
				OutputColorBar;
				doM(saveColor);
				onLine := onLine - 1;
			end
			else if (EqualString('/C:', s2, false, false)) then
			begin
				delete(curMessage^^[onLine], 1, 3);
				curMessage^^[onLine] := concat(char(3), MakeColorSequence(saveColor), curMessage^^[onLine], char(3), MakeColorSequence(0));
				Characaters := 0;
				for i := 1 to length(curMessage^^[onLine]) do
					if curMessage^^[online][i] = char(3) then
					begin
						repeat
							i := i + 1;
						until (curMessage^^[online][i] <> char(3));
						i := i + 4;
					end
					else
						Characaters := Characaters + 1;
				Characaters := 79 - Characaters;
				Characaters := Characaters div 2;
				for i := 1 to Characaters do
					curMessage^^[online] := concat(' ', curMessage^^[onLine]);
			end
			else if (EqualString('/L', s, false, false)) then
			begin
				if onLine > 1 then
				begin
					if (EqualString('/LN', s2, false, false)) then
						lineNumbers := true
					else
						linenumbers := false;
					for i := 1 to (onLine - 1) do
					begin
						NumToString(i, s4);
						if lineNumbers then
							OutLine(concat(RetInStr(489), s4), true, 0);	{Line: }
						bCR;
						ListLine(i);
					end;
					OutLine(RetInStr(490), true, 2);	{Continue...}
					bCR;
					lnsPause := 0;
					doM(saveColor);
				end;
				onLine := onLine - 1;
			end;
			if not done then
			begin
				if not (boardsection = quote) then
					bCR;
				if (onLine + 5) = maxLines then
				begin
					OutLine(RetInStr(617), false, 0);	{5 lines left.}
					bCR;
				end;
				if (online + 1) > maxLines then
				begin
					OutLine(RetInStr(491), false, 0);	{-= No more lines =-}
					OutLine(RetInStr(492), true, 0);	{/ES to save.}
					bCR;
					online := online - 1;
				end;
				if length(excess) > 0 then
					OutLine(excess, false, saveColor);
				if not setnewLine and (savedLine > -1) then
				begin
					Online := savedLine;
					savedLine := -1;
					ListMessage := true;
				end
				else if (savedLine = -99) then
				begin
					ListMessage := true;
					savedLine := -1;
					onLine := onLine + 1;
				end
				else
					onLine := onLine + 1;
				curMessage^^[onLine] := '';
				if savecolor <> 0 then
				begin
					s4 := MakeColorSequence(saveColor);
					curMessage^^[onLine] := concat(char(3), s4, curMessage^^[onLine], excess)
				end
				else
					curMessage^^[onLine] := concat(curMessage^^[onLine], excess);
				if ListMessage then
				begin
					for i := 1 to (online - 1) do
					begin
						bCR;
						ListLine(i);
					end;
					OutLine(RetInStr(490), true, 2);	{Continue...}
					bCR;
					lnsPause := 0;
					doM(saveColor);
				end;
			end
			else if done then
				boardAction := none;
		end;
	end;

	procedure LineChar (myChar: char);
		var
			tempstring, s: str255;
			temppos, i, OtherCs: integer;
			templong: longint;
	begin
		with curglobs^ do
		begin
			LnsPause := 0;
			if myChar = char(127) then
				myChar := char(8);
			{The Below line allows for 3 color changes before typing a / commnad}
			if ((length(curMessage^^[online]) = 6) or (length(curMessage^^[online]) = 12) or (length(curMessage^^[online]) = 18)) and (myChar = '/') and (saveColor <> 0) then
				Delete(curMessage^^[online], 1, length(curMessage^^[online]));
			if (mychar <> char(13)) and ((gBBSwindows[activeNode]^.cursor.h < (thisUser.scrnWdth - 1)) or (myChar = char(8))) then
			begin
				if (curMessage^^[online][length(curMessage^^[online])] = char(3)) then
				begin
					if (length(curMessage^^[online]) < 161) then
					begin
						if (myChar >= 'a') and (myChar <= 'g') then
							myChar := chr(ord(myChar) - 32);
						case myChar of
							'0', '1', '2', '3', '4', '5', '6', '7', '8', '9': 
								StringToNum(myChar, templong);
							'A': 
								templong := 10;
							'B': 
								templong := 11;
							'C': 
								tempLong := 12;
							'D': 
								templong := 13;
							'E': 
								templong := 14;
							'F': 
								templong := 15;
							'G': 
								templong := 16;
							otherwise
								templong := -1;
						end;
						if templong >= 0 then
						begin
							tempstring := MakeColorSequence(templong);
							curMessage^^[online] := concat(curMessage^^[online], tempstring);
							if thisUser.TerminalType = 1 then
							begin
								doM(USERCOLORBASE + templong);
								savecolor := templong;
							end;
						end
						else
							delete(curMessage^^[onLine], length(curMessage^^[online]), 1);
					end;
				end
				else if (Length(curMessage^^[onLine]) < 160) or (mychar = char(8)) then
				begin
					if mychar >= char(32) then
					begin
						curMessage^^[onLine] := concat(curMessage^^[onLine], myChar);
						OutLine(mychar, false, -1);
					end
					else if (myChar = char(8)) then
					begin
						s := curMessage^^[onLine];
						if length(s) > 0 then
						begin
							if s[length(s) - 5] = char(3) then
							begin
								delete(s, length(s) - 5, 6);
								if thisUser.TerminalType = 1 then
								begin
									tempstring := MakeColorSequence(16);
									s := concat(s, char(3), tempstring);
									doM(16);
									saveColor := 16;
								end;
							end
							else if (s[length(s)] = char(8)) then
							begin
								delete(s, length(s), 1);
								OutLine(' ', false, -1);
							end
							else
							begin
								backspace(1);
								delete(s, length(s), 1);
							end;
						end;
						curMessage^^[onLine] := s;
					end
					else if (mychar = char(24)) then
					begin
						if gBBSwindows[activeNode]^.cursor.h > 0 then
							backspace(gBBSwindows[activeNode]^.cursor.h);
						curMessage^^[onLine] := '';
						if thisUser.TerminalType = 1 then
							doM(0);
					end
					else if (myChar = char(14)) then
					begin
						if gBBSwindows[activeNode]^.cursor.h > 0 then
						begin
							curMessage^^[onLine] := concat(curMessage^^[onLine], char(8));
							outChr(char(8));
						end;
					end
					else if (mychar = char(16)) then
					begin
						curMessage^^[onLine] := concat(curMessage^^[online], char(3));
					end
					else if (mychar = char(9)) then
					begin
						if ((4 + length(curMessage^^[onLine]) < 160)) then
						begin
							curMessage^^[onLine] := concat(curMessage^^[onLine], '    ');
							OutLine('    ', false, -1);
						end;
					end;
				end;
			end
			else
			begin
				if mychar <> char(13) then
				begin
					excess := '';
					s := curMessage^^[onLine];
					i := length(s);
					while ((i > 1) and (s[i] <> char(32)) and (s[i] <> char(8))) do {and (s[i - 1] <> char(3))}
						i := i - 1;
					if (s[i + 1] = char(3)) then
					begin
						delete(s, i + 1, 2);
					end;
					if (i < (length(s))) and (i > (gBBSwindows[activeNode]^.cursor.h div 2)) then
					begin
						excess := copy(s, length(s) - (length(s) - i) + 1, length(s) - i);
						excess := concat(excess, myChar);
						backspace(length(s) - i);
						delete(s, length(s) - (length(s) - i), (length(s) - i) + 1);
						curMessage^^[onLine] := s;
					end
					else
						excess := mychar;
				end
				else
					excess := '';
				if (thisUser.backgrounds[saveColor] <> 0) and ((Pos('/c:', curMessage^^[onLine]) = 0) and (Pos('/C:', curMessage^^[onLine]) = 0)) then
				begin
					OtherCs := 0;
					for i := 1 to length(curMessage^^[online]) do
						if curMessage^^[online][i] = char(3) then
							OtherCs := OtherCs + 1;
					OtherCs := length(curMessage^^[online]) - (OtherCs * 6);
					OtherCs := 80 - OtherCs;
					curMessage^^[online] := StringOf(curMessage^^[online], ' ' : OtherCs);
				end;
				CheckLine;
			end;
		end;
	end;

	procedure EnterMessage (maxLins: integer);
		var
			i, w: integer;
			ts, msgline: str255;
			col: longint;
	begin
		with curglobs^ do
		begin
			if curWriting <> nil then
				DisposHandle(handle(curWriting));
			curWriting := nil;
			if curmessage <> nil then
				DisposHandle(handle(curMessage));
			curMessage := nil;
			if maxLins > 200 then
				maxLins := 200;
			if maxLins < 10 then
				maxLins := 10;
			maxLines := maxLins;
			curMessage := messgHand(NewHandle(maxLines * 162));
			if memError = noErr then
			begin
				HNoPurge(handle(curMessage));
				MoveHHi(handle(curMessage));
				maxLines := maxLins;
				onLine := 1;
				savedLine := -1;
				for i := 1 to maxLines do
					curmessage^^[i] := '';
				if (reply) and (newMsg) and (InitSystHand^^.Quoter) then
				begin
					if (BoardSection = Email) then
						wasEmail := True
					else
						wasEmail := False;
					BoardSection := Quote;
					QuoterDo := Quote1;
					DoQuoter;
				end
				else
				begin
					bcr;
					OutLineC(StringOf(RetInStr(493), maxLines : 0, RetInStr(494)), false, 0);
					if (BoardSection = EMail) and (InitSystHand^^.MailAttachments) and (not thisUser.CantSendPPFile) and (not WasAMsg) then
						OutLineC(RetInStr(131), true, 0)	{/HELP-menu,  /ES-save,  /F-attach file/save,  /ABT-abort,  /ESP-sign/save.}
					else if (not WasEMail) and (not thisUser.CantSendPPFile) and (MConference[inForum]^^[inConf].FileAttachments) then
						OutLineC(RetInStr(131), true, 0)	{/HELP-menu,  /ES-save,  /F-attach file/save,  /ABT-abort,  /ESP-sign/save.}
					else
						OutLineC(RetInStr(495), true, 0);	{Enter ''/HELP'' for help, ''/ES'' to save.}
					if reply then
						OutLineC(RetInStr(618), true, 2); {Enter '/RQ' To Quote From Previous Message}
					if thisUser.TerminalType = 1 then
						OutputColorBar;
					ts := RetInStr(496);
					if thisUser.scrnWdth < 80 then
						delete(ts, thisUser.scrnWdth, 80 - thisUser.scrnWdth);
					OutLine(ts, true, 0);
					bCR;
					bCR;
					if thisUser.TerminalType = 1 then
					begin
						ts := concat(char(3), MakeColorSequence(16));
						CurMessage^^[1] := ts;
						doM(16);
						saveColor := 16;
					end;
					lnsPause := 0;
					BoardAction := Writing;
				end;
			end
			else
			begin
				OutLine('Out of memory!', true, 0);
				BoardAction := none;
			end;
		end;
	end;

	procedure GetScrnLineToStr (num, scrnNum: integer; var ts: str255);
		var
			i: integer;
	begin
		with gBBSwindows[num]^ do
		begin
			ts := '';
			for i := 1 to 80 do
				ts := concat(ts, ' ');
			BlockMove(@screen[(topLine + scrnNum) mod 24, 0], pointer(ord4(@ts) + 1), 80);
		end;
	end;

	procedure ScrollChatSide (num: integer; sysopSide: boolean);
		var
			i: integer;
			t1: str255;
	begin
		with curGlobs^ do
		begin
			if sysopSide then
			begin
				ANSIcode('H');
				for i := 1 to 6 do
				begin
					GetScrnLineToStr(activeNode, i + 5, t1);
					OutLine(concat(char(27), '[K', t1), false, -1);
					bCR;
				end;
				for i := 6 to 11 do
				begin
					ANSIcode(StringOf(i + 1 : 0, 'H'));
					ANSIcode('K');
				end;
				ANSIcode(concat('7H'));
			end
			else
			begin
				ANSIcode('14H');
				for i := 1 to 6 do
				begin
					GetScrnLineToStr(activeNode, i + 16, t1);
					OutLine(concat(char(27), '[K', t1), false, -1);
					bCR;
				end;
				for i := 20 to 24 do
				begin
					ANSIcode(stringOf(i : 0, 'H'));
					ANSIcode('K');
				end;
				ANSIcode('20H');
			end;
		end;
	end;

	procedure DoChatShow (init, sysopSide: boolean; typed: char);
		var
			t1, t2, s: str255;
			i, i1: INTEGER;
			tempPt: point;
			intwowaychat: boolean;
	begin
		with curglobs^ do
		begin
			inTwoWayChat := InitSystHand^^.twoWayChat and (thisUser.TerminalType = 1);
			LnsPause := 0;
			if typed = char(127) then
				typed := char(8);
			if init then
			begin
				bCR;
				if inTwoWayChat then
				begin
					ANSICode('2J');
					gBBSwindows[activeNode]^.saveH := 0;
					gBBSwindows[activeNode]^.saveV := 13;
					ANSICode('13;1H');
					t1 := '';
					for i := 1 to thisUser.scrnWdth do
						t1 := concat(t1, char(205));
					OutLine(t1, false, 3);
					t1 := concat(' ', myUsers^^[0].Uname, RetInStr(497), thisUser.userName, ' ');
					ANSICode(StringOf('13;', (thisUser.scrnWdth - length(t1)) div 2 : 0, 'H'));
					OutLine(t1, false, 4);
					ANSICode('H');
					chatKeySysop := true;
				end
				else
				begin
					ClearScreen;
					gBBSwindows[activeNode]^.saveH := $FFFF;
					gBBSwindows[activeNode]^.saveV := $FFFF;
					OutLine(concat(myUsers^^[0].UName, RetInStr(498)), false, 1);	{'s here ... }
					bCR;
					bCR;
					chatKeySysop := true;
				end;
				if InitSystHand^^.twoColorchat then
					OutLine('', false, 1)
				else
					OutLine('', false, 0);
			end  {init chat}
			else
			begin
				if inTwoWayChat and (sysopSide <> chatKeySysop) then
				begin
					NumToString(gBBSwindows[activeNode]^.saveV + 1, t1);
					NumToString(gBBSwindows[activeNode]^.saveH + 1, t2);
					gBBSwindows[activeNode]^.saveV := gBBSwindows[activeNode]^.cursor.v;
					gBBSwindows[activeNode]^.saveH := gBBSwindows[activeNode]^.cursor.h;
					ANSIcode(concat('[', t1, ';', t2, 'H'));
					chatKeySysop := not chatKeySysop;
					if InitSystHand^^.twoColorChat then
					begin
						if chatKeySysop then
							OutLine('', false, 1)
						else
							OutLine('', false, 5);
					end;
				end;
				if (gBBSwindows[activeNode]^.cursor.h = 79) and (typed <> char(8)) and (typed <> char(13)) then
				begin
					excess := '';
					GetScrnLineToStr(activeNode, gBBSwindows[activeNode]^.cursor.v, s);
					delete(s, 80, 1);
					i := 79;
					while ((i > 1) and (s[i] <> char(32))) do
						i := i - 1;
					if (i < 79) and (i > (gBBSwindows[activeNode]^.cursor.h div 2)) then
					begin
						excess := copy(s, length(s) - (length(s) - i) + 1, length(s) - i);
						excess := concat(excess, typed);
						backspace(length(s) - i);
						delete(s, length(s) - (length(s) - i), (length(s) - i) + 1);
					end
					else
						excess := typed;
					t1 := excess;
					if inTwoWayChat and sysopSide and (gBBSwindows[activeNode]^.cursor.v = 11) then
						ScrollChatSide(activeNode, true)
					else if inTwoWayChat and not sysopSide and (gBBSwindows[activeNode]^.cursor.v = 22) then
						ScrollChatSide(activeNode, false)
					else
						bCR;
					OutLine(t1, false, -1);
				end
				else if typed = char(8) then
				begin
					backspace(1);
				end
				else if typed = char(13) then
					bCR
				else if typed = char(7) then
					OutChr(char(7))
				else if (typed < char(127)) and (typed > char(31)) or (typed > char(127)) then
				begin
					OutLine(typed, false, -1);
				end;
				if inTwoWayChat and sysopSide and (gBBSwindows[activeNode]^.cursor.v = 12) then
				begin
					ScrollChatSide(activeNode, true);
				end;
				if inTwoWayChat and not sysopSide and (gBBSwindows[activeNode]^.cursor.v = 23) then
				begin
					ScrollChatSide(activeNode, false);
				end;
			end;{ key showing sequence}
		end; {curGlobs}
	end;

	procedure Read_Mail;
		var
			MailNums2, i, b, totEm: integer;
			ts, userNumStr, fromUserStr, titleStr, dateStr: Str255;
			printEmail: emailrec;
			hasUserName: boolean;
			validUserNumber: boolean;
	begin
		with curGlobs^ do
		begin
			FindMyEmail(thisUser.UserNum);
			totEm := GetHandleSize(Handle(myEmailList)) div 2;
			MailNums2 := 0;
			if totEm > 0 then
			begin
				BufferIt(RetInStr(619), true, 2);{## From User                       Subject                       User#   Date}
				BufferIt(RetInStr(620), true, 2);{== =============================== ============================= ===== ========}
				releaseBuffer;
				for i := 1 to totEm do
				begin
					printEmail := theEmail^^[myEmailList^^[i - 1]];
					b := i;
					NumToString(printEmail.fromUser, ts);
					mailNums2 := mailNums2 + 1;
					dateStr := GetDate(printEmail.datesent);
					userNumStr := StringOf(' ' : 5 - length(ts), ts);
					titleStr := printEMail.title;
					if printEmail.FileAttached then
						titleStr := Concat('*FILE* ', titleStr);
					if (length(titleStr) > 29) then
						titleStr[0] := char(29);
					if printEmail.fromUser = TABBYTOID then
					begin
						if curWriting <> nil then
							DisposHandle(Handle(curWriting));
						curWriting := textHand(ReadMessage(printEMail.storedAs, 0, 0));
						if curWriting <> nil then
						begin
							fromUserStr := TakeMsgTop;
							DisposHandle(Handle(curWriting));
							if length(fromUserStr) > 31 then
								fromUserStr[0] := char(31);
						end
						else
							fromUserStr := 'NETWORK';
						userNumStr := '  N/A';
					end
					else
					begin
						validUserNumber := (printEmail.fromUser <= numUserRecs) and (printEmail.fromUser > 0);
						hasUserName := (not printEmail.anonyFrom) or (not thisUser.CantReadAnon) or (thisUser.coSysop);
						if validUserNumber then
						begin
							if (hasUserName) then
								fromUserStr := myUsers^^[printEmail.fromUser - 1].UName
							else
							begin
								fromUserStr := '>UNKNOWN<';
								userNumStr := '  N/A';
							end;
							if myUsers^^[printEmail.fromUser - 1].dltd then
							begin
								fromUserStr := '>>DELETED USER<<';
								userNumStr := '  N/A';
							end;
						end
						else
						begin
							fromUserStr := '>INVALID USER #<';
							userNumStr := '  N/A';
						end;
					end;
					BufferIt(StringOf(mailNums2 : 2, ' '), true, 0);
					BufferIt(StringOf(fromUserStr, ' ' : (32 - Length(fromUserStr))), false, 1);
					BufferIt(StringOf(titleStr, ' ' : (30 - Length(titleStr))), false, 5);
					BufferIt(Concat(userNumStr, ' '), false, 1);
					BufferIt(dateStr, false, 3);
					ReleaseBuffer;
				end;
				BoardSection := ReadMail;
				ReadDo := ReadTwo;
			end
			else
			begin
				OutLine(RetInStr(621), true, 0);	{You have no mail.}
				GoHome;
			end;
		end;
	end;
end.