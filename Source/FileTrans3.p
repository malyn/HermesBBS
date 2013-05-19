{ Segments: FileTrans3_1 }
unit FIleTrans3;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, Initial, Misc2, InpOut4, InpOut3, ChatroomUtils, nodeprefs, nodeprefs2, inpOut2, InpOut, User, SystemPrefs, Message_Editor, terminal;

	procedure DoNodeStuff;
	procedure DoRename;
	function DLRatioOK: boolean;
	function PrintFileInfo (theFl: filEntryRec; fromDir, fromSubDir: integer; doOther: boolean): integer;
	procedure printDirList (prompt: Boolean);
	procedure printSubDirList (whichDir: Integer);
	procedure PrintUserStuff;
	procedure PrintConfList (whichFor: integer);
	procedure printForumList;
	procedure MultiChatOut (whatstring: str255; header: boolean);
	procedure PrintTree;
	function FindConference (whichFor, Selected: integer): integer;
	function FigureDisplayConf (whichFor, theConf: integer): integer;
	procedure DoSlowDevice;
	procedure RemoveSlowDeviceFiles;
	function PrintFormLetters: integer;

implementation

{$S FileTrans3_1}
	procedure RemoveSlowDeviceFiles;
		var
			result, errorCode: OSErr;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			outRefNum, tempInt, index, i: integer;
			fName: str255;
			tempLong: longint;
			TheFiles: array[1..99] of string[31];
	begin
		result := FSOpen(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':?xxNONAMEFILExx?'), 0, outRefNum);
		if result = -43 then {File not found}
		begin
			result := FSClose(outRefNum);
			fName := StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':');
			myHPB.ioCompletion := nil;
			myHPB.ioNamePtr := @fName;
			myHPB.ioVRefNum := 0;
			myHPB.ioVolIndex := -1;
			result := PBHGetVInfo(@myHPB, false);
			fName := StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':');
			myCPB.ioCompletion := nil;
			myCPB.ioNamePtr := @fname;
			myCPB.ioVRefNum := myHPB.ioVRefNum;
			myCPB.ioFDirIndex := 0;
			result := PBGetCatInfo(@myCPB, false);
			myCPB.ioNamePtr := @fName;
			tempLong := myCPB.ioDrDirID;
			tempInt := myHPB.ioVRefNum;
			index := 1;
			repeat
				FName := '';
				myCPB.ioFDirIndex := index;
				myCPB.ioDrDirID := tempLong;
				myCPB.ioVrefNum := tempInt;
				result := PBGetCatInfo(@myCPB, FALSE);
				if result = noErr then
				begin
					TheFiles[index] := fName;
					index := index + 1;
				end;
			until (result <> noErr);
			index := index - 1;
			if index > 0 then
				for i := 1 to index do
					errorCode := FSDelete(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', TheFiles[i]), 0);

			errorCode := FSDelete(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0), 0);
		end;
	end;

	procedure DoSlowDevice;
		const
			MaxBuff = 32000;
		var
			i, inRefNum, outRefNum: integer;
			errorCode: OSErr;
			inputFlInfo: FInfo;
			fileSize, tempLong: longint;
	begin
		with curGlobs^ do
		begin
			case SlowDo of
				SlowOne: (* Check Non Batch File X-Fer *)
				begin
					if forums^^[tempInDir].dr[tempSubDir].SlowVolume then
					begin
						OutLine(RetInStr(140), true, 2);
						SlowDo := SlowThree;
					end
					else
					begin
						BoardSection := Download;
						DownDo := DownSix;
					end;
				end;
				SlowTwo: (* Check Batch File X-Fer *)
				begin
					crossint9 := crossint9 + 1;
					if crossint9 > fileTransit^^.numFiles then
					begin
						BoardSection := Batch;
						BatDo := BatFive;
					end
					else
					begin
						tempInDir := fileTransit^^.filesGoing[crossint9].fromDir;
						tempSubDir := fileTransit^^.filesGoing[crossint9].fromSub;
						if forums^^[tempInDir].dr[tempSubDir].SlowVolume then
						begin
							CurFil := fileTransit^^.filesGoing[crossint9].theFile;
							SlowDo := SlowThree;
							if crossint1 = -99 then
							begin
								OutLine(RetInStr(140), true, 2);
								crossint1 := 0;
							end;
						end;
					end;
				end;
				SlowThree: (* Setup Copy *)
				begin
					if (pos(':', curFil.realFName) = 0) then
						enteredPass2 := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFName)
					else
						enteredPass2 := curFil.realFName;
					errorCode := FSOpen(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, outRefNum);
					if errorCode <> noErr then
					begin
						errorCode := GetFInfo(enteredpass2, 0, inputFlInfo);
						errorCode := Create(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, inputFlInfo.fdCreator, inputFlInfo.fdType);
						if errorCode = -120 then
						begin
							errorCode := DirCreate(0, 0, StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0), templong);
							errorCode := makeADir(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0));
{errorCode := Create(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, inputFlInfo.fdCreator, inputFlInfo.fdType);}
						end
						else
							result := FSDelete(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0);
						result := copy1File(enteredPass2, StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', curFil.flName));
						if result <> noErr then
							sysbeep(0);

{SlowDo := SlowFour;}

{inputFlInfo.fdLocation := Point($00000000);}
{inputFlInfo.fdFldr := 0;}
{inputFlInfo.fdFlags := BAND(inputFlInfo.fdFlags, $F8FE);}
 {mask out desktop,inited,changed,busy}
{errorCode := SetFInfo(concat(sharedPath, 'Slow Files:', CurFil.flName), 0, inputFlInfo);}
					end;
					fileTransit^^.filesGoing[crossint9].theFile.realFName := StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', curFil.flName);
{else}
{begin}
{result := FSClose(outRefNum);}
					if wasBatch then
						SlowDo := SlowTwo
					else
					begin
						BoardSection := Download;
						DownDo := DownSix;
					end;
{end;}
				end;
				SlowFour: (* Setup Data Fork Copy *)
				begin
					with myBlocker do
					begin
						ioCompletion := nil;			{ no follow-on routine				}
						ioNamePtr := @enteredPass2;	{ pointer to path:file name	}
						ioVRefNum := 0;					{ dummy volume number		}
						ioVersNum := 0;					{ version always = 0				}
						ioPermssn := fsRdPerm;	{ request read-only					}
						ioMisc := nil;						{ use volume i/o buffer			}
					end; {with}
					errorCode := PBOpen(@myBlocker, false);		{ data fork }
					inRefNum := myBlocker.ioRefNum;	{ success so far, remember the file's refNum }
					dataBuffer := NewPtr(MaxBuff);
					errorCode := MemError;
					if errorCode <> noErr then
					begin
						LogError(concat(WhatTime(-1), ' Low on memory unable to copy file for slow device.'), true, 1);
						disposPtr(dataBuffer);
						errorCode := FSClose(inRefNum);
						if wasBatch then
							SlowDo := SlowTwo
						else
						begin
							BoardSection := Download;
							DownDo := DownSix;
						end;
					end
					else
					begin
						errorCode := FSOpen(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, outRefNum);
						errorCode := SetFPos(outRefNum, fsFromLEOF, 0);
						errorCode := GetEOF(inRefNum, filesize);
						errorCode := Allocate(outRefNum, fileSize);
						crossint8 := (fileSize + MaxBuff - 1) div MaxBuff;	{Number of Blocks}
						crossLong := MaxBuff;			{Bytes to Read}
						crossint6 := 0;						{Counter}
						SlowDo := SlowFive;
					end;
				end;
				SlowFive: (* Copy Data Fork *)
				begin
					crossint6 := crossint6 + 1;
					if crossint6 > crossint8 then
					begin
						SlowDo := SlowSix;
					end
					else
					begin
						with myBlocker do
						begin
							ioCompletion := nil;			{ no follow-on routine				}
							ioNamePtr := @enteredPass2;	{ pointer to path:file name	}
							ioVRefNum := 0;					{ dummy volume number		}
							ioVersNum := 0;					{ version always = 0				}
							ioPermssn := fsRdPerm;	{ request read-only					}
							ioMisc := nil;						{ use volume i/o buffer			}
						end; {with}
						errorCode := PBOpen(@myBlocker, false);		{ data fork }
						inRefNum := myBlocker.ioRefNum;	{ success so far, remember the file's refNum }
						result := SetFPos(inRefNum, fsFromLEOF, 0);
						errorCode := FSOpen(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, outRefNum);
						errorCode := SetFPos(outRefNum, fsFromLEOF, 0);
						errorCode := FSRead(inRefNum, crossLong, dataBuffer);
						errorCode := FSWrite(outRefNum, crossLong, dataBuffer);
						result := FSClose(inRefNum);
						result := FSClose(outRefNum);
					end;
				end;
				SlowSix: (* Setup Resource Fork Copy *)
				begin
					with myBlocker do
					begin
						ioCompletion := nil;			{ no follow-on routine				}
						ioNamePtr := @enteredPass2;	{ pointer to path:file name	}
						ioVRefNum := 0;					{ dummy volume number		}
						ioVersNum := 0;					{ version always = 0				}
						ioPermssn := fsRdPerm;	{ request read-only					}
						ioMisc := nil;						{ use volume i/o buffer			}
					end; {with}
					errorCode := PBOpenRF(@myBlocker, false);
					inRefNum := myBlocker.ioRefNum;
					errorCode := OpenRF(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, outRefNum);
					errorCode := SetFPos(outRefNum, fsFromLEOF, 0);
					errorCode := GetEOF(inRefNum, filesize);
					errorCode := Allocate(outRefNum, fileSize);
					crossint8 := (fileSize + MaxBuff - 1) div MaxBuff;	{Number of Blocks}
					crossLong := MaxBuff;			{Bytes to Read}
					crossint6 := 0;						{Counter}
					SlowDo := SlowSeven;
				end;
				SlowSeven: (* Copy Resource Fork *)
				begin
					crossint6 := crossint6 + 1;
					if crossint6 > crossint8 then
					begin
						disposPtr(dataBuffer);
						if wasBatch then
							SlowDo := SlowTwo
						else
						begin
							BoardSection := Download;
							DownDo := DownSix;
						end;
					end
					else
					begin
						with myBlocker do
						begin
							ioCompletion := nil;			{ no follow-on routine				}
							ioNamePtr := @enteredPass2;	{ pointer to path:file name	}
							ioVRefNum := 0;					{ dummy volume number		}
							ioVersNum := 0;					{ version always = 0				}
							ioPermssn := fsRdPerm;	{ request read-only					}
							ioMisc := nil;						{ use volume i/o buffer			}
						end; {with}
						errorCode := PBOpenRF(@myBlocker, false);		{ data fork }
						inRefNum := myBlocker.ioRefNum;	{ success so far, remember the file's refNum }
						result := SetFPos(inRefNum, fsFromLEOF, 0);
						errorCode := OpenRF(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, outRefNum);
						errorCode := SetFPos(outRefNum, fsFromLEOF, 0);
						errorCode := FSRead(inRefNum, crossLong, dataBuffer);
						errorCode := FSWrite(outRefNum, crossLong, dataBuffer);
						result := FSClose(inRefNum);
						result := FSClose(outRefNum);
					end;
				end;
			end; (* End Case *)
		end;
	end;

	function PrintFormLetters: integer;
		var
			fName: str255;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			index, i, x, y, z, n2: integer;
			BColor, YColor: str255;
			TheList: array[1..99] of string[47];
			Holder: array[1..99] of string[31];
	begin
		with curglobs^ do
		begin
			fName := concat(sharedPath, 'Forms:');
			myHPB.ioCompletion := nil;
			myHPB.ioNamePtr := @fName;
			myHPB.ioVRefNum := 0;
			myHPB.ioVolIndex := -1;
			result := PBHGetVInfo(@myHPB, false);
			fName := concat(sharedPath, 'Forms:');
			myCPB.ioCompletion := nil;
			myCPB.ioNamePtr := @fname;
			myCPB.ioVRefNum := myHPB.ioVRefNum;
			myCPB.ioFDirIndex := 0;
			result := PBGetCatInfo(@myCPB, false);
			myCPB.ioNamePtr := @fName;
			crossLong := myCPB.ioDrDirID;
			crossInt2 := myHPB.ioVRefNum;
			index := 1;
			n2 := 0;
			repeat
				FName := '';
				myCPB.ioFDirIndex := index;
				myCPB.ioDrDirID := crossLong;
				myCPB.ioVrefNum := crossInt2;
				result := PBGetCatInfo(@myCPB, FALSE);
				if result = noErr then
				begin
					if (index = 99) then
						result := 1;
					n2 := n2 + 1;
					Holder[index] := fName;
				end;
				index := index + 1;
			until (result <> noErr);
			OutLine(RetInStr(303), true, 2);	{Available Form Letters:}
			bCR;
			if (thisUser.TerminalType = 1) then
			begin
				BColor := concat(char(27), '[0;36;40m');
				YColor := concat(char(27), '[0;33;40m');
			end
			else
			begin
				BColor := char(0);
				YColor := char(0);
			end;
			x := n2;
			if (thisUser.columns) and (index > 5) then
			begin
				y := -1;
				z := 0;
				if (x < 99) then
					TheList[x + 1] := char(0);
				if (not odd(x)) then
					x := x - 1;
				for i := 1 to n2 do
				begin
					if y >= x then
						y := 0;
					y := y + 2;
					z := z + 1;
					if z < 10 then
						TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, Holder[i], '                                                ')
					else
						TheList[y] := StringOf(YColor, z : 0, '. ', BColor, Holder[i], '                                                ');
					if (thisUser.TerminalType = 0) or (not thisUser.ColorTerminal) then
						TheList[y][0] := char(39);
				end;
				z := 1;
				x := x + 1;
				repeat
					OutLine(concat(TheList[z], '  ', TheList[z + 1]), true, -1);
					z := z + 2;
				until z >= x;
				if odd(x) then
					OutLine(TheList[x], true, -1);
			end
			else
			begin
				x := 0;
				for i := 1 to n2 do
				begin
					x := x + 1;
					OutLine(StringOf(x : 2, '. '), true, 2);
					OutLine(Holder[i], false, 1);
				end;
			end;
			bCR;
			bCR;
			PrintFormLetters := index;
		end;
	end;

	procedure PrintTree;
		var
			i: integer;
			templong: longint;
	begin
		with curglobs^ do
		begin
			case crossint9 of
				0: 
				begin
					OutLine(RetInStr(643), true, 0);	{Available Areas And Directories:}
					bCR;
					if forumOk(0) then
					begin
						crossint4 := -1; {c}
						crossint5 := 0;	{x}
					end
					else
					begin
						crossint4 := 0;
						crossint5 := 1;
					end;
					crossint9 := 1;
				end;
				1: 
				begin
					crossint4 := crossint4 + 1;
					if (crossint4 = forumIdx^^.numforums) then
						crossint9 := 99
					else if (forumOk(crossint4)) then
					begin
						OutLine(stringOf(crossint5 : 2, ': ', forumIdx^^.name[crossint4]), true, 2);
						bCR;
						crossint6 := 0;
						crossint7 := 0;
						enteredPass2 := '';
						crossint5 := crossint5 + 1;
						crossint9 := 2;
					end;
				end;
				2: 
				begin
					crossint6 := crossint6 + 1;
					if (crossint6 > forumIdx^^.numDirs[crossint4]) then
						if crossint7 > 0 then
							crossint9 := 3
						else
						begin
							OutLine('No sub-directories available.', true, 1);
							crossint9 := 1;
						end
					else if (SubDirOk(crossint4, crossint6)) then
					begin
						crossint7 := crossint7 + 1;
						enteredPass2[crossint7] := char(crossint6);
					end;
				end;
				3: 
				begin
					if (thisUser.Columns) then
					begin
						if odd(crossint7) then
							templong := (crossint7 + 1) div 2
						else
							templong := crossint7 div 2;
						for i := 1 to templong do
						begin
							OutLine(StringOf(i : 7, '. '), true, 2);
							OutLine(stringOf(copy(forums^^[crossint4].dr[ord(enteredPass2[i])].dirName, 1, 36), ' ' : 38 - Length(forums^^[crossint4].dr[ord(enteredPass2[i])].dirName)), false, 1);

							if (odd(crossint7)) and (i = templong) then
								leave;

							OutLine(StringOf(i + templong : 2, '. '), false, 2);
							OutLine(copy(forums^^[crossint4].dr[ord(enteredPass2[i]) + templong].dirName, 1, 36), false, 1);
						end;
					end
					else
					begin
						for i := 1 to crossint7 do
						begin
							OutLine(StringOf(i : 2, '. '), true, 2);
							OutLine(forums^^[crossint4].dr[ord(enteredPass2[i])].dirName, false, 1);
						end;
					end;
					bCR;
					crossint9 := 1;
				end;
				99: 
					GoHome;
				otherwise
			end;
		end;
	end;

	procedure MultiChatOut (whatstring: str255; header: boolean);
		var
			savedNode, i: integer;
			t1, t2: str255;
			mySavedBD: BDact;
	begin
		for i := 1 to InitSystHand^^.numNodes do
		begin
			if (theNodes[i]^.BoardMode = User) and (theNodes[i]^.BoardSection = MultiChat) and (i <> activeNode) then
			begin
				curGlobs := theNodes[i];
				savedNode := activeNode;
				activeNode := i;
				with curglobs^ do
				begin
					mySavedBD := BoardAction;
					BoardAction := none;
					if thisUser.TerminalType = 1 then
					begin
						NumToString(gBBSwindows[activeNode]^.cursor.h + 1, t1);
						ANSICode(concat(t1, 'D'));
						ANSICode('K');
					end
					else
						bCR;
					if header then
					begin
						OutLine(concat(theNodes[savedNode]^.thisUser.UserName, ':'), false, 2);
						excess := '';
						OutLine(whatString, false, 0);
					end
					else
						OutLine(whatString, false, 2);
					BoardAction := mySavedBD;
					if prompting then
					begin
						bCR;
						ReprintPrompt;
					end;
				end;
				curGlobs := theNodes[savedNode];
				activeNode := savedNode;
			end;
		end;
	end;

	procedure DoNodeStuff;
		var
			tempLong: Longint;
			savedNode, i, b: integer;
			mySavedBD: BDact;
			te1, te2, te3: str255;
	begin
		with curglobs^ do
		begin
			case NodeDo of
				NodeOne: 
				begin
					NodeDo := NodeTwo;
					bCR;
					bCR;
					helpNum := 18;
					DoShowUserActivity;
					bCR;
					bCR;
					if thisUser.coSysop and (thisUser.SL = 255) then
						LettersPrompt(RetInStr(411), 'CSDQ', 1, true, false, true, char(0)) {Nodes: L:ist, M:essage, C:hat, S:py, D:isconnect, Q:uit : }
					else
						LettersPrompt(RetInStr(412), 'CQ', 1, true, false, true, char(0))  {Nodes: L:ist, M:essage, C:hat, Q:uit : }
				end;
				NodeTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						case curPrompt[1] of
							'Q': 
								GoHome;
							'C': 
							begin
{BoardSection := MultiChat;}
{MultiChatDo := Mult1;}
{OutLine(RetInStr(413), true, 1);	Entering chat room...}
{OutLine(RetInStr(414), true, 1);	Type ''/X'' to exit, and ''/H'' for help.}
{bCR;}
{NumToString(thisUser.userNum, te1);}
{MultiChatOut(concat(thisUser.userName, ' #', te1, ' is here.'), false);}
{curPrompt := '';}
{excess := '';}
								BoardSection := Chatroom;
								ChatRoomDo := EnterMain;
							end;
							'D': 
							begin
								NodeDo := NodeSeven;
								NumbersPrompt(RetInStr(416), '', InitSystHand^^.numNodes, 1);	{Disconnect which node? }
							end;
							'S': 
							begin
								if spying = 0 then
								begin
									NodeDo := NodeFive;
									NumbersPrompt(RetInStr(417), '', InitSystHand^^.numNodes, 1);	{Spy on which node? }
								end
								else
									NodeDo := NodeOne;
							end;
							otherwise
								NodeDo := NodeOne;
						end;
					end
					else
						NodeDo := NodeOne;
				end;
				NodeThree: 
				begin
				end;
				NodeFour: 
				begin
				end;
				NodeSix: 
				begin
					if aborted then
					begin
						OutLine(RetInStr(420), true, 1);	{Exiting spy mode...}
						NodeDo := NodeOne;
						theNodes[crossInt]^.spying := 0;
						if myQuote.wasSeg then
							thisUser.PauseScreen := true;
						myQuote.wasSeg := false;
						amSpying := false;
					end;
				end;
				nodeSeven: 
				begin
					if length(curprompt) > 0 then
					begin
						StringToNum(curPrompt, tempLong);
						crossInt := tempLong;
						if (crossInt <> activeNode) and (crossInt <= InitSystHand^^.numNodes) and (crossInt > 0) then
						begin
							if (theNodes[crossInt]^.boardMode = user) then
							begin
								savedNode := activeNode;
								curGlobs := theNodes[crossInt];
								activeNode := crossInt;
								with curGlobs^ do
								begin
									if myTrans.active then
									begin
										extTrans^^.flags[carrierLoss] := true;
										ClearInBuf;
										repeat
											ContinueTrans;
										until not myTrans.active;
									end;
									if (thisUser.userNum) > 0 then
										sysopLog('      Logged off from remote.', 6);
									HangupAndReset;
								end;
								activeNode := savedNode;
								curGlobs := theNodes[savedNode];
								OutLine('Node disconnected.', true, 0);
								NodeDo := NodeOne;
							end
							else if (theNodes[crossInt]^.boardMode = failed) then
							begin
								OutLine(RetInStr(421), true, 0);{Re-initializing stalled node.}
								savedNode := activeNode;
								curGlobs := theNodes[crossInt];
								activeNode := crossInt;
								HangUpAndReset;
								activeNode := savedNode;
								curGlobs := theNodes[savedNode];
							end
							else
							begin
								OutLine(RetInStr(422), true, 0);	{Inactive node.}
								NodeDo := NodeOne;
							end;
						end
						else
						begin
							OutLine(RetInStr(423), true, 0);	{Invalid Node.}
							NodeDo := NodeOne;
						end;
					end
					else
						NodeDo := NodeOne;
				end;
				nodeFive: 
				begin
					if length(curprompt) > 0 then
					begin
						StringToNum(curPrompt, tempLong);
						crossInt := tempLong;
						if (crossInt <> activeNode) and (crossInt <= InitSystHand^^.numNodes) and (crossInt > 0) then
						begin
							if (theNodes[crossInt]^.boardMode = user) and (theNodes[crossInt]^.thisUser.userNum > 0) then
							begin
								if not (theNodes[crossInt]^.myTrans.active) then
								begin
									if not (theNodes[crossInt]^.spying > 0) then
									begin
										OutLine(RetInStr(424), true, 1);	{Entering spy mode, ^X to exit...}
										bCR;
										if thisUser.TerminalType = 1 then
											dom(0);
										myQuote.wasSeg := false;
										if thisUser.PauseScreen then
										begin
											thisUser.PauseScreen := false;
											myQuote.wasSeg := true;
										end;
										amSpying := true;
										theNodes[crossInt]^.spying := activeNode;
										NodeDo := NodeSix;
										BoardAction := Repeating;
									end
									else
									begin
										OutLine(RetInStr(425), true, 0);	{That node is being spied on already.}
										NodeDo := NodeOne;
									end;
								end
								else
								begin
									OutLine(RetInStr(426), true, 0); {That user is engaged in a file transfer.}
									NodeDo := NodeOne;
								end;
							end
							else
							begin
								OutLine(RetInStr(422), true, 0);
								NodeDo := NodeOne;
							end;
						end
						else
						begin
							OutLine(RetInStr(423), true, 0);
							NodeDo := NodeOne;
						end;
					end
					else
						NodeDo := NodeOne;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoRename;
		var
			tempString, t2: str255;
			tempInt, savedDirPos: integer;
	begin
		with curglobs^ do
		begin
			case RenDo of
				renOne: 
				begin
					descSearch := false;
					bCR;
					LettersPrompt(RetInStr(441), '', forums^^[InRealDir].dr[InRealSubDir].fileNameLength, false, false, false, char(0));		{File to rename: }
					ANSIPrompter(forums^^[InRealDir].dr[InRealSubDir].fileNameLength);
					RenDo := RenTwo;
				end;
				renTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						curDirPos := 0;
						if OpenDirectory(InRealDir, InRealSubDir) then
						begin
							RenDo := RenThree;
							tempInDir := inRealDir;
							tempSubDir := InRealSubDir;
							fileMask := curPrompt;
						end
						else
						begin
							OutLine(RetInStr(59), true, 0);
							GoHome;
						end;
					end
					else
						GoHome;
				end;
				RenThree: 
				begin
					GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
					if curFil.flName <> '' then
					begin
						if PrintFileInfo(curFil, tempInDir, tempSubDir, false) = 0 then
							;
						RenDo := RenFour;
					end
					else
						GoHome;
				end;
				RenFour: 
				begin
					bCR;
					bCR;
					LettersPrompt(RetInStr(442), 'YNQ', 1, true, false, true, char(0));	{Change info for this file (Y/N/Q)? }
					RenDo := RenFive;
				end;
				RenFive: 
				begin
					if curPrompt = 'Y' then
					begin
						LettersPrompt(RetInStr(443), '', forums^^[inRealDir].dr[InRealSubDir].fileNameLength, false, false, false, char(0));	{New filename? }
						ANSIPrompter(forums^^[inRealDir].dr[InRealSubDir].fileNameLength);
						RenDo := RenSix;
					end
					else if (curPrompt = 'Q') then
						goHome
					else
						RenDo := RenThree;
				end;
				RenSix: 
				begin
					if length(curPrompt) > 0 then
					begin
						t2 := forums^^[tempInDir].dr[tempSubDir].path;
						if not FExist(concat(t2, curPrompt)) then
						begin
							savedDirPos := curDirPos;
							ReadExtended(curFil, tempIndir, tempSubDir);
							DeleteExtDesc(curFil, tempInDir, tempSubDir);
							if (pos(':', curFil.realFName) = 0) then
							begin
								tempstring := concat(t2, curPrompt);
								t2 := concat(t2, curFil.realFName);
							end
							else
								t2 := curFil.realFName;
							curFil.realFName := curprompt;
							curFil.flName := curPrompt;
							result := Rename(t2, 0, tempstring);
							AddExtended(curFil, tempInDir, tempSubDir);
							curDirPos := savedDirPos;
						end
						else
							OutLine(RetInStr(444), true, 0);	{Filename already in use; not changed.}
					end;
					OutLine(RetInStr(445), true, 0);	{New description: }
					bCR;
					LettersPrompt(': ', '', 72 - forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, false, false, char(0));
					ANSIPrompter(72 - forums^^[tempInDir].dr[tempSubDir].fileNameLength);
					RenDo := RenSeven;
				end;
				RenSeven: 
				begin
					if length(curPrompt) > 0 then
					begin
						curFil.flDesc := curprompt;
					end;
					bCR;
					YesNoQuestion(RetInStr(446), false);	{Enter a new extended description? }
					RenDo := RenEight;
				end;
				RenEight: 
				begin
					if curPrompt = 'N' then
						RenDo := RenThree
					else
					begin
						DeleteExtDesc(curFil, inRealDir, InRealSubDir);
						curFil.hasExtended := false;
						BoardSection := Ext;
						ExtenDo := Ex1;
					end;
					FileEntry(curFil, inRealDir, InRealSubDir, tempInt, curDirPos);
				end;
				otherwise
			end;
		end;
	end;

	function DLRatioOK: boolean;
		var
			myR, myR2: real;
	begin
		with curglobs^ do
		begin
			if not (thisUser.downloadedK = 0) then
			begin
				myR := thisUser.uploadedK / thisUser.downloadedK;
				myr2 := 1 / thisUser.DLRatioOneTo;
				if myR < myR2 then
					DLRatioOK := false
				else
					DLRatioOK := true;
			end
			else if (thisUser.DLCredits > 0) then
				DLRatioOK := true
			else
			begin
				if thisUser.uploadedK > 0 then
					DLratioOK := true
				else
					DLratioOK := false;
			end;
			if not thisUser.UDRatioOn then
				DLRatioOK := true;
		end;
	end;

	procedure printForumList;
		var
			i, b: integer;
			tempString: str255;
	begin
		with curglobs^ do
		begin
			OutLine(RetInStr(410), true, 0);	{Forums available:}
			bCR;
			b := 0;
			for i := 1 to InitSystHand^^.numMForums do
			begin
				if MForumOk(i) then
				begin
					b := b + 1;
					OutLine(stringOf(b : 2, '.'), true, 2);
					OutLine(concat(' ', MForum^^[i].Name), false, 1);
				end;
			end;
			bCR;
			crossint1 := b;
		end;
	end;

	function FigureDisplayConf (whichFor, theConf: integer): integer;
		var
			i, x: integer;
	begin
		x := 0;
		for i := 1 to theConf do
			if MConferenceOk(whichFor, i) then
				x := x + 1;
		FigureDisplayConf := x;
	end;

	function FindConference (whichFor, Selected: integer): integer;
		var
			i, x: integer;
	begin
		with curglobs^ do
		begin
			x := 0;
			displayConf := Selected;
			for i := 1 to MForum^^[whichFor].NumConferences do
				if MConferenceOk(whichFor, i) then
				begin
					x := x + 1;
					if x = selected then
					begin
						x := i;
						leave;
					end;
				end;
			FindConference := x;
		end;
	end;

	procedure PrintConfList (whichFor: integer);
		var
			i, x, y, z: integer;
			tempString, BColor, YColor: str255;
			tb2: boolean;
			TheList: array[1..50] of string[47];
	begin
		with curglobs^ do
		begin
			x := 0;
			if (MForumOk(WhichFor)) and (InitSystHand^^.numMForums >= whichFor) and (MForum^^[whichFor].NumConferences > 0) then
			begin
				OutLine(concat(RetInStr(433), MForum^^[whichFor].Name, ':'), true, 0);{Subs available for }
				bCR;
				if (thisUser.TerminalType = 1) then
				begin
					DecodeM(1, gBBSwindows[activeNode]^.bufStyle, BColor);
					DecodeM(2, gBBSwindows[activeNode]^.bufStyle, YColor);
				end
				else
				begin
					BColor := char(0);
					YColor := char(0);
				end;
				if (thisUser.columns) and (MForum^^[whichFor].NumConferences > 5) then
				begin
					x := 0;
					y := -1;
					z := 0;
					for i := 1 to MForum^^[whichFor].NumConferences do
						if MConferenceOk(whichFor, i) then
							x := x + 1;
					if (x < 50) then
						TheList[x + 1] := char(0);
					if (not odd(x)) then
						x := x - 1;
					for i := 1 to MForum^^[whichFor].NumConferences do
						if MConferenceOk(whichFor, i) then
						begin
							if y >= x then
								y := 0;
							y := y + 2;
							z := z + 1;
							if z < 10 then
								TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, MConference[whichFor]^^[i].Name, '                                                ')
							else
								TheList[y] := stringOf(YColor, z : 0, '. ', BColor, MConference[whichFor]^^[i].Name, '                                                ');
							if (thisUser.TerminalType = 0) or (not thisUser.ColorTerminal) then
								TheList[y][0] := char(39);
						end;
					z := 1;
					x := x + 1;
					repeat
						OutLine(concat(TheList[z], ' ', TheList[z + 1]), true, -1);
						z := z + 2;
					until z >= x;
					if odd(x) then
						OutLine(TheList[x], true, -1)
				end
				else
				begin
					x := 0;
					for i := 1 to MForum^^[whichFor].NumConferences do
						if MConferenceOk(whichFor, i) then
						begin
							x := x + 1;
							OutLine(StringOf(x : 2, '. '), true, 2);
							OutLine(MConference[whichFor]^^[i].Name, false, 1);
						end;
				end;
			end
			else
				OutLine(RetInStr(434), true, 0);	{No subs available.}
		end;
	end;

	procedure PrintUserStuff;
		var
			tempString, tempString2, tempString3: str255;
			tempDate: DateTimeRec;
			tempInt: integer;
	begin
		with curglobs^ do
		begin
			OutLine(concat('Your Statistics On: ', BBSName), false, 2);
			bcr;
			NumToString(thisUser.UserNum, tempString2);
			OutLine(concat(RetInStr(46), thisUser.UserName, ' #', tempString2), true, 0);
			OutLine(concat(RetInStr(288), SecLevels^^[thisUser.SL].class), true, 0);{Classification : }
			OutLine(concat(RetInStr(47), thisUser.Phone), true, 0);
			FindMyEmail(thisUser.UserNum);
			tempInt := GetHandleSize(handle(myEmailList)) div 2;
			if tempInt > 0 then
			begin
				NumToString(tempInt, tempString2);
				OutLine(concat(RetInStr(48), tempString2), true, 0);
			end;
			NumToString(thisUser.SL, tempString2);
			OutLine(concat(RetInStr(49), tempString2), true, 0);
			NumToString(thisUser.DSL, tempString2);
			OutLine(concat(RetInStr(50), tempString2), true, 0);
			IUDateString(thisUser.lastOn, abbrevDate, tempstring2);
			IUTimeString(thisUser.lastOn, true, tempString3);
			OutLine(concat(RetInStr(51), tempstring2, ' at ', tempstring3), true, 0);
			IUTimeString(thisUser.firstOn, true, tempString3);
			IUDateString(thisUser.firstOn, abbrevDate, tempstring2);
			OutLine(concat(RetInStr(67), tempstring2, ' at ', tempstring3), true, 0);
			OutLine(concat(RetInStr(52), DoNumber(thisUser.totalLogons)), true, 0);
			NumToString(thisUser.OnToday, tempString2);
			OutLine(concat(RetInStr(53), tempString2), true, 0);
			OutLine(concat(RetInStr(54), DoNumber(thisUser.MessagesPosted)), true, 0);
			OutLine(concat(RetInStr(55), DoNumber(thisUser.EMailSent)), true, 0);
			if thisUser.PCRatioOn then
			begin
				OutLine(stringOf(RetInStr(56), (thisUser.messagesPosted / thisUser.TotalLogons) : 0 : 2), true, 0);
			end;
			OutLine(concat(RetInStr(57), DoNumber(thisUser.totaltimeOn), ' minutes.'), true, 0);
			bCR;
		end;
	end;

	procedure printDirList (prompt: boolean);
		var
			i, x, y, z: integer;
			tempString, BColor, YColor: str255;
			tb2: boolean;
			TheList: array[1..64] of string[47];
	begin
		with curGlobs^ do
		begin
			if forumIdx^^.numForums > 0 then
			begin
				OutLine(RetInStr(644), true, 0);{Available Areas:}
				bCR;
				if (thisUser.TerminalType = 1) then
				begin
					DecodeM(1, gBBSwindows[activeNode]^.bufStyle, BColor);
					DecodeM(2, gBBSwindows[activeNode]^.bufStyle, YColor);
				end
				else
				begin
					BColor := char(0);
					YColor := char(0);
				end;
				if (thisUser.columns) and (forumIdx^^.numForums > 5) then
				begin
					x := 0;
					if forumOk(0) then
					begin
						OutLine(StringOf(x : 2), true, 0);
						OutLine(':', false, 2);
						OutLine(copy(forumIdx^^.name[0], 1, 37), false, 5);
						bCR;
					end;
					x := 0;
					y := -1;
					z := 0;
					for i := 1 to forumIdx^^.numForums do
						if ForumOK(i) then
							x := x + 1;
					if (x < 64) then
						TheList[x + 1] := char(0);
					if (not odd(x)) then
						x := x - 1;
					for i := 1 to forumIdx^^.numForums do
						if ForumOK(i) then
						begin
							if y >= x then
								y := 0;
							y := y + 2;
							z := z + 1;
							if z < 10 then
								TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, forumIdx^^.name[i], '                                                ')
							else
								TheList[y] := stringOf(YColor, z : 0, '. ', BColor, forumIdx^^.name[i], '                                                ');
							if (thisUser.TerminalType = 0) then
								TheList[y][0] := char(39);
						end;
					z := 1;
					x := x + 1;
					repeat
						OutLine(concat(TheList[z], '  ', TheList[z + 1]), true, -1);
						z := z + 2;
					until z >= x;
					if odd(x) then
						OutLine(TheList[x], true, -1)
				end
				else
				begin
					x := 0;
					if forumOk(0) then
					begin
						OutLine(StringOf(x : 2), true, 0);
						OutLine(':', false, 2);
						OutLine(copy(forumIdx^^.name[0], 1, 37), false, 5);
						bCR;
					end;
					for i := 1 to forumIdx^^.numForums do
						if ForumOK(i) then
						begin
							x := x + 1;
							OutLine(StringOf(x : 2, '. '), true, 2);
							OutLine(forumIdx^^.name[i], false, 1);
						end;
				end;
				bCR;
				if prompt then
				begin
					bCR;
					if thisUser.CoSysOp then
						NumbersPrompt(RetInStr(265), '', x, 0)	{Jump to ? }
					else
						NumbersPrompt(RetInStr(265), '', x, 1)	{Jump to ? }
				end;
			end
			else
			begin
				OutLine(RetInStr(645), true, 0);{No Areas Available.}
				GoHome;
			end;
		end;
	end;

	procedure printSubDirList (whichDir: Integer);
		var
			i, x, y, z: integer;
			tempString, BColor, YColor: str255;
			tb2: boolean;
			TheList: array[1..64] of string[47];
	begin
		with curglobs^ do
		begin
			OutLine(RetInStr(58), true, 0);
			bCR;
			if (thisUser.TerminalType = 1) then
			begin
				DecodeM(1, gBBSwindows[activeNode]^.bufStyle, BColor);
				DecodeM(2, gBBSwindows[activeNode]^.bufStyle, YColor);
			end
			else
			begin
				BColor := char(0);
				YColor := char(0);
			end;
			if (thisUser.columns) and (ForumIdx^^.numDirs[whichDir] > 5) then
			begin
				x := 0;
				y := -1;
				z := 0;
				for i := 1 to ForumIdx^^.numDirs[whichDir] do
					if SubDirOk(WhichDir, i) then
						x := x + 1;
				if (x < 64) then
					TheList[x + 1] := char(0);
				if (not odd(x)) then
					x := x - 1;
				for i := 1 to ForumIdx^^.numDirs[whichDir] do
					if SubDirOk(WhichDir, i) then
					begin
						if y >= x then
							y := 0;
						y := y + 2;
						z := z + 1;
						if z < 10 then
							TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, forums^^[whichDir].dr[i].dirName, '                                                ')
						else
							TheList[y] := stringOf(YColor, z : 0, '. ', BColor, forums^^[whichDir].dr[i].dirName, '                                                ');
						if (thisUser.TerminalType = 0) or (not thisUser.ColorTerminal) then
							TheList[y][0] := char(39);
					end;
				z := 1;
				x := x + 1;
				repeat
					OutLine(concat(TheList[z], '  ', TheList[z + 1]), true, -1);
					z := z + 2;
				until z >= x;
				if odd(x) then
					OutLine(TheList[x], true, -1)
			end
			else
			begin
				x := 0;
				for i := 1 to ForumIdx^^.numDirs[whichDir] do
					if SubDirOk(WhichDir, i) then
					begin
						x := x + 1;
						OutLine(StringOf(x : 2, '. '), true, 2);
						OutLine(forums^^[whichDir].dr[i].dirName, false, 1);
					end;
			end;
		end;
	end;

	function PrintFileInfo (theFl: filEntryRec; fromDir, fromSubDir: integer; doOther: boolean): integer;
		var
			tempString, t2, t3, t4, t5, t6, t7: str255;
			l1, fileKLen, templong: longInt;
			myDate: DateTimeRec;
			i: integer;
	begin
		with curglobs^ do
		begin
			PrintFileInfo := 0;
			if fromDir <> inRealDir then
				bufferIt(concat(RetInStr(646), forumIdx^^.name[fromDir]), true, 0);{Area       : }
			if (fromDir <> inRealDir) or (fromSubDir <> InRealSubDir) then
				bufferIt(concat(RetInStr(452), forums^^[fromDir].dr[fromSubDir].dirName), true, 0);{Directory  : }
			if thisUser.CoSysop then
				bufferIt(concat(RetInStr(647), forums^^[fromDir].dr[fromSubDir].path), true, 0);{Path       : }
			if (currentBaud <> 0) and (nodeType = 1) then
				l1 := theFl.bytelen div (modemDrivers^^[modemID].rs[rsIndex].effRate div 10)
			else
				l1 := 0;
			tempString := Secs2Time(l1);
			fileKlen := theFl.byteLen div 1024;
			if theFl.byteLen = -1 then
				t2 := 'ASK'
			else
			begin
				t2 := concat(doNumber(fileKLen), 'k');
			end;
			IUTimeString(theFl.whenUL, TRUE, t6);
			IUTimeString(theFl.lastDL, TRUE, t7);
			if (theFl.lastDL <> 0) and not thisUser.CantSeeULInfo then
				t5 := concat(getDate(theFl.lastDl), ' at ', t7)
			else
				t5 := RetInStr(460);
			if curFil.fileStat = 'F' then
				bufferIt(RetInStr(453), true, 0);	{*** Upload Fragment ***}
			bufferIt(concat(RetInStr(454), theFl.flName), true, 0);	{Filename   : }
			bufferIt(concat(RetInStr(455), theFl.flDesc), true, 0);	{Description: }
			bufferIt(concat(RetInStr(456), t2), true, 0);					{File size  : }
			if forums^^[fromDir].dr[fromSubDir].DLcost <> 1.0 then
			begin
				tempLong := trunc(fileKlen * forums^^[fromDir].dr[fromSubDir].DLCost);
				bufferIt(stringOf(RetInStr(648), doNumber(tempLong), 'k'), true, 0);{File Cost  : }
			end;
			bufferIt(concat(RetInStr(457), tempString), true, 0);	{Apprx. Time: }
			bufferIt(concat(RetInStr(458), getdate(theFL.whenUL), ' at ', t6), true, 0);	{Uploaded on: }
			if (theFL.uploaderNum > numuserRecs) or (myUsers^^[theFl.uploaderNum - 1].first > theFL.whenUL) then
			begin
				theFL.uploaderNum := 1;
				FileEntry(theFL, fromDir, fromSubDir, i, curDirPos);
			end;
			NumToString(theFl.uploaderNum, t2);
			if not thisUser.CantSeeULInfo then
				t2 := concat(myUsers^^[theFl.uploaderNum - 1].UName, ' #', t2)
			else
				t2 := RetInStr(460);
			bufferIt(concat(RetInStr(459), t2), true, 0);	{Uploaded by: }
			if not ThisUser.CantSeeULInfo then
				t2 := DoNumber(theFl.numDloads)
			else
				t2 := RetInStr(460);
			bufferIt(concat(RetInStr(461), t2), true, 0);	{Times D/L''d: }
			bufferIt(concat(RetInStr(462), t5), true, 0);	{Last D/L   : }
			releaseBuffer;
			if theFl.hasExtended then
			begin
				ReadExtended(theFl, fromDir, fromSubDir);
				if curWriting <> nil then
				begin
					bCR;
					OutLine(RetInStr(463), true, 1);	{Extended Description:}
					bCR;
					PrintExtended(0);
				end;
			end;
			tempString := forums^^[fromDir].dr[fromSubDir].path;
			if doOther then
			begin
				if (pos(':', theFl.realFName) = 0) then
					t2 := concat(tempString, theFl.realFname)
				else
					t2 := curFil.realFName;
				if not FExist(t2) then
				begin
					bCR;
					OutLine(RetInStr(464), true, 0);	{->FILE NOT THERE<-}
					bCR;
					bCR;
					NumbersPrompt(RetInStr(649), 'YNQ', -1, 1);{Request File For Downloading? [Y=Yes, N=No, Q=Quit]: }
					PrintFileInfo := -1;
				end
				else if ((l1) > (ticksLeft(activeNode) div 60)) then
				begin
					bCR;
					OutLine(RetInStr(465), true, 0);	{Not enough time left to D/L.}
					bCR;
					PrintFileInfo := -2;
				end;
			end;
		end;
	end;
end.