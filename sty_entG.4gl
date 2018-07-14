################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entG - STyle Maintenance program           #
#								rewrite from style.4gl                         #
#  																			   #
# 	R00	02aug01	td				initial release						           #
# 	R01	13jul04	td				add cost_lchg_date,ledger_cost                 #
# 	R02	21jun09	td		  Mod. Campaign - Copy style to SeedHK                 #
#   R03 06Jul12 tn        Mod. To add Fob fields and story into
#   R04 22sep14 td        Mod. To introduce SIN & NZ companies
#   R05 08aug15 td        Mod. To introduce division
#   R06 17jan16 td        Mod. To introduce fabric description
#	R07	25may18 td		  		Add video url page							   #
################################################################################
DATABASE seed

GLOBALS
CONSTANT IMAGE_FILE_DESTINATION = "/file_storage/brandbank_tmp/shau/reports/" #R03 -- change this if required
TYPE TYPE_IMAGE  RECORD
	line_no 			INT,
	style 				LIKE style.style,
	colour 				LIKE colour.colour,
	au_publish 			LIKE style_colour.publish,
	au_hero_image 		LIKE style_colour.hero_image,
	nz_publish 			LIKE style_colour.publish,
	nz_hero_image 		LIKE style_colour.hero_image,
	hk_publish 			LIKE style_colour.publish,
	hk_hero_image 		LIKE style_colour.hero_image,
	sg_publish 			LIKE style_colour.publish,
	sg_hero_image 		LIKE style_colour.hero_image,
	dw_au_hero_image 	LIKE style_colour.dw_auhero_img ,
	dw_nz_hero_image 	LIKE style_colour.dw_auhero_img ,
	dw_hk_hero_image 	LIKE style_colour.dw_auhero_img ,
	dw_sg_hero_image 	LIKE style_colour.dw_auhero_img ,
	au_image1 			LIKE style_colour.dwilabel1,
	au_image2 			LIKE style_colour.dwilabel1,
	au_image3 			LIKE style_colour.dwilabel1,
	au_image4 			LIKE style_colour.dwilabel1,
	au_image5 			LIKE style_colour.dwilabel1,
	hk_image1 			LIKE style_colour.dwilabel1,
	hk_image2 			LIKE style_colour.dwilabel1,
	hk_image3 			LIKE style_colour.dwilabel1,
	hk_image4 			LIKE style_colour.dwilabel1,
	hk_image5 			LIKE style_colour.dwilabel1,
	sg_image1 			LIKE style_colour.dwilabel1,
	sg_image2 			LIKE style_colour.dwilabel1,
	sg_image3 			LIKE style_colour.dwilabel1,
	sg_image4 			LIKE style_colour.dwilabel1,
	sg_image5 			LIKE style_colour.dwilabel1
END RECORD
TYPE TYPE_IMAGE_RECORD  RECORD
	style 				STRING,
	colour 				STRING,
	au_publish 			STRING,
	au_hero_image 		STRING,
	nz_publish 			STRING,
	nz_hero_image 		STRING,
	hk_publish 			STRING,
	hk_hero_image 		STRING,
	sg_publish 			STRING,
	sg_hero_image 		STRING,
	dw_au_hero_image 	STRING,
	dw_nz_hero_image 	STRING,
	dw_hk_hero_image 	STRING,
	dw_sg_hero_image 	STRING,
	au_image1 			STRING,
	au_image2 			STRING,
	au_image3 			STRING,
	au_image4 			STRING,
	au_image5 			STRING,
	hk_image1 			STRING,
	hk_image2 			STRING,
	hk_image3 			STRING,
	hk_image4 			STRING,
	hk_image5 			STRING,
	sg_image1 			STRING,
	sg_image2 			STRING,
	sg_image3 			STRING,
	sg_image4 			STRING,
	sg_image5 			STRING
END RECORD
#rxx <<
	DEFINE
		g_image_upload				STRING,
		g_error_string		   		STRING,					#rxx
		g_video						INTEGER,			#R07

		g_prev_unit_sell,
		g_prev_hk_unit_sell,
		g_prev_sg_unit_sell,
		g_prev_nz_unit_sell			DECIMAL(10,2),			#rxx
		g_image						INTEGER,				#R03
		g_path						CHAR(100),				#R03
		g_web_desc1					CHAR(2000),				#R03
		g_web_desc2					CHAR(100),				#R03
		g_web_desc3					CHAR(100),				#R01
		g_copy					    CHAR(3),
		#R02 >>
		#Hongkong
		g_hk_pos_del_flg			LIKE style.pos_del_flg,			#R05
		g_hk_style_desc				LIKE style.style_desc,
		g_hk_story_desc				LIKE story.story_desc,  #R03
		g_hk_story  				LIKE style.story,  		#R03
        g_hk_fob_cost 				DECIMAL(11,2),          #R03
		g_hk_short_desc				LIKE style.short_desc,
		g_hk_sup_sty				LIKE style.sup_sty,
		g_hk_supplier				LIKE style.supplier,
		g_hk_season					LIKE style.season,
		g_hk_division				LIKE style.season,			#R05
		g_hk_class					LIKE style.class,
		g_hk_category				LIKE style.category,
		g_hk_unit_cost				DECIMAL(8,2),
		g_hk_unit_sell				DECIMAL(8,2),
		g_hk_orig_sell				DECIMAL(8,2),
		g_hk_lchg_dte				LIKE style.lchg_dte,
		g_hk_gst_perc				LIKE style.gst_perc,
    	g_hk_fob_method 			char(15),               #R03
    	g_hk_fob 					char(15),               #R03
		#R02 <<
		g_printer					INTEGER,	#gxx
		g_cost_last_change          INTEGER,     #R01
		g_hk_cost_last_change       INTEGER,     #R02
		g_user						CHAR(20),
		g_opt						CHAR(10),
		g_hkopt						CHAR(10),				#R02
		g_first_recv				DATE,
		g_hk_first_recv				DATE,						#R02
  		g_pr        				RECORD LIKE queprt.*,
		g_style						RECORD LIKE style.*,
		g_style_webcat				RECORD LIKE style_webcat.*,		#R05
		g_hk_style					LIKE style.style,
		g_hkstyle					RECORD 
    		style char(9) ,
    		style_desc char(30),
    		short_desc char(20),
    		supplier integer,
    		sup_sty char(15),
    		season char(1) ,
    		#R04 division smallint ,
    		section smallint ,				#R04
    		class smallint,
    		category smallint ,
    		price_point smallint,
    		fabric_type smallint,
    		style_type smallint,
    		orig_sell money(8,2),
    		prev_sell money(8,2),
    		unit_cost money(8,2),
    		unit_sell money(8,2),
    		story smallint,
    		lchg_dte date,
    		del_flg char(1),
    		pos_del_flg char(1),
    		page char(20),
    		month integer,
    		catalogue char(1),
    		gst_perc decimal(4,2),
    		who char(20),
    		lockdtime datetime year to fraction(3),
    		cost_lchg_date date,
    		ledger_cost decimal(7,2),
    		date_insert date,
    		country_of_origin char(40),
    		fabric_content char(40),
    		classification char(30),
    		garment_cons char(30),
    		garment_dept char(20),
    		fob_method char(15),
    		fob char(15),
    		fob_cost decimal(11,2),
    		web_care char(80),
    		supplier_cost decimal(8,2)
				END RECORD,
    	g_hk_web_style_desc 				char(80),
    	g_hk_page 							char(80),
    	g_hk_web_care 						char(80),
    	g_hk_country_of_origin 				char(40),
    	g_hk_fabric_content 				char(40),
    	g_hk_fabric_desc					LIKE style.fabric_desc,			#R06
    	g_hk_classification 				char(30),
    	g_hk_garment_cons 					char(30),
    	g_hk_garment_dept 					char(20),
		#R04 >>
		#singapore
		g_sin_style					LIKE style.style,
    	g_sin_page 							char(80),
    	g_sin_web_style_desc 				char(80),
    	g_sin_web_care 						char(80),
    	g_sin_country_of_origin 			char(40),
    	g_sin_fabric_content 				char(40),
    	g_sin_fabric_desc					LIKE style.fabric_desc,			#R06
    	g_sin_classification 				char(30),
    	g_sin_garment_cons 					char(30),
    	g_sin_garment_dept 					char(20),
		g_sin_style_desc				LIKE style.style_desc,
		g_sin_story_desc				LIKE story.story_desc,  
		g_sin_story  					LIKE style.story,  		
        g_sin_fob_cost 					DECIMAL(11,2),         
		g_sin_short_desc				LIKE style.short_desc,
		g_sin_sup_sty					LIKE style.sup_sty,
		g_sin_supplier					LIKE style.supplier,
		g_sin_season					LIKE style.season,
		g_sin_division					LIKE style.season,			#R05
		g_sin_class						LIKE style.class,
		g_sin_category					LIKE style.category,
		g_sin_unit_cost					DECIMAL(8,2),
		g_sin_unit_sell					DECIMAL(8,2),
		g_sin_orig_sell					DECIMAL(8,2),
		g_sin_lchg_dte					LIKE style.lchg_dte,
		g_sin_gst_perc					LIKE style.gst_perc,
    	g_sin_fob_method 				CHAR(15),              
    	g_sin_fob 						CHAR(15), 
		g_sin_cost_last_change 		    INTEGER,     
		g_sinopt						CHAR(10),				
		g_sin_first_recv				DATE,						
		g_sinstyle					RECORD 
    		style 						CHAR(9) ,
    		style_desc 					CHAR(30),
    		short_desc 					CHAR(20),
    		supplier 					INTEGER,
    		sup_sty 					CHAR(15),
    		season 						CHAR(1) ,
    		#R04 division smallint ,
    		section 					SMALLINT ,				#R04
    		class 						SMALLINT,
    		category 					SMALLINT ,
    		price_point 				SMALLINT,
    		fabric_type 				SMALLINT,
    		style_type 					SMALLINT,
    		orig_sell 					MONEY(8,2),
    		prev_sell 					MONEY(8,2),
    		unit_cost 					MONEY(8,2),
    		unit_sell 					MONEY(8,2),
    		story 						SMALLINT,
    		lchg_dte 					DATE,
    		del_flg 					CHAR(1),
    		pos_del_flg 				CHAR(1),
    		page 						CHAR(20),
    		month 						INTEGER,
    		catalogue 					CHAR(1),
    		gst_perc 					DECIMAL(4,2),
    		who 						CHAR(20),
    		lockdtime 					DATETIME YEAR TO FRACTION(3),
    		cost_lchg_date 				DATE,
    		ledger_cost 				DECIMAL(7,2),
    		date_insert 				DATE,
    		country_of_origin 			CHAR(40),
    		fabric_content 				CHAR(40),
    		classification 				CHAR(30),
    		garment_cons 				CHAR(30),
    		garment_dept 				CHAR(20),
    		fob_method 					CHAR(15),
    		fob 						CHAR(15),
    		fob_cost 					DECIMAL(11,2),
    		web_care 					CHAR(80),
    		supplier_cost 				DECIMAL(8,2)
				END RECORD,
		#NZ
		g_nz_style						LIKE style.style,
    	g_nz_page 						char(80),
    	g_nz_web_style_desc 			char(80),
    	g_nz_web_care 					char(80),
    	g_nz_country_of_origin 			char(40),
    	g_nz_fabric_content 			char(40),
    	g_nz_fabric_desc				LIKE style.fabric_desc,			#R06
    	g_nz_classification 			char(30),
    	g_nz_garment_cons 				char(30),
    	g_nz_garment_dept 				char(20),
		g_nz_style_desc					LIKE style.style_desc,
		g_nz_story_desc					LIKE story.story_desc,  
		g_nz_story  					LIKE style.story,  		
        g_nz_fob_cost 					DECIMAL(11,2),         
		g_nz_short_desc					LIKE style.short_desc,
		g_nz_sup_sty					LIKE style.sup_sty,
		g_nz_supplier					LIKE style.supplier,
		g_nz_season						LIKE style.season,
		g_nz_division					LIKE style.season,			#R05
		g_nz_class						LIKE style.class,
		g_nz_category					LIKE style.category,
		g_nz_unit_cost					DECIMAL(8,2),
		g_nz_unit_sell					DECIMAL(8,2),
		g_nz_orig_sell					DECIMAL(8,2),
		g_nz_lchg_dte					LIKE style.lchg_dte,
		g_nz_gst_perc					LIKE style.gst_perc,
    	g_nz_fob_method 				CHAR(15),              
    	g_nz_fob 						CHAR(15), 
		g_nz_cost_last_change 		    INTEGER,     
		g_nzopt							CHAR(10),				
		g_nz_first_recv					DATE,						
		g_nzstyle		RECORD 
    		style 						CHAR(9) ,
    		style_desc 					CHAR(30),
    		short_desc 					CHAR(20),
    		supplier 					INTEGER,
    		sup_sty 					CHAR(15),
    		season 						CHAR(1) ,
    		section 					SMALLINT ,				#R04
    		class 						SMALLINT,
    		category 					SMALLINT ,
    		price_point 				SMALLINT,
    		fabric_type 				SMALLINT,
    		style_type 					SMALLINT,
    		orig_sell 					MONEY(8,2),
    		prev_sell 					MONEY(8,2),
    		unit_cost 					MONEY(8,2),
    		unit_sell 					MONEY(8,2),
    		story 						SMALLINT,
    		lchg_dte 					DATE,
    		del_flg 					CHAR(1),
    		pos_del_flg 				CHAR(1),
    		page 						CHAR(20),
    		month 						INTEGER,
    		catalogue 					CHAR(1),
    		gst_perc 					DECIMAL(4,2),
    		who 						CHAR(20),
    		lockdtime 					DATETIME YEAR TO FRACTION(3),
    		cost_lchg_date 				DATE,
    		ledger_cost 				DECIMAL(7,2),
    		date_insert 				DATE,
    		country_of_origin 			CHAR(40),
    		fabric_content 				CHAR(40),
    		classification 				CHAR(30),
    		garment_cons 				CHAR(30),
    		garment_dept 				CHAR(20),
    		fob_method 					CHAR(15),
    		fob 						CHAR(15),
    		fob_cost 					DECIMAL(11,2),
    		web_care 					CHAR(80),
    		supplier_cost 				DECIMAL(8,2)
				END RECORD,
		#R04 <<
		#R04 <<
		

		g_arg						CHAR(10),
		g_menuopt					CHAR(80),
		g_arrsize					INTEGER,
		g_dspsize					INTEGER,
		g_scrnhdr					CHAR(80),
		g_comp						CHAR(80),
		g_lnl						CHAR(80),
		g_wherepart					CHAR(500),
		g_currqcnt					CHAR(500),
		g_currqry					CHAR(500),
		g_lastquery					CHAR(500),
		g_select					CHAR(200),
		g_orderby					CHAR(100),
		g_dfqcnt					CHAR(200),
		g_constoption				CHAR(80),
		g_currentrec				INTEGER,
		g_totrec					INTEGER,
		g_void						INTEGER
END GLOBALS
################################################################################
# @@@@@@@@@@@@@@@@@ (sty_entG) @@@@@@@@@@@@@
################################################################################
