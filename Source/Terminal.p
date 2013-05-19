{ Segments: Terminal_1 }
unit Terminal;
interface

	uses
		AppleTalk, ADSP, Serial, Sound, Initial, NodePrefs2, SystemPrefs;

	const
		NOTHINGSPACE = 2;
		TABWIDTH = 4;
		HERMESFONTNUMBER = 150;
		CURSORHEIGHT = 2;


	procedure AllocateANSIwindow (num: integer);
	procedure OpenANSIWindow (num: integer);
	procedure CloseANSIWindow (num: integer);
	procedure ProcessData (num: integer; bufStuff: ptr; lenProc: integer);
	function isMyBBSWindow (theWind: windowPtr): integer;
	procedure DrawClippedGrow (theWindow: WindowPtr);
	procedure GrowBBSwindow (num: integer; reqWid, reqHei: integer);
	procedure ActivateBBSwind (activate: boolean; num: integer);
	procedure DisposeANSIWindow (num: integer);
	procedure UpdateBBSwindow (num: integer);
	procedure CommonAction (control: ControlHandle; var amount: INTEGER);
	procedure DoANSIClick (num: integer; where: point; shiftIsDown: boolean);
	procedure CopySelection (num: integer);
	function compareDL (aa, bb: filEntryRec; which: integer): boolean;
	procedure GenericShellSort (N: integer; function Compare (i, j: integer): boolean; procedure Exchange (i, j: integer));
	procedure SysQuickSort (Start, Finish: integer; which: integer);
	function SortDir (whichDir, whichSub: integer; which: integer): integer;
	procedure GetNextFile (temDir, temSub: integer; fileMsk: str255; var curposDir: integer; var tmpFile: filentryrec; afterDate: longInt);
	function OpenDirectory (whichDir, SubDir: integer): boolean;
	procedure CloseDirectory;
	procedure SetFontVars;
	procedure UpdateProgress;
	procedure ForeGround (color: integer);
	procedure BackGround (color: integer);
	function FileOKMask (fileNm: str255; fileMsk: str255): boolean;

implementation

{$S Terminal_1}
	procedure ForeGround (color: integer);
	begin
		if ((InitSystHand^^.usebold) or (not IsUsingColor)) and (color > 7) then
			color := color - 8;
		if isusingColor then
			RGBForeColor(ANSIColors[color])
		else
			ForeColor(OldANSIColors[color])
	end;

	procedure BackGround (color: integer);
	begin
		if isusingColor then
			RGBBackColor(ANSIColors[color])
		else
			BackColor(OldANSIColors[color])
	end;

	procedure SetFontVars;
		var
			size: longint;
	begin
		if (InitSystHand^^.ninePoint) then
		begin
			hermesFontSize := 9;
			hermesFontDescent := 2;
			hermesFontWidth := 6;
			hermesFontHeight := 11;
		end
		else
		begin
			hermesFontSize := 12;
			hermesFontDescent := 3;
			hermesFontWidth := 7;
			hermesFontHeight := 15;
		end;
	end;


	function compareDL (aa, bb: filEntryRec; which: integer): boolean;
		var
			ttt: integer;
	begin
		if (which = 1) then
		begin
			ttt := IUCompString(aa.flName, bb.flName);
			if ttt = -1 then
				compareDL := true
			else
				compareDL := false;
		end
		else if (which = 2) then
		begin
			if aa.whenUL > bb.whenUL then
				compareDL := true
			else
				compareDl := false;
		end
		else if (which = 3) then
		begin
			if aa.numDLoads > bb.numDLoads then
				compareDL := true
			else
				compareDL := false;
		end
		else if (which = 4) then
		begin
			if aa.byteLen > bb.byteLen then
				compareDL := true
			else
				compareDL := false;
		end
		else
		begin
			if aa.lastDL > bb.lastDL then
				compareDL := true
			else
				compareDL := false;
		end;
	end;

	{ Generic shell sort algorithm.  Modified from source contained in }
	{ "Algorithms in C++" by Robert Sedgewick pg. 109.                 }
	procedure GenericShellSort (N: integer; function Compare (i, j: integer): boolean; procedure Exchange (i, j: integer));
		var
			i, j, h: integer;
			v: integer;
			upper, lower: integer;
	begin
		h := 1;
		while h <= (N div 9) do
			h := 3 * h + 1;

		while h > 0 do
		begin
			for i := h + 1 to N do
			begin
				v := i - 1;
				j := i;
				while (j > h) and Compare(v, j - h - 1) do
				begin
					upper := j - 1;
					lower := j - h - 1;
					if v = upper then
						v := lower
					else if v = lower then
						v := upper;
					if lower <> upper then
						Exchange(lower, upper);
					j := j - h;
				end;
				if v <> j - 1 then
					Exchange(j - 1, v);
			end;

			h := h div 3;
		end;
	end;

	procedure ShellSortDirectory (which: integer);

		function Compare (i, j: integer): boolean;
		begin
			with curGlobs^ do
				Compare := compareDL(curOpenDir^^[i], curOpenDir^^[j], which);
		end;

		procedure Exchange (i, j: integer);
			var
				saved: FilEntryRec;
		begin
			with curGlobs^ do
			begin
				saved := curOpenDir^^[i];
				curOpenDir^^[i] := curOpenDir^^[j];
				curOpenDir^^[j] := saved;
			end;
		end;

	begin
		GenericShellSort(curGlobs^.curNumFiles, Compare, Exchange);
	end;

	procedure SysQuickSort (Start, Finish: integer; which: integer);
		var
			left, right: integer;
			starterValue, temp: filEntryRec;
	begin
		left := start;
		right := finish;
		StarterValue := sysopOpenDir^^[(start + finish) div 2];
		repeat
			while compareDL(sysopOpenDir^^[left], starterValue, which) do
				left := left + 1;
			while compareDL(starterValue, sysopOpenDir^^[right], which) do
				right := right - 1;
			if left <= right then
			begin
				temp := sysopOpenDir^^[left];
				sysopOpenDir^^[left] := sysopOpenDir^^[right];
				sysopOpenDir^^[right] := temp;
				left := left + 1;
				right := right - 1;
			end;
		until right <= left;
		if start < right then
			SysQuickSort(start, right, which);
		if left < finish then
			SysQuickSort(left, finish, which);
	end;

	procedure CloseDirectory;
	begin
		with curglobs^ do
		begin
			if (curOpenDir <> nil) then
			begin
				HPurge(handle(curOpenDir));
				DisposHandle(handle(curOpenDir));
			end;
			dirOpenNum := -1;
			subDirOpenNum := -1;
			curOpenDir := nil;
		end;
	end;

	function OpenDirectory (whichDir, SubDir: integer): boolean;
		var
			result: OSerr;
			DirRef: integer;
			tempLong: LongInt;
			myHParmer: HParamBlockRec;
			myParmer: ParamBlockRec;
			tempString: str255;
			s1: str255;
	begin
		with curglobs^ do
		begin
			OpenDirectory := false;
			CloseDirectory;
			curNumFiles := 0;
			GetDateTime(templong);
			if ForumIdx^^.numDirs[whichDir] >= (subDir) then
			begin
				tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[subDir].dirName);
				myHParmer.ioCompletion := nil;
				myHParmer.ioNamePtr := @TEMPSTRING;
				myHParmer.ioVRefNum := 0;
				myHParmer.ioPermssn := fsRdPerm;
				myHParmer.ioMisc := nil;
				myHParmer.ioDirID := 0;
				result := PBHOpen(@myHParmer, false);
				if result = noErr then
				begin
					dirRef := myHParmer.ioRefNum;
					result := SetFPos(DirRef, fsFromStart, 0);
					result := GetEOF(DirRef, tempLong);
					curOpenDir := aDirHand(NewHandle(tempLong));
					if MemError = noErr then
					begin
						MoveHHi(handle(curOpenDir));
						HNoPurge(handle(curOpenDir));
						result := FSRead(dirRef, tempLong, pointer(curOpenDir^));
						OpenDirectory := true;
						dirOpenNum := whichDir;
						subDirOpenNum := SubDir;
						if tempLong > 0 then
							curnumFiles := tempLong div SizeOf(filEntryRec);
					end
					else
						curOpenDir := nil;
					myParmer.ioCompletion := nil;
					myParmer.ioRefNum := dirRef;
					result := PBClose(@myParmer, false);
				end;
			end;
		end;
	end;

	function SortDir (whichDir, whichSub: integer; which: integer): integer;
	begin
		SortDir := 0;
		with curglobs^ do
		begin
			if OpenDirectory(whichDir, whichSub) then
			begin
				ShellSortDirectory(which);
				SortDir := curNumFiles;
			end;
		end;
	end;

	function FileOKMask (fileNm: str255; fileMsk: str255): boolean;
	begin
		UprString(fileMsk, false);
		UprString(fileNm, false);
		if fileMsk[length(fileMsk)] = '*' then
		begin
			delete(fileMsk, length(fileMsk), 1);
			if EqualString(fileMsk, copy(fileNm, 1, length(fileMsk)), false, false) then
				FileOKMask := true
			else
				FileOKMask := false;
		end
		else
		begin
			if pos(fileMsk, fileNm) > 0 then
				FileOKMask := true
			else
				FileOKMask := false;
		end;
	end;

	procedure GetNextFile (temDir, temSub: integer; fileMsk: str255; var curposDir: integer; var tmpFile: filentryrec; afterDate: longInt);
		var
			result: OSerr;
			tempRef, i, x, y: integer;
			numFls, tempLong: longInt;
			ts, ts2: str255;
	begin
		with curglobs^ do
		begin
			ts2 := fileMsk;
			lastKeyPressed := tickCount;
			tmpFile.flName := '';
			if not aborted then
			begin
				if temDir = DirOpenNum then
				begin
					numFls := curNumFiles;
					while ((curPosDir + 1) <= numFls) and (tmpFile.flName = '') do
					begin
						curPosDir := CurPosDir + 1;
						tmpFile := curOpenDir^^[curPosDir - 1];
						if fileMsk <> '' then
						begin
							if descSearch then
							begin
								if fileMsk[length(fileMsk)] = '*' then
									delete(fileMsk, length(fileMsk), 1);
								ts := tmpFile.flDesc;
								uprString(fileMsk, true);
								UprString(ts, true);
								if (pos(fileMsk, ts) = 0) and (not thisUser.ExtDesc) then
									tmpFile.flName := ''
								else if (tmpFile.hasExtended) and (pos(fileMsk, ts) = 0) then
								begin
									ReadExtended(tmpFile, temDir, temsub);
									for i := 1 to gethandlesize(handle(curwriting)) do
									begin
										if (CurWriting^^[i] >= char('a')) and (CurWriting^^[i] <= char('z')) then
											CurWriting^^[i] := Char(Ord(CurWriting^^[i]) - 32);
									end;
									tempLong := Munger(handle(CurWriting), 0, Pointer(Ord(@fileMsk) + 1), length(fileMsk), nil, 0);
									if tempLong < 0 then
										tmpFile.flName := '';
								end
								else if (pos(fileMsk, ts) = 0) then
									tmpFile.flName := '';
							end
							else
							begin
								if not (FileOKMask(tmpFile.flName, fileMsk)) then
									tmpFile.flName := '';
							end;
						end;
						if (afterDate <> 0) and (tmpFile.whenUL < afterDate) then
							tmpFile.flname := '';
						if (tmpFile.flName <> '') and (tmpFile.fileStat = 'F') then
						begin
							if (tmpFile.uploaderNum <> thisUser.userNum) and not (thisUser.coSysop) then
							begin
								tmpFile.flname := '';
							end;
						end;
					end;
				end;
			end;
		end;
	end;

	procedure SetRange (startRange: ptr; endRange: ptr; withThis: char);
		var
			tem: integer;
	begin
		while (longint(startRange) <= longint(endRange)) do
		begin
			startRange^ := byte(withThis);
			startRange := pointer(longint(startRange) + 1);
		end;
	end;

	procedure SetStyleRange (startRange: ptr; endRange: ptr; withThis: charStyle);
		var
			tstart: charStylePtr;
	begin
		tStart := charStylePtr(startRange);
		while (longint(tStart) <= longint(endRange)) do
		begin
			tStart^ := withThis;
			tStart := charStylePtr(longint(tStart) + SizeOf(charStyle));
		end;
	end;


	procedure DrawClippedGrow (theWindow: WindowPtr);
		var
			oldClip: RgnHandle;
			newClip: Rect;
	begin
		SetPort(theWindow);
		oldClip := NewRgn;
		GetClip(oldClip);
		SetRect(newClip, -15, -15, 0, 0);
		OffsetRect(newClip, theWindow^.portRect.right, theWindow^.portRect.bottom);
		ClipRect(newClip);
		DrawGrowIcon(theWindow);
		SetClip(oldClip);
		DisposeRgn(oldClip);
	end;

	procedure SetCursorPos (num, h, v: integer);
	begin
		with gBBSwindows[num]^ do
		begin
			if ansiPort <> nil then
				SetPort(ansiPort);
			if cursorOn then
			begin
				if (ansiPort <> nil) then
					InvertRect(cursorRect);
				cursorOn := false;
			end;
			if not scrollFreeze and (h >= 0) and (v >= 0) and (h <= 79) and (v <= 23) then
			begin
				cursor.h := h;
				cursor.v := v;
				if (ansiPort <> nil) and (ansiPort = FrontWindow) then
				begin
					cursorRect.left := ansiRect.left + h * HERMESFONTWIDTH;
					cursorRect.right := cursorRect.left + HERMESFONTWIDTH;
					cursorRect.top := ansiRect.top + (v + 1 - scrnTop) * HERMESFONTHEIGHT - 2;
					cursorRect.bottom := cursorRect.top + CURSORHEIGHT;
					if (cursorRect.top > ansiRect.top) and (cursorRect.right <= ansiRect.right) then
					begin
						InvertRect(cursorRect);
						cursorOn := true;
					end;
				end;
			end;
		end;
	end;

	procedure ActivateBBSwind (activate: boolean; num: integer);
	begin
		with gBBSwindows[num]^ do
		begin
			SetPort(ansiPort);
			if activate then
			begin
				DrawClippedGrow(ansiPort);
				ShowControl(ansiVScroll);
				SetCursorPos(num, cursor.h, cursor.v);
			end
			else
			begin
				DrawClippedGrow(ansiPort);
				HideControl(ansiVScroll);
				if cursorOn then
					InvertRect(cursorRect);
				cursorOn := false;
			end;
		end;
	end;

	function EqualStyle (sty1, sty2: CharStyle): boolean;
	begin
		if (sty1.fCol = sty2.fCol) and (sty1.bCol = sty2.bCol) and (sty1.intense = sty2.intense) then
			EqualStyle := true
		else
			EqualStyle := false;
	end;

	procedure UpdateBBSwindow (num: integer);
		var
			i, j, added, visChars: integer;
			p, e, f: ptr;
			drawStyle, g: CharStylePtr;
			tl1, tl2: integer;
			qPt: point;
			colorUse: boolean;
			tempRect: Rect;
	begin
		with gBBSwindows[num]^ do
		begin
			SetPort(ansiPort);
			colorUse := isUsingColor;
			ForeColor(blackColor);
			BackColor(whiteColor);
			tempRect := ansiPort^.portRect;

			SetRect(tempRect, tempRect.right - 15, -1, temprect.right + 1, tempRect.bottom);
			EraseRect(tempRect);
			FrameRect(tempRect);

			ForeGround(defaultStyle.fCol);
			BackGround(defaultStyle.bCol);
			tempRect := ansiPort^.portRect;
			tempRect.right := tempRect.right - 15;
			EraseRect(tempRect);

			TextFont(HERMESFONTNUMBER);
			TextMode(srcCopy);
			TextSize(HERMESFONTSIZE);
			TextFace([]);
			visChars := (ansiRect.right - ansiRect.left) div HERMESFONTWIDTH;
			if scrnTop < 0 then
			begin
				tl1 := sTopLine + (sNumLines - 1);
				if tl1 > (sNumLines - 1) then
					tl1 := tl1 - (sNumLines - 1) - 1;
				for i := abs(scrnTop) downto 1 do
				begin
					MoveTo(ansiRect.left, ansiRect.top + i * HERMESFONTHEIGHT - 2);
					DrawText(@bigbuffer^[tl1], 0, visChars);
					tl1 := tl1 - 1;
					if tl1 < 0 then
						tl1 := sNumLines - 1;
				end;
			end;
			for i := 0 to 23 do
			begin
				if (scrnBottom >= (i + 1)) then
				begin
					p := pointer(@screenInfo[(i + topLine) mod 24, 0]);
					e := pointer(longint(p) + ((visChars - 1) * SizeOf(charStyle)));
					j := 0;
					while longint(p) < longint(e) do
					begin
						added := 0;
						drawStyle := CharStylePtr(p);
						g := CharStylePtr(p);
						while (longint(g) < longint(e)) and EqualStyle(g^, drawStyle^) do
						begin
							g := CharStylePtr(longint(g) + SizeOf(charStyle));
							added := added + 1;
						end;
						if drawStyle^.intense and drawStyle^.underline then
							TextFace([underline])
						else if (drawStyle^.intense and InitSystHand^^.UseBold) or (drawStyle^.intense and not IsUsingColor) then
							TextFace([bold])
						else if drawStyle^.intense then
							drawStyle^.fcol := drawStyle^.fcol + 8
						else
							TextFace([]);
						if not colorUse then
						begin
							drawStyle^.fcol := defaultStyle.fcol;
							drawStyle^.bcol := defaultStyle.bcol;
						end;
						ForeGround(drawStyle^.fCol);
						BackGround(drawStyle^.bCol);
						if (drawStyle^.intense and not InitSystHand^^.useBold) or (drawStyle^.intense and IsUsingColor) then
							drawStyle^.fcol := drawStyle^.fcol - 8;
						MoveTo(ansiRect.left + j * HERMESFONTWIDTH, ansiRect.top + (i + 1 - scrnTop) * HERMESFONTHEIGHT - 2);
						DrawText(@screen[(i + topLine) mod 24, j], 0, added);
						j := j + added;
						p := pointer(longint(p) + (added * SizeOf(charStyle)));
					end;
				end;
			end;
			SetCursorPos(num, cursor.h, cursor.v);
			if not (FrontWindow = ansiPort) then
				HideControl(ansiVScroll);
			DrawControls(ansiPort);
			DrawClippedGrow(ansiPort);
		end;
	end;

	procedure ForceUpdate (num: integer; forced: RgnHandle);
		var
			savedRgn: RgnHandle;
	begin
		with gBBSwindows[num]^ do
		begin
			savedRgn := NewRgn;
			CopyRgn(ansiPort^.visRgn, savedRgn);
			UnionRgn(forced, windowPeek(ansiPort)^.updateRgn, forced);
			SectRgn(forced, ansiPort^.visRgn, ansiPort^.visRgn);
			SetEmptyRgn(windowPeek(ansiPort)^.updateRgn);
			UpdateBBSWindow(num);
			CopyRgn(savedRgn, ansiPort^.visRgn);
			DisposeRgn(savedRgn);
		end;
	end;

	procedure CommonAction (control: ControlHandle; var amount: INTEGER);
{Common algorithm for setting the new value of a control. It returns the actual amount}
{the value of the control changed. Note the pinning is done for the sake of returning}
{the amount the control value changed.}
		var
			value, max: INTEGER;
			window: WindowPtr;
	begin
		value := GetCtlValue(control);	{get current value}
		max := GetCtlMax(control);		{and max value}
		amount := value - amount;
		if amount < 0 then
			amount := 0
		else if amount > max then
			amount := max;
		SetCtlValue(control, amount);
		amount := value - amount;		{calculate true change}
	end; {CommonAction}

	procedure FromPtToBufPos (num: integer; screenPt: point; var bufPos: point);
	begin
		bufPos.h := (screenPt.h - NOTHINGSPACE + (HERMESFONTWIDTH div 2)) div HERMESFONTWIDTH;
		screenPt.v := screenPt.v - NOTHINGSPACE;
		if bufPos.h < 0 then
			bufPos.h := 0;
		if bufPos.h > 80 then
			bufPos.h := 80;
		bufPos.v := screenPt.v div HERMESFONTHEIGHT;
		if bufPos.v < 0 then
			bufPos.v := 0;
		if bufPos.v > (gBBSwindows[num]^.scrnLines - 1) then
			bufPos.v := gBBSwindows[num]^.scrnLines - 1;
		bufPos.v := gBBSwindows[num]^.scrnTop + bufPos.v;
	end;

	procedure FromBufPosToPt (num: integer; bufPos: point; var screenPt: point);
	begin
		screenPt.h := (bufPos.h * HERMESFONTWIDTH) + NOTHINGSPACE;
		screenPt.v := NOTHINGSPACE + ((bufPos.v - gBBSwindows[num]^.scrnTop + 1) * HERMESFONTHEIGHT);
	end;


	procedure doANSIScroll (num, amount: integer; updateSelect: boolean);
		var
			tempRgn: RgnHandle;
			i, j, added, visChars: integer;
			p, e, f: ptr;
			drawStyle, g: CharStylePtr;
			tl1, tl2: integer;
			tempRect: rect;
			temp: point;
			colorUse: boolean;
	begin
		with gBBSwindows[num]^ do
		begin
			scrnTop := scrnTop - amount;
			scrnBottom := scrnBottom - amount;
			if ansiPort <> nil then
			begin
				SetPort(ansiPort);
				colorUse := isUsingColor;
				TextFace([]);
				ForeGround(defaultStyle.fCol);
				BackGround(defaultStyle.bCol);
				visChars := (ansiRect.right - ansiRect.left) div HERMESFONTWIDTH;
				if abs(amount) = 1 then
				begin
					if not gMac.hasColorQD then
					begin
						ForeGround(0);
						BackGround(7);
					end;
					tempRgn := NewRgn;
					ScrollRect(ansiRect, 0, HERMESFONTHEIGHT * amount, tempRgn);
					if not (gMac.hasColorQD) then
					begin
						ForeGround(defaultStyle.fCol);
						BackGround(defaultStyle.bCol);
						EraseRgn(tempRgn);
					end;
					DisposeRgn(tempRgn);
					if amount = -1 then
					begin
						if (scrnBottom - 1) >= 0 then
							p := ptr(@screen[((topLine + scrnBottom - 1) mod 24), 0])
						else
							p := @bigBuffer^[(sTopLine + (sNumLines - abs(scrnBottom - 1))) mod sNumLines];
						MoveTo(ansiRect.left, ansiRect.top + scrnLines * HERMESFONTHEIGHT - 2);
					end
					else
					begin
						if scrnTop >= 0 then
							p := ptr(@screen[(topLine + scrnTop) mod 24, 0])
						else
							p := @bigBuffer^[(sTopLine + (sNumLines - abs(scrnTop))) mod sNumLines];
						MoveTo(ansiRect.left, ansiRect.top + HERMESFONTHEIGHT - 2);
					end;
					DrawText(p, 0, visChars);
					if updateSelect and selectActive then
					begin
						if amount = -1 then
							tl1 := scrnBottom - 1
						else
							tl1 := scrnTop;
						if (tl1 <= elastic.v) and (tl1 >= anchor.v) then
						begin
							if tl1 = anchor.v then
							begin
								FromBufPosToPt(num, anchor, tempRect.topLeft);
								tempRect.top := tempRect.top - HERMESFONTHEIGHT;
								temp := anchor;
								temp.h := 80;
								if anchor.v <> elastic.v then
									FromBufPosToPt(num, temp, tempRect.botRight)
								else
									FromBufPosToPt(num, elastic, tempRect.botRight);
							end
							else if (tl1 > anchor.v) and (tl1 < elastic.v) then
							begin
								SetPt(temp, 0, tl1);
								FromBufPosToPt(num, temp, tempRect.topLeft);
								tempRect.top := tempRect.top - HERMESFONTHEIGHT;
								SetPt(temp, 80, tl1);
								FromBufPosToPt(num, temp, tempRect.botRight);
							end
							else if tl1 = elastic.v then
							begin
								temp := elastic;
								temp.h := 0;
								FromBufPosToPt(num, temp, tempRect.topLeft);
								tempRect.top := tempRect.top - HERMESFONTHEIGHT;
								FromBufPosToPt(num, elastic, tempRect.botRight);
							end;
							bitclr(ptr(hilitemode), philitebit);
							InvertRect(tempRect);
						end;
					end;
				end
				else
				begin
					EraseRect(ansiRect);
					if scrnTop < 0 then
					begin
						tl1 := sTopLine + (sNumLines - 1);
						if tl1 > (sNumLines - 1) then
							tl1 := tl1 - (sNumLines - 1) - 1;
						for i := abs(scrnTop) downto 1 do
						begin
							MoveTo(ansiRect.left, ansiRect.top + i * HERMESFONTHEIGHT - 2);
							DrawText(@bigbuffer^[tl1], 0, visChars);
							tl1 := tl1 - 1;
							if tl1 < 0 then
								tl1 := sNumLines - 1;
						end;
					end;
					for i := 0 to 23 do
					begin
						if scrnBottom >= (i + 1) then
						begin
							p := pointer(@screenInfo[(i + topLine) mod 24, 0]);
							e := pointer(longint(p) + ((visChars - 1) * SizeOf(charStyle)));
							j := 0;
							while longint(p) < longint(e) do
							begin
								added := 0;
								drawStyle := CharStylePtr(p);
								g := CharStylePtr(p);
								while (longint(g) < longint(e)) and EqualStyle(g^, drawStyle^) do
								begin
									g := CharStylePtr(longint(g) + SizeOf(charStyle));
									added := added + 1;
								end;
								if drawStyle^.intense and drawStyle^.underline then
									TextFace([underline])
								else if (drawStyle^.intense and InitSystHand^^.UseBold) or (drawStyle^.intense and not IsUsingColor) then
									TextFace([bold])
								else if drawStyle^.intense then
									drawStyle^.fcol := drawStyle^.fcol + 8
								else
									TextFace([]);
								if colorUse then
								begin
									ForeGround(drawStyle^.fCol);
									BackGround(drawStyle^.bCol);
								end;
								if (drawStyle^.intense and not InitSystHand^^.useBold) or (drawStyle^.intense and IsUsingColor) then
									drawStyle^.fcol := drawStyle^.fcol - 8;
								MoveTo(ansiRect.left + j * HERMESFONTWIDTH, ansiRect.top + (i + 1 - scrnTop) * HERMESFONTHEIGHT - 2);
								DrawText(@screen[(i + topLine) mod 24, j], 0, added);
								j := j + added;
								p := pointer(longint(p) + (added * SizeOf(charStyle)));
							end;
						end;
					end;
				end;
			end;
		end;
	end;

	procedure AddLineToBuffer (num: integer; data: ptr);
	begin
		with gBBSwindows[num]^ do
		begin
			BlockMove(data, @bigBuffer^[sTopLine], 80);
			sTopLine := sTopLine + 1;
			if sTopLine >= sNumLines then
				sTopLine := 0;
			if selectActive then
			begin
				anchor.v := anchor.v - 1;
				elastic.v := elastic.v - 1;
				if anchor.v < -sNumLines then
					anchor.v := -sNumLines;
				if elastic.v < -sNumLines then
					selectActive := false;
			end;
			if scrollFreeze and (ansiPort <> nil) then
			begin
				i := GetCtlValue(ansiVScroll) - 1;
				scrnTop := scrnTop - 1;
				scrnBottom := scrnBottom - 1;
				if i < 0 then
					doANSIscroll(num, -1, true)
				else
					SetCtlValue(ansiVScroll, i);
			end;
		end;
	end;


	procedure ANSIVActionProc (control: ControlHandle; part: INTEGER);
		var
			amount, num: INTEGER;
			window: WindowPtr;
			theT: TEHandle;
	begin
		if part <> 0 then
		begin
			window := control^^.contrlOwner;
			num := isMyBBSwindow(window);
			with gBBSwindows[num]^ do
			begin
				if cursorOn then
				begin
					InvertRect(cursorRect);
					cursorOn := false;
				end;
				case part of
					inUpButton, inDownButton: 
						amount := 1;												{one line}
					inPageUp, inPageDown: 
						amount := scrnLines;	{one page}
					otherwise
				end;
				if (part = inDownButton) | (part = inPageDown) then
					amount := -amount;												{reverse direction}
				CommonAction(control, amount);
				if amount <> 0 then
					doANSIScroll(num, amount, true);
			end;
		end;
	end;

	procedure InvertSelection (num: integer; bufPos1, bufPos2: point);
		var
			switch: point;
			tempRect: rect;
			visChars: integer;
	begin
		with gBBSwindows[num]^ do
		begin
			visChars := (ansiRect.right - ansiRect.left) div HERMESFONTWIDTH;
			if (bufPos1.v = bufPos2.v) then
			begin
				if bufPos2.h < bufPos1.h then
				begin
					switch := bufPos1;
					bufPos1 := bufPos2;
					bufPos2 := switch;
				end;
				FromBufPosToPt(num, bufPos1, tempRect.topLeft);
				tempRect.top := tempRect.top - HERMESFONTHEIGHT;
				FromBufPosToPt(num, bufPos2, tempRect.botRight);
				if tempRect.top < ansiRect.top then
					tempRect.top := ansiRect.top;
				if tempRect.bottom > ansiRect.bottom then
					tempRect.bottom := ansiRect.bottom;
				bitclr(ptr(hilitemode), philitebit);
				InvertRect(tempRect);
			end
			else
			begin
				if bufPos2.v < bufPos1.v then
				begin
					switch := bufPos1;
					bufPos1 := bufPos2;
					bufPos2 := switch;
				end;
				if bufPos1.h = 0 then
				begin
					bufPos1.h := 80;
					bufPos1.v := bufPos1.v - 1;
				end;
				if bufPos2.h = visChars then
				begin
					bufPos2.h := 0;
					bufPos2.v := bufPos2.v + 1;
				end;
				if bufPos1.h < 80 then
				begin
					FromBufPosToPt(num, bufPos1, tempRect.topLeft);
					tempRect.top := tempRect.top - HERMESFONTHEIGHT;
					bufPos1.h := visChars;
					FromBufPosToPt(num, bufPos1, tempRect.botRight);
					if tempRect.top < ansiRect.top then
						tempRect.top := ansiRect.top;
					if tempRect.bottom > ansiRect.bottom then
						tempRect.bottom := ansiRect.bottom;
					bitclr(ptr(hilitemode), philitebit);
					InvertRect(tempRect);
				end;
				if (bufPos2.v - bufPos1.v) > 1 then
				begin
					bufPos1.h := 0;
					FromBufPosToPt(num, bufPos1, tempRect.topLeft);
					switch := bufPos2;
					switch.v := switch.v - 1;
					switch.h := visChars;
					FromBufPosToPt(num, switch, tempRect.botRight);
					if tempRect.top < ansiRect.top then
						tempRect.top := ansiRect.top;
					if tempRect.bottom > ansiRect.bottom then
						tempRect.bottom := ansiRect.bottom;
					bitclr(ptr(hilitemode), philitebit);
					InvertRect(tempRect);
				end;
				if (bufPos2.h > 0) then
				begin
					FromBufPosToPt(num, bufPos2, tempRect.botRight);
					bufPos2.h := 0;
					FromBufPosToPt(num, bufPos2, tempRect.topLeft);
					tempRect.top := tempRect.top - HERMESFONTHEIGHT;
					if tempRect.top < ansiRect.top then
						tempRect.top := ansiRect.top;
					if tempRect.bottom > ansiRect.bottom then
						tempRect.bottom := ansiRect.bottom;
					bitclr(ptr(hilitemode), philitebit);
					InvertRect(tempRect);
				end;
			end;
		end;
	end;

	procedure CopySelection (num: integer);
		var
			store: CharsHandle;
			temp: point;
			tempInt: longint;
			i, b: integer;
	begin
		with gBBSwindows[num]^ do
		begin
			if anchor.v > elastic.v then
			begin
				temp := anchor;
				anchor := elastic;
				elastic := temp;
			end
			else if (anchor.v = elastic.v) and (anchor.h > elastic.h) then
			begin
				temp := anchor;
				anchor := elastic;
				elastic := temp;
			end;
			store := CharsHandle(NewHandle(0));
			HNoPurge(handle(store));
			if (anchor.v = elastic.v) then
			begin
				SetHandleSize(handle(store), elastic.h - anchor.h);
				if anchor.v < 0 then
					BlockMove(@bigBuffer^[(sTopLine + (sNumLines + anchor.v)) mod sNumLines][anchor.h], ptr(store^), elastic.h - anchor.h)
				else
					BlockMove(@screen[(topLine + anchor.v) mod 24, anchor.h], ptr(store^), elastic.h - anchor.h);
			end
			else
			begin
				if anchor.h < 80 then
				begin
					if anchor.v < 0 then
					begin
						i := 80;
						while (i > anchor.h) and (bigBuffer^[(sTopLine + (sNumLines + anchor.v)) mod sNumLines][i - 1] = char(32)) do
							i := i - 1;
						SetHandleSize(handle(store), i - anchor.h + 1);
						BlockMove(@bigBuffer^[(sTopLine + anchor.v) mod sNumLines][anchor.h], ptr(store^), i - anchor.h);
					end
					else
					begin
						i := 80;
						while (i > anchor.h) and (screen[(topLine + anchor.v) mod 24, i - 1] = char(32)) do
							i := i - 1;
						SetHandleSize(handle(store), i - anchor.h + 1);
						BlockMove(@screen[(topLine + anchor.v) mod 24, anchor.h], ptr(store^), i - anchor.h);
					end;
					store^^[getHandleSize(handle(store)) - 1] := char(13);
				end;
				if (elastic.v - anchor.v) > 1 then
				begin
					for b := (anchor.v + 1) to (elastic.v - 1) do
					begin
						if b < 0 then
						begin
							i := 80;
							while (i > 0) and (bigBuffer^[(sTopLine + (sNumLines + b)) mod sNumLines][i - 1] = char(32)) do
								i := i - 1;
							tempint := GetHandleSize(handle(store));
							SetHandleSize(handle(store), tempint + i + 1);
							BlockMove(@bigBuffer^[(sTopLine + (sNumLines + b)) mod sNumLines][anchor.h], ptr(ord4(store^) + tempInt), i);
							store^^[getHandleSize(handle(store)) - 1] := char(13);
						end
						else
						begin
							i := 80;
							while (i > 0) and (screen[(topLine + b) mod 24, i - 1] = char(32)) do
								i := i - 1;
							tempint := GetHandleSize(handle(store));
							SetHandleSize(handle(store), tempint + i + 1);
							BlockMove(@screen[(topLine + b) mod 24, 0], ptr(ord4(store^) + tempInt), i);
							store^^[getHandleSize(handle(store)) - 1] := char(13);
						end;
					end;
				end;
				if (elastic.h > 0) then
				begin
					tempInt := GetHandleSize(handle(store));
					SetHandleSize(handle(store), tempInt + elastic.h);
					if elastic.v < 0 then
						BlockMove(@bigBuffer^[(sTopLine + elastic.v) mod sNumLines], ptr(ord4(store^) + tempInt), elastic.h)
					else
						BlockMove(@screen[(topLine + elastic.v) mod 24, 0], ptr(ord4(store^) + tempInt), elastic.h);
				end;
			end;
			tempInt := PutScrap(GetHandleSize(handle(store)), 'TEXT', pointer(store^));
		end;
	end;

	procedure DoANSIClick (num: integer; where: point; shiftIsDown: boolean);
		var
			part, value: integer;
			control: ControlHandle;
			tl: longint;
			oldElastic: point;
			tempRect: rect;
	begin
		with gBBSwindows[num]^ do
		begin
			SetPort(ansiPort);
			GlobalToLocal(where);
			if PtInRect(where, ansiRect) then
			begin
				if stillDown then
				begin
					if selectActive then
						InvertSelection(num, anchor, elastic);
					selectActive := true;
					FromPtToBufPos(num, where, anchor);
					elastic := anchor;
					oldElastic := elastic;
					if cursorOn then
					begin
						InvertRect(cursorRect);
						cursorOn := false;
					end;
					while stillDown do
					begin
						GetMouse(where);
						if (where.v < ansiRect.top) and (scrnTop > -sNumLines) then
						begin
							while (where.v < ansiRect.top) and StillDown do
							begin
								if (scrnTop > -sNumLines) then
								begin
									if anchor.v > scrnTop - 1 then
									begin
										SetCtlValue(ansiVScroll, GetCtlValue(ansiVScroll) - 1);
										doANSIscroll(num, 1, false);
										elastic.h := 0;
										elastic.v := scrnTop;
										InvertSelection(num, oldElastic, elastic);
										oldElastic := elastic;
									end
									else if anchor.v < scrnTop - 1 then
									begin
										elastic.h := 0;
										elastic.v := scrnTop;
										InvertSelection(num, oldElastic, elastic);
										oldElastic := elastic;
										oldElastic.v := oldElastic.v - 1;
										SetCtlValue(ansiVScroll, GetCtlValue(ansiVScroll) - 1);
										doANSIscroll(num, 1, false);
									end
									else
									begin
										elastic.h := 0;
										elastic.v := scrnTop;
										InvertSelection(num, oldElastic, elastic);
										SetCtlValue(ansiVScroll, GetCtlValue(ansiVScroll) - 1);
										doANSIscroll(num, 1, false);
										oldElastic := anchor;
										InvertSelection(num, oldElastic, elastic);
										oldElastic := elastic;
									end;
								end;
								GetMouse(where);
							end;
						end
						else if (where.v > ansiRect.bottom) then
						begin
							while (where.v > ansiRect.bottom) and StillDown do
							begin
								if (scrnBottom < 24) then
								begin
									if anchor.v < scrnBottom then
									begin
										SetCtlValue(ansiVScroll, GetCtlValue(ansiVScroll) + 1);
										doANSIscroll(num, -1, false);
										elastic.h := 80;
										elastic.v := scrnBottom - 1;
										InvertSelection(num, oldElastic, elastic);
										oldElastic := elastic;
									end
									else if (anchor.v > scrnBottom) then
									begin
										elastic.h := 80;
										elastic.v := scrnBottom - 1;
										InvertSelection(num, oldElastic, elastic);
										oldElastic := elastic;
										oldElastic.v := oldElastic.v + 1;
										SetCtlValue(ansiVScroll, GetCtlValue(ansiVScroll) + 1);
										doANSIscroll(num, -1, false);
									end
									else
									begin
										elastic.h := 80;
										elastic.v := scrnBottom - 1;
										InvertSelection(num, oldElastic, elastic);
										SetCtlValue(ansiVScroll, GetCtlValue(ansiVScroll) + 1);
										doANSIscroll(num, -1, false);
										oldElastic := anchor;
										InvertSelection(num, oldElastic, elastic);
										oldElastic := elastic;
									end;
								end;
								GetMouse(where);
							end;
						end;
						FromPtToBufPos(num, where, elastic);
						if longint(elastic) <> longint(oldElastic) then
						begin
							InvertSelection(num, oldElastic, elastic);
						end;
						oldElastic := elastic;
					end;
					if scrnBottom <> 24 then
						scrollFreeze := true
					else
						scrollFreeze := false;
				end
				else
				begin
					if selectActive then
					begin
						selectActive := false;
						InvertSelection(num, anchor, elastic);
					end;
				end;
			end
			else
			begin
				part := FindControl(where, ansiPort, control);
				case part of
					inThumb: 
					begin
						value := GetCtlValue(control);
						part := TrackControl(control, where, nil);
						if part <> 0 then
						begin
							value := value - GetCtlValue(control);
							if value <> 0 then
								doANSIScroll(num, value, true);
						end;
					end;
					otherwise									{must be page or button}
						if control = ansiVScroll then
							value := TrackControl(control, where, @ANSIVactionProc);
				end;
				if getCtlValue(ansiVScroll) <> getCtlMax(ansiVScroll) then
				begin
					scrollFreeze := true;
				end
				else
					scrollFreeze := false;
			end;
		end;
	end;

	function isMyBBSWindow (theWind: windowPtr): integer;  {returns -1 if not}
		var
			i: integer;
	begin
		isMyBBSWindow := -1;
		if theWind <> nil then
			for i := 1 to InitSystHand^^.numNodes do
				if gBBSwindows[i]^.ansiPort = theWind then
					isMyBBSWindow := i;
	end;

	procedure GrowBBSwindow (num: integer; reqWid, reqHei: integer);
		var
			tempRect: rect;
			growResult: longint;
	begin
		with gBBSwindows[num]^ do
		begin
			SetPort(ansiPort);
			reqWid := reqWid - NOTHINGSPACE * 2 - 15;
			reqHei := reqHei - NOTHINGSPACE * 2;
			while reqWid mod HERMESFONTWIDTH <> 0 do
				reqWid := reqWid - 1;
			while reqHei mod HERMESFONTHEIGHT <> 0 do
				reqHei := reqHei - 1;
			SizeWindow(ansiPort, reqWid + NOTHINGSPACE * 2 + 16, reqHei + NOTHINGSPACE * 2, TRUE);
			scrnLines := reqHei div HERMESFONTHEIGHT;
			scrnTop := 24 - scrnLines;
			scrnBottom := 24;
			ansiRect := ansiPort^.portRect;
			ansiRect.top := ansiRect.top + NOTHINGSPACE;
			ansiRect.bottom := ansiRect.bottom - NOTHINGSPACE;
			ansiRect.right := ansiRect.right - 16 - NOTHINGSPACE;
			ansiRect.left := ansiRect.left + NOTHINGSPACE;
			MoveControl(ansiVScroll, ansiPort^.portRect.right - 15, -1);
			SizeControl(ansiVScroll, 16, (ansiPort^.portRect.bottom - ansiPort^.portRect.top) - 13);
			SetCtlMax(ansiVScroll, sNumLines + scrnTop);
			SetCtlValue(ansiVScroll, sNumLines + scrnTop);
			scrollFreeze := false;
			SetCursorPos(num, cursor.h, cursor.v);
			InvalRect(ansiPort^.portRect);
		end;
	end;

	procedure WriteCapt (toWrite: ptr; lengWr: longint);
		var
			result: OSerr;
			count: longInt;
	begin
		with curglobs^ do
		begin
			result := FSWrite(captureRef, lengWr, pointer(toWrite));
		end;
	end;

	procedure termCheckLine (num: integer);
		var
			ts, ZAutoStr: str255;
			i: integer;
			ch: char;
	begin
		with gBBSwindows[num]^ do
		begin
			ts := '';
			for i := 1 to cursor.h do
				ts := concat(ts, ' ');
			BlockMove(@screen[(topLine + cursor.v) mod 24, 0], ptr(ord4(@ts) + 1), cursor.h);
			if (theNodes[num]^.waitDialResponse) and (length(ts) > 0) then
			begin
				if theNodes[num]^.frontCharElim = 5 then
					theNodes[num]^.frontCharElim := 0
				else if ts[1] <> 'R' then
				begin
					if pos('CONNECT', ts) = 1 then
					begin
						SysBeep(10);
						SysBeep(10);
						theNodes[num]^.dialing := false;
						CheckItem(GetMHandle(mTerminal), 5, false);
						InitSystHand^^.BBsdialIt[theNodes[num]^.crossInt] := false;
					end;
					theNodes[num]^.waitDialResponse := false;
					theNodes[num]^.dialDelay := tickCount;
				end;
			end;
		end;
	end;

	procedure ProcessData (num: integer; bufStuff: ptr; lenProc: integer);
		type
			twoChar = packed array[0..1] of char;
			twoChPtr = ^twoChar;
		var
			lineChanged: packed array[0..127] of boolean;
			i, scrolledUp, clearScrn, j, added, visChars, b: integer;
			p, lend, e, f: twoChPtr;
			colorUse: boolean;
			tempRgn, scrolledRgn: RgnHandle;
			drawStyle, g: CharStylePtr;
			r: rect;
			tl1, tl2: longint;
			tempString: str255;
	begin
		with gBBSwindows[num]^ do
		begin
			if curGlobs^.capturing then
				WriteCapt(bufStuff, lenProc);
			if curGlobs^.spying > 0 then
			begin
				activeNode := curGlobs^.spying;
				curGlobs := theNodes[curGlobs^.spying];
				if not curGlobs^.sysopLogon then
					result := AsyncMWrite(curGlobs^.outputRef, lenProc, bufStuff);
				ProcessData(activeNode, bufStuff, lenProc);
				activeNode := num;
				curGlobs := theNodes[num];
			end;
			colorUse := isUsingColor;
			if ansiPort <> nil then
				SetPort(ansiPort);
			if cursorOn then
			begin
				if ansiPort <> nil then
					InvertRect(cursorRect);
				cursorOn := false;
			end;
			for i := 0 to 127 do
				lineChanged[i] := false;
			scrolledUp := 0;
			clearScrn := -1;
			p := twoChPtr(bufStuff);
			lend := twoChPtr(longint(bufStuff) + lenProc);
			while longint(p) < longint(lend) do
			begin
				if ansiState = 0 then
				begin
					if (p^[0] = char(27)) and ansiEnable then
					begin
						ansiState := 1;
						p := pointer(longint(p) + 1);
					end
					else if ((p^[0] >= char(14)) or (p^[0] <= char(6))) and (p^[0] <> char(24)) and (p^[0] <> char(0)) then
					begin
						e := p;
						while (longint(e) < longint(lend)) and ((e^[0] >= char(14)) or (e^[0] <= char(6))) and (e^[0] <> char(27)) and (e^[0] <> char(24)) and (e^[0] <> char(0)) do
							e := twoChPtr(longint(e) + 1);   {loop to next control or end}
						while (cursor.h + longint(e) - longint(p) > 80) do
						begin
							f := pointer(longint(p) + (80 - cursor.h));
							BlockMove(ptr(p), @screen[(cursor.v + topLine) mod 24, cursor.h], longint(f) - longint(p));
							SetStyleRange(@screenInfo[(cursor.v + topLine) mod 24, cursor.h], @screenInfo[(cursor.v + topLine) mod 24, 79], curstyle);
							cursor.h := cursor.h + longint(f) - longint(p);
							if not scrollFreeze and (cursor.v - scrnTop >= 0) then
								lineChanged[cursor.v - scrnTop] := true;
							if cursor.v >= (24 - 1) then
							begin
								scrolledUp := scrolledUp + 1;
								for i := 1 to 127 do
									lineChanged[i - 1] := lineChanged[i];
								AddLineToBuffer(num, @screen[topLine, 0]);
								SetRange(@screen[topLine mod 24, 0], @screen[topLine mod 24, 79], char(32));
								SetStyleRange(@screenInfo[topLine mod 24, 0], @screenInfo[topLine mod 24, 79], curStyle);
								topLine := topLine + 1;
								if topLine >= 24 then
									topLine := 0;
								cursor.h := 0;
								if not scrollFreeze and (cursor.v - scrnTop >= 0) then
									lineChanged[cursor.v - scrnTop] := true;
							end
							else
							begin
								cursor.v := cursor.v + 1;
								cursor.h := 0;
							end;
							p := f;
						end;
						if (longint(e) - longint(p) > 0) then
						begin
							BlockMove(ptr(p), @screen[(cursor.v + topLine) mod 24, cursor.h], longint(e) - longint(p));
							SetStyleRange(@screenInfo[(cursor.v + topLine) mod 24, cursor.h], @screenInfo[(cursor.v + topLine) mod 24, cursor.h + longint(e) - longint(p) - 1], curStyle);
							cursor.h := cursor.h + longint(e) - longint(p);
							if not scrollFreeze and (cursor.v - scrnTop >= 0) then
								lineChanged[cursor.v - scrnTop] := true;
							p := e;
						end;
					end
					else
					begin
						case byte(p^[0]) of
							13: 
								if (ansiEnable) then
								begin
									if (theNodes[num]^.boardMode = Terminal) then
										TermCheckLine(num);
									cursor.h := 0;
								end
								else
								begin
									if (theNodes[num]^.boardMode = Terminal) then
										TermCheckLine(num);
									if cursor.v >= 24 - 1 then
									begin
										scrolledUp := scrolledUp + 1;
										for i := 1 to 127 do
											lineChanged[i - 1] := lineChanged[i];
										AddLineToBuffer(num, @screen[topLine, 0]);
										SetRange(@screen[topLine mod 24, 0], @screen[topLine mod 24, 79], char(32));
										SetStyleRange(@screenInfo[topLine mod 24, 0], @screenInfo[topLine mod 24, 79], curStyle);
										topLine := topLine + 1;
										if topLine >= 24 then
											topLine := 0;
										cursor.h := 0;
										if not scrollFreeze and (cursor.v - scrnTop >= 0) then
											lineChanged[cursor.v - scrnTop] := true;
									end
									else
									begin
										cursor.v := cursor.v + 1;
										cursor.h := 0;
									end;
								end;
							10: 
								if ansiEnable then
								begin
									if (theNodes[num]^.boardMode = Terminal) then
										TermCheckLine(num);
									if cursor.v >= 24 - 1 then
									begin
										scrolledUp := scrolledUp + 1;
										for i := 1 to 127 do
											lineChanged[i - 1] := lineChanged[i];
										AddLineToBuffer(num, @screen[topLine, 0]);
										SetRange(@screen[topLine mod 24, 0], @screen[topLine mod 24, 79], char(32));
										SetStyleRange(@screenInfo[topLine mod 24, 0], @screenInfo[topLine mod 24, 79], curStyle);
										topLine := topLine + 1;
										if topLine >= 24 then
											topLine := 0;
										cursor.h := 0;
										if not scrollFreeze and (cursor.v - scrnTop >= 0) then
											lineChanged[cursor.v - scrnTop] := true;
									end
									else
										cursor.v := cursor.v + 1;
									if not theNodes[num]^.inZScan and not theNodes[num]^.continuous then
										theNodes[num]^.lnsPause := theNodes[num]^.lnsPause + 1;
								end;
							24: 
							begin
								if theNodes[num]^.boardMode = Terminal then
								begin
									if (p^[1] = 'B') and (p^[3] = '0') then
										if (screen[(topLine + cursor.v) mod 24, 0] = '*') and (screen[(topLine + cursor.v) mod 24, 1] = '*') then
											theNodes[num]^.XferAutoStart := 2;
								end;
							end;
							8: 
							begin
								cursor.h := cursor.h - 1;
								if cursor.h < 0 then
									cursor.h := 0;
							end;
							7: 
								if (theNodes[activeNode]^.sysopLogon) or (theNodes[activeNode]^.BoardMode = Terminal) then
									SysBeep(10);
							9: 
							begin
								cursor.h := cursor.h + TABWIDTH;
								cursor.h := cursor.h - (cursor.h mod TABWIDTH);
								if cursor.h >= 79 then
									cursor.h := 79;
							end;
							12: 
							begin
								for i := 0 to 23 do
								begin
									AddLineToBuffer(num, @screen[(i + topLine) mod 24, 0]);
								end;
								topLine := 0;
								SetRange(@screen[0, 0], @screen[23, 79], char(32));
								SetStyleRange(@screenInfo[0, 0], @screenInfo[23, 79], curStyle);
								clearScrn := curStyle.bCol;
								if not scrollFreeze then
								begin
									for i := 0 to 23 do
										if (i - scrnTop) >= 0 then
											lineChanged[i - scrnTop] := false;
									if scrnTop < 0 then
										for i := 1 to abs(scrnTop) do
											lineChanged[i - 1] := true;
								end;
								SetPt(cursor, 0, 0);
								theNodes[num]^.lnsPause := 0;
							end;
							otherwise
						end;
						p := pointer(longint(p) + 1);
					end;
				end
				else
					case ansiState of
						1: 
						begin
							if (p^[0] = '[') then
							begin
								ansiState := 2;
								curParam := -1;
								ansiParams[0] := 0;
							end
							else
								ansiState := 0;
							p := pointer(longint(p) + 1);
						end;
						2: 
						begin
							if (p^[0] >= '0') and (p^[0] <= '9') then
							begin
								if curParam < 0 then
									curParam := 0;
								ansiParams[curParam] := ansiParams[curParam] * 10 + byte(p^[0]) - byte('0');
							end
							else if (p^[0] = ';') then
							begin
								curParam := curParam + 1;
								if (curParam >= 79) then
									curParam := 78;
								ansiParams[curParam] := 0;
							end
							else
							begin
								curParam := curParam + 1;
								case p^[0] of
									'n': 
									begin
										tempString := StringOf(char(27), '[', cursor.v : 0, ';', cursor.h : 0, 'R');
										result := AsyncMWrite(curGlobs^.outputRef, length(tempString), @tempString[1]);
									end;
									'H': 
									begin
										if curparam = 2 then
										begin
											cursor.v := ansiParams[0] - 1;
											cursor.h := ansiParams[1] - 1;
										end
										else if (curParam = 1) then
										begin
											cursor.v := ansiParams[0] - 1;
											cursor.h := 0;
										end
										else if (curParam = 0) then
										begin
											theNodes[num]^.lnsPause := 0;
											cursor.v := 0;
											cursor.h := 0;
										end;
										if cursor.v < 0 then
											cursor.v := 0
										else if cursor.v >= 24 then
											cursor.v := 23;
										if cursor.h < 0 then
											cursor.h := 0
										else if (cursor.h >= 80) then
											cursor.h := 79;
									end;
									'm': 
										if curParam > 0 then
										begin
											for i := 0 to (curParam - 1) do
											begin
												j := ansiParams[i];
												case j of
													0: 
														curStyle := defaultStyle;
													1: 
														curStyle.intense := true;
													4: 
														curStyle.underline := true;
													otherwise
														if ((theNodes[num]^.thisUser.ColorTerminal) or (theNodes[num]^.boardMode <> User)) then
														begin
															if ((j >= 30) and (j < 38)) and theNodes[num]^.thisUser.ColorTerminal then
																curStyle.fcol := j - 30
															else if ((j >= 40) and (j < 48)) then
																curStyle.bcol := j - 40;
														end;
												end;
											end;
										end;
									'A': 
									begin
										if curParam > 0 then
											i := ansiParams[0]
										else
											i := 1;
										cursor.v := cursor.v - i;
										if cursor.v < 0 then
											cursor.v := 0;
									end;
									'B': 
									begin
										if curParam > 0 then
											i := ansiParams[0]
										else
											i := 1;
										cursor.v := cursor.v + i;
										if cursor.v >= 24 then
											cursor.v := 23;
									end;
									'C': 
									begin
										if curParam > 0 then
											i := ansiParams[0]
										else
											i := 1;
										cursor.h := cursor.h + i;
										if cursor.h >= 80 then
											cursor.h := 79;
									end;
									'D': 
									begin
										if curParam > 0 then
											i := ansiParams[0]
										else
											i := 1;
										cursor.h := cursor.h - i;
										if cursor.h < 0 then
											cursor.h := 0;
									end;
									's': 
									begin
										saveV := cursor.v;
										saveH := cursor.h;
									end;
									'u': 
									begin
										cursor.h := saveH;
										cursor.v := saveV;
									end;
									'K': 
									begin
										if curParam = 0 then
										begin
											if not scrollFreeze and (cursor.v - scrnTop >= 0) then
												lineChanged[cursor.v - scrnTop] := true;
											SetRange(@screen[(cursor.v + topLine) mod 24, cursor.h], @screen[(cursor.v + topLine) mod 24, 79], char(32));
											SetStyleRange(@screenInfo[(cursor.v + topLine) mod 24, cursor.h], @screenInfo[(cursor.v + topLine) mod 24, 79], curStyle);
										end;
									end;
									'J': 
										if curParam = 1 then
										begin
											if ansiParams[0] = 2 then
											begin
												for i := 0 to 23 do
												begin
													AddLineToBuffer(num, @screen[(i + topLine) mod 24, 0]);
												end;
												topLine := 0;
												SetRange(@screen[0, 0], @screen[23, 79], char(32));
												SetStyleRange(@screenInfo[0, 0], @screenInfo[23, 79], curStyle);
												clearScrn := curStyle.bCol;
												if not scrollFreeze then
												begin
													for i := 0 to 23 do
														if (i - scrnTop) >= 0 then
															lineChanged[i - scrnTop] := false;
													if scrnTop < 0 then
														for i := 1 to abs(scrnTop) do
															lineChanged[i - 1] := true;
												end;
												clearScrn := curStyle.bCol;
											end;
										end;
									otherwise
								end;
								ansiState := 0;
							end;
							p := pointer(longint(p) + 1);
						end;
						otherwise
					end;
			end;
			if (ansiPort <> nil) and not scrollFreeze then
			begin
				TextFont(HERMESFONTNUMBER);
				TextMode(srcCopy);
				TextSize(HERMESFONTSIZE);
				TextFace([]);
				ForeGround(defaultStyle.fCol);
				BackGround(defaultStyle.bCol);
				visChars := (ansiRect.right - ansiRect.left) div HERMESFONTWIDTH;
				if scrolledUp > 0 then
				begin
					if not gMac.hasColorQD then
					begin
						ForeGround(0);
						BackGround(7);
					end;
					tempRgn := NewRgn;
					ScrollRect(ansiRect, 0, -HERMESFONTHEIGHT * scrolledUp, tempRgn);
					if not (gMac.hasColorQD) then
					begin
						BackGround(defaultStyle.bCol);
						EraseRgn(tempRgn);
					end;
					scrolledRgn := NewRgn;
					SetRectRgn(scrolledRgn, ansiRect.left, ansiRect.top + (HERMESFONTHEIGHT * (scrnLines - scrolledUp)), ansiRect.right, ansiRect.top + (HERMESFONTHEIGHT * scrnLines));
					DiffRgn(tempRgn, scrolledRgn, tempRgn);
					if not EmptyRgn(tempRgn) then
						ForceUpdate(num, tempRgn);
					DisposeRgn(scrolledRgn);
					DisposeRgn(tempRgn);
				end;
				if clearScrn >= 0 then
				begin
					if colorUse then
						BackGround(clearScrn);
					EraseRect(ansiRect);
				end;
				if scrnTop < 0 then
				begin
					tl1 := sTopLine + (sNumLines - 1);
					if tl1 > (sNumLines - 1) then
						tl1 := tl1 - (sNumLines - 1) - 1;
					for i := abs(scrnTop) downto 1 do
					begin
						if lineChanged[i - 1] then
						begin
							MoveTo(ansiRect.left, ansiRect.top + i * HERMESFONTHEIGHT - 2);
							DrawText(@bigbuffer^[tl1], 0, visChars);
						end;
						tl1 := tl1 - 1;
						if tl1 < 0 then
							tl1 := sNumLines - 1;
					end;
				end;
				for i := 0 to 23 do
				begin
					if lineChanged[i - scrnTop] and (i >= scrnTop) then
					begin
						p := pointer(@screenInfo[(i + topLine) mod 24, 0]);
						e := pointer(longint(p) + (visChars * SizeOf(charStyle)));
						j := 0;
						while longint(p) < longint(e) do
						begin
							added := 0;
							drawStyle := CharStylePtr(p);
							g := CharStylePtr(p);
							while (longint(g) < longint(e)) and EqualStyle(g^, drawStyle^) do
							begin
								g := CharStylePtr(longint(g) + SizeOf(charStyle));
								added := added + 1;
							end;
							if drawStyle^.intense and drawStyle^.underline then
								TextFace([bold, underline])
							else if (drawStyle^.intense and InitSystHand^^.UseBold) or (drawStyle^.intense and not IsUsingColor) then
								TextFace([bold])
							else if drawStyle^.intense then
								drawStyle^.fcol := drawStyle^.fcol + 8
							else
								TextFace([]);
							if not colorUse then
							begin
								drawStyle^.fcol := defaultStyle.fcol;
								drawStyle^.bcol := defaultStyle.bcol;
							end;
							ForeGround(drawStyle^.fCol);
							BackGround(drawStyle^.bCol);
							if (drawStyle^.intense and not InitSystHand^^.useBold) or (drawStyle^.intense and IsUsingColor) then
								drawStyle^.fcol := drawStyle^.fcol - 8;
							MoveTo(ansiRect.left + j * HERMESFONTWIDTH, ansiRect.top + (i + 1 - scrnTop) * HERMESFONTHEIGHT - HERMESFONTDESCENT);
							DrawText(@screen[(i + topLine) mod 24, j], 0, added);
							j := j + added;
							p := pointer(longint(p) + (added * SizeOf(charStyle)));
						end;
					end;
				end;
			end;
			SetCursorPos(num, cursor.h, cursor.v);
		end;
	end;

	procedure CloseANSIWindow (num: integer);
		var
			i: integer;
			tempRect: rect;
	begin
		if gBBSwindows[num] <> nil then
		begin
			with gBBSwindows[num]^ do
			begin
				if ansiPort <> nil then
				begin
					SetPort(ansiPort);
					tempRect := ansiPort^.portrect;
					LocalToGlobal(tempRect.topLeft);
					LocalToGlobal(tempRect.botRight);
					InitSystHand^^.wNodesUser[num] := savedWPos;
					InitSystHand^^.wNodesStd[num] := tempRect;
					if quit = 0 then
						InitSystHand^^.wIsOpen[num] := false;
					if gBBSwindows[num]^.ansiVScroll <> nil then
						DisposeControl(gBBSwindows[num]^.ansiVScroll);
					gBBSwindows[num]^.ansiVScroll := nil;
					if gBBSwindows[num]^.ansiPort <> nil then
						DisposeWindow(gBBSwindows[num]^.ansiPort);
					gBBSwindows[num]^.ansiPort := nil;
				end;
			end;
		end;
	end;

	procedure DisposeANSIWindow (num: integer);
	begin
		if gBBSwindows[num] <> nil then
		begin
			if gBBSwindows[num]^.ansiPort <> nil then
				CloseANSIWindow(num);
			DisposPtr(ptr(gBBSwindows[num]^.bigBuffer));
			DisposPtr(ptr(gBBSwindows[num]));
		end;
	end;

	procedure OpenANSIWindow (num: integer);
		var
			tRect, t2, defRect: rect;
			ts1: str255;
	begin
		with gBBSwindows[num]^ do
		begin
			SetRect(defRect, 2 + ((num - 1) * 2), 40 + (((num - 1) mod 10) * 20), 2 + ((num - 1) * 2) + (NOTHINGSPACE * 2) + 16 + (HERMESFONTWIDTH * 80), 40 + (((num - 1) mod 10) * 20) + (HERMESFONTHEIGHT * 26) + (NOTHINGSPACE * 2));
			SetRect(t2, 0, 0, 0, 0);
			if EqualRect(t2, InitSystHand^^.wNodesStd[num]) or (EqualRect(t2, InitSystHand^^.wNodesUser[num])) then
			begin
				InitSystHand^^.wNodesStd[num] := defRect;
				InitSystHand^^.wNodesUser[num] := defrect;
			end;
			tRect := InitSystHand^^.wNodesStd[num];
			if (tRect.bottom > screenBits.bounds.bottom) or (tRect.right > screenBits.bounds.right) then
				tRect := defRect;
			InitSystHand^^.wIsOpen[num] := true;
			if theNodes[num]^.thisUser.userNum > 0 then
				ts1 := StringOf(num : 0, ': ', theNodes[num]^.thisUser.userName)
			else
				ts1 := theNodes[num]^.NodeName;
			if isusingcolor then
				ansiPort := NewCWindow(nil, tRect, ts1, false, 8, pointer(-1), true, 0);
			if (not isusingcolor) or (ansiport = nil) then
				ansiPort := NewWindow(nil, tRect, ts1, false, 8, pointer(-1), true, 0);
			if ansiPort <> nil then
			begin
				SetPort(ansiPort);
				savedWPos := InitSystHand^^.wNodesUser[num];
				ansiRect := ansiPort^.portRect;
				ansiRect.top := ansiRect.top + NOTHINGSPACE;
				ansiRect.bottom := ansiRect.bottom - NOTHINGSPACE;
				ansiRect.right := ansiRect.right - 16 - NOTHINGSPACE;
				ansiRect.left := ansiRect.left + NOTHINGSPACE;
				scrnLines := (ansiRect.bottom - ansiRect.top) div HERMESFONTHEIGHT;
				scrnTop := 24 - scrnLines;
				scrnBottom := 24;
				SetRect(tRect, ansiPort^.portRect.right - 15, -1, ansiPort^.portRect.right + 1, ansiPort^.portRect.bottom - 14);
				ansiVScroll := NewControl(ansiPort, tRect, '', true, sNumLines + scrnTop, 0, sNumLines + scrnTop, 16, 0);
				ShowWindow(ansiPort);
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

	procedure AllocateANSIwindow (num: integer);
	begin
		gBBSwindows[num] := myANSIWindPtr(NewPtr(SizeOf(myANSIWindow)));
		if memError = noErr then
		begin
			with gBBSwindows[num]^ do
			begin
				visibleNode := num;
				ansiPort := nil;
				SetPt(cursor, 0, 0);
				topLine := 0;
				SetRange(@screen[0, 0], @screen[23, 79], char(32));
				SetStyleRange(@screenInfo[0, 0], @screenInfo[23, 79], defaultStyle);
				sNumLines := theNodes[num]^.bufLns;
				bigBuffer := scrnKeysPtr(NewPtr(SizeOf(aLine) * sNumLines));
				if bigBuffer <> nil then
					EraseBuffer(bigBuffer, sNumLines);
				sTopLine := 0;
				ansiState := 0;
				ansiEnable := true;
				cursorOn := false;
				curStyle := defaultStyle;
				scrnLines := 26;
				scrnTop := -2;
				scrnBottom := 24;
				scrollFreeze := false;
				selectActive := false;
				saveH := 0;
				saveV := 0;
				if InitSystHand^^.wIsOpen[num] then
					OpenANSIWindow(num);
			end;
		end;
	end;

	procedure UpdateProgress;
		var
			tempint, ti2, ti3, cps: integer;
			aHandle: handle;
			ts, ts2, ts3, ts4: str255;
			temprect: rect;
			tempLong, tl2: longint;
	begin
		with curglobs^ do
		begin
			if (transDilg <> nil) and InitSystHand^^.useXWind then
			begin
				setPort(transDilg);
				if ExtTrans^^.curBytesTotal > 0 then
				begin
					GetDItem(transDilg, 5, tempInt, aHandle, tempRect);
					ForeColor(blackColor);
					EraseRect(tempRect);
					FrameRect(tempRect);
					ForeColor(GreenColor);
					tempInt := ((tempRect.right - tempRect.left) * extTrans^^.curBytesDone) div extTrans^^.curBytesTotal;
					if tempInt > (tempRect.right - tempRect.left) then
						tempint := (tempRect.right - tempRect.left);
					tempRect.right := tempRect.left + tempInt;
					if tempRect.right > temprect.left then
					begin
						InsetRect(tempRect, 1, 1);
						PaintRect(tempRect);
					end;
					ForeColor(blackColor);
				end;
				GetDItem(transDilg, 7, tempInt, aHandle, tempRect);
				NumTostring(extTrans^^.curBytesDone, ts);
				NumToString(extTrans^^.curbytesTotal, ts2);
				if extTrans^^.curBytesTotal > 0 then
					ts3 := concat(ts, ' bytes out of ', ts2)
				else
					ts3 := concat(ts, ' bytes.');
				SetIText(aHandle, ts3);
				GetDItem(transDilg, 8, tempInt, aHandle, tempRect);
				cps := 0;
				if (tickCount - extTrans^^.curStartTime > 0) then
					templong := ((tickCount - extTrans^^.curStartTime) div 60)
				else
					templong := -1;
				if templong > 0 then
					cps := (extTrans^^.curBytesDone - startCPS) div templong;
				if cps < 0 then
					cps := 0;
				NumToString(cps, ts3);
				ts3 := concat(ts3, ' cps');
				if currentBaud > 10 then
				begin
					templong := trunc(100 * (cps / (currentBaud div 10)));
					NumToString(templong, ts2);
					ts3 := concat(ts3, ', ', ts2, '%');
					if extTrans^^.curBytesDone > 0 then
					begin
						tempLong := longint(((tickCount - extTrans^^.curStartTime) div 60) * longint(extTrans^^.curBytesTotal - extTrans^^.curBytesDone)) div extTrans^^.curBytesDone;
						ts3 := concat(ts3, ', ETF: ', SexToTime(tempLong));
					end;
				end;
				SetIText(aHandle, ts3);
				if extTrans^^.fileCount > 1 then
				begin
					GetDItem(transDilg, 11, tempInt, aHandle, tempRect);
					NumToString(extTrans^^.filesDone + 1, ts);
					NumToString(extTrans^^.fileCount, ts2);
					SetIText(aHandle, concat('Batch: ', ts, ' out of ', ts2, '.'));
				end;
			end
			else if (gBBSwindows[activeNode]^.ansiPort <> nil) and (transDilg = nil) then
			begin
				if (extTrans^^.curBytesTotal > 0) then
				begin
					tempLong := extTrans^^.curBytesTotal - extTrans^^.curBytesDone;
					if tempLong < 0 then
						tempLong := 0;
					NumToString(tempLong, ts);
					ts2 := 'Bytes Left: '
				end
				else
				begin
					ts2 := 'Bytes Done: ';
					NumToString(extTrans^^.curBytesDone, ts);
				end;
				cps := 0;
				templong := ((tickCount - extTrans^^.curStartTime) div 60);
				if templong > 0 then
					cps := (extTrans^^.curBytesDone - startCPS) div templong;
				if cps < 0 then
					cps := 0;
				NumToString(cps, ts3);
				if (extTrans^^.curBytesTotal > 0) then
					ts3 := concat(ts3, ' cps')
				else
					ts3 := '? cps';
				ts := concat(char(27), '[24H', ts2, ts, ', ', ts3, '        ');
				ProcessData(activeNode, @ts[1], length(ts));
			end;
		end;
	end;
end.