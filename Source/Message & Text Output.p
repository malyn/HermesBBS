{ Segments: MessNTextOutput_1 }
unit MessNTextOutput;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, NodePrefs2, Message_Editor, Terminal, inpOut4;

	procedure PrintCurMessage (updateQPtrs: boolean);
	procedure PrintCurEMail;
	function isTwoByteScript: boolean;

implementation


{$S MessNTextOutput_1}
	procedure PrintCurMessage (updateQPtrs: boolean);
		var
			tempString, s1, s2, tempString2, tempString3, tempString4, tempString5, posterName, theSize, theTime: str255;
			ref, i: integer;
			tempLong: longInt;
			result: OSerr;
			tempDate: DateTimeRec;
	begin
		with curglobs^ do
		begin
			if curWriting <> nil then
				DisposHandle(handle(curWriting));
			curWriting := nil;
			readMsgs := true;
			lastKeyPressed := tickCount;
			curMesgRec := curBase^^[inMessage - 1];
			if curMesgRec.fromUserNum <> 0 then
			begin
				bCR;
				curwriting := ReadMessage(curmesgrec.storedAs, inForum, inConf);
				mesRead := mesRead + 1;
				if not continuous and not inZscan then
					ClearScreen;
				posterName := curMesgRec.fromUserName;
				if curMesgRec.fromUserNum > 0 then
				begin
					NumToString(curMesgRec.fromUserNum, tempString5);
					posterName := concat(posterName, ' #', tempstring5);
				end;
				if (BoardSection <> MessageSearcher) then
				begin
					NumToString(inMessage, tempString);
					NumToString(curNumMess, tempString2);
				end
				else
				begin
					NumToString(crossInt8 + 1, tempString);
					NumToString(MessageSearch^^.NumFound, tempString2);
				end;
				bufferIt('Subj', false, 4);
				bufferIt(concat(': ', curMesgrec.title), false, 0);
				templong := 71 - (6 + length(curmesgRec.title));
				tempstring3 := '';
				if templong > 0 then
					tempstring3 := stringOf(' ' : tempLong);
				bufferIt(tempstring3, false, 0);
				bufferIt(concat('(', tempstring, '/', tempstring2, ')'), false, 3);
				if ((thisUser.cosysop) or (MConferenceOp(InForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser))) and not curMesgRec.deletable then
				begin
					bufferIt('||||', true, 4);
					bufferIt('> Permanent Message', false, 6);
					if thisUser.TerminalType = 1 then
						bufferIt('', false, 0);
				end;
				tempstring3 := takeMsgTop;		{Date Time Sequence}
				bufferIt('From', true, 4);
				wasAnonymous := false;
				if (curMesgRec.anonyFrom) then
					wasAnonymous := true;
				if (curMesgRec.anonyFrom) and (thisUser.CantReadAnon) then
					bufferIt(': >UNKNOWN<', false, 0)
				else
				begin
					if (MConference[inForum]^^[inConf].ConfType = 0) and (tempString3[1] > '@') then
					begin
						if (curmesgRec.fromUserNum <> 0) and (curMesgRec.fromuserNum <= numUserRecs) then
						begin
							if (curMesgRec.anonyFrom) and (not thisUser.CantReadAnon) then
								tempString := concat(': <<<', posterName, '>>> ')
							else if ((thisUser.coSysOp) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser))) and newHand^^.handle and newHand^^.realname and (myusers^^[curMesgRec.fromUserNum - 1].real <> '•') then
								tempString := concat(': ', posterName, ' [ ', myUsers^^[curMesgRec.fromUserNum - 1].real, ' ]')
							else if (not newHand^^.handle) and (MConference[inForum]^^[inConf].ShowCity) and (myUsers^^[curMesgRec.fromUserNum - 1].city <> '•') then
								tempString := stringOf(': ', posterName, ' ' : 40 - length(postername), myUsers^^[curMesgRec.fromuserNum - 1].City, ', ', myUsers^^[curMesgRec.fromuserNum - 1].State)
							else if ((thisUser.coSysop) or (MConferenceOp(InForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser))) and not newHand^^.handle and newhand^^.realname and ((myUsers^^[curMesgRec.fromUserNum - 1].state <> '•') and (myUsers^^[curMesgRec.fromUserNum - 1].city <> '•')) then
								tempString := concat(': ', posterName, ' [ ', myUsers^^[curMesgRec.fromUserNum - 1].city, ', ', myUsers^^[curMesgRec.fromUserNum - 1].state, ' ]')
							else
								tempstring := concat(': ', posterName);
							bufferIt(tempString, false, 0);
						end
						else
							bufferIt(': <<USER NOT FOUND>>', false, 0);
					end
					else
					begin
						if FindUser(curMesgRec.fromUserName, tempuser) then
							NumToString(tempUser.userNum, tempstring)
						else
							tempstring := '';
						if length(tempstring) > 0 then
						begin
							if (not newHand^^.handle) and (MConference[inForum]^^[inConf].ShowCity) and (myUsers^^[tempUser.UserNum - 1].city <> '•') then
								tempString := StringOf(': ', curMesgRec.fromUserName, ' #', tempString, ' ' : 40 - (length(curMesgRec.fromUserName)), ' ', myUsers^^[tempUser.UserNum - 1].City, ', ', myUsers^^[tempUser.UserNum - 1].State)
							else if ((thisUser.coSysop) or (MConferenceOp(InForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser))) and not newHand^^.handle and newhand^^.realname and ((myUsers^^[tempUser.UserNum - 1].state <> '•') and (myUsers^^[tempUser.UserNum - 1].city <> '•')) then
								tempString := concat(': ', curMesgRec.fromUserName, ' #', tempString, ' [ ', myUsers^^[tempUser.UserNum - 1].City, ', ', myUsers^^[tempUser.UserNum - 1].State, ' ]')
							else
								tempString := concat(': ', curMesgRec.fromUserName, ' #', tempString);
							bufferIt(tempString, false, 0);
						end
						else
							bufferIt(concat(': ', curMesgRec.fromUserName), false, 0);
					end;
				end;
				if MConference[inForum]^^[inConf].Threading then
				begin
					NumToString(curMesgrec.touserNum, tempString5);
					bufferIt('To  ', true, 4);
					if not curMesgRec.anonyTo then
					begin
						if curMesgRec.toUserNum > 0 then
							bufferIt(concat(': ', curMesgrec.toUserName, ' #', tempstring5), false, 0)
						else if curMesgRec.toUserNum = TABBYTOID then
							bufferIt(concat(': ', curMesgrec.toUserName), false, 0)
						else
							bufferIt(': All', false, 0);
					end
					else
						bufferIt(concat(': >UNKNOWN<'), false, 0);
				end;
				if (curMesgRec.anonyFrom) and (thisUser.CantReadAnon) then
					tempString3 := '>>>INACTIVE<<<';
				bufferIt('Date', true, 4);
				bufferIt(stringOf(': ', tempString3, '  '), false, 0);
				if (MConference[inForum]^^[inConf].ConfType <> 0) and ((tempString3[1] >= '0') and (tempString3[1] <= '9')) then
				begin
					tempString3 := concat(GetDate(curMesgRec.DateEn), ' ', whatTime(curMesgRec.DateEn));
					bufferIt('Imported', false, 4);
					bufferIt(concat(': ', tempString3), false, 0);
				end;

				WasAttach := false;
				WasAttachMac := true;
				AttachFName := char(0);
				if (curMesgRec.FileAttached) then
				begin
					WasAttach := true;
					AttachFName := curMesgRec.FileName;
					WasAttachMac := curMesgRec.isAMacFile;

					for i := 1 to forumIdx^^.numDirs[0] do
						if (forums^^[0].dr[i].DirName = 'Message Attachments') then
							tempSubDir := i;
					tempInDir := 0;
					theSize := char(0);
					theTime := char(0);
					if OpenDirectory(tempInDir, tempSubDir) then
					begin
						curDirPos := 0;
						allDirSearch := false;
						descSearch := false;
						fileMask := concat(AttachFName, '*');
						GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
						if curFil.flName <> '' then
						begin
							if curFil.byteLen = -1 then
								theSize := '<FILE IS OFFLINE>'
							else
								theSize := concat(doNumber(curFil.byteLen div 1024), 'k');
							if (currentBaud <> 0) and (nodeType = 1) then
								tempLong := curFil.bytelen div (modemDrivers^^[modemID].rs[rsIndex].effRate div 10)
							else
								tempLong := 0;
							theTime := Secs2Time(tempLong);
							theTime := concat(TheTime, ' to download.');
						end;
					end;

					tempString := concat('FILE ATTACHMENT: ', curMesgRec.FileName, ' - ', theSize, ' - ', theTime);
					bufferIt(tempString, true, 4);
				end;

			end;
			if updateQPtrs then
				if (curmesgRec.DateEn > thisuser.lastMsgs[inforum, inConf]) and not threadmode then
					thisuser.lastmsgs[inforum, inConf] := curmesgRec.DateEn;
			bufferbCR;
			bufferbCR;
			Releasebuffer;
			if textHnd <> nil then
				disposHandle(handle(texthnd));
			texthnd := nil;
			textHnd := texthand(curWriting);
			curWriting := nil;
			if textHnd <> nil then
			begin
				scanFile(textHnd);
				curtextPos := 0;
				openTextSize := GetHandleSize(handle(texthnd));
				BoardAction := ListText;
			end
			else
				OutLine('Message not found.', true, 0);
		end;
	end;

	procedure PrintCurEMail;
		var
			tempString, tempString2, tempString3, tempString4, tempString5: str255;
			tempDate: DateTimeRec;
			totEm, numit: integer;
			printMail: EmailRec;
	begin
		with curglobs^ do
		begin
			FindMyEmail(thisUser.UserNum);
			totEm := GetHandleSize(handle(myEmailList)) div 2;
			if atEmail >= totem then
				atEmail := totem - 1;
			if atEmail < 0 then
				atEmail := 0;
			if totEm > 0 then
			begin
				printMail := theEmail^^[myEmailList^^[atEmail]];
				bCR;
				if textHnd <> nil then
					DisposHandle(handle(texthnd));
				textHnd := nil;
				textHnd := textHand(ReadMessage(printMail.storedAs, 0, 0));
				if textHnd <> nil then
					scanFile(textHnd);
				tempString3 := StringOf('(', AtEmail + 1 : 0, '/', TotEm : 0, '): ', printMail.title);
				bufferIt(tempString3, true, 0);
				wasAnonymous := false;
				if (printMail.anonyFrom) then
					wasAnonymous := true;
				if (printMail.anonyFrom) and not (thisUser.coSysop) then
				begin
					bufferIt('Name: >UNKNOWN<', true, 0);
					tempUser.UserName := '???';
				end
				else
				begin
					if not ((mailer^^.MailerAware) and (printMail.fromUser = TABBYTOID)) then
					begin
						NumToString(printMail.fromUser, tempString2);
						if FindUser(tempString2, tempUser) then
						begin
							NumToString(tempUser.UserNum, tempString3);
							if (printMail.anonyFrom) and ((thisUser.coSysop) or (thisUser.CantReadAnon)) then
								tempString := concat('Name: <<<', tempuser.UserName, ' #', tempString3, '>>>')
							else if (thisUser.coSysop and newHand^^.handle) then
								tempString := concat('Name: ', tempuser.UserName, ' #', tempString3, ' [ ', tempUser.realName, ' ]')
							else if (thisUser.coSysOp and newHand^^.realname) then
								tempString := concat('Name: ', tempUser.UserName, ' #', tempString3, ' [ ', tempUser.City, ', ', tempUser.State, ' ] ')
							else
								tempString := concat('Name: ', tempuser.UserName, ' #', tempString3);
							bufferIt(tempString, true, 0);
						end
						else
							bufferIt('Name: <<USER NOT FOUND>>', true, 0);
					end
					else
					begin
						curWriting := TextHand(textHnd);
						tempstring5 := takeMsgTop;
						textHnd := textHand(curWriting);
						curWriting := nil;
						if FindUser(tempstring5, tempUser) then
							NumToString(tempuser.userNum, tempstring3)
						else
							tempstring3 := '';
						if length(tempstring3) > 0 then
							tempstring3 := concat(' #', tempstring3);
						bufferIt(concat('Name: ', tempstring5, tempstring3), true, 0);
					end;
				end;
				IUDateString(printMail.dateSent, abbrevDate, tempstring3);
				IUTimeString(printMail.dateSent, true, tempstring2);
				if (printMail.anonyFrom) and not (thisUser.coSysop) then
					tempstring := 'Date: >>INACTIVE<<'
				else
					tempString := concat('Date: ', tempString3, ' ', tempString2);
				bufferIt(tempString, true, 0);
				isMM := false;
				if (printMail.multiMail) then
					isMM := true;
				WasAttach := false;
				WasAttachMac := true;
				AttachFName := char(0);
				if (printMail.FileAttached) then
				begin
					WasAttach := true;
					AttachFName := printMail.FileName;
					WasAttachMac := printMail.isAMacFile;
					tempString := concat('FILE ATTACHMENT: ', printMail.FileName);
					bufferIt(tempString, true, 0);
				end;
				bufferbCR;
				Releasebuffer;
				if textHnd <> nil then
				begin
					curtextPos := 0;
					openTextSize := GetHandleSize(handle(texthnd));
					BoardAction := ListText;
					ListTextFile;
				end
				else
					OutLine('Message not found.', true, 0);
			end;
		end;
	end;

	function MySWRoutineAvailable (trapWord: Integer): Boolean;
		const
			_Unimplemented = $A89F;
		var
			trType: TrapType;
	begin
	{first determine whether it is an Operating System or Toolbox routine}
		if ORD(BAND(trapWord, $0800)) = 0 then
			trType := OSTrap
		else
			trType := ToolTrap;
	{filter cases where older systems mask with $1FF rather than $3FF}
		if (trType = ToolTrap) and (ORD(BAND(trapWord, $03FF)) >= $200) and (GetToolboxTrapAddress($A86E) = GetToolboxTrapAddress($AA6E)) then
			MySWRoutineAvailable := FALSE
		else
			MySWRoutineAvailable := (NGetTrapAddress(trapWord, trType) <> GetToolboxTrapAddress(_Unimplemented));
	end;

	function GetScriptManagerVariable (selector: INTEGER): LONGINT;
	inline
		$2F3C, $8402, $0008, $A8B5;

	function isTwoByteScript: boolean;
		const
			_Gestalt = $A1AD;

			gestaltScriptMgrVersion = 'scri';

			smSysScript = 18;											{System script}
			smRoman = 0;							{Roman}
			smJapanese = 1;					{Japanese}
			smTradChinese = 2;				{Traditional Chinese}
			smKorean = 3;						{Korean}
			smSimpChinese = 25;							{Simplified Chinese}
		var
			selectorValue: longint;
			ScriptMgrVersion: longint;
			result: OSErr;
	begin
		isTwoByteScript := false;
		if MySWRoutineAvailable(_Gestalt) then
		begin
			result := Gestalt(gestaltScriptMgrVersion, ScriptMgrVersion);
			if (result = noErr) and (ScriptMgrVersion > $0000) then
			begin
				selectorValue := GetScriptManagerVariable(smSysScript);
				if (selectorValue = smJapanese) or (selectorValue = smTradChinese) or (selectorValue = smKorean) or (selectorValue = smSimpChinese) then
					isTwoByteScript := true;
			end;
		end;
	end;



end.