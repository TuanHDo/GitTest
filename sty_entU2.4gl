################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entU Style Maintenance program             #
#  																			   #
# 	R00	21jun09  td       initial release				    	               #
#   R03 11Jul12  tn       To add fob fields and story into the program
#   R04 14Oct14  tn       To default the current season 
#   R05 08aug15  tn       add division
#   R16 28dec15 td        check old price v new price for SG only
###############################################################################r
DATABASE seed

GLOBALS
		"sty_entG.4gl"
################################################################################
#	reqhdrU - enter data													   #
################################################################################
FUNCTION sty_entU2(p_mode)
	DEFINE
			p_date_insert				DATE,				#R06
     	 	p_sin_first_recv 			DATE,
			p_sin_unit_sell_temp			LIKE sku.unit_sell,			#
			p_unit_sell_temp			LIKE sku.unit_sell,
			p_count						INTEGER,
	        p_text						STRING,				#gxx
		    p_opt						CHAR(10),
			p_lkref1					CHAR(80),
			p_supplier 					LIKE supplier.supplier,
			p_supplier_name 			LIKE supplier.supplier_name,
			p_sin_supplier_name 			LIKE supplier.supplier_name,			##
		    p_season 					LIKE season.season,
		    p_season_desc 				LIKE season.season_desc,
		    p_sin_season_desc 			LIKE season.season_desc,				#
			p_division 					LIKE division.division,
			p_sin_division_name 			LIKE division.division_name,			#R05
		    p_class		 				LIKE class.class,
		    p_class_desc 				LIKE class.class_desc,
		    p_sin_class_desc 			LIKE class.class_desc,					#
		    p_sin_story_desc 			LIKE class.class_desc,					#R03
			p_category		 			LIKE category.category,
			p_category_name	 			LIKE category.category_name,
			p_sin_category_name			LIKE category.category_name,			#
		    p_fabric_type	 			LIKE fabric_type.fabric_type,
		    p_fabric_desc 				LIKE fabric_type.fabric_desc,
		    p_story 					LIKE story.story,
		    p_story_desc 				LIKE story.story_desc,
			p_status					INTEGER,
			p_query						CHAR(500),
            sin17,sin18                       CHAR(20),   #R03
            cb                  		ui.ComboBox,                 #R06
			p_iostat					INTEGER,
			lstate						CHAR(10),
			p_retstat					INTEGER,
			p_mode						CHAR(1),
			p_option					CHAR(80),
			p_sin_prev_unit_cost 		LIKE style.unit_cost,			#
			p_prev_unit_cost 			LIKE style.unit_cost			#R01

	LET p_retstat = TRUE
	LET g_opt = NULL
	LET g_sin_lchg_dte = TODAY					#
	LET g_sin_gst_perc = 0						#

      #R06 >>  #R04
display "SIN: ",p_mode,g_sin_season
    IF p_mode = "a" THEN
        IF g_sin_season IS NULL THEN
            SELECT season
            INTO   g_sin_season
            FROM   seedsin:season
            WHERE   today between start_dt and end_dt

            DISPLAY BY NAME g_sin_season
            ATTRIBUTE(NORMAL)
        END IF
    END IF
display "SIN 1: ",p_mode,g_sin_season
            #R06 << R04

	CALL sty_entX()

	CALL ui.Interface.refresh()
   	LET cb = ui.ComboBox.forName("formonly.sin17")
   	IF cb IS NULL THEN
    	ERROR "Form field not found in current form"
       	RETURN FALSE
   	END IF
   	CALL cb.clear()
	CALL cb.addItem("Air","Air")
   	CALL cb.addItem("Sea","Sea")
   	CALL cb.addItem("Local","Local")
    LET sin17 = g_hk_fob_method
	LET g_sin_fob_method = g_hk_fob_method

	CALL ui.Interface.refresh()
   	LET cb = ui.ComboBox.forName("formonly.sin18")
   	IF cb IS NULL THEN
    	ERROR "Form field not found in current form"
       	RETURN FALSE
   	END IF
    CALL cb.clear()
	CALL cb.addItem("AUD","AUD")
	CALL cb.addItem("POUND","POUND")
	CALL cb.addItem("USD","USD")
    CALL cb.addItem("HONGKONG","HONGKONG")
    CALL cb.addItem("EURO","EURO")
    CALL cb.addItem("N/A","N/A")
	CALL cb.addItem("NZ","NZ")					

    LET sin18 = g_hk_fob
	LET g_sin_fob =  g_hk_fob
	LET g_sin_fob_cost = g_hk_fob_cost 			

     LET 	p_sin_first_recv = NULL
     SELECT	seedsin:sum_ros_style.date_first_receipt
     INTO 	p_sin_first_recv
     FROM 	seedsin:sum_ros_style
     WHERE 	seedsin:sum_ros_style.style = g_style.style


    LET  g_sin_style_desc = g_style.style_desc			
    LET  g_sin_short_desc = g_style.short_desc
    LET  g_sin_supplier = g_style.supplier
    LET  g_sin_sup_sty = g_style.sup_sty
    LET  g_sin_class = g_style.class
    LET  g_sin_category = g_style.category
	LET g_sin_story = g_hk_story

	LET lstate = "GETLINE"
	LET p_option = "OPTIONS: F1=ACCEPT F10=EXIT"
	DISPLAY p_option AT 22,1
	ATTRIBUTE (BLUE,REVERSE)
	
	WHILE lstate != "GETOUT"
		CASE
		## entry of data
		WHEN lstate = "GETLINE"
label retry:
			LET g_lnl[1,80] = "COPY: enter data"
			DISPLAY g_lnl AT 2,1
			ATTRIBUTE(NORMAL)

    		INPUT BY NAME g_sin_style_desc,				
						  g_sin_short_desc,				
						  g_sin_supplier,			
						  g_sin_sup_sty,			
						  g_sin_season,					
						  g_sin_division,		#R05		
						  g_sin_class,					
						  g_sin_category,				
						  g_sin_unit_cost,					
						  g_sin_unit_sell,					
						  g_sin_orig_sell,					
						  g_sin_lchg_dte,					
                          sin17,              
                          sin18,
						  g_sin_fob_cost,					
						  g_sin_story	    	
			WITHOUT DEFAULTS
--#			ATTRIBUTE(NORMAL)

			BEFORE FIELD g_sin_unit_sell

display "sin price: ",g_style.unit_sell, " ",p_sin_first_recv

         		IF p_sin_first_recv IS NULL THEN
					#R06 >>
					LET	p_date_insert = NULL
					SELECT	date_insert
					INTO	p_date_insert
					FROM	seedsin:style
					WHERE	style = g_style.style 

display "insert date: ",p_date_insert," ",g_style.style

					IF p_date_insert >= "251215" 
					OR p_mode = "a" THEN
					 	SELECT	sgd_price
					 	INTO	g_sin_unit_sell
					 	FROM	price_table
					 	WHERE	aud_price = g_style.unit_sell
					ELSE						#R06 >>
					 	SELECT	sgd_price
					 	INTO	g_sin_unit_sell
					 	FROM	price_table_old
					 	WHERE	aud_price = g_style.unit_sell
					END IF
					#R06 <<
					 DISPLAY BY NAME g_sin_unit_sell
					 ATTRIBUTE(NORMAL)
				END IF

			AFTER FIELD g_sin_unit_sell
				IF g_sin_unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter Singapore last sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_unit_sell
				END IF
				LET g_sin_orig_sell = g_sin_unit_sell
				DISPLAY BY NAME g_sin_orig_sell
				ATTRIBUTE(NORMAL)

			AFTER FIELD g_sin_unit_cost
				IF g_sin_unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter Singapore unit cost "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_unit_cost
				END IF

			AFTER FIELD  g_sin_supplier,
				         g_sin_season,
				         g_sin_division,			#R05
				         g_sin_class,
						 g_sin_category,
						 g_sin_story        
				CASE   
				WHEN infield(g_sin_supplier)
					IF g_sin_supplier IS NOT NULL THEN
						SELECT	supplier_name
						INTO	p_sin_supplier_name
						FROM	supplier
						WHERE	supplier = g_sin_supplier
display "ssin sup not found ",status
						IF status = NOTFOUND THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid supplier"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_sin_supplier
						END IF
						DISPLAY BY NAME p_sin_supplier_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Singapore  supplier "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_sin_supplier
					END IF
				# >>
				WHEN infield(g_sin_season)
					IF g_sin_season IS NOT NULL THEN
						SELECT	seedsin:season.season_desc
						INTO	p_sin_season_desc
						FROM	seedsin:season
						WHERE	seedsin:season.season = g_sin_season
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
display "sin season: status ",status
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid Singapore  season"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_sin_season
						END IF
						DISPLAY BY NAME p_sin_season_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Singapore season "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_sin_season
					END IF
				# <<
				#R05 >>
				WHEN infield(g_sin_division)
					IF g_sin_division IS NOT NULL THEN
						SELECT	seedsin:division.division_name
						INTO	p_sin_division_name
						FROM	seedsin:division
						WHERE	seedsin:division.division = g_sin_division
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
display "sin season: status ",status
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid Singapore  division"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_sin_division
						END IF
						DISPLAY BY NAME p_sin_division_name
						ATTRIBUTE(NORMAL)
					ELSE
						#ERROR "must enter division "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter Singapore division "
						#CALL messagebox(p_text,1)						#gxx
						#NEXT FIELD g_sin_division
					END IF
				#R05<<

				WHEN infield(g_sin_class)
					IF g_sin_class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_sin_class_desc
						FROM	class
						WHERE	class = g_sin_class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid class"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_sin_class
						END IF
						DISPLAY BY NAME p_sin_class_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter class "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_sin_class
					END IF
				WHEN infield(g_sin_category)
					IF g_sin_category IS NOT NULL THEN
						SELECT	category.category_name
						INTO	p_sin_category_name
        				FROM    class_cat, category
        				WHERE   class_cat.class     = g_sin_class    
                		AND		class_cat.category  = g_sin_category  
                		AND		category.category   = g_sin_category
						AND		class_cat.category = category.category

						IF status = NOTFOUND THEN
							ERROR "invalid category for selected class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid category for selected class"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_sin_class
						END IF
						DISPLAY BY NAME p_sin_category_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter category "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_sin_category
					END IF

				WHEN infield(g_sin_story)
					IF g_sin_story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_sin_story_desc
						FROM	story
						WHERE	story = g_sin_story

						IF status = NOTFOUND THEN
							ERROR "invalid story"
							ATTRIBUTE(RED)
							LET p_text =  "invalid story"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_sin_story
						END IF
						DISPLAY BY NAME p_sin_story_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Singapore story "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_sin_story
					END IF
				END CASE
			

			AFTER INPUT
				IF g_sin_style_desc IS NULL THEN
					ERROR "must enter style description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter Singapore style description"
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_style_desc
				END IF
				IF g_sin_short_desc IS NULL THEN
					ERROR "must enter style short description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter Singapore style short description"
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_short_desc
				END IF
				IF g_sin_supplier IS NULL THEN
					ERROR "must enter supplier "
					ATTRIBUTE(RED)
					LET p_text =  "must enter supplier "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_supplier
				END IF
				#IF g_sin_sup_sty IS NULL THEN
					#ERROR "must enter supplier Style "
					#ATTRIBUTE(RED)
					#LET p_text =  "must enter supplier Style "
					#CALL messagebox(p_text,1)						#gxx
					#NEXT FIELD g_sin_sup_sty
				#END IF
				IF g_sin_season IS NULL THEN
					ERROR "must enter season "
					ATTRIBUTE(RED)
					LET p_text =  "must enter season "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_season
				END IF
				#R06 >>
				##IF g_sin_division IS NULL THEN
					##ERROR "must enter division "
					##ATTRIBUTE(RED)
					##LET p_text =  "must enter division "
					##CALL messagebox(p_text,1)						#gxx
					##NEXT FIELD g_sin_division
				##END IF
				#R06 <<
				IF g_sin_class IS NULL THEN
					ERROR "must enter class "
					ATTRIBUTE(RED)
					LET p_text =  "must enter class "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_hclass
				END IF
				IF g_sin_category IS NULL THEN
					ERROR "must enter category "
					ATTRIBUTE(RED)
					NEXT FIELD g_sin_category
				END IF
				IF g_sin_unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter unit cost "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_unit_cost
				END IF
				IF g_sin_orig_sell IS NULL THEN
					ERROR "must enter original sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter Singapore original sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_orig_sell
				END IF
				IF g_sin_unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter Singapore  last sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_unit_sell
				END IF
				IF g_sin_lchg_dte IS NULL THEN
					ERROR "must enter last change date "
					ATTRIBUTE(RED)
					LET p_text =  "must enter last change date "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_lchg_dte
				END IF
				IF g_sin_story IS NULL THEN       #R03
					ERROR "must enter story "
					ATTRIBUTE(RED)
					lET p_text =  "must enter story "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_sin_story
				END IF
				LET lstate = "WRITEDATA"

			ON ACTION find
				CASE   
				WHEN infield(g_sin_season)
					LET p_lkref1= NULL
                    CALL gp_lookup1("season",p_lkref1)
                    RETURNING p_season,p_sin_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_sin_season = p_season
						DISPLAY BY NAME g_sin_season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R05 >>
				WHEN infield(g_sin_division)
					LET p_lkref1= NULL
                    CALL gp_lookup("division",p_lkref1)
                    RETURNING p_division,p_sin_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_sin_division = p_division
						DISPLAY BY NAME g_hk_division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_division_name
						ATTRIBUTE (NORMAL)
					END IF
				#R05 <<
				WHEN infield(g_sin_class)
					LET p_lkref1= NULL
                    CALL gp_lookup("class",p_lkref1)
                    RETURNING p_class,p_sin_class_desc
                    IF p_class IS NOT NULL THEN
						LET	g_sin_class = p_class
						DISPLAY BY NAME g_sin_class
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_class_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_sin_category)
					LET p_lkref1=  g_sin_class
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_sin_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_sin_category = p_category
						DISPLAY BY NAME g_sin_category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_category_name
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_sin_story)
					LET p_lkref1= NULL
                    CALL gp_lookup("story",p_lkref1)
                    RETURNING p_story,p_sin_story_desc
                    IF p_story IS NOT NULL THEN
						LET	g_sin_story = p_story
						DISPLAY BY NAME g_sin_story
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_story_desc
						ATTRIBUTE (NORMAL)
					END IF
				OTHERWISE
                    ERROR "no lookup for this field"
					ATTRIBUTE(RED)
                END CASE

			ON CHANGE sin17
				CASE
				WHEN sin17= "Air"
					LET g_sin_fob_method = "Air"
				WHEN sin17= "Sea"
					LET g_sin_fob_method = "Sea"
				WHEN sin17= "Local"
					LET g_sin_fob_method = "Local"
				END CASE

			ON CHANGE sin18
				CASE
				WHEN sin18= "POUND"
					LET g_sin_fob = "POUND"
				WHEN sin18= "USD"
					LET g_sin_fob = "USD"
				WHEN sin18= "HONGKONG"
					LET g_sin_fob = "HONGKONG"
				WHEN sin18= "EURO"
					LET g_sin_fob = "EURO"
				WHEN sin18= "N/A"
					LET g_sin_fob = "N/A"
				WHEN sin18= "AUD"
					LET g_sin_fob = "AUD"
				WHEN sin18= "NZ"									
					LET g_sin_fob = "NZ"
				WHEN sin18= "SGD"									
					LET g_sin_fob = "SGD"
				END CASE

			ON ACTION cancel
				IF p_mode = "a" THEN
					LET g_sin_style_desc = NULL
					LET g_sin_short_desc = NULL
					LET g_sin_supplier = NULL
					LET g_sin_sup_sty = NULL
					LET g_sin_season = NULL
					LET g_sin_division = NULL			#R05
					LET g_sin_class = NULL
					LET g_sin_category = NULL
					LET g_sin_unit_cost = NULL
					LET g_sin_unit_sell = NULL
					LET g_sin_orig_sell = NULL
					LET g_sin_lchg_dte = NULL
					LET g_sin_gst_perc = NULL
					LET g_sin_fob_method = NULL   #R03
					LET g_sin_fob = NULL
					LET g_sin_fob_cost = NULL
					LET g_sin_story = NULL   	#R03
					LET lstate = "GETOUT"
				ELSE
					LET lstate = "GETOUT"
				END IF
				EXIT INPUT
			END INPUT

		WHEN lstate = "WRITEDATA"	
			IF sty_entI("COPYSIN") THEN
				LET p_retstat = TRUE
				LET g_wherepart =
					" WHERE style = \"", g_style.style, "\""
				LET p_text =  "style copied"
				LET lstate = "GETOUT"
				##INITIALIZE g_style.* TO NULL
				CALL sty_entX()
			ELSE
				LET p_retstat = FALSE
				LET p_text = "copying style failed"
				LET lstate = "GETOUT"
			END IF
			CALL messagebox(p_text,1)						#gxx
		#
		#	error return
		#
		WHEN lstate = "GOTERR" 
			LET p_retstat = FALSE
			LET lstate = "GETOUT"
		END CASE
	END WHILE	
	CALL sty_entX()
	RETURN p_retstat
END FUNCTION				
################################################################################
# @@@@@@@@@@@@@@@ (reqhdrU) @@@@@@@@@@@@@@@@
################################################################################
