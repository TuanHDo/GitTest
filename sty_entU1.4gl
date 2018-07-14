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
#   R04 13 Oct   td & tn  To default the current season
#   R05 08aug15 td        Mod. To introduce division
################################################################################
DATABASE seed

GLOBALS
		"sty_entG.4gl"
################################################################################
#	reqhdrU - enter data													   #
################################################################################
FUNCTION sty_entU1(p_mode)
	DEFINE
     	 	p_hk_first_recv 			DATE,
			p_hk_unit_sell_temp			LIKE sku.unit_sell,			#
			p_unit_sell_temp			LIKE sku.unit_sell,
			p_count						INTEGER,
	        p_text						STRING,				#gxx
		    p_opt						CHAR(10),
			p_lkref1					CHAR(80),
			p_supplier 					LIKE supplier.supplier,
			p_supplier_name 			LIKE supplier.supplier_name,
			p_hk_supplier_name 			LIKE supplier.supplier_name,			##
		    p_season 					LIKE season.season,
		    p_season_desc 				LIKE season.season_desc,
		    p_hk_season_desc 			LIKE season.season_desc,				#
			p_division 					LIKE division.division,
			p_hk_division_name 			LIKE division.division_name,			#R05
		    p_class		 				LIKE class.class,
		    p_class_desc 				LIKE class.class_desc,
		    p_hk_class_desc 			LIKE class.class_desc,					#
		    p_hk_story_desc 			LIKE class.class_desc,					#R03
			p_category		 			LIKE category.category,
			p_category_name	 			LIKE category.category_name,
			p_hk_category_name			LIKE category.category_name,			#
		    p_fabric_type	 			LIKE fabric_type.fabric_type,
		    p_fabric_desc 				LIKE fabric_type.fabric_desc,
		    p_story 					LIKE story.story,
		    p_story_desc 				LIKE story.story_desc,
			p_status					INTEGER,
			p_query						CHAR(500),
            r8,r9                       CHAR(20),   #R03
            cb                  		ui.ComboBox,                 #rxx
			p_iostat					INTEGER,
			lstate						CHAR(10),
			p_retstat					INTEGER,
			p_mode						CHAR(1),
			p_option					CHAR(80),
			p_hk_prev_unit_cost 		LIKE style.unit_cost,			#
			p_prev_unit_cost 			LIKE style.unit_cost			#R01

	LET p_retstat = TRUE
	LET g_opt = NULL
	LET g_hk_lchg_dte = TODAY					#
	LET g_hk_gst_perc = 0						#

	#rxx >>  #R04
display "HK: ",p_mode,g_hk_season
	IF p_mode = "a" THEN
		IF g_hk_season IS NULL THEN
			SELECT season
			INTO   g_hk_season
			FROM   seedhk:season
			WHERE 	today between start_dt and end_dt
				
			DISPLAY BY NAME g_hk_season
			ATTRIBUTE(NORMAL)
		END IF
	END IF
display "HK 1: ",p_mode,g_hk_season
			#rxx << R04
        #R03 <<
		CALL ui.Interface.refresh()
    	LET cb = ui.ComboBox.forName("formonly.r8")
    	IF cb IS NULL THEN
	    	ERROR "Form field not found in current form"
        	RETURN FALSE
    	END IF
    	CALL cb.clear()
		CALL cb.addItem("Air","Air")
    	CALL cb.addItem("Sea","Sea")
    	CALL cb.addItem("Local","Local")
    	LET r8= "Local"
		LET g_hk_fob_method = "Local"

		CALL ui.Interface.refresh()
    	LET cb = ui.ComboBox.forName("formonly.r9")
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
    	LET r9= "AUD"
		LET g_hk_fob = "AUD"
		LET g_hk_fob_cost = 0

     LET 	p_hk_first_recv = NULL
     SELECT	seedhk:sum_ros_style.date_first_receipt
     INTO 	p_hk_first_recv
     FROM 	seedhk:sum_ros_style
     WHERE 	seedhk:sum_ros_style.style = g_style.style

     LET g_hk_style_desc= g_style.style_desc
	 LET g_hk_short_desc =g_style.short_desc				
	 LET g_hk_supplier	 = g_style.supplier		
	 LET g_hk_sup_sty	 = g_style.sup_sty		
  	 LET g_hk_class	 = g_style.class				
	 LET g_hk_category	 = g_style.category			

	CALL sty_entX()
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

    		INPUT BY NAME g_hk_style_desc,				
						  g_hk_short_desc,				
						  g_hk_supplier,			
						  g_hk_sup_sty,			
						  g_hk_season,					
						  g_hk_division,		#R05				
						  g_hk_class,					
						  g_hk_category,				
						  g_hk_lchg_dte,					
						  g_hk_unit_cost,					
						  g_hk_unit_sell,					
						  g_hk_orig_sell,					
                          r8,              #R03
                          r9,
						  #g_hk_fob_method, #R03 >>					
						  #g_hk_fob,					
						  g_hk_fob_cost,					
						  g_hk_story	    #R03 <<		
			WITHOUT DEFAULTS
--#			ATTRIBUTE(NORMAL)


			AFTER FIELD g_hk_unit_sell
         		IF p_hk_first_recv IS NULL THEN
					 SELECT	hkd_price
					 INTO	g_hk_unit_sell
					 FROM	price_table
					 WHERE	aud_price = g_style.unit_sell

					 DISPLAY BY NAME g_hk_unit_sell
					 ATTRIBUTE(NORMAL)
				END IF
				IF g_hk_unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter Hong Kong last sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_unit_sell
				END IF

				LET g_hk_orig_sell = g_hk_unit_sell
				DISPLAY BY NAME g_hk_orig_sell
				ATTRIBUTE(NORMAL)

				IF g_hk_unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					NEXT FIELD g_hk_unit_sell
				END IF

			AFTER FIELD g_hk_unit_cost
				IF g_hk_unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong unit cost "
					CALL messagebox(p_text,1)						
					NEXT FIELD g_hk_unit_cost
				END IF

			AFTER FIELD  g_hk_supplier,
				         g_hk_season,
				         g_hk_division,		#R05
				         g_hk_class,
						 g_hk_category,
						 g_hk_story         #R03
				CASE   
				WHEN infield(g_hk_supplier)
					IF g_hk_supplier IS NOT NULL THEN
						SELECT	supplier_name
						INTO	p_hk_supplier_name
						FROM	supplier
						WHERE	supplier = g_hk_supplier
display "shk sup not found ",status
						IF status = NOTFOUND THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid supplier"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_hk_supplier
						END IF
						DISPLAY BY NAME p_hk_supplier_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HongKong  supplier "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_hk_supplier
					END IF
				# >>
				WHEN infield(g_hk_season)
					IF g_hk_season IS NOT NULL THEN
						SELECT	seedhk:season.season_desc
						INTO	p_hk_season_desc
						FROM	seedhk:season
						WHERE	seedhk:season.season = g_hk_season
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
display "hk season: status ",status
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid HongKong  season"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_hk_season
						END IF
						DISPLAY BY NAME p_hk_season_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HonkKong season "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_hk_season
					END IF
				# <<
				#R05 >>
				WHEN infield(g_hk_division)
					IF g_hk_division IS NOT NULL THEN
						SELECT	seedhk:division.division_name
						INTO	p_hk_division_name
						FROM	seedhk:division
						WHERE	seedhk:division.division = g_hk_division
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
display "hk season: status ",status
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid HongKong  division"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_hk_division
						END IF
						DISPLAY BY NAME p_hk_division_name
						ATTRIBUTE(NORMAL)
					#ELSE
						#ERROR "must enter season "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter HonkKong season "
						#CALL messagebox(p_text,1)						#gxx
						#NEXT FIELD g_hk_season
					END IF
					#R05 <<

				WHEN infield(g_hk_class)
					IF g_hk_class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_hk_class_desc
						FROM	class
						WHERE	class = g_hk_class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid class"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_hk_class
						END IF
						DISPLAY BY NAME p_hk_class_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter class "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_hk_class
					END IF
				WHEN infield(g_hk_category)
					IF g_hk_category IS NOT NULL THEN
						SELECT	category.category_name
						INTO	p_hk_category_name
        				FROM    class_cat, category
        				WHERE   class_cat.class     = g_hk_class    
                		AND		class_cat.category  = g_hk_category  
                		AND		category.category   = g_hk_category
						AND		class_cat.category = category.category

						IF status = NOTFOUND THEN
							ERROR "invalid category for selected class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid category for selected class"
							CALL messagebox(p_text,1)						#gxx
							NEXT FIELD g_hk_class
						END IF
						DISPLAY BY NAME p_hk_category_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter category "
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_hk_category
					END IF

				WHEN infield(g_hk_story)
					IF g_hk_story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_hk_story_desc
						FROM	story
						WHERE	story = g_hk_story

						IF status = NOTFOUND THEN
							ERROR "invalid story"
							ATTRIBUTE(RED)
							NEXT FIELD g_hk_story
						END IF
						DISPLAY BY NAME p_hk_story_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "invalid story"
						CALL messagebox(p_text,1)						#gxx
						NEXT FIELD g_hk_story
					END IF
				END CASE
			

			AFTER INPUT
				IF g_hk_style_desc IS NULL THEN
					ERROR "must enter style description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong style description"
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_style_desc
				END IF
				IF g_hk_short_desc IS NULL THEN
					ERROR "must enter style short description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong style short description"
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_short_desc
				END IF
				IF g_hk_supplier IS NULL THEN
					ERROR "must enter supplier "
					ATTRIBUTE(RED)
					LET p_text =  "must enter supplier "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_supplier
				END IF
				#IF g_hk_sup_sty IS NULL THEN
					#ERROR "must enter supplier Style "
					#ATTRIBUTE(RED)
					#NEXT FIELD g_hk_sup_sty
				#END IF
				IF g_hk_season IS NULL THEN
					ERROR "must enter season "
					ATTRIBUTE(RED)
					LET p_text =  "must enter season "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_season
				END IF
				IF g_hk_class IS NULL THEN
					ERROR "must enter class "
					ATTRIBUTE(RED)
					LET p_text =  "must enter class "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_hclass
				END IF
				IF g_hk_category IS NULL THEN
					ERROR "must enter category "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong  category "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_category
				END IF
				IF g_hk_unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong  unit cost "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_unit_cost
				END IF
				IF g_hk_orig_sell IS NULL THEN
					ERROR "must enter original sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong original sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_orig_sell
				END IF
				IF g_hk_unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HongKong last sell price "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_unit_sell
				END IF
				IF g_hk_lchg_dte IS NULL THEN
					ERROR "must enter last change date "
					ATTRIBUTE(RED)
					LET p_text =  "must enter last change date "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_lchg_dte
				END IF
				IF g_hk_story IS NULL THEN       #R03
					ERROR "must enter story "
					ATTRIBUTE(RED)
					lET p_text =  "must enter story "
					CALL messagebox(p_text,1)						#gxx
					NEXT FIELD g_hk_story
				END IF
				LET lstate = "WRITEDATA"

			ON ACTION find
				CASE   
				WHEN infield(g_hk_season)
					LET p_lkref1= NULL
                    CALL gp_lookup1("season",p_lkref1)
                    RETURNING p_season,p_hk_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_hk_season = p_season
						DISPLAY BY NAME g_hk_season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R05 >>
				WHEN infield(g_hk_division)
					LET p_lkref1= NULL
                    CALL gp_lookup1("division",p_lkref1)
                    RETURNING p_division,p_hk_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_hk_division = p_division
						DISPLAY BY NAME g_hk_division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_division_name
						ATTRIBUTE (NORMAL)
					END IF
					#R05 <<
				WHEN infield(g_hk_class)
					LET p_lkref1= NULL
                    CALL gp_lookup("class",p_lkref1)
                    RETURNING p_class,p_hk_class_desc
                    IF p_class IS NOT NULL THEN
						LET	g_hk_class = p_class
						DISPLAY BY NAME g_hk_class
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_class_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_hk_category)
					LET p_lkref1=  g_hk_class
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_hk_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_hk_category = p_category
						DISPLAY BY NAME g_hk_category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_category_name
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_hk_story)
					LET p_lkref1= NULL
                    CALL gp_lookup("story",p_lkref1)
                    RETURNING p_story,p_hk_story_desc
                    IF p_story IS NOT NULL THEN
						LET	g_hk_story = p_story
						DISPLAY BY NAME g_hk_story
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_story_desc
						ATTRIBUTE (NORMAL)
					END IF
				OTHERWISE
                    ERROR "no lookup for this field"
					ATTRIBUTE(RED)
                END CASE

			ON CHANGE r8
				CASE
				WHEN r8= "Air"
					LET g_hk_fob_method = "Air"
				WHEN r8= "Sea"
					LET g_hk_fob_method = "Sea"
				WHEN r8= "Local"
					LET g_hk_fob_method = "Local"
				END CASE

			ON CHANGE r9
				CASE
				WHEN r9= "POUND"
					LET g_hk_fob = "POUND"
				WHEN r9= "USD"
					LET g_hk_fob = "USD"
				WHEN r9= "HONGKONG"
					LET g_hk_fob = "HONGKONG"
				WHEN r9= "EURO"
					LET g_hk_fob = "EURO"
				WHEN r9= "N/A"
					LET g_hk_fob = "N/A"
				WHEN r9= "AUD"
					LET g_hk_fob = "AUD"
				WHEN r9= "NZ"									
					LET g_hk_fob = "NZ"
				WHEN r9= "SGD"									
					LET g_hk_fob = "SGD"
				END CASE
			ON ACTION cancel
				IF p_mode = "a" THEN
					LET g_hk_style_desc = NULL
					LET g_hk_short_desc = NULL
					LET g_hk_supplier = NULL
					LET g_hk_sup_sty = NULL
					LET g_hk_season = NULL
					LET g_hk_division = NULL		#R05
					LET g_hk_class = NULL
					LET g_hk_category = NULL
					LET g_hk_unit_cost = NULL
					LET g_hk_unit_sell = NULL
					LET g_hk_orig_sell = NULL
					LET g_hk_lchg_dte = NULL
					LET g_hk_gst_perc = NULL
					LET g_hk_fob_method = NULL   #R03
					LET g_hk_fob = NULL
					LET g_hk_fob_cost = NULL
					LET g_hk_story = NULL   	#R03
					LET lstate = "GETOUT"
				ELSE
					LET lstate = "GETOUT"
				END IF
				EXIT INPUT
			END INPUT

		WHEN lstate = "WRITEDATA"	
			IF sty_entI("COPY") THEN
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
