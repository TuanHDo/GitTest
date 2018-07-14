################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entM - Style Maintenance program           #
#  																			   #
# 	R00	02aug01	td				initial release						           #
#	R01	22oct05 td		Mod. Campaign - convert to Genero                      #
# 	R02	21jun09	td		  Mod. Campaign - Copy style to SeedHK                 #
#   R03 06Jul12 tn      Mod. Add Fob fields and Story into SeedHK
#   R04 23apr13 td      Mod. increase the length of the style to 7 characters
#   R05 22sep14 td      Mod. To introduce SG & NZ companies
#   R06 08aug15 td      Mod. To introduce division
#   R07 20jun18 td      Mod. Upload Images file 
################################################################################
DATABASE seed

GLOBALS 'sty_entG.4gl'

MAIN
	DEFINE	
			p_user					CHAR(40),		#R07
			p_cmd					STRING,			#R07
			p_image_upload   		STRING,			#R07
			p_image_file		    VARCHAR(100),	#R07
			p_style					LIKE style.style,		#R02
			p_display				STRING,			#R01
			p_prog					CHAR(80),		#R01
		 	p_menuopt 				CHAR(80),
			p_dspdone				INTEGER,
			p_inuse					INTEGER,
			p_retstat				INTEGER,
			p_run					STRING,		#R07
			p_prog1					STRING,		#R07
			p_lasttime				CHAR(10)


	#rxx >>
	LET p_prog1 = arg_val(0)
	#exit the program if another copy of this is being run
	display  "fglrun-bin ", p_prog1 CLIPPED
##display "RUN: ", p_run
	##CALL close_if_process_running(p_run,p_prog1)							#R01
	#rxx <<
	 CALL gp_Init("R00")
	DEFER INTERRUPT
	DEFER QUIT

	CLOSE WINDOW SCREEN
	LET g_void =  sty_entI("SETDEFAULT")	
	CALL create_temp()								#R07
	OPEN WINDOW pf_sty_ent WITH FORM "stymaint"
	ATTRIBUTE(TEXT=g_scrnhdr,STYLE="maint")
	#gxx <<
	{main menu }
--#	DISPLAY g_menuopt AT 22,1 ATTRIBUTE(REVERSE,BLUE)

	MENU ""
		COMMAND "Add" "add a new record"
			MESSAGE ""
			LET g_currqry = NULL
			LET g_wherepart = NULL
			LET g_currentrec = 0
			LET p_retstat = sty_entU("a")
			IF g_wherepart IS NOT NULL THEN
				LET g_currqry = g_select CLIPPED, " ",
								g_wherepart CLIPPED," ",
								g_orderby CLIPPED
				LET g_currqcnt = g_dfqcnt CLIPPED, g_wherepart CLIPPED
				LET g_lastquery = g_currqry
				LET g_void = sty_entE()
			END IF

		COMMAND "Upd" "update the current record"
			MESSAGE ""
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
                LET p_inuse = FALSE
				LET p_retstat = sty_entI("LOCK")
			    CASE
                WHEN NOT p_retstat
                    LET p_inuse = TRUE
                OTHERWISE
                    LET p_retstat = sty_entU("u")
                    LET p_retstat = sty_entI("UNLOCK")
                    IF p_lasttime = "Nxt" THEN
                        LET g_void = sty_entI("CURRENT")
                        NEXT OPTION "Nxt"
                    ELSE
                        NEXT OPTION "Prev"
                    END IF
                END CASE
                IF p_inuse THEN
                    ERROR "record is in USE, try later"
                    SLEEP 2
                END IF
			END CASE
		#R02 >>
		COMMAND "Copy" "Copy the current record to SeedHK"
			MESSAGE ""
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
                LET p_inuse = FALSE
				LET p_retstat = sty_entI("LOCK")
			    CASE
                WHEN NOT p_retstat
                    LET p_inuse = TRUE
                OTHERWISE
					LET p_style = NULL
					SELECT	style
					INTO	p_style
					FROM	seedhk:style
					WHERE	style = g_style.style

					IF p_style IS NOT NULL THEN
						LET p_display = "Style already exists in HK database"
						CALL messagebox(p_display,2)  
				    ELSE
                    	LET p_retstat = sty_entU1("")
					END IF
                    LET p_retstat = sty_entI("UNLOCK")
                    IF p_lasttime = "Nxt" THEN
                        LET g_void = sty_entI("CURRENT")
                        NEXT OPTION "Nxt"
                    ELSE
                        NEXT OPTION "Prev"
                    END IF
                END CASE
                IF p_inuse THEN
                    ERROR "record is in USE, try later"
                    SLEEP 2
                END IF
			END CASE
		#R02 <<
		#R05 >>
		COMMAND "CopySin" "Copy the current record to SeedSG"
			MESSAGE ""
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
                LET p_inuse = FALSE
				LET p_retstat = sty_entI("LOCK")
			    CASE
                WHEN NOT p_retstat
                    LET p_inuse = TRUE
                OTHERWISE
					LET p_style = NULL
					SELECT	style
					INTO	p_style
					FROM	seedsin:style
					WHERE	style = g_style.style

					IF p_style IS NOT NULL THEN
						LET p_display = "Style already exists in SG Database"
						CALL messagebox(p_display,2)  
				    ELSE
                    	LET p_retstat = sty_entU2("")
					END IF
                    LET p_retstat = sty_entI("UNLOCK")
                    IF p_lasttime = "Nxt" THEN
                        LET g_void = sty_entI("CURRENT")
                        NEXT OPTION "Nxt"
                    ELSE
                        NEXT OPTION "Prev"
                    END IF
                END CASE
                IF p_inuse THEN
                    ERROR "record is in USE, try later"
                    SLEEP 2
                END IF
			END CASE
		#R05 <<
		#R05 >>
		COMMAND "CopyNZ" "Copy the current record to SeedNZ"
			MESSAGE ""
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
                LET p_inuse = FALSE
				LET p_retstat = sty_entI("LOCK")
			    CASE
                WHEN NOT p_retstat
                    LET p_inuse = TRUE
                OTHERWISE
					LET p_style = NULL
					SELECT	style
					INTO	p_style
					FROM	seednz:style
					WHERE	style = g_style.style

					IF p_style IS NOT NULL THEN
						LET p_display = "Style already exists in NZ Database"
						CALL messagebox(p_display,2)  
				    ELSE
                    	LET p_retstat = sty_entU3("")
					END IF
                    LET p_retstat = sty_entI("UNLOCK")
                    IF p_lasttime = "Nxt" THEN
                        LET g_void = sty_entI("CURRENT")
                        NEXT OPTION "Nxt"
                    ELSE
                        NEXT OPTION "Prev"
                    END IF
                END CASE
                IF p_inuse THEN
                    ERROR "record is in USE, try later"
                    SLEEP 2
                END IF
			END CASE
		#R05 <<
		#R07 >>
		COMMAND "Upload" "Upload Online Images file"
			SELECT	LIMIT 1 who
			INTO	p_user
			FROM	report_run
			WHERE	report_name = p_prog1
			
			IF status != NOTFOUND THEN
				LET p_display = "\nThe Upload Image program is  being run by ",p_user,
								"\nPlease try it again later"
				CALL messagebox(p_display,1)
			ELSE
    			LET p_cmd = "ls /file_storage/brandbank_tmp/shau/flow/images/image.end"				
    			RUN p_cmd RETURNING p_retstat
    			IF p_retstat <> 0 THEN
					DISPLAY "upload pressed!"
					IF  online_setpasswd() THEN
						LET p_display = "\nThe csv file upload will overwite all previous products/images . ",
									"\nPlease ensure that images  are linked to the correct product code."
						CALL messagebox(p_display,1)
						CALL ui.Interface.frontCall("standard","openfile",[NULL,"","*.csv","Image file"],[p_image_upload])
					##CALL ui.Interface.frontCall("standard","openfile",[NULL,"","*.xlsx","Image file"],[p_image_upload])
display "upload image ",p_image_upload
						IF p_image_upload IS NULL THEN
					    	CALL fgl_winmessage("Error","Upload was cancelled","Upload Cancelled")
						ELSE
							LET g_image_upload =  p_image_upload
							#TODO add valiation here
							DISPLAY "FILENAME : ",p_image_upload
							LET p_image_file = TIME
							LET p_image_file = "QP",p_image_file[1,2]||p_image_file[4,5]||p_image_file[7,8]
							LET p_image_file = SFMT("%1%2_image_file.csv"
													,IMAGE_FILE_DESTINATION,p_image_file)
display p_image_file, " ",p_image_upload," ",IMAGE_FILE_DESTINATION

							DISPLAY p_image_file
							CALL FGL_GETFILE(p_image_upload,p_image_file)			#getfile to /tmp
							INSERT INTO report_run VALUES(g_user,p_prog1,CURRENT)   #block other users
							LET p_retstat =  sty_entUpload(p_image_file)
							#release the block
							DELETE FROM report_run 
							WHERE  who = g_user
						    AND		report_name = p_prog1
						END IF
					END IF
				ELSE
					LET p_display = "\nImage files are being transmitted ",
									"\nPlease try it again later"
					CALL messagebox(p_display,1)
				END IF
			END IF
			#R07 <<


		COMMAND "Report" "run report" 
			MESSAGE ""
			LET p_retstat = sty_entQ("Select")
			CASE
			WHEN p_retstat = 0
				IF g_currqry IS NULL OR g_totrec = 0 THEN
					ERROR "no current list"
					ATTRIBUTE(RED)
				END IF
			OTHERWISE
				LET g_void = sty_entI("CURRENT")
				INITIALIZE g_style.* TO NULL
				IF sty_entI("INIT") THEN
					CALL sty_entR() 		# query print
				END IF
			END CASE

		COMMAND KEY(F10,INTERRUPT,"E") "Exit" "exit this program" 
			MESSAGE ""
			DISPLAY "" AT 22,1
			EXIT MENU

		COMMAND "Select" "select working set of records"
			MESSAGE ""
			LET p_retstat = sty_entQ("Select")
			CASE
			WHEN p_retstat = 0
				IF g_currqry IS NULL OR g_totrec = 0 THEN
					ERROR "no current list"
					ATTRIBUTE(RED)
				ELSE
					LET g_void = sty_entI("CURRENT")
					CALL sty_entX()
				END IF
			WHEN p_retstat = 1
				IF sty_entE() THEN
					LET p_lasttime = "Nxt"
					NEXT OPTION "Nxt"
				END IF
			END CASE
			
		COMMAND "Colour" "Add style colour "
			MESSAGE ""
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
			OTHERWISE
				IF sty_entL() THEN
                	LET p_retstat = sty_entI("COLOUR")
				END IF
				IF p_lasttime = "Nxt" THEN
					LET g_void = sty_entI("CURRENT")
					NEXT OPTION "Nxt"
				ELSE
					NEXT OPTION "Prev"
				END IF
			END CASE
		#R05 >>
		COMMAND "Sku" "Enquire skus "
			MESSAGE ""
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
			OTHERWISE
               	LET p_retstat = sty_entA1("INIT")
               	LET p_retstat = sty_entA1("SELECT")
               	LET p_retstat = sty_entA1("BROWSE")
				IF p_lasttime = "Nxt" THEN
					LET g_void = sty_entI("CURRENT")
					NEXT OPTION "Nxt"
				ELSE
					NEXT OPTION "Prev"
				END IF
			END CASE
		#R05 <<

		COMMAND "First" "display First record"
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
				LET p_lasttime = "First"
				IF NOT sty_entI("FIRST") THEN
					ERROR "last record on display"
					ATTRIBUTE(RED)
					NEXT OPTION "Prev"
					LET p_lasttime = "Prev"
				ELSE
					CALL sty_entX()
				END IF
			END CASE	

		COMMAND "Prev" "display PREVIOUS record"
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
				LET p_lasttime = "Prev"
				IF NOT sty_entI("PRIOR") THEN
					ERROR "first record on display"
					ATTRIBUTE(RED)
					NEXT OPTION "Nxt"
					LET p_lasttime = "Nxt"
				ELSE
					CALL sty_entX()
				END IF
			END CASE	

		COMMAND "Nxt" "display NEXT record"
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
				LET p_lasttime = "Nxt"
				IF NOT sty_entI("NEXT") THEN
					ERROR "last record on display"
					ATTRIBUTE(RED)
					NEXT OPTION "Prev"
					LET p_lasttime = "Prev"
				ELSE
					CALL sty_entX()
				END IF
			END CASE	
		
		COMMAND "Last" "display Last record"
			CASE
			WHEN g_totrec = 0
				ERROR "no records in list"
				ATTRIBUTE(RED)
			WHEN g_currqry IS NULL
				ERROR "record not found: create one with Select"
				ATTRIBUTE(RED)
			OTHERWISE
				LET p_lasttime = "Last"
				IF NOT sty_entI("LAST") THEN
					ERROR "last record on display"
					ATTRIBUTE(RED)
					NEXT OPTION "First"
					LET p_lasttime = "First"
				ELSE
					CALL sty_entX()
				END IF
			END CASE	

		COMMAND KEY(CONTROL-V)
			LET p_prog = arg_val(0)
			LET p_display = "Program: ",p_prog[36,80]
			CALL messagebox(p_display,1)
	END MENU
	EXIT PROGRAM(0)
END MAIN
################################################################################
# @@@@@@@@@@@@@@@@@@@@ (main)@@@@@@@@@@@@@@@@@@ #
################################################################################
################################################################################
#	sty_entQ - Query by Form											       #
################################################################################
FUNCTION sty_entQ(p_request)
	DEFINE
			p_request			CHAR(10),
			p_status			INTEGER

	IF p_request = "Report"
    THEN
        LET p_request = gp_pulldown("Choose","Select","Current","Quit"
                                    ,"",5,40)
    ELSE
        LET p_request = "Select"
    END IF

	CASE
    WHEN p_request = "All"
        MESSAGE ""
        LET g_currqry = g_select CLIPPED, g_orderby CLIPPED
        LET g_currqcnt = g_dfqcnt
        LET g_lastquery = g_currqry
        LET g_wherepart = "1 = 1"
        RETURN 1

	WHEN p_request = "Select"
		##CLEAR FORM
		MESSAGE ""
		LET g_lnl[1,80] = "QUERY BY FORMS: enter selection criteria"
		DISPLAY g_lnl AT 2,1
		DISPLAY "" AT 2,1
		CALL sty_entC() RETURNING g_currqry, p_status
		IF p_status THEN
			RETURN 0
		END IF
--#		DISPLAY g_menuopt AT 22,1 ATTRIBUTE(REVERSE,BLUE)
		IF g_currqry IS NOT NULL THEN
			LET g_currqcnt = g_dfqcnt CLIPPED, " WHERE ",g_wherepart CLIPPED
			LET g_lastquery = g_currqry
			RETURN 1
		END IF
   	WHEN p_request = "Current"
        CASE
        WHEN g_totrec = 0
            ERROR "no records in list"
        WHEN g_currqry IS NULL
            ERROR "no active list: create one with SELECT"
        OTHERWISE
            RETURN 2
        END CASE
	END CASE
	RETURN FALSE
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@@@@@@ (sty_entQ)@@@@@@@@@@@@@@@@@@ #
################################################################################
################################################################################
#	sty_entC - Construct the Query
################################################################################
FUNCTION sty_entC()
	DEFINE
			initial_flag		INTEGER,
			query_string		CHAR(500),
			where_part			CHAR(200)

	LET g_constoption = "OPTIONS: F1=ACCEPT F10=EXIT F11=HELP"			
	DISPLAY g_constoption AT 22,1 
	ATTRIBUTE(REVERSE,BLUE)
	LET int_flag = FALSE
	##CLEAR FORM
	##CURRENT WINDOW is  pf_sty_ent 
	CONSTRUCT BY NAME where_part ON
		style.style,
    	style.style_desc,
    	style.short_desc,
    	style.supplier,
    	style.sup_sty,
    	style.season,
    	style.division,
    	style.section,					#R05
    	style.class,
    	style.category,
    	style.fabric_type,
    	style.story,
    	style.lchg_dte,
    	style.del_flg,
    	style.unit_cost,
    	style.unit_sell,
    	style.orig_sell,
    	style.country_of_origin
		
--#		ATTRIBUTE(NORMAL)

		ON KEY (F10,INTERRUPT)
			LET int_flag = TRUE
			EXIT CONSTRUCT

		ON ACTION cancel
display "here"
			LET int_flag = TRUE
			EXIT CONSTRUCT

		ON ACTION accept
display "accept"
			LET int_flag = FALSE
			EXIT CONSTRUCT

	END CONSTRUCT
display "here: ",	initial_flag

	IF int_flag THEN
		RETURN g_lastquery,TRUE
	END IF
	#IF where_part IS NULL THEN
		#LET where_part = "1=1"
	#END IF
	LET query_string = g_select CLIPPED, " WHERE ",where_part CLIPPED,
											g_orderby CLIPPED
	LET g_wherepart = where_part CLIPPED
display "string: ",query_string, "wherepart: ", g_wherepart
	RETURN query_string,FALSE
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@@@@@@ (sty_entC)@@@@@@@@@@@@@@@@@@ #
################################################################################
################################################################################
#	sty_entE - display record
################################################################################
FUNCTION sty_entE()

	INITIALIZE g_style.* TO NULL
	#R02 >>	
	LET g_hk_style_desc = NULL
    LET g_hk_short_desc = NULL
    LET g_hk_supplier = NULL
    LET g_hk_sup_sty = NULL
    LET g_hk_season = NULL
    LET g_hk_division = NULL				#R06
    LET g_hk_class = NULL
    LET g_hk_category = NULL
    LET g_hk_unit_cost = NULL
    LET g_hk_unit_sell = NULL
    LET g_hk_orig_sell = NULL
    LET g_hk_lchg_dte = NULL
    LET g_hk_gst_perc = NULL
    LET g_hk_fob_method = NULL  #r03
    LET g_hk_fob = NULL
    LET g_hk_fob_cost = NULL
    LET g_hk_story = NULL
    LET g_hk_story_desc = NULL
	#R02 <<
	#R05 >>
	LET g_sin_style_desc = NULL
    LET g_sin_short_desc = NULL
    LET g_sin_supplier = NULL
    LET g_sin_sup_sty = NULL
    LET g_sin_season = NULL
    LET g_sin_division = NULL			#R06
    LET g_sin_class = NULL
    LET g_sin_category = NULL
    LET g_sin_unit_cost = NULL
    LET g_sin_unit_sell = NULL
    LET g_sin_orig_sell = NULL
    LET g_sin_lchg_dte = NULL
    LET g_sin_gst_perc = NULL
    LET g_sin_fob_method = NULL  
    LET g_sin_fob = NULL
    LET g_sin_fob_cost = NULL
    LET g_sin_story = NULL
    LET g_sin_story_desc = NULL
	#NZ
	LET g_nz_style_desc = NULL
    LET g_nz_short_desc = NULL
    LET g_nz_supplier = NULL
    LET g_nz_sup_sty = NULL
    LET g_nz_season = NULL
    LET g_nz_division = NULL			#R06
    LET g_nz_class = NULL
    LET g_nz_category = NULL
    LET g_nz_unit_cost = NULL
    LET g_nz_unit_sell = NULL
    LET g_nz_orig_sell = NULL
    LET g_nz_lchg_dte = NULL
    LET g_nz_gst_perc = NULL
    LET g_nz_fob_method = NULL  
    LET g_nz_fob = NULL
    LET g_nz_fob_cost = NULL
    LET g_nz_story = NULL
    LET g_nz_story_desc = NULL
	#R05 <<
	#R05 <<

	IF NOT sty_entI("INIT") THEN
		ERROR "no record satisfies selection criteria"
		RETURN FALSE
	END IF
	LET g_void = sty_entI("NEXT")
	LET g_currentrec = 1
	CALL sty_entX()
	RETURN TRUE
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@@@@@@ (sty_entE)@@@@@@@@@@@@@@@@@@ #
################################################################################
#R07 >>
FUNCTION create_temp()
	CREATE TEMP TABLE t_image(
		line_no 			INT,
		style 				CHAR(9),
		colour 				SMALLINT,
		au_publish			CHAR(1),
		au_hero_image 		CHAR(1),
		nz_publish 			CHAR(1),
		nz_hero_image 		CHAR(1),
		hk_publish 			CHAR(1),
		hk_hero_image 		CHAR(1),
		sg_publish 			CHAR(1),
		sg_hero_image 		CHAR(1),
		dw_au_hero_image 	CHAR(1),
		dw_nz_hero_image 	CHAR(1),
		dw_hk_hero_image 	CHAR(1),
		dw_sg_hero_image 	CHAR(1),
		au_image1 			VARCHAR(100),
		au_image2 			VARCHAR(100),
		au_image3 			VARCHAR(100),
		au_image4 			VARCHAR(100),
		au_image5 			VARCHAR(100),
		hk_image1 			VARCHAR(100),
		hk_image2 			VARCHAR(100),
		hk_image3 			VARCHAR(100),
		hk_image4 			VARCHAR(100),
		hk_image5 			VARCHAR(100),
		sg_image1 			VARCHAR(100),
		sg_image2 			VARCHAR(100),
		sg_image3 			VARCHAR(100),
		sg_image4 			VARCHAR(100),
		sg_image5 			VARCHAR(100));

	CREATE TEMP TABLE t_upload_image 
  (
    line_no integer,
    style char(9),
    colour smallint,
    au_publish char(1),
    au_hero_image char(1),
    nz_publish char(1),
    nz_hero_image char(1),
    hk_publish char(1),
    hk_hero_image char(1),
    sg_publish char(1),
    sg_hero_image char(1),
    dw_au_hero_image char(1),
    dw_nz_hero_image char(1),
    dw_hk_hero_image char(1),
    dw_sg_hero_image char(1),
    au_image1 varchar(100),
    au_image2 varchar(100),
    au_image3 varchar(100),
    au_image4 varchar(100),
    au_image5 varchar(100),
    hk_image1 varchar(100),
    hk_image2 varchar(100),
    hk_image3 varchar(100),
    hk_image4 varchar(100),
    hk_image5 varchar(100),
    sg_image1 varchar(100),
    sg_image2 varchar(100),
    sg_image3 varchar(100),
    sg_image4 varchar(100),
    sg_image5 varchar(100),
    upload_status char(20),
    who char(40),
    upload_date datetime year to fraction(3),
    filename char(200)
  );
END FUNCTION
#R07 <<
