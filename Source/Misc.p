{ Segments: Misc_1 }
unit Misc;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, User;

	procedure Open_FB_Edit;
	procedure Close_FB_Edit;
	procedure Update_FB_Edit;
	procedure Do_FB_Edit (theEvent: EventRecord; itemHit: integer);
	procedure OpenSystemPrefs;
	procedure CloseSystemPrefs;
	procedure UpdateSystemPrefs;
	procedure DoSystemPrefs (theEvent: EventRecord; itemHit: integer);
	procedure Open_Security;
	procedure Close_Security;
	procedure Update_Security;
	procedure Do_Security (theEvent: EventRecord; ItemHit: Integer);
	procedure Open_Access;
	procedure Close_Access;
	procedure Update_Access;
	procedure Do_Access (theEvent: EventRecord; itemHit: Integer);
	procedure Open_New;
	procedure Close_New;
	procedure Update_New;
	procedure Do_New (theEvent: EventRecord; itemHit: Integer);
	procedure Open_GFiles;
	procedure Update_GFiles;
	procedure Close_GFiles;
	procedure Do_Gfiles (theEvent: EventRecord; itemHit: Integer);

implementation

	procedure SetFontVars;
	external;
	procedure OpenANSIWindow (num: integer);
	external;
	procedure CloseANSIWindow (num: integer);
	external;

	var
		ExitDialog: Boolean;
		tempRect: Rect;
		DItem: Handle;
		CItem, CTempItem: controlhandle;
		curSec, curEditSec, temp, DType, Index, ItemHit: Integer;
		FeedBackList, MUserList, secList, tempLHand: ListHandle;
		cSize: Point;

{$S Misc_1}
	procedure GetFields;
		var
			ccc: cell;
			t1: Str255;
	begin
		intGFileRec^^.sections[CurEditSec].SecName := GetTextBox(GFileSelection, 3);
		t1 := GetTextBox(GFileSelection, 17);
		if (length(t1) > 0) and ((t1[1] >= 'A') and (t1[1] <= 'Z')) then
			intGFileRec^^.sections[CurEditSec].Restrict := t1[1]
		else
			intGFileRec^^.sections[CurEditSec].Restrict := char(0);
		if length(intGFileRec^^.sections[CurEditSec].SecName) = 0 then
			SysBeep(1);
		ccc.h := 0;
		ccc.v := CurEditSec - 1;
		LSetCell(ptr(ord4(@intGFileRec^^.sections[CurEditSec].SecName) + 1), length(intGFileRec^^.sections[CurEditSec].SecName), ccc, tempLHand);
	end;

	procedure SetSecLevel;
		var
			tempString: str255;
			i: integer;
	begin
		SetTextBox(GetSelection, 3, SecLevels^^[CurSec].Class);
		SetTextBox(GetSelection, 5, stringOf(SecLevels^^[CurSec].DLRatioOneTo : 0));
		SetTextBox(GetSelection, 25, stringOf(SecLevels^^[CurSec].PostRatioOneTo : 0));
		SetTextBox(GetSelection, 27, stringOf(SecLevels^^[CurSec].MesgDay : 0));
		SetTextBox(GetSelection, 29, stringOf(SecLevels^^[CurSec].LnsMessage : 0));
		SetTextBox(GetSelection, 31, stringOf(SecLevels^^[CurSec].CallsPrDay : 0));
		SetTextBox(GetSelection, 33, stringOf(SecLevels^^[CurSec].TimeAllowed : 0));
		SetTextBox(GetSelection, 53, stringOf(SecLevels^^[CurSec].TransLevel : 0));
		for i := 1 to 26 do
			SetCheckBox(GetSelection, 76 + i, SecLevels^^[curSec].Restrics[i]);
		SetCheckBox(GetSelection, 34, False);
		SetCheckBox(GetSelection, 36, False);
		if SecLevels^^[CurSec].UseDayOrCall then
			SetCheckBox(GetSelection, 34, true)
		else
			SetCheckBox(GetSelection, 36, true);
		SetCheckBox(GetSelection, 54, SecLevels^^[curSec].ReadAnon);
		SetCheckBox(GetSelection, 63, SecLevels^^[curSec].BBSList);
		SetCheckBox(GetSelection, 64, SecLevels^^[curSec].Uploader);
		SetCheckBox(GetSelection, 57, SecLevels^^[curSec].UDRatio);
		SetCheckBox(GetSelection, 56, SecLevels^^[curSec].PostMessage);
		SetCheckBox(GetSelection, 55, SecLevels^^[curSec].Chat);
		SetCheckBox(GetSelection, 60, SecLevels^^[curSec].Email);
		SetCheckBox(GetSelection, 62, SecLevels^^[curSec].ListUser);
		SetCheckBox(GetSelection, 61, SecLevels^^[curSec].AutoMsg);
		SetCheckBox(GetSelection, 59, SecLevels^^[curSec].AnonMsg);
		SetCheckBox(GetSelection, 58, SecLevels^^[curSec].PCRatio);
		SetCheckBox(GetSelection, 159, SecLevels^^[curSec].EnableHours);
		SetCheckBox(GetSelection, 160, SecLevels^^[curSec].PPFile);
		SetCheckBox(GetSelection, 164, SecLevels^^[curSec].CantNetMail);
		SetCheckBox(GetSelection, 148, SecLevels^^[curSec].MustRead);

		SetCheckBox(GetSelection, 48, SecLevels^^[curSec].Active);
		SetTextBox(GetSelection, 151, stringof(SecLevels^^[curSec].messcomp : 1 : 1));
		SetTextBox(GetSelection, 152, stringof(SecLevels^^[curSec].xfercomp : 1 : 1));
		SetCheckBox(GetSelection, 161, false);
		SetCheckBox(GetSelection, 162, false);
		if SecLevels^^[curSec].AlternateText then
			SetCheckBox(GetSelection, 162, true)
		else
			SetCheckBox(GetSelection, 161, true);
	end;

	procedure Close_Security;
		var
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (GetSelection <> nil) then
		begin
			SecLevels^^[curSec].class := GetTextBox(GetSelection, 3);
			LDispose(secList);
			DisposDialog(GetSelection);
			GetSelection := nil;
			DoSecRec(true);
		end;
	end;

	procedure Close_Access;
		var
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (AccessDilg <> nil) then
		begin
			DisposDialog(AccessDilg);
			AccessDilg := nil;
			if GetSelection <> nil then
			begin
				for i := 65 to 70 do
					SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 64]);
				for i := 107 to 112 do
					SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 100]);
				SetTextBox(GetSelection, 120, InitSystHand^^.Restrictions[13]);
				for i := 122 to 128 do
					SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 108]);
				for i := 132 to 135 do
					SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 111]);
				SetTextBox(GetSelection, 140, InitSystHand^^.Restrictions[25]);
				SetTextBox(GetSelection, 142, InitSystHand^^.Restrictions[26]);
			end;
		end;
	end;

	procedure Close_New;
		var
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (NewDilg <> nil) then
		begin
			for i := 1 to 3 do
				NewHand^^.SysOpText[i] := GetTextBox(NewDilg, 19 + i);
			DisposDialog(NewDilg);
			NewDilg := nil;
			LoadNewUser(True);
			DoSystRec(True);
		end;
	end;

	procedure Close_GFiles;
		var
			tempString, t1: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			ts: Str255;
			result: longint;
	begin
		if (GFileSelection <> nil) then
		begin
			if (intGFileRec^^.numSecs > 0) and (curEditSec <> -1) then
			begin
				intGFileRec^^.sections[CurEditSec].SecName := GetTextBox(GFileSelection, 3);
				t1 := GetTextBox(GFileSelection, 17);
				if (length(t1) > 0) and ((t1[1] >= 'A') and (t1[1] <= 'Z')) then
					intGFileRec^^.sections[CurEditSec].Restrict := t1[1]
				else
					intGFileRec^^.sections[CurEditSec].Restrict := char(0);
				for i := 1 to intGFileRec^^.numSecs do
				begin
					ts := concat(InitSystHand^^.GFilePath, intGFileRec^^.sections[i].secName);
					result := MakeADir(ts);
				end;
			end;
			LDispose(tempLHand);
			DisposDialog(GFileSelection);
			GFileSelection := nil;
			doGFileRec(true);
		end;
	end;

	procedure Update_Access;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (AccessDilg <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(AccessDilg);
			DrawDialog(AccessDilg);
			setPort(savedPort);
		end;
	end;

	procedure Update_New;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (NewDilg <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(NewDilg);
			DrawDialog(NewDilg);
			setPort(savedPort);
		end;
	end;

	procedure Update_GFiles;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (GFileSelection <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(GFileSelection);
			DrawDialog(GFileSelection);
			LUpdate(GFileSelection^.visRgn, tempLHand);
			setPort(savedPort);
		end;
	end;

	procedure Update_Security;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (GetSelection <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(GetSelection);
			DrawDialog(GetSelection);

			tempRect := secList^^.rView;
			if (tempRect.Right <= (tempRect.Left + 10)) then
				tempRect.Right := tempRect.Left + 10;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			LUpdate(GetSelection^.visRgn, secList);

			setPort(savedPort);
		end;
	end;

	procedure Do_Access (theEvent: EventRecord; ItemHit: Integer);
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			ttUser: userRec;
	begin
		if (AccessDilg <> nil) then
		begin
			SetPort(AccessDilg);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(AccessDilg, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			case itemHit of
				54: 
				begin
					for i := 27 to 52 do
					begin
						InitSystHand^^.restrictions[i - 26] := GetTextBox(AccessDilg, i);
					end;
					DoSystRec(True);
					Close_Access;
				end;
				53: 
					Close_Access;
			end;
		end;
	end;

	procedure Do_Security (theEvent: EventRecord; ItemHit: Integer);
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			ttUser: userRec;
			adder: integer;
			adder2: real;
	begin
		if (GetSelection <> nil) then
		begin
			SetPort(GetSelection);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(GetSelection, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			adder := 10;
			adder2 := 1.0;
			if optiondown then
			begin
				adder := 1;
				adder2 := 0.1;
			end;
			case itemHit of
				1: 
				begin
					DoubleClick := LClick(myPt, theEvent.modifiers, SecList);
					tempCell.v := 0;
					tempCell.h := 0;
					if LGetSelect(true, TempCell, SecList) then
					begin
						SecLevels^^[curSec].class := GetTextBox(GetSelection, 3);
						curSec := TempCell.v + 1;
						SetSecLevel;
					end;
				end;
				147: 
					Open_Access;
				161: 
				begin
					SecLevels^^[curSec].AlternateText := false;
					SetCheckBox(GetSelection, 162, false);
					SetCheckBox(GetSelection, 161, true);
				end;
				162: 
				begin
					SecLevels^^[curSec].AlternateText := true;
					SetCheckBox(GetSelection, 161, false);
					SetCheckBox(GetSelection, 162, true);
				end;
				34, 36: 
				begin
					if not ((ItemHit = 34) and (GetCheckBox(GetSelection, 34)) or (ItemHit = 36) and (GetCheckBox(GetSelection, 36))) then
					begin
						SetCheckBox(GetSelection, 34, false);
						SetCheckBox(GetSelection, 36, false);
						if ItemHit = 34 then
						begin
							SetCheckBox(GetSelection, 34, true);
							SecLevels^^[curSec].UseDayOrCall := True;
						end
						else
						begin
							SetCheckBox(GetSelection, 36, true);
							SecLevels^^[curSec].UseDayOrCall := False;
						end;
					end;
				end;
				77..102: 
				begin
					if SecLevels^^[curSec].Restrics[ItemHit - 76] then
						SecLevels^^[curSec].Restrics[ItemHit - 76] := false
					else
						SecLevels^^[curSec].Restrics[ItemHit - 76] := true;
					SetCheckBox(GetSelection, ItemHit, SecLevels^^[curSec].Restrics[ItemHit - 76]);
				end;
				6, 7: 
				begin
					if (itemHit = 6) then
						adder := adder * (-1);
					SecLevels^^[curSec].DLRatioOneTo := UpDown(GetSelection, 5, SecLevels^^[CurSec].DLRatioOneTo, Adder, 99, 0);
				end;
				9, 10: 
				begin
					if (itemHit = 9) then
						adder := adder * (-1);
					SecLevels^^[curSec].PostRatioOneTo := UpDown(GetSelection, 25, SecLevels^^[CurSec].PostRatioOneTo, Adder, 99, 0);
				end;
				12, 13: 
				begin
					if (itemHit = 12) then
						adder := adder * (-1);
					SecLevels^^[curSec].MesgDay := UpDown(GetSelection, 27, SecLevels^^[CurSec].MesgDay, Adder, 999, 0);
				end;
				15, 16: 
				begin
					if (itemHit = 15) then
						adder := adder * (-1);
					SecLevels^^[curSec].LnsMessage := UpDown(GetSelection, 29, SecLevels^^[CurSec].LnsMessage, Adder, 200, 0);
				end;
				18, 19: 
				begin
					if (itemHit = 18) then
						adder := adder * (-1);
					SecLevels^^[curSec].CallsPrDay := UpDown(GetSelection, 31, SecLevels^^[CurSec].CallsPrDay, Adder, 999, 0);
				end;
				49, 50: 
				begin
					if (itemHit = 49) then
						adder := adder * (-1);
					SecLevels^^[curSec].TransLevel := UpDown(GetSelection, 53, SecLevels^^[curSec].TransLevel, Adder, 255, 0);
				end;
				153, 154: 
				begin
					if (itemHit = 153) then
						adder2 := adder2 * (-1);
					SecLevels^^[curSec].messcomp := UpDownReal(GetSelection, 151, SecLevels^^[curSec].messcomp, Adder2, 99.9, 0.00);
				end;
				156, 157: 
				begin
					if (itemHit = 156) then
						adder2 := adder2 * (-1);
					SecLevels^^[curSec].xfercomp := UpDownReal(GetSelection, 152, SecLevels^^[curSec].xfercomp, Adder2, 99.9, 0.00);
				end;
				21, 22: 
				begin
					if (itemHit = 21) then
						adder := adder * (-1);
					SecLevels^^[CurSec].TimeAllowed := UpDown(GetSelection, 33, SecLevels^^[CurSec].TimeAllowed, Adder, 999, 0);
				end;
				54: 
				begin
					if SecLevels^^[curSec].ReadAnon then
						SecLevels^^[curSec].ReadAnon := false
					else
						SecLevels^^[curSec].ReadAnon := true;
					SetCheckBox(GetSelection, 54, SecLevels^^[curSec].ReadAnon);
				end;
				63: 
				begin
					if SecLevels^^[curSec].BBSList then
						SecLevels^^[curSec].BBSList := false
					else
						SecLevels^^[curSec].BBSList := true;
					SetCheckBox(GetSelection, 63, SecLevels^^[curSec].BBSList);
				end;
				64: 
				begin
					if SecLevels^^[curSec].Uploader then
						SecLevels^^[curSec].Uploader := false
					else
						SecLevels^^[curSec].Uploader := true;
					SetCheckBox(GetSelection, 64, SecLevels^^[curSec].Uploader);
				end;
				57: 
				begin
					if SecLevels^^[curSec].UDRatio then
						SecLevels^^[curSec].UDRatio := false
					else
						SecLevels^^[curSec].UDRatio := true;
					SetCheckBox(GetSelection, 57, SecLevels^^[curSec].UDRatio);
				end;
				56: 
				begin
					if SecLevels^^[curSec].PostMessage then
						SecLevels^^[curSec].PostMessage := false
					else
						SecLevels^^[curSec].PostMessage := true;
					SetCheckBox(GetSelection, 56, SecLevels^^[curSec].PostMessage);
				end;
				55: 
				begin
					if SecLevels^^[curSec].Chat then
						SecLevels^^[curSec].Chat := false
					else
						SecLevels^^[curSec].Chat := true;
					SetCheckBox(GetSelection, 55, SecLevels^^[curSec].Chat);
				end;
				148: 
				begin
					if SecLevels^^[curSec].MustRead then
						SecLevels^^[curSec].MustRead := false
					else
						SecLevels^^[curSec].MustRead := true;
					SetCheckBox(GetSelection, 148, SecLevels^^[curSec].MustRead);
				end;
				48: 
				begin
					if SecLevels^^[curSec].Active then
						SecLevels^^[curSec].Active := false
					else
						SecLevels^^[curSec].Active := true;
					SetCheckBox(GetSelection, 48, SecLevels^^[curSec].Active);
				end;
				60: 
				begin
					if SecLevels^^[curSec].Email then
						SecLevels^^[curSec].Email := false
					else
						SecLevels^^[curSec].Email := true;
					SetCheckBox(GetSelection, 60, SecLevels^^[curSec].Email);
				end;
				62: 
				begin
					if SecLevels^^[curSec].ListUser then
						SecLevels^^[curSec].ListUser := false
					else
						SecLevels^^[curSec].ListUser := true;
					SetCheckBox(GetSelection, 62, SecLevels^^[curSec].ListUser);
				end;
				61: 
				begin
					if SecLevels^^[curSec].AutoMsg then
						SecLevels^^[curSec].AutoMsg := false
					else
						SecLevels^^[curSec].AutoMsg := true;
					SetCheckBox(GetSelection, 61, SecLevels^^[curSec].AutoMsg);
				end;
				59: 
				begin
					if SecLevels^^[curSec].AnonMsg then
						SecLevels^^[curSec].AnonMsg := false
					else
						SecLevels^^[curSec].AnonMsg := true;
					SetCheckBox(GetSelection, 59, SecLevels^^[curSec].AnonMsg);
				end;
				58: 
				begin
					if SecLevels^^[curSec].PCRatio then
						SecLevels^^[curSec].PCRatio := false
					else
						SecLevels^^[curSec].PCRatio := true;
					SetCheckBox(GetSelection, 58, SecLevels^^[curSec].PCRatio);
				end;
				159: 
				begin
					SecLevels^^[curSec].EnableHours := not SecLevels^^[curSec].EnableHours;
					SetCheckBox(GetSelection, 159, SecLevels^^[curSec].EnableHours);
				end;
				160: 
				begin
					SecLevels^^[curSec].PPFile := not SecLevels^^[curSec].PPFile;
					SetCheckBox(GetSelection, 160, SecLevels^^[curSec].PPFile);
				end;
				164: 
				begin
					SecLevels^^[curSec].CantNetMail := not SecLevels^^[curSec].CantNetMail;
					SetCheckBox(GetSelection, 164, SecLevels^^[curSec].CantNetMail);
				end;
				otherwise
			end;
		end;
	end;

	procedure Open_Security;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			tempString: Str255;
	begin
		if (GetSelection = nil) then
		begin
			GetSelection := GetNewDialog(799, nil, pointer(-1));
			SetPort(GetSelection);
			SetGeneva(GetSelection);
			DrawDialog(GetSelection);
			GetDItem(GetSelection, 1, Dtype, Ditem, TempRect);
			TempRect.right := tempRect.right - 14;
			SetRect(tr2, 0, 0, 1, 0);
			SetPt(myC, tempRect.right - tempRect.left, 12);
			SecList := LNew(TempRect, tr2, myC, 2048, GetSelection, False, False, False, True);
			SecList^^.selFlags := lOnlyOne + lNoNilHilite;
			for i := 1 to 255 do
			begin
				if SecLevels^^[i].Active then
					AddListString(StringOf('•', i : 0), SecList)
				else
					AddListString(StringOf(i : 0), SecList);
			end;
			LdoDraw(True, SecList);
			CurSec := 1;
			for i := 65 to 70 do
				SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 64]);
			for i := 107 to 112 do
				SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 100]);
			SetTextBox(GetSelection, 120, InitSystHand^^.Restrictions[13]);
			for i := 122 to 128 do
				SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 108]);
			for i := 132 to 135 do
				SetTextBox(GetSelection, i, InitSystHand^^.Restrictions[i - 111]);
			SetTextBox(GetSelection, 140, InitSystHand^^.Restrictions[25]);
			SetTextBox(GetSelection, 142, InitSystHand^^.Restrictions[26]);
			SetSecLevel;
			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, SecList);
			ShowWindow(GetSelection);
			SelectWindow(GetSelection);
		end
		else
			SelectWindow(GetSelection);
	end;

	procedure Open_Access;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			tempString: Str255;
	begin
		if (AccessDilg = nil) then
		begin
			AccessDilg := GetNewDialog(798, nil, pointer(-1));
			SetPort(AccessDilg);
			ShowWindow(AccessDilg);
			SetGeneva(AccessDilg);
			for i := 27 to 52 do
				SetTextBox(AccessDilg, i, InitSystHand^^.Restrictions[i - 26]);
			SelectWindow(AccessDilg);
		end
		else
			SelectWindow(AccessDilg);
	end;


	procedure Open_GFiles;
		var
			tempRect, tr2, r, databounds: Rect;
			myC, myPt: Point;
			DType, i, kind, hm, wm, wid: Integer;
			DItem: Handle;
			tempString, ts: Str255;
			myPop: popupHand;
			h: Handle;
			CItem: ControlHandle;
			test: longint;
	begin
		if (GFileSelection = nil) then
		begin
			GFileSelection := GetNewDialog(1069, nil, pointer(-1));
			SetPort(GFileSelection);
			ShowWindow(GFileSelection);
			SetGeneva(GFileSelection);
			CurEditSec := -1;
			GetDItem(GFileSelection, 1, dType, dItem, tempRect);
			TempRect.Right := TempRect.Right - 15;
			InsetRect(TempRect, -1, -1);
			FrameRect(TempRect);
			InsetRect(TempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			cSize.h := TempRect.Right - TempRect.Left;
			cSize.v := 12;
			tempLHand := LNew(TempRect, dataBounds, cSize, 0, GFileSelection, FALSE, FALSE, FALSE, TRUE);
			tempLHand^^.selFlags := lOnlyOne;
			cSize.h := 0;
			cSize.v := 0;
			if intGFileRec^^.numSecs > 0 then
			begin
				i := LAddRow(intGFileRec^^.numSecs, 800, tempLHand);
				for i := 1 to intGFileRec^^.numSecs do
				begin
					cSize.v := i - 1;
					ts := intGFileRec^^.sections[i].secname;
					LSetCell(Pointer(ord(@ts) + 1), length(ts), cSize, tempLHand);
				end;
			end;
			LDoDraw(TRUE, tempLHand);

			SelectWindow(GFileSelection);
		end
		else
			SelectWindow(GFileSelection);
	end;

	procedure Open_New;
		var
			tempRect, tr2, r: Rect;
			myC, myPt: Point;
			DType, i, kind, hm, wid, wm: Integer;
			DItem: Handle;
			tempString: Str255;
			h: Handle;
			CItem: ControlHandle;
			test: longint;
			myPop: popupHand;
	begin
		if (NewDilg = nil) then
		begin
			NewDilg := GetNewDialog(1600, nil, pointer(-1));
			SetPort(NewDilg);
			SetGeneva(NewDilg);
			SetCheckBox(NewDilg, 8, NewHand^^.NoVFeedback);
			SetCheckBox(NewDilg, 9, NewHand^^.RealName);
			SetCheckBox(NewDilg, 10, NewHand^^.City);
			SetCheckBox(NewDilg, 11, NewHand^^.Gender);
			SetCheckBox(NewDilg, 12, NewHand^^.BirthDay);
			SetCheckBox(NewDilg, 13, NewHand^^.Country);
			SetCheckBox(NewDilg, 14, NewHand^^.DataPN);
			SetCheckBox(NewDilg, 15, NewHand^^.Company);
			SetCheckBox(NewDilg, 16, NewHand^^.Street);
			SetCheckBox(NewDilg, 23, NewHand^^.Computer);
			SetCheckBox(NewDilg, 28, NewHand^^.NoAutoCapital);
			SetCheckBox(NewDilg, 29, NewHand^^.VoicePN);
			for i := 1 to 3 do
			begin
				SetCheckBox(NewDilg, 16 + i, NewHand^^.SysOp[i]);
				SetTextBox(NewDilg, 19 + i, NewHand^^.SysOpText[i]);
			end;
			SetTextBox(NewDilg, 3, DoNumber(InitSystHand^^.DLCredits));
			SetTextBox(NewDilg, 24, DoNumber(NewHand^^.QScanBack));
			ShowWindow(NewDilg);
			SelectWindow(NewDilg);
		end
		else
			SelectWindow(NewDilg);
	end;

	procedure SetFields;
		var
			tempString: str255;
	begin
		SetTextBox(GFileSelection, 3, intGFileRec^^.sections[CurEditSec].SecName);
		SetTextBox(GFileSelection, 6, stringOf(intGFileRec^^.sections[CurEditSec].minSL : 0));
		SetTextBox(GFileSelection, 7, stringOf(intGFileRec^^.sections[CurEditSec].minAge : 0));
		SetTextBox(GFileSelection, 17, '');
		if intGFileRec^^.sections[CurEditSec].Restrict <> char(0) then
			SetTextBox(GFileSelection, 17, intGFileRec^^.sections[CurEditSec].Restrict);
	end;

	procedure Do_GFiles (theEvent: EventRecord; ItemHit: Integer);
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell, ccc: cell;
			tempint: integer;
			tempString, ts: str255;
			tempRect, tr2, r: Rect;
			myC: Point;
			DType, i, kind, hm: Integer;
			DItem: Handle;
			ttUser: userRec;
			adder: Integer;
			h: handle;
			result: longint;
	begin
		if (GFileSelection <> nil) then
		begin
			SetPort(GFileSelection);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(GFileSelection, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			adder := 10;
			if optiondown then
				adder := 1;
			case itemHit of
				14: 
				begin
					csize := cell($00000000);
					if LGetSelect(true, cSize, tempLHand) then
					begin
						if (CurEditSec <> -1) then
							GetFields;
						LSetSelect(false, cSize, tempLHand);
					end;
					if intGFileRec^^.numSecs <= 98 then
					begin
						i := LAddRow(1, 800, tempLHand);
						cSize.v := i;
						cSize.h := 0;
						ts := 'New';
						intGFileRec^^.sections[cSize.v + 1].secName := ts;
						intGFileRec^^.sections[cSize.v + 1].minSL := 0;
						intGFileRec^^.sections[cSize.v + 1].minAge := 0;
						intGFileRec^^.sections[csize.v + 1].restrict := char(0);
						for i := 1 to 13 do
							intGFileRec^^.sections[cSize.v + 1].reserved[i] := char(0);
						LSetCell(ptr(ord4(@ts) + 1), length(ts), cSize, tempLHand);
						LSetSelect(true, cSize, tempLHand);
						CurEditSec := Csize.v + 1;
						SetFields;
						intGFileRec^^.numSecs := intGFileRec^^.numSecs + 1;
					end
					else
						SysBeep(1);
				end;
				15: 
				begin
					cSize := cell($00000000);
					if LGetSelect(true, cSize, tempLHand) then
					begin
						if intGFileRec^^.numSecs > (cSize.v + 1) then
						begin
							for i := cSize.v + 2 to IntGFileRec^^.numSecs do
								IntGFileRec^^.sections[i - 1] := IntGFileRec^^.sections[i];
						end;
						IntGFileRec^^.numSecs := IntGFileRec^^.numSecs - 1;
						LDelRow(1, cSize.v, tempLHand);
						SetTextBox(GFileSelection, 3, '');
						SetTextBox(GFileSelection, 6, '0');
						SetTextBox(GFileSelection, 7, '0');
						SetTextBox(GFileSelection, 17, '');
						CurEditSec := -1;
					end;
				end;
				1: 
				begin
					if LClick(myPt, theEvent.modifiers, tempLHand) then
						;
					cSize := cell($00000000);
					if LGetSelect(true, cSize, tempLHand) then
					begin
						if (CurEditSec <> -1) then
							GetFields;
						CurEditSec := cSize.v + 1;
						SetFields;
					end;
				end;
				8, 9: 
				begin
					if (itemHit = 8) then
						adder := adder * (-1);
					intGFileRec^^.sections[CurEditSec].minSL := UpDown(GFileSelection, 6, intGFileRec^^.sections[CurEditSec].minSL, Adder, 255, 0);
				end;
				11, 12: 
				begin
					if (itemHit = 11) then
						adder := adder * (-1);
					intGFileRec^^.sections[CurEditSec].minAge := UpDown(GFileSelection, 7, intGFileRec^^.sections[CurEditSec].minAge, Adder, 99, 0);
				end;
			end;
		end;
	end;

	procedure Do_New (theEvent: EventRecord; ItemHit: Integer);
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2, r: Rect;
			myC: Point;
			DType, i, kind, hm: Integer;
			DItem: Handle;
			ttUser: userRec;
			adder: Integer;
			h: handle;
			result: longint;
			tempMenu: MenuHandle;
	begin
		if (NewDilg <> nil) then
		begin
			SetPort(NewDilg);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(NewDilg, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			adder := 100;
			if optiondown then
				adder := 10;
			if (itemHit = 25) or (itemHit = 26) then
				if optiondown then
					adder := 1
				else
					adder := 10;
			case itemHit of
				7: 
				begin
				end;
				8: 
				begin
					if newHand^^.NoVFeedback then
						newHand^^.NoVFeedback := false
					else
						newHand^^.NoVFeedback := true;
					SetCheckBox(NewDilg, 8, newHand^^.NoVFeedback);
				end;
				9: 
				begin
					if not newHand^^.handle and newHand^^.realName then
					begin
						ProblemRep('You must have Use Aliases or Ask For Real Names selected.');
					end
					else
					begin
						if newHand^^.RealName then
							newHand^^.RealName := false
						else
							newHand^^.RealName := true;
						SetCheckBox(NewDilg, 9, newHand^^.RealName);
					end;
				end;
				10: 
				begin
					if newHand^^.City then
						newHand^^.City := false
					else
						newHand^^.City := true;
					SetCheckBox(NewDilg, 10, newHand^^.City);
				end;
				11: 
				begin
					if newHand^^.Gender then
						newHand^^.Gender := false
					else
						newHand^^.Gender := true;
					SetCheckBox(NewDilg, 11, newHand^^.Gender);
				end;
				12: 
				begin
					if newHand^^.BirthDay then
						newHand^^.BirthDay := false
					else
						newHand^^.BirthDay := true;
					SetCheckBox(NewDilg, 12, newHand^^.BirthDay);
				end;
				13: 
				begin
					if newHand^^.Country then
						newHand^^.Country := false
					else
						newHand^^.Country := true;
					SetCheckBox(NewDilg, 13, newHand^^.Country);
				end;
				14: 
				begin
					if newHand^^.DataPN then
						newHand^^.DataPN := false
					else
						newHand^^.DataPN := true;
					SetCheckBox(NewDilg, 14, newHand^^.DataPN);
				end;
				15: 
				begin
					if newHand^^.Company then
						newHand^^.Company := false
					else
						newHand^^.Company := true;
					SetCheckBox(NewDilg, 15, newHand^^.Company);
				end;
				16: 
				begin
					if newHand^^.Street then
						newHand^^.Street := false
					else
						newHand^^.Street := true;
					SetCheckBox(NewDilg, 16, newHand^^.Street);
				end;
				23: 
				begin
					if newHand^^.Computer then
						newHand^^.Computer := false
					else
						newHand^^.Computer := true;
					SetCheckBox(NewDilg, 23, newHand^^.Computer);
				end;
				4, 5: 
				begin
					if (itemHit = 4) then
						adder := adder * (-1);
					InitSystHand^^.DLCredits := UpDown(NewDilg, 3, InitSystHand^^.DLCredits, Adder, 9999, 0);
				end;
				17, 18, 19: 
				begin
					if newHand^^.SysOp[ItemHit - 16] then
						newHand^^.SysOp[ItemHit - 16] := false
					else
						newHand^^.SysOp[ItemHit - 16] := true;
					SetCheckBox(NewDilg, ItemHit, newHand^^.SysOp[ItemHit - 16]);
				end;
				25, 26: 
				begin
					if (itemHit = 25) then
						adder := adder * (-1);
					NewHand^^.QScanBack := UpDown(NewDilg, 24, NewHand^^.QScanBack, Adder, 999, 0)
				end;
				28: 
				begin
					if NewHand^^.NoAutoCapital then
						NewHand^^.NoAutoCapital := false
					else
						NewHand^^.NoAutoCapital := true;
					SetCheckBox(NewDilg, 28, NewHand^^.NoAutoCapital);
				end;
				29: 
				begin
					if newHand^^.VoicePN then
						newHand^^.VoicePN := false
					else
						newHand^^.VoicePN := true;
					SetCheckBox(NewDilg, 29, newHand^^.VoicePN);
				end;
			end;
		end;
	end;

	procedure EditTransferSec (new: boolean; which: integer);
	external;

	procedure DoSystemPrefs;
		var
			myPt: Point;
			doubleclick, hk, MailForum: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind, which: Integer;
			DItem: Handle;
			ttUser: userRec;
			adder, adder3: integer;
			adder2: real;
			newForum: ReadDirHandle;
	begin
		if (SystPrefs <> nil) then
		begin
			SetPort(SystPrefs);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(SystPrefs, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			adder := 10;
			adder2 := 1.0;
			adder3 := 3600;
			if optiondown then
			begin
				adder := 1;
				adder2 := 0.1;
				adder3 := 60;
			end;
			case itemHit of
				84: 
				begin
					globalStr := RetInStr(573);	{Select Path For Transfer Data}
					TempString := doGetDirectory;
					if TempString <> '' then
					begin
						InitSystHand^^.DataPath := TempString;
						SetTextBox(SystPrefs, 85, InitSystHand^^.DataPath);
					end;
				end;
				86: 
				begin
					globalStr := RetInStr(574);	{Select Path For Message Data}
					TempString := doGetDirectory;
					if TempString <> '' then
					begin
						InitSystHand^^.MsgsPath := TempString;
						SetTextBox(SystPrefs, 87, InitSystHand^^.MsgsPath);
					end;
				end;
				93: 
				begin
					globalStr := 'Select GFiles Folder';
					TempString := doGetDirectory;
					if TempString <> '' then
					begin
						InitSystHand^^.GFilePath := TempString;
						SetTextBox(SystPrefs, 94, InitSystHand^^.GFilePath);
					end;
				end;
				89, 90: 
				begin
					SetCheckBox(SystPrefs, 89, false);
					SetCheckBox(SystPrefs, 90, false);
					SetCheckBox(SystPrefs, itemHit, true);
				end;
				49, 50: 
				begin
					SetCheckBox(SystPrefs, 49, false);
					SetCheckBox(SystPrefs, 50, false);
					SetCheckBox(SystPrefs, itemHit, true);
				end;
				18, 19: 
				begin
					SetCheckBox(SystPrefs, 18, false);
					SetCheckBox(SystPrefs, 19, false);
					SetCheckBox(SystPrefs, itemHit, true);
				end;
				75, 76: 
				begin
					SetCheckBox(SystPrefs, 75, false);
					SetCheckBox(SystPrefs, 76, false);
					SetCheckBox(SystPrefs, itemHit, true);
				end;
				4, 5, 6, 7, 8, 9, 10, 15, 45, 46, 65, 32, 29, 17: 
				begin
					hk := GetCheckBox(SystPrefs, itemHit);
					if hk then
						SetCheckBox(SystPrefs, itemHit, false)
					else
						SetCheckBox(SystPrefs, itemHit, true);
				end;
				30: 
				begin
					hk := GetCheckBox(SystPrefs, itemHit);
					if hk then
					begin
						SetCheckBox(SystPrefs, itemHit, false);
						HideDItem(SystPrefs, 32);
						HideDItem(SystPrefs, 33);
						HideDItem(SystPrefs, 24);
						HideDItem(SystPrefs, 95);
						HideDItem(SystPrefs, 96);
						HideDItem(SystPrefs, 97);
						HideDItem(SystPrefs, 25);
					end
					else
					begin
						SetCheckBox(SystPrefs, itemHit, true);
						ShowDItem(SystPrefs, 32);
						ShowDItem(SystPrefs, 33);
						ShowDItem(SystPrefs, 24);
						ShowDItem(SystPrefs, 95);
						ShowDItem(SystPrefs, 96);
						ShowDItem(SystPrefs, 97);
						ShowDItem(SystPrefs, 25);
						MailForum := false;
						for i := 1 to forumIdx^^.numDirs[0] do
							if (forums^^[0].dr[i].DirName = 'Mail Attachments') then
								MailForum := true;
						if (not MailForum) and (ForumIdx^^.numDirs[0] + 1 < 65) then
						begin
							ForumIdx^^.numDirs[0] := ForumIdx^^.numDirs[0] + 1;
							which := ForumIdx^^.numDirs[0];
							forums^^[0].dr[which].DirName := 'Mail Attachments';
							tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[0], ':', forums^^[0].dr[which].dirName);
							result := Create(tempString, 0, 'HRMS', 'DATA');
							CreateResFile(tempString);
							CloseResFile(OpenResFile(tempstring));
							result := Create(concat(InitSystHand^^.DataPath, forumIdx^^.name[0], ':', 'Mail Attachments AHDR'), 0, 'HRMS', 'DATA');
							result := Create(concat(InitSystHand^^.DataPath, forumIdx^^.name[0], ':', 'Mail Attachments HDR'), 0, 'HRMS', 'DATA');
							forums^^[0].dr[which].Path := forums^^[0].dr[1].Path;
							forums^^[0].dr[which].MinDSL := 255;
							forums^^[0].dr[which].DSLtoUL := 10;
							forums^^[0].dr[which].DSLtoDL := 255;
							forums^^[0].dr[which].MaxFiles := 1000;
							forums^^[0].dr[which].Restriction := char(0);
							forums^^[0].dr[which].NonMacFiles := 0;
							forums^^[0].dr[which].mode := 0;
							forums^^[0].dr[which].MinAge := 0;
							forums^^[0].dr[which].FileNameLength := 31;
							forums^^[0].dr[which].freeDir := false;
							forums^^[0].dr[which].AllowUploads := false;
							forums^^[0].dr[which].Handles := false;
							forums^^[0].dr[which].ShowUploader := true;
							forums^^[0].dr[which].Color := 0;
							forums^^[0].dr[which].TapeVolume := false;
							forums^^[0].dr[which].SlowVolume := false;
							for i := 1 to 3 do
								forums^^[0].dr[which].Operators[i] := 0;
							forums^^[0].dr[which].DLCost := 1.0;
							forums^^[0].dr[which].ULCost := 0.0;
							forums^^[0].dr[which].DLCreditor := 0.0;
							forums^^[0].dr[which].HowLong := 0;
							forums^^[0].dr[which].UploadOnly := false;
							i := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
							newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[0]));
							RmveResource(handle(newForum));
							DisposeHandle(handle(newForum));
							newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
							HLock(handle(newForum));
							newForum^^ := forums^^[0];
							AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[0]);
							WriteResource(handle(newForum));
							DetachResource(handle(newForum));
							HUnlock(handle(newForum));
							DisposHandle(handle(newForum));
							CloseResFile(i);
							DoForumRec(True);
						end
						else if (not MailForum) and (ForumIdx^^.numDirs[0] + 1 > 65) then
						begin
							ProblemRep('Aborted, you will exceed the 64 directory limit.');
							SetCheckBox(SystPrefs, itemHit, false);
							HideDItem(SystPrefs, 32);
							HideDItem(SystPrefs, 33);
							HideDItem(SystPrefs, 24);
							HideDItem(SystPrefs, 95);
							HideDItem(SystPrefs, 96);
							HideDItem(SystPrefs, 97);
							HideDItem(SystPrefs, 25);
						end;
					end;
				end;
				95, 96: 
				begin
					if (itemHit = 95) then
						adder2 := adder2 * (-1);
					InitSystHand^^.MailDLCost := UpDownReal(SystPrefs, 33, InitSystHand^^.MailDLCost, Adder2, 99.90, 0.00);
				end;
				25: 
				begin
					for i := 1 to forumIdx^^.numDirs[0] do
						if (forums^^[0].dr[i].DirName = 'Mail Attachments') then
							tempint := i;
					EditTransferSec(false, tempint);
				end;
				11: 
				begin
					if newHand^^.handle and not newHand^^.realName then
					begin
						ProblemRep('You must have Use Aliases or Ask For Real Names selected.');
					end
					else
					begin
						if newHand^^.Handle then
							newHand^^.Handle := false
						else
							newHand^^.Handle := true;
						SetCheckBox(SystPrefs, 11, newHand^^.Handle);
					end;
				end;
				66, 67: 
				begin
					if (itemHit = 66) then
						adder := adder * (-1);
					InitSystHand^^.protocoltime := UpDown(SystPrefs, 44, InitSystHand^^.protocoltime, Adder, 99, 0);
				end;
				72, 73: 
				begin
					if (itemHit = 72) then
						adder := adder * (-1);
					InitSystHand^^.screensaver[1] := UpDown(SystPrefs, 53, InitSystHand^^.screensaver[1], Adder, 99, 1);
				end;
				22, 23: 
				begin
					if (itemHit = 23) then
						adder := adder * (-1);
					InitSystHand^^.MailDeleteDays := UpDown(SystPrefs, 63, InitSystHand^^.MailDeleteDays, Adder, 999, 10);
				end;
				69, 70: 
				begin
					if (itemHit = 69) then
						adder := adder * (-1);
					InitSystHand^^.logdays := UpDown(SystPrefs, 48, InitSystHand^^.logdays, Adder, 99, 1);
				end;
				55: 
				begin
					if ((InitSystHand^^.OpStartHour + adder3) < 86400) then
					begin
						InitSystHand^^.OpStartHour := InitSystHand^^.OpStartHour + adder3
					end
					else
						InitSystHand^^.OpStartHour := (InitSystHand^^.OpStartHour + adder3) - 86400;
					SetTextBox(SystPrefs, 37, DrawTime(InitSystHand^^.OpStartHour));
				end;
				54: 
				begin
					if ((InitSystHand^^.OpStartHour - adder3) > 0) then
					begin
						InitSystHand^^.OpStartHour := InitSystHand^^.OpStartHour - adder3
					end
					else
						InitSystHand^^.OpStartHour := (InitSystHand^^.OpStartHour - adder3) + 86400;
					SetTextBox(SystPrefs, 37, DrawTime(InitSystHand^^.OpStartHour));
				end;
				58: 
				begin
					if ((InitSystHand^^.OpEndHour + adder3) < 86400) then
					begin
						InitSystHand^^.OpEndHour := InitSystHand^^.OpEndHour + adder3
					end
					else
						InitSystHand^^.OpEndHour := (InitSystHand^^.OpEndHour + adder3) - 86400;
					SetTextBox(SystPrefs, 38, DrawTime(InitSystHand^^.OpEndHour));
				end;
				57: 
				begin
					if ((InitSystHand^^.OpEndHour - adder3) > 0) then
					begin
						InitSystHand^^.OpEndHour := InitSystHand^^.OpEndHour - adder3
					end
					else
						InitSystHand^^.OpEndHour := (InitSystHand^^.OpEndHour - adder3) + 86400;
					SetTextBox(SystPrefs, 38, DrawTime(InitSystHand^^.OpEndHour));
				end;
				otherwise
			end;
		end;
	end;

	procedure UpdateSystemPrefs;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (SystPrefs <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(SystPrefs);

			FrameIt(SystPrefs, 79);
			FrameIt(SystPrefs, 81);
			FrameIt(SystPrefs, 83);
			FrameIt(SystPrefs, 80);

			ShowWindow(SystPrefs);
			DrawDialog(SystPrefs);
			SelectWindow(SystPrefs);

			setPort(savedPort);
		end;
	end;

	procedure OpenSystemPrefs;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i: Integer;
			DItem: Handle;
			tempString: str255;
	begin
		if (SystPrefs = nil) then
		begin
			SystPrefs := GetNewDialog(277, nil, Pointer(-1));
			SetPort(SystPrefs);
			ShowWindow(SystPrefs);
			SetGeneva(SystPrefs);
			SelectWindow(SystPrefs);

			SetTextBox(SystPrefs, 44, stringof(InitSystHand^^.protocoltime : 0));
			SetTextBox(SystPrefs, 48, stringof(InitSystHand^^.logdays : 0));
			SetTextBox(SystPrefs, 53, stringof(InitSystHand^^.screenSaver[1] : 0));
			SetTextBox(SystPrefs, 12, InitSystHand^^.overridePass);
			SetTextBox(SystPrefs, 13, InitSystHand^^.newUserPass);
			SetTextBox(SystPrefs, 14, stringof(InitSystHand^^.numCalls : 0));
			SetTextBox(SystPrefs, 63, stringOf(InitSystHand^^.MailDeleteDays : 0));

			SetCheckBox(SystPrefs, 45, InitSystHand^^.SSLock);
			SetCheckBox(SystPrefs, 11, NewHand^^.Handle);
			SetCheckBox(SystPrefs, 15, InitSystHand^^.closed);
			SetCheckBox(SystPrefs, 4, InitSystHand^^.TwoWayChat);
			SetCheckBox(SystPrefs, 5, InitSystHand^^.TwoColorChat);
			SetCheckBox(SystPrefs, 6, InitSystHand^^.useXWind);
			SetCheckBox(SystPrefs, 65, InitSystHand^^.usePauses);
			SetCheckBox(SystPrefs, 29, InitSystHand^^.NoANSIDetect);
			SetCheckBox(SystPrefs, 17, InitSystHand^^.NoXFerPathChecking);
{    SetCheckBox(SystPrefs, 8, InitSystHand^^.allowHandles);}
			SetCheckBox(SystPrefs, 9, InitSystHand^^.freePhone);
			SetCheckBox(SystPrefs, 10, InitSystHand^^.closedTransfers);
{    SetCheckBox(SystPrefs, 11, InitSystHand^^.mustRead);}

			SetTextBox(SystPrefs, 33, StringOf(InitSystHand^^.MailDLCost : 0 : 2));
			SetCheckBox(SystPrefs, 32, InitSystHand^^.FreeMailDL);
			SetCheckBox(SystPrefs, 30, InitSystHand^^.MailAttachments);
			if (not InitSystHand^^.MailAttachments) then
			begin
				HideDItem(SystPrefs, 32);
				HideDItem(SystPrefs, 33);
				HideDItem(SystPrefs, 24);
				HideDItem(SystPrefs, 95);
				HideDItem(SystPrefs, 96);
				HideDItem(SystPrefs, 97);
				HideDItem(SystPrefs, 25);
			end;
			SetTextBox(SystPrefs, 85, InitSystHand^^.DataPath);
			SetTextBox(SystPrefs, 87, InitSystHand^^.MsgsPath);
			SetTextBox(SystPrefs, 94, InitSystHand^^.GFilePath);
			if InitSystHand^^.screenSaver[0] = 1 then
				SetCheckBox(SystPrefs, 7, true)
			else
				SetCheckBox(SystPrefs, 7, false);

			if InitSystHand^^.ninepoint then
				SetCheckBox(SystPrefs, 49, true)
			else
				SetCheckBox(SystPrefs, 50, true);

			if InitSystHand^^.blackOnWhite = 1 then
				SetCheckBox(SystPrefs, 18, true)
			else
				SetCheckBox(SystPrefs, 19, true);

			if InitSystHand^^.totals then
				SetCheckBox(SystPrefs, 76, true)
			else
				SetCheckBox(SystPrefs, 75, true);

			if InitSystHand^^.UseBold then
				SetCheckBox(SystPrefs, 90, true)
			else
				SetCheckBox(SystPrefs, 89, true);

			GetDItem(SystPrefs, 46, dType, dItem, tempRect);


			SetTextBox(SystPrefs, 37, DrawTime(InitSystHand^^.OpStartHour));
			SetTextBox(SystPrefs, 38, DrawTime(InitSystHand^^.OpEndHour));

			FrameIt(SystPrefs, 79);
			FrameIt(SystPrefs, 81);
			FrameIt(SystPrefs, 83);
			FrameIt(SystPrefs, 80);

			SelectWindow(SystPrefs);
		end
		else
			SelectWindow(SystPrefs);
	end;

	procedure CloseSystemPrefs;
		var
			ts: str255;
			DType, i: Integer;
			DItem: Handle;
			tempRect: Rect;
			templong: longint;
	begin
		if (SystPrefs <> nil) then
		begin
			InitSystHand^^.closed := GetCheckBox(SystPrefs, 15);
			InitSystHand^^.SSLock := GetCheckBox(SystPrefs, 45);
			InitSystHand^^.useXWind := GetCheckBox(SystPrefs, 6);
{    InitSystHand^^.AllowHandles := GetCheckBox(SystPrefs, 8);}
			InitSystHand^^.freePhone := GetCheckBox(SystPrefs, 9);
			InitSystHand^^.closedTransfers := GetCheckBox(SystPrefs, 10);
{    InitSystHand^^.mustRead := GetCheckBox(SystPrefs, 11);}
			InitSystHand^^.twoWayChat := GetCheckBox(SystPrefs, 4);
			InitSystHand^^.twoColorChat := GetCheckBox(SystPrefs, 5);
			InitSystHand^^.MailAttachments := GetCheckBox(SystPrefs, 30);
			if (InitSystHand^^.MailAttachments) then
				InitSystHand^^.FreeMailDL := GetCheckBox(SystPrefs, 32);
			InitSystHand^^.UsePauses := GetCheckBox(SystPrefs, 65);
			InitSystHand^^.NoANSIDetect := GetCheckBox(SystPrefs, 29);
			InitSystHand^^.NoXFerPathChecking := GetCheckBox(SystPrefs, 17);
			if GetCheckBox(SystPrefs, 7) then
				InitSystHand^^.screenSaver[0] := 1
			else
				InitSystHand^^.screenSaver[0] := 0;
			if GetCheckBox(SystPrefs, 18) then
				InitSystHand^^.blackOnWhite := 1
			else
				InitSystHand^^.blackOnWhite := 0;
			if GetCheckBox(SystPrefs, 90) then
				InitSystHand^^.useBold := true
			else
				InitSystHand^^.useBold := false;
			GetDItem(SystPrefs, 14, dType, dItem, tempRect);
			GetIText(DItem, ts);
			StringToNum(ts, InitSystHand^^.NumCalls);
			GetDItem(SystPrefs, 63, dType, dItem, tempRect);
			GetIText(DItem, ts);
			StringToNum(ts, templong);
			InitSystHand^^.MailDeleteDays := templong;
			GetDItem(SystPrefs, 12, dType, dItem, tempRect);
			GetIText(DItem, ts);
			InitSystHand^^.OverRidePass := ts;
			GetDItem(SystPrefs, 13, dType, dItem, tempRect);
			GetIText(DItem, ts);
			InitSystHand^^.NewUserPass := ts;
			if (GetCheckBox(SystPrefs, 49)) then
				InitSystHand^^.ninePoint := true
			else
				InitSystHand^^.ninePoint := false;
			if (GetCheckBox(SystPrefs, 76)) then
				InitSystHand^^.totals := true
			else
				InitSystHand^^.totals := false;
			LoadNewUser(True);
			doSystRec(true);
			DisposDialog(SystPrefs);
			SystPrefs := nil;
			if InitSystHand^^.blackOnWhite = 1 then
			begin
				defaultstyle.fcol := 7;
				defaultstyle.bcol := 0;
			end
			else
			begin
				defaultstyle.fcol := 0;
				defaultstyle.bcol := 7;
			end;
			if (((hermesFontSize = 9) and not InitSystHand^^.ninePoint) or ((hermesFontSize = 12) and InitSystHand^^.ninePoint)) then
			begin
				SetFontVars;
				for i := 1 to MAX_NODES do
				begin
					CloseANSIWindow(i);
					SetRect(InitSystHand^^.wNodesStd[i], 0, 0, 0, 0);
					SetRect(InitSystHand^^.wNodesUser[i], 0, 0, 0, 0);
					InitSystHand^^.wIsOpen[i] := true;
				end;
				for i := 1 to InitSystHand^^.numNodes do
					OpenANSIWindow(i);
			end;
		end;
	end;

	procedure putallfeedbackin;
		var
			i: integer;
			dType: integer;
			dItem: handle;
			tempRect: rect;
			ds: str255;
	begin
		for i := 1 to (numUserRecs) do
		begin
			if (not fullNames^^[i].del) then
				AddListString(fullNames^^[i].n, MUserList)
		end;
	end;

	procedure putfeedbackin;
		var
			i: integer;
			dType: integer;
			dItem: handle;
			tempRect: rect;
			ds: str255;
	begin
		for i := 1 to InitFBHand^^.numfeedbacks do
		begin
			AddListString(myUsers^^[InitFBHand^^.usernum[i] - 1].UName, feedbackList);
		end;
	end;

	procedure Open_FB_Edit;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (GetFBSelection = nil) then
		begin
			GetFBSelection := GetNewDialog(992, nil, pointer(-1));
			SetPort(GetFBSelection);
			SetGeneva(GetFBSelection);
			MakeFullNames(1);
			GetDItem(GetFBSelection, 7, DType, DItem, tempRect);
			TempRect.right := tempRect.right - 14;
			SetRect(tr2, 0, 0, 1, 0);
			SetPt(myC, tempRect.right - tempRect.left, 12);
			MUserList := LNew(tempRect, tr2, myC, 0, getFBSelection, false, false, false, true);
			MUserList^^.selFlags := lOnlyOne + lNoNilHilite;
			PutAllFeedBackIn;
			LDoDraw(true, MUserList);
			GetDItem(GetFBSelection, 8, DType, DItem, tempRect);
			TempRect.right := tempRect.right - 14;
			SetRect(tr2, 0, 0, 1, 0);
			SetPt(myC, tempRect.right - tempRect.left, 12);
			FeedBackList := LNew(tempRect, tr2, myC, 0, getFBSelection, false, false, false, true);
			FeedBackList^^.selFlags := lOnlyOne + lNoNilHilite;
			PutFeedBackIn;
			LDoDraw(true, FeedBackList);
			myC.v := 0;
			LSetSelect(TRUE, myC, FeedBackList);
			GetDItem(GetFBSelection, 1, kind, Ditem, tempRect);
			HiLiteControl(controlHandle(Ditem), 255);
			GetDItem(GetFBSelection, 2, kind, Ditem, tempRect);
			HiLiteControl(controlHandle(Ditem), 255);
			ShowWindow(GetFBSelection);
			SelectWindow(GetFBSelection);
			curr := 0;
		end
		else
			SelectWindow(GetFBSelection);
	end;

	procedure Close_FB_Edit;
		var
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (GetFBSelection <> nil) then
		begin
			LDispose(MUserList);
			LDispose(feedbacklist);
			DisposDialog(GetFBSelection);
			GetFBSelection := nil;
			DoFBRec(false);
		end;
		if FullNames <> nil then
		begin
			DisposHandle(handle(fullnames));
			fullNames := nil;
		end;
	end;

	procedure Do_FB_Edit;
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			ttUser: userRec;
	begin
		if (GetFBSelection <> nil) then
		begin
			SetPort(GetFBSelection);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(GetFBSelection, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			case itemHit of
				1: 
				begin
					hk := false;
					i := 0;
					repeat
						i := i + 1;
						if (InitFBHand^^.usernum[i] = fbuser) then
							hk := true;
					until (i >= InitFBHand^^.numFeedBacks) or (hk);
					if (not hk) and (InitFBHand^^.numFeedBacks <= 20) and (fbuser > 0) then
					begin
						InitFBHand^^.numFeedBacks := InitFBHand^^.numFeedBacks + 1;
						InitFBHand^^.userNum[InitFBHand^^.numFeedBacks] := fbuser;
						AddListString(myUsers^^[fbuser - 1].UName, FeedBackList);
						GetDItem(GetFBSelection, 10, kind, Ditem, tempRect);
						GetIText(Ditem, tempString);
						InitFBHand^^.Speciality[InitFBHand^^.numFeedBacks] := TempString;
						TempString := '';
						SetIText(DItem, tempString);
					end
					else
						SysBeep(1);
				end;
				2: 
				begin
					tempcell.v := 0;
					tempcell.h := 0;
					if LGetSelect(true, tempCell, FeedBackList) then
						LDelRow(1, tempCell.v, FeedBackList);
					if tempCell.v + 1 > 1 then
					begin
						for i := (TempCell.v + 1) to InitFBHand^^.numFeedBacks do
						begin
							InitFBHand^^.userNum[i] := InitFBHand^^.userNum[i + 1];
							InitFBHand^^.speciality[i] := InitFBHand^^.speciality[i + 1];
							curr := i;
						end;
					end
					else
						InitFBHand^^.userNum[1] := 0;
					InitFBHand^^.numFeedBacks := InitFBHand^^.numFeedBacks - 1;
					curr := 0;
				end;
				3: 
				begin
					if curr <> 0 then
					begin
						GetDItem(GetFBSelection, 10, kind, Ditem, tempRect);
						GetIText(Ditem, tempString);
						InitFBHand^^.Speciality[curr] := TempString;
						curr := 0;
					end;
					DoFBRec(true);
					Close_FB_Edit;
				end;
				4: 
					Close_FB_Edit;
				7: 
				begin
					if curr <> 0 then
					begin
						GetDItem(GetFBSelection, 10, kind, Ditem, tempRect);
						GetIText(Ditem, tempString);
						InitFBHand^^.Speciality[curr] := TempString;
						TempString := '';
						SetIText(DItem, tempString);
					end;
					DoubleClick := LClick(myPt, theEvent.modifiers, MUserList);
					tempCell.h := 0;
					tempCell.v := 0;
					GetDItem(GetFBSelection, 1, kind, Ditem, tempRect);
					HiLiteControl(controlHandle(Ditem), 255);
					GetDItem(GetFBSelection, 2, kind, Ditem, tempRect);
					HiLiteControl(controlHandle(Ditem), 255);
					if LGetSelect(true, tempCell, MUserList) then
					begin
						tempint := 50;
						LGetCell(@tempString[1], tempint, tempCell, MUserList);
						tempString[0] := char(tempint);
						GetDItem(GetFBSelection, 1, kind, Ditem, tempRect);
						if FindUser(tempString, ttuser) then
						begin
							HiLiteControl(controlHandle(Ditem), 0);
							fbuser := ttuser.usernum;
						end;
					end;
					curr := 0;
					if not MUserList^^.lActive then
						LActivate(True, MUserList);
					LActivate(false, FeedBackList);
				end;
				8: 
				begin
					if curr <> 0 then
					begin
						GetDItem(GetFBSelection, 10, kind, Ditem, tempRect);
						GetIText(Ditem, tempString);
						InitFBHand^^.Speciality[curr] := TempString;
						TempString := '';
						SetIText(DItem, tempString);
					end;
					DoubleClick := LClick(myPt, theEvent.modifiers, FeedBackList);
					tempCell.h := 0;
					tempCell.v := 0;
					GetDItem(GetFBSelection, 1, kind, Ditem, tempRect);
					HiLiteControl(controlHandle(Ditem), 255);
					GetDItem(GetFBSelection, 2, kind, Ditem, tempRect);
					HiLiteControl(controlHandle(Ditem), 255);
					if LGetSelect(true, tempCell, FeedBackList) then
					begin
						tempint := 50;
						LGetCell(@tempString[1], tempint, tempCell, FeedBackList);
						tempString[0] := char(tempint);
						GetDItem(GetFBSelection, 2, kind, Ditem, tempRect);
						if FindUser(tempString, ttuser) then
						begin
							HiLiteControl(controlHandle(Ditem), 0);
							fbuser := ttuser.usernum;
							curr := tempcell.v + 1;
							GetDItem(GetFBSelection, 10, kind, Ditem, tempRect);
							SetIText(Ditem, InitFBHand^^.Speciality[curr]);
						end;
					end
					else
						curr := 0;
					if not Feedbacklist^^.lActive then
						LActivate(True, FeedBackList);
					LActivate(false, MUserList);
				end;
				otherwise
			end;
		end;
	end;

	procedure Update_FB_Edit;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			i: integer;
	begin
		if (GetFBSelection <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(GetFBSelection);
			EraseRect(getFBSelection^.portrect);
			DrawDialog(GetFBSelection);

			tempRect := MUserList^^.rView;
			if (tempRect.Right <= (tempRect.Left + 10)) then
				tempRect.Right := tempRect.Left + 10;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			LUpdate(GetFBSelection^.visRgn, MUserList);

			tempRect := feedbackList^^.rView;
			if (tempRect.Right <= (tempRect.Left + 10)) then
				tempRect.Right := tempRect.Left + 10;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			LUpdate(GetFBSelection^.visRgn, feedbackList);

			setPort(savedPort);
		end;
	end;
end.