################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entU Style Maintenance program             #
#  																			   #
# 	R00	02aug01  td       initial release				    	               #
# 	R01	13jul04	td		  add cost_lchg_date,ledger_cost                 #
# 	R02	21jun09	td		  Mod. Campaign - Copy style to SeedHK                 #
#   R03 06Jul12 tn        Mod. To add Fob fields and story as well
#   R04 31Jul12 tn        Mod. default HK descriptions = AUS descriptions      # 
#   R05 09Aug12 tn        Mod. if seedhk story is null then set = seedAu story
#   R06 28jan13 td        Mod. Campaign - introducenew stylelg1 table          #
#   R07 23apr13 td        Mod. Campaign - replace division with section        #
#   R08 04may13 td        Mod. Campaign - convert to hk pricing                #
#   R09 27may13 td        Mod. Campaign - block orig sell as per AOB's advice  #
#   R10 29jul14 td        Mod. Campaign - introduce Singapore company          #
#   R11 22sep14 td        Mod. To introduce NZ companies
#   R12 15nov14 td              Mod Campaign - Set pos_del_flg = "A" to be used"
#                               in the product dump data file to N
#   R13 28jun15 td		introduce demandware web categories
#   R14 08aug15 td        Mod. To introduce division
#   R15 08nov11 td        Mod. sync country of origin field with country field in the costing system
#   R16 28dec15 td        check old price v new price for SG only
#   R17 17jan16 td        add fabric description
#   R18 04jun16 td        add givex e-cert field
#   R19 27aug16 td        add size code
#   R20 02oct16 td        Mod. add HK & SG images
#   R21 06oct16 td        Vet against inactive supplier
#   R22 11mar17 td        add myer name
#	R23	25may18 td		  Add video url page							   #
################################################################################
DATABASE seed

GLOBALS
		"sty_entG.4gl"

	DEFINE
			ssa_styclrlns  ARRAY[50] OF RECORD
				colour				LIKE colour.colour,
				colour_name			LIKE colour.colour_name
						END RECORD,
			ssa_skulns  ARRAY[100] OF RECORD
				sku					LIKE sku.sku,
				colour				LIKE sku.colour,
				colour_name			LIKE colour.colour_name,
				sizes				LIKE sku.sizes,
				unit_sell			LIKE sku.unit_sell
						END RECORD,
			ssa_skulns1  ARRAY[100] OF RECORD
            	ord_nbr 			LIKE sku.ord_nbr,
            	style 				LIKE sku.style,
            	unit_cost  			LIKE sku.unit_cost ,
            	date_first_receipt  LIKE sku.date_first_receipt ,
            	sku_status  		LIKE sku.sku_status
						END RECORD,
			#R02 >>
			ssa_hkskulns  ARRAY[100] OF RECORD
				sku					LIKE sku.sku,
				colour				LIKE sku.colour,
				colour_name			LIKE colour.colour_name,
				sizes				LIKE sku.sizes,
				unit_sell			LIKE sku.unit_sell
						END RECORD,
			ssa_hkskulns1  ARRAY[100] OF RECORD
            	ord_nbr 			LIKE sku.ord_nbr,
            	style 				LIKE sku.style,
            	unit_cost  			LIKE sku.unit_cost ,
            	date_first_receipt  LIKE sku.date_first_receipt ,
            	sku_status  		LIKE sku.sku_status
						END RECORD,
			#R02 <<
			#R10 >>
			ssa_sinskulns  ARRAY[100] OF RECORD
				sku					LIKE sku.sku,
				colour				LIKE sku.colour,
				colour_name			LIKE colour.colour_name,
				sizes				LIKE sku.sizes,
				unit_sell			LIKE sku.unit_sell
						END RECORD,
			ssa_sinskulns1  ARRAY[100] OF RECORD
            	ord_nbr 			LIKE sku.ord_nbr,
            	style 				LIKE sku.style,
            	unit_cost  			LIKE sku.unit_cost ,
            	date_first_receipt  LIKE sku.date_first_receipt ,
            	sku_status  		LIKE sku.sku_status
						END RECORD,
			#R10 <<
			#R11 >>
			ssa_nzskulns  ARRAY[100] OF RECORD
				sku					LIKE sku.sku,
				colour				LIKE sku.colour,
				colour_name			LIKE colour.colour_name,
				sizes				LIKE sku.sizes,
				unit_sell			LIKE sku.unit_sell
						END RECORD,
			ssa_nzskulns1  ARRAY[100] OF RECORD
            	ord_nbr 			LIKE sku.ord_nbr,
            	style 				LIKE sku.style,
            	unit_cost  			LIKE sku.unit_cost ,
            	date_first_receipt  LIKE sku.date_first_receipt ,
            	sku_status  		LIKE sku.sku_status
						END RECORD,
			#R11 <<
			s_maxidx    			INTEGER,
			s_hkmaxidx    			INTEGER,				#R02
			s_sinmaxidx    			INTEGER,				#R10
			s_nzmaxidx    			INTEGER,				#R11
			s_arrsize				INTEGER,
			s_dspsize 				INTEGER,
			s_skulns				RECORD LIKE sku.*,
			s_hkskulns				RECORD LIKE sku.*,					#R02
			s_sinskulns				RECORD LIKE sku.*,					#R10
			s_nzskulns				RECORD LIKE sku.*,					#R11
			s_styclr				RECORD LIKE style_colour.*
################################################################################
#	reqhdrU - enter data													   #
################################################################################
FUNCTION sty_entU(p_mode)
	DEFINE
			p_myer_name					LIKE category.myer_name,					#R22
			p_size						LIKE sty_sizehdr.size_code,						#R19
			p_size_desc					LIKE sty_sizehdr.size_desc,						#R19
			p_fabric			LIKE ax_fabric_content.fabric,	    #R17
			p_cons						CHAR(30),						#R17
			p_date_insert				DATE,					#txx
			p_country     				LIKE ax_country.country,
			p_country_name				LIKE ax_country.country_name,
			p_customs     				LIKE ax_customs.customs,
			p_customs_desc				LIKE ax_customs.customs_desc,
			#R03 >>
			 p_style_desc                LIKE style.style_desc,
			 p_style	                LIKE style.style,
			p_sub_cat ,
            p_sub_sub_cat ,
            p_sub_sub_sub_cat ,
            p_sub_sub_sub_sub_cat ,
            p_cat                       LIKE web_cat3.web_cat ,     #R03
			 p_assort1,
            p_assort2,
            p_assort3                   LIKE style.assort1,
			p_assort1_desc,
            p_assort2_desc,
            p_assort3_desc              CHAR(30),
			r1x							CHAR(2000),			#R21
			r2x,r3x                 CHAR(300),
			p_sub_cat_name,
			p_sub_sub_cat_name,
			p_sub_sub_sub_cat_name,
			p_sub_cat1_name,
			p_sub_cat2_name,
			p_sub_cat3_name,
			p_sub_cat4_name,
			p_sub_cat5_name,
			p_sub_sub_cat1_name,
			p_sub_sub_cat2_name,
			p_sub_sub_cat3_name,
			p_sub_sub_cat4_name,
			p_sub_sub_cat5_name,
			p_cat1_name					LIKE web_cat1.web_cat_name,	#R03
			p_cat2_name					LIKE web_cat1.web_cat_name,	#R03
			p_cat3_name					LIKE web_cat1.web_cat_name,	#R03
			p_cat4_name					LIKE web_cat1.web_cat_name,	#R03
			p_cat5_name					LIKE web_cat1.web_cat_name,	#xxx
			#R13 >>
			p_dw_cat1_name,
			p_dw_subcat1_name,
			p_dw_ssubcat1_name,
			p_dw_sssubcat1_name,
			p_dw_cat2_name,
			p_dw_subcat2_name,
			p_dw_ssubcat2_name,
			p_dw_sssubcat2_name,
			p_dw_cat3_name,
			p_dw_subcat3_name,
			p_dw_ssubcat3_name,
			p_dw_sssubcat3_name,
			p_dw_cat4_name,
			p_dw_subcat4_name,
			p_dw_ssubcat4_name,
			p_dw_sssubcat4_name,
			p_dw_cat5_name,
			p_dw_subcat5_name,
			p_dw_ssubcat5_name,
			p_dw_sssubcat5_name,
			#R13 <<
			r1           		        CHAR(20),                    #R03
			r2                  		CHAR(20),                    #R03
			r8		        			CHAR(20),                    #r03
			r9               			CHAR(20),                    #R03
			sin17		       			CHAR(20),                    #R10
			sin18              			CHAR(20),                    #R10
			nz17		       			CHAR(20),                    #R11
			nz18              			CHAR(20),                    #R11
            cb                  		ui.ComboBox,                 #R03
			p_hk_unit_sell_temp			LIKE sku.unit_sell,			#R02
			p_hk_orig_sell_temp			LIKE sku.unit_sell,			#R12
			p_sin_unit_sell_temp		LIKE sku.unit_sell,			#R10
			p_nz_unit_sell_temp		LIKE sku.unit_sell,			#R11
			p_unit_sell_temp			LIKE sku.unit_sell,
			p_orig_sell_temp			LIKE sku.unit_sell,		#R12
			p_hk_unit_sellx			DECIMAL(8,2),
			p_sin_unit_sellx		DECIMAL(8,2),
			p_nz_unit_sellx			DECIMAL(8,2),
			p_count						INTEGER,
	        p_text						STRING,				#gxx
		    p_opt						CHAR(10),
			p_lkref1					CHAR(80),
			p_supplier 					LIKE supplier.supplier,
			p_supplier_name 			LIKE supplier.supplier_name,
			p_hk_supplier_name 			LIKE supplier.supplier_name,			##R02
			p_sin_supplier_name 		LIKE supplier.supplier_name,			#R10
			p_nz_supplier_name 		LIKE supplier.supplier_name,			#R11
		    p_season 					LIKE season.season,
		    p_season_desc 				LIKE season.season_desc,
		    p_hk_season_desc 			LIKE season.season_desc,				#R02
		    p_sin_season_desc 			LIKE season.season_desc,				#R10
		    p_nz_season_desc 			LIKE season.season_desc,				#R11
			#R07 p_division 					LIKE division.division,
			#R07 p_division_name 			LIKE division.division_name,
			p_division 					LIKE division.division,					#R14
			p_division_name 			LIKE division.division_name,			#R14
			p_hk_division_name 			LIKE division.division_name,			#R14
			p_nz_division_name 		LIKE division.division_name,				#R14
			p_sin_division_name 		LIKE division.division_name,			#R14
			p_section 					LIKE section.section,				#R07
			p_section_name 				LIKE section.section_name,			#R07
		    p_class		 				LIKE class.class,
		    p_class_desc 				LIKE class.class_desc,
		    p_hk_class_desc 			LIKE class.class_desc,					#R02
		    p_sin_class_desc 			LIKE class.class_desc,					#R10
		    p_nz_class_desc 			LIKE class.class_desc,					#R11
			p_category		 			LIKE category.category,
			p_category_name	 			LIKE category.category_name,
			p_hk_category_name 			LIKE category.category_name,			#R02
			p_sin_category_name 		LIKE category.category_name,			#R10
			p_nz_category_name 		LIKE category.category_name,			#R11
		    p_fabric_type	 			LIKE fabric_type.fabric_type,
		    p_fabric_desc 				LIKE fabric_type.fabric_desc,
		    p_story 					LIKE story.story,
		    p_hk_story 					LIKE story.story,
		    p_sin_story 				LIKE story.story,					#R10
		    p_nz_story 				LIKE story.story,					#R11
		    p_story_desc 				LIKE story.story_desc,
		    p_hk_story_desc 			LIKE story.story_desc,  #r03
		    p_sin_story_desc 			LIKE story.story_desc,  #R10
		    p_nz_story_desc 			LIKE story.story_desc,  #R11
			p_status					INTEGER,
			p_query						CHAR(500),
			p_iostat					INTEGER,
			lstate						CHAR(10),
			p_retstat					INTEGER,
			p_mode						CHAR(1),
			p_option					CHAR(80),
			p_hk_prev_unit_cost 		LIKE style.unit_cost,			#R02
			p_sin_prev_unit_cost 		LIKE style.unit_cost,			#R10
			p_nz_prev_unit_cost 		LIKE style.unit_cost,			#R11
			p_prev_unit_cost 			LIKE style.unit_cost,			#R01
			p_prev_supplier 			LIKE style.supplier,				#R21
			p_prev_hk_supplier 			LIKE style.supplier,				#R21
			p_prev_sin_supplier 		LIKE style.supplier,				#R21
			p_prev_nz_supplier 			LIKE style.supplier				#R21

	LET p_retstat = TRUE
	LET p_myer_name = NULL					#R22
	LET g_opt = NULL
	LET g_hkopt = NULL						#R02
	LET g_sinopt = NULL						#R10
	LET g_nzopt = NULL						#R11
	LET g_first_recv = NULL
	LET p_unit_sell_temp= NULL
	LET p_orig_sell_temp= NULL				#R12
	LET p_prev_unit_cost = g_style.unit_cost                    #R01
	LET p_prev_supplier = g_style.supplier                      #R21
    LET g_cost_last_change = FALSE                              #R01

	LET g_hk_first_recv = NULL									#R02
	LET p_hk_unit_sell_temp= NULL								#R02
	LET p_hk_orig_sell_temp= NULL								#R02
    LET g_hk_cost_last_change = FALSE                           #R02
	LET p_hk_prev_unit_cost = g_hk_unit_cost                    #R02
	LET g_hk_supplier = NULL				#R02
	LET g_hk_sup_sty = NULL				#R02

	LET g_hk_style_desc = NULL
	LET g_hk_short_desc = NULL
	LET g_hk_season = NULL
	LET g_hk_division = NULL				#R14
	LET g_hk_class = NULL
	LET g_hk_category = NULL
	LET g_hk_unit_sell = NULL
	LET g_hk_orig_sell = NULL
	LET g_hk_lchg_dte = NULL
	LET g_hk_gst_perc = NULL

	#R10 >>
	LET g_sin_first_recv = NULL									
	LET p_sin_unit_sell_temp= NULL								
    LET g_sin_cost_last_change = FALSE                          
	LET p_sin_prev_unit_cost = g_sin_unit_cost                  
	LET g_sin_supplier = NULL				
	LET g_sin_sup_sty = NULL				

	LET g_sin_style_desc = NULL
	LET g_sin_short_desc = NULL
	LET g_sin_season = NULL
	LET g_sin_division = NULL				#R14
	LET g_sin_class = NULL
	LET g_sin_category = NULL
	LET g_sin_unit_sell = NULL
	LET g_sin_orig_sell = NULL
	LET g_sin_lchg_dte = NULL
	LET g_sin_gst_perc = NULL
	#R10 <<
	#R11 >>
	LET g_nz_first_recv = NULL									
	LET p_nz_unit_sell_temp= NULL								
    LET g_nz_cost_last_change = FALSE                          
	LET p_nz_prev_unit_cost = g_nz_unit_cost                  
	LET g_nz_supplier = NULL				
	LET g_nz_sup_sty = NULL				

	LET g_nz_style_desc = NULL
	LET g_nz_short_desc = NULL
	LET g_nz_season = NULL
	LET g_nz_division = NULL				#R14
	LET g_nz_class = NULL
	LET g_nz_category = NULL
	LET g_nz_unit_sell = NULL
	LET g_nz_orig_sell = NULL
	LET g_nz_lchg_dte = NULL
	LET g_nz_gst_perc = NULL
	#R11 <<

	LET g_prev_unit_sell = g_style.unit_sell			#R21
	IF p_mode = "a" THEN
		INITIALIZE g_style.* TO NULL
		LET g_style.catalogue = "N"					#R03
		LET g_style.del_flg = "N"
		LET g_style.lchg_dte = TODAY
		LET g_hk_lchg_dte = TODAY					#R02
		LET g_sin_lchg_dte = TODAY					#R10
		LET g_nz_lchg_dte = TODAY					#R11
		#R07 LET g_style.division = 1
		LET g_style.section = NULL 					#R07
		LET g_style.gst_perc = 0
		LET g_hk_gst_perc = 0						#R02
		LET g_hk_unit_cost = 0						#R03
		LET g_sin_gst_perc = 0						#R10
		LET g_sin_unit_cost = 0						#R10
		LET g_nz_gst_perc = 0						#R11
		LET g_nz_unit_cost = 0						#R11

        #Tantest
        LET g_hk_story =  NULL
        LET p_hk_story_desc =  NULL

        LET g_sin_story =  NULL						#R10
        LET p_sin_story_desc =  NULL				#R10
        LET g_nz_story =  NULL						#R11
        LET p_nz_story_desc =  NULL				#R11

		CALL ui.Interface.refresh()
    	LET cb = ui.ComboBox.forName("formonly.r1")
    	IF cb IS NULL THEN
	    	ERROR "Form field not found in current form"
        	RETURN FALSE
    	END IF
    	CALL cb.clear()
		CALL cb.addItem("Air","Air")
    	CALL cb.addItem("Sea","Sea")
    	CALL cb.addItem("Local","Local")
    	LET r1= "Local"
		LET g_style.fob_method = "Local"

		CALL ui.Interface.refresh()
    	LET cb = ui.ComboBox.forName("formonly.r2")
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
		CALL cb.addItem("SGD","SGD")						#R10
    	LET r2= "AUD"
		LET g_style.fob = "AUD"
		LET g_style.fob_cost = 0
		#R03 <<

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
		CALL cb.addItem("SGD","SGD")									#R10
    	LET r9= "AUD"
		LET g_hk_fob = "AUD"
		LET g_hk_fob_cost = 0
        #R03 >>
	#R11 >>
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

		#R10 >>
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
    	LET sin17= "Local"
		LET g_sin_fob_method = "Local"

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
		CALL cb.addItem("SGD","SGD")									#R10
    	LET sin18= "AUD"
		LET g_sin_fob = "AUD"
		LET g_sin_fob_cost = 0
		#R10 <<
		#NZ
		#R11 >>
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
    	LET nz17= "Local"
		LET g_nz_fob_method = "Local"

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
		CALL cb.addItem("SGD","SGD")									
    	LET nz18= "AUD"
		LET g_nz_fob = "AUD"
		LET g_nz_fob_cost = 0
		#R11 <<

		CALL sty_entX()

		#R03 >>
		LET g_void = sty_entW("INIT")           #R03
        LET g_void = sty_entW("SELECT")         #R03
        LET g_void = sty_entW("SELECTX")        #R03
		LET lstate = "GETLINE"
	ELSE
		LET g_void = sty_entW("INIT")           #R03
        LET g_void = sty_entW("SELECT")         #R03
        LET g_void = sty_entW("SELECTX")        #R03

		IF g_style.catalogue IS NULL THEN					#R03
			LET g_style.catalogue = "N"					#R03
		END IF
         SELECT	date_first_receipt
         INTO 	g_first_recv
         FROM 	sum_ros_style
         WHERE 	style = g_style.style
		 #R02 >>
         SELECT	seedhk:sum_ros_style.date_first_receipt
         INTO 	g_hk_first_recv
         FROM 	seedhk:sum_ros_style
         WHERE 	seedhk:sum_ros_style.style = g_style.style
		 #R10 >>
         SELECT	seedsin:sum_ros_style.date_first_receipt
         INTO 	g_sin_first_recv
         FROM 	seedsin:sum_ros_style
         WHERE 	seedsin:sum_ros_style.style = g_style.style
		#R10 <<
		 #R11 >>
         SELECT	seednz:sum_ros_style.date_first_receipt
         INTO 	g_nz_first_recv
         FROM 	seednz:sum_ros_style
         WHERE 	seednz:sum_ros_style.style = g_style.style
		#R11 <<

##display "hk first recv: ",g_hk_first_recv

        #Tan #R03
		SELECT	seedhk:style.style_desc,
				seedhk:style.short_desc,
				seedhk:style.supplier,
				seedhk:style.sup_sty,
				seedhk:style.season,
				seedhk:style.division,				#R14
				seedhk:style.class,
				seedhk:style.category,
				seedhk:style.unit_cost,
				seedhk:style.unit_sell,
				seedhk:style.orig_sell,
				seedhk:style.lchg_dte,
				seedhk:style.gst_perc,
				seedhk:style.fob_method, #R03
				seedhk:style.fob,
				seedhk:style.fob_cost,
				seedhk:style.story,   #R03
				seedhk:style.pos_del_flg		#R12
		INTO
			g_hk_style_desc,
			g_hk_short_desc,
			g_hk_supplier,
			g_hk_sup_sty,
			g_hk_season,
			g_hk_division,				#R14
			g_hk_class,	
			g_hk_category,
			g_hk_unit_cost,
			g_hk_unit_sell,
			g_hk_orig_sell,
			g_hk_lchg_dte,
			g_hk_gst_perc,
			g_hk_fob_method,  #R03
			g_hk_fob, 
			g_hk_fob_cost,
			g_hk_story,
			g_hk_pos_del_flg 		#R12

		FROM	seedhk:style
        WHERE 	seedhk:style.style = g_style.style
##display "orig sell: ",g_hk_orig_sell

        #R05 Tantest
         IF g_hk_story IS NULL THEN
             LET g_hk_story = g_style.story

		   	 SELECT	story_desc
			 INTO	p_hk_story_desc
        	 FROM    seedhk:story 
        	 WHERE   story = g_hk_story
         END IF
		#R02 <<
		#R10 >>
		SELECT	seedsin:style.style_desc,
				seedsin:style.short_desc,
				seedsin:style.supplier,
				seedsin:style.sup_sty,
				seedsin:style.season,
				seedsin:style.division,			#R14
				seedsin:style.class,
				seedsin:style.category,
				seedsin:style.unit_cost,
				seedsin:style.unit_sell,
				seedsin:style.orig_sell,
				seedsin:style.lchg_dte,
				seedsin:style.gst_perc,
				seedsin:style.fob_method, 
				seedsin:style.fob,
				seedsin:style.fob_cost,
				seedsin:style.story   
		INTO
			g_sin_style_desc,
			g_sin_short_desc,
			g_sin_supplier,
			g_sin_sup_sty,
			g_sin_season,
			g_sin_division,				#R14
			g_sin_class,	
			g_sin_category,
			g_sin_unit_cost,
			g_sin_unit_sell,
			g_sin_orig_sell,
			g_sin_lchg_dte,
			g_sin_gst_perc,
			g_sin_fob_method,  
			g_sin_fob, 
			g_sin_fob_cost,
			g_sin_story

		FROM	seedsin:style
        WHERE 	seedsin:style.style = g_style.style
##display "orig sell: ",g_sin_orig_sell

         IF g_sin_story IS NULL THEN
             LET g_sin_story = g_style.story

		   	 SELECT	story_desc
			 INTO	p_sin_story_desc
        	 FROM    seedsin:story 
        	 WHERE   story = g_sin_story
         END IF
		#R10 <<
		#NZ
		#R11 >>
		SELECT	seednz:style.style_desc,
				seednz:style.short_desc,
				seednz:style.supplier,
				seednz:style.sup_sty,
				seednz:style.season,
				seednz:style.division,			#R14
				seednz:style.class,
				seednz:style.category,
				seednz:style.unit_cost,
				seednz:style.unit_sell,
				seednz:style.orig_sell,
				seednz:style.lchg_dte,
				seednz:style.gst_perc,
				seednz:style.fob_method, 
				seednz:style.fob,
				seednz:style.fob_cost,
				seednz:style.story   
		INTO
			g_nz_style_desc,
			g_nz_short_desc,
			g_nz_supplier,
			g_nz_sup_sty,
			g_nz_season,
			g_nz_division,					#R14
			g_nz_class,	
			g_nz_category,
			g_nz_unit_cost,
			g_nz_unit_sell,
			g_nz_orig_sell,
			g_nz_lchg_dte,
			g_nz_gst_perc,
			g_nz_fob_method,  
			g_nz_fob, 
			g_nz_fob_cost,
			g_nz_story

		FROM	seednz:style
        WHERE 	seednz:style.style = g_style.style
##display "orig sell: ",g_nz_orig_sell

         IF g_nz_story IS NULL THEN
             LET g_nz_story = g_style.story

		   	 SELECT	story_desc
			 INTO	p_nz_story_desc
        	 FROM    seednz:story 
        	 WHERE   story = g_nz_story
         END IF
		#R11 <<
		#R21 >>
		LET p_prev_hk_supplier = g_hk_supplier 
		LET p_prev_sin_supplier = g_sin_supplier
		LET p_prev_nz_supplier = g_nz_supplier
		#R21 >>
		LET g_prev_hk_unit_sell = g_hk_unit_sell			#rxx
		LET g_prev_sg_unit_sell = g_sin_unit_sell			#rxx
		LET g_prev_nz_unit_sell = g_nz_unit_sell			#rxx
		#R03 >>
		CALL ui.Interface.refresh()
    	LET cb = ui.ComboBox.forName("formonly.r1")
    	IF cb IS NULL THEN
	    	ERROR "Form field not found in current form"
        	RETURN FALSE
    	END IF
    	CALL cb.clear()
		CALL cb.addItem("Air","Air")
    	CALL cb.addItem("Sea","Sea")
    	CALL cb.addItem("Local","Local")
		LET r1=  g_style.fob_method 

		CALL ui.Interface.refresh()
    	LET cb = ui.ComboBox.forName("formonly.r2")
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
		CALL cb.addItem("SGD","SGD")					
		LET r2=  g_style.fob 
		#R03 <<

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
		LET r8=  g_hk_fob_method 

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
		CALL cb.addItem("SGD","SGD")					
		LET r9=  g_hk_fob 
        #R03 >>
		#R10 >>
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
		LET sin17=  g_sin_fob_method 

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
		CALL cb.addItem("SGD","SGD")					
		LET sin18=  g_sin_fob 
		#R10 <<
		#NZ
		#R11 >>
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
		LET nz17=  g_nz_fob_method 

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
		CALL cb.addItem("SGD","SGD")					
		LET nz18=  g_nz_fob 
		#R11 <<

		LET r1x = g_style.web_desc1                         #R03
        LET r2x  = g_style.web_desc2                        #R03
        LET r3x =   g_style.web_desc3                       #R03
		LET g_style.lchg_dte = TODAY
		LET lstate = "GETLINE"
	END IF
	LET p_option = "OPTIONS: F1=ACCEPT F10=EXIT"
	DISPLAY p_option AT 22,1
	ATTRIBUTE (BLUE,REVERSE)
	
	WHILE lstate != "GETOUT"
		CASE
		## entry of data
		WHEN lstate = "GETLINE"
label retry:
			IF p_mode = "a" THEN
				LET g_lnl[1,80] = "ADD: enter data"
				DISPLAY g_lnl AT 2,1
				ATTRIBUTE(NORMAL)
			ELSE
				LET g_lnl[1,80] = "MODIFY: enter data"
				DISPLAY g_lnl AT 2,1
				ATTRIBUTE(NORMAL)
			END IF

    		INPUT BY NAME g_style.style_desc,
    					  g_style.short_desc,
    					  g_style.supplier,
    					  g_style.sup_sty,
    					  g_style.season,
    					  #R07 g_style.division,
    					  g_style.division,					#R14
    					  g_style.section,					#R07
    					  g_style.class,
    					  g_style.category,
    					  g_style.myer_desc,				#R22
    				      g_style.unit_cost,
    					  g_style.unit_sell,
    					  g_style.orig_sell,
    					  g_style.lchg_dte,
    					  g_style.del_flg,
					      r1,							#R03
					      r2,							#R03
						  g_style.fob_cost,	    		#R03
    					  g_style.fabric_type,
    					  g_style.story,
    					  g_style.style_type,				#R01
    					  g_style.catalogue,				#R02
    					  g_style.size_code,				#R19
    					  g_style.country_of_origin,
    					  g_style.classification,
    					  g_style.garment_cons,
    					  g_style.garment_dept,
    					  g_style.fabric_desc,				#R17
    					  g_style.fabric_content,
    					  g_style.page,						#R02
    					  g_style.web_care,					#R03

						  #hongkong
						  g_hk_style_desc,				#R02
						  g_hk_short_desc,				#R02
						  g_hk_supplier,				#R02
						  g_hk_sup_sty,					#R03
						  g_hk_season,					#R02
						  g_hk_division,				#R14
						  g_hk_class,					#R02
						  g_hk_category,				#R02
						  g_hk_unit_cost,					#R02
						  g_hk_unit_sell,					#R02
						  g_hk_orig_sell,					#R02
						  g_hk_lchg_dte,					#R02
						  r8,	  		     		#R03
						  r9,	    				#R03
						  g_hk_fob_cost,	    		
						  g_hk_story,	                #R03    		
						  #R10 >>
    					  #g_hk_country_of_origin,		
    					  #g_hk_classification,
    					  #g_hk_garment_cons,
    					  #g_hk_garment_dept,
						  #g_hk_page,
    					  ##g_hk_web_care,					
    					  #g_hk_fabric_content,
						 #singapore >>
						  g_sin_style_desc,				
						  g_sin_short_desc,				
						  g_sin_supplier,			
						  g_sin_sup_sty,				
						  g_sin_season,					
						  g_sin_division,			#R14
						  g_sin_class,					
						  g_sin_category,				
						  g_sin_unit_cost,					
						  g_sin_unit_sell,					
						  g_sin_orig_sell,				
						  g_sin_lchg_dte,					
						  sin17,	  		     		
						  sin18,	    				
						  g_sin_fob_cost,	    		
						  g_sin_story,	                
    					  #g_sin_country_of_origin,		
    					  #g_sin_classification,
    					  #g_sin_garment_cons,
    					  #g_sin_garment_dept,

						  #g_sin_page,
    					  #g_sin_web_care,					
    					  #g_sin_fabric_content,
						  #R10 <<
						 #nz >>
						#R11 >>
						  g_nz_style_desc,				
						  g_nz_short_desc,				
						  g_nz_supplier,			
						  g_nz_sup_sty,				
						  g_nz_season,					
						  g_nz_division,		#R14
						  g_nz_class,					
						  g_nz_category,				
						  g_nz_unit_cost,					
						  g_nz_unit_sell,					
						  g_nz_orig_sell,				
						  g_nz_lchg_dte,					
						  nz17,	  		     		
						  nz18,	    				
						  g_nz_fob_cost,	    		
						  g_nz_story,	                
						  #R11 <<
						  #web and images
						  g_style.web_style_desc,							#R03
    					  r1x,										#R03
    					  r2x,										#R03
    					  r3x,										#R03

    					  #R20 g_style.cat1,								#R03
    					  #R20 g_style.cat2,								#R03
    					  #R20 g_style.cat3,								#R03
    					  #R20 g_style.cat4,								#R03
    					  #R20 g_style.cat5,								#R03

						  #R13 >>
    					  g_style_webcat.dw_cat1,		
    					  g_style_webcat.dw_cat2,	
    					  g_style_webcat.dw_cat3,
    					  g_style_webcat.dw_cat4,	
    					  g_style_webcat.dw_cat5,	
						  #R13 <<

    					  g_style.assort1,					#R03
    					  g_style.assort2,					#R03
    					  g_style.assort3,					#R03
						  g_style.givex_id						#R18
			WITHOUT DEFAULTS
--#			ATTRIBUTE(NORMAL)


			#R15 >>
			ON IDLE 1800
				LET lstate = "GETOUT"
				EXIT INPUT
			#R15 <<

			#R19 >>
			BEFORE FIELD size_code
				IF p_mode = "u" THEN
					SELECT	LIMIT 1 ord_nbr
					FROM	po_lns
					WHERE	style = g_style.style

					IF status = NOTFOUND THEN		#no order found for this style
						#do nothing/allow change
					ELSE
						IF g_user = "slisa"
						OR g_user = "anthonyc"
						OR g_user = "scarley"
						OR g_user = "genero" THEN
							#do nothing/allow change
						ELSE
							NEXT FIELD fabric_desc
						END IF
					END IF
				END IF

			AFTER FIELD size_code
                IF g_style.size_code IS NOT NULL THEN
					LET	p_size_desc = NULL
  	               	SELECT  size_desc
					INTO	p_size_desc
                    FROM    sty_sizehdr
                    WHERE   size_code = g_style.size_code	
  
                    IF status = NOTFOUND THEN
	                	LET p_text = "invalid size code sz.1"
                        CALL messagebox(p_text,2)
                       	NEXT FIELD size_code
  	 				ELSE
                        DISPLAY BY NAME g_style.size_code,
									    p_size_desc
                        ATTRIBUTE(NORMAL)
  		            END IF
				ELSE
					IF p_mode = "a" THEN
	                     LET p_text = "must enter size code sz.2"
                         CALL messagebox(p_text,2)
                         NEXT FIELD size_code
					END IF
				END IF
			#R19 <<
				
			#R15 >>
			AFTER FIELD country_of_origin,
						classification

				CASE
                WHEN infield(country_of_origin)
                	IF g_style.country_of_origin IS NOT NULL THEN
  	                	SELECT  country_name
                        FROM    ax_country
                        #R15 WHERE   country_name = g_style.country_of_origin
                        WHERE   country = g_style.country_of_origin					#R15
  
                       IF status = NOTFOUND THEN
	                       LET p_text = "invalid country ax.1"
                          CALL messagebox(p_text,2)
                         	NEXT FIELD country_of_origin
  	 					ELSE
                            DISPLAY BY NAME g_style.country_of_origin
                            ATTRIBUTE(NORMAL)
  		               END IF
					END IF
                WHEN infield(classification)
                	IF g_style.classification IS NOT NULL THEN
            			##IF NOT check_numb(g_style.classification) THEN				#R15
                            ##LET p_text = "invalid customs code ax.2"				#R15
                            ##CALL messagebox(p_text,2)								#R15
                            ##NEXT FIELD classification								#R15
                         ##ELSE
							#LET	p_customs_desc = NULL							#R15
                            #SELECT  customs_desc
							##INTO	p_customs_desc								#R15
                            #FROM    ax_customs
                            #WHERE   customs_desc = g_style.classification
                            ##WHERE   customs = g_style.classification					#R15

                            #IF status = NOTFOUND THEN
                                  #LET p_text = "invalid customs code ax.2"
                                  #CALL messagebox(p_text,2)
                                  #NEXT FIELD classification
                            #END IF
                            DISPLAY BY NAME g_style.classification
									        ##p_customs_desc							#R15
                            ATTRIBUTE(NORMAL)
						##END IF
                      END IF
                 END CASE

				#R19>>
                 ON ACTION   zoom INFIELD size_code
						CALL size_query() RETURNING p_size,p_size_desc
                        IF p_size IS NOT NULL THEN
                            LET g_style.size_code = p_size
                            DISPLAY BY NAME g_style.size_code,
										    p_size_desc
                            ATTRIBUTE(NORMAL)
						END IF
				#R19 >>

                 ON ACTION   zoom20 INFIELD country_of_origin
						CALL country_query() RETURNING p_country,p_country_name
                        IF p_country IS NOT NULL THEN
                            #R15 LET g_style.country_of_origin =  p_country_name
                            LET g_style.country_of_origin =  p_country
                            DISPLAY BY NAME g_style.country_of_origin,
										    p_country_name						#R15
                            ATTRIBUTE(NORMAL)
						END IF

					#R17 >>
					ON ACTION zoom INFIELD garment_cons
						CALL cons_query() RETURNING p_cons
						IF p_cons IS NOT NULL THEN					#R23
							LET g_style.garment_cons = p_cons
            				DISPLAY BY NAME g_style.garment_cons
							ATTRIBUTE(NORMAL)
						END IF

               		ON ACTION   zoom INFIELD fabric_content
						CALL fabric_content_query() RETURNING p_fabric,p_fabric_desc
                    	IF p_fabric_desc IS NOT NULL THEN
                    		LET g_style.fabric_content =  p_fabric_desc
                        	DISPLAY BY NAME g_style.fabric_content
                        	ATTRIBUTE(NORMAL)
						END IF
					#R17 <<

                    ON ACTION   zoom21 INFIELD classification
						CALL customs_query() RETURNING p_customs,p_customs_desc
                        IF p_customs IS NOT NULL THEN
                            LET g_style.classification =  p_customs_desc
                            ##LET g_style.classification =  p_customs						#R15
                            DISPLAY BY NAME g_style.classification
									        ##p_customs_desc							#R15
                            ATTRIBUTE(NORMAL)
						END IF
			#R02 >>
			BEFORE FIELD g_hk_style_desc
			#	DISPLAY BY NAME g_hk_style_desc
				#ATTRIBUTE(REVERSE,WHITE)
				IF p_mode = "u" THEN
					SELECT	*
					FROM	seedhk:style
					WHERE	style = g_style.style

					IF status = NOTFOUND THEN
                		MESSAGE "invalid SeedHK style"
 						##LET p_text = "invalid HK style "
 						LET p_text = "\nthis style is not existed ",
 						             "\nin HongKong database ",
 						             "\nPlease use the CopyHKStyle option "
						CALL messagebox(p_text,1)  		
						##SLEEP 2
						NEXT FIELD style_desc				#R10
					END IF
				END IF
					#R10 >>
			BEFORE FIELD g_sin_style_desc
				IF p_mode = "u" THEN
					SELECT	*
					FROM	seedsin:style
					WHERE	style = g_style.style

					IF status = NOTFOUND THEN
                		MESSAGE "invalid Seed Sin style"
						##NEXT FIELD g_sin_country_of_origin
 						LET p_text = "\nthis style is not existed ",
 						             "\nin Singapore database ",
 						             "\nPlease use the CopySinStyle option "
						CALL messagebox(p_text,1)  		
						NEXT FIELD style_desc				#R10
					END IF
					#R10 <<
				END IF
			#NZ
			#R11 >>
			BEFORE FIELD g_nz_style_desc
				IF p_mode = "u" THEN
					SELECT	*
					FROM	seednz:style
					WHERE	style = g_style.style

					IF status = NOTFOUND THEN
                		MESSAGE "invalid Seed NZ style"
 						LET p_text = "\nthis style is not existed ",
 						             "\nin NZ database ",
 						             "\nPlease use the CopyNZStyle option "
						CALL messagebox(p_text,1)  		
						NEXT FIELD style_desc				
					END IF
				END IF
				#R11 <<

			AFTER FIELD style_desc
				IF p_mode = "a" THEN
					LET g_hk_style_desc = g_style.style_desc
					DISPLAY BY NAME g_hk_style_desc
					ATTRIBUTE(NORMAL)
					#R10 >>
					LET g_sin_style_desc = g_style.style_desc
					DISPLAY BY NAME g_sin_style_desc
					ATTRIBUTE(NORMAL)
					#R10 <<
					#R11 >>
					LET g_nz_style_desc = g_style.style_desc
					DISPLAY BY NAME g_nz_style_desc
					ATTRIBUTE(NORMAL)
					#R11 <<
				END IF

			#R03 >>
			AFTER FIELD sup_sty
				LET g_hk_sup_sty = g_style.sup_sty
				DISPLAY BY NAME g_hk_sup_sty
				ATTRIBUTE(NORMAL)
			#R03 <<
				#R10 >>
				LET g_sin_sup_sty = g_style.sup_sty
				DISPLAY BY NAME g_sin_sup_sty
				ATTRIBUTE(NORMAL)
				#R10 <<
				#R11 >>
				LET g_nz_sup_sty = g_style.sup_sty
				DISPLAY BY NAME g_nz_sup_sty
				ATTRIBUTE(NORMAL)
				#R11 <<

			AFTER FIELD g_hk_style_desc
				IF g_hk_style_desc IS NULL THEN
					ERROR "must enter HK style description"
					ATTRIBUTE(RED)
					LET p_text = "must enter HK style description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_style_desc
				END IF

			AFTER FIELD g_hk_short_desc
				IF g_hk_short_desc IS NULL THEN
					ERROR "must enter style short description"
					ATTRIBUTE(RED)
					LET p_text = "must enter HK style short description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_short_desc
				END IF
			#R02 <<

			#R10 >>
			AFTER FIELD g_sin_style_desc
				IF g_sin_style_desc IS NULL THEN
					ERROR "must enter SIN style description"
					ATTRIBUTE(RED)
					LET p_text = "must enter SIN style description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_sin_style_desc
				END IF

			AFTER FIELD g_sin_short_desc
				IF g_sin_short_desc IS NULL THEN
					ERROR "must enter SIN style short description"
					ATTRIBUTE(RED)
					LET p_text = "must enter SIN style short description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_sin_short_desc
				END IF
			#R10 <<

			#R11 >>
			AFTER FIELD g_nz_style_desc
				IF g_nz_style_desc IS NULL THEN
					ERROR "must enter NZ style description"
					ATTRIBUTE(RED)
					LET p_text = "must enter NZ style description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_nz_style_desc
				END IF

			AFTER FIELD g_nz_short_desc
				IF g_nz_short_desc IS NULL THEN
					ERROR "must enter NZ style short description"
					ATTRIBUTE(RED)
					LET p_text = "must enter NZ style short description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_nz_short_desc
				END IF
			#R11 <<

			AFTER FIELD short_desc
			 	IF p_mode = "a" THEN
					LET g_hk_short_desc = g_style.short_desc
					DISPLAY BY NAME g_hk_short_desc
					ATTRIBUTE(NORMAL)
					#R10 >>
					LET g_sin_short_desc = g_style.short_desc
					DISPLAY BY NAME g_sin_short_desc
					ATTRIBUTE(NORMAL)
					#R10 <<
					#R11 >>
					LET g_nz_short_desc = g_style.short_desc
					DISPLAY BY NAME g_nz_short_desc
					ATTRIBUTE(NORMAL)
					#R11 <<
				END IF
			#R02 <<

			#R17 >>
    		 BEFORE FIELD garment_dept
display "before field ",g_style.class
				SELECT	department_name
				INTO	g_style.garment_dept
				FROM	class a, class_dept b
				WHERE	a.department = b.department
				AND		class = g_style.class

				DISPLAY BY NAME g_style.garment_dept
				ATTRIBUTE(NORMAL)
			#R17 <<

			#R03 >>>>
    		 #R10 AFTER FIELD garment_dept
				#R10 NEXT FIELD  style_desc
			#R10 >>
    		 #AFTER FIELD fabric_content
				#IF p_mode = "u" THEN
					#NEXT FIELD  style_desc
				#END IF

			BEFORE FIELD supplier,
				         season,
				    	 #R07 division,
				    	 section,				#R07
				         class,
						 category,
						 fabric_type,
					     story 

                    {
			    	SELECT	story_desc
			  		INTO	p_hk_story_desc
        			FROM    seedhk:story 
        			WHERE   story = g_hk_story
					DISPLAY BY NAME p_hk_story_desc
                    }

				LET p_option = "OPTIONS: F1=ACCEPT F8=SEARCH F10=EXIT"
    			DISPLAY p_option AT 22,1
				ATTRIBUTE(REVERSE,BLUE)

			#R09 >>	
			BEFORE FIELD orig_sell
            	IF g_first_recv IS NOT NULL THEN
                	MESSAGE "AU Stock has been received - can't change original sell price "
					SLEEP 2
					MESSAGE ""
                	LET p_text =  "AU Stock has been received - can't change original sell price "
					CALL messagebox(p_text,1)  		
					NEXT FIELD unit_sell
            	END IF
			#R09 <<
			#R12 >>
			IF p_mode = "u" THEN
				LET p_orig_sell_temp = g_style.orig_sell
			END IF
			#R12 <<
			
			BEFORE FIELD unit_sell
            	IF g_first_recv IS NOT NULL THEN
                	DISPLAY "Stock has been received - use Mark Down Sys to change last selling price"
                	ERROR "Stock has been received - use the Mark Down System to change last selling price"
					##SLEEP 2
					MESSAGE ""
					#R02 NEXT FIELD short_desc
                	LET p_text =  "\nAU Stock has been received - use Mark Down System ",
							      "\nto change last selling price"
					CALL messagebox(p_text,1)  		
    				NEXT FIELD r1							#R10
            	END IF
				IF p_mode = "u" THEN
					LET p_unit_sell_temp = g_style.unit_sell
				END IF

			AFTER FIELD unit_sell
				#R08 >>
         		IF g_hk_first_recv IS NULL THEN
					SELECT	hkd_price
					INTO	g_hk_unit_sell
					FROM	price_table
					WHERE	aud_price = g_style.unit_sell

					DISPLAY BY NAME g_hk_unit_sell
					ATTRIBUTE(NORMAL)

					LET p_hk_unit_sellx = g_hk_unit_sell
					DISPLAY BY NAME p_hk_unit_sellx
					ATTRIBUTE(NORMAL)
				END IF
				#R08 <<
				#R10 >>
         			IF g_sin_first_recv IS NULL THEN
						#R16 >>
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
						ELSE						#R16 >>
						 	SELECT	sgd_price
						 	INTO	g_sin_unit_sell
						 	FROM	price_table_old
						 	WHERE	aud_price = g_style.unit_sell
						END IF
					#R16 <<

						 DISPLAY BY NAME g_sin_unit_sell
						 ATTRIBUTE(NORMAL)

						LET p_sin_unit_sellx = g_sin_unit_sell
						DISPLAY BY NAME p_sin_unit_sellx
						ATTRIBUTE(NORMAL)
					END IF
				#R10 <<
				#R11 >>
         			IF g_nz_first_recv IS NULL THEN
						 SELECT	nzd_price
						 INTO	g_nz_unit_sell
						 FROM	price_table
						 WHERE	aud_price = g_style.unit_sell

						 DISPLAY BY NAME g_nz_unit_sell
						 ATTRIBUTE(NORMAL)

						LET p_nz_unit_sellx = g_nz_unit_sell
						DISPLAY BY NAME p_nz_unit_sellx
						ATTRIBUTE(NORMAL)
					END IF
				#R11 <<

            	IF g_first_recv IS NULL THEN
					#R10 
					IF g_style.unit_sell IS NULL 
					OR g_style.unit_sell= 0 THEN						#R10
						ERROR "must enter AUS last sell price "
						ATTRIBUTE(RED)
						LET p_text =  "must enter AU last sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD unit_sell
					END IF
					#R10
					LET g_style.orig_sell = g_style.unit_sell
					DISPLAY BY NAME g_style.orig_sell
					ATTRIBUTE(NORMAL)

					#R12 >>
					IF p_unit_sell_temp != g_style.unit_sell THEN
                    	LET g_style.pos_del_flg = "A"
                    END IF
					#R12 <<
				END IF

			#R12 >>
			AFTER FIELD orig_sell
            	IF g_first_recv IS NULL THEN
					IF p_orig_sell_temp != g_style.orig_sell THEN
                   		LET g_style.pos_del_flg = "A"
					END IF
                END IF
			#R12 <<


			#R01 >>
			AFTER FIELD unit_cost
            	IF g_style.unit_cost != p_prev_unit_cost THEN
                	LET g_cost_last_change = TRUE
            	END IF

            #R01 <<

			#R09 >>
			BEFORE FIELD g_hk_orig_sell
            	IF g_hk_first_recv IS NOT NULL THEN
                	DISPLAY "Stock has been received - use the Mark Down System to change last selling price"
					##SLEEP 2
					MESSAGE ""
					#R10 NEXT FIELD country_of_origin
                	LET p_text =  "\nHK Stock has been received - use the Mark Down System ",
								  "\nto change last selling price"
					CALL messagebox(p_text,1)  		
					NEXT FIELD r8					#R10
            	END IF
			#R09 <<

			#R12 >>
			IF p_mode = "u" THEN
				LET p_hk_orig_sell_temp = g_hk_orig_sell
##	display "hk unit sell :", p_hk_unit_sell_temp , g_hk_unit_sell
			END IF
			#R12 <<

			#R02 >>
			BEFORE FIELD g_hk_unit_sell
            	IF g_hk_first_recv IS NOT NULL THEN
                	DISPLAY "Stock has been received - use the Mark Down System to change last selling price"
					##SLEEP 2
					MESSAGE ""
					#R10 NEXT FIELD country_of_origin
                	LET p_text =  "\nHK Stock has been received - use the Mark Down System ",
								  "\nto change last selling price"
					CALL messagebox(p_text,1)  		
					NEXT FIELD r8					#R10
            	END IF

				IF p_mode = "u" THEN
					LET p_hk_unit_sell_temp = g_hk_unit_sell
##	display "hk unit sell :", p_hk_unit_sell_temp , g_hk_unit_sell
				END IF

			AFTER FIELD g_hk_unit_sell
            	IF g_hk_first_recv IS NULL THEN
					LET g_hk_orig_sell = g_hk_unit_sell
					DISPLAY BY NAME g_hk_orig_sell
					ATTRIBUTE(NORMAL)
				END IF

            	IF g_hk_first_recv IS NULL THEN				#R10
					IF g_hk_unit_sell IS NULL 
					OR g_hk_unit_sell =0 THEN						#R10
						ERROR "must enter HK last sell price "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HK last sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_unit_sell
					END IF
					#R12 >>
                	IF p_hk_unit_sell_temp != g_hk_unit_sell THEN
                    	LET g_hk_pos_del_flg = "A"
                	END IF
					#R12 <<
				END IF

			  #R12 >>
            AFTER FIELD g_hk_orig_sell
            	IF g_hk_first_recv IS NULL THEN				#R10
                	IF p_hk_orig_sell_temp != g_hk_orig_sell THEN
                    	LET g_hk_pos_del_flg = "A"
                	END IF
				END IF
            #R12 <<

	##display "hk unit sell1 :", p_hk_unit_sell_temp , g_hk_unit_sell
			AFTER FIELD g_hk_unit_cost
            	IF g_hk_unit_cost != p_hk_prev_unit_cost THEN
                	LET g_hk_cost_last_change = TRUE
            	END IF
				#R02 >>
				IF g_hk_unit_cost IS NULL THEN
					ERROR "must enter HK unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HK unit cost "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_unit_cost
				END IF
				#R02 <
            #R02 <<

			#R10 >>
			BEFORE FIELD g_sin_orig_sell
            	IF g_sin_first_recv IS NOT NULL THEN
                	DISPLAY "Stock has been received - use the Mark Down System to change last selling price"
                	LET p_text =  "\nSingapore stock has been received - use the Mark Down System",
									"\nto change last selling price"
					CALL messagebox(p_text,1)  		
					##SLEEP 2
					MESSAGE ""
					NEXT FIELD sin17
            	END IF

			BEFORE FIELD g_sin_unit_sell
            	IF g_sin_first_recv IS NOT NULL THEN
                	LET p_text =  "\nSingapore stock has been received - use the Mark Down System",
									"\nto change last selling price"
					CALL messagebox(p_text,1)  		
                	DISPLAY "Stock has been received - use the Mark Down System to change last selling price"
					##SLEEP 2
					MESSAGE ""
					NEXT FIELD sin17
            	END IF

				IF p_mode = "u" THEN
					LET p_sin_unit_sell_temp = g_sin_unit_sell
##	display "sin unit sell :", p_sin_unit_sell_temp , g_sin_unit_sell
				END IF

			AFTER FIELD g_sin_unit_sell
            	IF g_sin_first_recv IS NULL THEN
					LET g_sin_orig_sell = g_sin_unit_sell
					DISPLAY BY NAME g_sin_orig_sell
					ATTRIBUTE(NORMAL)
				END IF

            	IF g_sin_first_recv IS NULL THEN				
					IF g_sin_unit_sell IS NULL 
					OR g_sin_unit_sell =0 THEN						
						#R16 >>
						LET	p_date_insert = NULL
						SELECT	date_insert
						INTO	p_date_insert
						FROM	seedsin:style
						WHERE	style = g_style.style 

display "insert date: ",p_date_insert," ",g_style.style

						IF p_date_insert >= "251215" THEN
						 	SELECT	sgd_price
						 	INTO	g_sin_unit_sell
						 	FROM	price_table
						 	WHERE	aud_price = g_style.unit_sell
						ELSE						#R16 >>
						 	SELECT	sgd_price
						 	INTO	g_sin_unit_sell
						 	FROM	price_table_old
						 	WHERE	aud_price = g_style.unit_sell
						END IF 
					#R16 <<

						DISPLAY BY NAME g_sin_unit_sell
						ATTRIBUTE(NORMAL)
						ERROR "must enter SIN last sell price "
						ATTRIBUTE(RED)

						IF g_sin_unit_sell IS NULL 
						OR g_sin_unit_sell =0 THEN						
							LET p_text =  "must enter SIN last sell price "
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_unit_sell
						END IF
					END IF
				END IF

	##display "sin unit sell1 :", p_sin_unit_sell_temp , g_sin_unit_sell
			AFTER FIELD g_sin_unit_cost
            	IF g_sin_unit_cost != p_sin_prev_unit_cost THEN
                	LET g_sin_cost_last_change = TRUE
            	END IF

				IF g_sin_unit_cost IS NULL THEN
					ERROR "must enter SIN unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter SIN unit cost "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_sin_unit_cost
				END IF
				#R10 <<
			#R11 >>
			BEFORE FIELD g_nz_orig_sell
            	IF g_nz_first_recv IS NOT NULL THEN
                	DISPLAY "Stock has been received - use the Mark Down System to change last selling price"
                	LET p_text =  "\nNZ stock has been received - use the Mark Down System",
									"\nto change last selling price"
					CALL messagebox(p_text,1)  		
					##SLEEP 2
					MESSAGE ""
					NEXT FIELD nz17
            	END IF

			BEFORE FIELD g_nz_unit_sell
            	IF g_nz_first_recv IS NOT NULL THEN
                	LET p_text =  "\nNZ stock has been received - use the Mark Down System",
									"\nto change last selling price"
					CALL messagebox(p_text,1)  		
                	DISPLAY "Stock has been received - use the Mark Down System to change last selling price"
					##SLEEP 2
					MESSAGE ""
					NEXT FIELD nz17
            	END IF

				IF p_mode = "u" THEN
					LET p_nz_unit_sell_temp = g_nz_unit_sell
##	display "nz unit sell :", p_nz_unit_sell_temp , g_nz_unit_sell
				END IF

			AFTER FIELD g_nz_unit_sell
            	IF g_nz_first_recv IS NULL THEN
					LET g_nz_orig_sell = g_nz_unit_sell
					DISPLAY BY NAME g_nz_orig_sell
					ATTRIBUTE(NORMAL)
				END IF

            	IF g_nz_first_recv IS NULL THEN				
					IF g_nz_unit_sell IS NULL 
					OR g_nz_unit_sell =0 THEN						
						 SELECT	nzd_price
						 INTO	g_nz_unit_sell
						 FROM	price_table
						 WHERE	aud_price = g_style.unit_sell

						DISPLAY BY NAME g_nz_unit_sell
						ATTRIBUTE(NORMAL)
						ERROR "must enter NZ last sell price "
						ATTRIBUTE(RED)

						IF g_nz_unit_sell IS NULL 
						OR g_nz_unit_sell =0 THEN						
							LET p_text =  "must enter NZ last sell price "
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_unit_sell
						END IF
					END IF
				END IF

	##display "nz unit sell1 :", p_nz_unit_sell_temp , g_nz_unit_sell
			AFTER FIELD g_nz_unit_cost
            	IF g_nz_unit_cost != p_nz_prev_unit_cost THEN
                	LET g_nz_cost_last_change = TRUE
            	END IF

				IF g_nz_unit_cost IS NULL THEN
					ERROR "must enter NZ unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter NZ unit cost "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_nz_unit_cost
				END IF
				#R11 <<

			AFTER FIELD  supplier,
				         season,
				    	 division,					#R14
				    	 section,					#R07
				         class,
						 category,
						 myer_desc,					#R22
						 fabric_type,
					     story ,
						 style_type,					#R03 
						 #R20 cat1,					#R03
						 #R20 cat2,					#R03
						 #R20 cat3,					#R03
						 #R20 cat4,					#R03
						 #R20 cat5,					#R03
						 dw_cat1,				#R13
						 dw_cat2,				#R13
						 dw_cat3,				#R13
						 dw_cat4,				#R13
						 dw_cat5,				#R13
						 assort1,				#R03
						 assort2,				#R03
						 assort3,				#R03
				         givex_id				#R18
				CASE   
				WHEN infield(supplier)
					IF g_style.supplier IS NOT NULL THEN
						#R21 >>
			 			IF p_mode = "a" THEN
							SELECT	supplier_name
							INTO	p_supplier_name
							FROM	supplier
							WHERE	supplier = g_style.supplier
							AND		archive_flag = "N"					#R21
						ELSE
							IF p_prev_supplier != g_style.supplier THEN
								SELECT	supplier_name
								INTO	p_supplier_name
								FROM	supplier
								WHERE	supplier = g_style.supplier
								AND		archive_flag = "N"					#R21
							ELSE
								SELECT	supplier_name
								INTO	p_supplier_name
								FROM	supplier
								WHERE	supplier = g_style.supplier
							END IF
						END IF	
						#R21 <<

						LET p_status = status
##display "supp not found: ", status
						IF p_status = NOTFOUND THEN
						##IF p_status = 100 THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid AU supplier"
							CALL messagebox(p_text,1)  		
							NEXT FIELD supplier
						END IF
						LET g_hk_supplier = g_style.supplier			#R03
						LET p_hk_supplier_name = p_supplier_name		#R03
						DISPLAY BY NAME p_supplier_name,
								        g_hk_supplier,					#R03
										p_hk_supplier_name				#R03
						ATTRIBUTE(NORMAL)
						#R10 >>
						LET g_sin_supplier = g_style.supplier		
						LET p_sin_supplier_name = p_supplier_name		
						DISPLAY BY NAME g_sin_supplier,					
										p_sin_supplier_name				
						ATTRIBUTE(NORMAL)
						#R10 <<
						#R11 >>
						LET g_nz_supplier = g_style.supplier		
						LET p_nz_supplier_name = p_supplier_name		
						DISPLAY BY NAME g_nz_supplier,					
										p_nz_supplier_name				
						ATTRIBUTE(NORMAL)
						#R11 <<
					END IF
				WHEN infield(season)
					IF g_style.season IS NOT NULL THEN
						SELECT	season_desc
						INTO	p_season_desc
						FROM	season
						WHERE	season = g_style.season

						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid AU season"
							CALL messagebox(p_text,1)  		
							NEXT FIELD season
						END IF
		   #R03 			LET g_hk_season = g_style.season					#R03
		   #R03 			LET p_hk_season_desc = p_season_desc				#R03
						DISPLAY BY NAME p_season_desc,
										g_hk_season, 					#R03
										g_sin_season ,					#R10
										g_nz_season 					#R11
#R03 										p_hk_season_desc					#R03
						ATTRIBUTE(NORMAL)
					END IF

				#R14 >>
				WHEN infield(division)
					IF g_style.division IS NOT NULL THEN
						SELECT	division_name
						INTO	p_division_name
						FROM	division
						WHERE	division = g_style.division

						IF status = NOTFOUND THEN
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid division"
							CALL messagebox(p_text,1)  		
							NEXT FIELD division
						END IF
						DISPLAY BY NAME p_division_name
						ATTRIBUTE(NORMAL)
					END IF
				#R14 <<

				#R07 WHEN infield(division)
				WHEN infield(section)							#R07
					#R07 IF g_style.division IS NOT NULL THEN
						#R07 SELECT	division_name
						#R07 INTO	p_division_name
						#R07 FROM	division
						#R07 WHERE	division = g_style.division
						#R07 >>
						IF g_style.section IS NOT NULL THEN
							SELECT	section_name
							INTO	p_section_name
							 FROM	section
							 WHERE	section = g_style.section

							IF status = NOTFOUND THEN
								#R07 ERROR "invalid division"
								ERROR "invalid section"
								ATTRIBUTE(RED)
								LET p_text =  "invalid section"
								CALL messagebox(p_text,1)  		
								#R07 NEXT FIELD division
								NEXT FIELD section					#R07
							END IF
							#R07 DISPLAY BY NAME p_division_name
							DISPLAY BY NAME p_section_name			#R07
							ATTRIBUTE(NORMAL)
						END IF

				WHEN infield(class)
					IF g_style.class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_class_desc
						FROM	class
						WHERE	class = g_style.class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid AU class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD class
						END IF
						LET g_hk_class = g_style.class					#R03
						LET p_hk_class_desc = p_class_desc				#R03
						LET g_sin_class = g_style.class					#R10
						LET p_sin_class_desc = p_class_desc				#R10
						LET g_nz_class = g_style.class					#R11
						LET p_nz_class_desc = p_class_desc				#R11
						DISPLAY BY NAME p_class_desc,
									    g_hk_class,						#R03
									    p_hk_class_desc,				#R03
									    g_sin_class,					#R10
									    p_sin_class_desc,				#R10
									    g_nz_class,					#R11
									    p_nz_class_desc				#R11
						ATTRIBUTE(NORMAL)
						#R17 >>
						SELECT	department_name
						INTO	g_style.garment_dept
						FROM	class a, class_dept b
						WHERE	a.department = b.department
						AND		class = g_style.class
		
						DISPLAY BY NAME g_style.garment_dept
						ATTRIBUTE(NORMAL)
						#R17 <<
					END IF
				#R02 <<
				#IF g_style.fabric_type IS NULL THEN
				WHEN infield(category)
					IF g_style.category IS NOT NULL THEN
						#R22 SELECT	category.category_name
						LET p_myer_name = NULL										#R22
						SELECT	category.category_name,myer_product_type			#R22
						INTO	p_category_name,p_myer_name							#R22
        				FROM    class_cat, category
        				WHERE   class_cat.class     = g_style.class    
                		AND		class_cat.category  = g_style.category  
                		AND		category.category   = g_style.category
						AND		class_cat.category = category.category

						IF status = NOTFOUND THEN
							ERROR "invalid category for selected class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid AU category for selected class"
							CALL messagebox(p_text,1)  		
							#NEXT FIELD category
							NEXT FIELD class
						END IF

						#R22 >>
						IF p_myer_name IS NULl THEN
							ERROR "invalid Myer Product Type "
							ATTRIBUTE(RED)
							LET p_text =  "invalid Myer Product type"
							CALL messagebox(p_text,1)  		
							NEXT FIELD category
						END IF
						#R22 <<

						LET g_hk_category = g_style.category				#R03
						LET p_category_name = p_category_name				#R03
						LET g_sin_category = g_style.category				#R10
						LET g_nz_category = g_style.category				#R11
						DISPLAY BY NAME p_category_name,
									    g_hk_category,						#R03
									    g_sin_category,						#R10
									    g_nz_category,						#R11
										p_category_name						#R03
						ATTRIBUTE(NORMAL)
					END IF
				#R22 >>
				WHEN infield(myer_desc)
			 		IF p_mode = "a" THEN
						LET  g_style.myer_desc = p_myer_name
						IF g_style.myer_desc IS NULL THEN
							LET p_text =  "must enter Myer description"
							CALL messagebox(p_text,1)  		
							NEXT FIELD myer_desc
						END IF
					ELSE
						IF g_style.myer_desc IS  NULL THEN
							LET  g_style.myer_desc = p_myer_name
						END IF
					END IF
					DISPLAY BY NAME g_style.myer_desc
					ATTRIBUTE(NORMAL)
				#R22 <<	
				WHEN infield(fabric_type)
					IF g_style.fabric_type IS NOT NULL THEN
						SELECT	fabric_desc
						INTO	p_fabric_desc
						FROM	fabric_type
						WHERE	fabric_type = g_style.fabric_type

						IF status = NOTFOUND THEN
							ERROR "invalid fabric"
							ATTRIBUTE(RED)
							LET p_text =  "invalid AU fabric"
							CALL messagebox(p_text,1)  		
							NEXT FIELD fabric_type
						END IF
						DISPLAY BY NAME p_fabric_desc
						ATTRIBUTE(NORMAL)
					END IF
				WHEN infield(story)
					IF g_style.story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_story_desc
						FROM	story
						WHERE	story = g_style.story

						IF status = NOTFOUND THEN
							ERROR "invalid story"
							ATTRIBUTE(RED)
							LET p_text =  "invalid AU story"
							CALL messagebox(p_text,1)  		
							NEXT FIELD story
						END IF
						DISPLAY BY NAME p_story_desc
						ATTRIBUTE(NORMAL)
					END IF
				#R03 >>
				#WHEN infield(catalogue)
					#IF g_style.catalogue = "N" THEN
						#NEXT FIELD style_desc
					#END IF
					#LET p_style = g_style.style
					#LET p_style_desc = g_style.style_desc
					#DISPLAY BY NAME p_style,
								    #p_style_desc
					#ATTRIBUTE(NORMAL)
				#R20 WHEN infield(cat1)
					#R20 IF	g_style.cat1 IS NOT  NULL THEN
						#R20 LET p_cat1_name = NULL
						#R20 SELECT	web_cat_name
						#R20 INTO	p_cat1_name
						#R20 FROM	web_cat1
						#R20 WHERE	web_cat = g_style.cat1 
				
						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "category 1 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat1
						#R20 END IF


						#R20 DISPLAY BY NAME g_style.cat1
						#R20 ATTRIBUTE (NORMAL)
						#R20 DISPLAY BY NAME p_cat1_name
						#R20 ATTRIBUTE (NORMAL)

						#R20 IF g_style.sub_cat1 IS NULL THEN
 							#R20 LET p_text = "must enter sub category 1  "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat1
						#R20 END IF

						#R20 SELECT	*
						#R20 FROM	web_cat
						#R20 WHERE	web_cat1 = g_style.cat1
						#R20 AND		web_cat2 = g_style.sub_cat1
						#R20 AND		web_cat3 = g_style.sub_sub_cat1
#R20 
						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "hierarcy category 1 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat1
						#R20 END IF
					#R20 ELSE
						#R20 LET g_style.sub_cat1 = NULL
						#R20 LET	g_style.sub_sub_cat1 = NULL
						#R20 DISPLAY BY NAME g_style.cat1,
						                #R20 g_style.sub_cat1,
						                #R20 g_style.sub_sub_cat1
						#R20 ATTRIBUTE (NORMAL)
					#R20 END IF
				#R20 WHEN infield(cat2)
					#R20 IF	g_style.cat2 IS  NOT NULL THEN
						#R20 LET p_cat2_name = NULL
						#R20 SELECT	web_cat_name
						#R20 INTO	p_cat2_name
						#R20 FROM	web_cat1
						#R20 WHERE	web_cat = g_style.cat2
			#R20 	
						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "category 2 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat2
						#R20 END IF
#R20 
						#R20 IF g_style.sub_cat2 IS NULL THEN
 							#R20 LET p_text = "must enter sub category 2  "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat2
						#R20 END IF

						#R20 SELECT	*
						#R20 FROM	web_cat
						#R20 WHERE	web_cat1 = g_style.cat2
						#R20 AND		web_cat2 = g_style.sub_cat2
						#R20 AND		web_cat3 = g_style.sub_sub_cat2
#R20 
						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "hierarchy category 2 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat2
						#R20 END IF
						#R20 DISPLAY BY NAME g_style.cat2
						#R20 ATTRIBUTE (NORMAL)
						#R20 DISPLAY BY NAME p_cat2_name
						#R20 ATTRIBUTE (NORMAL)
					#R20 ELSE
						#R20 LET g_style.sub_cat2 = NULL
						#R20 LET	g_style.sub_sub_cat2 = NULL
						#R20 DISPLAY BY NAME g_style.cat2,
						                #R20 g_style.sub_cat2,
						                #R20 g_style.sub_sub_cat2
						#R20#R20  ATTRIBUTE (NORMAL)
					#R20 END IF
				#R20 WHEN infield(cat3)
					#R20 IF	g_style.cat3 IS NOT  NULL THEN
						#R20 LET p_cat3_name = NULL
						#R20 SELECT	web_cat_name
						#R20 INTO	p_cat3_name
						#R20 FROM	web_cat1
						#R20 WHERE	web_cat = g_style.cat3 
			#R20 	
						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "category 3 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat3
						#R20 END IF
						#R20 DISPLAY BY NAME g_style.cat3
						#R20 ATTRIBUTE (NORMAL)
						#R20 DISPLAY BY NAME p_cat3_name
						#R20 ATTRIBUTE (NORMAL)

						#R20 IF g_style.sub_cat3 IS NULL THEN
 							#R20 LET p_text = "must enter sub category 3  "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat3
						#R20 END IF
#R20 
						#R20 SELECT	*
						#R20 FROM	web_cat
						#R20 WHERE	web_cat1 = g_style.cat3
						#R20 AND		web_cat2 = g_style.sub_cat3
						#R20#R20  AND		web_cat3 = g_style.sub_sub_cat3

						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "hierarchy category 3 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat3
						#R20 END IF
					#R20 ELSE
						#R20 LET g_style.sub_cat3 = NULL
						#R20 LET	g_style.sub_sub_cat3 = NULL
						#R20 DISPLAY BY NAME g_style.cat3,
						                #R20 g_style.sub_cat3,
						                #R20 g_style.sub_sub_cat3
						#R20 ATTRIBUTE (NORMAL)
					#R20 END IF
				#R20 WHEN infield(cat4)
					#R20 IF	g_style.cat4 IS  NOT NULL THEN
						#R20 LET p_cat4_name = NULL
						#R20 SELECT	web_cat_name
						#R20#R20  INTO	p_cat4_name
						#R20 FROM	web_cat1
						#R20 WHERE	web_cat = g_style.cat4

						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "category 4 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat4
						#R20 END IF
						#R20 DISPLAY BY NAME g_style.cat4
						#R20 ATTRIBUTE (NORMAL)
						#R20 DISPLAY BY NAME p_cat4_name
						#R20 ATTRIBUTE (NORMAL)
						#R20 IF g_style.sub_cat4 IS NULL THEN
 							#R20 LET p_text = "must enter sub category 4  "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat4
						#R20 END IF
						#R20 SELECT	*
						#R20 FROM	web_cat
						#R20 WHERE	web_cat1 = g_style.cat4
						#R20 AND		web_cat2 = g_style.sub_cat4
						#R20 AND		web_cat3 = g_style.sub_sub_cat4

						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "hierarchy category 4 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat4
						#R20 END IF
					#R20 ELSE 
						#R20 LET g_style.sub_cat4 = NULL
						#R20 LET	g_style.sub_sub_cat4 = NULL
						#R20 DISPLAY BY NAME g_style.cat4,
						                #R20 g_style.sub_cat4,
						                #R20 g_style.sub_sub_cat4
						#R20 ATTRIBUTE (NORMAL)
					#R20 END IF
				#R20 WHEN infield(cat5)
					#R20 IF	g_style.cat5 IS NOT  NULL THEN
						#R20 LET p_cat5_name = NULL
						#R20 SELECT	web_cat_name
						#R20 INTO	p_cat5_name
						#R20 FROM	web_cat1
						#R20#R20  WHERE	web_cat = g_style.cat5 
				
						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "category 5 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat5
						#R20 END IF
						#R20 DISPLAY BY NAME g_style.cat5
						#R20 ATTRIBUTE (NORMAL)
						#R20 DISPLAY BY NAME p_cat5_name
						#R20 ATTRIBUTE (NORMAL)
						#R20 IF g_style.sub_cat5 IS NULL THEN
 							#R20 LET p_text = "must enter sub category 5  "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat5
						#R20 END IF
						#R20 SELECT	*
						#R20 FROM	web_cat
						#R20 WHERE	web_cat1 = g_style.cat5
						#R20 AND		web_cat2 = g_style.sub_cat5
						#R20 AND		web_cat3 = g_style.sub_sub_cat5

						#R20 IF status = NOTFOUND THEN
 							#R20 LET p_text = "hierarchy category 5 not found "
							#R20 CALL messagebox(p_text,1)  		
							#R20 NEXT FIELD cat5
						#R20 END IF
					#R20 ELSE
						#R20 LET g_style.sub_cat5 = NULL
						#R20 LET	g_style.sub_sub_cat5 = NULL
						#R20 DISPLAY BY NAME g_style.cat5,
						                #R20 g_style.sub_cat5,
						                #R20 g_style.sub_sub_cat5
						#R20 ATTRIBUTE (NORMAL)
				#R20 	END IF
				#R13 >>
				WHEN infield(dw_cat1)
					IF	g_style_webcat.dw_cat1 IS NOT  NULL THEN
						LET p_dw_cat1_name = NULL
						SELECT	web_cat_name
						INTO	p_dw_cat1_name
						FROM	dw_web_cat1
						WHERE	web_cat = g_style_webcat.dw_cat1 
				
						IF status = NOTFOUND THEN
 							LET p_text = "demandware category 1 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat1
						END IF

						DISPLAY BY NAME g_style_webcat.dw_cat1
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_dw_cat1_name
						ATTRIBUTE (NORMAL)

						IF g_style_webcat.dw_sub_cat1 IS NULL THEN
 							LET p_text = "must enter demandware sub category 1  "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat1
						END IF

						IF g_style_webcat.dw_sssub_cat1 IS NULL THEN
							LET g_style_webcat.dw_sssub_cat1 = " "
						END IF


						#display " cat 1", g_style_webcat.dw_cat1,
						#" 2 ",g_style_webcat.dw_sub_cat1,
						#" 3 ",g_style_webcat.dw_ssub_cat1,
						#" 4 ",g_style_webcat.dw_sssub_cat1

						SELECT	UNIQUE web_cat1
						FROM	dw_web_cat
						WHERE	web_cat1 = g_style_webcat.dw_cat1
						AND		web_cat2 = g_style_webcat.dw_sub_cat1
						--AND		web_cat3 = g_style_webcat.dw_ssub_cat1
						--AND		web_cat4 = g_style_webcat.dw_sssub_cat1

						IF status = NOTFOUND THEN
 							LET p_text = "demandware hierarcy category 1 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat1
						END IF
					ELSE
						LET g_style_webcat.dw_sub_cat1 = NULL
						LET	g_style_webcat.dw_ssub_cat1 = NULL
						LET	g_style_webcat.dw_sssub_cat1 = NULL
						DISPLAY BY NAME g_style_webcat.dw_cat1,
						                g_style_webcat.dw_sub_cat1,
						                g_style_webcat.dw_ssub_cat1,
						                g_style_webcat.dw_sssub_cat1
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(dw_cat2)
					IF	g_style_webcat.dw_cat2 IS  NOT NULL THEN
						LET p_dw_cat2_name = NULL
						SELECT	web_cat_name
						INTO	p_dw_cat2_name
						FROM	dw_web_cat1
						WHERE	web_cat = g_style_webcat.dw_cat2
				
						IF status = NOTFOUND THEN
 							LET p_text = "demandware category 2 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat2
						END IF

						IF g_style_webcat.dw_sub_cat2 IS NULL THEN
 							LET p_text = "must enter demandware sub category 2  "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat2
						END IF

						#IF g_style_webcat.dw_sssub_cat2 IS NULL THEN
							#LET g_style_webcat.dw_sssub_cat2 = " "
						#END IF

						LET p_count = 0 			#R17
						SELECT	COUNT(*)			#R17
						INTO	p_count				#R17
						FROM	dw_web_cat
						WHERE	web_cat1 = g_style_webcat.dw_cat2
						AND		web_cat2 = g_style_webcat.dw_sub_cat2
						--AND		web_cat3 = g_style_webcat.dw_ssub_cat2
						--AND		web_cat4 = g_style_webcat.dw_sssub_cat2

						#R17 IF status = NOTFOUND THEN
						IF p_count = 0 THEN					#R17
 							LET p_text = "demandware hierarchy category 2 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat2
						END IF
						DISPLAY BY NAME g_style_webcat.dw_cat2
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_dw_cat2_name
						ATTRIBUTE (NORMAL)
					ELSE
						LET g_style_webcat.dw_sub_cat2 = NULL
						LET	g_style_webcat.dw_ssub_cat2 = NULL
						LET	g_style_webcat.dw_sssub_cat2 = NULL
						DISPLAY BY NAME g_style_webcat.dw_cat2,
						                g_style_webcat.dw_sub_cat2,
						                g_style_webcat.dw_ssub_cat2,
						                g_style_webcat.dw_sssub_cat2
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(dw_cat3)
					IF	g_style_webcat.dw_cat3 IS NOT  NULL THEN
						LET p_dw_cat3_name = NULL
						SELECT	web_cat_name
						INTO	p_dw_cat3_name
						FROM	dw_web_cat1
						WHERE	web_cat = g_style_webcat.dw_cat3 
				
						IF status = NOTFOUND THEN
 							LET p_text = "demandware category 3 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat3
						END IF
						DISPLAY BY NAME g_style_webcat.dw_cat3
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_dw_cat3_name
						ATTRIBUTE (NORMAL)

						IF g_style_webcat.dw_sub_cat3 IS NULL THEN
 							LET p_text = "must enter demandware sub category 3  "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat3
						END IF

						IF g_style_webcat.dw_sssub_cat3 IS NULL THEN
							LET g_style_webcat.dw_sssub_cat3 = " "
						END IF

						LET p_count = 0 			#R17
						SELECT	COUNT(*)			#R17
						INTO	p_count				#R17
						FROM	dw_web_cat
						WHERE	web_cat1 = g_style_webcat.dw_cat3
						AND		web_cat2 = g_style_webcat.dw_sub_cat3
						--AND		web_cat3 = g_style_webcat.dw_ssub_cat3
						--AND		web_cat4 = g_style_webcat.dw_sssub_cat3

						IF p_count = 0 THEN					#R17
						#IF status = NOTFOUND THEN
 							LET p_text = "demandware hierarchy category 3 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat3
						END IF
					ELSE
						LET g_style_webcat.dw_sub_cat3 = NULL
						LET	g_style_webcat.dw_ssub_cat3 = NULL
						LET	g_style_webcat.dw_sssub_cat3 = NULL
						DISPLAY BY NAME g_style_webcat.dw_cat3,
						                g_style_webcat.dw_sub_cat3,
						                g_style_webcat.dw_ssub_cat3,
						                g_style_webcat.dw_sssub_cat3
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(dw_cat4)
					IF	g_style_webcat.dw_cat4 IS  NOT NULL THEN
						LET p_dw_cat4_name = NULL
						SELECT	web_cat_name
						INTO	p_dw_cat4_name
						FROM	dw_web_cat1
						WHERE	web_cat = g_style_webcat.dw_cat4
				
						IF status = NOTFOUND THEN
 							LET p_text = "demandware category 4 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat4
						END IF
						DISPLAY BY NAME g_style_webcat.dw_cat4
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_dw_cat4_name
						ATTRIBUTE (NORMAL)
						IF g_style_webcat.dw_sub_cat4 IS NULL THEN
 							LET p_text = "must enter demandware sub category 4  "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat4
						END IF

						IF g_style_webcat.dw_sssub_cat4 IS NULL THEN
							LET g_style_webcat.dw_sssub_cat4 = " "
						END IF

						LET p_count = 0 			#R17
						SELECT	COUNT(*)			#R17
						INTO	p_count				#R17
						#SELECT	*
						FROM	dw_web_cat
						WHERE	web_cat1 = g_style_webcat.dw_cat4
						AND		web_cat2 = g_style_webcat.dw_sub_cat4
						--AND		web_cat3 = g_style_webcat.dw_ssub_cat4
						--AND		web_cat4 = g_style_webcat.dw_sssub_cat4

						IF p_count = 0 THEN					#R17
						#IF status = NOTFOUND THEN
 							LET p_text = "demandware hierarchy category 4 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat4
						END IF
					ELSE 
						LET g_style_webcat.dw_sub_cat4 = NULL
						LET	g_style_webcat.dw_ssub_cat4 = NULL
						LET	g_style_webcat.dw_sssub_cat4 = NULL
						DISPLAY BY NAME g_style_webcat.dw_cat4,
						                g_style_webcat.dw_sub_cat4,
						                g_style_webcat.dw_ssub_cat4,
						                g_style_webcat.dw_sssub_cat4
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(dw_cat5)
					IF	g_style_webcat.dw_cat5 IS NOT  NULL THEN
						LET p_dw_cat5_name = NULL
						SELECT	web_cat_name
						INTO	p_dw_cat5_name
						FROM	dw_web_cat1
						WHERE	web_cat = g_style_webcat.dw_cat5 
				
						IF status = NOTFOUND THEN
 							LET p_text = "demandware category 5 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat5
						END IF
						DISPLAY BY NAME g_style_webcat.dw_cat5
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_dw_cat5_name
						ATTRIBUTE (NORMAL)
						IF g_style_webcat.dw_sub_cat5 IS NULL THEN
 							LET p_text = "must enter demandware sub category 5  "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat5
						END IF

						LET p_count = 0 			#R17
						SELECT	COUNT(*)			#R17
						INTO	p_count				#R17
						#SELECT	*
						FROM	dw_web_cat
						WHERE	web_cat1 = g_style_webcat.dw_cat5
						AND		web_cat2 = g_style_webcat.dw_sub_cat5
						--AND		web_cat3 = g_style_webcat.dw_ssub_cat5
						--AND		web_cat4 = g_style_webcat.dw_sssub_cat5

						IF p_count = 0 THEN					#R17
						#IF status = NOTFOUND THEN
 							LET p_text = "demandware hierarchy category 5 not found "
							CALL messagebox(p_text,1)  		
							NEXT FIELD dw_cat5
						END IF
					ELSE
						LET g_style_webcat.dw_sub_cat5 = NULL
						LET	g_style_webcat.dw_ssub_cat5 = NULL
						LET	g_style_webcat.dw_sssub_cat5 = NULL
						DISPLAY BY NAME g_style_webcat.dw_cat5,
						                g_style_webcat.dw_sub_cat5,
						                g_style_webcat.dw_ssub_cat5,
						                g_style_webcat.dw_sssub_cat5
						ATTRIBUTE (NORMAL)
					END IF
				#R13 <<

				WHEN infield(assort1)
					IF	g_style.assort1 IS NOT NULL THEN
						SELECT	assort_ldesc 
						INTO	p_assort1_desc
						FROM	i_assortl
						WHERE	assort_lcode =  g_style.assort1
						AND		assort_id = 2

						IF status = NOTFOUND THEN
 							LET p_text = "invalid outsole assortment "
							CALL messagebox(p_text,1)  		
							NEXT FIELD assort1
						END IF
						DISPLAY BY NAME g_style.assort1,
										p_assort1_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(assort2)
					IF	g_style.assort2 IS NOT NULL THEN
						SELECT	assort_ldesc
						INTO	p_assort2_desc
						FROM	i_assortl
						WHERE	assort_lcode = g_style.assort2
						AND		assort_id = 3

						IF status = NOTFOUND THEN
 							LET p_text = "invalid heel height assortment "
							CALL messagebox(p_text,1)  		
							NEXT FIELD assort2
						END IF
						DISPLAY BY NAME g_style.assort2,
										p_assort2_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(assort3)
					IF	g_style.assort3 IS NOT NULL THEN
						SELECT	assort_ldesc
						INTO	p_assort3_desc
						FROM	i_assortl
						WHERE	assort_lcode = g_style.assort3
						AND		assort_id = 4
	
						IF status = NOTFOUND THEN
 							LET p_text = "invalid platform height assortment "
							CALL messagebox(p_text,1)  		
							NEXT FIELD assort3
						END IF
						DISPLAY BY NAME g_style.assort3,
										p_assort3_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R18 >>
				WHEN infield(givex_id)
					LET g_void =  sty_entW("INPUT") 
					NEXT FIELD r1x
				#R18 <<
				END CASE

			#R02 >>
			AFTER FIELD  g_hk_supplier,
				         g_hk_season,
				         g_hk_division,				#R14
				         g_hk_class,
						 g_hk_category,
						 g_hk_story      #tan0908
				CASE   
				WHEN infield(g_hk_supplier)
					IF g_hk_supplier IS NOT NULL THEN
						#R21 >>
			 			IF p_mode = "a" THEN
							SELECT	supplier_name
							INTO	p_hk_supplier_name
							FROM	supplier
							WHERE	supplier = g_hk_supplier
							AND		archive_flag = "N"				#R21
						ELSE
							IF p_prev_hk_supplier != g_hk_supplier THEN
								SELECT	supplier_name
								INTO	p_hk_supplier_name
								FROM	supplier
								WHERE	supplier = g_hk_supplier
								AND		archive_flag = "N"				#R21
							ELSE
								SELECT	supplier_name
								INTO	p_hk_supplier_name
								FROM	supplier
								WHERE	supplier = g_hk_supplier
							END IF
						END IF	
						#R21 <<
##display "shk sup not found ",status
						IF status = NOTFOUND THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid HK supplier"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_hk_supplier
						END IF
						DISPLAY BY NAME p_hk_supplier_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						CALL messagebox(p_text,1)  		
						LET p_text= "must enter HK supplier "
						NEXT FIELD g_hk_supplier
					END IF
				#R02 >>
				WHEN infield(g_hk_season)
					IF g_hk_season IS NOT NULL THEN
						SELECT	seedhk:season.season_desc
						INTO	p_hk_season_desc
						FROM	seedhk:season
						WHERE	seedhk:season.season = g_hk_season
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
##display "hk season: status ",status
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid HK  season"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_hk_season
						END IF
						DISPLAY BY NAME p_hk_season_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HK  season "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_season
					END IF
				#R02 <<
				#R14 >>
				WHEN infield(g_hk_division)
					IF g_hk_division IS NOT NULL THEN
						SELECT	seedhk:division.division_name
						INTO	p_hk_division_name
						FROM	seedhk:division
						WHERE	seedhk:division.division = g_hk_division

						LET p_status = status
						IF p_status = 100 THEN
##display "hk season: status ",status
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid HK  division"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_hk_division
						END IF
						DISPLAY BY NAME p_hk_division_name
						ATTRIBUTE(NORMAL)
					#ELSE
						#ERROR "must enter division "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter HK  division "
						#CALL messagebox(p_text,1)  		
						#NEXT FIELD g_hk_division
					END IF
				#R14 <<
				WHEN infield(g_hk_class)
					IF g_hk_class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_hk_class_desc
						FROM	class
						WHERE	class = g_hk_class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid HK class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_hk_class
						END IF
						DISPLAY BY NAME p_hk_class_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HK class "
						CALL messagebox(p_text,1)  		
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
							LET p_text =  "invalid HK category for selected class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_hk_class
						END IF
						DISPLAY BY NAME p_hk_category_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HK category "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_category
					END IF

				WHEN infield(g_hk_story)    #R03
					IF g_hk_story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_hk_story_desc     #R05
        				FROM    seedhk:story 
        				WHERE   story = g_hk_story

						IF status = NOTFOUND THEN
							ERROR "Invalid story"
							ATTRIBUTE(RED)
							LET p_text =  "Invalid HK  story"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_hk_story
						END IF

						DISPLAY BY NAME p_hk_story_desc
						ATTRIBUTE(NORMAL)
						#IF p_mode = "u" THEN							#R10
							#NEXT FIELD  g_hk_style_desc					#R10
						#END IF											#R10
					ELSE
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HK story "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_story     #r03
					END IF
				END CASE
			#R02 <<
			#R10 >>
			AFTER FIELD  g_sin_supplier,
				         g_sin_season,
				         g_sin_division,				#R14
				         g_sin_class,
						 g_sin_category,
						 g_sin_story     
				CASE   
				WHEN infield(g_sin_supplier)
					IF g_sin_supplier IS NOT NULL THEN
						#R21 >>
			 			IF p_mode = "a" THEN
							SELECT	supplier_name
							INTO	p_sin_supplier_name
							FROM	supplier
							WHERE	supplier = g_sin_supplier
							AND		archive_flag = "N"				#R21
						ELSE
							IF p_prev_sin_supplier != g_sin_supplier THEN
								SELECT	supplier_name
								INTO	p_sin_supplier_name
								FROM	supplier
								WHERE	supplier = g_sin_supplier
								AND		archive_flag = "N"				#R21
							ELSE
								SELECT	supplier_name
								INTO	p_sin_supplier_name
								FROM	supplier
								WHERE	supplier = g_sin_supplier
							END IF
						END IF	
						#R21 <<
						IF status = NOTFOUND THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid SIN supplier"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_supplier
						END IF
						DISPLAY BY NAME p_sin_supplier_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter SIN supplier "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_supplier
					END IF
				#R02 >>
				WHEN infield(g_sin_season)
					IF g_sin_season IS NOT NULL THEN
						SELECT	seedsin:season.season_desc
						INTO	p_sin_season_desc
						FROM	seedsin:season
						WHERE	seedsin:season.season = g_sin_season
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
##display "sin season: status ",status
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid Singapore season"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_season
						END IF
						DISPLAY BY NAME p_sin_season_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Singapore season "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_season
					END IF
				#R14 >>
				WHEN infield(g_sin_division)
					IF g_sin_division IS NOT NULL THEN
						SELECT	seedsin:division.division_name
						INTO	p_sin_division_name
						FROM	seedsin:division
						WHERE	seedsin:division.division = g_sin_division
						LET p_status = status
						##IF p_status = NOTFOUND THEN
						IF p_status = 100 THEN
##display "sin season: status ",status
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid Singapore division"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_division
						END IF
						DISPLAY BY NAME p_sin_division_name
						ATTRIBUTE(NORMAL)
					#ELSE
						#ERROR "must enter division "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter Singapore division "
						#CALL messagebox(p_text,1)  		
						#NEXT FIELD g_sin_division
					END IF
					#R14 <<

				WHEN infield(g_sin_class)
					IF g_sin_class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_sin_class_desc
						FROM	class
						WHERE	class = g_sin_class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid SIN class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_class
						END IF
						DISPLAY BY NAME p_sin_class_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter SIN class "
						CALL messagebox(p_text,1)  		
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
							LET p_text =  "invalid SIN category for selected class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_class
						END IF
						DISPLAY BY NAME p_sin_category_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter  SIN category "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_category
					END IF

				WHEN infield(g_sin_story)    #R03
					IF g_sin_story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_sin_story_desc     #R05
        				FROM    seedsin:story 
        				WHERE   story = g_sin_story

						IF status = NOTFOUND THEN
							ERROR "Invalid story"
							ATTRIBUTE(RED)
							LET p_text =  "Invalid Singapore  story"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_sin_story
						END IF

						DISPLAY BY NAME p_sin_story_desc
						ATTRIBUTE(NORMAL)
						#R10 >>
						#IF p_mode = "u" THEN
							#NEXT FIELD  g_sin_style_desc
						#END IF
						#R10 <<
					ELSE
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Singapore  story "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_story     #r03
					END IF
				END CASE
			#R10 <<
			#NZ
			#R11 >>
			AFTER FIELD  g_nz_supplier,
				         g_nz_season,
				         g_nz_division,			#R14
				         g_nz_class,
						 g_nz_category,
						 g_nz_story     
				CASE   
				WHEN infield(g_nz_supplier)
					IF g_nz_supplier IS NOT NULL THEN
						#R21 >>
			 			IF p_mode = "a" THEN
							SELECT	supplier_name
							INTO	p_nz_supplier_name
							FROM	supplier
							WHERE	supplier = g_nz_supplier
							AND		archive_flag = "N"				#R21
						ELSE
							IF p_prev_nz_supplier != g_nz_supplier THEN
								SELECT	supplier_name
								INTO	p_nz_supplier_name
								FROM	supplier
								WHERE	supplier = g_nz_supplier
								AND		archive_flag = "N"				#R21
							ELSE
								SELECT	supplier_name
								INTO	p_nz_supplier_name
								FROM	supplier
								WHERE	supplier = g_nz_supplier
							END IF
						END IF	
						#R21 <<
						IF status = NOTFOUND THEN
							ERROR "invalid supplier"
							ATTRIBUTE(RED)
							LET p_text =  "invalid NZ supplier"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_supplier
						END IF
						DISPLAY BY NAME p_nz_supplier_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ supplier "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_supplier
					END IF
				WHEN infield(g_nz_season)
					IF g_nz_season IS NOT NULL THEN
						SELECT	seednz:season.season_desc
						INTO	p_nz_season_desc
						FROM	seednz:season
						WHERE	seednz:season.season = g_nz_season
						LET p_status = status
						IF p_status = 100 THEN
##display "nz season: status ",status
							ERROR "invalid season"
							ATTRIBUTE(RED)
							LET p_text =  "invalid NZ season"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_season
						END IF
						DISPLAY BY NAME p_nz_season_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ season "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_season
					END IF
				#R14 >>
				WHEN infield(g_nz_division)
					IF g_nz_division IS NOT NULL THEN
						SELECT	seednz:division.division_name
						INTO	p_nz_division_name
						FROM	seednz:division
						WHERE	seednz:division.division = g_nz_division
						LET p_status = status
						IF p_status = 100 THEN
##display "nz season: status ",status
							ERROR "invalid division"
							ATTRIBUTE(RED)
							LET p_text =  "invalid NZ division"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_division
						END IF
						DISPLAY BY NAME p_nz_division_name
						ATTRIBUTE(NORMAL)
					##ELSE
						##ERROR "must enter division "
						##ATTRIBUTE(RED)
						##LET p_text =  "must enter NZ division "
						##CALL messagebox(p_text,1)  		
						##NEXT FIELD g_nz_division
					END IF
				#R14 <<

				WHEN infield(g_nz_class)
					IF g_nz_class IS NOT NULL THEN
						SELECT	class_desc
						INTO	p_nz_class_desc
						FROM	class
						WHERE	class = g_nz_class

						IF status = NOTFOUND THEN
							ERROR "invalid class"
							ATTRIBUTE(RED)
							LET p_text =  "invalid NZ class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_class
						END IF
						DISPLAY BY NAME p_nz_class_desc
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ class "
						CALL messagebox(p_text,1)  		
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
							LET p_text =  "invalid NZ category for selected class"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_class
						END IF
						DISPLAY BY NAME p_nz_category_name
						ATTRIBUTE(NORMAL)
					ELSE
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter  NZ category "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_category
					END IF

				WHEN infield(g_nz_story)   
					IF g_nz_story IS NOT NULL THEN
						SELECT	story_desc
						INTO	p_nz_story_desc     
        				FROM    seednz:story 
        				WHERE   story = g_nz_story

						IF status = NOTFOUND THEN
							ERROR "Invalid story"
							ATTRIBUTE(RED)
							LET p_text =  "Invalid NZ  story"
							CALL messagebox(p_text,1)  		
							NEXT FIELD g_nz_story
						END IF

						DISPLAY BY NAME p_nz_story_desc
						ATTRIBUTE(NORMAL)
						#IF p_mode = "u" THEN
							#NEXT FIELD  g_nz_style_desc
						#END IF
					ELSE
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ  story "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_story     
					END IF
				END CASE
			#R11 <<

			#R03 >>
			ON CHANGE r1					
				CASE
				WHEN r1= "Air"
					LET g_style.fob_method = "Air"
				WHEN r1= "Sea"
					LET g_style.fob_method = "Sea"
				WHEN r1= "Local"
					LET g_style.fob_method = "Local"
				END CASE
			ON CHANGE r2						
				CASE
				WHEN r2= "POUND"
					LET g_style.fob = "POUND"
				WHEN r2= "USD"
					LET g_style.fob = "USD"
				WHEN r2= "HONGKONG"
					LET g_style.fob = "HONGKONG"
				WHEN r2= "EURO"
					LET g_style.fob = "EURO"
				WHEN r2= "N/A"
					LET g_style.fob = "N/A"
				WHEN r2= "AUD"
					LET g_style.fob = "AUD"
				WHEN r2= "NZ"									
					LET g_style.fob = "NZ"					
				WHEN r2= "SGD"						#R10								
					LET g_style.fob = "SGD"			#R10				
				END CASE

			ON CHANGE r8    #R03Tan					
				CASE
				WHEN r8= "Air"
					LET g_hk_fob_method = "Air"
				WHEN r8= "Sea"
					LET g_hk_fob_method = "Sea"
				WHEN r8= "Local"
					LET g_hk_fob_method = "Local"
				END CASE

			ON CHANGE r9   #R03Tan			
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
				WHEN r9= "SGD"					#R10"									
					LET g_hk_fob = "SGD"
				END CASE

			#R10 >>
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
			#R10 <<
			#R11 >>
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
			#R11 <<

{
			ON KEY(F8)
				CASE   
				WHEN infield(season)
					LET p_lkref1= NULL
                    CALL gp_lookup("season",p_lkref1)
                    RETURNING p_season,p_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_style.season = p_season
						DISPLAY BY NAME g_style.season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R07 WHEN infield(division)
					#R07 LET p_lkref1= NULL
                    #R07 CALL gp_lookup("division",p_lkref1)
                    #R07 RETURNING p_division,p_division_name
                    #R07 IF p_class IS NOT NULL THEN
						#R07 LET	g_style.division = p_division
						#R07 DISPLAY BY NAME g_style.division
						#R07 ATTRIBUTE (NORMAL)
						#R07 DISPLAY BY NAME p_division_name
						#R07 ATTRIBUTE (NORMAL)
					#R07 END IF
				#R07 >>
				WHEN infield(section)
					LET p_lkref1= NULL
                    CALL gp_lookup("section",p_lkref1)
                    RETURNING p_section,p_section_name
                    IF p_class IS NOT NULL THEN
						LET	g_style.section = p_section
						DISPLAY BY NAME g_style.section
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_section_name
						ATTRIBUTE (NORMAL)
					END IF
				#R07 <<
				WHEN infield(class)
					LET p_lkref1= NULL
                    CALL gp_lookup("class",p_lkref1)
                    RETURNING p_class,p_class_desc
                    IF p_class IS NOT NULL THEN
						LET	g_style.class = p_class
						DISPLAY BY NAME g_style.class
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_class_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(category)
					LET p_lkref1= g_style.class
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_style.category = p_category
						DISPLAY BY NAME g_style.category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_category_name
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(fabric_type)
					LET p_lkref1= NULL
                    CALL gp_lookup("fabric",p_lkref1)
                    RETURNING p_fabric_type,p_fabric_desc
                    IF p_fabric_type IS NOT NULL THEN
						LET	g_style.fabric_type = p_fabric_type
						DISPLAY BY NAME g_style.fabric_type
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_fabric_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(story)
					LET p_lkref1= NULL
                    CALL gp_lookup("story",p_lkref1)
                    RETURNING p_story,p_story_desc
                    IF p_story IS NOT NULL THEN
						LET	g_style.story = p_story
						DISPLAY BY NAME g_style.story
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_story_desc
						ATTRIBUTE (NORMAL)
					END IF
				OTHERWISE
                    ERROR "no lookup for this field"
					ATTRIBUTE(RED)
                END CASE

			ON KEY (F10,INTERRUPT)
				IF p_mode = "a" THEN
					INITIALIZE g_style.* TO NULL
					LET lstate = "GETOUT"
				ELSE
					LET lstate = "GETOUT"
				END IF
				EXIT INPUT
}

		#R03 >>
		AFTER FIELD r1x
			LET g_style.web_desc1 = r1x CLIPPED

		AFTER FIELD r2x
			LET g_style.web_desc2 = r2x CLIPPED

		AFTER FIELD r3x
			LET g_style.web_desc3 = r3x CLIPPED
		#R03 <<

		#R10 >>
		ON ACTION hongkong
			NEXT FIELD g_hk_style_desc

		#R10 >>
		ON ACTION singapore
			NEXT FIELD g_sin_style_desc

		#R11>>
		ON ACTION newzealand
			NEXT FIELD g_nz_style_desc

			#R03 >>
			ON ACTION images
				LET g_image = FALSE
				LET g_void =  sty_entW("INPUT") 
			display "images xxxxx", g_image

			ON ACTION web
display "web xxxx"
				##LET g_void = sty_entW("INIT")
				##LET g_void = sty_entW("SELECT")
				##LET g_void = sty_entW("DISPLAY")
				NEXT FIELD r1x

			#R23 >>
			ON ACTION video
				LET g_video = FALSE
				LET g_void =  sty_entW("INPUT1") 
			#display "video url xxxxx", g_video_url
			#R23

			#R20 ON ACTION zoom1
				#R20 LET p_lkref1= ""
                #R20 CALL gp_lookup("webcat",p_lkref1)
                #R20 RETURNING p_cat,p_cat1_name
                #R20 IF p_cat IS NOT NULL THEN
					#R20 LET	g_style.cat1 = p_cat
					#R20 DISPLAY BY NAME g_style.cat1
					#R20 ATTRIBUTE (NORMAL)
					#R20 DISPLAY BY NAME p_cat1_name
					#R20#R20  ATTRIBUTE (NORMAL)
					#R20 LET p_sub_cat = NULL
					#R20 LET p_sub_cat_name = NULL
					#R20 LET p_sub_sub_cat = NULL
					#R20 LET p_sub_sub_cat_name = NULL
					#R20#R20  CALL web_catLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name
					#R20 IF p_cat IS NOT NULL THEN
						#R20 LET g_style.sub_cat1 = p_sub_cat
						#R20 LET p_sub_cat1_name = p_sub_cat_name
						#R20 LET g_style.sub_sub_cat1 = p_sub_sub_cat
						#R20 LET p_sub_sub_cat1_name = p_sub_sub_cat_name
						#R20 DISPLAY BY NAME g_style.sub_cat1,
									#R20 p_sub_cat1_name,
									#R20 g_style.sub_sub_cat1,
									#R20 p_sub_sub_cat1_name
						#R20 ATTRIBUTE (NORMAL)
					#R20 END IF
				#R20 END IF

			#R20 ON ACTION zoom2
				#R20 LET p_lkref1= ""
                #R20 CALL gp_lookup("webcat",p_lkref1)
                #R20 RETURNING p_cat,p_cat2_name
                #R20#R20  IF p_cat IS NOT NULL THEN
					#R20#R20  LET	g_style.cat2 = p_cat
					#R20 DISPLAY BY NAME g_style.cat2
					#R20 ATTRIBUTE (NORMAL)
					#R20 DISPLAY BY NAME p_cat2_name
					#R20 ATTRIBUTE (NORMAL)
					#R20 LET p_sub_cat = NULL
					#R20 LET p_sub_cat_name = NULL
					#R20 LET p_sub_sub_cat = NULL
					#R20 LET p_sub_sub_cat_name = NULL
					#R20 CALL web_catLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name
					#R20 LET g_style.sub_cat2 = p_sub_cat
					#R20 LET p_sub_cat2_name = p_sub_cat_name
					#R20 LET g_style.sub_sub_cat2 = p_sub_sub_cat
					#R20 LET p_sub_sub_cat2_name = p_sub_sub_cat_name
		#R20 display "here: ",	p_sub_sub_cat, " ",g_style.sub_sub_cat2
					#R20 DISPLAY BY NAME g_style.sub_cat2,
									#R20 p_sub_cat2_name,
									#R20 g_style.sub_sub_cat2,
									#R20 p_sub_sub_cat2_name
					#R20 ATTRIBUTE (NORMAL)
				#R20 END IF

			#R20 ON ACTION zoom3
				#R20 LET p_lkref1= ""
                #R20 CALL gp_lookup("webcat",p_lkref1)
                #R20 RETURNING p_cat,p_cat3_name
                #R20 IF p_cat IS NOT NULL THEN
					#R20 LET	g_style.cat3 = p_cat
					#R20 DISPLAY BY NAME g_style.cat3
					#R20 ATTRIBUTE (NORMAL)
					#R20#R20  DISPLAY BY NAME p_cat3_name
					#R20 ATTRIBUTE (NORMAL)
					#R20 LET p_sub_cat = NULL
					#R20 LET p_sub_cat_name = NULL
					#R20 LET p_sub_sub_cat = NULL
					#R20 LET p_sub_sub_cat_name = NULL
					#R20 CALL web_catLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name
					#R20 LET g_style.sub_cat3 = p_sub_cat
					#R20 LET p_sub_cat3_name = p_sub_cat_name
					#R20 LET g_style.sub_sub_cat3 = p_sub_sub_cat
					#R20 LET p_sub_sub_cat3_name = p_sub_sub_cat_name
					#R20 DISPLAY BY NAME g_style.sub_cat3,
									#R20 p_sub_cat3_name,
									#R20 g_style.sub_sub_cat3,
									#R20 p_sub_sub_cat3_name
					#R20 ATTRIBUTE (NORMAL)
				#R20 END IF

			#R20 ON ACTION zoom4
				#R20 LET p_lkref1= ""
                #R20 CALL gp_lookup("webcat",p_lkref1)
                #R20 RETURNING p_cat,p_cat4_name
                #R20 IF p_cat IS NOT NULL THEN
					#R20 LET	g_style.cat4 = p_cat
					#R20 DISPLAY BY NAME g_style.cat4
					#R20 ATTRIBUTE (NORMAL)
					#R20#R20  DISPLAY BY NAME p_cat4_name
					#R20 ATTRIBUTE (NORMAL)
					#R20 LET p_sub_cat = NULL
					#R20 LET p_sub_cat_name = NULL
					#R20 LET p_sub_sub_cat = NULL
					#R20 LET p_sub_sub_cat_name = NULL
					#R20 CALL web_catLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name
					#R20 LET g_style.sub_cat4 = p_sub_cat
					#R20 LET p_sub_cat4_name = p_sub_cat_name
					#R20 LET g_style.sub_sub_cat4 = p_sub_sub_cat
					#R20 LET p_sub_sub_cat4_name = p_sub_sub_cat_name
					#R20 DISPLAY BY NAME g_style.sub_cat4,
									#R20 p_sub_cat4_name,
									#R20 g_style.sub_sub_cat4,
									#R20 p_sub_sub_cat4_name
					#R20 ATTRIBUTE (NORMAL)
				#R20 END IF

			#R20 ON ACTION zoom5
				#R20 LET p_lkref1= ""
                #R20 CALL gp_lookup("webcat",p_lkref1)
                #R20 RETURNING p_cat,p_cat5_name
                #R20 IF p_cat IS NOT NULL THEN
					#R20 LET	g_style.cat5 = p_cat
					#R20 DISPLAY BY NAME g_style.cat5
					#R20 ATTRIBUTE (NORMAL)
					#R20 DISPLAY BY NAME p_cat5_name
					#R20 ATTRIBUTE (NORMAL)
					#R20 LET p_sub_cat = NULL
					#R20 LET p_sub_cat_name = NULL
					#R20 LET p_sub_sub_cat = NULL
					#R20 LET p_sub_sub_cat_name = NULL
					#R20#R20  CALL web_catLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name
					#R20 LET g_style.sub_cat5 = p_sub_cat
					#R20 LET p_sub_cat5_name = p_sub_cat_name
					#R20 LET g_style.sub_sub_cat5 = p_sub_sub_cat
					#R20 LET p_sub_sub_cat5_name = p_sub_sub_cat_name
					#R20 DISPLAY BY NAME g_style.sub_cat5,
									#R20 p_sub_cat5_name,
									#R20 g_style.sub_sub_cat5,
									#R20 p_sub_sub_cat5_name
					#R20 ATTRIBUTE (NORMAL)
				#R20  END IF

			#R13 >>
			ON ACTION zoom INFIELD dw_cat1
				LET p_lkref1= ""
                CALL gp_lookup("dw_webcat",p_lkref1)
                RETURNING p_cat,p_dw_cat1_name
                IF p_cat IS NOT NULL THEN
					LET	g_style_webcat.dw_cat1 = p_cat
					DISPLAY BY NAME g_style_webcat.dw_cat1
					ATTRIBUTE (NORMAL)
					DISPLAY BY NAME p_dw_cat1_name
					ATTRIBUTE (NORMAL)
					LET p_sub_cat = NULL
					LET p_sub_sub_cat = NULL
					LET p_sub_sub_sub_cat = NULL
					LET p_sub_cat_name = NULL
					LET p_sub_sub_cat_name = NULL
					LET p_sub_sub_sub_cat_name = NULL
					CALL web_dwcatLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name,p_sub_sub_sub_cat,p_sub_sub_sub_cat_name
					IF p_cat IS NOT NULL THEN
						LET g_style_webcat.dw_sub_cat1 = p_sub_cat
						LET g_style_webcat.dw_ssub_cat1 = p_sub_sub_cat
						LET g_style_webcat.dw_sssub_cat1 = p_sub_sub_sub_cat
						LET p_dw_subcat1_name = p_sub_cat_name
						LET p_dw_ssubcat1_name = p_sub_sub_cat_name
						LET p_dw_sssubcat1_name = p_sub_sub_sub_cat_name
						DISPLAY BY NAME g_style_webcat.dw_sub_cat1,
									    p_dw_subcat1_name,
									    g_style_webcat.dw_ssub_cat1,
									    p_dw_ssubcat1_name,
									    g_style_webcat.dw_sssub_cat1,
									    p_dw_sssubcat1_name
						ATTRIBUTE (NORMAL)
					END IF
				END IF

			ON ACTION zoom INFIELD dw_cat2
				LET p_lkref1= ""
                CALL gp_lookup("dw_webcat",p_lkref1)
                RETURNING p_cat,p_dw_cat2_name
                IF p_cat IS NOT NULL THEN
					LET	g_style_webcat.dw_cat2 = p_cat
					DISPLAY BY NAME g_style_webcat.dw_cat2
					ATTRIBUTE (NORMAL)
					DISPLAY BY NAME p_dw_cat2_name
					ATTRIBUTE (NORMAL)
					LET p_sub_cat = NULL
					LET p_sub_sub_cat = NULL
					LET p_sub_sub_sub_cat = NULL
					LET p_sub_cat_name = NULL
					LET p_sub_sub_cat_name = NULL
					LET p_sub_sub_sub_cat_name = NULL
					CALL web_dwcatLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name,p_sub_sub_sub_cat,p_sub_sub_sub_cat_name
					IF p_cat IS NOT NULL THEN
						LET g_style_webcat.dw_sub_cat2 = p_sub_cat
						LET g_style_webcat.dw_ssub_cat2 = p_sub_sub_cat
						LET g_style_webcat.dw_sssub_cat2 = p_sub_sub_sub_cat
						LET p_dw_subcat2_name = p_sub_cat_name
						LET p_dw_ssubcat2_name = p_sub_sub_cat_name
						LET p_dw_sssubcat2_name = p_sub_sub_sub_cat_name
						DISPLAY BY NAME g_style_webcat.dw_sub_cat2,
									    p_dw_subcat2_name,
									    g_style_webcat.dw_ssub_cat2,
									    p_dw_ssubcat2_name,
									    g_style_webcat.dw_sssub_cat2,
									    p_dw_sssubcat2_name
						ATTRIBUTE (NORMAL)
					END IF
				END IF

			ON ACTION zoom INFIELD dw_cat3
				LET p_lkref1= ""
                CALL gp_lookup("dw_webcat",p_lkref1)
                RETURNING p_cat,p_dw_cat3_name
                IF p_cat IS NOT NULL THEN
					LET	g_style_webcat.dw_cat3 = p_cat
					DISPLAY BY NAME g_style_webcat.dw_cat3
					ATTRIBUTE (NORMAL)
					DISPLAY BY NAME p_dw_cat3_name
					ATTRIBUTE (NORMAL)
					LET p_sub_cat = NULL
					LET p_sub_sub_cat = NULL
					LET p_sub_sub_sub_cat = NULL
					LET p_sub_cat_name = NULL
					LET p_sub_sub_cat_name = NULL
					LET p_sub_sub_sub_cat_name = NULL
					CALL web_dwcatLst(p_cat) RETURNING p_cat, p_sub_cat, p_sub_cat_name, p_sub_sub_cat, p_sub_sub_cat_name, p_sub_sub_sub_cat, p_sub_sub_sub_cat_name
					IF p_cat IS NOT NULL THEN
						LET g_style_webcat.dw_sub_cat3 = p_sub_cat
						LET g_style_webcat.dw_ssub_cat3 = p_sub_sub_cat
						LET g_style_webcat.dw_sssub_cat3 = p_sub_sub_sub_cat
						LET p_dw_subcat3_name = p_sub_cat_name
						LET p_dw_ssubcat3_name = p_sub_sub_cat_name
						LET p_dw_sssubcat3_name = p_sub_sub_sub_cat_name
						DISPLAY BY NAME g_style_webcat.dw_sub_cat3,
									    p_dw_subcat3_name,
									    g_style_webcat.dw_ssub_cat3,
									    p_dw_ssubcat3_name,
									    g_style_webcat.dw_sssub_cat3,
									    p_dw_sssubcat3_name
						ATTRIBUTE (NORMAL)
					END IF
				END IF

			ON ACTION zoom INFIELD dw_cat4
				LET p_lkref1= ""
                CALL gp_lookup("dw_webcat",p_lkref1)
                RETURNING p_cat,p_dw_cat4_name
                IF p_cat IS NOT NULL THEN
					LET	g_style_webcat.dw_cat4 = p_cat
					DISPLAY BY NAME g_style_webcat.dw_cat4
					ATTRIBUTE (NORMAL)
					DISPLAY BY NAME p_dw_cat4_name
					ATTRIBUTE (NORMAL)
					LET p_sub_cat = NULL
					LET p_sub_sub_cat = NULL
					LET p_sub_sub_sub_cat = NULL
					LET p_sub_cat_name = NULL
					LET p_sub_sub_cat_name = NULL
					LET p_sub_sub_sub_cat_name = NULL
					CALL web_dwcatLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name,p_sub_sub_sub_cat,p_sub_sub_sub_cat_name
					IF p_cat IS NOT NULL THEN
						LET g_style_webcat.dw_sub_cat4 = p_sub_cat
						LET g_style_webcat.dw_ssub_cat4 = p_sub_sub_cat
						LET g_style_webcat.dw_sssub_cat4 = p_sub_sub_sub_cat
						LET p_dw_subcat4_name = p_sub_cat_name
						LET p_dw_ssubcat4_name = p_sub_sub_cat_name
						LET p_dw_sssubcat4_name = p_sub_sub_sub_cat_name
						DISPLAY BY NAME g_style_webcat.dw_sub_cat4,
									    p_dw_subcat4_name,
									    g_style_webcat.dw_ssub_cat4,
									    p_dw_ssubcat4_name,
									    g_style_webcat.dw_sssub_cat4,
									    p_dw_sssubcat4_name
						ATTRIBUTE (NORMAL)
					END IF
				END IF

			ON ACTION zoom INFIELD dw_cat5
				LET p_lkref1= ""
                CALL gp_lookup("dw_webcat",p_lkref1)
                RETURNING p_cat,p_dw_cat5_name
                IF p_cat IS NOT NULL THEN
					LET	g_style_webcat.dw_cat5 = p_cat
					DISPLAY BY NAME g_style_webcat.dw_cat5
					ATTRIBUTE (NORMAL)
					DISPLAY BY NAME p_dw_cat5_name
					ATTRIBUTE (NORMAL)
					LET p_sub_cat = NULL
					LET p_sub_sub_cat = NULL
					LET p_sub_sub_sub_cat = NULL
					LET p_sub_cat_name = NULL
					LET p_sub_sub_cat_name = NULL
					LET p_sub_sub_sub_cat_name = NULL
					CALL web_dwcatLst(p_cat) RETURNING p_cat,p_sub_cat,p_sub_cat_name,p_sub_sub_cat,p_sub_sub_cat_name,p_sub_sub_sub_cat,p_sub_sub_sub_cat_name
					IF p_cat IS NOT NULL THEN
						LET g_style_webcat.dw_sub_cat5 = p_sub_cat
						LET g_style_webcat.dw_ssub_cat5 = p_sub_sub_cat
						LET g_style_webcat.dw_sssub_cat5 = p_sub_sub_sub_cat
						LET p_dw_subcat5_name = p_sub_cat_name
						LET p_dw_ssubcat5_name = p_sub_sub_cat_name
						LET p_dw_sssubcat5_name = p_sub_sub_sub_cat_name
						DISPLAY BY NAME g_style_webcat.dw_sub_cat5,
									    p_dw_subcat5_name,
									    g_style_webcat.dw_ssub_cat5,
									    p_dw_ssubcat5_name,
									    g_style_webcat.dw_sssub_cat5,
									    p_dw_sssubcat5_name
						ATTRIBUTE (NORMAL)
					END IF
				END IF
			#R13 <<
				
			ON ACTION zoom6
				LET p_lkref1= 2
                CALL gp_lookup("assort",p_lkref1)
                RETURNING p_assort1,p_assort1_desc
                IF p_assort1 IS NOT NULL THEN
					LET	g_style.assort1 = p_assort1
					DISPLAY BY NAME g_style.assort1,
									p_assort1_desc
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom7
				LET p_lkref1= 3
                CALL gp_lookup("assort",p_lkref1)
                RETURNING p_assort2,p_assort2_desc
                IF p_assort2 IS NOT NULL THEN
					LET	g_style.assort2 = p_assort2
					DISPLAY BY NAME g_style.assort2,
									p_assort2_desc
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom8
				LET p_lkref1= 4
                CALL gp_lookup("assort",p_lkref1)
                RETURNING p_assort3,p_assort3_desc
                IF p_assort3 IS NOT NULL THEN
					LET	g_style.assort3 = p_assort3
					DISPLAY BY NAME g_style.assort3,
									p_assort3_desc
					ATTRIBUTE (NORMAL)
				END IF

			#R03 <<
			ON ACTION find
				CASE   
				WHEN infield(season)
					LET p_lkref1= NULL
                    CALL gp_lookup("season",p_lkref1)
                    RETURNING p_season,p_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_style.season = p_season
						DISPLAY BY NAME g_style.season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R02 >>
				WHEN infield(g_hk_season)
					LET p_lkref1= NULL
                    CALL gp_lookup1("hkseason",p_lkref1)
                    RETURNING p_season,p_hk_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_hk_season = p_season
						DISPLAY BY NAME g_hk_season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R02 <<
				#R14 >>
				WHEN infield(g_hk_division)
					LET p_lkref1= NULL
                    CALL gp_lookup("division",p_lkref1)
                    RETURNING p_division,p_hk_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_hk_division = p_division
						DISPLAY BY NAME g_hk_division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_division_name
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_sin_division)
					LET p_lkref1= NULL
                    CALL gp_lookup("division",p_lkref1)
                    RETURNING p_division,p_sin_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_sin_division = p_division
						DISPLAY BY NAME g_sin_division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_division_name
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(g_nz_division)
					LET p_lkref1= NULL
                    CALL gp_lookup("division",p_lkref1)
                    RETURNING p_division,p_nz_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_nz_division = p_division
						DISPLAY BY NAME g_nz_division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_division_name
						ATTRIBUTE (NORMAL)
					END IF
				#R14 <<

				#R10 >>
				WHEN infield(g_sin_season)
					LET p_lkref1= NULL
                    CALL gp_lookup1("sinseason",p_lkref1)
                    RETURNING p_season,p_sin_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_sin_season = p_season
						DISPLAY BY NAME g_sin_season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R10 <<
				#R11 >>
				WHEN infield(g_nz_season)
					LET p_lkref1= NULL
                    CALL gp_lookup1("nzseason",p_lkref1)
                    RETURNING p_season,p_nz_season_desc
                    IF p_season IS NOT NULL THEN
						LET	g_nz_season = p_season
						DISPLAY BY NAME g_nz_season
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_season_desc
						ATTRIBUTE (NORMAL)
					END IF
				#R11 <<
				#R14 >>
				WHEN infield(division)
					LET p_lkref1= NULL
                    CALL gp_lookup("division",p_lkref1)
                    RETURNING p_division,p_division_name
                    IF p_division IS NOT NULL THEN
						LET	g_style.division = p_division
						DISPLAY BY NAME g_style.division
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_division_name
						ATTRIBUTE (NORMAL)
					END IF
				#R14 >>

				WHEN infield(section)
					LET p_lkref1= NULL
                    CALL gp_lookup("section",p_lkref1)
                    RETURNING p_section,p_section_name
                    IF p_section IS NOT NULL THEN
						LET	g_style.section = p_section
						DISPLAY BY NAME g_style.section
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_section_name
						ATTRIBUTE (NORMAL)
					END IF
				#R07 <<
				WHEN infield(class)
					LET p_lkref1= NULL
                    CALL gp_lookup("class",p_lkref1)
                    RETURNING p_class,p_class_desc
                    IF p_class IS NOT NULL THEN
						LET	g_style.class = p_class
						DISPLAY BY NAME g_style.class
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_class_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(category)
					LET p_lkref1= g_style.class
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_style.category = p_category
						DISPLAY BY NAME g_style.category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_category_name
						ATTRIBUTE (NORMAL)
					END IF
				#R02 >>
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
					LET p_lkref1= g_hk_class
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_hk_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_hk_category = p_category
						DISPLAY BY NAME g_hk_category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_hk_category_name
						ATTRIBUTE (NORMAL)
					END IF
				#R02 <<
				#R10 >>
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
					LET p_lkref1= g_sin_class
display "look up: ",p_lkref1
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_sin_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_sin_category = p_category
						DISPLAY BY NAME g_sin_category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_sin_category_name
						ATTRIBUTE (NORMAL)
					END IF
				#R10 <<
				#R11 >>
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
					LET p_lkref1= g_nz_class
display "look up: ",p_lkref1
                    CALL gp_lookup("category",p_lkref1)
                    RETURNING p_category,p_nz_category_name
                    IF p_category IS NOT NULL THEN
						LET	g_nz_category = p_category
						DISPLAY BY NAME g_nz_category
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_nz_category_name
						ATTRIBUTE (NORMAL)
					END IF
				#R10 <<
				WHEN infield(fabric_type)
					LET p_lkref1= NULL
                    CALL gp_lookup("fabric",p_lkref1)
                    RETURNING p_fabric_type,p_fabric_desc
                    IF p_fabric_type IS NOT NULL THEN
						LET	g_style.fabric_type = p_fabric_type
						DISPLAY BY NAME g_style.fabric_type
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_fabric_desc
						ATTRIBUTE (NORMAL)
					END IF
				WHEN infield(story)
					LET p_lkref1= NULL
                    CALL gp_lookup("story",p_lkref1)
                    RETURNING p_story,p_story_desc
                    IF p_story IS NOT NULL THEN
						LET	g_style.story = p_story
						DISPLAY BY NAME g_style.story
						ATTRIBUTE (NORMAL)
						DISPLAY BY NAME p_story_desc
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
				#R10 >>
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
				#R10 <<
				#R11 >>
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
				#R11 <<
				OTHERWISE
                    ERROR "no lookup for this field"
					ATTRIBUTE(RED)
                END CASE

			AFTER INPUT
				IF g_style.style_desc IS NULL THEN
					ERROR "must enter style description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS style description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD style_desc
				END IF
				IF g_style.short_desc IS NULL THEN
					ERROR "must enter style short description"
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS style short description"
					CALL messagebox(p_text,1)  		
					NEXT FIELD short_desc
				END IF
				IF g_style.supplier IS NULL THEN
					ERROR "must enter supplier "
					ATTRIBUTE(RED)
					LET p_text =  "must enter supplier "
					CALL messagebox(p_text,1)  		
					NEXT FIELD supplier
				END IF
				#IF g_style.sup_sty IS NULL THEN
				#	ERROR "must enter supplier style "
				#	NEXT FIELD sup_sty
				#END IF
				IF g_style.season IS NULL THEN
					ERROR "must enter season "
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS season "
					CALL messagebox(p_text,1)  		
					NEXT FIELD season
				END IF
				##IF g_style.division IS NULL THEN
					##ERROR "must enter division "
					##ATTRIBUTE(RED)
					##NEXT FIELD division
				##END IF
				#R07 >>
				IF g_style.section IS NULL THEN
					ERROR "must enter section "
					ATTRIBUTE(RED)
					LET p_text =  "must enter section "
					CALL messagebox(p_text,1)  		
					NEXT FIELD section
				END IF
				#R07 <<
				IF g_style.class IS NULL THEN
					ERROR "must enter class "
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS class "
					CALL messagebox(p_text,1)  		
					NEXT FIELD class
				END IF
				IF g_style.category IS NULL THEN
					ERROR "must enter category "
					ATTRIBUTE(RED)
					LET p_text =  "must enter category "
					CALL messagebox(p_text,1)  		
					NEXT FIELD category
				END IF
				#	ERROR "must enter fabric type "
				#	NEXT FIELD fabric_type
				#END IF
				#IF g_style.story IS NULL THEN
				#	ERROR "must enter story "
				#	NEXT FIELD story
				#END IF
				IF g_style.unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS unit cost "
					CALL messagebox(p_text,1)  		
					NEXT FIELD unit_cost
				END IF
				IF g_style.orig_sell IS NULL THEN
					ERROR "must enter original sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS original sell price "
					CALL messagebox(p_text,1)  		
					NEXT FIELD orig_sell
				END IF
				IF g_style.unit_sell IS NULL THEN
					ERROR "must enter last sell price "
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS last sell price "
					CALL messagebox(p_text,1)  		
					NEXT FIELD unit_sell
				END IF
				IF g_style.lchg_dte IS NULL THEN
					ERROR "must enter last change date "
					ATTRIBUTE(RED)
					LET p_text =  "must enter last change date "
					CALL messagebox(p_text,1)  		
					NEXT FIELD lchg_dte
				END IF
				IF g_style.del_flg IS NULL THEN
					ERROR "must enter style status "
					ATTRIBUTE(RED)
					LET p_text =  "must enter style status "
					CALL messagebox(p_text,1)  		
					NEXT FIELD del_flg
				END IF
				#R01 >>
				IF g_style.style_type IS NULL THEN
					ERROR "must enter style type "
					ATTRIBUTE(RED)
					LET p_text =  "must enter style type "
					CALL messagebox(p_text,1)  		
					NEXT FIELD style_type
				END IF
				IF g_style.unit_cost IS NULL THEN
					ERROR "must enter unit cost "
					ATTRIBUTE(RED)
					LET p_text =  "must enter AUS unit cost "
					CALL messagebox(p_text,1)  		
					NEXT FIELD unit_cost
				END IF
				#R01 <<

{
				IF g_hk_supplier IS  NULL THEN
					ERROR "must enter supplier "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HK  supplier "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_supplier
				END IF
				IF g_hk_season IS NULL THEN
					ERROR "must enter season "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HK  season "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_season
				END IF
				IF g_hk_class IS NULL THEN
					ERROR "must enter class "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HK class "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_class
				END IF
				IF g_hk_category IS  NULL THEN
					ERROR "must enter category "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HK category "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_category
				END IF

				IF g_hk_story IS NULL THEN
					ERROR "must enter story "
					ATTRIBUTE(RED)
					LET p_text =  "must enter HK story "
					CALL messagebox(p_text,1)  		
					NEXT FIELD g_hk_story     #r03
				END IF
}

				IF p_mode = "a" THEN
					IF g_hk_supplier IS NULL THEN
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Hongkong supplier "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_supplier
					END IF
					IF g_hk_season IS NULL THEN
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HongKong season "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_season
					END IF
					#R14 >>
					#IF g_hk_division IS NULL THEN
						#ERROR "must enter division "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter HongKong division "
						#CALL messagebox(p_text,1)  		
						#NEXT FIELD g_hk_division
					#END IF
					#R14 <<
					IF g_hk_class IS NULL THEN
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HongKongclass "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_class
					END IF
					IF g_hk_category IS NULL THEN
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter  HongKong category "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_category
					END IF

					IF g_hk_story IS NULL THEN
						ERROR "must enter story "
						ATTRIBUTE(RED)
						LET p_text =  "must enter HongKong  story "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_story     #r03
					END IF
					#R10 >>
					IF g_sin_supplier IS NULL THEN
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter SIN supplier "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_supplier
					END IF
					#R10 <<
					#R11 >>
					IF g_nz_supplier IS NULL THEN
						ERROR "must enter supplier "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ supplier "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_supplier
					END IF
					#R11 <<
					IF g_hk_unit_cost IS NULL THEN
						LET p_text =  "must enter HK unit cost "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_unit_cost
					END IF
					IF g_hk_orig_sell IS NULL THEN
						LET p_text =  "must enter HK original sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_orig_sell
					END IF
					IF g_hk_unit_sell IS NULL THEN
						LET p_text =  "must enter HK last sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_hk_unit_sell
					END IF
					#R10 >>
					IF g_sin_season IS NULL THEN
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter Singapore season "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_season
					END IF

					#R14 >>
					#IF g_sin_division IS NULL THEN
						#ERROR "must enter Singapore division "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter Singapore division "
						#CALL messagebox(p_text,1)  		
						##NEXT FIELD g_sin_division
					#END IF
					#R14 <<
					IF g_sin_class IS NULL THEN
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter SIN class "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_class
					END IF
					IF g_sin_category IS NULL THEN
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter  SIN category "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_category
					END IF
					IF g_sin_unit_cost IS NULL THEN
						LET p_text =  "must enter SIN unit cost "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_unit_cost
					END IF
					IF g_sin_orig_sell IS NULL THEN
						LET p_text =  "must enter SIN original sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_orig_sell
					END IF
					IF g_sin_unit_sell IS NULL THEN
						LET p_text =  "must enter SIN last sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_unit_sell
					END IF
					IF g_sin_story IS NULL THEN
						LET p_text =  "must enter Singapore  story "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_sin_story     #r03
					END IF
					#R10 <<
					#R11 >>
					IF g_nz_season IS NULL THEN
						ERROR "must enter season "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ season "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_season
					END IF
					#R14 >>
					#IF g_nz_division IS NULL THEN
						#ERROR "must enter division "
						#ATTRIBUTE(RED)
						#LET p_text =  "must enter NZ division "
						#CALL messagebox(p_text,1)  		
						#NEXT FIELD g_nz_division
					#END IF
					#R15 <<
					IF g_nz_class IS NULL THEN
						ERROR "must enter class "
						ATTRIBUTE(RED)
						LET p_text =  "must enter NZ class "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_class
					END IF
					IF g_nz_category IS NULL THEN
						ERROR "must enter category "
						ATTRIBUTE(RED)
						LET p_text =  "must enter  NZ category "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_category
					END IF
					IF g_nz_unit_cost IS NULL THEN
						LET p_text =  "must enter NZ unit cost "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_unit_cost
					END IF
					IF g_nz_orig_sell IS NULL THEN
						LET p_text =  "must enter NZ original sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_orig_sell
					END IF
					IF g_nz_unit_sell IS NULL THEN
						LET p_text =  "must enter NZ last sell price "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_unit_sell
					END IF
					IF g_nz_story IS NULL THEN
						LET p_text =  "must enter NZ  story "
						CALL messagebox(p_text,1)  		
						NEXT FIELD g_nz_story     
					END IF
					#R11<<
				END IF
				LET lstate = "WRITEDATA"

			#gxx >>
			ON ACTION cancel
				IF p_mode = "a" THEN
					INITIALIZE g_style.* TO NULL
					#R02 >>
					LET g_hk_style_desc = NULL
					LET g_hk_short_desc = NULL
					LET g_hk_supplier = NULL
					LET g_hk_season = NULL
					LET g_hk_division = NULL			#R14
					LET g_hk_class = NULL
					LET g_hk_category = NULL
					LET g_hk_unit_cost = NULL
					LET g_hk_unit_sell = NULL
					LET g_hk_orig_sell = NULL
					LET g_hk_lchg_dte = NULL
					LET g_hk_gst_perc = NULL
					LET g_hk_gst_perc = NULL
					LET g_hk_fob_method = NULL  #R03
					LET g_hk_fob = NULL
					LET g_hk_fob_cost = NULL
					LET g_hk_story =   NULL
					LET g_hk_story_desc =  NULL   #R03
					#R10 >>
					LET g_sin_style_desc = NULL
					LET g_sin_short_desc = NULL
					LET g_sin_supplier = NULL
					LET g_sin_season = NULL
					LET g_sin_division = NULL				#R14
					LET g_sin_class = NULL
					LET g_sin_category = NULL
					LET g_sin_unit_cost = NULL
					LET g_sin_unit_sell = NULL
					LET g_sin_orig_sell = NULL
					LET g_sin_lchg_dte = NULL
					LET g_sin_gst_perc = NULL
					LET g_sin_gst_perc = NULL
					LET g_sin_fob_method = NULL  #R03
					LET g_sin_fob = NULL
					LET g_sin_fob_cost = NULL
					LET g_sin_story =   NULL
					LET g_sin_story_desc =  NULL   #R03
					#R10 <<
					#R11 >>
					LET g_nz_style_desc = NULL
					LET g_nz_short_desc = NULL
					LET g_nz_supplier = NULL
					LET g_nz_season = NULL
					LET g_nz_division = NULL				#R14
					LET g_nz_class = NULL
					LET g_nz_category = NULL
					LET g_nz_unit_cost = NULL
					LET g_nz_unit_sell = NULL
					LET g_nz_orig_sell = NULL
					LET g_nz_lchg_dte = NULL
					LET g_nz_gst_perc = NULL
					LET g_nz_gst_perc = NULL
					LET g_nz_fob_method = NULL  
					LET g_nz_fob = NULL
					LET g_nz_fob_cost = NULL
					LET g_nz_story =   NULL
					LET g_nz_story_desc =  NULL   
					#R11 <<
					#R02 <<
					LET lstate = "GETOUT"
				ELSE
					LET lstate = "GETOUT"
				END IF
				EXIT INPUT
			#gxx <<
			END INPUT

		WHEN lstate = "WRITEDATA"	
			IF p_mode = "a" THEN
				IF sty_entI("INSERT") THEN
					LET p_retstat = TRUE
					LET g_wherepart =
						" WHERE style = \"", g_style.style, "\""
					LET p_text =  "style added"
					LET lstate = "GETOUT"
					CALL sty_entLG("a")							#R06
					##INITIALIZE g_style.* TO NULL
					CALL sty_entX()
				ELSE
					LET p_retstat = FALSE
					LET p_text = "adding style failed"
					LET lstate = "GETOUT"
				END IF
				CALL messagebox(p_text,1)						#gxx
			ELSE
				#R02 >>
				IF g_first_recv IS NULL  THEN
					IF p_unit_sell_temp != g_style.unit_sell THEN
						SELECT	count(*)
						INTO	p_count
						FROM	sku
						WHERE 	style = g_style.style
					
						IF p_count > 0 THEN
							LET p_text = 
                            	"\nDo you want to apply last AUS unit sell",
                            	"\nto all colour"

							MENU "Dialog"
       						ATTRIBUTE( STYLE="dialog",
                  				COMMENT= p_text,
                  				IMAGE="stop")
       							COMMAND "No" 
                					LET  g_opt = "NO"
       							COMMAND "Yes" 
                					LET  g_opt = "YES"
  							END MENU
                			CASE
                			WHEN g_opt = "NO"
								IF NOT sty_sku() THEN
 									LET p_text =
             							"no LSP been updated "
									CALL messagebox(p_text,1)  		#gxx
									GOTO retry
								END IF
							END CASE
						END IF
					END IF
				ELSE
					LET g_first_recv = "010100"
				END IF
				#R02 >>
##display "seedhk test : ",g_hk_first_recv
				IF g_hk_first_recv IS NULL  THEN
					IF p_hk_unit_sell_temp != g_hk_unit_sell THEN
##display "here"
						SELECT	count(*)
						INTO	p_count
						FROM	seedhk:sku
						WHERE 	style = g_style.style
					
						IF p_count > 0 THEN
							LET p_text = 
                            	"\nDo you want to apply last HK unit sell",
                            	"\nto all colour"

							MENU "Dialog"
       						ATTRIBUTE( STYLE="dialog",
                  				COMMENT= p_text,
                  				IMAGE="stop")
       							COMMAND "No" 
                					LET  g_hkopt = "NO"
       							COMMAND "Yes" 
                					LET  g_hkopt = "YES"
  							END MENU
                			CASE
                			WHEN g_hkopt = "NO"
								IF NOT sty_HK_sku() THEN
 									LET p_text =
             							"no LSP been updated "
									CALL messagebox(p_text,1)  		#gxx
									GOTO retry
								END IF
							END CASE
						END IF
					END IF
				ELSE
					LET g_hk_first_recv = "010100"			#R02
				END IF
				#R10 >>
				IF g_sin_first_recv IS NULL  THEN
					IF p_sin_unit_sell_temp != g_sin_unit_sell THEN
##display "here"
						SELECT	count(*)
						INTO	p_count
						FROM	seedsin:sku
						WHERE 	style = g_style.style
					
						IF p_count > 0 THEN
							LET p_text = 
                            	"\nDo you want to apply last SIN unit sell",
                            	"\nto all colour"

							MENU "Dialog"
       						ATTRIBUTE( STYLE="dialog",
                  				COMMENT= p_text,
                  				IMAGE="stop")
       							COMMAND "No" 
                					LET  g_sinopt = "NO"
       							COMMAND "Yes" 
                					LET  g_sinopt = "YES"
  							END MENU
                			CASE
                			WHEN g_sinopt = "NO"
								IF NOT sty_sin_sku() THEN
 									LET p_text =
             							"no LSP been updated "
									CALL messagebox(p_text,1)  		#gxx
									GOTO retry
								END IF
							END CASE
						END IF
					END IF
				ELSE
					LET g_sin_first_recv = "010100"			
				END IF
				#R10 <<
		
				#R11 >>
				IF g_nz_first_recv IS NULL  THEN
					IF p_nz_unit_sell_temp != g_nz_unit_sell THEN
##display "here"
						SELECT	count(*)
						INTO	p_count
						FROM	seednz:sku
						WHERE 	style = g_style.style
					
						IF p_count > 0 THEN
							LET p_text = 
                            	"\nDo you want to apply last NZ unit sell",
                            	"\nto all colour"

							MENU "Dialog"
       						ATTRIBUTE( STYLE="dialog",
                  				COMMENT= p_text,
                  				IMAGE="stop")
       							COMMAND "No" 
                					LET  g_nzopt = "NO"
       							COMMAND "Yes" 
                					LET  g_nzopt = "YES"
  							END MENU
                			CASE
                			WHEN g_nzopt = "NO"
								IF NOT sty_nz_sku() THEN
 									LET p_text =
             							"no LSP been updated "
									CALL messagebox(p_text,1)  		#gxx
									GOTO retry
								END IF
							END CASE
						END IF
					END IF
				ELSE
					LET g_nz_first_recv = "010100"			
				END IF
				#R11 <<
			#R02 <<
				IF sty_entI("UPDATE") THEN
					LET p_retstat = TRUE
					LET p_text = "style updated"
					CALL sty_entLG("u")							#R06
					LET lstate = "GETOUT"
					#R10 >>
{
					INITIALIZE g_style.* TO NULL
					LET g_hk_style_desc = NULL
					LET g_hk_short_desc = NULL
					LET g_hk_supplier = NULL
					LET g_hk_season = NULL
					LET g_hk_class = NULL
					LET g_hk_category = NULL
					LET g_hk_unit_cost = NULL
					LET g_hk_unit_sell = NULL
					LET g_hk_orig_sell = NULL
					LET g_hk_lchg_dte = NULL
					LET g_hk_gst_perc = NULL
					LET g_hk_gst_perc = NULL
					LET g_hk_fob_method = NULL  
					LET g_hk_fob = NULL
					LET g_hk_fob_cost = NULL
					LET g_hk_story =   NULL
					LET g_hk_story_desc =  NULL   
					#R10 >>
					LET g_sin_style_desc = NULL
					LET g_sin_short_desc = NULL
					LET g_sin_supplier = NULL
					LET g_sin_season = NULL
					LET g_sin_division = NULL			#R14
					LET g_sin_class = NULL
					LET g_sin_category = NULL
					LET g_sin_unit_cost = NULL
					LET g_sin_unit_sell = NULL
					LET g_sin_orig_sell = NULL
					LET g_sin_lchg_dte = NULL
					LET g_sin_gst_perc = NULL
					LET g_sin_gst_perc = NULL
					LET g_sin_fob_method = NULL  
					LET g_sin_fob = NULL
					LET g_sin_fob_cost = NULL
					LET g_sin_story =   NULL
					LET g_sin_story_desc =  NULL   
					CALL sty_entX()
}
					#R10 <<
				ELSE
					LET p_retstat = FALSE
					LET lstate = "GOTERR"		{ error return to caller }
					LET p_text = "updating style failed"
				END IF
				CALL messagebox(p_text,1) 		#gxx
			END IF
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
################################################################################
#	reqhdrX - display banking data                                          #
################################################################################
FUNCTION sty_entX()
	DEFINE
			p_size_desc					LIKE sty_sizehdr.size_desc,				#R19
			p_customs_desc				LIKE ax_customs.customs_desc,			#R15
			p_country_name			LIKE ax_country.country_name,				#R15
			p_hkcustoms_desc				LIKE ax_customs.customs_desc,			#R15
			p_hkcountry_name			LIKE ax_country.country_name,				#R15
			p_sincustoms_desc				LIKE ax_customs.customs_desc,			#R15
			p_sincountry_name			LIKE ax_country.country_name,				#R15
			p_nzcustoms_desc				LIKE ax_customs.customs_desc,			#R15
			p_nzcountry_name			LIKE ax_country.country_name,				#R15
			p_hk_unit_sellx			DECIMAL(8,2),
			p_sin_unit_sellx		DECIMAL(8,2),
			p_nz_unit_sellx			DECIMAL(8,2),
			cb                          ui.ComboBox,			#R03
			#R03 >>
			p_style_desc                LIKE style.style_desc,
			 p_style	                LIKE style.style,
			p_assort1_desc,
			p_assort2_desc,
			p_assort3_desc				CHAR(30),
			p_sub_cat1_name,
			p_sub_cat2_name,
			p_sub_cat3_name,
			p_sub_cat4_name,
			p_sub_cat5_name,
			p_sub_sub_cat1_name,
			p_sub_sub_cat2_name,
			p_sub_sub_cat3_name,
			p_sub_sub_cat4_name,
			p_sub_sub_cat5_name,
			p_cat1_name					LIKE web_cat1.web_cat_name,	#R01
			p_cat2_name					LIKE web_cat1.web_cat_name,	#R01
			p_cat3_name					LIKE web_cat1.web_cat_name,	#R01
			p_cat4_name					LIKE web_cat1.web_cat_name,	#R01
			p_cat5_name					LIKE web_cat1.web_cat_name,	#R01
			r1x							CHAR(2000) ,			#R21
			r2x,r3x					CHAR(300),
			#R03 <<
			#R13 >>
			p_dw_cat1_name,
			p_dw_subcat1_name,
			p_dw_ssubcat1_name,
			p_dw_sssubcat1_name,
			p_dw_cat2_name,
			p_dw_subcat2_name,
			p_dw_ssubcat2_name,
			p_dw_sssubcat2_name,
			p_dw_cat3_name,
			p_dw_subcat3_name,
			p_dw_ssubcat3_name,
			p_dw_sssubcat3_name,
			p_dw_cat4_name,
			p_dw_subcat4_name,
			p_dw_ssubcat4_name,
			p_dw_sssubcat4_name,
			p_dw_cat5_name,
			p_dw_subcat5_name,
			p_dw_ssubcat5_name,
			p_dw_sssubcat5_name,
			#R13 <<
			p_supplier_name 			LIKE supplier.supplier_name,
		    p_season_desc 				LIKE season.season_desc,
			p_division_name 			LIKE division.division_name,
			p_hk_division_name 			LIKE division.division_name,					#R14
			p_sin_division_name 			LIKE division.division_name,				#R14
			p_nz_division_name 			LIKE division.division_name,					#R14
			p_section_name 				LIKE division.division_name,				#R07
		    p_class_desc 				LIKE class.class_desc,
			p_category_name 			LIKE category.category_name,
		    p_fabric_desc 				LIKE fabric_type.fabric_desc,
		    p_story_desc 				LIKE story.story_desc,
			p_hk_supplier_name 			LIKE supplier.supplier_name,			#R02
		    p_hk_season_desc 			LIKE season.season_desc,			#R02
		    p_hk_class_desc 			LIKE class.class_desc,			#R02
		    p_hk_story_desc 			LIKE story.story_desc,			#R03
            r1,r2,r8,r9                 CHAR(20),                       #R03
			p_hk_category_name 		LIKE category.category_name,			#R10
			p_sin_supplier_name			LIKE supplier.supplier_name,		#R10
		    p_sin_season_desc 			LIKE season.season_desc,			#R10
		    p_sin_class_desc 			LIKE class.class_desc,			#R10
		    p_sin_story_desc 			LIKE story.story_desc,			#R10
            sin17,sin18                 CHAR(20),                       #R10
			p_sin_category_name 		LIKE category.category_name,			#R10
			p_nz_supplier_name			LIKE supplier.supplier_name,		#R10
		    p_nz_season_desc 			LIKE season.season_desc,			#R10
		    p_nz_class_desc 			LIKE class.class_desc,			#R10
		    p_nz_story_desc 			LIKE story.story_desc,			#R10
            nz17,nz18                 CHAR(20),                       #R10
			p_nz_category_name 		LIKE category.category_name			#R10
	
	IF g_currentrec IS NOT NULL AND g_currentrec != 0 THEN
		MESSAGE "record ",g_currentrec USING "<<<<<#",
				" of ", g_totrec USING "<<<<<#"
	END IF

	LET	p_supplier_name = NULL
	SELECT	supplier_name
	INTO	p_supplier_name
	FROM	supplier
	WHERE	supplier = g_style.supplier

	LET	p_season_desc = NULL
	SELECT	season_desc
	INTO	p_season_desc
	FROM	season
	WHERE	season = g_style.season

	#R14 >>
	LET	p_division_name = NULL
	SELECT	division_name
	INTO	p_division_name
	FROM	division
	WHERE	division = g_style.division
	#R14 <<

	#R07 >>
	LET	p_section_name = NULL
	SELECT	section_name
	INTO	p_section_name
	FROM	section
	WHERE	section = g_style.section

	LET	p_class_desc = NULL
	SELECT	class_desc
	INTO	p_class_desc
	FROM	class
	WHERE	class = g_style.class

	LET	p_category_name = NULL
	SELECT	category_name
	INTO	p_category_name
	FROM	category
	WHERE	category = g_style.category

	LET	p_fabric_desc = NULL
	SELECT	fabric_desc
	INTO	p_fabric_desc
	FROM	fabric_type
	WHERE	fabric_type = g_style.fabric_type

	LET	p_story_desc = NULL
	SELECT	story_desc
	INTO	p_story_desc
	FROM	story
	WHERE	story = g_style.story

	#R15x >>
  	SELECT  country_name
  	INTO  	p_country_name
    FROM    ax_country
    WHERE   country = g_style.country_of_origin					#R15

    ##IF check_numb(g_style.classification) THEN				#R15
    	#SELECT  customs_desc
		#INTO	p_customs_desc
    	#FROM    ax_customs
    	#WHERE   customs_desc = g_style.classification					#R15
	##END IF
	#R15 <<

	#R02 >>
	LET	p_hk_supplier_name = NULL
	SELECT	supplier_name
	INTO	p_hk_supplier_name
	FROM	supplier
	WHERE	supplier = g_hk_supplier

	LET	p_hk_season_desc = NULL
	SELECT	seedhk:season.season_desc
	INTO	p_hk_season_desc
	FROM	seedhk:season
	WHERE	seedhk:season.season = g_hk_season

	#R14 >>
	LET	p_hk_division_name = NULL
	SELECT	seedhk:division.division_name
	INTO	p_hk_division_name
	FROM	seedhk:division
	WHERE	seedhk:division.division = g_hk_division
	#R14 <<

	LET	p_hk_class_desc = NULL
	SELECT	class_desc
	INTO	p_hk_class_desc
	FROM	class
	WHERE	class = g_hk_class

	LET	p_hk_category_name = NULL
	SELECT	category_name
	INTO	p_category_name
	FROM	category
	WHERE	category = g_hk_category
	#R02 <<
    #R03

    #R05tantest
    IF g_hk_story is NULL THEN
         LET g_hk_story = g_style.story
    END IF

	LET	p_hk_story_desc = NULL

	SELECT	story_desc
	INTO	p_hk_story_desc
	FROM	story
	WHERE	story = g_hk_story
	#R10 >>
	LET	p_sin_supplier_name = NULL
	SELECT	supplier_name
	INTO	p_sin_supplier_name
	FROM	supplier
	WHERE	supplier = g_sin_supplier

	LET	p_sin_season_desc = NULL
	SELECT	seedsin:season.season_desc
	INTO	p_sin_season_desc
	FROM	seedsin:season
	WHERE	seedsin:season.season = g_sin_season

	#R14 >>
	LET	p_sin_division_name = NULL
	SELECT	seedsin:division.division_name
	INTO	p_sin_division_name
	FROM	seedsin:division
	WHERE	seedsin:division.division = g_sin_division
	#R14 <<

	LET	p_sin_class_desc = NULL
	SELECT	class_desc
	INTO	p_sin_class_desc
	FROM	class
	WHERE	class = g_sin_class

	LET	p_sin_category_name = NULL
	SELECT	category_name
	INTO	p_category_name
	FROM	category
	WHERE	category = g_sin_category

    IF g_sin_story is NULL THEN
         LET g_sin_story = g_style.story
    END IF

	LET	p_sin_story_desc = NULL

	SELECT	story_desc
	INTO	p_sin_story_desc
	FROM	story
	WHERE	story = g_sin_story
	#R10 <<
	#R11 >>
	LET	p_nz_supplier_name = NULL
	SELECT	supplier_name
	INTO	p_nz_supplier_name
	FROM	supplier
	WHERE	supplier = g_nz_supplier

	LET	p_nz_season_desc = NULL
	SELECT	seednz:season.season_desc
	INTO	p_nz_season_desc
	FROM	seednz:season
	WHERE	seednz:season.season = g_nz_season

	#R14 >>
	LET	p_nz_division_name = NULL
	SELECT	seednz:division.division_name
	INTO	p_nz_division_name
	FROM	seednz:division
	WHERE	seednz:division.division = g_nz_division
	#R14 <<

	LET	p_nz_class_desc = NULL
	SELECT	class_desc
	INTO	p_nz_class_desc
	FROM	class
	WHERE	class = g_nz_class

	LET	p_nz_category_name = NULL
	SELECT	category_name
	INTO	p_category_name
	FROM	category
	WHERE	category = g_nz_category

    IF g_nz_story is NULL THEN
         LET g_nz_story = g_style.story
    END IF

	LET	p_nz_story_desc = NULL

	SELECT	story_desc
	INTO	p_nz_story_desc
	FROM	story
	WHERE	story = g_nz_story
	#R11 <<

	#R03 >>
	LET r1x =  g_style.web_desc1		
	LET r2x =  g_style.web_desc2	
	LET r3x =  g_style.web_desc3		

	LET p_style =g_style.style							
	LET p_style_desc = g_style.style_desc						#R03

	#R20 LET p_cat1_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_cat1_name
	#R20 FROM	web_cat1
	#R20 WHERE	web_cat = g_style.cat1 

	#R20 LET p_sub_cat1_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_cat1_name
	#R20 FROM	web_cat2
	#R20 WHERE	web_cat = g_style.sub_cat1 

	#R20 LET p_sub_sub_cat1_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_sub_cat1_name
	#R20 FROM	web_cat3
	#R20 WHERE	web_cat = g_style.sub_sub_cat1 

	#R20 LET p_cat2_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_cat2_name
	#R20 FROM	web_cat1
	#R20 WHERE	web_cat = g_style.cat2 

	#R20 LET p_sub_cat2_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_cat2_name
	#R20 FROM	web_cat2
	#R20 WHERE	web_cat = g_style.sub_cat2

	#R20 LET p_sub_sub_cat2_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_sub_cat2_name
	#R20 FROM	web_cat3
	#R20 WHERE	web_cat = g_style.sub_sub_cat2 

	#R20 LET p_cat3_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_cat3_name
	#R20#R20  FROM	web_cat1
	#R20 WHERE	web_cat = g_style.cat3 

	#R20 LET p_sub_cat3_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_cat3_name
	#R20 FROM	web_cat2
	#R20 WHERE	web_cat = g_style.sub_cat3 

	#R20 LET p_sub_sub_cat3_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_sub_cat3_name
	#R20 FROM	web_cat3
	#R20 WHERE	web_cat = g_style.sub_sub_cat3 

	#R20 LET p_cat4_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_cat4_name
	#R20 FROM	web_cat1
	#R20 WHERE	web_cat = g_style.cat4 

	#R20 LET p_sub_cat4_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_cat4_name
	#R20 FROM	web_cat2
	#R20 WHERE	web_cat = g_style.sub_cat4 

	#R20 LET p_sub_sub_cat4_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_sub_cat4_name
	#R20 FROM	web_cat3
	#R20 WHERE	web_cat = g_style.sub_sub_cat4 

	#R20 LET p_cat5_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_cat5_name
	#R20 FROM	web_cat1
	#R20 WHERE	web_cat = g_style.cat5 

	#R20 LET p_sub_cat5_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_cat5_name
	#R20 FROM	web_cat2
	#R20 WHERE	web_cat = g_style.sub_cat5 

	#R20 LET p_sub_sub_cat5_name = NULL
	#R20 SELECT	web_cat_name
	#R20 INTO	p_sub_sub_cat5_name
	#R20 FROM	web_cat3
	#R20 WHERE	web_cat = g_style.sub_sub_cat5 

	#R13 >>
	#category 1
	LET p_dw_cat1_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_cat1_name
	FROM	dw_web_cat1
	WHERE	web_cat = g_style_webcat.dw_cat1 

	LET p_dw_subcat1_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_subcat1_name
	FROM	dw_web_cat2
	WHERE	web_cat = g_style_webcat.dw_sub_cat1 

	LET p_dw_ssubcat1_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_ssubcat1_name
	FROM	dw_web_cat3
	WHERE	web_cat = g_style_webcat.dw_ssub_cat1 

	LET p_dw_sssubcat1_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_sssubcat1_name
	FROM	dw_web_cat4
	WHERE	web_cat = g_style_webcat.dw_sssub_cat1 

	#dw category 2
	LET p_dw_cat2_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_cat2_name
	FROM	dw_web_cat1
	WHERE	web_cat = g_style_webcat.dw_cat2 

	LET p_dw_subcat2_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_subcat2_name
	FROM	dw_web_cat2
	WHERE	web_cat = g_style_webcat.dw_sub_cat2 

	LET p_dw_ssubcat2_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_ssubcat2_name
	FROM	dw_web_cat3
	WHERE	web_cat = g_style_webcat.dw_ssub_cat2 

	LET p_dw_sssubcat2_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_sssubcat2_name
	FROM	dw_web_cat4
	WHERE	web_cat = g_style_webcat.dw_sssub_cat2 

	#dw category 3
	LET p_dw_cat3_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_cat3_name
	FROM	dw_web_cat1
	WHERE	web_cat = g_style_webcat.dw_cat3 

	LET p_dw_subcat3_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_subcat3_name
	FROM	dw_web_cat2
	WHERE	web_cat = g_style_webcat.dw_sub_cat3 

	LET p_dw_ssubcat3_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_ssubcat3_name
	FROM	dw_web_cat3
	WHERE	web_cat = g_style_webcat.dw_ssub_cat3 

	LET p_dw_sssubcat4_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_sssubcat4_name
	FROM	dw_web_cat4
	WHERE	web_cat = g_style_webcat.dw_sssub_cat3 

	#dw category 4
	LET p_dw_cat4_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_cat4_name
	FROM	dw_web_cat1
	WHERE	web_cat = g_style_webcat.dw_cat4 

	LET p_dw_subcat4_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_subcat4_name
	FROM	dw_web_cat2
	WHERE	web_cat = g_style_webcat.dw_sub_cat4 

	LET p_dw_ssubcat4_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_ssubcat4_name
	FROM	dw_web_cat3
	WHERE	web_cat = g_style_webcat.dw_ssub_cat4 

	LET p_dw_sssubcat4_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_sssubcat4_name
	FROM	dw_web_cat4
	WHERE	web_cat = g_style_webcat.dw_sssub_cat4 

	#dw category 5
	LET p_dw_cat5_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_cat5_name
	FROM	dw_web_cat1
	WHERE	web_cat = g_style_webcat.dw_cat5 

	LET p_dw_subcat5_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_subcat5_name
	FROM	dw_web_cat2
	WHERE	web_cat = g_style_webcat.dw_sub_cat5 

	LET p_dw_ssubcat5_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_ssubcat5_name
	FROM	dw_web_cat3
	WHERE	web_cat = g_style_webcat.dw_ssub_cat5 

	LET p_dw_sssubcat5_name = NULL
	SELECT	web_cat_name
	INTO	p_dw_sssubcat5_name
	FROM	dw_web_cat4
	WHERE	web_cat = g_style_webcat.dw_sssub_cat5 
	#R13 <<

	LET	p_assort1_desc = NULL
	SELECT	assort_ldesc 
	INTO	p_assort1_desc
	FROM	i_assortl
	WHERE	assort_lcode =  g_style.assort1
	AND		assort_id = 2

	LET	p_assort2_desc = NULL
	SELECT	assort_ldesc 
	INTO	p_assort2_desc
	FROM	i_assortl
	WHERE	assort_lcode =  g_style.assort2
	AND		assort_id = 3

	LET	p_assort3_desc = NULL
	SELECT	assort_ldesc 
	INTO	p_assort3_desc
	FROM	i_assortl
	WHERE	assort_lcode =  g_style.assort3
	AND		assort_id = 4

	#R03 >>
	LET g_hk_fob_method = NULL
	LET g_hk_fob = NULL
	LET g_hk_country_of_origin = NULL
	LET g_hk_fabric_content  = NULL
	LET g_hk_fabric_desc  = NULL				#R17
	LET g_hk_classification = NULL
	LET g_hk_garment_cons = NULL
	LET g_hk_garment_dept  = NULL     

	SELECT	fob_method,
			fob,
		    country_of_origin,
			fabric_desc,				#R17
			fabric_content ,
			classification,
			garment_cons,
			garment_dept,
			unit_sell					#R11
	INTO	g_hk_fob_method, 
			g_hk_fob,
		    g_hk_country_of_origin,
			g_hk_fabric_desc,			#R17
			g_hk_fabric_content ,
			g_hk_classification,
			g_hk_garment_cons,
			g_hk_garment_dept,      
			p_hk_unit_sellx				#R11
	FROM	seedhk:style
	WHERE	style = g_style.style
	#R03 <<
	#R11 >>
	IF p_hk_unit_sellx IS NULL THEN
		LET p_hk_unit_sellx = 0 
	END IF
	#R11 <<
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
   	LET r8= g_hk_fob_method 


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
	CALL cb.addItem("SGD","SGD")				#R10					

    LET r9 = g_hk_fob

	#AUS
	CALL ui.Interface.refresh()
   	LET cb = ui.ComboBox.forName("formonly.r1")
   	IF cb IS NULL THEN
    	ERROR "Form field not found in current form"
       	RETURN FALSE
   	END IF
   	CALL cb.clear()
	CALL cb.addItem("Air","Air")
   	CALL cb.addItem("Sea","Sea")
   	CALL cb.addItem("Local","Local")

   	LET r1= g_style.fob_method 

	CALL ui.Interface.refresh()
   	LET cb = ui.ComboBox.forName("formonly.r2")
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
   	LET r2= g_style.fob

	#R10 >>
	LET g_sin_fob_method = NULL
	LET g_sin_fob = NULL
	LET g_sin_country_of_origin = NULL
	LET g_sin_fabric_content  = NULL
	LET g_sin_fabric_desc  = NULL				#R17
	LET g_sin_classification = NULL
	LET g_sin_garment_cons = NULL
	LET g_sin_garment_dept  = NULL     

	SELECT	fob_method,
			fob,
		    country_of_origin,
			fabric_desc ,					#R17
			fabric_content ,
			classification,
			garment_cons,
			garment_dept,
			unit_sell						#R11      
	INTO	g_sin_fob_method, 
			g_sin_fob,
		    g_sin_country_of_origin,
			g_sin_fabric_desc ,				#R17
			g_sin_fabric_content ,
			g_sin_classification,
			g_sin_garment_cons,
			g_sin_garment_dept,      
			p_sin_unit_sellx				#R11
	FROM	seedsin:style
	WHERE	style = g_style.style

	#R11 >>
	IF p_sin_unit_sellx IS NULL THEN
		LET p_sin_unit_sellx = 0 
	END IF
	#R11 <<
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
   	LET sin17= g_sin_fob_method 


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
	CALL cb.addItem("SGD","SGD")				#R10					

    LET sin18 = g_sin_fob
	#R10 <<
	#R11 >>
	LET g_nz_fob_method = NULL
	LET g_nz_fob = NULL
	LET g_nz_country_of_origin = NULL
	LET g_nz_fabric_content  = NULL
	LET g_nz_fabric_desc  = NULL				#R17
	LET g_nz_classification = NULL
	LET g_nz_garment_cons = NULL
	LET g_nz_garment_dept  = NULL     

	SELECT	fob_method,
			fob,
		    country_of_origin,
			fabric_desc ,					#R17
			fabric_content ,
			classification,
			garment_cons,
			garment_dept      ,
			unit_sell					#R11
	INTO	g_nz_fob_method, 
			g_nz_fob,
		    g_nz_country_of_origin,
			g_nz_fabric_desc ,				#R17
			g_nz_fabric_content ,
			g_nz_classification,
			g_nz_garment_cons,
			g_nz_garment_dept      ,
			p_nz_unit_sellx			#R11
	FROM	seednz:style
	WHERE	style = g_style.style

	#R11 >>
	IF p_nz_unit_sellx IS NULL THEN
		LET p_nz_unit_sellx = 0 
	END IF
	#R11 <<
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
   	LET nz17= g_nz_fob_method 


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
	CALL cb.addItem("SGD","SGD")				#R10					

    LET nz18 = g_nz_fob
	#R11 <<

display r8,r9,g_hk_fob_method,g_hk_fob

	#R19 >>
  	SELECT  size_desc
  	INTO  	p_size_desc
    FROM    sty_sizehdr
    WHERE   size_code = g_style.size_code
	#R19 <<

	#R15x >>
  	SELECT  country_name
  	INTO  	p_hkcountry_name
    FROM    ax_country
    WHERE   country = g_hk_country_of_origin					#R15

    ##IF check_numb(g_hk_classification) THEN				#R15
    	##SELECT  customs_desc
		##INTO	p_hkcustoms_desc
    	##FROM    ax_customs
    	##WHERE   customs_desc = g_hk_classification					#R15
	##END IF

  	SELECT  country_name
  	INTO  	p_sincountry_name
    FROM    ax_country
    WHERE   country = g_sin_country_of_origin					#R15

    ##IF check_numb(g_sin_classification) THEN				#R15
    	##SELECT  customs_desc
		##INTO	p_sincustoms_desc
    	##FROM    ax_customs
    	##WHERE   customs_desc = g_sin_classification					#R15
	##END IF
  	SELECT  country_name
  	INTO  	p_nzcountry_name
    FROM    ax_country
    WHERE   country = g_nz_country_of_origin					#R15

    ##IF  check_numb(g_nz_classification) THEN				#R15
    	##SELECT  customs_desc
		##INTO	p_nzcustoms_desc
    	##FROM    ax_customs
    	##WHERE   customs_desc = g_nz_classification					#R15
	##END IF
	#R15 <<

	#R15 <<
	LET g_hk_style = g_style.style					#R10
	LET g_sin_style = g_style.style					#R10
	LET g_nz_style = g_style.style					#R11
   	DISPLAY BY NAME	g_style.style,
					g_hk_style,						#R10
					g_sin_style,					#R10
					g_nz_style,					#R11
				  	g_style.style_desc,
    			    g_style.short_desc,
    				g_style.supplier,
					p_supplier_name,
    				g_style.sup_sty,
    				g_style.season,
					p_season_desc,
    				g_style.division,				#R14
					p_division_name,				#R14
    				g_style.section,				#R07
					p_section_name,					#R07
    				g_style.class,
					p_class_desc,
    				g_style.category,
					p_category_name,
    				g_style.myer_desc,			#R22
    				g_style.fabric_type,
					p_fabric_desc,
					g_style.fabric_desc,		#R20
    			    g_style.story,
				    p_hk_story_desc,
    				g_style.lchg_dte,
    				g_style.style_type,				#R01
    				g_style.del_flg,
    				g_style.unit_cost,
    				g_style.gst_perc,
    			    g_style.country_of_origin,
					p_country_name,					#R15
    		        g_style.fabric_content,
    				g_style.classification,
					##p_customs_desc,					#R15
    				g_style.garment_cons,
    				g_style.garment_dept,
    				g_style.unit_sell,
					p_hk_unit_sellx,						#R11
					p_sin_unit_sellx,						#R11
					p_nz_unit_sellx,						#R11
    				g_style.orig_sell,
				#R02 >>
				  	g_hk_style_desc,
    			    g_hk_short_desc,
    				g_hk_supplier,
					p_hk_supplier_name,
    				g_hk_season,
					p_hk_season_desc,
					#R15 >>
    				g_hk_division,				#R14
					p_hk_division_name,			#R14
    				g_hk_class,
					p_hk_class_desc,
    				g_hk_category,
					p_hk_category_name,
    				g_hk_lchg_dte,
    				g_hk_unit_cost,
    				g_hk_gst_perc,
    				g_hk_unit_sell,
    				g_hk_orig_sell,
					r1,						#R03
					r2,						#R03
                    r8,
                    r9,
    				#g_hk_fob_method,   #R03
    				#g_hk_fob,
    				g_hk_fob_cost,
    				g_style.fob_cost,			#R03
    				g_hk_story,
					p_hk_story_desc,   #R03
				#R02 <<
    				g_style.catalogue,				
    				g_style.size_code,				#R19
  					p_size_desc,					#R19
    			    g_style.page,						
    			    g_style.web_care,					
    				g_hk_country_of_origin,		
  				  	p_hkcountry_name,
    				g_hk_classification,
			   		##p_hkcustoms_desc,
    				g_hk_garment_cons,
    				g_hk_garment_dept,
					g_hk_page,
    				g_hk_web_care,					
    				g_hk_fabric_desc,			#R17
    				g_hk_fabric_content,
					#R10 >>
				  	g_sin_style_desc,
    			    g_sin_short_desc,
    				g_sin_supplier,
					p_sin_supplier_name,
    				g_sin_season,
					p_sin_season_desc,
    				g_sin_division,			#R14
					p_sin_division_name,	#R14
    				g_sin_class,
					p_sin_class_desc,
    				g_sin_category,
					p_sin_category_name,
    				g_sin_lchg_dte,
    				g_sin_unit_cost,
    				g_sin_gst_perc,
    				g_sin_unit_sell,
    				g_sin_orig_sell,
					sin17,
					sin18,
    				g_sin_fob_cost,
    				g_style.fob_cost,			
    				g_sin_story,
					p_sin_story_desc,
    				g_sin_country_of_origin,		
  				  	p_sincountry_name,
    				g_sin_classification,
					##p_sincustoms_desc,
    				g_sin_garment_cons,
    				g_sin_garment_dept,
					g_sin_page,
    				g_sin_web_care,					
    				g_sin_fabric_desc,				#R17
    				g_sin_fabric_content,
					#R11 >>
				  	g_nz_style_desc,
    			    g_nz_short_desc,
    				g_nz_supplier,
					p_nz_supplier_name,
    				g_nz_season,
					p_nz_season_desc,
    				g_nz_division,				#R14
					p_nz_division_name,			#R14
    				g_nz_class,
					p_nz_class_desc,
    				g_nz_category,
					p_nz_category_name,
    				g_nz_lchg_dte,
    				g_nz_unit_cost,
    				g_nz_gst_perc,
    				g_nz_unit_sell,
    				g_nz_orig_sell,
					nz17,
					nz18,
    				g_nz_fob_cost,
    				g_style.fob_cost,			
    				g_nz_story,
					p_nz_story_desc,
    				g_nz_country_of_origin,		
  				  	p_nzcountry_name,
    				g_nz_classification,
					##p_nzcustoms_desc,
    				g_nz_garment_cons,
    				g_nz_garment_dept,
					g_nz_page,
    				g_nz_web_care,					
    				g_nz_fabric_desc,			#R17
    				g_nz_fabric_content
					#R11 <<
					#R10 <<
	ATTRIBUTE(NORMAL)
	#R03 >>
	DISPLAY BY NAME g_style.web_style_desc,
					r1x,					
					r2x,					
					r3x,					
    				#R20 g_style.cat1,				
					#R20 p_cat1_name,				
    				#R20 g_style.sub_cat1,			
					#R20 p_sub_cat1_name,			
    				#R20 g_style.sub_sub_cat1,		
					#R20 p_sub_sub_cat1_name,				
    				#R20 g_style.cat2,				
					#R20 p_cat2_name,			
    				#R20 g_style.sub_cat2,	
					#R20 p_sub_cat2_name,				
    				#R20 g_style.sub_sub_cat2,				
					#R20 p_sub_sub_cat2_name,				
    				#R20 g_style.cat3,				
					#R20 p_cat3_name,			
    				#R20 g_style.sub_cat3,				
					#R20 p_sub_cat3_name,				
    				#R20 g_style.sub_sub_cat3,			
					#R20 p_sub_sub_cat3_name,				
    				#R20 g_style.cat4,				
					#R20 p_cat4_name,				
    				#R20 g_style.sub_cat4,				
					#R20 p_sub_cat4_name,				
    				#R20 g_style.sub_sub_cat4,			
					#R20 p_sub_sub_cat4_name,			
    				#R20 g_style.cat5,				
					#R20 p_cat5_name,				
    				#R20 g_style.sub_cat5,				
					#R20 p_sub_cat5_name,				
    				#R20 g_style.sub_sub_cat5,			
					#R20 p_sub_sub_cat5_name,			
					#R13 >>
    				g_style_webcat.dw_cat1,				
					p_dw_cat1_name,				
    				g_style_webcat.dw_sub_cat1,			
					p_dw_subcat1_name,			
    				g_style_webcat.dw_ssub_cat1,		
					p_dw_ssubcat1_name,				
    				g_style_webcat.dw_sssub_cat1,		
					p_dw_sssubcat1_name,				

    				g_style_webcat.dw_cat2,				
					p_dw_cat2_name,			
    				g_style_webcat.dw_sub_cat2,	
					p_dw_subcat2_name,				
    				g_style_webcat.dw_ssub_cat2,				
					p_dw_ssubcat2_name,				
    				g_style_webcat.dw_sssub_cat2,				
					p_dw_sssubcat2_name,				

    				g_style_webcat.dw_cat3,				
					p_dw_cat3_name,			
    				g_style_webcat.dw_sub_cat3,				
					p_dw_subcat3_name,				
    				g_style_webcat.dw_ssub_cat3,			
					p_dw_ssubcat3_name,				
    				g_style_webcat.dw_sssub_cat3,			
					p_dw_sssubcat3_name,				

    				g_style_webcat.dw_cat4,				
					p_dw_cat4_name,				
    				g_style_webcat.dw_sub_cat4,				
					p_dw_subcat4_name,				
    				g_style_webcat.dw_ssub_cat4,			
					p_dw_ssubcat4_name,			
    				g_style_webcat.dw_sssub_cat4,			
					p_dw_sssubcat4_name,			

    				g_style_webcat.dw_cat5,				
					p_dw_cat5_name,				
    				g_style_webcat.dw_sub_cat5,				
					p_dw_subcat5_name,				
    				g_style_webcat.dw_ssub_cat5,			
					p_dw_ssubcat5_name,			
    				g_style_webcat.dw_sssub_cat5,			
					p_dw_sssubcat5_name,			
					#R13 <<

    				g_style.assort1,			
					p_assort1_desc,
    				g_style.assort2,			
					p_assort2_desc,
    				g_style.assort3,			
					p_assort3_desc,
				    g_style.givex_id			#R18
	ATTRIBUTE(NORMAL)
	#R03x <<
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sty_entX) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_sku()

	DEFINE
			p_f10 					INTEGER,
			sidx 					INTEGER,
			p_status				INTEGER,
			p_text					CHAR(100),
			p_option				CHAR(80),
			p_retstat				INTEGER,
			idx						INTEGER,
			jdx						INTEGER,
			p_colour_name			LIKE colour.colour_name,
			p_dummy					INTEGER

	OPEN WINDOW w_1 AT 9,5
    WITH FORM "sty_sku"
	ATTRIBUTE(TEXT="Style SKu",STYLE="naked")
	#gxx <<

	OPTIONS
			DELETE KEY F20,
			INSERt KEY F30

	LET s_arrsize = 100
	LET s_dspsize = 10
    LET s_maxidx = 0
    LET p_retstat = TRUE
	FOR idx = 1 TO s_arrsize
        INITIALIZE ssa_skulns[idx].* TO NULL
        INITIALIZE ssa_skulns1[idx].* TO NULL
    END FOR
	INITIALIZE s_skulns.* TO NULL

	DECLARE c_sel CURSOR FOR 
	SELECT	a.*,size_pos
	FROM	sku  a, sizes b
	WHERE	style = g_style.style
	AND		a.sizes = b.sizes
	ORDER	BY colour,size_pos

	LET idx = 1
	FOREACH c_sel INTO s_skulns.* ,p_dummy
		LET ssa_skulns[idx].sku = s_skulns.sku
		LET ssa_skulns[idx].colour = s_skulns.colour

		LEt p_colour_name = NULL
		SELECT	colour_name
		INTO	p_colour_name  
		FROM	colour
		WHERE	colour = s_skulns.colour

		LET ssa_skulns[idx].colour_name = p_colour_name
		LET ssa_skulns[idx].sizes = s_skulns.sizes
		LET ssa_skulns[idx].unit_sell = s_skulns.unit_sell

		LET ssa_skulns1[idx].ord_nbr =  s_skulns.ord_nbr
		LET ssa_skulns1[idx].style =  s_skulns.style
		LET ssa_skulns1[idx].unit_cost =  g_style.unit_cost
		LET ssa_skulns1[idx].date_first_receipt =  s_skulns.date_first_receipt
		LET ssa_skulns1[idx].sku_status =  s_skulns.sku_status
		LET idx = idx + 1
	END FOREACH
	LET s_maxidx = idx - 1
	IF idx <= s_arrsize THEN
		INITIALIZE ssa_skulns[idx].* TO NULL
		INITIALIZE ssa_skulns1[idx].* TO NULL
		FOR jdx = idx TO s_arrsize
			LET ssa_skulns[jdx].* = ssa_skulns[idx].* 
			LET ssa_skulns1[jdx].* = ssa_skulns1[idx].* 
		END FOR
	END IF
	LET p_option = "OPTIONS: F1=ACCEPT F10=EXIT"
	DISPLAY p_option AT 13,1
	ATTRIBUTE(BLUE,REVERSE)
	WHILE TRUE
		CALL SET_COUNT(s_maxidx)
		LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_skulns
    	WITHOUT DEFAULTS 
    	FROM sc_skulns.*
		ATTRIBUTE(NORMAL)
		
			BEFORE ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
				LET s_maxidx = ARR_COUNT()

			AFTER ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()

   	       ON KEY (F10)
				LET s_maxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			
			AFTER INPUT
				MESSAGE ""
				LET s_maxidx = ARR_COUNT()
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				FOR idx = 1 TO s_maxidx
					IF ssa_skulns[idx].unit_sell IS NULL THEN
						LET p_text = " LSP must be entered"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
					IF ssa_skulns[idx].unit_sell = 0 THEN
						LET p_text = " LSP cannot equal to 0"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
				END FOR			
		   #gxx >>
   	       ON ACTION exit
				LET s_maxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			#gxx <<
			END INPUT
	        IF p_retstat OR p_f10 THEN
	          	EXIT WHILE
	       	END IF
		END WHILE
		MESSAGE ""
		CLOSE WINDOW w_1
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sty_sku) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#   sty_entA() update sku last selling price
################################################################################
FUNCTION sty_entA()
	DEFINE
			p_retstat				INTEGER,
			idx						INTEGER

	LET p_retstat = TRUE
	DELETE FROM sku
    WHERE  style = g_style.style
    IF  status != 0 THEN
        RETURN FALSE
    END IF

    DECLARE c_ins CURSOR FOR
        INSERT INTO sku VALUES ( s_skulns.* )
        OPEN c_ins
        FOR idx = 1 TO s_maxidx
            LET s_skulns.ord_nbr = ssa_skulns1[idx].ord_nbr
            LET s_skulns.sku = ssa_skulns[idx].sku
            LET s_skulns.style = ssa_skulns1[idx].style
            LET s_skulns.colour = ssa_skulns[idx].colour
            LET s_skulns.sizes  = ssa_skulns[idx].sizes 
            LET s_skulns.unit_cost  = ssa_skulns1[idx].unit_cost 
            LET s_skulns.unit_sell  = ssa_skulns[idx].unit_sell 
            LET s_skulns.date_first_receipt  = ssa_skulns1[idx].date_first_receipt 
            LET s_skulns.sku_status  = ssa_skulns1[idx].sku_status
		 	PUT c_ins
            IF status != 0 THEN
                LET p_retstat = FALSE
				EXIT FOR
            END IF
        END FOR
        CLOSE c_ins
	RETURN p_retstat
END FUNCTION
################################################################################
#   sty_sku() update sku last selling price
################################################################################
FUNCTION sty_entL()
	DEFINE
			p_f10 					INTEGER,
			sidx 					INTEGER,
			p_status				INTEGER,
			p_text					CHAR(100),
			p_option				CHAR(80),
			p_retstat				INTEGER,
			idx						INTEGER,
			jdx						INTEGER,
			kdx						INTEGER,
			p_colour_name			LIKE colour.colour_name,
			p_colour				LIKE colour.colour,
			p_dummy					INTEGER

	OPEN WINDOW w_2 AT 9,5
    WITH FORM "styl_color"
	ATTRIBUTE(TEXT="Style Colour",STYLE="naked")
	#gxx <<


	LET s_arrsize =50 
	LET s_dspsize = 10
    LET s_maxidx = 0
    LET p_retstat = TRUE
	FOR idx = 1 TO s_arrsize
        INITIALIZE ssa_styclrlns[idx].* TO NULL
    END FOR
	INITIALIZE s_styclr.* TO NULL

	LET p_option = "OPTIONS: F1=ACCEPT F8=SEARCH F10=EXIT"
	#DISPLAY p_option AT 13,1
	#ATTRIBUTE(NORMAL,REVERSE)
	WHILE TRUE
		CALL SET_COUNT(s_maxidx)
		LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_styclrlns
    	WITHOUT DEFAULTS 
    	FROM sc_style_colour.*
		ATTRIBUTE(NORMAL)
		
			BEFORE ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
				LET s_maxidx = ARR_COUNT()

			AFTER ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()

    		AFTER DELETE
				MESSAGE ""
				LET kdx = ARR_COUNT() + 1
				INITIALIZE ssa_styclrlns[kdx].* TO NULL
				LET s_maxidx = s_maxidx - 1

			BEFORE INSERT
				LET s_maxidx = ARR_COUNT()

			AFTER INSERT
				LET s_maxidx = s_maxidx + 1

			AFTER FIELD colour
				IF ssa_styclrlns[idx].colour IS NOT NULL THEN
					SELECT	colour_name
					INTO	ssa_styclrlns[idx].colour_name
					FROM	colour
					WHERE	colour = ssa_styclrlns[idx].colour

					IF status = NOTFOUND THEN
						ERROR "invalid colour"
						NEXT FIELD colour
					END IF
					DISPLAY ssa_styclrlns[idx].colour
					TO sc_style_colour[sidx].colour
					ATTRIBUTE(NORMAL)
					DISPLAY ssa_styclrlns[idx].colour_name
					TO sc_style_colour[sidx].colour_name
					ATTRIBUTE(NORMAL)
{
				  	IF ssa_styclrlns[idx].colour = ssa_styclrlns[idx-1].colour
                    THEN
                      	LET p_text = "duplicate colour lines with "
                        ERROR "ERROR line ",idx USING "<&",
                                " ",p_text CLIPPED,
                                " line ",idx USING "<&"
						INITIALIZE ssa_styclrlns[idx].* TO NULL
						NEXT FIELD colour
					END IF
}
				END IF

			ON KEY(F8)
				CASE
                WHEN infield(colour)
                    CALL colour_lookup() RETURNING p_colour,p_colour_name
                    LET  ssa_styclrlns[idx].colour=p_colour
                    LET  ssa_styclrlns[idx].colour_name=p_colour_name
                    DISPLAY  ssa_styclrlns[idx].colour
                    TO sc_style_colour[sidx].colour
                    ATTRIBUTE(NORMAL)
                    DISPLAY ssa_styclrlns[idx].colour_name
                    TO sc_style_colour[sidx].colour_name
                    ATTRIBUTE(NORMAL)
                OTHERWISE
                    ERROR "no lookup for this field"
				END CASE

   	       ON KEY (F10)
				LET s_maxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			
			AFTER INPUT
				MESSAGE ""
				LET s_maxidx = ARR_COUNT()
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				FOR idx = 1 TO s_maxidx
					IF ssa_styclrlns[idx].colour IS NULL THEN
						LET p_text = " colour must be entered"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
					FOR jdx = 1 TO (idx-1)
				  		IF ssa_styclrlns[idx].colour = ssa_styclrlns[jdx].colour
                        THEN
                        	LET p_text = "duplicate colour lines with "
                            ERROR "ERROR line ",idx USING "<&",
                                " ",p_text CLIPPED,
                                " line ",jdx USING "<&"
                            LET p_retstat = FALSE
                            EXIT FOR
						END IF
					END FOR
					IF NOT p_retstat THEN
						EXIT FOR
					END IF
				END FOR			
				#gxx >>
			ON ACTION find
				CASE
                WHEN infield(colour)
                    CALL colour_lookup() RETURNING p_colour,p_colour_name
                    LET  ssa_styclrlns[idx].colour=p_colour
                    LET  ssa_styclrlns[idx].colour_name=p_colour_name
                    DISPLAY  ssa_styclrlns[idx].colour
                    TO sc_style_colour[sidx].colour
                    ATTRIBUTE(NORMAL)
                    DISPLAY ssa_styclrlns[idx].colour_name
                    TO sc_style_colour[sidx].colour_name
                    ATTRIBUTE(NORMAL)
                OTHERWISE
                    ERROR "no lookup for this field"
				END CASE

   	       ON ACTION exit
				LET s_maxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			END INPUT
	        IF p_retstat OR p_f10 THEN
	          	EXIT WHILE
	       	END IF
		END WHILE
		MESSAGE ""
		CLOSE WINDOW w_2
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sty_sku) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_entLA()
	DEFINE
			p_retstat				INTEGER,
			idx						INTEGER

	LET p_retstat = TRUE

    DECLARE c_ins1 CURSOR FOR
        INSERT INTO style_colour VALUES ( s_styclr.* )
        OPEN c_ins1
        FOR idx = 1 TO s_maxidx
			SELECT	*
			FROM	style_colour
			WHERE	style = g_style.style
			AND		colour = ssa_styclrlns[idx].colour

			IF status = NOTFOUND THEN
            	LET s_styclr.style = g_style.style
            	LET s_styclr.colour = ssa_styclrlns[idx].colour
		 		PUT c_ins1
            	IF status != 0 THEN
                	LET p_retstat = FALSE
					EXIT FOR
            	END IF
			END IF
        END FOR
        CLOSE c_ins1
	RETURN p_retstat
END FUNCTION
################################################################################
#   sty_sku() update sku last selling price
################################################################################
################################################################################
# @@@@@@@@@@@@@@@ (sty_entX) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_HK_sku()

	DEFINE
			p_f10 					INTEGER,
			sidx 					INTEGER,
			p_status				INTEGER,
			p_text					CHAR(100),
			p_option				CHAR(80),
			p_retstat				INTEGER,
			idx						INTEGER,
			jdx						INTEGER,
			p_colour_name			LIKE colour.colour_name,
			p_dummy					INTEGER


	OPEN WINDOW w_1 AT 9,5
    WITH FORM "sty_hksku"
	ATTRIBUTE(TEXT="Style SKu",STYLE="naked")

	OPTIONS
			DELETE KEY F20,
			INSERt KEY F30

	LET s_arrsize = 100
	LET s_dspsize = 10
    LET s_hkmaxidx = 0
    LET p_retstat = TRUE
	FOR idx = 1 TO s_arrsize
        INITIALIZE ssa_hkskulns[idx].* TO NULL
        INITIALIZE ssa_hkskulns1[idx].* TO NULL
    END FOR
	INITIALIZE s_hkskulns.* TO NULL

	DECLARE c_hksel1 CURSOR FOR 
		SELECT	a.*,size_pos
		FROM	seedhk:sku  a, sizes b
		WHERE	style = g_style.style
		AND		a.sizes = b.sizes
		ORDER	BY colour,size_pos

	LET idx = 1
	FOREACH c_hksel1 INTO s_hkskulns.* ,p_dummy
		LET ssa_hkskulns[idx].sku = s_hkskulns.sku
		LET ssa_hkskulns[idx].colour = s_hkskulns.colour

		LEt p_colour_name = NULL
		SELECT	colour_name
		INTO	p_colour_name  
		FROM	colour
		WHERE	colour = s_hkskulns.colour

		LET ssa_hkskulns[idx].colour_name = p_colour_name
		LET ssa_hkskulns[idx].sizes = s_hkskulns.sizes
		LET ssa_hkskulns[idx].unit_sell = s_hkskulns.unit_sell

		LET ssa_hkskulns1[idx].ord_nbr =  s_hkskulns.ord_nbr
		LET ssa_hkskulns1[idx].style =  s_hkskulns.style
		LET ssa_hkskulns1[idx].unit_cost =  g_style.unit_cost
		LET ssa_hkskulns1[idx].date_first_receipt =  s_hkskulns.date_first_receipt
		LET ssa_hkskulns1[idx].sku_status =  s_hkskulns.sku_status
		LET idx = idx + 1
	END FOREACH
	LET s_maxidx = idx - 1
	IF idx <= s_arrsize THEN
		INITIALIZE ssa_hkskulns[idx].* TO NULL
		INITIALIZE ssa_hkskulns1[idx].* TO NULL
		FOR jdx = idx TO s_arrsize
			LET ssa_hkskulns[jdx].* = ssa_hkskulns[idx].* 
			LET ssa_hkskulns1[jdx].* = ssa_hkskulns1[idx].* 
		END FOR
	END IF
	LET p_option = "OPTIONS: F1=ACCEPT F10=EXIT"
	DISPLAY p_option AT 13,1
	ATTRIBUTE(BLUE,REVERSE)
	WHILE TRUE
		CALL SET_COUNT(s_maxidx)
		LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_hkskulns
    	WITHOUT DEFAULTS 
    	FROM sc_hkskulns.*
		ATTRIBUTE(NORMAL)
		
			BEFORE ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
				LET s_hkmaxidx = ARR_COUNT()

			AFTER ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()

   	       ON KEY (F10)
				LET s_hkmaxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			
			AFTER INPUT
				MESSAGE ""
				LET s_hkmaxidx = ARR_COUNT()
				LET p_retstat = TRUE
				IF s_hkmaxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				FOR idx = 1 TO s_hkmaxidx
					IF ssa_hkskulns[idx].unit_sell IS NULL THEN
						LET p_text = " LSP must be entered"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
					IF ssa_hkskulns[idx].unit_sell = 0 THEN
						LET p_text = " LSP cannot equal to 0"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
				END FOR			
		   #gxx >>
   	       ON ACTION exit
				LET s_hkmaxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			#gxx <<
			END INPUT
	        IF p_retstat OR p_f10 THEN
	          	EXIT WHILE
	       	END IF
		END WHILE
		MESSAGE ""
		CLOSE WINDOW w_1
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sty_sku) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_ent1A()
	DEFINE
			p_retstat				INTEGER,
			idx						INTEGER

	LET p_retstat = TRUE
	DELETE FROM seedhk:sku
    WHERE  style = g_style.style
    IF  status != 0 THEN
        RETURN FALSE
    END IF

    DECLARE c_hkins CURSOR FOR
        INSERT INTO seedhk:sku VALUES ( s_hkskulns.* )
        OPEN c_hkins
        FOR idx = 1 TO s_hkmaxidx
            LET s_hkskulns.ord_nbr = ssa_hkskulns1[idx].ord_nbr
            LET s_hkskulns.sku = ssa_hkskulns[idx].sku
            LET s_hkskulns.style = ssa_hkskulns1[idx].style
            LET s_hkskulns.colour = ssa_hkskulns[idx].colour
            LET s_hkskulns.sizes  = ssa_hkskulns[idx].sizes 
            LET s_hkskulns.unit_cost  = ssa_hkskulns1[idx].unit_cost 
            LET s_hkskulns.unit_sell  = ssa_hkskulns[idx].unit_sell 
            LET s_hkskulns.date_first_receipt  = ssa_hkskulns1[idx].date_first_receipt 
            LET s_hkskulns.sku_status  = ssa_hkskulns1[idx].sku_status
		 	PUT c_hkins
            IF status != 0 THEN
                LET p_retstat = FALSE
				EXIT FOR
            END IF
        END FOR
        CLOSE c_hkins
	RETURN p_retstat
END FUNCTION
#R10 >>
FUNCTION sty_SIN_sku()

	DEFINE
			p_f10 					INTEGER,
			sidx 					INTEGER,
			p_status				INTEGER,
			p_text					CHAR(100),
			p_option				CHAR(80),
			p_retstat				INTEGER,
			idx						INTEGER,
			jdx						INTEGER,
			p_colour_name			LIKE colour.colour_name,
			p_dummy					INTEGER


	OPEN WINDOW w_1 AT 9,5
    WITH FORM "sty_sinsku"
	ATTRIBUTE(TEXT="Style SKu",STYLE="naked")

	OPTIONS
			DELETE KEY F20,
			INSERt KEY F30

	LET s_arrsize = 100
	LET s_dspsize = 10
    LET s_sinmaxidx = 0
    LET p_retstat = TRUE
	FOR idx = 1 TO s_arrsize
        INITIALIZE ssa_sinskulns[idx].* TO NULL
        INITIALIZE ssa_sinskulns1[idx].* TO NULL
    END FOR
	INITIALIZE s_sinskulns.* TO NULL

	DECLARE c_sinsel1 CURSOR FOR 
		SELECT	a.*,size_pos
		FROM	seedsin:sku  a, sizes b
		WHERE	style = g_style.style
		AND		a.sizes = b.sizes
		ORDER	BY colour,size_pos

	LET idx = 1
	FOREACH c_sinsel1 INTO s_sinskulns.* ,p_dummy
		LET ssa_sinskulns[idx].sku = s_sinskulns.sku
		LET ssa_sinskulns[idx].colour = s_sinskulns.colour

		LEt p_colour_name = NULL
		SELECT	colour_name
		INTO	p_colour_name  
		FROM	colour
		WHERE	colour = s_sinskulns.colour

		LET ssa_sinskulns[idx].colour_name = p_colour_name
		LET ssa_sinskulns[idx].sizes = s_sinskulns.sizes
		LET ssa_sinskulns[idx].unit_sell = s_sinskulns.unit_sell

		LET ssa_sinskulns1[idx].ord_nbr =  s_sinskulns.ord_nbr
		LET ssa_sinskulns1[idx].style =  s_sinskulns.style
		LET ssa_sinskulns1[idx].unit_cost =  g_style.unit_cost
		LET ssa_sinskulns1[idx].date_first_receipt =  s_sinskulns.date_first_receipt
		LET ssa_sinskulns1[idx].sku_status =  s_sinskulns.sku_status
		LET idx = idx + 1
	END FOREACH
	LET s_maxidx = idx - 1
	IF idx <= s_arrsize THEN
		INITIALIZE ssa_sinskulns[idx].* TO NULL
		INITIALIZE ssa_sinskulns1[idx].* TO NULL
		FOR jdx = idx TO s_arrsize
			LET ssa_sinskulns[jdx].* = ssa_sinskulns[idx].* 
			LET ssa_sinskulns1[jdx].* = ssa_sinskulns1[idx].* 
		END FOR
	END IF
	LET p_option = "OPTIONS: F1=ACCEPT F10=EXIT"
	DISPLAY p_option AT 13,1
	ATTRIBUTE(BLUE,REVERSE)
	WHILE TRUE
		CALL SET_COUNT(s_maxidx)
		LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_sinskulns
    	WITHOUT DEFAULTS 
    	FROM sc_sinskulns.*
		ATTRIBUTE(NORMAL)
		
			BEFORE ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
				LET s_sinmaxidx = ARR_COUNT()

			AFTER ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()

   	       ON KEY (F10)
				LET s_sinmaxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			
			AFTER INPUT
				MESSAGE ""
				LET s_sinmaxidx = ARR_COUNT()
				LET p_retstat = TRUE
				IF s_sinmaxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				FOR idx = 1 TO s_sinmaxidx
					IF ssa_sinskulns[idx].unit_sell IS NULL THEN
						LET p_text = " LSP must be entered"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
					IF ssa_sinskulns[idx].unit_sell = 0 THEN
						LET p_text = " LSP cannot equal to 0"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
				END FOR			
		   #gxx >>
   	       ON ACTION exit
				LET s_sinmaxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			#gxx <<
			END INPUT
	        IF p_retstat OR p_f10 THEN
	          	EXIT WHILE
	       	END IF
		END WHILE
		MESSAGE ""
		CLOSE WINDOW w_1
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sty_sku) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_ent2A()
	DEFINE
			p_retstat				INTEGER,
			idx						INTEGER

	LET p_retstat = TRUE
	DELETE FROM seedsin:sku
    WHERE  style = g_style.style
    IF  status != 0 THEN
        RETURN FALSE
    END IF

    DECLARE c_sinins CURSOR FOR
        INSERT INTO seedsin:sku VALUES ( s_sinskulns.* )
        OPEN c_sinins
        FOR idx = 1 TO s_sinmaxidx
            LET s_sinskulns.ord_nbr = ssa_sinskulns1[idx].ord_nbr
            LET s_sinskulns.sku = ssa_sinskulns[idx].sku
            LET s_sinskulns.style = ssa_sinskulns1[idx].style
            LET s_sinskulns.colour = ssa_sinskulns[idx].colour
            LET s_sinskulns.sizes  = ssa_sinskulns[idx].sizes 
            LET s_sinskulns.unit_cost  = ssa_sinskulns1[idx].unit_cost 
            LET s_sinskulns.unit_sell  = ssa_sinskulns[idx].unit_sell 
            LET s_sinskulns.date_first_receipt  = ssa_sinskulns1[idx].date_first_receipt 
            LET s_sinskulns.sku_status  = ssa_sinskulns1[idx].sku_status
		 	PUT c_sinins
            IF status != 0 THEN
                LET p_retstat = FALSE
				EXIT FOR
            END IF
        END FOR
        CLOSE c_sinins
	RETURN p_retstat
END FUNCTION
#R10 <<
#R11 >>
FUNCTION sty_NZ_sku()

	DEFINE
			p_f10 					INTEGER,
			sidx 					INTEGER,
			p_status				INTEGER,
			p_text					CHAR(100),
			p_option				CHAR(80),
			p_retstat				INTEGER,
			idx						INTEGER,
			jdx						INTEGER,
			p_colour_name			LIKE colour.colour_name,
			p_dummy					INTEGER


	OPEN WINDOW w_1 AT 9,5
    WITH FORM "sty_nzsku"
	ATTRIBUTE(TEXT="Style SKu",STYLE="naked")

	OPTIONS
			DELETE KEY F20,
			INSERt KEY F30

	LET s_arrsize = 100
	LET s_dspsize = 10
    LET s_nzmaxidx = 0
    LET p_retstat = TRUE
	FOR idx = 1 TO s_arrsize
        INITIALIZE ssa_nzskulns[idx].* TO NULL
        INITIALIZE ssa_nzskulns1[idx].* TO NULL
    END FOR
	INITIALIZE s_nzskulns.* TO NULL

	DECLARE c_nzsel1 CURSOR FOR 
		SELECT	a.*,size_pos
		FROM	seednz:sku  a, sizes b
		WHERE	style = g_style.style
		AND		a.sizes = b.sizes
		ORDER	BY colour,size_pos

	LET idx = 1
	FOREACH c_nzsel1 INTO s_nzskulns.* ,p_dummy
		LET ssa_nzskulns[idx].sku = s_nzskulns.sku
		LET ssa_nzskulns[idx].colour = s_nzskulns.colour

		LEt p_colour_name = NULL
		SELECT	colour_name
		INTO	p_colour_name  
		FROM	colour
		WHERE	colour = s_nzskulns.colour

		LET ssa_nzskulns[idx].colour_name = p_colour_name
		LET ssa_nzskulns[idx].sizes = s_nzskulns.sizes
		LET ssa_nzskulns[idx].unit_sell = s_nzskulns.unit_sell

		LET ssa_nzskulns1[idx].ord_nbr =  s_nzskulns.ord_nbr
		LET ssa_nzskulns1[idx].style =  s_nzskulns.style
		LET ssa_nzskulns1[idx].unit_cost =  g_style.unit_cost
		LET ssa_nzskulns1[idx].date_first_receipt =  s_nzskulns.date_first_receipt
		LET ssa_nzskulns1[idx].sku_status =  s_nzskulns.sku_status
		LET idx = idx + 1
	END FOREACH
	LET s_maxidx = idx - 1
	IF idx <= s_arrsize THEN
		INITIALIZE ssa_nzskulns[idx].* TO NULL
		INITIALIZE ssa_nzskulns1[idx].* TO NULL
		FOR jdx = idx TO s_arrsize
			LET ssa_nzskulns[jdx].* = ssa_nzskulns[idx].* 
			LET ssa_nzskulns1[jdx].* = ssa_nzskulns1[idx].* 
		END FOR
	END IF
	LET p_option = "OPTIONS: F1=ACCEPT F10=EXIT"
	DISPLAY p_option AT 13,1
	ATTRIBUTE(BLUE,REVERSE)
	WHILE TRUE
		CALL SET_COUNT(s_maxidx)
		LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_nzskulns
    	WITHOUT DEFAULTS 
    	FROM sc_nzskulns.*
		ATTRIBUTE(NORMAL)
		
			BEFORE ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
				LET s_nzmaxidx = ARR_COUNT()

			AFTER ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()

   	       ON KEY (F10)
				LET s_nzmaxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			
			AFTER INPUT
				MESSAGE ""
				LET s_nzmaxidx = ARR_COUNT()
				LET p_retstat = TRUE
				IF s_nzmaxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				FOR idx = 1 TO s_nzmaxidx
					IF ssa_nzskulns[idx].unit_sell IS NULL THEN
						LET p_text = " LSP must be entered"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
					IF ssa_nzskulns[idx].unit_sell = 0 THEN
						LET p_text = " LSP cannot equal to 0"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
				END FOR			
		   #gxx >>
   	       ON ACTION exit
				LET s_nzmaxidx= ARR_COUNT()
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT INPUT
			#gxx <<
			END INPUT
	        IF p_retstat OR p_f10 THEN
	          	EXIT WHILE
	       	END IF
		END WHILE
		MESSAGE ""
		CLOSE WINDOW w_1
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sty_sku) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_ent3A()
	DEFINE
			p_retstat				INTEGER,
			idx						INTEGER

	LET p_retstat = TRUE
	DELETE FROM seednz:sku
    WHERE  style = g_style.style
    IF  status != 0 THEN
        RETURN FALSE
    END IF

    DECLARE c_nzins CURSOR FOR
        INSERT INTO seednz:sku VALUES ( s_nzskulns.* )
        OPEN c_nzins
        FOR idx = 1 TO s_nzmaxidx
            LET s_nzskulns.ord_nbr = ssa_nzskulns1[idx].ord_nbr
            LET s_nzskulns.sku = ssa_nzskulns[idx].sku
            LET s_nzskulns.style = ssa_nzskulns1[idx].style
            LET s_nzskulns.colour = ssa_nzskulns[idx].colour
            LET s_nzskulns.sizes  = ssa_nzskulns[idx].sizes 
            LET s_nzskulns.unit_cost  = ssa_nzskulns1[idx].unit_cost 
            LET s_nzskulns.unit_sell  = ssa_nzskulns[idx].unit_sell 
            LET s_nzskulns.date_first_receipt  = ssa_nzskulns1[idx].date_first_receipt 
            LET s_nzskulns.sku_status  = ssa_nzskulns1[idx].sku_status
		 	PUT c_nzins
            IF status != 0 THEN
                LET p_retstat = FALSE
				EXIT FOR
            END IF
        END FOR
        CLOSE c_nzins
	RETURN p_retstat
END FUNCTION
#R11 <<
FUNCTION country_query()
    DEFINE where_part 			CHAR(200),
			p_exit				INTEGER,
           query_text 			CHAR(250),
		   country_cnt, idx 		SMALLINT,
			p_country_name		LIKE ax_country.country_name,
		    p_acountry DYNAMIC ARRAY OF RECORD
				country 			LIKE ax_country.country,
				country_name 	LIKE ax_country.country_name
				END RECORD

    OPEN WINDOW country_win AT 10,20
        WITH FORM "country_qry"
		ATTRIBUTE(TEXT="COUNTRY",STYLE="printer")				

	DISPLAY "Enter criteria for selection" AT 1,1 ATTRIBUTE(DIM)
    INPUT BY NAME p_country_name
	ATTRIBUTE(WITHOUT DEFAULTS = TRUE)

		ON ACTION exit
			LET p_exit = TRUE
			EXIT INPUT

		#ON ACTION accept
			#EXIT INPUT
		AFTER FIELD p_country_name
			LET p_exit = FALSE
			EXIT INPUT
	END INPUT

	IF p_exit THEN
##    	CLOSE WINDOW w_country
    	CLOSE WINDOW country_win
		RETURN "",""
	END IF

    LET query_text = "select * from ax_country ",
					 "Where UPPER(country_name) MATCHES ","'*",p_country_name CLIPPED,"*'",
					 " order by 1"

##display query_text

    PREPARE country_st FROM query_text

    DECLARE c_country CURSOR FOR country_st
	LET country_cnt = 1
	FOREACH c_country INTO p_acountry[country_cnt].*
		LET country_cnt = country_cnt + 1
		##IF country_cnt > 50 THEN
			##EXIT FOREACH
		##END IF
	END FOREACH
	LET country_cnt = country_cnt - 1  

	LET idx = 1  
	IF country_cnt < 1 THEN
    	CLOSE WINDOW country_win
		INITIALIZE p_acountry[idx].* TO NULL
		ERROR "No selection satifies criteria" 
											ATTRIBUTE(RED, REVERSE)
		RETURN p_acountry[idx].country, p_acountry[idx].country_name
	END IF

    OPEN WINDOW w_country AT 12,15
        WITH FORM "country_li" ATTRIBUTES (STYLE="naked")
		CALL set_count(country_cnt)
		DISPLAY ARRAY p_acountry TO sc_country_li.* 
		ATTRIBUTE(UNDERLINE)
			ON ACTION exit
				EXIT DISPLAY
			AFTER DISPLAY
				LET idx = ARR_CURR()
            	EXIT DISPLAY
		END DISPLAY

    CLOSE WINDOW w_country
    CLOSE WINDOW country_win
	RETURN p_acountry[idx].country, p_acountry[idx].country_name
END FUNCTION
FUNCTION customs_query()
    DEFINE where_part 			CHAR(200),
			p_exit				INTEGER,
           query_text 			CHAR(250),
		   customs_cnt, idx 		SMALLINT,
			p_customs_desc		LIKE ax_customs.customs_desc,
		    p_acustoms DYNAMIC ARRAY OF RECORD
				customs 			LIKE ax_customs.customs,
				customs_desc 	LIKE ax_customs.customs_desc
				END RECORD

    OPEN WINDOW customs_win AT 10,20
        WITH FORM "customs_qry"
		ATTRIBUTE(TEXT="CLASSIFICATION",STYLE="printer")				
		#ATTRIBUTE(BORDER, DIM, FORM LINE FIRST)

	DISPLAY "Enter criteria for selection" AT 1,1 ATTRIBUTE(DIM)
    INPUT BY NAME p_customs_desc
	ATTRIBUTE(WITHOUT DEFAULTS = TRUE)

		ON ACTION exit
			LET p_exit = TRUE
			EXIT INPUT

		##ON ACTION accept
    	AFTER FIELD p_customs_desc
			LET p_exit = FALSE
			EXIT INPUT
	END INPUT

	IF p_exit THEN
    	##CLOSE WINDOW w_customs
    	CLOSE WINDOW customs_win
		RETURN "",""
	END IF
    LET query_text = "select * from ax_customs ",
					 "Where UPPER(customs_desc) MATCHES ","'*",p_customs_desc CLIPPED,"*'",
					 " order by 1"

##display query_text

    PREPARE customs_st FROM query_text

    DECLARE c_customs CURSOR FOR customs_st
	LET customs_cnt = 1
	FOREACH c_customs INTO p_acustoms[customs_cnt].*
		LET customs_cnt = customs_cnt + 1
		##IF customs_cnt > 50 THEN
			##EXIT FOREACH
		##END IF
	END FOREACH
	LET customs_cnt = customs_cnt - 1  

	LET idx = 1  
	IF customs_cnt < 1 THEN
    	CLOSE WINDOW customs_win
		INITIALIZE p_acustoms[idx].* TO NULL
		ERROR "No selection satifies criteria" 
											ATTRIBUTE(RED, REVERSE)
		RETURN p_acustoms[idx].customs, p_acustoms[idx].customs_desc
	END IF

    OPEN WINDOW w_customs AT 12,15
        WITH FORM "customs_li" ATTRIBUTES (STYLE="naked")
		CALL set_count(customs_cnt)
		DISPLAY ARRAY p_acustoms TO sc_customs_li.* 
		ATTRIBUTE(UNDERLINE)
			ON ACTION exit
				EXIT DISPLAY
			AFTER DISPLAY
				LET idx = ARR_CURR()
            	EXIT DISPLAY
		END DISPLAY

    CLOSE WINDOW w_customs
    CLOSE WINDOW customs_win
	RETURN p_acustoms[idx].customs, p_acustoms[idx].customs_desc
END FUNCTION
#R15 >>
################################################################################
# check_numb - validate entered numbers                                        #
################################################################################
FUNCTION check_numb(p_string)
    DEFINE  p_string            CHAR(40),
            p_retstat           INTEGER

    LET p_string = p_string CLIPPED
    LET p_retstat = gp_isnum(p_string)
    RETURN p_retstat
END FUNCTION    
################################################################################
# @@@@@@@@@@@@@@@@@ check_numb @@@@@@@@@@@@@@@@@@                              #
################################################################################
FUNCTION cons_query()
    DEFINE where_part CHAR(200),
           query_text CHAR(300),
		   supplier_cnt, idx INTEGER,
		   p_cons DYNAMIC ARRAY OF RECORD
				cons			CHAR(30)
		END RECORD

	LET p_cons[1].cons = "KNIT"
	LET p_cons[2].cons = "WOVEN"
	LET p_cons[3].cons = "NOT APPLICABLE"

    OPEN WINDOW w_cons AT 12,10
        WITH FORM "cons_li" ATTRIBUTES (STYLE="naked")

		CALL set_count(3)

		DISPLAY ARRAY p_cons TO sc_cons.* ATTRIBUTE(NORMAL)
        	ON ACTION exit
            	LET int_flag = TRUE
            	EXIT DISPLAY

        	ON ACTION accept
            	LET idx = arr_curr()
            	LET int_flag = FALSE
            	EXIT DISPLAY
    	END DISPLAY
	#IF int_flag THEN
		#LET int_flag = FALSE
	#END IF

    CLOSE WINDOW w_cons

	IF int_flag THEN                                #Gxx
        RETURN NULL
    ELSE
#display "return: ",idx
		RETURN p_cons[idx].cons
	END IF
END FUNCTION
FUNCTION fabric_content_query()
    DEFINE where_part 			CHAR(200),
			p_exit				INTEGER,
           query_text 			CHAR(250),
		   fabric_cnt, idx 		SMALLINT,
			p_fabric_desc		LIKE ax_fabric_content.fabric_desc,
		    p_afabric DYNAMIC ARRAY OF RECORD
				fabric 			LIKE ax_fabric_content.fabric,
				fabric_desc 	LIKE ax_fabric_content.fabric_desc
				END RECORD

    OPEN WINDOW fabric_win AT 10,20
        WITH FORM "fabric_qry"
		ATTRIBUTE(TEXT="CLASSIFICATION",STYLE="printer")				

	DISPLAY "Enter criteria for selection" AT 1,1 ATTRIBUTE(DIM)
    INPUT BY NAME p_fabric_desc
	ATTRIBUTE(WITHOUT DEFAULTS = TRUE)

		ON ACTION exit
			LET p_exit = TRUE
			EXIT INPUT

    	AFTER FIELD p_fabric_desc
			LET p_exit = FALSE
			EXIT INPUT
	END INPUT

	IF p_exit THEN
    	CLOSE WINDOW fabric_win
		RETURN "",""
	END IF
    LET query_text = "select * from ax_fabric_content ",
					 "Where UPPER(fabric_desc) MATCHES ","'*",p_fabric_desc CLIPPED,"*'",
					 " order by 1"

##display query_text

    PREPARE fabric_st FROM query_text

    DECLARE c_fabric CURSOR FOR fabric_st
	LET fabric_cnt = 1
	FOREACH c_fabric INTO p_afabric[fabric_cnt].*
		LET fabric_cnt = fabric_cnt + 1
		##IF fabric_cnt > 50 THEN
			##EXIT FOREACH
		##END IF
	END FOREACH
	LET fabric_cnt = fabric_cnt - 1  

	LET idx = 1  
	IF fabric_cnt < 1 THEN
    	CLOSE WINDOW fabric_win
		INITIALIZE p_afabric[idx].* TO NULL
		ERROR "No selection satifies criteria" 
											ATTRIBUTE(RED, REVERSE)
		RETURN p_afabric[idx].fabric, p_afabric[idx].fabric_desc
	END IF

    OPEN WINDOW w_fabric AT 12,15
        WITH FORM "fabric_li" ATTRIBUTES (STYLE="naked")
		CALL set_count(fabric_cnt)
		DISPLAY ARRAY p_afabric TO sc_fabric_li.* 
		ATTRIBUTE(UNDERLINE)
			ON ACTION exit
				EXIT DISPLAY
			AFTER DISPLAY
				LET idx = ARR_CURR()
            	EXIT DISPLAY
		END DISPLAY

    CLOSE WINDOW w_fabric
    CLOSE WINDOW fabric_win
	RETURN p_afabric[idx].fabric, p_afabric[idx].fabric_desc
END FUNCTION
FUNCTION size_query()
    DEFINE where_part 			CHAR(200),
			p_exit				INTEGER,
           query_text 			CHAR(250),
		   size_cnt, idx 		SMALLINT,
			p_size_desc			LIKE sty_sizehdr.size_desc,
		    p_asize DYNAMIC ARRAY OF RECORD
				size 			LIKE sty_sizehdr.size_code,
				size_desc 		LIKE sty_sizehdr.size_desc
				END RECORD

    OPEN WINDOW size_win AT 10,20
        WITH FORM "size_qry"
		ATTRIBUTE(TEXT="CLASSIFICATION",STYLE="printer")				

	DISPLAY "Enter criteria for selection" AT 1,1 ATTRIBUTE(DIM)
    INPUT BY NAME p_size_desc
	ATTRIBUTE(WITHOUT DEFAULTS = TRUE)

		ON ACTION exit
			LET p_exit = TRUE
			EXIT INPUT

    	AFTER FIELD p_size_desc
			LET p_exit = FALSE
			EXIT INPUT
	END INPUT

	IF p_exit THEN
    	CLOSE WINDOW size_win
		RETURN "",""
	END IF
    LET query_text = "select * from sty_sizehdr ",
					 "Where UPPER(size_desc) MATCHES ","'*",p_size_desc CLIPPED,"*'",
					 " order by 1"

##display query_text

    PREPARE size_st FROM query_text

    DECLARE c_size CURSOR FOR size_st
	LET size_cnt = 1
	FOREACH c_size INTO p_asize[size_cnt].*
		LET size_cnt = size_cnt + 1
	END FOREACH
	LET size_cnt = size_cnt - 1  

	LET idx = 1  
	IF size_cnt < 1 THEN
    	CLOSE WINDOW size_win
		INITIALIZE p_asize[idx].* TO NULL
		ERROR "No selection satifies criteria" 
											ATTRIBUTE(RED, REVERSE)
		RETURN p_asize[idx].size, p_asize[idx].size_desc
	END IF

    OPEN WINDOW w_size AT 12,15
        WITH FORM "size_li" ATTRIBUTES (STYLE="naked")
		CALL set_count(size_cnt)
		DISPLAY ARRAY p_asize TO sc_size_li.* 
		ATTRIBUTE(UNDERLINE)
			ON ACTION exit
				EXIT DISPLAY
			AFTER DISPLAY
				LET idx = ARR_CURR()
            	EXIT DISPLAY
		END DISPLAY

    CLOSE WINDOW w_size
    CLOSE WINDOW size_win
	RETURN p_asize[idx].size, p_asize[idx].size_desc
END FUNCTION
