{ Segments: Quoter_1 }
unit Quoter;

{Quoter	v1.5							}
{Last Modified : 01/03/96	}

{--- v1.0 Changes----------------}
{--Created, First release.}
{--- v1.1 Changes----------------}
{--Typing single digit number to quote. Then}
{  a Q would quote weird line numbers.}
{--- v1.2 Changes----------------}
{--Changed 'R' for blank line to 'B'.}
{--- v1.3 Changes----------------}
{--Added Quote, TitleChange RedirectReply Prompts}
{--- v1.4 Changes----------------}
{--Added Quote Header Line}
{--- v1.5 Changes----------------}
{--Reset color to White on Black for the Quote Header Line}
{--Added Quote Header Options for Anon Subs}
{--Added Real Name in quote header for conferences that are networked}


interface

	uses
		AppleTalk, ADSP, Serial, Sound, Initial, LoadAndSave, NodePrefs2, Message_Editor, inpOut4;

	procedure OutputColorBar;
	function MakeColorSequence (Which: integer): str255;
	function MakeQuoteHeader (receiver, sender, title: str255; AnonConference: boolean): str255;
	procedure SetUpQuoteText (UserName: string; StoredAs: longint; Forum, Conf: integer);
	procedure DoQuoter;
	procedure OpenQuoterSetup;
	procedure UpdateQuoterSetup;
	procedure DoQuoterSetup (event: EventRecord; itemHit: integer);
	procedure CloseQuoterSetup;

implementation

{$S Quoter_1}
	function MakeColorSequence (Which: integer): str255;
		var
			ColorText: string[5];
	begin
		with curGlobs^ do
		begin
			ColorText := StringOf(thisUser.foregrounds[Which] : 0);
			ColorText := StringOf(ColorText, thisUser.backgrounds[Which] : 0);
			if thisUser.intense[Which] then
				ColorText := concat(ColorText, 'T')
			else
				ColorText := concat(ColorText, 'F');
			if thisUser.underlines[Which] then
				ColorText := concat(ColorText, 'T')
			else
				ColorText := concat(ColorText, 'F');
			if thisUser.blinking[Which] then
				ColorText := concat(ColorText, 'T')
			else
				ColorText := concat(ColorText, 'F');
		end;
		MakeColorSequence := ColorText;
	end;

	procedure OutputColorBar;
		var
			i, StartPoint: integer;
			VarStr, s: str255;
	begin
		with curGlobs^ do
		begin
			VarStr := RetInStr(145);
			StartPoint := length(VarStr);
			StartPoint := StartPoint + 33;
			StartPoint := 40 - (StartPoint div 2);
			s := StringOf(' ' : StartPoint - 1, VarStr, ' ');
			BufferIt(s, true, 1);
			for i := 0 to 14 do
				if i <= 9 then
				begin
					BufferIt(StringOf(i : 0), false, USERCOLORBASE + i);
					BufferIt(' ', false, USERCOLORBASE + 0);
				end
				else
				begin
					case i of
						10: 
							s := 'A';
						11: 
							s := 'B';
						12: 
							s := 'C';
						13: 
							s := 'D';
						14: 
							s := 'E';
						15: 
							s := 'F';
					end;
					BufferIt(s, false, USERCOLORBASE + i);
					if i < 15 then
						BufferIt(' ', false, USERCOLORBASE + 0);
				end;
			ReleaseBuffer;
			OutLine('F', false, USERCOLORBASE + 15);	{Attempt to Fix problem with last color}
			ANSIcode('0;37;40m');
		end;
	end;

	function MakeInitials (UserName: string): string;
		var
			ts: str255;
			LastSpace, i, x: integer;
	begin
		if pos(' ', UserName) = 0 then
			ts := copy(UserName, 1, 2)
		else
		begin
			ts := copy(UserName, 1, 1);
			i := pos(',', UserName);
			if i <> 0 then
				Delete(UserName, i, length(UserName));
			i := length(UserName);
			repeat
				if UserName[i] = ' ' then
				begin
					Delete(UserName, i, 1);
					i := i - 1;
				end
				else
					i := -99;
			until i = -99;
			for x := 1 to length(UserName) do
				if UserName[x] = ' ' then
					LastSpace := x;
			ts := concat(ts, copy(UserName, LastSpace + 1, 1));
		end;
		ts := concat(ts, '> ');
		MakeInitials := ts;
	end;

	function CheckColorCodes (Position: integer): integer;
		var
			Finish: integer;
	begin
		with curGlobs^ do
		begin
			Finish := Position;
			repeat
				Finish := Finish + 1;
			until curWriting^^[Finish] <> char(3);
			if (pos(curWriting^^[Finish], '0123456789') <> 0) and (pos(curWriting^^[Finish + 1], '0123456789') <> 0) then
				Finish := Finish + 4;

			CheckColorCodes := Finish;
		end;
	end;

	procedure StripCharCodes;
		var
			NumChars, Position, Finish, Wrap: longint;
			OldInitials: string[4];
	begin
		with curGlobs^ do
		begin
			NumChars := GetHandleSize(handle(curWriting)) - 1;
			Position := 0;
			repeat
				if curWriting^^[Position] = char(3) then
				begin
					Finish := CheckColorCodes(Position);
					BlockMove(@curWriting^^[Finish + 1], @curWriting^^[Position], NumChars - (Finish + 1));
					SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - ((Finish + 1) - Position));
					NumChars := NumChars - ((Finish + 1) - Position);
					Position := Position - 1;
				end
				else if (curWriting^^[Position] = char(8)) or (curWriting^^[Position] = char(26)) then
				begin
					BlockMove(@curWriting^^[Position + 1], @curWriting^^[Position], NumChars - (Position + 1));
					SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 1);
					NumChars := NumChars - 1;
					Position := Position - 1;
				end;
				if (curWriting^^[Position] = '>') and (curWriting^^[Position + 1] = ' ') then
				begin
					if (curWriting^^[Position - 5] = char(13)) and (curWriting^^[Position - 4] = ' ') and (curWriting^^[Position - 3] = ' ') then
					begin
						BlockMove(@curWriting^^[Position - 2], @curWriting^^[Position - 4], NumChars - (Position - 2));
						SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 2);
						NumChars := NumChars - 2;
						Position := Position - 2;
					end
					else if (curWriting^^[Position - 4] = char(13)) and (curWriting^^[Position - 3] = ' ') then
					begin
						BlockMove(@curWriting^^[Position - 2], @curWriting^^[Position - 3], NumChars - (Position - 2));
						SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 1);
						NumChars := NumChars - 1;
						Position := Position - 1;
					end;
				end;
				Position := Position + 1;
			until Position >= NumChars;
		end;
	end;

	procedure LoadIntoWriting;
		var
			Position, Wrap, Start, SavedP, NumChars: longint;
			Initials, OtherInitials: string[4];
			addCR: boolean;
	begin
		with curGlobs^ do
		begin
			NumChars := GetHandleSize(handle(curWriting)) - 1;
			Position := 0;
			Start := 0;
			addCR := false;
			if curWriting^^[0] <> char(13) then
			begin
				SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + 1);
				NumChars := GetHandleSize(handle(curWriting)) - 1;
				BlockMove(@curWriting^^[0], @curWriting^^[1], NumChars);
				curWriting^^[0] := char(13);
			end;
			repeat
				if (curWriting^^[Position] = char(13)) then
				begin
					if (curWriting^^[Position + 3] = '>') and ((curWriting^^[Position + 4] = ' ') or (curWriting^^[Position + 4] = char(13))) then
					begin
						if (Position - 1) - Start > 0 then
						begin
							TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
							BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], (Position - 1) - Start);
							TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char((Position - 1) - Start);
							if addCR then
							begin
								addCR := false;
								TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
								TheQuote.QuotingText^^[TheQuote.QuoteEnd] := char(13);
							end;
						end;
						Initials := concat(curWriting^^[Position + 1], curWriting^^[Position + 2], '> ');
						Start := Position + 1;
						repeat
							Position := Position + 1;
						until curWriting^^[Position] = char(13);

						if Position - Start <= 75 then
						begin
							TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
							BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], Position - Start);
							TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);
							if curWriting^^[Position + 1] = char(13) then
							begin
								TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
								TheQuote.QuotingText^^[TheQuote.QuoteEnd] := char(13);
								Position := Position + 2;
								while ((curWriting^^[Position] = char(13)) and (Position < NumChars)) and (curWriting^^[Position + 3] <> '>') do
								begin
									TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
									TheQuote.QuotingText^^[TheQuote.QuoteEnd] := char(13);
									Position := Position + 1;
								end;
								Start := Position;
								Position := Position - 1;
							end
							else
							begin
								Start := Position;
								Position := Position - 1;
							end;
						end
						else if (curWriting^^[Position + 3] = '>') and (curWriting^^[Position + 4] = ' ') then
						begin
							OtherInitials := concat(curWriting^^[Position + 1], curWriting^^[Position + 2], '> ');
							Wrap := Position;
							repeat
								Wrap := Wrap - 1;
							until ((curWriting^^[Wrap] = ' ') or (Position - Wrap > 34)) and (Wrap - Start <= 75);
							SavedP := Position;
							Position := Wrap;
							TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
							BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], Position - Start);
							TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);

							if OtherInitials <> Initials then
							begin
								TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
								TheQuote.QuotingText^^[TheQuote.QuoteEnd] := Initials;
								BlockMove(@curWriting^^[Position + 1], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][5], (SavedP - 1) - (Position + 1));
								TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(((SavedP - 1) - (Position + 1)) + 4);

								Position := SavedP - 1;
								Start := Position;
							end
							else
							begin
								BlockMove(@Initials[1], @curWriting^^[Position - 3], 4);
								BlockMove(@curWriting^^[SavedP + 4], @curWriting^^[SavedP], NumChars - (SavedP + 4));
								SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 4);
								NumChars := NumChars - 4;
								Start := Position - 3;
								repeat
									Position := Position + 1;
								until curWriting^^[Position] = char(13);
								if (Position - 1) - Start <= 75 then
								begin
									TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
									BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], (Position) - Start);
									TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char((Position) - Start);

									Start := Position;
									Position := Position - 1;
								end
								else
								begin
									if (curWriting^^[Position + 3] = '>') and (curWriting^^[Position + 4] = ' ') then
									begin
										BlockMove(@curWriting^^[Position + 4], @curWriting^^[Position], NumChars - (Position + 4));
										SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 4);
										NumChars := NumChars - 4;
									end;
									Wrap := Position;
									repeat
										Wrap := Wrap - 1;
									until ((curWriting^^[Wrap] = ' ') or (Position - Wrap > 34)) and (Wrap - Start <= 75);
									Position := Wrap;
									TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
									BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], Position - Start);
									TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);

									curWriting^^[Position - 4] := char(13);
									BlockMove(@Initials[1], @curWriting^^[Position - 3], 4);
									Position := Position - 5;
									Start := Position;
								end;
							end;
						end
						else
						begin
							Wrap := Position;
							repeat
								Wrap := Wrap - 1;
							until ((curWriting^^[Wrap] = ' ') or (Position - Wrap > 34)) and (Wrap - Start <= 75);
							SavedP := Position;
							Position := Wrap;
							TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
							BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], Position - Start);
							TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);

							TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
							TheQuote.QuotingText^^[TheQuote.QuoteEnd] := Initials;
							BlockMove(@curWriting^^[Position + 1], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][5], SavedP - (Position + 1));
							TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char((SavedP - (Position + 1)) + 4);
							if curWriting^^[SavedP + 1] = char(13) then
							begin
								Position := SavedP + 1;
								while (curWriting^^[Position] = char(13)) and (Position < NumChars) and (curWriting^^[Position + 3] <> '>') do
								begin
									TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
									TheQuote.QuotingText^^[TheQuote.QuoteEnd] := char(13);
									Position := Position + 1;
									Start := Position;
								end;
							end
							else
							begin
								Start := SavedP;
								Position := SavedP - 1;
							end;
						end;
					end
					else
					begin
						if (Position - Start > 1) then
						begin
							curWriting^^[Position] := ' ';
							Position := Position + 1;
						end
						else
						begin
							BlockMove(@curWriting^^[Position + 1], @curWriting^^[Position], NumChars - (Position + 1));
							SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 1);
							NumChars := NumChars - 1;
						end;
						if (curWriting^^[Position] = char(13)) and (curWriting^^[Position + 3] <> '>') then
						begin
							if (Position - Start > 0) then
							begin
								TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
								BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], (Position) - Start);
								TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);
							end;
							while (curWriting^^[Position] = char(13)) and (Position < NumChars) and (curWriting^^[Position + 3] <> '>') do
							begin
								TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
								TheQuote.QuotingText^^[TheQuote.QuoteEnd] := char(13);
								Position := Position + 1;
							end;
							Start := Position;
						end;
						if curWriting^^[Position + 3] = '>' then
						begin
							addCR := true;
							Position := Position - 1;
						end;
					end;
				end
				else if (Position - Start >= 75) then
				begin
					if (curWriting^^[Position] <> char(13)) and (curWriting^^[Position] <> ' ') then
					begin
						Wrap := Position;
						repeat
							Wrap := Wrap - 1;
						until (curWriting^^[Wrap] = ' ') or (curWriting^^[Wrap] = char(13)) or (Wrap < Position - 38);
						Position := Wrap;
					end;
					TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
					BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], (Position) - Start);
					TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);

					Start := Position + 1;
				end;
				Position := Position + 1;
			until Position >= NumChars;
			if (Position - Start > 0) then
			begin
				Wrap := Position;
				repeat
					Wrap := Wrap - 1;
				until (curWriting^^[Wrap] = char(26)) or (Wrap = Start);
				if curWriting^^[Wrap] = char(26) then
					Position := Wrap - 1;
				TheQuote.QuoteEnd := TheQuote.QuoteEnd + 1;
				BlockMove(@curWriting^^[Start], @TheQuote.QuotingText^^[TheQuote.QuoteEnd][1], (Position) - Start);
				TheQuote.QuotingText^^[TheQuote.QuoteEnd][0] := char(Position - Start);
			end;
		end;
	end;

{-------------------------------------------------------------------------------------------}
{ 										 Make sure to ALWAYS call this after SetUpQuoteText										}

	function MakeQuoteHeader (receiver, sender, title: str255; AnonConference: boolean): str255;
		var
			QuoteHeaderHandle: StringHandle;
			keyStr, date, time: str255;
			MungerResult: longint;
			LengthSearch, LengthReplace: integer;
	begin

		if (AnonConference) and (InitSystHand^^.QuoteHeaderOptions = UseAnonAndNormal) then
		begin
			LengthSearch := length(InitSystHand^^.QuoteHeaderAnon);
			result := PtrToHand(@InitSystHand^^.QuoteHeaderAnon[1], handle(QuoteHeaderHandle), LengthSearch);
		end
		else
		begin
			LengthSearch := length(InitSystHand^^.QuoteHeader);
			result := PtrToHand(@InitSystHand^^.QuoteHeader[1], handle(QuoteHeaderHandle), LengthSearch);
		end;

		{%sender - User Quoting}
		keyStr := '%sender';
		LengthSearch := length(keyStr);
		LengthReplace := length(sender);
		repeat
			MungerResult := Munger(handle(QuoteHeaderHandle), 0, @keyStr[1], LengthSearch, @sender[1], LengthReplace);
		until (MungerResult = -1);

		{%receiver - User Receiving}
		keyStr := '%receiver';
		LengthSearch := length(keyStr);
		LengthReplace := length(receiver);
		repeat
			MungerResult := Munger(handle(QuoteHeaderHandle), 0, @keyStr[1], LengthSearch, @receiver[1], LengthReplace);
		until (MungerResult = -1);

		{%date - Date Posted}
		keyStr := '%date';
		LengthSearch := length(keyStr);
		date := GetDate(-1);
		LengthReplace := length(date);
		repeat
			MungerResult := Munger(handle(QuoteHeaderHandle), 0, @keyStr[1], LengthSearch, @date[1], LengthReplace);
		until (MungerResult = -1);

		{%time - Time Posted}
		keyStr := '%time';
		LengthSearch := length(keyStr);
		time := WhatTime(-1);
		LengthReplace := length(time);
		repeat
			MungerResult := Munger(handle(QuoteHeaderHandle), 0, @keyStr[1], LengthSearch, @time[1], LengthReplace);
		until (MungerResult = -1);

		{%title - Title of Message}
		keyStr := '%title';
		LengthSearch := length(keyStr);
		if title[1] = char(0) then
			Delete(title, 1, 1);
		LengthReplace := length(title);
		repeat
			MungerResult := Munger(handle(QuoteHeaderHandle), 0, @keyStr[1], LengthSearch, @title[1], LengthReplace);
		until (MungerResult = -1);

		BlockMove(Ptr(QuoteHeaderHandle^), @keyStr[1], GetHandleSize(handle(QuoteHeaderHandle)));
		keyStr[0] := char(GetHandleSize(handle(QuoteHeaderHandle)));

		keyStr := concat(char(3), MakeColorSequence(0), keyStr);

		MakeQuoteHeader := keyStr;

		if (not InitSystHand^^.UseQuoteHeader) or ((InitSystHand^^.QuoteHeaderOptions = NoHeaderInAnon) and (AnonConference)) then
			curGlobs^.TheQuote.GaveHeader := true;

		if QuoteHeaderHandle <> nil then
		begin
			DisposHandle(handle(QuoteHeaderHandle));
			QuoteHeaderHandle := nil;
		end;

	end;

	procedure SetUpQuoteText (UserName: string; StoredAs: longint; Forum, Conf: integer);
		var
			ts: str255;
	begin
		with curGlobs^ do
		begin
			if TheQuote.QuotingText <> nil then
			begin
				DisposHandle(handle(TheQuote.QuotingText));
				TheQuote.QuotingText := nil;
			end;

			TheQuote.QuotingText := MessgHand(NewHandleClear(SizeOf(HermesMesg)));
			MoveHHi(handle(TheQuote.QuotingText));

			curWriting := ReadMessage(storedAs, Forum, Conf);
			ts := TakeMsgTop;

			TheQuote.QuoteMark := 0;
			TheQuote.QuoteEnd := 0;

			TheQuote.GaveHeader := false;

			StripCharCodes;
			LoadIntoWriting;

			if WasAnonymous then
				TheQuote.Initials := '??> '
			else
				TheQuote.Initials := MakeInitials(UserName);

			if curWriting <> nil then
			begin
				DisposHandle(handle(curWriting));
				curWriting := nil;
			end;
		end;
	end;

	procedure ListTextToQuote;
		var
			i, ListTo: integer;
			s: str255;
			s40: string[40];
			s25: string[25];
	begin
		with curGlobs^ do
		begin
			ClearScreen;
			OutLine('Title:', true, 4);
			if WasEmail then
			begin
				s40 := curEMailRec.Title;
				s25 := TempUser.userName;
				OutLine(concat(' ', s40, '  '), false, 5);
				OutLine('From:', false, 4);
				if WasAnonymous then
					Outline(' Anonymous  ', false, 5)
				else
					OutLine(concat(' ', s25, '  '), false, 5);
			end
			else
			begin
				s40 := curMesgRec.Title;
				s25 := curBase^^[inMessage - 1].fromUserName;
				OutLine(concat(' ', s40, '  '), false, 5);
				OutLine('From:', false, 4);
				if WasAnonymous then
					Outline(' Anonymous  ', false, 5)
				else
					OutLine(concat(' ', s25, '  '), false, 5);
			end;

			if TheQuote.QuoteMark + 20 > TheQuote.QuoteEnd then
				ListTo := TheQuote.QuoteEnd
			else
				ListTo := TheQuote.QuoteMark + 20;
			TheQuote.QuoteMark := TheQuote.QuoteMark + 1;
			for i := TheQuote.QuoteMark to ListTo do
			begin
				NumToString(i, s);
				if length(s) = 1 then
					s := concat(' ', s, '. ')
				else if length(s) = 2 then
					s := concat(s, '. ')
				else
					s := concat(s, '.');
				OutLine(s, true, 2);
				if TheQuote.QuotingText^^[i][length(TheQuote.QuotingText^^[i])] <> char(2) then
					OutLine(TheQuote.QuotingText^^[i], false, 0)
				else
				begin
					s := TheQuote.QuotingText^^[i];
					Delete(s, length(s), 1);
					OutLine(s, false, 1);
				end;
			end;
			TheQuote.QuoteMark := TheQuote.QuoteMark - 1;
		end;
	end;

	function DecipherNQuote: char;
		var
			i, x, BlankLine, Start, Finish: integer;
			l: longint;
			s, s1, s2, YellowC, WhiteC: str255;
			TheSpecialChar: char;
	begin
		with curGlobs^ do
		begin
			YellowC := concat(char(3), MakeColorSequence(2));
			WhiteC := concat(char(3), MakeColorSequence(0));
			if pos(curPrompt[length(curPrompt)], 'QNP') > 0 then
			begin
				TheSpecialChar := curPrompt[length(curPrompt)];
				Delete(curPrompt, length(curPrompt), 1);
			end
			else
				TheSpecialChar := char(0);
			BlankLine := 0;
			repeat
				l := pos(' ', curPrompt);
				if l <> 0 then
					Delete(curPrompt, l, 1);
			until pos(' ', curPrompt) = 0;
			if not TheQuote.GaveHeader then
			begin
				TheQuote.GaveHeader := True;
				for i := 1 to 5 do
					if length(TheQuote.Header) > 78 then
					begin
						if TheQuote.Header[78] = char(32) then
						begin
							curMessage^^[online] := copy(TheQuote.Header, 1, 78);
							if online + 1 > maxLines then
							begin
								DecipherNQuote := 'Z';
								online := online - 1;
								Exit(DecipherNQuote);
							end;
							online := online + 1;
							Delete(TheQuote.Header, 1, 78);
						end
						else
						begin
							for x := 78 downto 40 do
								if TheQuote.Header[x] = char(32) then
									leave;
							curMessage^^[online] := copy(TheQuote.Header, 1, x);
							if online + 1 > maxLines then
							begin
								DecipherNQuote := 'Z';
								online := online - 1;
								Exit(DecipherNQuote);
							end;
							online := online + 1;
							Delete(TheQuote.Header, 1, x);
						end;
					end
					else
					begin
						curMessage^^[online] := TheQuote.Header;
						if online + 1 > maxLines then
						begin
							DecipherNQuote := 'Z';
							online := online - 1;
							Exit(DecipherNQuote);
						end;
						online := online + 1;
						leave;
					end;
				if online + 1 > maxLines then
				begin
					DecipherNQuote := 'Z';
					online := online - 1;
					Exit(DecipherNQuote);
				end;
				online := online + 1; {Blank Line}
			end;
			if (pos(',', curPrompt) <> 0) or (pos('-', curPrompt) <> 0) then
			begin
				i := 0;
				s := char(0);
				Start := 0;
				Finish := 0;
				repeat
					i := i + 1;
					if (curPrompt[i] > '/') and (curPrompt[i] < ':') then
					begin
						s := concat(s, curPrompt[i]);
					end
					else if curPrompt[i] = 'B' then
						BlankLine := BlankLine + 1
					else if curPrompt[i] = '-' then
					begin
						if length(s) > 0 then
						begin
							StringToNum(s, l);
							Start := l
						end;
						s := char(0);
					end;
					if (curPrompt[i] = ',') or (i = length(curPrompt)) then
					begin
						if length(s) > 0 then
						begin
							StringToNum(s, l);
							if Start = 0 then
								Start := l
							else
								Finish := l;
						end;
						s := char(0);
					end;

					if (curPrompt[i] = ',') or (i = length(curPrompt)) then
					begin
						if ((Start <= TheQuote.QuoteEnd) and (Finish <= TheQuote.QuoteEnd)) and ((Start > 0) and (Finish > 0)) then
						begin
							if Finish > Start then
							begin
								for x := Start to Finish do
								begin
									if TheQuote.QuotingText^^[x][3] <> '>' then
										CurMessage^^[online] := concat(YellowC, TheQuote.Initials, WhiteC, TheQuote.QuotingText^^[x])
									else
									begin
										CurMessage^^[online] := concat(YellowC, copy(TheQuote.QuotingText^^[x], 1, 3), WhiteC, copy(TheQuote.QuotingText^^[x], 4, length(TheQuote.QuotingText^^[x]) - 3));
									end;
									if curMessage^^[online][length(curMessage^^[online])] = char(13) then
										Delete(curMessage^^[online], length(curMessage^^[online]), 1);
									if curMessage^^[online][length(curMessage^^[online])] = char(2) then
										Delete(curMessage^^[online], length(curMessage^^[online]), 1);
									if (TheQuote.QuotingText^^[x][length(TheQuote.QuotingText^^[x])] <> char(2)) then
										TheQuote.QuotingText^^[x] := concat(TheQuote.QuotingText^^[x], char(2));
									if online + 1 > maxLines then
									begin
										DecipherNQuote := 'Z';
										online := online - 1;
										Exit(DecipherNQuote);
									end;
									online := online + 1;
								end;
							end
							else if Start > Finish then
								for x := Start downto Finish do
								begin
									if TheQuote.QuotingText^^[x][3] <> '>' then
										CurMessage^^[online] := concat(YellowC, TheQuote.Initials, WhiteC, TheQuote.QuotingText^^[x])
									else
										CurMessage^^[online] := concat(YellowC, copy(TheQuote.QuotingText^^[x], 1, 3), WhiteC, copy(TheQuote.QuotingText^^[x], 4, length(TheQuote.QuotingText^^[x]) - 3));
									if curMessage^^[online][length(curMessage^^[online])] = char(13) then
										Delete(curMessage^^[online], length(curMessage^^[online]), 1);
									if curMessage^^[online][length(curMessage^^[online])] = char(2) then
										Delete(curMessage^^[online], length(curMessage^^[online]), 1);
									if (TheQuote.QuotingText^^[x][length(TheQuote.QuotingText^^[x])] <> char(2)) then
										TheQuote.QuotingText^^[x] := concat(TheQuote.QuotingText^^[x], char(2));
									if online + 1 > maxLines then
									begin
										DecipherNQuote := 'Z';
										online := online - 1;
										Exit(DecipherNQuote);
									end;
									online := online + 1;
								end
							else if Start = Finish then
							begin
								if TheQuote.QuotingText^^[Start][3] <> '>' then
									CurMessage^^[online] := concat(YellowC, TheQuote.Initials, WhiteC, TheQuote.QuotingText^^[Start])
								else
									CurMessage^^[online] := concat(YellowC, copy(TheQuote.QuotingText^^[Start], 1, 3), WhiteC, copy(TheQuote.QuotingText^^[Start], 4, length(TheQuote.QuotingText^^[Start]) - 3));
								if curMessage^^[online][length(curMessage^^[online])] = char(13) then
									Delete(curMessage^^[online], length(curMessage^^[online]), 1);
								if curMessage^^[online][length(curMessage^^[online])] = char(2) then
									Delete(curMessage^^[online], length(curMessage^^[online]), 1);
								if (TheQuote.QuotingText^^[Start][length(TheQuote.QuotingText^^[Start])] <> char(2)) then
									TheQuote.QuotingText^^[Start] := concat(TheQuote.QuotingText^^[Start], char(2));
								if online + 1 > maxLines then
								begin
									DecipherNQuote := 'Z';
									online := online - 1;
									Exit(DecipherNQuote);
								end;
								online := online + 1;
							end;
							if BlankLine > 0 then
								online := online + BlankLine;
						end
						else if (Start > 0) and (Start <= TheQuote.QuoteEnd) and (Finish = 0) then
						begin
							if TheQuote.QuotingText^^[Start][3] <> '>' then
								CurMessage^^[online] := concat(YellowC, TheQuote.Initials, WhiteC, TheQuote.QuotingText^^[Start])
							else
								CurMessage^^[online] := concat(YellowC, copy(TheQuote.QuotingText^^[Start], 1, 3), WhiteC, copy(TheQuote.QuotingText^^[Start], 4, length(TheQuote.QuotingText^^[Start]) - 3));
							if curMessage^^[online][length(curMessage^^[online])] = char(13) then
								Delete(curMessage^^[online], length(curMessage^^[online]), 1);
							if curMessage^^[online][length(curMessage^^[online])] = char(2) then
								Delete(curMessage^^[online], length(curMessage^^[online]), 1);
							if (TheQuote.QuotingText^^[Start][length(TheQuote.QuotingText^^[Start])] <> char(2)) then
								TheQuote.QuotingText^^[Start] := concat(TheQuote.QuotingText^^[Start], char(2));
							if online + 1 > maxLines then
							begin
								DecipherNQuote := 'Z';
								online := online - 1;
								Exit(DecipherNQuote);
							end;
							online := online + 1;
							if online + BlankLine > maxLines then
							begin
								DecipherNQuote := 'Z';
								online := online - 1;
								Exit(DecipherNQuote);
							end;
							if BlankLine > 0 then
								online := online + BlankLine;
						end;
						BlankLine := 0;
						s := char(0);
						Start := 0;
						Finish := 0;
					end
				until i = length(curPrompt);
			end
			else
			begin
				repeat
					l := pos('B', curPrompt);
					if l <> 0 then
					begin
						BlankLine := BlankLine + 1;
						Delete(curPrompt, l, 1);
					end;
				until pos('B', curPrompt) = 0;

				StringToNum(curPrompt, l);
				if (l <= TheQuote.QuoteEnd) and (l > 0) then
				begin
					if TheQuote.QuotingText^^[l][3] <> '>' then
						CurMessage^^[online] := concat(YellowC, TheQuote.Initials, WhiteC, TheQuote.QuotingText^^[l])
					else
						CurMessage^^[online] := concat(YellowC, copy(TheQuote.QuotingText^^[l], 1, 3), WhiteC, copy(TheQuote.QuotingText^^[l], 4, length(TheQuote.QuotingText^^[l]) - 3));
					if curMessage^^[online][length(curMessage^^[online])] = char(13) then
						Delete(curMessage^^[online], length(curMessage^^[online]), 1);
					if curMessage^^[online][length(curMessage^^[online])] = char(2) then
						Delete(curMessage^^[online], length(curMessage^^[online]), 1);
					if (TheQuote.QuotingText^^[l][length(TheQuote.QuotingText^^[l])] <> char(2)) then
						TheQuote.QuotingText^^[l] := concat(TheQuote.QuotingText^^[l], char(2));
					if online + 1 > maxLines then
					begin
						DecipherNQuote := 'Z';
						online := online - 1;
						Exit(DecipherNQuote);
					end;
					online := online + 1;
					if online + BlankLine > maxLines then
					begin
						DecipherNQuote := 'Z';
						online := online - 1;
						Exit(DecipherNQuote);
					end;
					if BlankLine > 0 then
						online := online + BlankLine;
				end;
			end;
		end;
		DecipherNQuote := TheSpecialChar;
	end;

	procedure DoQPrompt (prompt, accepted: str255; sizeLimit: integer);
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				promptLine := prompt;
				allowedChars := accepted;
				replaceChar := char(0);
				ansiAllowed := false;
				Capitalize := true;
				enforceNumeric := false;
				autoAccept := false;
				wrapAround := false;
				wrapsonCR := true;
				breakChar := char(0);
				HermesColor := 2;
				InputColor := 5;
				numericLow := sizeLimit;
				numericHigh := 0;
				maxChars := -3;
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	procedure ListTheMessage;
		var
			i: integer;
	begin
		with curGlobs^ do
		begin
			if not NewMsg then
				bCR;
			if onLine > 1 then
				for i := 1 to (onLine - 1) do
				begin
					ListLine(i);
					bCR;
				end;
		end;
	end;

	procedure DoQuoter;
		var
			ts, s: str255;
			c: char;
	begin
		with curGlobs^ do
		begin
			case QuoterDo of
				Quote1: 
				begin
					bCR;
					helpnum := 27;
					if NewMsg then
					begin
						if (wasEMail) then
							ts := curEMailRec.Title
						else
							ts := curMesgRec.Title;
						if (ts[1] = char(0)) then
							Delete(ts, 1, 1);
						OutLine('Title: ', true, 2);
						OutLine(ts, false, 4);
						OutLine('', false, 0);
						OutLine('   To: ', true, 2);
						if (wasAnonymous) and (ThisUser.CantReadAnon) then
						begin
							OutLine('>>UNKNOWN<<', false, 4)
						end
						else
						begin
							if (wasEMail) and (curEMailRec.ToUser = TABBYTOID) and (myFido.atNode <> '-100') then
								OutLine(concat(myFido.name, ', ', myFido.atNode), false, 4)
							else if (wasEMail) and (curEMailRec.ToUser = TABBYTOID) and (myFido.atNode = '-100') then
								OutLine(myFido.name, false, 4)
							else if (wasEMail) then
								OutLine(MailingUser.UserName, false, 4)
							else if (not wasEMail) then
								OutLine(curMesgRec.ToUserName, false, 4);
						end;
						OutLine('', false, 0);
						bCR;
						bCR;

						if (InitSystHand^^.Quoter) and (not wasEMail) then
						begin
							if MConference[inForum]^^[inConf].ConfType = 2 then	{Usenet Group always has to be ALL}
							begin
								LettersPrompt(RetInStr(596), 'QT', 1, true, false, true, char(0))
							end
							else
								LettersPrompt(RetInStr(597), 'QTR', 1, true, false, true, char(0));
						end
						else if (not wasEMail) then
							LettersPrompt(RetInStr(598), 'TR', 1, true, false, true, char(0))
						else if (wasEMail) and (InitSystHand^^.Quoter) then
							LettersPrompt(RetInStr(596), 'QT', 1, true, false, true, char(0))
						else if (wasEMail) then
							LettersPrompt(RetInStr(599), 'T', 1, true, false, true, char(0));
						QuoterDo := QTR1;
					end
					else
					begin
						curPrompt := 'Y';
						QuoterDo := Quote2;
					end;
				end;
				QTR1: 
				begin
					if (curPrompt <> '') then
					begin
						if (curPrompt = 'Q') then
						begin
							curPrompt := 'Y';
							QuoterDo := Quote2;
						end
						else if (curPrompt = 'T') then
						begin
							if (wasEMail) then
							begin
								replyStr := curEMailRec.Title;
							end
							else
							begin
								if curMesgRec.Title[1] = char(0) then
									replyStr := copy(curMesgRec.Title, 2, length(curMesgRec.Title) - 1)
								else
									replyStr := curMesgRec.Title;
							end;
							bCR;
							OutLine(RetInStr(600), true, 2);
							OutLine(replyStr, false, 4);
							OutLine('', false, 0);
							bCR;
							bCR;
							LettersPrompt(RetInStr(176), '', 43, false, false, false, char(0));
							ANSIPrompter(43);
							QuoterDo := QTR2;
						end
						else if (curPrompt = 'R') then
						begin
							bCR;
							OutLine(RetInStr(601), true, 2);
							if (WasAnonymous) and (ThisUser.CantReadAnon) then
								OutLine('>>UNKNOWN<<', false, 4)
							else
								OutLine(curMesgRec.ToUserName, false, 4);
							OutLine('', false, 0);
							bCR;
							bCR;
							LettersPrompt(RetInStr(746), '', 31, false, false, false, char(0));
							ANSIPrompter(31);
							QuoterDo := QTR3;
						end
						else
							QuoterDo := Quote1;
					end
					else
						QuoterDo := Quote3;
				end;
				QTR2: {Change Title}
				begin
					if (curPrompt <> '') then
					begin
						if (wasEMail) then
							curEMailRec.Title := curPrompt
						else
						begin
							if (curPrompt = replyStr) and (MConference[inForum]^^[inConf].Threading) then
								replyStr := concat(char(0), curPrompt)
							else
								replyStr := curPrompt;
							curMesgRec.Title := replyStr;
						end;
					end;
					bCR;
					bCR;
					QuoterDo := Quote1;
				end;
				QTR3: {Redirect Reply}
				begin
					if (curPrompt <> '') then
					begin
						if FindUser(curPrompt, tempuser) then
						begin
							if (not tempUser.DeletedUser) then
							begin
								curMesgRec.touserNum := tempuser.userNum;
								curMesgRec.toUserName := tempUser.userName;
							end;
						end
						else if MConference[inForum]^^[inConf].ConfType = 1 then
						begin
							curMesgRec.toUserName := curprompt;
							curMesgRec.touserNum := TABBYTOID;
						end
						else
						begin
							UprString(curPrompt, true);
							if (curPrompt = 'ALL') then
							begin
								curMesgRec.toUserName := 'All';
								curMesgRec.toUserNum := 0;
							end
							else
								OutLine(RetInStr(747), true, 2);
						end;
					end;
					QuoterDo := Quote1;
				end;
				Quote2: {Check Prompt}
				begin
					if curPrompt = 'Y' then
						QuoterDo := Quote4
					else
						QuoterDo := Quote3;
				end;
				Quote3: {Exit Quoter}
				begin
					if NewMsg then
					begin
						bCR;
						OutLineC(StringOf(RetInStr(493), maxLines : 0, RetInStr(494)), false, 0);
						if (wasEMail) and (InitSystHand^^.MailAttachments) and (not thisUser.CantSendPPFile) then
							OutLineC(RetInStr(131), true, 0)	{/HELP-menu,  /ES-save,  /F-attach file/save,  /ABT-abort,  /ESP-sign/save.}
						else if (not WasEMail) and (not thisUser.CantSendPPFile) and (MConference[inForum]^^[inConf].FileAttachments) then
							OutLineC(RetInStr(131), true, 0)	{/HELP-menu,  /ES-save,  /F-attach file/save,  /ABT-abort,  /ESP-sign/save.}
						else
							OutLineC(RetInStr(495), true, 0);	{Enter ''/HELP'' for help, ''/ES'' to save.}
						OutLineC(RetInStr(618), true, 2); {Enter '/RQ' To Quote From Previous Message}
						if thisUser.TerminalType = 1 then
							OutputColorBar;
						ts := RetInStr(496);
						if thisUser.scrnWdth < 80 then
							Delete(ts, thisUser.scrnWdth, 80 - thisUser.scrnWdth);
						OutLine(ts, true, 0);
						bCR;
						bCR;
						ListTheMessage;
						if curPrompt = '**NO MORE LINES**' then
						begin
							OutLine(RetInStr(491), true, 0);	{-= No more lines =-}
							OutLine(RetInStr(492), true, 0);	{/ES to save.}
							bCR;
						end;
						NewMsg := False;
						if thisUser.TerminalType = 1 then
						begin
							ts := concat(char(3), MakeColorSequence(16));
							CurMessage^^[online] := ts;
							doM(16);
							saveColor := 16;
						end;
					end
					else
					begin
						ListTheMessage;
						OutLine(RetInStr(614), true, 0);	{Continue...}
						bCR;
						doM(saveColor);
						if savecolor <> 0 then
						begin
							ts := concat(char(3), MakeColorSequence(saveColor));
							curMessage^^[onLine] := ts;
						end;
					end;
					lnsPause := 0;
					BoardAction := Writing;
					if wasEmail then
						BoardSection := Email
					else if wasSearching then
						BoardSection := MessageSearcher
					else
						BoardSection := Post;
				end;
				Quote4: 
				begin
					ListTextToQuote;
					bCR;
					OutLine('Enter Lines to Quote: (e.g. 1-5,8-9B,21-24Q)  Add (B)lank Line and (Q)uit:', true, 2);
					bCR;
					ts := '01234567890-,QB ';
					s := 'Q]uit : ';
					if TheQuote.QuoteMark + 21 <= TheQuote.QuoteEnd then
					begin
						ts := concat(ts, 'N');
						s := concat('N]ext Page, ', s);
					end;
					if TheQuote.QuoteMark - 20 > -1 then
					begin
						ts := concat(ts, 'P');
						s := concat('P]revious Page, ', s);
					end;
					DoQPrompt(s, ts, 80 - length(s));
					QuoterDo := Quote5;
				end;
				Quote5: (* Check Prompt & Quote *)
				begin
					if (curPrompt = 'Q') or (curPrompt = '') then
					begin
						online := online + 1; {To give us a blank line}
						QuoterDo := Quote3;
					end
					else if curPrompt = 'N' then
					begin
						TheQuote.QuoteMark := TheQuote.QuoteMark + 20;
						QuoterDo := Quote4;
					end
					else if curPrompt = 'P' then
					begin
						TheQuote.QuoteMark := TheQuote.QuoteMark - 20;
						QuoterDo := Quote4;
					end
					else if curPrompt[1] > '0' then
					begin
						c := DecipherNQuote;
						if c = 'Z' then
						begin
							curPrompt := '**NO MORE LINES**';
							QuoterDo := Quote3;
						end
						else if c <> char(0) then
							curPrompt := c
						else
							QuoterDo := Quote4;
					end
					else
						QuoterDo := Quote4;
				end;
				otherwise
			end;
		end;
	end;

	procedure OpenQuoterSetup;
		var
			ItemType: integer;
			ItemHandle: handle;
			ItemRect: rect;
	begin
		if QuoterDlg = nil then
		begin
			QuoterDlg := GetNewDialog(235, nil, Pointer(-1));
			SetPort(QuoterDlg);
			SetGeneva(QuoterDlg);

			FrameIt(QuoterDlg, 18);
			SetCheckBox(QuoterDlg, 11, InitSystHand^^.Quoter);
			SetCheckBox(QuoterDlg, 12, InitSystHand^^.UseQuoteHeader);

			SetCheckBox(QuoterDlg, 15, false);
			SetCheckBox(QuoterDlg, 16, false);
			SetCheckBox(QuoterDlg, 17, false);
			if (InitSystHand^^.QuoteHeaderOptions = UseNormal) then
				SetCheckBox(QuoterDlg, 15, true)
			else if (InitSystHand^^.QuoteHeaderOptions = UseAnonAndNormal) then
				SetCheckBox(QuoterDlg, 16, true)
			else
				SetCheckBox(QuoterDlg, 17, true);

			if InitSystHand^^.QuoteHeader[1] = char(0) then
				InitSystHand^^.QuoteHeader := 'On %date, %sender quoted %receiver: %title.';
			SetTextBox(QuoterDlg, 3, InitSystHand^^.QuoteHeader);
			if InitSystHand^^.QuoteHeaderAnon[1] = char(0) then
				InitSystHand^^.QuoteHeaderAnon := 'On %date, %receiver was quoted: %title.';
			SetTextBox(QuoterDlg, 13, InitSystHand^^.QuoteHeaderAnon);

			GetDItem(QuoterDlg, 1, ItemType, ItemHandle, ItemRect);
			InsetRect(ItemRect, -4, -4);
			PenSize(3, 3);
			FrameRoundRect(ItemRect, 16, 16);

			ShowWindow(QuoterDlg);
		end
		else
			SelectWindow(QuoterDlg);
	end;

	procedure UpdateQuoterSetup;
		var
			SavedPort: GrafPtr;
			ItemType: integer;
			ItemHandle: handle;
			ItemRect: rect;
	begin
		GetPort(SavedPort);
		SetPort(QuoterDlg);
		FrameIt(QuoterDlg, 18);
		DrawDialog(QuoterDlg);
		GetDItem(QuoterDlg, 1, ItemType, ItemHandle, ItemRect);
		InsetRect(ItemRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(ItemRect, 16, 16);
		SetPort(SavedPort);
	end;

	procedure DoQuoterSetup (event: EventRecord; itemHit: integer);
		var
			ItemType: integer;
			ItemHandle: handle;
			ItemRect: rect;
			s: str255;
	begin
		if (QuoterDlg <> nil) and (QuoterDlg = FrontWindow) then
		begin
			SetPort(QuoterDlg);
			case ItemHit of
				1: {OK}
				begin
					InitSystHand^^.Quoter := GetCheckBox(QuoterDlg, 11);
					s := GetTextBox(QuoterDlg, 3);
					if (length(s) > 0) then
						InitSystHand^^.QuoteHeader := s;
					s := GetTextBox(QuoterDlg, 13);
					if (length(s) > 0) then
						InitSystHand^^.QuoteHeaderAnon := s;
					InitSystHand^^.UseQuoteHeader := GetCheckBox(QuoterDlg, 12);
					if (GetCheckBox(QuoterDlg, 15)) then
						InitSystHand^^.QuoteHeaderOptions := UseNormal
					else if (GetCheckBox(QuoterDlg, 16)) then
						InitSystHand^^.QuoteHeaderOptions := UseAnonAndNormal
					else
						InitSystHand^^.QuoteHeaderOptions := NoHeaderInAnon;

					DoSystRec(true);
					CloseQuoterSetup;
				end;
				2: {Cancel}
					CloseQuoterSetup;
				11, 12:	{Use Quoter}
				begin
					if GetCheckBox(QuoterDlg, ItemHit) then
						SetCheckBox(QuoterDlg, ItemHit, False)
					else
						SetCheckBox(QuoterDlg, ItemHit, True);
				end;
				15, 16, 17: 
				begin
					SetCheckBox(QuoterDlg, 15, False);
					SetCheckBox(QuoterDlg, 16, False);
					SetCheckBox(QuoterDlg, 17, False);
					SetCheckBox(QuoterDlg, ItemHit, true);
				end;
				otherwise
			end;
		end;
	end;

	procedure CloseQuoterSetup;
	begin
		if QuoterDlg <> nil then
		begin
			DisposDialog(QuoterDlg);
			QuoterDlg := nil;
		end;
	end;


end.