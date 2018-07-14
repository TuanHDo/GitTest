################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entI - Style maintenance program           #
#  																			   #
# 	R00	02aug01	td				initial release						           #
# 	R01	13jul04	td				add cost_lchg_date,ledger_cost                 #
#	R02	22oct05 td				Mod. Campaign - convert to Genero              #
#	R03	15nov06 td				introduce date insert field					  #
#	R04	09jan09 td				update seedhk:supplier style                   #
# 	R05	21jun09	td		  Mod. Campaign - Copy style to SeedHK                 #
#   R06 11Jul12 tn        Mod. To add new fields ie. fob_method,fob,fob_cost and story to SeedH
#   R07 28jan13 td        Mod. Campaign - introduce new stylelg1 table         #
#						  update po_lns.unit_cost = style.unit_cost only       #
#						  if the style is not in the costing system            #
#   R08 23apr13 td      Mod. increase the length of the style to 7 characters
#   R09 22sep14 td        Mod. To introduce SIN & NZ companies
#   R10 15nov14 td              Mod Campaign - Set pos_del_flg = "A" to be used"
#                               in the product dump data file to N
#   R11 08aug15 td        Mod. To introduce division
#   R12 17jan16 td        Mod. To introduce fabric description
#   R13 02oct16 td        Mod. add HK & SG images
#   R14	02dec17 td	  Mod. Campaign - Genero Cloud migration
#	R15	25may18 td		  		Add video url page							   #
################################################################################
DATABASE seed

GLOBALS
	"sty_entG.4gl"

	DEFINE
			   s_lockdtime         LIKE style.lockdtime
FUNCTION sty_entI(p_mode)

	DEFINE
			p_style					RECORD LIKE style.*,			#R05
			p_count2				SMALLINT,						#R07
			p_count					SMALLINT,
			p_count1				SMALLINT,
			p_who      		        CHAR(20),
			p_query					CHAR(200),
			#R08 tmpstyle 				CHAR(6),
			tmpstyle 				CHAR(7),					#R08
			p_start_no				SMALLINT,
			p_option				CHAR(10),
			p_text					STRING,						#R02
			p_mode					CHAR(10),
			p_retstat				INTEGER,
			p_redo					CHAR(10),
			p_program			STRING,
			p_status				INTEGER,
			p_lockdtime         	LIKE style.lockdtime,
			p_cursoropen			INTEGER

	LET p_retstat = TRUE
	LET p_cursoropen = FALSE
	LET p_redo = NULL
	IF p_mode = "UPDATE" OR p_mode = "INSERT" OR p_mode="DELETE"  OR p_mode = "LOCK" OR p_mode = "UNLOCK" OR p_mode = "COLOUR"
	OR p_mode = "COPY" OR p_mode = "COPYSIN" OR p_mode ="COPYNZ"			#R09
	THEN
		BEGIN WORK
	END IF
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	
	LABEL redo:
	CASE
	WHEN p_mode = "SETDEFAULT"
		#R14 LET g_user = FGL_GETENV("LOGNAME")
    	LET g_user = ARG_VAL(1)			#R14
    LET p_program  = ARG_VAL(0)		#R14

    display "program: " ,p_program, " usr: ",g_user
		LET g_comp = gp_getco(1)							#get company name
		LET g_scrnhdr = "** ",g_comp CLIPPED," **"
		LET g_scrnhdr[30,60] = "- Style - "
		LET g_scrnhdr[65,80] = DATE

		LET g_select = "SELECT style	FROM style "
		#LET g_orderby = " ORDER BY customer"
		LET g_orderby = " ORDER BY style DESC"
		LET g_dfqcnt = "SELECT COUNT(*) FROM style"
		LET g_currqry = NULL
    	##LET g_user = fgl_getenv("LOGNAME")
		WHENEVER ERROR STOP

	WHEN p_mode = "INIT"
		IF p_cursoropen THEN
			CALL close_cursor()
			LET p_cursoropen = FALSE
		END IF
		INITIALIZE g_style.* TO NULL
		INITIALIZE g_style_webcat.* TO NULL			#R12
		LET g_hk_style_desc = NULL
		LET g_hk_short_desc = NULL
		LET g_hk_supplier = NULL
		LET g_hk_sup_sty = NULL
		LET g_hk_season = NULL
		LET g_hk_division = NULL				#R11
		LET g_hk_class = NULL
		LET g_hk_category = NULL
		LET g_hk_unit_cost = NULL
		LET g_hk_unit_sell = NULL
		LET g_hk_orig_sell = NULL
		LET g_hk_lchg_dte = NULL
		LET g_hk_gst_perc = NULL
		LET g_hk_fob_method = NULL #R06
		LET g_hk_fob = NULL 
		LET g_hk_fob_cost = NULL #R06
		LET g_hk_story = NULL #R06
		#R09 >>
		#sinagpore
		LET g_sin_style_desc = NULL
		LET g_sin_short_desc = NULL
		LET g_sin_supplier = NULL
		LET g_sin_sup_sty = NULL
		LET g_sin_season = NULL
		LET g_sin_division = NULL			#R11
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
		#NZ
		#R09 >>
		LET g_nz_style_desc = NULL
		LET g_nz_short_desc = NULL
		LET g_nz_supplier = NULL
		LET g_nz_sup_sty = NULL
		LET g_nz_season = NULL
		LET g_nz_division = NULL			#R11
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
		#R09 <<
		#R09 <<

##display ">>> g_currqry = ",g_currqry sleep 3   #tantest

		PREPARE s_1 FROM g_currqry
		DECLARE c_set SCROLL CURSOR WITH HOLD FOR s_1
		LET g_totrec = 0
		MESSAGE "searching file..."
		PREPARE cnt_1 FROM g_currqcnt
		DECLARE c_count CURSOR FOR cnt_1
		OPEN c_count  
		FETCH c_count INTO g_totrec
		CLOSE c_count
		MESSAGE ""
		IF g_totrec = 0 THEN
			LET p_retstat = FALSE
		ELSE
			OPEN c_set
			LET p_cursoropen = TRUE
			LET p_retstat = TRUE
		END IF

	#R02 >>
	 WHEN p_mode = "LAST"
        FETCH LAST c_set INTO g_style.style
        LET g_currentrec = g_totrec
        LET p_retstat = TRUE
    WHEN p_mode = "FIRST"
        FETCH FIRST c_set INTO g_style.style
        LET g_currentrec = 1
        LET p_retstat = TRUE
	#R02 <<
	WHEN p_mode = "NEXT"
		FETCH NEXT c_set INTO g_style.style
		IF status = NOTFOUND THEN
			FETCH LAST c_set INTO g_style.style
			LET g_currentrec = g_totrec
			LET p_retstat = FALSE
		ELSE
			LET g_currentrec = g_currentrec + 1
			LET p_retstat = TRUE
		END IF	

	WHEN p_mode = "PRIOR"
		FETCH PRIOR c_set INTO g_style.style
		IF status = NOTFOUND THEN
			FETCH FIRST c_set INTO g_style.style
			LET g_currentrec = 1
			LET p_retstat = FALSE
		ELSE
			LET g_currentrec = g_currentrec - 1
			LET p_retstat = TRUE
		END IF	

	WHEN p_mode = "INSERT"
		LET p_retstat = TRUE
		WHENEVER ERROR CONTINUE										
		LET g_style.lchg_dte = TODAY
		LET g_style.cost_lchg_date = TODAY   #R01
		LET g_style.style = ""
		LET g_style.pos_del_flg = NULL				#R10
		LET p_start_no = 0

		LET g_style.web_desc1 = strip_special_chars(g_style.web_desc1)  #R09
		LET g_style.web_desc2 = strip_special_chars(g_style.web_desc2)  #R09
		LET g_style.web_desc3 = strip_special_chars(g_style.web_desc3)  #R09

		####################################
		#generate next available style number
		####################################
		SELECT	MIN(av_styles.next_avail) 
   	    INTO 	p_start_no
		FROM 	av_styles
		WHERE 	av_styles.season = g_style.season 
		AND   	av_styles.class  = g_style.class
		LET p_status = status
		IF p_status = 0 THEN 					#ok
			IF p_start_no IS NOT NULL THEN
				IF (p_start_no > 999 OR p_start_no < 1 ) THEN
					ERROR p_start_no, " Corrupt av_styles table - cannot create style no"
					SLEEP 3
					LET p_retstat = FALSE
				ELSE
					# now make the style
					LET tmpstyle = g_style.season USING "#",
						   		   #R09 g_style.class  USING "&&",
						   		   g_style.class  USING "&&&",				#R09
						    		p_start_no     USING "&&&" 
					LET g_style.style = tmpstyle

					## delete the style to make it unavailable
   		    		DELETE FROM av_styles   
   		    		WHERE av_styles.season = g_style.season
					AND   av_styles.class  = g_style.class
					AND   av_styles.next_avail = p_start_no

					LET p_status = status	
					IF p_status < 0 THEN
						ERROR "Unable to delete last ",g_style.style," - cancelling insert"
						SLEEP 3
						LET p_retstat = FALSE
					ELSE
						DISPLAY BY NAME g_style.style
						ATTRIBUTE(UNDERLINE)
						LET g_style.date_insert = TODAY						#R03
						####################################
						# insert aus style
						####################################
						INSERT INTO style VALUES (g_style.*) 
						LET p_status = status
						IF p_status = -239 THEN		{ ie. duplicate record }
							LET p_text =
								"\nA record with the same key values as",
								"\nthe entered record already exists.",
								"\nThe insert of this record has failed."
								CALL messagebox(p_text,2)				#R02
							LET p_retstat = FALSE
							GOTO endadd									#R05
						END IF
						#R05 >>
						#R12 >>
						####################################
						# insert aus style web categories
						####################################
						LET g_style_webcat.style = g_style.style
						LET g_style_webcat.who = g_user
						LET g_style_webcat.arrival_date = NULL
						LET g_style_webcat.lockdtime = CURRENT
display  "insert web style: ",g_style_webcat.style
						INSERT INTO style_webcat VALUES (g_style_webcat.*) 
						LET p_status = status
						IF p_status = -239 THEN		{ ie. duplicate record }
							LET p_text =
								"\nA record with the same key values as",
								"\nthe entered record already exists.",
								"\nThe insert of this style web cat record has failed. ",g_style_webcat.style
								CALL messagebox(p_text,2)				#R02
							LET p_retstat = FALSE
							GOTO endadd									#R05
						END IF
						#R12 <<
						####################################
						# insert hongkong style
						####################################
						LET g_style.style_desc = g_hk_style_desc
						LET g_style.short_desc = g_hk_short_desc
						LET g_style.supplier = g_hk_supplier
						LET g_style.sup_sty = g_hk_sup_sty
						LET g_style.season = g_hk_season
						LET g_style.division = g_hk_division				#R11
					    LET g_style.class = g_hk_class
						LET g_style.category  = g_hk_category
						LET g_style.unit_cost = g_hk_unit_cost
						LET g_style.unit_sell = g_hk_unit_sell
						LET g_style.orig_sell = g_hk_orig_sell
						LET g_style.lchg_dte = g_hk_lchg_dte
						LET g_style.gst_perc = g_hk_gst_perc
						LET g_style.who = g_user
						LET g_style.fob_method = g_hk_fob_method  #R06
						LET g_style.fob = g_hk_fob 
						LET g_style.fob_cost = g_hk_fob_cost 
						LET g_style.story = g_hk_story            #R06 

display "insert seedhk: ",g_style.style
						INSERT INTO seedhk:style VALUES (g_style.*) 
						LET p_status = status
						IF p_status = -239 THEN		{ ie. duplicate record }
							LET p_text =
								"\nA record with the same key values as",
								"\nthe entered record already exists.",
								"\nThe insert of this HK record has failed."
								CALL messagebox(p_text,2)				#R02
							LET p_retstat = FALSE
							GOTO endadd									#R05
						END IF
						#R05 <<
						#R09 >>
						####################################
						# insert singapore style
						####################################
						LET g_style.style_desc = g_sin_style_desc
						LET g_style.short_desc = g_sin_short_desc
						LET g_style.supplier = g_sin_supplier
						LET g_style.sup_sty = g_sin_sup_sty
						LET g_style.season = g_sin_season
						LET g_style.division = g_sin_division			#R11
					    LET g_style.class = g_sin_class
						LET g_style.category  = g_sin_category
						LET g_style.unit_cost = g_sin_unit_cost
						LET g_style.unit_sell = g_sin_unit_sell
						LET g_style.orig_sell = g_sin_orig_sell
						LET g_style.lchg_dte = g_sin_lchg_dte
						LET g_style.gst_perc = g_sin_gst_perc
						LET g_style.who = g_user
						LET g_style.fob_method = g_sin_fob_method  
						LET g_style.fob = g_sin_fob 
						LET g_style.fob_cost = g_sin_fob_cost 
						LET g_style.story = g_sin_story            

display "insert seedsin: ",g_style.style
						INSERT INTO seedsin:style VALUES (g_style.*) 
						LET p_status = status
						IF p_status = -239 THEN		{ ie. duplicate record }
							LET p_text =
								"\nA record with the same key values as",
								"\nthe entered record already exists.",
								"\nThe insert of this sin record has failed."
								CALL messagebox(p_text,2)				
							LET p_retstat = FALSE
							GOTO endadd									
						END IF
						####################################
						# insert NZ style
						####################################
						LET g_style.style_desc = g_nz_style_desc
						LET g_style.short_desc = g_nz_short_desc
						LET g_style.supplier = g_nz_supplier
						LET g_style.sup_sty = g_nz_sup_sty
						LET g_style.season = g_nz_season
						LET g_style.division = g_nz_division			#R11
					    LET g_style.class = g_nz_class
						LET g_style.category  = g_nz_category
						LET g_style.unit_cost = g_nz_unit_cost
						LET g_style.unit_sell = g_nz_unit_sell
						LET g_style.orig_sell = g_nz_orig_sell
						LET g_style.lchg_dte = g_nz_lchg_dte
						LET g_style.gst_perc = g_nz_gst_perc
						LET g_style.who = g_user
						LET g_style.fob_method = g_nz_fob_method  
						LET g_style.fob = g_nz_fob 
						LET g_style.fob_cost = g_nz_fob_cost 
						LET g_style.story = g_nz_story            

display "insert seednz: ",g_style.style
						INSERT INTO seednz:style VALUES (g_style.*) 
						LET p_status = status
						IF p_status = -239 THEN		{ ie. duplicate record }
							LET p_text =
								"\nA record with the same key values as",
								"\nthe entered record already exists.",
								"\nThe insert of this NZ record has failed."
								CALL messagebox(p_text,2)				
							LET p_retstat = FALSE
							GOTO endadd									
						END IF
						#R09 <<
						#R09 >>
						display "image insert: ",g_image
						IF g_image THEN				
							##########################################
							# "Add web information failed"
							##########################################
							IF NOT sty_entW("INSERT") THEN
								LET p_text = "Add web information failed"
								CALL messagebox(p_text,2)				
								LET p_retstat = FALSE
								GOTO endadd								
							END IF
							LET g_image = FALSE
						END IF
						display "image insertx: ",g_image

						#R09 <<
						#R15 >>
						IF g_video THEN
							IF NOT sty_entW("INSERTV") THEN
								LET p_text = "Add video url information failed"
								CALL messagebox(p_text,2)				
								LET p_retstat = FALSE
								LET g_video = FALSE
								GOTO endadd								
							END IF
							LET g_video = FALSE
						END IF
						display "video insertx: ",g_video
						#R15 <<
					END IF
				END IF
		ELSE
			LET p_text =  "No style nos avail for issue"
			CALL messagebox(p_text,2)				#R02
			LET p_retstat = FALSE
		END IF
	ELSE
		LET p_text =  "No style nos avail for issue"
		CALL messagebox(p_text,2)				#R02
		LET p_retstat = FALSE
	END IF
LABEL endadd:
	#double check added style for all brands
	IF p_retstat THEN
		LET p_count = 0 
		SELECT	COUNT(*)
		INTO	p_count
		FROM	seedhk:style
		WHERE	style = g_style.style
		
		IF p_count = 0 THEN
			LET p_text =  "style does not exist in Hong Kong"
			CALL messagebox(p_text,2)				
			LET p_retstat = FALSE
		ELSE
			LET p_count = 0 
			SELECT	COUNT(*)
			INTO	p_count
			FROM	seedsin:style
			WHERE	style = g_style.style

			IF p_count = 0 THEN
				LET p_text =  "style does not exist in Singapore"
				CALL messagebox(p_text,2)				
				LET p_retstat = FALSE
			ELSE
				LET p_count = 0 
				SELECT	COUNT(*)
				INTO	p_count
				FROM	seednz:style
				WHERE	style = g_style.style
				IF p_count = 0 THEN
					LET p_text =  "style does not exist in NZ"
					CALL messagebox(p_text,2)				
					LET p_retstat = FALSE
				END IF
			END IF
		END IF
	END IF
	#R09 <<
	WHENEVER ERROR STOP									

	WHEN p_mode = "COLOUR"	
		LET p_retstat = TRUE
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO NOT WAIT
		IF sty_entLA() THEN
			LET p_text =
					"style_colour added"
		ELSE
			LET p_text =
					"style_colour added failed"
			LET p_retstat = FALSE
		END IF
		CALL messagebox(p_text,2)				#R02

	WHEN p_mode = "UPDATE"	
		LET p_retstat = TRUE
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO NOT WAIT
		LET g_style.web_desc1 = strip_special_chars(g_style.web_desc1)  #R09
		LET g_style.web_desc2 = strip_special_chars(g_style.web_desc2)  #R09
		LET g_style.web_desc3 = strip_special_chars(g_style.web_desc3)  #R09
		#R01 >>
    	IF g_cost_last_change THEN
        	LET g_style.cost_lchg_date = TODAY
    	END IF
    	#R01 <<
		LET g_style.lchg_dte = TODAY
		LET g_hk_lchg_dte = TODAY
		LET g_sin_lchg_dte = TODAY				#R09
		LET g_nz_lchg_dte = TODAY				#R09
		#################################################################
		# update aus style
		# stock has not been received in into warehouse
		#################################################################
		IF g_first_recv IS NULL THEN		#stock hasnot been received in
			LET g_style.orig_sell   = g_style.unit_sell           
			WHENEVER ERROR CONTINUE
			IF g_opt = "NO" THEN        #change sku selling price by user
				IF sty_entA()  THEN	    #ok
					UPDATE style
					SET	 	style.* = g_style.*
					WHERE	style = g_style.style
					LET p_status = status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
					END IF
				ELSE 
					LET p_retstat = FALSE
				END IF
			ELSE					#change sku selling price by system
				UPDATE style
				SET	 	style.* = g_style.*
				WHERE	style = g_style.style
				LET p_status = status
				IF p_status != 0 THEN
					LET p_retstat = FALSE
				ELSE
            		UPDATE sku
            		SET 	sku.unit_cost  = g_style.unit_cost,
            		 		sku.unit_sell  = g_style.unit_sell
            		WHERE   sku.style      = g_style.style
					LET p_status = status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
					END IF
				END IF
			END IF
		#################################################################
		# update aus style
		# stock has not been received in into warehouse
		#################################################################
		ELSE					#stock has been received in
			UPDATE style
			SET	 	style.* = g_style.*
			WHERE	style = g_style.style
	
			LET p_status = status
			IF p_status != 0 THEN
				LET p_retstat = FALSE
			END IF
		END IF
		###################################################################
		# no syle costing 
		###################################################################
		IF p_retstat THEN
display "WEB CAT: ",g_style_webcat.style," ",g_style_webcat.dw_cat1," ",g_style_webcat.dw_sub_cat1," ",g_style_webcat.dw_ssub_cat1
			#R12 >>
			LET g_style_webcat.who = g_user
			LET g_style_webcat.lockdtime = CURRENT
			UPDATE style_webcat
			SET	 	style_webcat.* = g_style_webcat.*
			WHERE	style = g_style.style

			LET p_status = status
			IF p_status != 0 THEN
				LET p_retstat = FALSE
				GOTO endupd							#R09
			END IF
			IF SQLCA.SQLERRD[3] = 0 THEN        #no row for updating
				LET g_style_webcat.style = g_style.style
				LET g_style_webcat.who = g_user
				LET g_style_webcat.lockdtime = CURRENT
				LET g_style_webcat.arrival_date = NULL
				INSERT INTO style_webcat VALUES (g_style_webcat.*) 
				LET p_status = status
				IF p_status != 0 THEN
display "insert style web cat failed"
					LET p_retstat = FALSE
					GOTO endupd							#R09
				END IF
			END IF 
			#R12 <<
			#R07 >>
			LET p_count2 = 0
			SELECT	COUNT(*)
			INTO	p_count2
			FROM	cost_sheet
			WHERE	style = g_style.style

			IF p_count2 = 0 THEN
display "update AU po_lns here"
				UPDATE po_lns
            	SET     unit_cost = g_style.unit_cost
            	WHERE style = g_style.style
				LET p_status = status
				IF p_status != 0 THEN
					LET p_retstat = FALSE
					GOTO endupd							#R09
				END IF
			END IF
			#R07 <<
			#R09 ELSE
			##########################################
			# still no style costing???
			##########################################
			IF p_retstat THEN						#R09
display "after update AU po_lns here"
				#update unit cost only
           		UPDATE sku
           		SET 	sku.unit_cost  = g_style.unit_cost
           		WHERE   sku.style      = g_style.style
				LET p_status = status
				IF p_status != 0 THEN
					LET p_retstat = FALSE
					GOTO endupd									#R09
				END IF
				#R04 >>
		#		UPDATE	seedhk:style
		#		SET		sup_sty = g_style.sup_sty
		#		WHERE	style = g_style.style
		#		IF p_status != 0 THEN
		#			LET p_retstat = FALSE
		#		END IF
				#R04 <<
			END IF
		END IF
		#R05 >>
		#############################################
		# if okay - them update images
		#############################################
		IF p_retstat THEN
			#R09 >>
			display "update image: ",g_image
			IF g_image THEN
			 	IF NOT sty_entW("UPDATE") THEN
					LET p_text = "Updated web information failed"
					CALL messagebox(p_text,2)				
					LET p_retstat = FALSE
					GOTO endupd								
				END IF
				LET g_image = FALSE
			END IF
			display "update imagex: ",g_image
			#R15 >>
			IF g_video THEN
			 	IF NOT sty_entW("UPDATEV") THEN
					LET p_text = "Updated video url information failed"
					CALL messagebox(p_text,2)				
					LET p_retstat = FALSE
					LET g_video = FALSE
					GOTO endupd								
				END IF
				LET g_video = FALSE
			END IF
			#R15 <<

			#R09 <<
##display "seedhk update", g_style.style
			#LET g_style.style_desc = g_hk_style_desc
			#LET g_style.short_desc = g_hk_short_desc
			#LET g_style.supplier = g_hk_supplier
			#LET g_style.season = g_hk_season
		    #LET g_style.class = g_hk_class
			#LET g_style.category  = g_hk_category
			#LET g_style.unit_cost = g_hk_unit_cost
			#LET g_style.unit_sell = g_hk_unit_sell
			#LET g_style.orig_sell = g_hk_orig_sell
			#LET g_style.lchg_dte = g_hk_lchg_dte
			#LET g_style.gst_perc = g_hk_gst_perc
		
			############################################
			# now update hongkong style
			############################################
			SELECT	*
			FROM	seedhk:style
			WHERE	style = g_style.style

			LET p_status = status

#display "status: ",p_status, status

			##IF p_status != NOTFOUND THEN
			IF p_status = 0 THEN				#found
				#copy skus to seedhk:sku
display "UPDATING HK "
				LET p_count1 = 0 
				SELECT	UNIQUE colour
				FROM 	sku
				WHERE 	style = g_style.style
				AND 	sku NOT IN (SELECT sku from seedhk:sku where style = g_style.style )
				INTO TEMP t_colour
					
				SELECT	count(*)
				INTO	p_count1
				FROM	t_colour

				IF p_count1 > 0 THEN
					INSERT INTO seedhk:sku
					SELECT	*
					FROM 	sku
					WHERE 	style = g_style.style
					AND 	sku NOT IN (SELECT sku from seedhk:sku where style = g_style.style)

					LET p_status = status
					IF p_status != 0 THEN
display "inserting hk sku failed ",p_status
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF

display "updating hk sku"
					UPDATE seedhk:sku
					SET	   unit_cost = g_hk_unit_cost,
							unit_sell = g_hk_unit_sell
					WHERE	style = g_style.style
					AND		colour in (SELECT colour from t_colour)

					LET p_status = status
					IF p_status != 0 THEN
display "updating hk sku failed ",p_status
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF
				END IF 

				DROP TABLE t_colour;
					#R09	
display "found", g_hk_first_recv
				###########################################
				# no stock received in into HK warehouse
				###########################################
				IF g_hk_first_recv IS NULL THEN		#stock hasnot been received in
					LET g_style.orig_sell   = g_style.unit_sell           
					WHENEVER ERROR CONTINUE
					##check for existing skus??, if not found then insert them . copy sku function...
					LET p_count = 0 
					SELECT	COUNT(*)
					INTO	p_count
					FROM	seedhk:sku
					WHERE	style = g_style.style

					IF p_count = 0 then
						INSERT INTO seedhk:sku 
						SELECT	* 
						FROM	sku
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF

						UPDATE seedhk:sku
						SET	   unit_cost = g_hk_unit_cost,
								unit_sell = g_hk_unit_sell
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					END IF 
					IF g_opt = "NO" THEN        #change sku selling price by user
						IF sty_ent1A()  THEN	    #ok
							UPDATE	seedhk:style
					    	SET 	style_desc = g_hk_style_desc,
									short_desc = g_hk_short_desc ,
									supplier = g_hk_supplier ,
									sup_sty = g_hk_sup_sty ,
									season =  g_hk_season,
									division =  g_hk_division,			#R11
		    						class = g_hk_class ,
									category  = g_hk_category ,
									unit_cost = g_hk_unit_cost,
									unit_sell = g_hk_unit_sell,
									orig_sell = g_hk_orig_sell,
			 				    	lchg_dte = g_hk_lchg_dte,
									gst_perc = g_hk_gst_perc ,
                                    fob_method = g_hk_fob_method,  #R06
                                    fob = g_hk_fob,
                                    fob_cost = g_hk_fob_cost,
                                    story = g_hk_story,          #R06
						    		who		 = g_user,
									sup_sty = g_style.sup_sty,
									country_of_origin = g_style.country_of_origin,
									classification = g_style.classification,
									fabric_content = g_style.fabric_content,
									fabric_desc = g_style.fabric_desc,				#R12
									pos_del_flg = g_hk_pos_del_flg					#R10
							WHERE	style = g_style.style
							LET p_status = status
							IF p_status != 0 THEN
								LET p_retstat = FALSE
								GOTO endupd									#R09
							END IF
						ELSE 
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					ELSE					#change sku selling price by system
						UPDATE	seedhk:style
				   		 SET 	style_desc = g_hk_style_desc,
								short_desc = g_hk_short_desc ,
								supplier = g_hk_supplier ,
								sup_sty = g_hk_sup_sty ,
								season =  g_hk_season,
								division =  g_hk_division,			#R11
		    					class = g_hk_class ,
								category  = g_hk_category ,
								unit_cost = g_hk_unit_cost,
								unit_sell = g_hk_unit_sell,
								orig_sell = g_hk_orig_sell,
			 				    lchg_dte = g_hk_lchg_dte,
								gst_perc = g_hk_gst_perc ,
                                fob_method = g_hk_fob_method,  #R06
                                fob = g_hk_fob,
                                fob_cost = g_hk_fob_cost,
                                story = g_hk_story,          #R06
						    	who		 = g_user,
								sup_sty = g_style.sup_sty,
								country_of_origin = g_style.country_of_origin,
							    classification = g_style.classification,
								fabric_content = g_style.fabric_content,
								fabric_desc = g_style.fabric_desc,				#R12
								pos_del_flg = g_hk_pos_del_flg					#R10
						WHERE	style = g_style.style
						LET p_status = status
						IF p_status != 0 THEN
##display "style failed"
							LET p_retstat = FALSE
							GOTO endupd									#R09
						ELSE
            				UPDATE seedhk:sku
            				SET 	unit_cost  = g_hk_unit_cost,
            		 				unit_sell  = g_hk_unit_sell
            				WHERE   style      = g_style.style
							LET p_status = status
							IF p_status != 0 THEN
##display "sku failed"
								LET p_retstat = FALSE
								GOTO endupd									#R09
							END IF
						END IF
					END IF
				ELSE					#stock has been received in
##display "update seedhk style here"
					UPDATE	seedhk:style
			   		 SET 	style_desc = g_hk_style_desc,
							short_desc = g_hk_short_desc ,
							supplier = g_hk_supplier ,
							sup_sty = g_hk_sup_sty ,
							season =  g_hk_season,
							division =  g_hk_division,			#R11
		   					class = g_hk_class ,
							category  = g_hk_category ,
							unit_cost = g_hk_unit_cost,
							unit_sell = g_hk_unit_sell,
							orig_sell = g_hk_orig_sell,
						    lchg_dte = g_hk_lchg_dte,
							gst_perc = g_hk_gst_perc ,
                            fob_method = g_hk_fob_method,  #R06
                            fob = g_hk_fob,
                            fob_cost = g_hk_fob_cost,
                            story = g_hk_story,          #R06
						    who		 = g_user,
							sup_sty = g_style.sup_sty,
							country_of_origin = g_style.country_of_origin,
						    classification = g_style.classification,
							fabric_content = g_style.fabric_content,
							fabric_desc = g_style.fabric_desc,				#R12
							pos_del_flg = g_hk_pos_del_flg					#R10
					WHERE	style = g_style.style
					LET p_status = status
##display "failed: ",p_status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF
				END IF
				IF p_retstat THEn
					#R07 >>
display "update HK po_lns here"
					LET p_count2 = 0
					SELECT	COUNT(*)
					INTO	p_count2
					FROM	seedhk:cost_sheet
					WHERE	style = g_style.style

					IF p_count2 = 0 THEN
						UPDATE seedhk:po_lns
   		         		SET     unit_cost = g_hk_unit_cost
   		         		WHERE 	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd							#R09
						END IF
					END IF
					#R07 <<
					#R09 ELSE
					IF p_retstat THEN
display "after update HK po_lns here"
						#update unit cost only
           				UPDATE  seedhk:sku
           				SET 	unit_cost  = g_hk_unit_cost
           				WHERE   style      = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
						UPDATE	seedhk:style
						SET		sup_sty = g_hk_sup_sty,
								country_of_origin = g_style.country_of_origin,
								classification = g_style.classification,
								fabric_content = g_style.fabric_content,
								fabric_desc = g_style.fabric_desc					#R12
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					END IF
				END IF
			END IF
			#R09 >>
			#singapore
			SELECT	*
			FROM	seedsin:style
			WHERE	style = g_style.style

			LET p_status = status

#display "status: ",p_status, status
display "UPDATING SINGAPORE"
			##IF p_status != NOTFOUND THEN
			IF p_status = 0 THEN				#found
				#copy skus to seedsin:sku
				LET p_count1 = 0 
				SELECT	UNIQUE colour
				FROM 	sku
				WHERE 	style = g_style.style
				AND 	sku NOT IN (SELECT sku from seedsin:sku where style = g_style.style )
				INTO TEMP t_colour
					
				SELECT	count(*)
				INTO	p_count1
				FROM	t_colour

				IF p_count1 > 0 THEN
					INSERT INTO seedsin:sku
					SELECT	*
					FROM 	sku
					WHERE 	style = g_style.style
					AND 	sku NOT IN (SELECT sku from seedsin:sku where style = g_style.style)

					LET p_status = status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF

					UPDATE seedsin:sku
					SET	   unit_cost = g_sin_unit_cost,
							unit_sell = g_sin_unit_sell
					WHERE	style = g_style.style
					AND		colour in (SELECT colour from t_colour)

					LET p_status = status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF
				END IF 
				DROP TABLE t_colour;
					#R09	
##display "found", g_sin_first_recv
				IF g_sin_first_recv IS NULL THEN		#stock hasnot been received in
					LET g_style.orig_sell   = g_style.unit_sell           
					WHENEVER ERROR CONTINUE
					##check for existing skus??, if not found then insert them . copy sku function...
					LET p_count = 0 
					SELECT	COUNT(*)
					INTO	p_count
					FROM	seedsin:sku
					WHERE	style = g_style.style

					IF p_count = 0 then
						INSERT INTO seedsin:sku 
						SELECT	* 
						FROM	sku
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF

						UPDATE seedsin:sku
						SET	   unit_cost = g_sin_unit_cost,
								unit_sell = g_sin_unit_sell
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					END IF 
					IF g_opt = "NO" THEN        #change sku selling price by user
						IF sty_ent2A()  THEN	    #ok
							UPDATE	seedsin:style
					    	SET 	style_desc = g_sin_style_desc,
									short_desc = g_sin_short_desc ,
									supplier = g_sin_supplier ,
									sup_sty = g_sin_sup_sty ,
									season =  g_sin_season,
									division =  g_sin_division,		#R11
		    						class = g_sin_class ,
									category  = g_sin_category ,
									unit_cost = g_sin_unit_cost,
									unit_sell = g_sin_unit_sell,
									orig_sell = g_sin_orig_sell,
			 				    	lchg_dte = g_sin_lchg_dte,
									gst_perc = g_sin_gst_perc ,
                                    fob_method = g_sin_fob_method,  #R06
                                    fob = g_sin_fob,
                                    fob_cost = g_sin_fob_cost,
                                    story = g_sin_story,          #R06
						    		who		 = g_user,
									sup_sty = g_style.sup_sty,
									country_of_origin = g_style.country_of_origin,
									classification = g_style.classification,
									fabric_content = g_style.fabric_content,
									fabric_desc = g_style.fabric_desc					#R12
							WHERE	style = g_style.style
							LET p_status = status
							IF p_status != 0 THEN
								LET p_retstat = FALSE
								GOTO endupd									#R09
							END IF
						ELSE 
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					ELSE					#change sku selling price by system
						UPDATE	seedsin:style
				   		 SET 	style_desc = g_sin_style_desc,
								short_desc = g_sin_short_desc ,
								supplier = g_sin_supplier ,
								sup_sty = g_sin_sup_sty ,
								season =  g_sin_season,
								division =  g_sin_division,			#R11
		    					class = g_sin_class ,
								category  = g_sin_category ,
								unit_cost = g_sin_unit_cost,
								unit_sell = g_sin_unit_sell,
								orig_sell = g_sin_orig_sell,
			 				    lchg_dte = g_sin_lchg_dte,
								gst_perc = g_sin_gst_perc ,
                                fob_method = g_sin_fob_method,  #R06
                                fob = g_sin_fob,
                                fob_cost = g_sin_fob_cost,
                                story = g_sin_story,          #R06
						    	who		 = g_user,
								sup_sty = g_style.sup_sty,
								country_of_origin = g_style.country_of_origin,
							    classification = g_style.classification,
								fabric_content = g_style.fabric_content,
								fabric_desc = g_style.fabric_desc					#R12
						WHERE	style = g_style.style
						LET p_status = status
						IF p_status != 0 THEN
##display "style failed"
							LET p_retstat = FALSE
							GOTO endupd									#R09
						ELSE
            				UPDATE seedsin:sku
            				SET 	unit_cost  = g_sin_unit_cost,
            		 				unit_sell  = g_sin_unit_sell
            				WHERE   style      = g_style.style
							LET p_status = status
							IF p_status != 0 THEN
##display "sku failed"
								LET p_retstat = FALSE
								GOTO endupd									#R09
							END IF
						END IF
					END IF
				ELSE					#stock has been received in
##display "update seedsin style here"
					UPDATE	seedsin:style
			   		 SET 	style_desc = g_sin_style_desc,
							short_desc = g_sin_short_desc ,
							supplier = g_sin_supplier ,
							sup_sty = g_sin_sup_sty ,
							season =  g_sin_season,
							division =  g_sin_division,			#R11
		   					class = g_sin_class ,
							category  = g_sin_category ,
							unit_cost = g_sin_unit_cost,
							unit_sell = g_sin_unit_sell,
							orig_sell = g_sin_orig_sell,
						    lchg_dte = g_sin_lchg_dte,
							gst_perc = g_sin_gst_perc ,
                            fob_method = g_sin_fob_method,  #R06
                            fob = g_sin_fob,
                            fob_cost = g_sin_fob_cost,
                            story = g_sin_story,          #R06
						    who		 = g_user,
							sup_sty = g_style.sup_sty,
							country_of_origin = g_style.country_of_origin,
						    classification = g_style.classification,
							fabric_content = g_style.fabric_content,
							fabric_desc = g_style.fabric_desc					#R12
					WHERE	style = g_style.style
					LET p_status = status
##display "failed: ",p_status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF
				END IF
				IF p_retstat THEn
					#R07 >>
display "update sin po_lns here"
					LET p_count2 = 0
					SELECT	COUNT(*)
					INTO	p_count2
					FROM	seedsin:cost_sheet
					WHERE	style = g_style.style

					IF p_count2 = 0 THEN
						UPDATE seedsin:po_lns
   		         		SET     unit_cost = g_sin_unit_cost
   		         		WHERE 	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd							#R09
						END IF
					END IF
					#R07 <<
					#R09 ELSE
					IF p_retstat THEN
display "after update sin po_lns here"
						#update unit cost only
           				UPDATE  seedsin:sku
           				SET 	unit_cost  = g_sin_unit_cost
           				WHERE   style      = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
						UPDATE	seedsin:style
						SET		sup_sty = g_sin_sup_sty,
								country_of_origin = g_style.country_of_origin,
								classification = g_style.classification,
								fabric_content = g_style.fabric_content,
								fabric_desc = g_style.fabric_desc						#R12
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
	#						GOTO endupd									#R09
						END IF
					END IF
				END IF
			END IF
			#NZ
			SELECT	*
			FROM	seednz:style
			WHERE	style = g_style.style

			LET p_status = status

#display "status: ",p_status, status
display "UPDATING NZ"
			##IF p_status != NOTFOUND THEN
			IF p_status = 0 THEN				#found
				#R12 >>
				#IF g_nz_unit_cost IS NULL 
				#OR g_nz_unit_cost = 0 THEN
					#LET p_text = "\nNZ cost is 0",
								 #"Failed to update NZ style ",g_style.style
					#CALL messagebox(p_text,2)				#R02
					#CALL sty_entLG("u")
					#LET p_retstat = FALSE
					#GOTO endupd									#R09
				#END IF
				IF g_nz_unit_sell IS NULL 
				OR g_nz_unit_sell = 0 THEN
					LET p_text = "\nNZ price is 0",
								 "\nFailed to update NZ style ",g_style.style,
								"\nPlease contact I.T"
					CALL messagebox(p_text,2)				#R02
					LET p_retstat = FALSE
					GOTO endupd									#R09
				END IF
				#R12 <<

				#copy skus to seednz:sku
				LET p_count1 = 0 
				SELECT	UNIQUE colour
				FROM 	sku
				WHERE 	style = g_style.style
				AND 	sku NOT IN (SELECT sku from seednz:sku where style = g_style.style )
				INTO TEMP t_colour
					
				SELECT	count(*)
				INTO	p_count1
				FROM	t_colour

				IF p_count1 > 0 THEN
					INSERT INTO seednz:sku
					SELECT	*
					FROM 	sku
					WHERE 	style = g_style.style
					AND 	sku NOT IN (SELECT sku from seednz:sku where style = g_style.style)

					LET p_status = status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF

					UPDATE seednz:sku
					SET	   unit_cost = g_nz_unit_cost,
							unit_sell = g_nz_unit_sell
					WHERE	style = g_style.style
					AND		colour in (SELECT colour from t_colour)

					LET p_status = status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF
				END IF 
				DROP TABLE t_colour;
					#R09	
##display "found", g_nz_first_recv
				IF g_nz_first_recv IS NULL THEN		#stock hasnot been received in
					LET g_style.orig_sell   = g_style.unit_sell           
					WHENEVER ERROR CONTINUE
					##check for existing skus??, if not found then insert them . copy sku function...
					LET p_count = 0 
					SELECT	COUNT(*)
					INTO	p_count
					FROM	seednz:sku
					WHERE	style = g_style.style

					IF p_count = 0 then
						INSERT INTO seednz:sku 
						SELECT	* 
						FROM	sku
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF

						UPDATE seednz:sku
						SET	   unit_cost = g_nz_unit_cost,
								unit_sell = g_nz_unit_sell
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					END IF 
					IF g_opt = "NO" THEN        #change sku selling price by user
						IF sty_ent3A()  THEN	    #ok
							UPDATE	seednz:style
					    	SET 	style_desc = g_nz_style_desc,
									short_desc = g_nz_short_desc ,
									supplier = g_nz_supplier ,
									sup_sty = g_nz_sup_sty ,
									season =  g_nz_season,
									division =  g_nz_division,			#R11
		    						class = g_nz_class ,
									category  = g_nz_category ,
									unit_cost = g_nz_unit_cost,
									unit_sell = g_nz_unit_sell,
									orig_sell = g_nz_orig_sell,
			 				    	lchg_dte = g_nz_lchg_dte,
									gst_perc = g_nz_gst_perc ,
                                    fob_method = g_nz_fob_method,  #R06
                                    fob = g_nz_fob,
                                    fob_cost = g_nz_fob_cost,
                                    story = g_nz_story,          #R06
						    		who		 = g_user,
									sup_sty = g_style.sup_sty,
									country_of_origin = g_style.country_of_origin,
									classification = g_style.classification,
									fabric_content = g_style.fabric_content,
									fabric_desc = g_style.fabric_desc					#R12
							WHERE	style = g_style.style
							LET p_status = status
							IF p_status != 0 THEN
								LET p_retstat = FALSE
								GOTO endupd									#R09
							END IF
						ELSE 
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
					ELSE					#change sku selling price by system
						UPDATE	seednz:style
				   		 SET 	style_desc = g_nz_style_desc,
								short_desc = g_nz_short_desc ,
								supplier = g_nz_supplier ,
								sup_sty = g_nz_sup_sty ,
								season =  g_nz_season,
								division =  g_nz_division,			#R11
		    					class = g_nz_class ,
								category  = g_nz_category ,
								unit_cost = g_nz_unit_cost,
								unit_sell = g_nz_unit_sell,
								orig_sell = g_nz_orig_sell,
			 				    lchg_dte = g_nz_lchg_dte,
								gst_perc = g_nz_gst_perc ,
                                fob_method = g_nz_fob_method,  #R06
                                fob = g_nz_fob,
                                fob_cost = g_nz_fob_cost,
                                story = g_nz_story,          #R06
						    	who		 = g_user,
								sup_sty = g_style.sup_sty,
								country_of_origin = g_style.country_of_origin,
							    classification = g_style.classification,
								fabric_content = g_style.fabric_content,
								fabric_desc = g_style.fabric_desc					#R12
						WHERE	style = g_style.style
						LET p_status = status
						IF p_status != 0 THEN
##display "style failed"
							LET p_retstat = FALSE
							GOTO endupd									#R09
						ELSE
            				UPDATE seednz:sku
            				SET 	unit_cost  = g_nz_unit_cost,
            		 				unit_sell  = g_nz_unit_sell
            				WHERE   style      = g_style.style
							LET p_status = status
							IF p_status != 0 THEN
##display "sku failed"
								LET p_retstat = FALSE
								GOTO endupd									#R09
							END IF
						END IF
					END IF
				ELSE					#stock has been received in
##display "update seednz style here"
					UPDATE	seednz:style
			   		 SET 	style_desc = g_nz_style_desc,
							short_desc = g_nz_short_desc ,
							supplier = g_nz_supplier ,
							sup_sty = g_nz_sup_sty ,
							season =  g_nz_season,
							division =  g_nz_division,			#R11
		   					class = g_nz_class ,
							category  = g_nz_category ,
							unit_cost = g_nz_unit_cost,
							unit_sell = g_nz_unit_sell,
							orig_sell = g_nz_orig_sell,
						    lchg_dte = g_nz_lchg_dte,
							gst_perc = g_nz_gst_perc ,
                            fob_method = g_nz_fob_method,  #R06
                            fob = g_nz_fob,
                            fob_cost = g_nz_fob_cost,
                            story = g_nz_story,          #R06
						    who		 = g_user,
							sup_sty = g_style.sup_sty,
							country_of_origin = g_style.country_of_origin,
						    classification = g_style.classification,
							fabric_content = g_style.fabric_content,
							fabric_desc = g_style.fabric_desc					#R12
					WHERE	style = g_style.style
					LET p_status = status
##display "failed: ",p_status
					IF p_status != 0 THEN
						LET p_retstat = FALSE
						GOTO endupd									#R09
					END IF
				END IF
				IF p_retstat THEn
					#R07 >>
display "update nz po_lns here"
					LET p_count2 = 0
					SELECT	COUNT(*)
					INTO	p_count2
					FROM	seednz:cost_sheet
					WHERE	style = g_style.style

					IF p_count2 = 0 THEN
						UPDATE seednz:po_lns
   		         		SET     unit_cost = g_nz_unit_cost
   		         		WHERE 	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd							#R09
						END IF
					END IF
					#R07 <<
					#R09 ELSE
					IF p_retstat THEN
display "after update nz po_lns here"
						#update unit cost only
           				UPDATE  seednz:sku
           				SET 	unit_cost  = g_nz_unit_cost
           				WHERE   style      = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
							GOTO endupd									#R09
						END IF
						UPDATE	seednz:style
						SET		sup_sty = g_nz_sup_sty,
								country_of_origin = g_style.country_of_origin,
								classification = g_style.classification,
								fabric_content = g_style.fabric_content,
								fabric_desc = g_style.fabric_desc					#R12
						WHERE	style = g_style.style

						LET p_status = status
						IF p_status != 0 THEN
							LET p_retstat = FALSE
	#						GOTO endupd									#R09
						END IF
					END IF
				END IF
			END IF
		END IF 
LABEL endupd:							#R09
		WHENEVER ERROR STOP

	WHEN p_mode = "COPY"
		LET p_retstat=TRUE
		#copystyle
		INITIALIZE p_style.* TO NULL
		LET p_style.* = g_style.*
		LET p_style.style_desc = g_hk_style_desc
		LET p_style.short_desc = g_hk_short_desc
		LET p_style.supplier = g_hk_supplier
		LET p_style.sup_sty = g_hk_sup_sty
		LET p_style.season = g_hk_season
		LET p_style.division = g_hk_division				#R11
		LET p_style.class = g_hk_class
		LET p_style.category  = g_hk_category
		LET p_style.unit_cost = g_hk_unit_cost
		LET p_style.unit_sell = g_hk_unit_sell
		LET p_style.orig_sell = g_hk_orig_sell
		LET p_style.lchg_dte = g_hk_lchg_dte
		LET p_style.gst_perc = g_hk_gst_perc
		LET p_style.fob_method = g_hk_fob_method  #R06
		LET p_style.fob = g_hk_fob
		LET p_style.fob_cost = g_hk_fob_cost
		LET p_style.story = g_hk_story          #R06
		LET p_style.who = g_user
		LET p_style.pos_del_flg = NULL			#R10

		INSERT INTO seedhk:style VALUES (p_style.*)
		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
			GOTO endcopy
		END IF

		DELETE  
		FROM	seedhk:sku
		WHERE	style = g_style.style

		INSERT 	INTO seedhk:sku 
		SELECT * 
		FROM	sku
		WHERE	style = g_style.style

		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
			GOTO endcopy
		END IF
	
		UPDATE	seedhk:sku
		SET		unit_cost = p_style.unit_cost ,
				unit_sell = p_style.unit_sell,
				date_first_receipt = NULL
		WHERE	style  = g_style.style
		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
			GOTO endcopy
		END IF
##display "end: ",p_retstat
LABEL endcopy:
	#R09 >>
	WHEN p_mode = "COPYSIN"
		#copystyle
		INITIALIZE p_style.* TO NULL
		LET p_style.* = g_style.*
		LET p_style.style_desc = g_sin_style_desc
		LET p_style.short_desc = g_sin_short_desc
		LET p_style.supplier = g_sin_supplier
		LET p_style.sup_sty = g_sin_sup_sty
		LET p_style.season = g_sin_season
		LET p_style.division = g_sin_division			#R11
		LET p_style.class = g_sin_class
		LET p_style.category  = g_sin_category
		LET p_style.unit_cost = g_sin_unit_cost
		LET p_style.ledger_cost = g_sin_unit_cost
		LET p_style.unit_sell = g_sin_unit_sell
		LET p_style.prev_sell = NULL
		LET p_style.orig_sell = g_sin_orig_sell
		LET p_style.lchg_dte = g_sin_lchg_dte
		LET p_style.gst_perc = g_sin_gst_perc
display "copy sin: ",g_sin_fob_method," ",g_sin_fob
		LET p_style.fob_method = g_sin_fob_method  #R06
		LET p_style.fob = g_sin_fob
		LET p_style.fob_cost = g_sin_fob_cost
		LET p_style.story = g_sin_story          #R06
		LET p_style.who = g_user
	    LET p_style.cost_lchg_date  = NULL
        LET p_style.ledger_cost  = NULL

		INSERT INTO seedsin:style VALUES (p_style.*)
		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
			GOTO endcopyx
		END IF

		DELETE FROM seedsin:sku 
		WHERE	style = g_style.style

		INSERT 	INTO seedsin:sku 
		SELECT * 
		FROM	sku
		WHERE	style = g_style.style

		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
		END IF
	
		UPDATE	seedsin:sku
		SET		unit_cost = p_style.unit_cost ,
				unit_sell = p_style.unit_sell
		WHERE	style  = g_style.style
		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
		END IF
LABEL endcopyx:							#R09
	#R09 >>
	WHEN p_mode = "COPYNZ"
		#copystyle
		INITIALIZE p_style.* TO NULL
		LET p_style.* = g_style.*
		LET p_style.style_desc = g_nz_style_desc
		LET p_style.short_desc = g_nz_short_desc
		LET p_style.supplier = g_nz_supplier
		LET p_style.sup_sty = g_nz_sup_sty
		LET p_style.season = g_nz_season
		LET p_style.division = g_nz_division			#R11
		LET p_style.class = g_nz_class
		LET p_style.category  = g_nz_category
		LET p_style.unit_cost = g_nz_unit_cost
		LET p_style.ledger_cost = g_nz_unit_cost
		LET p_style.unit_sell = g_nz_unit_sell
		LET p_style.prev_sell = NULL
		LET p_style.orig_sell = g_nz_orig_sell
		LET p_style.lchg_dte = g_nz_lchg_dte
		LET p_style.gst_perc = g_nz_gst_perc
display "copy nz: ",g_nz_fob_method," ",g_nz_fob
		LET p_style.fob_method = g_nz_fob_method  #R06
		LET p_style.fob = g_nz_fob
		LET p_style.fob_cost = g_nz_fob_cost
		LET p_style.story = g_nz_story          #R06
		LET p_style.who = g_user
	    LET p_style.cost_lchg_date  = NULL
        LET p_style.ledger_cost  = NULL

		INSERT INTO seednz:style VALUES (p_style.*)
		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
			GOTO endcopynz
		END IF

		DELETE FROM seednz:sku 
		WHERE	style = g_style.style

		INSERT 	INTO seednz:sku 
		SELECT * 
		FROM	sku
		WHERE	style = g_style.style

		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
		END IF
	
		UPDATE	seednz:sku
		SET		unit_cost = p_style.unit_cost ,
				unit_sell = p_style.unit_sell,
				date_first_receipt = NULL
		WHERE	style  = g_style.style
		LET p_status = status
		IF p_status != 0 THEN
			LET p_retstat = FALSE
		END IF
LABEL endcopynz:							#R09

	WHEN p_mode = "LOCK"
		LET p_retstat=FALSE
		LET p_query=
			" SELECT	who,lockdtime ",
			" FROM		style ",
			" WHERE		style = ","\"",g_style.style,"\""
		PREPARE s_lock FROM p_query
		DECLARE c_lock CURSOR FOR s_lock
		OPEN c_lock
		FETCH c_lock INTO p_who,s_lockdtime
		LET p_status=status
		CLOSE c_lock
display "lock: ", s_lockdtime
		CASE
		WHEN p_status=0
			IF s_lockdtime IS NULL THEN
				LET p_who = g_user
				LET p_lockdtime=CURRENT
				UPDATE style
				SET		who=p_who
				,		lockdtime=p_lockdtime
				WHERE	style=g_style.style
				IF status=0 THEN
					LET p_retstat=TRUE
				END IF
			ELSE
		 		LET p_text =
                            "\nThis record is currently in use by ",p_who CLIPPED,
                            "\nThis user has been using this record",
                            "\nsince ",s_lockdtime,
							"\nTo unlock this record,see MIS for help "
							CALL messagebox(p_text,2)				#R02
					LET p_retstat =FALSE
			END IF
		OTHERWISE
			LEt p_retstat=TRUE
		END	CASE
	
	WHEN p_mode="UNLOCK"		
		#this logic exists when the user abort UPDATE,DELETE
		LET p_retstat=FALSE
		LET p_query=
			" SELECT	who,lockdtime ",
			" FROM		style ",
			" WHERE		style = ","\"",g_style.style,"\""
		PREPARE s_unlock FROM p_query
		DECLARE c_unlock CURSOR FOR s_unlock
		OPEN c_unlock
		FETCH c_unlock INTO p_who,p_lockdtime
		LET p_status=status
		CLOSE c_unlock
		CASE
		WHEN p_status=0
			UPDATE style
			SET		who = g_user,
					lockdtime = NULL
			WHERE	style = g_style.style
			AND		lockdtime = p_lockdtime
			AND		who = g_user
			LET p_retstat = TRUE
		OTHERWISE
			LET p_retstat = TRUE
		END CASE
	END CASE
		
	IF p_retstat AND
	(p_mode = "CURRENT" OR p_mode = "NEXT" or p_mode = "PRIOR"
	 OR p_mode = "FIRST" OR p_mode = "LAST"
	 OR p_mode = "LOCK" OR p_mode = "UNLOCK")
	THEN    
		DECLARE	c_fetch	CURSOR FOR
		SELECT	*
		FROM	style
		WHERE	style = g_style.style

		OPEN c_fetch
		FETCH c_fetch INTO g_style.*
		IF status = NOTFOUND THEN
			{re-select }
			MESSAGE "error - record has changed..."
			LET p_redo = p_mode
			LET p_mode = "INIT"
			GOTO redo
		END IF
		#R05 >>
		LET g_hk_style_desc = NULL
        LET g_hk_short_desc = NULL
        LET g_hk_supplier = NULL
        LET g_hk_sup_sty = NULL
        LET g_hk_season = NULL
        LET g_hk_division = NULL			#R11
        LET g_hk_class = NULL
        LET g_hk_category = NULL
        LET g_hk_unit_cost = NULL
        LET g_hk_unit_sell = NULL
        LET g_hk_orig_sell = NULL
        LET g_hk_lchg_dte = NULL
        LET g_hk_gst_perc = NULL
        LET g_hk_fob_method = NULL  #R06
        LET g_hk_fob = NULL
        LET g_hk_fob_cost = NULL
        LET g_hk_story = NULL      #R06

		SELECT	seedhk:style.style_desc,
				seedhk:style.short_desc,
				seedhk:style.supplier,
				seedhk:style.sup_sty,
				seedhk:style.season,
				seedhk:style.division,			#R11
				seedhk:style.class,
				seedhk:style.category,
				seedhk:style.unit_cost,
				seedhk:style.unit_sell,
				seedhk:style.orig_sell,
				seedhk:style.lchg_dte,
				seedhk:style.gst_perc,
				seedhk:style.fob_method, #R06
				seedhk:style.fob,
				seedhk:style.fob_cost,
				seedhk:style.story, 		#R06
				seedhk:style.pos_del_flg	#R10
		INTO
			g_hk_style_desc,
			g_hk_short_desc,
			g_hk_supplier,
			g_hk_sup_sty,
			g_hk_season,
			g_hk_division,				#R11
			g_hk_class,	
			g_hk_category,
			g_hk_unit_cost,
			g_hk_unit_sell,
			g_hk_orig_sell,
			g_hk_lchg_dte,
			g_hk_gst_perc,
			g_hk_fob_method,        #R06
			g_hk_fob,
			g_hk_fob_cost,
			g_hk_story,              #R06
			g_hk_pos_del_flg         #R10

		FROM	seedhk:style
        WHERE 	seedhk:style.style = g_style.style
##display "here: ", g_hk_unit_sell," ", g_hk_unit_cost, " ",g_hk_orig_sell, " ",g_style.style

		#R09 >>
		LET g_sin_style_desc = NULL
        LET g_sin_short_desc = NULL
        LET g_sin_supplier = NULL
        LET g_sin_sup_sty = NULL
        LET g_sin_season = NULL
        LET g_sin_division = NULL			#R11
        LET g_sin_class = NULL
        LET g_sin_category = NULL
        LET g_sin_unit_cost = NULL
        LET g_sin_unit_sell = NULL
        LET g_sin_orig_sell = NULL
        LET g_sin_lchg_dte = NULL
        LET g_sin_gst_perc = NULL
        LET g_sin_fob_method = NULL  #R06
        LET g_sin_fob = NULL
        LET g_sin_fob_cost = NULL
        LET g_sin_story = NULL      #R06

		SELECT	seedsin:style.style_desc,
				seedsin:style.short_desc,
				seedsin:style.supplier,
				seedsin:style.sup_sty,
				seedsin:style.season,
				seedsin:style.division,			#R11
				seedsin:style.class,
				seedsin:style.category,
				seedsin:style.unit_cost,
				seedsin:style.unit_sell,
				seedsin:style.orig_sell,
				seedsin:style.lchg_dte,
				seedsin:style.gst_perc,
				seedsin:style.fob_method, #R06
				seedsin:style.fob,
				seedsin:style.fob_cost,
				seedsin:style.story 		#R06
		INTO
			g_sin_style_desc,
			g_sin_short_desc,
			g_sin_supplier,
			g_sin_sup_sty,
			g_sin_season,
			g_sin_division,			#R11
			g_sin_class,	
			g_sin_category,
			g_sin_unit_cost,
			g_sin_unit_sell,
			g_sin_orig_sell,
			g_sin_lchg_dte,
			g_sin_gst_perc,
			g_sin_fob_method,        #R06
			g_sin_fob,
			g_sin_fob_cost,
			g_sin_story              #R06

		FROM	seedsin:style
        WHERE 	seedsin:style.style = g_style.style
		#NZ
		#R09 >>
		LET g_nz_style_desc = NULL
        LET g_nz_short_desc = NULL
        LET g_nz_supplier = NULL
        LET g_nz_sup_sty = NULL
        LET g_nz_season = NULL
        LET g_nz_division = NULL			#R11
        LET g_nz_class = NULL
        LET g_nz_category = NULL
        LET g_nz_unit_cost = NULL
        LET g_nz_unit_sell = NULL
        LET g_nz_orig_sell = NULL
        LET g_nz_lchg_dte = NULL
        LET g_nz_gst_perc = NULL
        LET g_nz_fob_method = NULL  #R06
        LET g_nz_fob = NULL
        LET g_nz_fob_cost = NULL
        LET g_nz_story = NULL      #R06

		SELECT	seednz:style.style_desc,
				seednz:style.short_desc,
				seednz:style.supplier,
				seednz:style.sup_sty,
				seednz:style.season,
				seednz:style.division,			#R11
				seednz:style.class,
				seednz:style.category,
				seednz:style.unit_cost,
				seednz:style.unit_sell,
				seednz:style.orig_sell,
				seednz:style.lchg_dte,
				seednz:style.gst_perc,
				seednz:style.fob_method, #R06
				seednz:style.fob,
				seednz:style.fob_cost,
				seednz:style.story 		#R06
		INTO
			g_nz_style_desc,
			g_nz_short_desc,
			g_nz_supplier,
			g_nz_sup_sty,
			g_nz_season,
			g_nz_division,			#R11
			g_nz_class,	
			g_nz_category,
			g_nz_unit_cost,
			g_nz_unit_sell,
			g_nz_orig_sell,
			g_nz_lchg_dte,
			g_nz_gst_perc,
			g_nz_fob_method,        #R06
			g_nz_fob,
			g_nz_fob_cost,
			g_nz_story              #R06

		FROM	seednz:style
        WHERE 	seednz:style.style = g_style.style
		#R09 <<
		#R12 >>
		SELECT	*
		INTO	g_style_webcat.*
		FROM	style_webcat
		WHERE	style = g_style.style
		#R12 <<

		LET g_void = sty_entW("INIT")           #R09
        LET g_void = sty_entW("SELECT")         #R09
        LET g_void = sty_entW("BROWSE")         #R09
        LET g_void = sty_entW("BROWSEV")        #R15
        LET g_void = sty_entW("SELECTX")        #R09
        #R13 LET g_void = sty_entW("BROWSEX")        #R09
        LET g_void = sty_entW("DWBROWSEX")      #R12
        LET g_void = sty_entW("HKBROWSEX")      #R13
        LET g_void = sty_entW("SGBROWSEX")      #R13
		CALL sty_entX()						
		CLOSE c_fetch
	END IF
	
	IF p_mode = "UPDATE" OR p_mode= "INSERT" OR p_mode = "DELETE" OR p_mode = "LOCK" OR p_mode = "UNLOCK" OR p_mode = "COLOUR" 
	OR p_mode = "COPY" OR p_mode = "COPYSIN" OR p_mode = "COPYNZ" THEN
		IF p_retstat THEN
			COMMIT WORK
		ELSE
			ROLLBACK WORK
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@@@@ (sty_entI) @@@@@@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	close_cursor - close cursor
################################################################################
FUNCTION close_cursor()
	CLOSE c_set
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@@@@ (close_cursor) @@@@@@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	sty_entLG - write to log table
################################################################################
FUNCTION sty_entLG(p_change)
	DEFINE
			p_change			CHAR(2),
#R07 		p_stylelg			RECORD LIKE stylelg.*
			p_stylelg			RECORD LIKE stylelg1.*			#R07 

display "start log", g_style.style
	# Do AU log here
	#R07 >>
	INITIALIZE p_stylelg.* TO NULL
	SELECT	*
	INTO	p_stylelg.*
	FROM	style
	WHERE	style = g_style.style

	LET p_stylelg.style  =g_style.style
	LET p_stylelg.fob_cost  =g_prev_unit_sell				#rxx before the unit sell was
	#R14 LET p_stylelg.who =  fgl_getenv("LOGNAME")
	LET p_stylelg.who =  g_user		#R14
	LET p_stylelg.lockdtime  =CURRENT						#R07
	IF p_change = "u" THEN								#R07
		LET p_stylelg.pos_del_flg = "u"					#R07
	ELSE												#R07
		LET p_stylelg.pos_del_flg = "a"					#R07
	END IF												#R07
	INSERT INTO stylelg1 VALUES (p_stylelg.*) 
	# Do HK log here
	INITIALIZE p_stylelg.* TO NULL
	SELECT	*
	INTO	p_stylelg.*
	FROM	seedhk:style
	WHERE	style = g_style.style

	if status != notfound then
		LET p_stylelg.fob_cost  =g_prev_hk_unit_sell				#rxx before the unit sell was
		#R14 LET p_stylelg.who =  fgl_getenv("LOGNAME")
		LET p_stylelg.who =  g_user			#R14
		LET p_stylelg.style  =g_style.style
		LET p_stylelg.lockdtime  =CURRENT						#R07
		IF p_change = "u" THEN								#R07
			LET p_stylelg.pos_del_flg = "u"					#R07
		ELSE												#R07
			LET p_stylelg.pos_del_flg = "a"					#R07
		END IF												#R07
		INSERT INTO seedhk:stylelg1 VALUES (p_stylelg.*) 
	END IF
	#R09 >>
	# Do Sin log here
	INITIALIZE p_stylelg.* TO NULL
	SELECT	*
	INTO	p_stylelg.*
	FROM	seedsin:style
	WHERE	style = g_style.style

	if status != notfound then
		LET p_stylelg.fob_cost  =g_prev_sg_unit_sell				#rxx before the unit sell was
		#R14 LET p_stylelg.who =  fgl_getenv("LOGNAME")
		LET p_stylelg.who =  g_user   #R14
		LET p_stylelg.style  =g_style.style
		LET p_stylelg.lockdtime  =CURRENT					
		IF p_change = "u" THEN							
			LET p_stylelg.pos_del_flg = "u"				
		ELSE											
			LET p_stylelg.pos_del_flg = "a"					
		END IF												
		INSERT INTO seedsin:stylelg1 VALUES (p_stylelg.*) 
	END IF
	#NZ
	# Do NZ log here
	INITIALIZE p_stylelg.* TO NULL
	SELECT	*
	INTO	p_stylelg.*
	FROM	seednz:style
	WHERE	style = g_style.style

	if status != notfound then
		LET p_stylelg.fob_cost  =g_prev_nz_unit_sell				#rxx before the unit sell was
		#R14 LET p_stylelg.who =  fgl_getenv("LOGNAME")
		LET p_stylelg.who =  g_user		#R14
		LET p_stylelg.style  =g_style.style
		LET p_stylelg.lockdtime  =CURRENT					
		IF p_change = "u" THEN							
			LET p_stylelg.pos_del_flg = "u"				
		ELSE											
			LET p_stylelg.pos_del_flg = "a"					
		END IF												
		INSERT INTO seednz:stylelg1 VALUES (p_stylelg.*) 
	END IF
	#R09 <<
	#R07 <<
	#R07 LET p_stylelg.change = "u"
	#R07LET p_stylelg.date_lg =  TODAY
	#R07LET p_stylelg.style= g_style.style
	#R07LET p_stylelg.time_lg =CURRENT
	#R07LET p_stylelg.program = "sty_ent.4ge"
	#R07LET p_stylelg.unit_sell =  g_style.unit_sell
	#R07 LET p_stylelg.unit_sell =   g_hk_unit_sell
	#R07 INSERT INTO seedhk:stylelg VALUES (p_stylelg.*) 
display "end log"
END FUNCTION	
################################################################################
#	sty_entLG - write to log table
################################################################################
#R09
FUNCTION strip_special_chars(s)
DEFINE s STRING
DEFINE sb base.StringBuffer
DEFINE ch CHAR(1)
DEFINE i INTEGER

   LET sb = base.StringBuffer.create()
   FOR i = 1 TO s.getLength()
      LET ch = s.getCharAt(i)
      IF ORD(ch) >= 32 AND ORD(ch) <= 127 THEN
         CALL sb.append(ch)
      END IF
   END FOR
   RETURN sb.toString()
END FUNCTION
