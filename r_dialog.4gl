###############################################################################
#
#	(c) Copyright Century Software Pty. Ltd. Australia, 1986-2011
#	http://www.CenturySoftware.com.au
#   License granted to Brandbank for internal use.
#   This code cannot be distributed in binary or source format.
#
############################################################################
#
#	gp_dialog.4gl			Dialog box routines
#
#	External Functions:
#		gp_Dialog			Run a dynamic dialog box
#		gp_PrepareBox		Prepare a new dialog box for later execution
#		gp_ExecBox			Execute operation on prepared dialog box
#		gp_DBerr			Database error dialog
#		gp_Version			Version advice dialog
#
#	Move to lib_gen:
#		gp_dberr
#		gp_version
#		gp_ResourceGet
#
#	Local Functions:
#		gpx_CentreJustify	Centre justify strings
#		gpx_SplitString		Splits a string into 2 parts with a delimiter
#		gpx_Clipped			Clip spaces from both sides of string
#		gpx_PromptForAnyKey	Prompt for any key
#		gpx_OpenWindow		Open window and return window descriptor
#		gpx_CloseWindow		Close window opened with gpx_OpenWindow
#		gpx_CurrentWindow	Make window current
#		gpx_Heap			Heap operations
#		gpx_FetchData		Fetch data from heap
#		gpx_GUIdialog		GUI Dialog for "any", "yes" and "no" dialogs
#		gpx_GUImenu			GUI Menu
#		gpx_FindItem		Find an item from an array matching first char
#		gpx_NextItem		Find next item in array which is not null
#		gpx_WinDialog		Call Windowed dialog box using approp function
#		
#	See Individual Function for further details.
#
#############################################################################
GLOBALS
	DEFINE
		g_pgm		CHAR(20),
		g_dbtrans	INTEGER,
		g_dbtype	CHAR(20),
		g_rlockid	CHAR(20),
		g_version	CHAR(40),
		g_gui		INTEGER,
		g_GUIclient	CHAR(8),
		g_GUIfename	STRING,
		g_underscore	INTEGER,
		g_background    CHAR(1),
		g_dbname	CHAR(20)
END GLOBALS

DEFINE
	s_once			INTEGER,
	s_count			INTEGER,
	s_retry			INTEGER,

	s_initialized	INTEGER,
	s_dialogLocal	INTEGER,

	sa_windowstat	ARRAY [12] OF CHAR(1),
	s_heap			CHAR(4096),
	s_dsize			INTEGER,
	s_heapsize		INTEGER,
	sa_heapptr		ARRAY [64] OF
						RECORD
							p_active	SMALLINT,
							p_start		SMALLINT,
							p_end		SMALLINT
						END RECORD,
	sa_dialog		ARRAY [32] OF
						RECORD
							p_name		CHAR(20),	#### Name of dialog
							p_mode		CHAR(8),	#### Dialog type
							i_title		SMALLINT,	#### Title pointer
							i_message	SMALLINT,	#### Menu pointer
							i_prompt	SMALLINT,	#### Prompt pointer
							p_row		SMALLINT,	#### Default row
							p_col		SMALLINT,	#### Default column
							p_help		SMALLINT,	#### Help number
							p_active	SMALLINT	#### status
						END RECORD,
	s_f_prompt		INTEGER,
	s_WebMenu		INTEGER	,
	s_DisplayTrx	INTEGER	


{


###############################################################################
#
#	gp_Dialog	Pop up an interactive dialogue box.
#				This similar to GUI (Mac, etc.) type dialogue boxes.
#				It can be used to grab the user's attention
#				and prompt them for appropiate action.
#				This routine simply supplies the mechanism. The formatting of
#				the message is left to the user.
#				The tendency to add to many options to this has been
#				avoided, since this will make this much easier to use.
#
#	Synopsis:
#	 	gp_Dialog(p_title, p_message, p_prompt, p_mode, p_row, p_col, p_help)
#
#	Where:
#		p_title		The title (if any) of this dialogue box.
#					If this is blank or NULL, then no title will
#					be displayed.
#		p_message	The message or body of text to display.
#					Arrays are too cumbersome to pass as parameters, so
#					A string (limit of 512 chars) is used to pass the message.
#					New lines are separated by "|" for delimiters, hence the
#					message can effectively dictate the size of the dialogue
#					box. Furthermore, other routines can be used to format
#					the string, justify it if required or extract messages
#					from the database. Despite the string limitation, dialogue
#					boxes are mean't to be small and short.
#					For menus, each segment is a menu option. If an option
#					is selected, then the segment string is returned.
#					R01: Pull-down, Pop-up are available in a similar format;
#					Each menu option is separated by the "|" delimiter.
#					R03: Empty segments can be used as separators. Also menu
#					items beginning with a space can also be used as separators
#					since a menu option must be selectable by single character
#					key stroke and a space only points to next option.
#					Hence " ---------- " is a separator element.
#		p_prompt	Prompt for user action.
#					R05: Previously ignored in menus, a prompt can be passed
#					which will be displayed on line 23 in REVERSE (like dsp23).
#					No prompt is displayed if p_prompt is NULL. On exiting,
#					the previous line 23 is restored. If prompt = "default",
#					a default pick & point message is displayed.
#		p_mode		This determines the type of user interaction required.
#					Currently supported are:
#						"yes"		Confirmation defaulting to YES
#						"no"		Confirmation defaulting to NO
#						"ready"		Ready/Hold defaulting to HOLD
#						"update"	Update/Hold defaulting to HOLD
#						"proceed"	Proceed/Update defaulting to UPDATE
#						"any"		Press any key to continue
#						"menu"		Pull down menu of options
#					Additionally, if a "!" character is appended to the end,
#					an audible bell is sent when window is opened.
#		p_row,p_col	R02: Override location of window.
#					When p_row or p_col is zero,
#					the middle row or middle column is used to centre the
#					pop-up window. Hence, if both p_row & p_col are zero
#					then the window is centred in the middle of the screen.
#					When either value is set, that value is used to locate
#					the top left hand corner of the window.
#		p_help		Help number for this dialog box. F10 will be used to
#					activate this. Only one help screen per dialog is supported.
#					This should be plenty even though it would have been nice
#					to have help at each "decision" point in a dialog.
#
#	Returns:
#		This, due to the nature of this function must be a string.
#		For "any" mode, NULL is returned.
#		For "yes/no", the string "YES" or "NO" is returned.
#		For "ready/hold", "READY" or "HOLD" is returned.
#		For "update/hold", "UPDATE" or "HOLD" is returned.
#		For "proceed/update", "PROCEED" or "UPDATE" is returned.
#		For "menu", the selected option is retured or NULL on INTERRUPT,F4
#		If exact types are required, then write a higher level routine to
#		interpret these!
#
#
###############################################################################


FUNCTION gp_Dialog(p_title, p_message, p_prompt, p_mode, p_row, p_col, p_help)

	DEFINE

		### Args ###
		p_title			CHAR(80),
		p_message		CHAR(512),
		p_prompt		CHAR(80),
		p_mode			CHAR(8),
		p_row			INTEGER,
		p_col			INTEGER,
		p_help			INTEGER,

		### Constants ###
		pc_delimiter	CHAR(1),
		pc_cmdlimiter	CHAR(1),
		pc_scrrows		INTEGER,
		pc_scrcols		INTEGER,
		pc_ynsize		INTEGER,
		pc_maxrows		INTEGER,		

		### Locals ###
		pa_dialog 		ARRAY[16] OF CHAR(80),
		pa_command		ARRAY[16] OF CHAR(20),
		p_option		CHAR(80),
		p_input			CHAR(10),	
		p_type			CHAR(8),
		p_keyput		CHAR(1),
		p_keydown		CHAR(1),
		p_keyup			CHAR(1),
		p_keychar		CHAR(1),
		pw_dialog		INTEGER,
		pw_message		INTEGER,
		p_retstat		INTEGER,
		p_maxlength		INTEGER,
		p_maxlines		INTEGER,
		p_height		INTEGER,
		p_width			INTEGER,
		p_length		INTEGER,
		p_typeoffset	INTEGER,
		p_selected		INTEGER,
		p_continue		INTEGER,
		p_ptr			INTEGER,
		p_dir			INTEGER,
		p_start			INTEGER,
		p_text			INTEGER,
		p_menuitems		INTEGER,
		idx				INTEGER

	LET p_title = gp_sed(p_title,"*","",0)

	IF NOT s_initialized		
	THEN					
		LET pc_scrrows = 24
		LET pc_scrcols = 80
		LET pc_ynsize = 15
		LET pc_delimiter = "|"
		LET pc_cmdlimiter = "!"
		LET pc_maxrows = 16					

		### get/set resource for dialog style ###
		LET s_dialogLocal = 0
		LET p_option = gp_ResourceGet("acct.gp.dialog.local")
		IF p_option MATCHES "[0-9]"
		THEN
			LET s_dialogLocal = p_option
		END IF
		INITIALIZE p_option TO NULL
	END IF


	### Determine what menu style to use ###
	IF g_gui < 1 OR fgl_getenv("UTDIALOGTYPE") = "BDL"
	THEN
		LET s_WebMenu = FALSE
	ELSE
		LET s_WebMenu = TRUE
	END IF



	#
	#	Message Dissection
	#		The message is broken into smaller segments.
	#		An arbitrary limit of 16 lines is catered for (this should
	#		be sufficient since this is supposed to be a dialogue
	#		box and not an epic).
	#		New segment delimiters are "|" symbols.
	#		This should be configurable to any symbol.
	#		This permits a certain degree of formatting.
	#		IF WE HAVE TO DO SOME FUNNY THINGS TO WORK AROUND 4GL'S
	#		inability to distinguish between spaces & empty strings.
	#		%%% Other routines can be used to create the message string
	#		and do justifying, etc.
	#		%%% Yet another routine can be called to extract dialogue info
	#		from database tables of dialogue data.
	#

	LET p_typeoffset = 1
	INITIALIZE p_option TO NULL
	FOR idx = 1 TO pc_maxrows
		INITIALIZE pa_dialog[idx] TO NULL
		INITIALIZE pa_command[idx] TO NULL
	END FOR

	### Branch to GUI Functions if available ###
	IF g_gui AND p_mode NOT MATCHES "[Mm]*"
	THEN
		RETURN gpx_GUIdialog(p_title, p_message, p_prompt, p_mode)
	END IF

	### Determine type of dialogue ###
	CASE
	### Yes/No/Ready/Update/Proceed ###
	WHEN p_mode MATCHES "[YyNnRrUuPp]*"
		LET p_type = "CONFIRM"
	WHEN p_mode MATCHES "[Mm]*"
		LET p_type = "MENU"
		LET p_typeoffset = 0
	OTHERWISE
		LET p_type = "ANY"
	END CASE

	### Parse and distribute message ###
	LET p_maxlength = LENGTH(p_message)
	LET p_ptr = 1
	LET p_start = 1
	LET p_text = 0
	LET p_menuitems = 0
	FOR idx = 1 TO pc_maxrows
		### Check for end of message ###
		IF p_ptr > p_maxlength
		THEN
			LET idx = idx - 1
			EXIT FOR
		END IF

		### Search for end of segment ###
		WHILE p_ptr <= p_maxlength AND p_message[p_ptr] != pc_delimiter
			LET p_ptr = p_ptr + 1
		END WHILE

		### Set segment as line ###
		IF p_start < p_ptr
		THEN
			LET pa_dialog[idx] = p_message[p_start,p_ptr-1] CLIPPED
			LET p_text = p_text + 1

			### count valid menu items ###
			IF p_type = "MENU"
			THEN
				IF pa_dialog[idx][1,1] != " "
				THEN
					LET p_menuitems = p_menuitems + 1

					### Split apart if command exists ###
					CALL gpx_SplitString("!", pa_dialog[idx])
						RETURNING pa_dialog[idx], pa_command[idx]
					LET pa_command[idx] = gpx_Clipped(pa_command[idx])
				END IF
			END IF
		END IF
		LET p_ptr = p_ptr + 1
		LET p_start = p_ptr
	END FOR

	### Some boundary adjustments ###
	IF p_maxlength > 0
	THEN
		IF p_text AND p_message[p_maxlength,p_maxlength] = pc_delimiter
		THEN
			LET idx = idx + 1
		END IF
	END IF
	IF idx > pc_maxrows
	THEN
		LET p_maxlines = pc_maxrows
	ELSE
		LET p_maxlines = idx
	END IF

	### Check for options if menu ###
	IF p_type = "MENU" AND p_menuitems < 2
	THEN
		### A little bit of recursion here! ###
		LET p_message = "|",
			"There were insufficient options to create a menu.|",
			"A menu must have at least 2 items to choose from.|"
		RETURN gp_dialog("BAD MENU!", p_message,
			"Press any key to continue", "any", 0, 0, 0)
	END IF



	#
	#	Size Window
	#		The size of the window is determined by checking lengths
	#		of all participants and number of lines used.
	#		A border is not an option, but mandatory, since the idea
	#		is to catch the user's attention. A bell could be an option
	#		but this can be done prior to calling this routine if required.
	#		Also a space will be cushion the message from the borders.
	#
	### Now determine width of box ###
	LET p_width = LENGTH(p_title)
	CASE
	WHEN p_type = "CONFIRM"
		LET p_length = LENGTH(p_prompt) + pc_ynsize
	WHEN p_type = "MENU"
		LET p_length = 7
	OTHERWISE
		LET p_length = LENGTH(p_prompt)
	END CASE
	IF p_length > p_width
	THEN
		LET p_width = p_length
	END IF
	FOR idx = 1 TO p_maxlines
		LET p_length = LENGTH(pa_dialog[idx])
		IF p_length > p_width
		THEN
			LET p_width = p_length
		END IF
	END FOR
	LET p_width = p_width + 2

	### Height of box ###
	LET p_height = p_maxlines + 3

	### Set location of box: centre if row or col is zero ###
	IF p_row = 0
	THEN
		LET p_row = ((pc_scrrows - p_height) / 2) + 1
	END IF
	IF p_col = 0
	THEN
		LET p_col = ((pc_scrcols - p_width) / 2) + 1
	END IF



	#
	#	Pop-Up and Display
	#		Title lives on the first line (centre justified)
	#		Then message text
	#		Then prompt or menu (centre justified)
	#		The last line is wasted (for consistency with menu)
	#

	### Begin Open appropriate type of window ###
	IF p_type = "MENU" AND g_gui
	THEN
		IF NOT s_WebMenu
		THEN		
			LET pw_dialog = gpx_OpenWindow("gp_mg",
				p_row, p_col, p_height-3, p_width)
		END IF	
	ELSE
		LET pw_dialog = gpx_OpenWindow("DIALOG",
			p_row, p_col, p_height, p_width)
	END IF
		
	###  Open window ###
	IF pw_dialog < 1 AND NOT s_WebMenu					
	THEN
		RETURN ""
	END IF
	IF p_mode MATCHES "*!"
	THEN
		ERROR ""
	END IF
	LET pw_message = 0								

	### Display title ###
	IF LENGTH(p_title) > 1
	THEN

		IF NOT (g_gui AND p_type = "MENU")
		THEN							
			LET p_title = gpx_CentreJustify(p_title, p_width - 2)
			IF g_gui											
			THEN											
				DISPLAY p_title[1, p_width - 2]					
					AT 1,2  
			ELSE											
				DISPLAY p_title
					AT 1,2  
				DISPLAY "  " AT 1, p_width				
			END IF								
		END IF								
	END IF

	### Display message lines if not GUI (which uses DISP ARR) ###
	IF NOT (g_gui AND p_type = "MENU")	
	THEN							
		### Form used by gp_GetKey to catch keystrokes ###
		IF p_type = "MENU"
		THEN
			### only open this once - and keep it open ###
			IF NOT s_f_prompt
			THEN
				OPEN FORM f_prompt FROM "gp_dialog"
				LET s_f_prompt = TRUE
			END IF
			DISPLAY FORM f_prompt ATTRIBUTE(NORMAL, INVISIBLE)
		END IF

		### Displays menu option lines ###
		FOR idx = 1 TO p_maxlines
			LET p_ptr = idx + 2 - p_typeoffset
			DISPLAY pa_dialog[idx] CLIPPED
				AT p_ptr,2  

			### Hi-lite first char if menu ###
			IF p_type = "MENU"
			THEN
				LET p_keychar = pa_dialog[idx][1,1]
				DISPLAY p_keychar
					AT p_ptr,2 ATTRIBUTE(NORMAL, BOLD)
			END IF
		END FOR
	END IF		



	#
	#	Interact With User
	#		The yes/no menu is actually a subwindow
	#		to simulate the "buttons" usually found in dialogue boxes.
	#

	CASE

	#
	#	Get confirmation from user
	#
	WHEN p_type = "CONFIRM"
		### Display prompt ###
		LET p_length = LENGTH(p_prompt)
		LET p_height = p_height - 1
		LET idx = ((p_width - p_length - pc_ynsize) / 2) + 2
		DISPLAY p_prompt
			AT p_height,idx  

		### Pop up menu window ###
		LET p_row = p_row + p_height - 1
		LET p_col = p_col + idx + p_length - 1
		LET p_width = p_width - 2
		OPEN WINDOW w_dgconfirm AT p_row, p_col WITH 2 ROWS, pc_ynsize COLUMNS
		ATTRIBUTE(STYLE="popup")

		### Get user choice, prime with appropiate default ###
		CASE
		WHEN p_mode MATCHES "[Yy]*"
			MENU ""
				COMMAND "Yes"
					LET p_option = "YES"
					EXIT MENU
				COMMAND "No"
					LET p_option = "NO"
					EXIT MENU

				### %%%% Standard ONKEYS here ###
			END MENU
		WHEN p_mode MATCHES "[Nn]*"
			MENU ""
				COMMAND "No"
					LET p_option = "NO"
					EXIT MENU
				COMMAND "Yes"
					LET p_option = "YES"
					EXIT MENU

				### %%%% Standard ONKEYS here ###
			END MENU
		WHEN p_mode MATCHES "[Rr]*"
			MENU ""
				COMMAND "Ready"
					LET p_option = "READY"
					EXIT MENU
				COMMAND "Hold"
					LET p_option = "HOLD"
					EXIT MENU
			END MENU		
		WHEN p_mode MATCHES "[Uu]*"
			MENU ""
				COMMAND "Update"
					LET p_option = "UPDATE"
					EXIT MENU
				COMMAND "Hold"
					LET p_option = "HOLD"
					EXIT MENU
			END MENU		
		WHEN p_mode MATCHES "[Pp]*"
			MENU ""
				COMMAND "Update"
					LET p_option = "PROCEED"
					EXIT MENU
				COMMAND "Update"
					LET p_option = "UPDATE"
					EXIT MENU
			END MENU		
		END CASE	
		
		CLOSE WINDOW w_dgconfirm		


	#
	#	Press any key to continue
	#
	WHEN p_type = "ANY"

		### Centre prompt on prompt line ###
		LET p_prompt = gpx_CentreJustify(p_prompt, p_width-2)
		LET p_row = p_height - 1
		DISPLAY p_prompt CLIPPED
			AT p_row, 2  
		### R04: mod for Fkeys ###
		CALL gpx_PromptForAnyKey(p_help)


	#
	#	Pull-down/Pop-up menu
	#
	WHEN p_type = "MENU"

		### Initialize ###
		LET p_continue = TRUE
		LET p_option = ""
		LET p_row = 1

		#
		#	%%% Skip for WebMenu?
		#

		###  Branch to GUI Menu ###
		IF g_gui
		THEN
			IF s_WebMenu										
			THEN											
				### Standard GUI ###					
				LET p_option = gpx_WebMenu(p_title, p_width,	
					pa_dialog, pa_command, p_maxlines, p_help)
			ELSE											
				### For web - HTML and Java ###			
				LET p_option = gpx_GUImenu(p_title, p_width,
					pa_dialog, pa_command, p_maxlines, p_help)
			END IF									

			EXIT CASE
		END IF


		#
		#	Loop until quit or option chosen
		#	This has unfortunately become a little complicated
		#	over the last few mods
		#
		LET p_selected = FALSE
		WHILE p_continue

			### Highlight current line ###
			LET p_ptr = p_row + 2
			LET p_option = pa_dialog[p_row]
			DISPLAY " ", p_option
				AT p_ptr,1  

			### if selected, then check if a command exists ###
			IF p_selected
			THEN
				IF pa_command[p_row] IS NULL
				THEN
					EXIT WHILE
				ELSE
					#### Call next dialog ###
					LET p_option = gp_ExecBox("RUN", pa_command[p_row])
					IF p_option IS NOT NULL
					THEN
						### need return full menu path ###
						LET p_option = pa_dialog[p_row] CLIPPED, "|",
							p_option CLIPPED
						EXIT WHILE
					END IF
				END IF
			END IF

			IF g_dbtype MATCHES "*V04"
			THEN					
				OPTIONS			
					INPUT ATTRIBUTE(INVISIBLE)			
			END IF									

			OPTIONS
				ACCEPT KEY CONTROL-M

			### Get operator selection ###
			LET p_selected = FALSE
			LET p_dir = 1


			LET p_input = gp_GetKey()
			CASE
			WHEN p_input = "UP" OR p_input = "LEFT"
				LET p_dir = -1
				INITIALIZE p_option TO NULL
			WHEN p_input = "DOWN" OR p_input = "RIGHT"
				LET p_dir = 1
				INITIALIZE p_option TO NULL
			WHEN p_input = "F4" OR p_input = "DEL"
				INITIALIZE p_option TO NULL
				LET p_continue = FALSE
				LET p_selected = TRUE
			WHEN p_input ="F1" OR p_input = "RETURN"
				LET p_selected = TRUE
			WHEN p_input = "F10"
				CALL showhelp(p_help)
			OTHERWISE
				LET p_input = p_input CLIPPED
				IF LENGTH(p_input) = 1 THEN
					LET p_keyput = p_input[1,1]
				END IF
			END CASE

			OPTIONS
				ACCEPT KEY F1
			### Check for exit/accept status ###
			IF p_selected
			THEN
				CONTINUE WHILE
			END IF

			#
			#	%%%% Need to cater for multiple occurences - one day
			#
			### Check input key against options list ###
			FOR idx = 1 TO p_maxlines
				IF gp_upshift(p_keyput) = gp_upshift(pa_dialog[idx][1,1])
				THEN
					### Defer selection for a little while ###
					LET p_selected = TRUE
					LET p_option = pa_dialog[idx]
					EXIT FOR
				END IF
			END FOR

			### Check for illegal characters ###
			IF NOT p_selected AND p_keyput IS NOT NULL AND p_keyput != " "
			THEN
				### Error ###
				ERROR ""
				CONTINUE WHILE
			END IF

			### Clear previous option ###
			DISPLAY " ", pa_dialog[p_row]
				AT p_ptr,1  
			LET p_keychar = pa_dialog[p_row][1,1]
			DISPLAY p_keychar
				AT p_ptr,2 ATTRIBUTE(NORMAL, BOLD)

			### If option selected then skip the rest ###
			IF p_selected
			THEN
				LET p_row = idx
				CONTINUE WHILE
			END IF

			### return or space, find next option ###
			LET p_row = p_row + p_dir
			WHILE TRUE
				IF p_row > p_maxlines
				THEN
					LET p_row = 1
				END IF
				IF p_row < 1
				THEN
					LET p_row = p_maxlines
				END IF
				IF pa_dialog[p_row] IS NULL
					OR pa_dialog[p_row][1,1] = " "
				THEN
					LET p_row = p_row + p_dir
				ELSE
					EXIT WHILE
				END IF
			END WHILE

		END WHILE

	END CASE	

	### End session : closes prompt window w_message ###
	### New windows, no close form f_prompt ###
	IF pw_message > 0	
	THEN
		CALL gpx_CloseWindow(pw_message)
	END IF


	### New windows ###
	IF NOT s_WebMenu
	THEN		
		CALL gpx_CloseWindow(pw_dialog)
	END IF	

	RETURN p_option CLIPPED

END FUNCTION




###############################################################################
#
#	gp_PrepareBox	Prepare a dialog box for later execution.
#					Similar to gp_dialog, this function allows dialogs
#					to be stored and re-executed repeatedly. It is also
#					the only way of calling another dialog from within
#					an existing dialog. A user name is attached to the dialog
#					box which is used as a "key" to access the prepared dialog.
#					This is supplied by the calling program.
#					Subsequent calls using the same key updates the
#					existing dialog, otherwise a new dialog is created.
#					Only one additional parameter is required over gp_dialog.
#
#	Synopsis:
#	 	gp_PrepareBox(p_name,
#			p_title, p_message, p_prompt, p_mode, p_row, p_col, p_help)
#
#	Where:
#		p_name		Name of dialog
#		p_title, p_message, p_prompt, p_mode, p_row, p_col, p_help
#					See gp_dialog()
#
#	Returns:
#		TRUE if OK, else FALSE
#
###############################################################################

FUNCTION gp_PrepareBox(p_name,
			p_title, p_message, p_prompt, p_mode, p_row, p_col, p_help)

	DEFINE

		### Args ###
		p_name			CHAR(20),
		p_title			CHAR(80),
		p_message		CHAR(512),
		p_prompt		CHAR(80),
		p_mode			CHAR(8),
		p_row			INTEGER,
		p_col			INTEGER,
		p_help			INTEGER,

		### constants ###
		pc_maxdialog	INTEGER,

		### Local ###
		p_void			CHAR(1),
		idx				INTEGER


	### "constants" ###
	LET pc_maxdialog = 32


	### Drop possibly existing dialog ###
	CALL gp_ExecBox("DELETE", p_name)
		RETURNING p_void

	### If not found, then search for any free dialog ###
	FOR idx = 1 TO pc_maxdialog
		IF NOT sa_dialog[idx].p_active
		THEN
			EXIT FOR
		END IF
	END FOR

	### If nothing available - sorry ###
	IF idx > pc_maxdialog
	THEN
		ERROR _("gpx_PrepareBox: Out of dialog pointers")
		SLEEP 2
		RETURN FALSE
	END IF

	### Set new dialog ###
	LET sa_dialog[idx].p_active = TRUE
	LET sa_dialog[idx].p_name = p_name
	LET sa_dialog[idx].p_mode = p_mode
	LET sa_dialog[idx].p_row = p_row
	LET sa_dialog[idx].p_col = p_col
	LET sa_dialog[idx].p_help = p_help
	LET sa_dialog[idx].i_title = gpx_Heap("ADD", 0, p_title)
	LET sa_dialog[idx].i_message = gpx_Heap("ADD", 0, p_message)
	LET sa_dialog[idx].i_prompt = gpx_Heap("ADD", 0, p_prompt)

	RETURN TRUE

END FUNCTION




###############################################################################
#
#	gp_ExecBox		Operations on prepared dialog boxes
#
#	Synopsis:
#	 	gp_ExecBox(p_request, p_name)
#
#	Where:
#		p_request	Action to take
#					"RUN" or "EXEC*"	Execute the named dialog box
#					"DELETE" or "DROP"	Remove the dialog box
#					"CLEAR"				Clear all dialog boxes
#		p_name		Name of dialog - this may contain parameter list as well
#					e.g. "update_menu(1,2)". These are ignored for anything
#					other than "RUN" or "EXEC*"
#
#	Returns:
#		Menu option if chosen when "RUN"
#		In all other cases, NULL
#
###############################################################################

FUNCTION gp_ExecBox(p_request, p_name)

	DEFINE

		### Args ###
		p_request		CHAR(8),
		p_name			CHAR(30),

		### constants ###
		pc_maxdialog	INTEGER,

		### Local ###
		p_args			CHAR(20),
		p_void			INTEGER,
		p_row			INTEGER,
		p_col			INTEGER,
		p_start			INTEGER,
		p_end			INTEGER,
		idx				INTEGER


	### "constants" ###
	LET pc_maxdialog = 32
	LET p_request = gp_upshift(p_request)


	### Separate possible parameters ###
	LET p_args = ""
	IF p_name MATCHES "*(*)"
	THEN
		CALL gpx_SplitString("(", p_name)
			RETURNING p_name, p_args
	END IF

	### Search for dialog name ###
	FOR idx = 1 TO pc_maxdialog
		IF sa_dialog[idx].p_active
		THEN
			IF sa_dialog[idx].p_name = p_name
			THEN
				EXIT FOR
			END IF
		END IF
	END FOR

	### If nothing found - forget it ###
	IF idx > pc_maxdialog
	THEN
		RETURN ""
	END IF

	### Set new dialog ###
	CASE
	WHEN p_request = "CLEAR"
		LET p_start = 1
		LET p_end = pc_maxdialog

	WHEN p_request = "DELETE" or p_request = "DROP"
		LET p_start = idx
		LET p_end = idx
	
	WHEN p_request = "RUN" or p_request MATCHES "EXEC*"
		IF p_args IS NOT NULL
		THEN
			### Extract row & column arguments ###
			CALL gpx_SplitString(",", p_args)
				RETURNING p_row, p_args
			CALL gpx_SplitString(")", p_args)
				RETURNING p_col, p_args
		ELSE
			### Set to previously defined row & column ###
			LET p_row = sa_dialog[idx].p_row
			LET p_col = sa_dialog[idx].p_col
		END IF

		### Run this dialog ###
		RETURN gp_dialog(
			gpx_FetchData(sa_dialog[idx].i_title),
			gpx_FetchData(sa_dialog[idx].i_message),
			gpx_FetchData(sa_dialog[idx].i_prompt),
			sa_dialog[idx].p_mode,
			p_row, p_col, sa_dialog[idx].p_help)

	END CASE


	### Clear and deletes ###
	FOR idx = p_start TO p_end
		IF sa_dialog[idx].p_active
		THEN
			LET sa_dialog[idx].p_active = FALSE
			LET sa_dialog[idx].p_name = ""
			LET sa_dialog[idx].p_mode = ""
			LET sa_dialog[idx].p_row = 0
			LET sa_dialog[idx].p_col = 0
			LET sa_dialog[idx].p_help = 0
			LET p_void = gpx_Heap("DELETE", sa_dialog[idx].i_title, "")
			LET p_void = gpx_Heap("DELETE", sa_dialog[idx].i_message, "")
			LET p_void = gpx_Heap("DELETE", sa_dialog[idx].i_prompt, "")
		END IF
	END FOR

	RETURN ""

END FUNCTION




################################################################################
#
#	gpx_CentreJustify		Centre justify string
#
#	Synopsis:
#		gpx_CentreJustify(p_string, p_width)
#
#	Where:
#		p_string	string to justify
#		p_width		field width to justify in (max 80)
#
#	Returns:
#		The centre justified string
#
#	Caveats:
#		The returned string will be of length 80 - side effect of 4GL
#
#	R00 03may90		MoHo
#
################################################################################

FUNCTION gpx_CentreJustify(p_string, p_width)

DEFINE

	### Args ###
	p_string	CHAR(80),
	p_width		INTEGER,

	### Local ###
	p_result	CHAR(80),
	p_length	INTEGER,
	p_prefix	INTEGER,
	p_suffix	INTEGER


	INITIALIZE p_result TO NULL

	### Check width ###
	IF p_width < 1
	THEN
		RETURN p_result
	END IF

	### Check length of string ###
	LET p_length = LENGTH(p_string)
	IF p_length >= p_width
	THEN
		LET p_result[1,p_width] = p_string[1,p_width]
		RETURN p_result
	END IF

	### Check length of string ###
	LET p_length = LENGTH(p_string)
	IF p_length > p_width
	THEN
		RETURN p_string[1,p_width]
	END IF

	### Calculate prefix & suffix lengths ###
	LET p_suffix = ((p_width - p_length) / 2) - 1
	LET p_prefix = p_width - p_length - p_suffix

	### Format ###
	LET p_result[1,p_prefix]
		= "                                        "
	LET p_result[p_prefix,p_width-p_suffix] = p_string
	LET p_result[p_width-p_suffix,p_width]
		= "                                        "

	RETURN p_result

END FUNCTION




################################################################################
#
#	gpx_SplitString		Used to separate the "menu" part of a string from
#						the "command".
#
#	Synopsis:
#		gpx_SplitString(p_delimiter, p_string)
#
#	Where:
#		p_delimiter		Delimiter character
#		p_string		String to separate
#
#	R00 15jun90		MoHo
#
#	NOTE: Could be written better, though time is of the essence.
#
################################################################################

FUNCTION gpx_SplitString(p_delimiter, p_string)

	DEFINE
		### Args ###
		p_delimiter	CHAR(1),
		p_string	CHAR(80),

		### Local ###
		p_match1	CHAR(3),
		p_match2	CHAR(2),
		p_match3	CHAR(2),
		p_length	INTEGER,
		idx			INTEGER


	### Exclusions; check boundaries - lazy but sure ###
	LET p_match1 = "*", p_delimiter, "*"
	LET p_match2 = p_delimiter, "*"
	LET p_match3 = "*", p_delimiter
	LET p_length = LENGTH(p_string)
	CASE
	WHEN p_string NOT MATCHES p_match1
		RETURN p_string, ""
	WHEN p_string = p_delimiter
		RETURN "", ""
	WHEN p_string MATCHES p_match2
		RETURN "", p_string[2,p_length]
	WHEN p_string MATCHES p_match3
		RETURN p_string[1,p_length-1], ""
	END CASE

	### Locate separator ###
	FOR idx = 1 TO p_length
		IF p_string[idx] = p_delimiter
		THEN
			EXIT FOR
		END IF
	END FOR

	### Substring each portion ###
	RETURN p_string[1,idx-1], p_string[idx+1,p_length]

END FUNCTION





################################################################################
#
#	gpx_Clipped		Clip spaces from around a string
#					Spaces on both left and right are clipped.
#
#	Synopsis:
#		gpx_Clipped(p_string)
#
#	Where:
#		p_string		String to clip
#
#	R00 16jun90		MoHo
#
################################################################################

FUNCTION gpx_Clipped(p_string)

	DEFINE
		### Args ###
		p_string	CHAR(80),

		### Local ###
		p_length	INTEGER,
		idx			INTEGER


	LET p_length = LENGTH(p_string)
	FOR idx = 1 TO p_length
		IF p_string[idx] != " "
		THEN
			EXIT FOR
		END IF
	END FOR

	IF idx <= p_length
	THEN
		RETURN p_string[idx,p_length] CLIPPED
	ELSE
		RETURN ""
	END IF

END FUNCTION




################################################################################
#
#	gpx_PromptForAnyKey		Prompt for any key and return
#							This was written because there was no escaping
#							a PROMPT from an ON KEY without using the
#							dreaded (eeecccch!) G*TO.
#
#	Synopsis:
#		gpx_PromptForAnyKey(p_help)
#
#	Where:
#		p_help		Help number - though not currently used
#
#	R00 02jun90		MoHo
#	R01	28jul90		MoHo	Added provision for help
#
################################################################################

FUNCTION gpx_PromptForAnyKey(p_help)

	DEFINE
		### Args ###
		p_help		INTEGER,

		### Local ###
		p_keyput	CHAR(1)


	### R12:Begin ###
	LET p_keyput = gp_PromptKey()
	RETURN
	### R12:End ###

	OPTIONS ACCEPT KEY F36
	PROMPT "" FOR CHAR p_keyput
		### Standard ONKEYS here ###
		ON KEY(F1,F2,F3,F4,F5,F6,F7,F8,F9,INTERRUPT)
			OPTIONS ACCEPT KEY F1
			RETURN
	END PROMPT
	OPTIONS ACCEPT KEY F1

	RETURN

END FUNCTION




###############################################################################
#
#	gpx_OpenWindow		Opens window - returns window identifier
#						Informix can be real stupid at times
#						This gets around lack of indirection i.e.
#						windows are "rvalues" or constant references which
#						means we can't open windows recursively!
#						Furthermore, we can't generally pass attributes to
#						these windows either.
#
#	Synopsis:
#		gpx_OpenWindow(p_type, p_rowpos, p_colpos, p_rowsize, p_colsize)
#
#	Where:
#		p_type				Type of window - currently "DIALOG" or "MESSAGE"
#							DIALOG windows have borders, etc.
#							MESSAGE windows are borderless.
#		p_rowpos,p_colpos	Row & column of top left corner to place window
#		p_rowsize,p_colsize	Size in rows and columns of window
#							not including the border.
#
#	Returns:
#		pw_window	 - a window identifier or 0 on failure
#
#	R00	15may90		MoHo	Toyed with this idea
#	R01	11jun90		MoHo	Introduction into gp_dialog
#	R12	15aug96		MoHo	Added "form" type below for 4Js GUI
#							This was originally "MENU", but extended to allow
#							forms of p_typeRRCC to be used where RR is rowsize
#							and CC is colsize. IF RR and CC are zero, then
#							the form name p_type is used with RRCC appended.
#
#	Limitations:
#		Maximum number of windows open is limited to 12
#
###############################################################################

FUNCTION gpx_OpenWindow(p_type, p_rowpos, p_colpos, p_rowsize, p_colsize)

	DEFINE
		### Args ###
		p_type		CHAR(12),
		p_rowpos	INTEGER,
		p_colpos	INTEGER,
		p_rowsize	INTEGER,
		p_colsize	INTEGER,

		### Locals ###
		p_form		CHAR(12),											

		### Constants ###
		pc_maxwindow	INTEGER,

		### Local ###
		pw_window	INTEGER


	LET pc_maxwindow = 12


	### Search for free window identifier ###
	FOR pw_window = 1 TO pc_maxwindow
		IF sa_windowstat[pw_window] IS NULL
		THEN
			EXIT FOR
		END IF
	END FOR

	### R12: If MENU and GUI ... ###
	IF p_type != "MESSAGE" AND p_type != "DIALOG"
	THEN
		LET p_form = p_type
		IF p_rowsize > 0 OR p_colsize > 0
		THEN
			LET p_form = p_form CLIPPED,
				p_rowsize USING "&&", p_colsize USING "&&"
		END IF
		LET p_type = "FORM"
	END IF
		
	### Yuckeee code ###
	CASE
	WHEN p_type = "MESSAGE"
		EXIT CASE

	WHEN pw_window = 1
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window1 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window1 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window1 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 2
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window2 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window2 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window2 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 3
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window3 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window3 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window3 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 4
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window4 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window4 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window4 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 5
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window5 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window5 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window5 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 6
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window6 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window6 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window6 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 7
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window7 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window7 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window7 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 8
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window8 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window8 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window8 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 9
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window9 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window9 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window9 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 10
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window10 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window10 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window10 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 11
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window11 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window11 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window11 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	WHEN pw_window = 12
		CASE
		WHEN p_type = "DIALOG"
			OPEN WINDOW w__window12 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "MESSAGE"
			OPEN WINDOW w__window12 AT p_rowpos, p_colpos WITH p_rowsize ROWS, p_colsize COLUMNS
			ATTRIBUTE(STYLE="popup")
		WHEN p_type = "FORM"									
			OPEN WINDOW w__window12 AT p_rowpos, p_colpos WITH FORM p_form
			ATTRIBUTE(STYLE="popup")
		END CASE

	### Out of windows ###
	OTHERWISE
		ERROR _("gpx_OpenWindow: Out of windows")
		SLEEP 2
		RETURN 0
	END CASE

	### Set window status to active ###
	LET sa_windowstat[pw_window] = "A"
	RETURN pw_window

END FUNCTION



###############################################################################
#
#	gpx_CloseWindow		Counterpart to OpenWindow
#						Closes window an frees up the window descriptor
#
#	Synopsis:
#		gpx_CloseWindow(pw_window)
#
#	Where:
#		pw_window	window identifier returned by gpx_OpenWindow
#
#	R00	15may90		MoHo	Toyed with this idea
#	R01	11jun90		MoHo	Introduction into gp_dialog
#
###############################################################################

FUNCTION gpx_CloseWindow(pw_window)

	DEFINE
		### Args ###
		pw_window		INTEGER,

		### Constants ###
		pc_maxwindow	INTEGER,
		p_text			CHAR(80)

	
	LET pc_maxwindow = 12

	### Check window is in range ###
	IF pw_window < 1 OR pw_window > pc_maxwindow
	THEN
		LET p_text = "gpx_CloseWindow: ERROR: window id %1 is out of range"
		ERROR SFMT(_(p_text), pw_window)
		RETURN
	END IF

	### Check window is active ###
	IF sa_windowstat[pw_window] IS NULL
		OR sa_windowstat[pw_window] != "A"
	THEN
		ERROR _("gpx_CloseWindow: WARNING: window was not active")
		RETURN
	END IF

	### Proceed to close window (more yechee code) ###
	CASE
	WHEN pw_window = 1
		CLOSE WINDOW w__window1
	WHEN pw_window = 2
		CLOSE WINDOW w__window2
	WHEN pw_window = 3
		CLOSE WINDOW w__window3
	WHEN pw_window = 4
		CLOSE WINDOW w__window4
	WHEN pw_window = 5
		CLOSE WINDOW w__window5
	WHEN pw_window = 6
		CLOSE WINDOW w__window6
	WHEN pw_window = 7
		CLOSE WINDOW w__window7
	WHEN pw_window = 8
		CLOSE WINDOW w__window8
	WHEN pw_window = 9
		CLOSE WINDOW w__window9
	WHEN pw_window = 10
		CLOSE WINDOW w__window10
	WHEN pw_window = 11
		CLOSE WINDOW w__window11
	WHEN pw_window = 12
		CLOSE WINDOW w__window12
	END CASE

	### Set window status to in-active ###
	INITIALIZE sa_windowstat[pw_window] TO NULL
	RETURN

END FUNCTION




###############################################################################
#
#	gpx_CurrentWindow	Make this window current
#
#	Synopsis:
#		gpx_CurrentWindow(pw_window)
#
#	Where:
#		pw_window	is a window identifier returned by gpx_OpenWindow
#
#	R00	11jun90		MoHo	Required, as an afterthought
#
###############################################################################

FUNCTION gpx_CurrentWindow(pw_window)

	DEFINE
		### Args ###
		pw_window	INTEGER,

		### Constants ###
		pc_maxwindow	INTEGER,
		p_text		CHAR(80)

	
	LET pc_maxwindow = 12


	### Check window is in range ###
	IF pw_window < 1 OR pw_window > pc_maxwindow
	THEN
		LET p_text = "gpx_CurrentWindow: ERROR: window id %1 is out of range"
		ERROR SFMT(_(p_text), pw_window)
		RETURN
	END IF

	### Check window is active ###
	IF sa_windowstat[pw_window] IS NULL
		OR sa_windowstat[pw_window] != "A"
	THEN
		ERROR _("gpx_CloseWindow: WARNING: window was not active")
		RETURN
	END IF

	### Proceed to close window (more yechee code) ###
	CASE

	WHEN pw_window = 1
		CURRENT WINDOW IS w__window1
	WHEN pw_window = 2
		CURRENT WINDOW IS w__window2
	WHEN pw_window = 3
		CURRENT WINDOW IS w__window3
	WHEN pw_window = 4
		CURRENT WINDOW IS w__window4
	WHEN pw_window = 5
		CURRENT WINDOW IS w__window5
	WHEN pw_window = 6
		CURRENT WINDOW IS w__window6
	WHEN pw_window = 7
		CURRENT WINDOW IS w__window7
	WHEN pw_window = 8
		CURRENT WINDOW IS w__window8
	WHEN pw_window = 9
		CURRENT WINDOW IS w__window9
	WHEN pw_window = 10
		CURRENT WINDOW IS w__window10
	WHEN pw_window = 11
		CURRENT WINDOW IS w__window11
	WHEN pw_window = 12
		CURRENT WINDOW IS w__window12
	END CASE

	RETURN

END FUNCTION




###############################################################################
#
#	gpx_Heap	Heap operations
#				Some dynamic string management routines. 4GL is too static.
#				This allows strings to be packed and variable in length
#				(in terms of real storage). The access cost is minimal
#				- a single function call.
#
#	Synopsis:
#		gpx_Heap(p_request, p_idx, p_data)
#
#	Where:
#		p_request	Function - "ADD", "DELETE" or "CLEAR"
#		p_idx		When deleting, the data "pointer"
#		p_data		When adding, the data to be added
#
#	R00	15jun90		MoHo		To minimize resources when stacking menus
#								Each dialog uses at least 672 bytes. This
#								is far more space efficient.
#
#	Limitations:
#		The heap size is 4K. This should be "heaps" but can grow if required.
#		The number of allocatable string pointers is 64. This can also grow.
#		p_data length is maximum of 512 characters.
#
###############################################################################

FUNCTION gpx_Heap(p_request, p_idx, p_data)

	DEFINE
		### Args ###
		p_request		CHAR(8),
		p_idx			INTEGER,
		p_data			CHAR(512),

		### Constants ###
		pc_maxheapptr	INTEGER,
		pc_maxheap		INTEGER,

		### Local ###
		p_length		INTEGER,
		p_start			INTEGER,
		p_end			INTEGER,
		idx				INTEGER


	### Set "constants" ###
	LET pc_maxheap = 4096
	LET pc_maxheapptr = 64
	LET p_request = gp_upshift(p_request)

	### Request? ###
	CASE
	WHEN p_request = "ADD" OR p_request = "INSERT"
		LET p_length = LENGTH(p_data)

		### Any data? ###
		IF p_length < 1
		THEN
			RETURN 0
		END IF

		### Enough space left? ###
		IF s_heapsize + p_length > pc_maxheap
		THEN
			ERROR _("gpx_Heap: Out of heap space")
			SLEEP 2
			RETURN 0
		END IF

		### Search for free pointer ###
		FOR idx = 1 TO pc_maxheapptr
			IF NOT sa_heapptr[idx].p_active
			THEN
				EXIT FOR
			END IF
		END FOR
		IF idx > pc_maxheapptr
		THEN
			ERROR _("gpx_Heap: Out of heap pointers")
			SLEEP 2
			RETURN 0
		END IF

		### Assign some space ###
		LET s_heap = s_heap CLIPPED, p_data CLIPPED
		LET sa_heapptr[idx].p_active = TRUE
		LET sa_heapptr[idx].p_start = s_heapsize + 1
		LET sa_heapptr[idx].p_end
			= sa_heapptr[idx].p_start + p_length - 1
		LET s_heapsize = LENGTH(s_heap)
		RETURN idx

	WHEN p_request = "CLEAR"
		LET s_heap = ""
		LET s_heapsize = 0
		FOR idx = 1 TO pc_maxheapptr
			LET sa_heapptr[idx].p_active = FALSE
		END FOR
		RETURN 1

	WHEN p_request = "DELETE" or p_request = "DROP"
		### Check for valid index ###
		IF p_idx < 1 OR p_idx > pc_maxheapptr
		THEN
			RETURN 0
		END IF
		IF sa_heapptr[p_idx].p_active
		THEN
			LET p_start = sa_heapptr[p_idx].p_start
			LET p_end = sa_heapptr[p_idx].p_end
		ELSE
			RETURN 0
		END IF

		### Drop data chunk from heap ###
		CASE
		WHEN sa_heapptr[p_idx].p_start = 1
			LET s_heap = s_heap[p_end+1,s_heapsize+1] CLIPPED
		WHEN sa_heapptr[p_idx].p_end = s_heapsize
			LET s_heap = s_heap[1,p_start-1] CLIPPED
		OTHERWISE
			LET s_heap = s_heap[1,p_start-1] CLIPPED,
				s_heap[p_end+1,s_heapsize+1] CLIPPED
		END CASE
		LET p_length = p_end - p_start + 1
		LET s_heapsize = LENGTH(s_heap)

		### Re-pack heap ###
		LET sa_heapptr[p_idx].p_active = FALSE
		FOR idx = 1 TO pc_maxheapptr
			IF sa_heapptr[idx].p_active AND sa_heapptr[idx].p_start > p_end
			THEN
				LET sa_heapptr[idx].p_start = sa_heapptr[idx].p_start - p_length
				LET sa_heapptr[idx].p_end = sa_heapptr[idx].p_end - p_length
			END IF
		END FOR
		RETURN 1

	END CASE

	RETURN 0

END FUNCTION

###############################################################################
#
#	gpx_FetchData	Fetch previously stored data from heap.
#
#	Synopsis:
#		gpx_FetchData(p_idx)
#
#	Where:
#		p_idx		the data "pointer" returned from Heap "add" function
#
#	Returns:
#		Variable length data from heap
#
#	R00	15jun90		MoHo		To minimize resources when stacking menus
#
###############################################################################

FUNCTION gpx_FetchData(p_idx)

	DEFINE
		### Args ###
		p_idx			INTEGER,

		### Constants ###
		pc_maxheapptr	INTEGER,

		### Local ###
		p_start			INTEGER,
		p_end			INTEGER


	### Set "constants" ###
	LET pc_maxheapptr = 64

	### Check for valid index ###
	IF p_idx < 1 OR p_idx > pc_maxheapptr
	THEN
		RETURN ""
	END IF
	IF NOT sa_heapptr[p_idx].p_active
	THEN
		RETURN ""
	END IF

	### Fetch data and return ###
	LET p_start = sa_heapptr[p_idx].p_start
	LET p_end = sa_heapptr[p_idx].p_end

	RETURN s_heap[p_start,p_end] CLIPPED

END FUNCTION
################################################################################
# @@@@( gpx_FetchData )@@@@
###############################################################################
#
#	gp_dberr	report on a IO error in a dialog box
#
#	This function put here to minimise the number of syspgm's that have
#	to be updated
#
#	R01	23Apr92	lai		modify function to return TRUE if p_sqlstatus = 0
#						FALSE otherwise
#
FUNCTION gp_dberr(p_table, p_sqlstatus, p_isamstatus)

	DEFINE
		p_table			CHAR(20),
		p_sqlstatus		INTEGER,
		p_isamstatus	INTEGER,
		p_length		INTEGER,
		p_sqlcaerrm		CHAR(80),
		p_sqlerrm		CHAR(200),
		p_option		CHAR(20),
		p_sqlerr		CHAR(200),
		p_string		CHAR(80),											
		p_isamerr		CHAR(200),
		p_msg			CHAR(400)

	LET p_sqlcaerrm = SQLCA.SQLERRM
	LET p_sqlerrm = SQLERRMESSAGE

	IF p_sqlstatus = 0 THEN													
		IF g_background != "Y" THEN
			MESSAGE ""				
		END IF
		LET s_count = 0														
		RETURN TRUE															
	END IF																	

	### W02 begins ###
	IF NOT s_once THEN
		SELECT	cf_value
		INTO	p_string
		FROM	ut_config
		WHERE	cf_key = "UTRETRY"
		IF status = NOTFOUND THEN
			LET s_retry = 10		#default 10 times
		ELSE
			WHENEVER ERROR CONTINUE
			LET s_retry = p_string
			IF status != 0 THEN
				LET status = 0
				LET s_retry = 0
			END IF
			WHENEVER ERROR STOP
		END IF
	END IF
	IF NOT db_sperrcode(p_sqlstatus) THEN
		IF s_retry != 0 AND s_count != s_retry THEN
			IF s_count = 3 THEN												
				MESSAGE SFMT(_("table: '%1' is in use. please wait . . ."), 
							p_table CLIPPED)
			END IF
			LET s_count = s_count + 1
			SLEEP 1
			RETURN FALSE
		END IF
	END IF																	
	IF p_sqlcaerrm IS NULL THEN
		LET p_sqlerr = p_sqlcaerrm
	ELSE
		LET p_sqlerr = err_get(p_sqlstatus)
	END IF															

	CASE
	WHEN db_Env() MATCHES "IFX*"
		LET p_isamerr = err_get(p_isamstatus)
	WHEN db_Env() = "ORACLE"
		LET p_isamerr = gp_dbErrMsg(p_isamstatus)
	WHEN db_Env() = "MSSQL"
		# remove first 47 characters as it contains
		# [Microsoft][ODBC SQL Server Driver][SQL Server]
		LET p_length = LENGTH(p_sqlerrm)
		LET p_isamerr = p_sqlerrm[48, p_length]
	END CASE

	LET p_msg =
	"gp_dberr: database error on table '", p_table CLIPPED, "'.", ASCII 10,
	"SQL error ", p_sqlstatus USING "-<<<&",".", p_sqlerr CLIPPED,ASCII 10,
	"ISAM error ", p_isamstatus USING "-<<<<&" ,".", p_isamerr CLIPPED, ASCII 10

	CALL ERRORLOG(p_msg)

	# truncate long SQL error msgs

	LET p_sqlerr = p_sqlerr[1,75]									
	LET p_isamerr = p_isamerr[1,75]									

	IF g_background != "Y" THEN
		# if error is a user defined code (i.e. from stored procedure) just
		# return back to program, do not quit program
		IF NOT db_sperrcode(p_sqlstatus) THEN
			LET p_msg =
				"|A database error has occurred on table '%1'.|",
				"SQL error %2.|%3|ISAM error %4.|%5|",
				"|You can choose to retry the operation or abandon it.",
				"|If you abandon the data will need to be re-entered.|"
			
			LET p_msg = SFMT(_(p_msg), p_table CLIPPED,
							 p_sqlstatus USING "-<<<&",
					 		 _(p_sqlerr) CLIPPED,
							 p_isamstatus USING "-<<<<&",
				     		 _(p_isamerr) CLIPPED)

			LET p_option =  
				gp_dialog( "DATABASE ERROR", p_msg,
						"Retry operation ?", "yes!", 0, 0, 3900)
		ELSE
			LET p_msg =
				"|A database error has occurred on table '%1'.|",
				"SQL error %2.|%3|ISAM error %4.|%5|"
	
			LET p_msg = SFMT(_(p_msg), p_table CLIPPED, 
							 p_sqlstatus USING "-<<<&",
					 		 _(p_sqlerr) CLIPPED, p_isamstatus USING "-<<<<&",
				     		 _(p_isamerr) CLIPPED)

			LET p_option =  
				gp_dialog( "DATABASE ERROR", p_msg,
						"Press any key to continue", "any!", 0, 0, 3900)
			RETURN TRUE
		END IF
	ELSE
		CALL err_log(p_msg)
	    LET p_option = "NO"
	END IF
	
	CASE
	WHEN p_option = "NO"
		WHENEVER ERROR CONTINUE
		IF g_dbtrans THEN
			 CALL db_Work("ROLLBACK")
		END IF
		IF g_rlockid IS NOT NULL THEN		 ## free any resource locks ## 
			DELETE FROM ut_config
			WHERE  cf_key = g_rlockid
		END IF
		WHENEVER ERROR STOP
		EXIT PROGRAM(0)
	END CASE
	LET s_count = 0															

	RETURN FALSE															

END FUNCTION
################################################################################
# @@@@( gp_dberr )@@@@

###############################################################################
#	gp_version	display version advice information
#
#	This function put here to minimise the number of syspgm's that have
#	to be updated
#
#	R00	27jan93	fox		initial release
#
#FUNCTION gp_version()

	#CALL gp_about()
#
	#RETURN


#END FUNCTION
################################################################################
# @@@@( gp_version )@@@@

###############################################################################
#
#	gp_about	can be used to display version, configuration & credits information
#
#
FUNCTION gp_about()

	DEFINE
	p_title		CHAR(30)									

	LET p_title = "About ", g_pgm CLIPPED							

	# reset int_flag to FALSE, this way if calling program is within a
	# construct / input statement program doesn't exit input entry
	# when user cancel's out of dialog.
	LET int_flag = FALSE

END FUNCTION
################################################################################
# @@@@( gp_about )@@@@


################################################################################
#
#	gpx_GUIdialog	4Js Extension for GUI Dialog Box
#					Note that this is not a precise translation of the
#					standard 4GL version. It does not have:
#						a)	Ability to specify ROW and COLUMN (is centred)
#						b)	Prompt text
#						c)	Help
#					but on the other hand does have an icon.
#					The default icons to be used are:
#						Question Icon for Yes/No dialogs
#						Info Icon for Any dialogs.
#					Extensions for Any Dialogs are:
#						Severity level indicated by:
#							"!"		Exclamation Icon (BELL in std vers)
#							"."		Stop Icon
#							"?"		Question Icon
#
#	Synopsis:
#
#		gpx_GUIdialog(p_title, p_message, p_mode)
#
#	Where:
#
#		p_title		Title in dialog box
#		p_message	Text of message, using "|" delimiters for new lines
#		p_prompt	User prompt
#		p_mode		Same as for gp_Dialog now with above embellishments
#
#	R00 15aug96	MoHo
#
################################################################################

FUNCTION gpx_GUIdialog(p_title, p_message, p_prompt, p_mode)

	DEFINE

		### Args ###
		p_title			CHAR(80),
		p_message		CHAR(512),
		p_prompt		CHAR(80),
		p_mode			CHAR(8),

		### Constants ###
		pc_delimiter	CHAR(1),
		pc_newline		CHAR(1),

		### Locals ###
		p_string		CHAR(512),
		p_stitle		CHAR(30),
		p_response		CHAR(80),
		p_icon			CHAR(12),
		p_default		CHAR(12),										
		p_lcldefault	CHAR(12),										
		p_buttons		CHAR(40),										
		p_length		INTEGER,
		p_idx			INTEGER,
		p_jdx			INTEGER,

	    p_buttonArray   DYNAMIC ARRAY OF RECORD
            original     STRING,
            localised    STRING
        END RECORD

	### Define delimiters ###
	LET pc_delimiter = "|"
	LET pc_newline = ASCII 10	# Carriage Return #
	
    LET p_message = _(p_message)
    LET p_prompt = _(p_prompt)
    LET p_title = _(p_title)

    CALL p_buttonArray.clear()

	### 4JsBug - Replace delimiters with newlines "\n" ###
	LET p_length = LENGTH(p_message)
	FOR p_idx = 1 TO p_length
		IF p_message[p_idx] = pc_delimiter
		THEN
			LET p_string[p_idx] = pc_newline
		ELSE
			LET p_string[p_idx] = p_message[p_idx]
		END IF
	END FOR
	LET p_message = p_string CLIPPED

	### Add prompt ###
	IF p_prompt != "default"
	THEN
		LET p_message = p_message CLIPPED, pc_newline, p_prompt CLIPPED
	END IF

	### Set Title ###
	LET p_stitle = p_title[1,30] CLIPPED

	### Set default Icon ###
	IF p_mode MATCHES "[Aa]*"
	THEN
		LET p_icon = "info"
	ELSE
		LET p_icon = "question"
	END IF

	### Any Specific Icon required? ###
	CASE
	WHEN p_mode MATCHES "*!*"
		LET p_icon = "exclamation"
	WHEN p_mode MATCHES "*.*"
		LET p_icon = "stop"
	WHEN stridx(p_mode, "?") > 0
		LET p_icon = "question"
	END CASE

	### Determine type of dialogue ###
	CASE
	WHEN p_mode MATCHES "[Yy]*"
        LET p_buttonArray[1].original = "Yes"
        LET p_buttonArray[1].localised = "Yes"
        LET p_buttonArray[2].original = "No"
        LET p_buttonArray[2].localised = "No"

		LET p_default = p_buttonArray[1].original
		LET p_lcldefault = p_buttonArray[1].localised
		LET p_buttons = p_buttonArray[1].localised CLIPPED, "|",
                        p_buttonArray[2].localised CLIPPED

	WHEN p_mode MATCHES "[Nn]*"
        LET p_buttonArray[1].original = "Yes"
        LET p_buttonArray[1].localised = "Yes"
        LET p_buttonArray[2].original = "No"
        LET p_buttonArray[2].localised = "No"

		LET p_default = p_buttonArray[2].original
		LET p_lcldefault = p_buttonArray[2].localised
		LET p_buttons = p_buttonArray[1].localised CLIPPED, "|",
                        p_buttonArray[2].localised

	WHEN p_mode MATCHES "[Rr]*"
        LET p_buttonArray[1].original = "Hold"
        LET p_buttonArray[1].localised = _("Hold")
        LET p_buttonArray[2].original = "Ready"
        LET p_buttonArray[2].localised = _("Ready")

		LET p_default = p_buttonArray[1].localised
		LET p_lcldefault = p_buttonArray[1].localised
		LET p_buttons = p_buttonArray[2].localised CLIPPED, "|",
                        p_buttonArray[1].localised

	WHEN p_mode MATCHES "[Uu]*"
        LET p_buttonArray[1].original = "Hold"
        LET p_buttonArray[1].localised = _("Hold")
        LET p_buttonArray[2].original = "Update"
        LET p_buttonArray[2].localised = _("Update")

		LET p_default = p_buttonArray[1].localised
		LET p_lcldefault = p_buttonArray[1].localised
		LET p_buttons = p_buttonArray[2].original CLIPPED, "|",
                        p_buttonArray[1].original
		
	WHEN p_mode MATCHES "[Pp]*"
        LET p_buttonArray[1].original = "Proceed"
        LET p_buttonArray[1].localised = _("Proceed")
        LET p_buttonArray[2].original = "Update"
        LET p_buttonArray[2].localised = _("Update")

		LET p_default = p_buttonArray[1].localised
		LET p_lcldefault = p_buttonArray[1].localised
		LET p_buttons = p_buttonArray[1].localised CLIPPED, "|",
                        p_buttonArray[2].localised
		
	OTHERWISE
		LET p_response = ""

		### R20:Begins ###
		LET p_lcldefault = "OK"
		LET p_default = "OK"
		LET p_buttons = "OK"
		### R20:Ends ###

	END CASE


	### R20:Begins - call common dialog routine ###
	LET p_response = gpx_WinDialog(p_title, p_message,
		p_buttons, p_default, p_icon)
	### R20:Ends ###

    FOR p_idx = 1 TO p_buttonArray.getLength()
        IF p_buttonArray[p_idx].localised = p_response THEN
            LET p_response = p_buttonArray[p_idx].original
            EXIT FOR
        END IF
    END FOR

	RETURN UPSHIFT(p_response) CLIPPED

END FUNCTION




################################################################################
#
#	gpx_GUImenu		GUI version of Menu
#
#	R00 15aug96		MoHo
#
################################################################################

FUNCTION gpx_GUImenu(p_title, p_width, pa_dialog, pa_command, p_items, p_help)

	DEFINE
		p_Title			CHAR(80),
		p_Width			INTEGER,
		pa_Dialog 		ARRAY[16] OF CHAR(80),
		pa_Command		ARRAY[16] OF CHAR(20),
		p_Items			INTEGER,
		p_Help			INTEGER,

		pa_Label 		ARRAY[16] OF CHAR(40),
		p_Form		RECORD
						p_Button01	CHAR(40),
						p_Button02	CHAR(40),
						p_Button03	CHAR(40),
						p_Button04	CHAR(40),
						p_Button05	CHAR(40),
						p_Button06	CHAR(40),
						p_Button07	CHAR(40),
						p_Button08	CHAR(40),
						p_Button09	CHAR(40),
						p_Button10	CHAR(40),
						p_Button11	CHAR(40),
						p_Button12	CHAR(40),
						p_Button13	CHAR(40),
						p_Button14	CHAR(40),
						p_Button15	CHAR(40),
						p_Button16	CHAR(40)
					END RECORD,
		p_Request	CHAR(10),
		p_Vector	CHAR(1),
		p_Cancel	CHAR(1),											
		p_Current	INTEGER,
		p_Idx		INTEGER,
		p_Row		INTEGER,
		p_Col		INTEGER,
		p_Option	CHAR(80),
		p_Char		CHAR(1),
		p_Spaces	CHAR(80),
		p_Message	CHAR(80)



	INITIALIZE p_Option TO NULL

	### Initialize all buttons ###
 #There was a problem under MDI of disabled buttons showing F'n key labels
	LET p_Form.p_Button01 = "*"
	LET p_Form.p_Button02 = "*"
	LET p_Form.p_Button03 = "*"
	LET p_Form.p_Button04 = "*"
	LET p_Form.p_Button05 = "*"
	LET p_Form.p_Button06 = "*"
	LET p_Form.p_Button07 = "*"
	LET p_Form.p_Button08 = "*"
	LET p_Form.p_Button09 = "*"
	LET p_Form.p_Button10 = "*"
	LET p_Form.p_Button11 = "*"
	LET p_Form.p_Button12 = "*"
	LET p_Form.p_Button13 = "*"
	LET p_Form.p_Button14 = "*"
	LET p_Form.p_Button15 = "*"
	LET p_Form.p_Button16 = "*"

	### Display buttons (% and possibly bitmaps in future) ###
	CASE p_Items
	WHEN 1
		DISPLAY BY NAME p_Form.p_Button01
	WHEN 2
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button02
	WHEN 3
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button03
	WHEN 4
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button04
	WHEN 5
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button05
	WHEN 6
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button06
	WHEN 7
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button07
	WHEN 8
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button08
	WHEN 9
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button09
	WHEN 10
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button10
	WHEN 11
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button11
	WHEN 12
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button12
	WHEN 13
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button13
	WHEN 14
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button14
	WHEN 15
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button15
	WHEN 16
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button16
	END CASE


	#%% Process labels and match strings ###
	FOR p_Idx = 1 TO p_Items
		IF pa_Dialog[p_Idx] IS NOT NULL OR LENGTH(pa_Dialog[p_Idx]) > 0
		THEN
			### R15:Begins ###
			IF g_underscore
			THEN
				LET pa_Label[p_Idx] = "&", _(pa_Dialog[p_Idx])
			ELSE
				LET pa_Label[p_Idx] = _(pa_Dialog[p_Idx])
			END IF
			### R15:Ends ###

			### R18:Begins - Indicate if more behind this option ###
			IF pa_Command[p_Idx] IS NOT NULL
			THEN
				LET pa_Label[p_Idx] = pa_Label[p_Idx] CLIPPED, " ..."
			END IF
			### R18:Ends ###
		END IF
	END FOR

	### Transfer descriptions to buttons ###
	LET p_Form.p_Button01 = pa_Label[1]
	LET p_Form.p_Button02 = pa_Label[2]
	LET p_Form.p_Button03 = pa_Label[3]
	LET p_Form.p_Button04 = pa_Label[4]
	LET p_Form.p_Button05 = pa_Label[5]
	LET p_Form.p_Button06 = pa_Label[6]
	LET p_Form.p_Button07 = pa_Label[7]
	LET p_Form.p_Button08 = pa_Label[8]
	LET p_Form.p_Button09 = pa_Label[9]
	LET p_Form.p_Button10 = pa_Label[10]
	LET p_Form.p_Button11 = pa_Label[11]
	LET p_Form.p_Button12 = pa_Label[12]
	LET p_Form.p_Button13 = pa_Label[13]
	LET p_Form.p_Button14 = pa_Label[14]
	LET p_Form.p_Button15 = pa_Label[15]
	LET p_Form.p_Button16 = pa_Label[16]


	### Display title ###
	LET p_Title = gpx_CentreJustify(p_Title, p_Width+3)
	DISPLAY _(p_Title[1, p_Width+3])
		AT 1,1  

	LET p_Cancel = "X"													
	DISPLAY BY NAME p_Cancel											

	### Display buttons (% and possibly bitmaps in future) ###
	CASE p_Items
	WHEN 1
		DISPLAY BY NAME p_Form.p_Button01
	WHEN 2
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button02
	WHEN 3
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button03
	WHEN 4
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button04
	WHEN 5
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button05
	WHEN 6
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button06
	WHEN 7
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button07
	WHEN 8
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button08
	WHEN 9
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button09
	WHEN 10
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button10
	WHEN 11
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button11
	WHEN 12
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button12
	WHEN 13
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button13
	WHEN 14
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button14
	WHEN 15
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button15
	WHEN 16
		DISPLAY BY NAME p_Form.p_Button01 THRU p_Form.p_Button16
	END CASE


	OPTIONS
		ACCEPT KEY F36


	LET p_Current = 1
	INPUT BY NAME p_Cancel												
 WITHOUT DEFAULTS													
		ATTRIBUTE(INVISIBLE)
		HELP 1000

		ON KEY (F1, ACCEPT, RETURN)

			IF pa_Dialog[p_Current] != " "
			THEN
				LET p_Option = gpx_FindItem(pa_Dialog[p_Current],
					pa_Dialog, pa_Command, p_Items)
			END IF

			IF p_Option IS NOT NULL THEN
				EXIT INPUT
			END IF


		ON KEY (F4, INTERRUPT, ESCAPE)
			EXIT INPUT

		ON KEY (F10)
			CALL ShowHelp(p_Help)

		ON KEY (
			"1","2","3","4","5","6","7","8","9","0",
			"A","B","C","D","E","F","G","H","I","J","K","L","M",
			"N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
			"a","b","c","d","e","f","g","h","i","j","k","l","m",
			"n","o","p","q","r","s","t","u","v","w","x","y","z")
			LET p_Char = ASCII fgl_lastkey()
			LET p_Option = gpx_FindItem(p_Char,
				pa_Dialog, pa_Command, p_Items)

			IF p_Option IS NOT NULL THEN
				EXIT INPUT
			END IF

		ON KEY (
			F11,F12,F13,F14,F15,F16,F17,F18,F19,F20,
			F21,F22,F23,F24,F25,F26,F27,F28,F29,F30)

			LET p_Idx = fgl_lastkey() - 3009
			IF pa_Dialog[p_Idx] != " "
			THEN
				LET p_Option = gpx_FindItem(pa_Dialog[p_Idx],
					pa_Dialog, pa_Command, p_Items)
			END IF

			IF p_Option IS NOT NULL THEN
				EXIT INPUT
			END IF


		ON KEY (UP, LEFT)
			LET p_Current = gpx_NextItem("UP", p_Current, pa_Dialog, p_Items)

		ON KEY (DOWN, RIGHT, TAB)
			LET p_Current = gpx_NextItem("DOWN", p_Current, pa_Dialog, p_Items)


		ON KEY (CONTROL-B)
			OPTIONS ACCEPT KEY F1
			CALL gp_version()
			OPTIONS ACCEPT KEY F36

		ON KEY (CONTROL-T)
			#% User help for menu?
			ERROR _("No user help defined.")

	END INPUT

	OPTIONS
		ACCEPT KEY F1


	RETURN p_Option

END FUNCTION




################################################################################
#
#	gpx_FindItem	Find and item from an array matching first char
#
#	R00 15aug96		MoHo
#
################################################################################

FUNCTION gpx_FindItem(p_option, pa_dialog, pa_command, p_items)

	DEFINE
		p_option	CHAR(80),
		pa_dialog 	ARRAY[16] OF CHAR(80),
		pa_command	ARRAY[16] OF CHAR(20),
		p_items		INTEGER,

		p_return	CHAR(80),
		p_length	INTEGER,
		p_idx		INTEGER


	LET p_length = LENGTH(p_option)

	FOR p_idx = 1 TO p_items

		#
		#	If single char - match first char in any case
		#	OR match whole string longer than one char
		#
		IF p_length = 1 AND UPSHIFT(p_option) = UPSHIFT(pa_dialog[p_idx][1,1])
			OR p_option = pa_dialog[p_idx]
		THEN
			### Any associated command? ###
			IF pa_command[p_idx] IS NULL
			THEN
				RETURN pa_dialog[p_idx] CLIPPED
			ELSE
				#### Call next dialog ###
				LET p_option = gp_ExecBox("RUN", pa_command[p_idx])
				IF p_option IS NOT NULL
				THEN
					LET p_return = pa_dialog[p_idx] CLIPPED,
						"|", p_option CLIPPED
					RETURN p_return CLIPPED
				END IF
			END IF
		END IF

	END FOR

	RETURN NULL

END FUNCTION






################################################################################
#
#	gpx_NextItem	Find next item in array which is not null
#
#	R00 30sep96		MoHo
#
################################################################################

FUNCTION gpx_NextItem(p_Dir, p_Current, pa_Dialog, p_Items)

	DEFINE
		p_Dir		CHAR(4),
		p_Current	INTEGER,
		pa_Dialog 	ARRAY[16] OF CHAR(80),
		p_Items		INTEGER,

		p_Next		INTEGER,
		p_Row		INTEGER,
		p_Inc		INTEGER,
		p_Idx		INTEGER


	### Which direction? ###
	IF UPSHIFT(p_Dir) = "DOWN"
	THEN
		LET p_Inc = 1
	ELSE
		LET p_Inc = -1
	END IF


	### Clear current selection ###
	LET p_Row = p_Current + 2
	DISPLAY "" AT p_Row, 1

	### Ensure we don't go forever ###
	LET p_Next = p_Current
	FOR p_Idx = 1 TO p_Items

		### Assign next ###
		LET p_Next = p_Next + p_Inc

		### Edges ###
		IF p_Next > p_Items
		THEN
			LET p_Next = 1
		END IF
		IF p_Next < 1
		THEN
			LET p_Next = p_Items
		END IF

		### If OK, then exit ###
		IF pa_Dialog[p_Next] IS NOT NULL
		THEN
			LET p_Row = p_Next + 2
			DISPLAY " " AT p_Row, 1 ATTRIBUTE(REVERSE, RED)
			RETURN p_Next
		END IF

	END FOR


	### All else fails, return original current ###
	LET p_Row = p_Current + 2
	DISPLAY " " AT p_Row, 1 ATTRIBUTE(REVERSE, RED)
	RETURN p_Current

END FUNCTION





################################################################################
#
#	gpx_WebMenu		Web safe version of Menu for HTML/Java
#
#	R19 18jan00		MoHo	Introduced
#
################################################################################

FUNCTION gpx_WebMenu(p_title, p_width, pa_dialog, pa_command, p_items, p_help)

	DEFINE
		p_Title			CHAR(80),
		p_Width			INTEGER,
		pa_Dialog 		ARRAY[16] OF CHAR(80),
		pa_Command		ARRAY[16] OF CHAR(20),
		p_Items			INTEGER,
		p_Help			INTEGER,

		p_Menu			CHAR(80),
		pa_Label 		ARRAY[16] OF CHAR(40),
		pa_Comment 		ARRAY[16] OF CHAR(40),
		p_Idx		INTEGER,
		p_style		STRING,
		p_Option	CHAR(80)



	INITIALIZE p_Option TO NULL


	### Process labels and match strings ###
	FOR p_Idx = 1 TO p_Items
	    ### Suppress Quit ###
   		IF UPSHIFT(pa_Dialog[p_Idx]) = "QUIT"
	    THEN
 			IF g_GUIfename != "GWC"
			THEN
         		LET pa_Dialog[p_Idx] = ""
			ELSE
				LET pa_Dialog[p_Idx] = "Cancel" # Since quit gets hidden
			END IF
	     END IF
		IF pa_Dialog[p_Idx] IS NOT NULL OR LENGTH(pa_Dialog[p_Idx]) > 0
		THEN
			LET pa_Label[p_Idx] = _(pa_Dialog[p_Idx])
			LET pa_Comment[p_Idx] = _(p_Title CLIPPED), " ", _(pa_Dialog[p_Idx])

			### More options behind this one? ###
			IF pa_Command[p_Idx] IS NOT NULL
			THEN
				LET pa_Label[p_Idx] = pa_Label[p_Idx] CLIPPED, " ..."
			END IF
		END IF
	END FOR

	### Menu name ###
	IF g_GUIclient = "JAVA"
	THEN
		LET p_Menu = UPSHIFT(p_Title)
	ELSE
		LET p_Menu = p_Title CLIPPED, ":"
	END IF

    IF g_GUIfename != "GWC"
    THEN
        LET p_style = "popup"
    ELSE
        LET p_style = "menu"
    END IF

	MENU p_Menu ATTRIBUTE(STYLE = p_style)

		BEFORE MENU

			### Hide blank items ###
			HIDE OPTION ALL
			FOR p_Idx = 1 TO p_Items
				IF LENGTH(pa_Dialog[p_Idx])
				THEN
					SHOW OPTION pa_Label[p_Idx]
				END IF
			END FOR

		COMMAND pa_Label[ 1] pa_Comment[ 1] HELP p_help
			LET p_Option = pa_Dialog[ 1]
			EXIT MENU

		COMMAND pa_Label[ 2] pa_Comment[ 2] HELP p_help
			LET p_Option = pa_Dialog[ 2]
			EXIT MENU

		COMMAND pa_Label[ 3] pa_Comment[ 3] HELP p_help
			LET p_Option = pa_Dialog[ 3]
			EXIT MENU

		COMMAND pa_Label[ 4] pa_Comment[ 4] HELP p_help
			LET p_Option = pa_Dialog[ 4]
			EXIT MENU

		COMMAND pa_Label[ 5] pa_Comment[ 5] HELP p_help
			LET p_Option = pa_Dialog[ 5]
			EXIT MENU

		COMMAND pa_Label[ 6] pa_Comment[ 6] HELP p_help
			LET p_Option = pa_Dialog[ 6]
			EXIT MENU

		COMMAND pa_Label[ 7] pa_Comment[ 7] HELP p_help
			LET p_Option = pa_Dialog[ 7]
			EXIT MENU

		COMMAND pa_Label[ 8] pa_Comment[ 8] HELP p_help
			LET p_Option = pa_Dialog[ 8]
			EXIT MENU

		COMMAND pa_Label[ 9] pa_Comment[ 9] HELP p_help
			LET p_Option = pa_Dialog[ 9]
			EXIT MENU

		COMMAND pa_Label[10] pa_Comment[10] HELP p_help
			LET p_Option = pa_Dialog[10]
			EXIT MENU

		COMMAND pa_Label[11] pa_Comment[11] HELP p_help
			LET p_Option = pa_Dialog[11]
			EXIT MENU

		COMMAND pa_Label[12] pa_Comment[12] HELP p_help
			LET p_Option = pa_Dialog[12]
			EXIT MENU

		COMMAND pa_Label[13] pa_Comment[13] HELP p_help
			LET p_Option = pa_Dialog[13]
			EXIT MENU

		COMMAND pa_Label[14] pa_Comment[14] HELP p_help
			LET p_Option = pa_Dialog[14]
			EXIT MENU

		COMMAND pa_Label[15] pa_Comment[15] HELP p_help
			LET p_Option = pa_Dialog[15]
			EXIT MENU

		COMMAND pa_Label[16] pa_Comment[16] HELP p_help
			LET p_Option = pa_Dialog[16]
			EXIT MENU


		COMMAND KEY (F4, INTERRUPT, ESCAPE)
			EXIT MENU

	END MENU


	RETURN gpx_FindItem(p_Option, pa_Dialog, pa_Command, p_Items) CLIPPED

END FUNCTION





################################################################################
#
#	gpx_WinQuestion	Call question dialog box
#
#	R20 14sep00		MoHo
#
################################################################################

FUNCTION gpx_WinDialog(p_title, p_message, p_buttons, p_default, p_icon)

	DEFINE
		p_title			CHAR(80),
		p_message		CHAR(512),
		p_buttons		CHAR(512),
		p_default		CHAR(40),
		p_icon			CHAR(12),

		p_mode			CHAR(40),
		p_response		CHAR(80)


	LET p_mode = DOWNSHIFT(p_default)
	CASE
	WHEN p_mode MATCHES "[yn]*"
		IF s_dialogLocal
		THEN
			--#	LET p_response = fgl_winbutton(p_title, p_message, p_default,
			--#		p_buttons, p_icon, 0)
		ELSE
			--#	LET p_response = fgl_winquestion(p_title, p_message, p_default,
			--#		p_buttons, p_icon, 0)
		END IF

	WHEN DOWNSHIFT(p_buttons) MATCHES "ok"
		IF s_dialogLocal
		THEN
			--#	LET p_response = fgl_winbutton(p_title, p_message, "OK",
			--#		"OK", p_icon, 0)
		ELSE
			--#	CALL fgl_winmessage(p_title, p_message, p_icon)
		END IF

	OTHERWISE
		--#	LET p_response = fgl_winbutton(p_title, p_message, p_default,
		--#		p_buttons, p_icon, 0)

	END CASE


	RETURN p_response

END FUNCTION





################################################################################
#
#!	gp_ResourceGet	Get fglprofile resource value
#
#	R20 14sep00	MoHo	%%% Relocate to lib_gen from A53
#	R21 18sep00 ast		Temp fix - cannot do fgl_getresource() in 4js ver 2.x,
#						use env var GPDIALOGLOCAL instead. Exclude this 
#						revision with 4js 3.x and set up ~/etc/fgldefaults.
#
################################################################################

FUNCTION gp_ResourceGet(p_resource)

	DEFINE
		p_resource	CHAR(80),
		p_value		CHAR(500),
		p_message	CHAR(200),					
		p_temp		CHAR(20)					

	## fgl_getresource() not available in 4js 2.x	
	## should uncomment this for version 3.x	
	#LET p_value = fglgetresource(p_resource)
	#RETURN p_value

	## comment following R21 mod out for 4js ver 3.x and set				
	## up ~/etc/fgldefaults instead of env var GPDIALOGLOCAL			
	LET p_message = ",", fgl_getenv("GPDIALOGLOCAL") CLIPPED, ","	
	LET p_temp = "*,", g_pgm CLIPPED, ",*"
	IF p_message MATCHES p_temp THEN
		LET p_value = "1"
	ELSE
		LET p_value = "0"
	END IF

	RETURN p_value

END FUNCTION

#
#	FUNCTION gp_dbErrMsg	- Decodes error message code into a logical message
#
FUNCTION gp_dbErrMsg(p_errcode)
	DEFINE
		p_errcode	INTEGER,
		p_msgtext	CHAR(1024)

		CASE
		WHEN db_Env() = "ORACLE"
			# define each of the error messages here. Error code is defined 
			# in exception's returned parameter, which must have a range 
			# -20000 ~ -20999
			CASE
			WHEN p_errcode = -20000
				LET p_msgtext = "No supplier exist in supplier table"
			WHEN p_errcode = -20001
				LET p_msgtext = "Records in ap_reqalloc still being referenced"
			WHEN p_errcode = -20002
				LET p_msgtext = "No customer exist in customer table"
			WHEN p_errcode = -20003
				LET p_msgtext = "Records in ar_reqalloc still being referenced"
			WHEN p_errcode = -2005
				LET p_msgtext = "Records in pc_dist still being referenced"
			WHEN p_errcode = -20004
				LET p_msgtext = "Records in gl_dist still being referenced"
			WHEN p_errcode = -20010
				LET p_msgtext = "CSE 0001: More than 1 company exists in ",
								"supplier table"
			WHEN p_errcode = -20012
				LET p_msgtext = "CSE 0002: More than 1 company exists in ",
								"customer table"
			WHEN p_errcode = -20013
				LET p_msgtext = "CSE 0003: More than 1 currency exists in ",
								"GL account table"
			WHEN p_errcode = -20014
				LET p_msgtext = "CSE 0004: More than 1 currency exists in ",
								"GL account table"
			WHEN p_errcode = -20015
				LET p_msgtext = "CSE 0005: UTMULTICOMPANY already set to yes "
			WHEN p_errcode = -20016
				LET p_msgtext = "CSE 0006: UTMULTIUNIT already set to yes "
			WHEN p_errcode = -20100
				LET p_msgtext = "CSE 1000: GL distributions missing.",
								"|See error log for more details."
			WHEN p_errcode = -20200
				LET p_msgtext = "CSE 2000: Company not in AP company table.",
								"|See error log for more details."
			WHEN p_errcode = -20201
				LET p_msgtext = "CSE 2001: Current year for AP company is ",
								"NULL.|See error log for more details."
			WHEN p_errcode = -20202
				LET p_msgtext = "CSE 2002: Current period for AP company is ",
								"NULL.|See error log for more details."
			WHEN p_errcode = -20203
				LET p_msgtext = "CSE 2003: Period set for AP company is ",
								"NULL.|See error log for more details."
			WHEN p_errcode = -20205
				LET p_msgtext = "CSE 2005: Period table not setup"
			WHEN p_errcode = -20206
				LET p_msgtext = "CSE 2006: Date not within current period.",
								"|See error log for more details."
			WHEN p_errcode = -20207
				LET p_msgtext = "CSE 2007: Date not within valid periods.",
								"|See error log for more details."
			WHEN p_errcode = -20300
				LET p_msgtext = "CSE 3000: Company not in AR company table.",
								"|See error log for more details."
			WHEN p_errcode = -20301
				LET p_msgtext = "CSE 3001: Current year for AR company is ",
								"NULL.|See error log for more details."
			WHEN p_errcode = -20302
				LET p_msgtext = "CSE 3002: Current period for AR company is ",
								"NULL.|See error log for more details."
			WHEN p_errcode = -20303
				LET p_msgtext = "CSE 3003: Period set for AR company is NULL.",
								"|See error log for more details."
			WHEN p_errcode = -20305
				LET p_msgtext = "CSE 3005: period table not setup"
			WHEN p_errcode = -20306
				LET p_msgtext = "CSE 3006: date not within current period.",
								"|See error log for more details."
			WHEN p_errcode = -20307
				LET p_msgtext = "CSE 3007: Date not within valid periods.",
								"|See error log for more details."
			WHEN p_errcode = -20400
				LET p_msgtext = "CSE 4000: Bank not in CB bank table.",
								"|See error log for more details."
			WHEN p_errcode = -20401
				LET p_msgtext = "CSE 4001: Current year for CB bank is NULL.",
								"|See error log for more details."
			WHEN p_errcode = -20402
				LET p_msgtext = "CSE 4002: Current period for CB bank IS NULL.",
								"|See error log for more details."
			WHEN p_errcode = -20403
				LET p_msgtext = "CSE 4003: Period set for CB bank IS NULL.",
								"|See error log for more details."
			WHEN p_errcode = -20405
				LET p_msgtext = "CSE 4005: Period table not setup"
			WHEN p_errcode = -20406
				LET p_msgtext = "CSE 4006: Date not within current period.",
								"|See error log for more details."
			WHEN p_errcode = -20407
				LET p_msgtext = "CSE 4007: Date before current period.",
								"|See error log for more details."
			WHEN p_errcode = -20500
				LET p_msgtext = "CSE 5000: PCINITBUDGET ledger not defined.",
								"|See error log for more details."
			WHEN p_errcode = -20501 
				LET p_msgtext = "CSE 5001: PCINITBUDGET ledger not a REAL ",
								"ledger.|See error log for more details."
			WHEN p_errcode = -20502
				LET p_msgtext = "CSE 5002: PCFORECAST ledger not defined.",
								"|See error log for more details."
			WHEN p_errcode = -20503
				LET p_msgtext = "CSE 5003: PCFORECAST ledger not a REAL ",
								"ledger.|See error log for more details."
			WHEN p_errcode = -20504
				LET p_msgtext = "CSE 5004: GLINITBUDGET ledger not defined.",
								"|See error log for more details."
			WHEN p_errcode = -20504
				LET p_msgtext = "CSE 5005: GLINITBUDGET ledger not a REAL ",
								"ledger.|See error log for more details."
			WHEN p_errcode = -20506
				LET p_msgtext = "CSE 5006: GLFORECAST ledger not defined.", 
								"|See error log for more details."
			WHEN p_errcode = -20507
				LET p_msgtext = "CSE 5007: GLFORECAST ledger not a REAL ",
								"ledger.|See error log for more details."
			WHEN p_errcode = -20508
				LET p_msgtext = "CSE 5008: PC account has an invalid GL ",
								"control account.|See error log for more ",
								"details."
			WHEN p_errcode = -20600
				LET p_msgtext = "CSE 6000: Bookvalue cannot be less than ",
								"combined depreciation" 
			WHEN p_errcode = -20601
				LET p_msgtext = "CSE 6001: Bookvalue cannot be less than ",
								"minimum value.|See error log for more ",
								"details."
			WHEN p_errcode = -20602
				LET p_msgtext = "CSE 6002: APGRACEDAYS must be between 0 ", 
								"and 30 days"
			WHEN p_errcode = -20603
				LET p_msgtext = "CSE 6002: ARGRACEDAYS must be between 0 ",
								"and 30 days"
			WHEN p_errcode = -20900
				LET p_msgtext = "CSE 9000: pa_glgrefchk: glgroup / dept ",
								"still being referenced.|See error log ",
								"for more details."
			WHEN p_errcode = -20998
				LET p_msgtext = "CSE 9999: arg1 > arg2"
			WHEN p_errcode = -20998
				LET p_msgtext = "CSE 9999: arg1 < arg2"
			END CASE

			RETURN p_msgtext
		OTHERWISE
		END CASE

END FUNCTION

FUNCTION lib_dialogVers()

DEFINE
	p_sticky CHAR(20),
	p_id CHAR(40)

	LET p_sticky = "$Name: tested80 $"
	LET p_id = "$Id: lib_dialog.4gl,v 80.0 2010/02/25 05:39:41 cath Exp $"

	RETURN "lib_dialog", "$Release$", ""

END FUNCTION
FUNCTION lib_dialog_getRev()

		RETURN "$Revision: 80.0 $"

END FUNCTION
}
FUNCTION gp_DialogBox(p_title, p_message, p_prompt, p_mode, p_row, p_col,p_key)

	DEFINE
			p_title					CHAR(80),
			p_message				CHAR(512),
			p_prompt				CHAR(80),
			p_mode					CHAR(8),
			p_row					INTEGER,
			p_col					INTEGER,
			p_key					INTEGER,

			pa_dialog				ARRAY[16] OF CHAR(80),
			pa_command				ARRAY[16] OF CHAR(20),

			p_keyup					CHAR(1),
			p_keychar				CHAR(1),
			pw_dialog				INTEGER,
			pw_message				INTEGER,
			p_retstat				INTEGER,
			p_maxlength				INTEGER,
			p_maxlines				INTEGER,
			p_height				INTEGER,
			p_option				CHAR(80),
			p_input					CHAR(10),
			p_type					CHAR(8),
			p_keyput				CHAR(1),
			p_keydown				CHAR(1),
			p_width					INTEGER,
			p_length				INTEGER,
			p_typeoffset			INTEGER,
			p_selected				INTEGER,
			p_continue				INTEGER,
			p_ptr					INTEGER,
			p_dir					INTEGER,
			p_start					INTEGER,
			p_text					INTEGER,
			idx						INTEGER,

			PC_delimiter			CHAR(1),
			pc_cmdlimiter			CHAR(1),
			pc_scrrows				INTEGER,
			pc_scrcols				INTEGER,
			pc_ynsize				INTEGER,
			pc_maxrows				INTEGER

		
		LET pc_scrrows = 24
		LET pc_scrcols = 80
		LET pc_ynsize = 15
		LET pc_delimiter = "|"
		LET pc_cmdlimiter = "!"
		LET pc_maxrows = 16


		LET p_typeoffset = 1
		INITIALIZE p_option TO NULL
		FOR idx = 1 TO pc_maxrows
			INITIALIZE pa_dialog[idx] TO NULL
			INITIALIZE pa_command[idx] TO NULL
		END FOR
	
		CASE
		WHEN p_mode MATCHES "[YyNn]*"
			LET p_type = "CONFIRM"
		OTHERWISE
			LET p_type = "ANY"
		END CASE
	

		LET p_maxlength = LENGTH(p_message)
		LET p_ptr = 1
		LET p_start = 1
		LET p_text = 0
		FOR idx = 1 TO pc_maxrows
			IF p_ptr > p_maxlength
			THEN
				LET idx = idx - 1
				EXIT FOR
			END IF
			
			WHILE p_ptr <= p_maxlength AND p_message[p_ptr] != pc_delimiter
				LET p_ptr =p_ptr +1
			END WHILE

			IF p_start < p_ptr
			THEN
				LET pa_dialog[idx] = p_message[p_start,p_ptr-1] CLIPPED
				LET p_text = p_text + 1
			END IF
			LET p_ptr = p_ptr + 1
			LET p_start = p_ptr
		END FOR

		IF p_maxlength > 0
		THEN
			IF p_text AND p_message[p_maxlength, p_maxlength] = pc_delimiter
			THEN
				LET idx = idx + 1
			END IF
		END IF

		IF idx > pc_maxrows
		THEN
			LET p_maxlines = pc_maxrows
		ELSE
			LET p_maxlines = idx
		END IF

		LET p_width = LENGTH(p_title)
		CASE
		WHEN p_type = "CONFIRM"
			LET p_length = LENGTH(p_prompt) + pc_ynsize
		OTHERWISE
			LET p_length = LENGTH(p_prompt)
		END CASE

		IF p_length > p_width
		THEN
			LET p_width = p_length
		END IF

		FOR idx = 1 TO p_maxlines
			LET p_length = LENGTH(pa_dialog[idx])
			IF p_length > p_width
			THEN
				LET p_width = p_length
			END IF
		END FOR
		LET p_width = p_width +2


		LET p_height = p_maxlines + 3
		IF p_row = 0
		THEN
			LET p_row = ((pc_scrrows - p_height) / 2) +1
		END IF
		IF p_col = 0
		THEN
			LET p_col = ((pc_scrcols - p_width) / 2) +1
		END IF

		LET pw_dialog = gp_OpenWindow("DIALOG",p_row, p_col, p_height,

										p_width)
		IF pw_dialog < 1
		THEN
			RETURN ""
		END IF
		IF p_mode MATCHES "*!"
		THEN	
			ERROR ""
		END IF
		LET pw_message = 0

		IF LENGTH(p_title) > 1
		THEN
			LET p_title = gp_CentreJustify(p_title, p_width - 2)
			DISPLAY p_title
--#				AT 1,2 ATTRIBUTE(REVERSE,BLUE)
			DISPLAY "  " AT 1, p_width
				ATTRIBUTE(NORMAL)
		END IF

		FOR idx = 1 TO p_maxlines
			LET p_ptr = idx + 2 - p_typeoffset
			DISPLAY pa_dialog[idx] CLIPPED
				AT p_ptr,2 ATTRIBUTE(NORMAL)
		END FOR
		#rxx

		
		CASE
		WHEN p_type = "CONFIRM"
			LET p_length = LENGTH(p_prompt)
			LET p_height = p_height - 1
			LEt idx = ((p_width - p_length - pc_ynsize) / 2) +2
			DISPLAY p_prompt
--#				AT p_height, idx ATTRIBUTE(NORMAL, UNDERLINE,BLUE)

			LET p_row = p_row + p_height - 1
			LET p_col = p_col + idx + p_length - 1
			LET p_width = p_width - 2
			OPEN WINDOW w_dgconfirm
			AT p_row, p_col
			WITH 2 ROWS, pc_ynsize COLUMNS
--#			ATTRIBUTE(REVERSE, BORDER,BLACK,
						PROMPT LINE LAST,
						MESSAGE LINE LAST,
						COMMENT LINE LAST,
						FORM LINE FIRST)
			IF p_mode MATCHES "[Yy] *"
			THEN
				MENU ""
					COMMAND "Yes"
						LET p_option  ="YES"
						EXIT MENU
					COMMAND "No"
						LET p_option = "NO"
						EXIT MENU
				END MENU
			ELSE
				MENU ""
					COMMAND "No"
						LET p_option = "NO"
						EXIT MENU
					COMMAND "Yes"
						LET p_option = "YES"
						EXIT MENU
				END MENU
			END IF

			CLOSE WINDOW w_dgconfirm


		WHEN p_type = "ANY"
			LET p_prompt = gp_CentreJustify(p_prompt, p_width-2)
			LET p_row = p_height - 1
			DISPLAY p_prompt CLIPPED 
--#				AT p_row, 2 ATTRIBUTE(REVERSE,BLUE)
			CALL gp_PromptForAnyKey(p_key)

		END CASE

		IF pw_message > 0
		THEN
			CALL gp_CloseWindow(pw_message)
		END IF

		CALL gp_CloseWindow(pw_dialog)

		RETURN p_option CLIPPED
END FUNCTION

FUNCTION gp_CentreJustify(p_string, p_width)

DEFINE
		p_string				CHAR(80),
		p_width					INTEGER,

		p_result				CHAR(80),
		p_length				INTEGER,
		p_prefix				INTEGER,
		p_suffix				INTEGER

		INITIALIZE p_result TO NULL

		IF p_width <1
		THEN
			RETURN p_result
		END IF

		LET p_length = LENGTH(p_string)
		IF p_length >= p_width
		THEN
			LET p_result[1,p_width] = p_string[1,p_width]
			RETURN p_result
		END IF

		LET p_length = LENGTH(p_string)
		IF p_length > p_width 
		THEN
			RETURN p_string[1, p_width]
		END IF

		LET p_suffix = ((p_width - p_length) / 2) - 1
		LET p_prefix = p_width - p_length - p_suffix

		LET p_result[1,p_prefix]
			= "                                        "
		LET p_result[p_prefix,p_width-p_suffix] = p_string
		LET p_result[p_width-p_suffix,p_width]
			= "                                        "
		RETURN p_result
END FUNCTION

FUNCTION gp_OpenWindow(p_type, p_rowpos,p_colpos, p_rowsize, p_colsize)

	DEFINE
			p_type		CHAR(12),
			p_colsize	INTEGER,
			p_rowpos	INTEGER,
            p_colpos	INTEGER,
			p_rowsize	INTEGER



	CASE
	WHEN p_type = "DIALOG"
		OPEN WINDOW w_window
			AT p_rowpos, p_colpos
			WITH p_rowsize ROWS, p_colsize COLUMNS
--#			ATTRIBUTE (BORDER,REVERSE,BLACK, PROMPT LINE LAST,
			MESSAGE LINE LAST, COMMENT LINE LAST, FORM LINE 2)
	END CASE
	RETURN 1
END FUNCTION


FUNCTION gp_CloseWindow(pw_window)
DEFINE
	pw_window				INTEGER

	CLOSE WINDOW w_window
	RETURN
END FUNCTION


FUNCTION gp_PromptForAnyKey(p_key)

	DEFINE
		p_key		INTEGER,

		p_keyput	CHAR(1)


	LET p_keyput = gp_PromptKey()
	RETURN
	OPTIONS ACCEPT KEY F36
	PROMPT "" FOR CHAR p_keyput
		ON KEY(F1,F2,F3,F4,F5,F6,F7,F8,F9,INTERRUPT)
			OPTIONS ACCEPT KEY F1
			RETURN
	END PROMPT
	OPTIONS ACCEPT KEY F1

	RETURN

END FUNCTION

FUNCTION gp_PromptKey()

	DEFINE
		p_vector	CHAR(1)




		PROMPT ""
			FOR CHAR p_vector
			ATTRIBUTE(INVISIBLE)

			ON KEY (F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,
				F11,F12,F13,F14,F15,F16,F17,F18,F19,F20,				
				F21,F22,F23,F24,F25,F26,F27,F28,F29,F30,				
				UP,DOWN,LEFT,RIGHT,
				ESCAPE,TAB,INTERRUPT)
				LET p_vector = ""
		END PROMPT

		RETURN gp_KeyChar(fgl_lastkey())
END FUNCTION

FUNCTION gp_KeyChar(p_key)

	DEFINE
		p_key		INTEGER,
		p_char		CHAR(12)


		CASE
		WHEN p_key = fgl_keyval("return")
			LET p_char = "RETURN"
		WHEN p_key = fgl_keyval("escape")
			LET p_char = "ESCAPE"
		WHEN p_key < 128
			LET p_char = ASCII p_key
		WHEN p_key = fgl_keyval("up")
			LET p_char = "UP"
		WHEN p_key = fgl_keyval("down")
			LET p_char = "DOWN"
		WHEN p_key = fgl_keyval("left")
			LET p_char = "LEFT"
		WHEN p_key = fgl_keyval("right")
			LET p_char = "RIGHT"
		WHEN p_key = fgl_keyval("interrupt")
			LET p_char = "DEL"
		WHEN p_key = fgl_keyval("quit")
			LET p_char = "QUIT"
		WHEN p_key >= fgl_keyval("f1")
			LET p_char = "F", p_key - 2999 USING "<<"
		END CASE

		RETURN p_char CLIPPED

END FUNCTION

