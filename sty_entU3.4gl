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
#   R05 08aug15  td       To add division
################################################################################
DATABASE seed

GLOBALS
		"sty_entG.4gl"
################################################################################
#	reqhdrU - enter data													   #
################################################################################
FUNCTION sty_entU3(p_mode)
	DEFINE
     	 	p_nz_first_recv 			DATE,
			p_nz_unit_sell_temp			LIKE sku.unit_sell,			#
			p_unit_sell_temp			LIKE sku.unit_sell,
			p_count						INTEGER,
	        p_text						STRING,				#gxx
		    p_opt						CHAR(10),
			p_lkref1					CHAR(80),
			p_supplier 					LIKE supplier.supplier,
			p_supplier_name 			LIKE supplier.supplier_name,
			p_nz_supplier_name 			LIKE supplier.supplier_name,			##
		    p_season 					LIKE season.season,
		    p_season_desc 				LIKE season.season_desc,
		    p_nz_season_desc 			LIKE season.season_desc,				#
			p_division 					LIKE division.division,
			p_nz_division_name 			LIKE division.division_name,				#R05
		    p_class		 				LIKE class.class,
		    p_class_desc 				LIKE class.class_desc,
		    p_nz_class_desc 			LIKE class.class_desc,					#
		    p_nz_story_desc 			LIKE class.class_desc,					#R03
			p_category		 			LIKE category.category,
			p_category_name	 			LIKE category.category_name,
			p_nz_category_name			LIKE category.category_name,			#
		    p_fabric_type	 			LIKE fabric_type.fabric_type,
		    p_fabric_desc 				LIKE fabric_type.fabric_desc,
		    p_story 					LIKE story.story,
		    p_story_desc 				LIKE story.story_desc,
			p_status					INTEGER,
			p_query						CHAR(500),
            nz17,nz18                       CHAR(20),   #R03
            cb                  		ui.ComboBox,                 #rxx
			p_iostat					INTEGER,
			lstate						CHAR(10),
			p_retstat					INTEGER,
			p_mode						CHAR(1),
			p_option					CHAR(80),
			p_nz_prev_unit_cost 		LIKE style.unit_cost,			#
			p_prev_unit_cost 			LIKE style.unit_cost			#R01

	LET p_retstat = TRUE
	LET g_opt = NULL
	LET g_nz_lchg_dte = TODAY					#
	LET g_nz_gst_perc = 0						#

		  #R04
display "NZ: ",p_mode,g_nz_season
    IF p_mode = "a" THEN
        IF g_nz_season IS NULL THEN
            SELECT season
            INTO   g_nz_season
            FROM   seednz:season
            WHERE   today between start_dt and end_dt

            DISPLAY BY NAME g_nz_season
            ATTRIBUTE(NORMAL)
        END IF
    END IF
display "NZ 1: ",p_mode,g_nz_season
            #rxx << R04

	CALL sty_entX()

	CALL ui.Interface.refresh()
   	LET cb = ui.ComboBox.forName("formonly.nz17")
   	IF cb IS NULL THEN
    	ERROR "Form field not found in current form"
       	RETURN FALSE
   	END IF
   	CALL cb.clear()
	CALL cb.addItem("Air","Air")
   	CALL cb.addItem("Sea","Sea")
   	CALL cb.addItem("Local","Local")
    LET nz17 = g_hk_fob_method
	LET g_nz_fob_method = g_hk_fob_method

	CALL ui.Interface.refresh()
   	LET cb = ui.ComboBox.forName("formonly.nz18")
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

    LET nz18 = g_hk_fob
	LET g_nz_fob =  g_hk_fob
	LET g_nz_fob_cost = g_hk_fob_cost 			

     LET 	p_nz_first_recv = NULL
     SELECT	seednz:sum_ros_style.date_first_receipt
     INTO 	p_nz_first_recv
     FROM 	seednz:sum_ros_style
     WHERE 	seednz:sum_ros_style.style = g_style.style


    LET  g_nz_style_desc = g_style.style_desc			
    LET  g_nz_short_desc = g_style.short_desc
    LET  g_nz_supplier = g_style.supplier
    LET  g_nz_sup_sty = g_style.sup_sty
    LET  g_nz_class = g_style.class
    LET  g_nz_category = g_style.category
    LET  g_nz_season = g_style.season
    LET  g_nz_division = g_style.division				#R05
	LET g_nz_story = g_hk_story

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

    		INPUT BY NAME g_nz_style_desc,				
						  g_nz_short_desc,				
						  g_nz_supplier,			
						  g_nz_sup_sty,			
						  g_nz_season,					
						  g_nz_division,			#R05
						  g_nz_class,					
						  g_nz_category,				
						  g_nz_unit_cost,					
						  g_nz_unit_sell,					
						  g_nz_orig_sell,					
						  g_nz_lchg_dte,					
                          nz17,              
                          nz18,
						  g_nz_fob_cost,					
						  g_nz_story	    	
			WITHOUT DEFAULTS
--#			ATTRIBUTE(NORMAL)

			BEFORE FIELD g_nz_unit_sell
         		IF p_nz_first_recv IS NULL THEN
					 SELECT	nzd_price
					 INTO	g_nz_unit_sell
					 FROM	price_table
					 WHERE	aud_price = g_style.unit_sell

display "au price: ",g_style.unit_sell, " nz price ",g_nz_unit_sell," ",p_nz_first_recv
					 DISPLAY BY NAME g_nz_unit_sell
					 ATTRIBUTE(NORMAL)
				END IF

			AFTER FIELD g_nz_unit_sell
				IF g_nz_unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ last sell price 1 "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_unit_sell
				END IF
display "LSP: ",g_nz_unit_sell
				LET g_nz_orig_sell = g_nz_unit_sell
				DISPLAY BY NAME g_nz_orig_sell
				ATTRIBUTE(NORMAL)

			AFTER FIELD g_nz_unit_cost
				IF g_nz_unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ unit cost "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_unit_cost
				END IF

			AFTER FIELD  g_nz_supplier,
				         g_nz_season,
				         g_nz_division,				#R05
				         g_nz_class,
						 g_nz_category,
						 g_nz_story        
				CASE   
				WHEN infield(g_nz_supplier)
					IF g_nz_supplier IS NOT NULL THEN
						SELECT	supplier_name
						INTO	p_nz_supplier_name
						FROM	supplier
						WHERE	supplier = g_nz_supplier
display "snz sup not found ",status
						IF status = NOTFOUND THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid supplier"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_nz_supplier
						END IF
						DISPLAY BY NAME p_nz_supplier_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ  supplier "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_nz_supplier
					END IF
				# >>
				WHEN infield(g_nz_season)
					IF g_nz_season IS NOT NULL THEN
						SELECT	seednz:season.season_desc
						INTO	p_nz_season_desc
						FROM	seednz:season
						WHERE	seednz:season.season = g_nz_season
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
display "nz season: status ",status
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid NZ  season"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_nz_season
						END IF
						DISPLAY BY NAME p_nz_season_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ season "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_nz_season
					END IF
				# <<
				#R05 >>
				WHEN infield(g_nz_division)
					IF g_nz_division IS NOT NULL THEN
						SELECT	seednz:division.division_name
						INTO	p_nz_division_name
						FROM	seednz:division
						WHERE	seednz:division.division = g_nz_division
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
display "nz season: status ",status
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid NZ  division"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_nz_division
						END IF
						DISPLAY BY NAME p_nz_division_name
						ATTRIBUTE(NORMAL)
					##ELSE
						##ERROR "must enter division "
						##ATTRIBUTE(RED)
						##LET p_text =  "must enter NZ division "
						##CALL messagebox(p_text,1)						#gxx
						##NEXT FIELD g_nz_division
					END IF
				#R05 <<
				WHEN infield(g_nz_class)
					IF g_nz_class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_nz_class_desc
						FROM	class
						WHERE	class = g_nz_class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid class"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_nz_class
						END IF
						DISPLAY BY NAME p_nz_class_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter class "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_nz_class
					END IF
				WHEN infield(g_nz_category)
					IF g_nz_category IS NOT NULL THEN
						SELECT	category.category_name
						INTO	p_nz_category_name
        				FROM    class_cat, category
        				WHERE   class_cat.class     = g_nz_class    
                		AND		class_cat.category  = g_nz_category  
                		AND		category.category   = g_nz_category
						AND		class_cat.category = category.category

						IF status = NOTFOUND THEN
							ERROR "invalid category for selected class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid category for selected class"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_nz_class
						END IF
						DISPLAY BY NAME p_nz_category_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter category "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_nz_category
					END IF

				WHEN infield(g_nz_story)
					IF g_nz_story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_nz_story_desc
						FROM	story
						WHERE	story = g_nz_story

						IF status = NOTFOUND THEN
							ERROR "invalid story"
							ATTRIBUTE(RED)
							LET p_text =  "invalid story"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_nz_story
						END IF
						DISPLAY BY NAME p_nz_story_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ story "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_nz_story
					END IF
				END CASE
			

			AFTER INPUT
				IF g_nz_style_desc IS NULL THEN
					ERROR "must enter style description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ style description"
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_style_desc
				END IF
				IF g_nz_short_desc IS NULL THEN
					ERROR "must enter style short description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ style short description"
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_short_desc
				END IF
				IF g_nz_supplier IS NULL THEN
					ERROR "must enter supplier "
					ATTRIBUTE(RED)
					LET p_text =  "must enter supplier "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_supplier
				END IF
				#IF g_sin_sup_sty IS NULL THEN
					#ERROR "must enter supplier Style "
					#ATTRIBUTE(RED)
					#LET p_text =  "must enter supplier Style "
					#CALL messagebox(p_text,1)						#gxx
					#NEXT FIELD g_sin_sup_sty
				#END IF
				IF g_nz_season IS NULL THEN
					ERROR "must enter season "
					ATTRIBUTE(RED)
					LET p_text =  "must enter season "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_season
				END IF
				#rxx >>
				#IF g_nz_division IS NULL THEN
					#ERROR "must enter division "
					#ATTRIBUTE(RED)
					##LET p_text =  "must enter division "
					#CALL messagebox(p_text,1)						#gxx
					#NEXT FIELD g_nz_division
				#END IF
				#rxx <<
				IF g_nz_class IS NULL THEN
					ERROR "must enter class "
					ATTRIBUTE(RED)
					LET p_text =  "must enter class "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_hclass
				END IF
				IF g_nz_category IS NULL THEN
					ERROR "must enter category "
					ATTRIBUTE(RED)
					NEXT FIELD g_nz_category
				END IF
				IF g_nz_unit_cost IS NULL 
				OR g_nz_unit_cost = 0 THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter unit cost "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_unit_cost
				END IF
				IF g_nz_orig_sell IS NULL 
				OR g_nz_orig_sell = 0 THEN
					ERROR "must enter original sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ original sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_orig_sell
				END IF
				IF g_nz_unit_sell IS NULL 
				OR g_nz_unit_sell = 0 THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ  last sell price 2 "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_unit_sell
				END IF
				IF g_nz_lchg_dte IS NULL THEN
					ERROR "must enter last change date "
					ATTRIBUTE(RED)
					LET p_text =  "must enter last change date "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_lchg_dte
				END IF
				IF g_nz_story IS NULL THEN       #R03
					ERROR "must enter story "
					ATTRIBUTE(RED)
					lET p_text =  "must enter story "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_nz_story
				END IF
				LET lstate = "WRITEDATA"

			ON ACTION find
				CASE   
				WHEN infield(g_nz_season)
					LET p_lkref1= NULL
                    CALL gp_lookup1("season",p_lkref1)
                    RETURNING p_season,p_nz_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_nz_season = p_season
						DISPLAY BY NAME g_nz_season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R05 >>
				WHEN infield(g_nz_division)
					LET p_lkref1= NULL
                    CALL gp_lookup1("division",p_lkref1)
                    RETURNING p_division,p_nz_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_nz_division = p_division
						DISPLAY BY NAME g_nz_division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_division_name
						ATTRIBUTE (NORMAL)
					END IF
				#R05 <<
				WHEN infield(g_nz_class)
					LET p_lkref1= NULL
                    CALL gp_lookup("class",p_lkref1)
                    RETURNING p_class,p_nz_class_desc
                    IF p_class IS NOT NULL THEN
						LET	g_nz_class = p_class
						DISPLAY BY NAME g_nz_class
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_class_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_nz_category)
					LET p_lkref1=  g_nz_class
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_nz_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_nz_category = p_category
						DISPLAY BY NAME g_nz_category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_category_name
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_nz_story)
					LET p_lkref1= NULL
                    CALL gp_lookup("story",p_lkref1)
                    RETURNING p_story,p_nz_story_desc
                    IF p_story IS NOT NULL THEN
						LET	g_nz_story = p_story
						DISPLAY BY NAME g_nz_story
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_story_desc
						ATTRIBUTE (NORMAL)
					END IF
				OTHERWISE
                    ERROR "no lookup for this field"
					ATTRIBUTE(RED)
                END CASE

			ON CHANGE nz17
				CASE
				WHEN nz17= "Air"
					LET g_nz_fob_method = "Air"
				WHEN nz17= "Sea"
					LET g_nz_fob_method = "Sea"
				WHEN nz17= "Local"
					LET g_nz_fob_method = "Local"
				END CASE

			ON CHANGE nz18
				CASE
				WHEN nz18= "POUND"
					LET g_nz_fob = "POUND"
				WHEN nz18= "USD"
					LET g_nz_fob = "USD"
				WHEN nz18= "HONGKONG"
					LET g_nz_fob = "HONGKONG"
				WHEN nz18= "EURO"
					LET g_nz_fob = "EURO"
				WHEN nz18= "N/A"
					LET g_nz_fob = "N/A"
				WHEN nz18= "AUD"
					LET g_nz_fob = "AUD"
				WHEN nz18= "NZ"									
					LET g_nz_fob = "NZ"
				WHEN nz18= "SGD"									
					LET g_nz_fob = "SGD"
				END CASE

			ON ACTION cancel
				IF p_mode = "a" THEN
					LET g_nz_style_desc = NULL
					LET g_nz_short_desc = NULL
					LET g_nz_supplier = NULL
					LET g_nz_sup_sty = NULL
					LET g_nz_season = NULL
					LET g_nz_division = NULL			#R05
					LET g_nz_class = NULL
					LET g_nz_category = NULL
					LET g_nz_unit_cost = NULL
					LET g_nz_unit_sell = NULL
					LET g_nz_orig_sell = NULL
					LET g_nz_lchg_dte = NULL
					LET g_nz_gst_perc = NULL
					LET g_nz_fob_method = NULL   #R03
					LET g_nz_fob = NULL
					LET g_nz_fob_cost = NULL
					LET g_nz_story = NULL   	#R03
					LET lstate = "GETOUT"
				ELSE
					LET lstate = "GETOUT"
				END IF
				EXIT INPUT
			END INPUT

		WHEN lstate = "WRITEDATA"	
			IF sty_entI("COPYNZ") THEN
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
