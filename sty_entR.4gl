################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_ent - Report							   #
#  																			   #
# 	R00	02aug01	td				initial release						           #
#   R01 11sep01 td				Mod. Campaigns- Setup an alternate wibm printer#
#	R03	18apr05 td		Mod. Campaign - convert to Genero                      #
#																	           #
################################################################################
GLOBALS
		"sty_entG.4gl"
	
################################################################################
# sty_entR()
################################################################################
FUNCTION sty_entR()
	DEFINE
			p_mode			CHAR(1),
 			p_rpttype       CHAR(20),
            p_rpttext       CHAR(80),
			file_name		CHAR(8),
			file_name1		CHAR(14), 
			file_name2		CHAR(6),
			p_printername	CHAR(80),	#R03
			p_display		STRING		#R03

	#R03 >>
	CALL ui.Interface.refresh()
   	CALL printer_G() RETURNING p_printername
	IF p_printername IS NULL THEN
		RETURN 
	END IF
	{ process report }
	LET g_printer = FALSE					#R01
	#R01 >>
	IF p_printername =  "wibm" THEN
		LET g_printer = TRUE
	END IF
	#R01 <<
	LET file_name = TIME
	LET file_name2 = file_name[1], file_name[2], 
					 file_name[4], file_name[5], 
					 file_name[7], file_name[8]
	LET file_name1 = "QPstyle", file_name2 CLIPPED
	START REPORT sty_entP TO file_name1

	CALL open_window("4","SOH")
	LET p_display = "Extracting data...please wait" 
	DISPLAY BY NAME p_display
	ATTRIBUTE(MAGENTA)
	CALL ui.Interface.refresh()
	IF (int_flag) THEN
	   	LET p_display = "Report cancelled"
		CALL messagebox(p_display,2)
	   	CALL ui.Interface.refresh() 
		RETURN 
	END IF
	#R03 <<

	WHILE sty_entI("NEXT") 
		#R03 >>
		LET p_display = "Printing Style ",g_style.style
		DISPLAY BY NAME p_display
		ATTRIBUTE(MAGENTA)
		CALL ui.Interface.refresh()
		IF (int_flag) THEN
	   		LET p_display = "Report cancelled"
			CALL messagebox(p_display,2)
	   		CALL ui.Interface.refresh() 
			RETURN 
		END IF
		OUTPUT TO REPORT sty_entP(g_style.*)
	END WHILE

	FINISH REPORT sty_entP
    CALL close_window("4","SOH")
	IF int_flag THEN
		LET p_display = "report cancelled"			#R03
		CALL messagebox(p_display,2)				#R03
	ELSE
		LET p_display = "report completed"			#R03
		CALL messagebox(p_display,1)				#R03
		CALL handle_output(p_printername,file_name1)            #R03
	END IF
	MESSAGE "Report finished"  
	SLEEP 1
END FUNCTION
################################################################################
#@@@@@@@@@@@@@@@@@ sty_entR() @@@@@@@@@@@@@@@@@@@@
################################################################################
################################################################################
# sty_entP()
################################################################################
REPORT sty_entP(pr_style)

	DEFINE 
			pr_colour_name      LIKE colour.colour_name,                    #rxx
            pr_stylecol         RECORD LIKE style_colour.*,                 #rxx
		    pr_season_desc 		LIKE season.season_desc,
		    pr_class_desc 		LIKE class.class_desc,
			pr_category_name 	LIKE category.category_name,
			pr_style			RECORD LIKE style.*,
			esc_char			CHAR(1),
  			p_rptwidth          INTEGER,
            idx                 INTEGER,
            p_line              CHAR(140),
            p_prg               CHAR(15),
            p_prglen            INTEGER ,
			p_rephdr 			CHAR(80),
     		h_col               ARRAY[5] OF INTEGER,
            t_col               ARRAY[5] OF INTEGER,
            r_col               ARRAY[18] OF INTEGER

OUTPUT
	TOP MARGIN 2
	BOTTOM MARGIN 2
	LEFT MARGIN 0
	RIGHT MARGIN 140
	PAGE LENGTH 66

FORMAT
	PAGE HEADER
	IF PAGENO = 1 THEN
		{ set general parameters }
		LET p_rptwidth = 130
		LET p_rephdr = "STYLE REPORT"

		{ set on header columns }
		LET h_col[1] = 1
		LET h_col[2] = p_rptwidth - 23
		LET h_col[3] = (p_rptwidth - LENGTH(p_rephdr)) / 2

		{ set on row columns }
		LET	r_col[1] = 	1				{style}
		LET	r_col[2] = 	11				{short desc}
		LET	r_col[3] = 	35				{supplier}
		LET	r_col[4] = 	45				{supplier type}
		LET	r_col[5] = 	62				{faric type}
		LET	r_col[6] = 	69				{style type}
		LET	r_col[7] = 	77				{unitt cost}
		LET	r_col[8] = 	89				{unit sell} 
		LET	r_col[9] = 	101				{story}
		LET	r_col[10] = 108				{last change date}
		LET	r_col[11] = 121				{status}

		{ set on trailer columns }
		LET t_col[1] = 1
		LET t_col[2] = (p_rptwidth - 24) / 2
		LET t_col[3] = (p_rptwidth - 8) / 2

       FOR idx = 1 TO 130
            LET p_line[idx,idx] = "-"
      END FOR
	END IF
 	LET esc_char = ASCII 27
    LET p_prg = "sty_ent.4ge "
    LET p_prg = p_prg CLIPPED
	#R01 >>
	IF g_printer THEN
  		PRINT p_prg CLIPPED,
   			COLUMN h_col[1], " ** ", g_comp CLIPPED, " **",
  		 	COLUMN h_col[2],    "  ", DATE, " ",TIME,
                              PAGENO USING " Page: <<<"
	ELSE  
	#R01 <<
  		PRINT   esc_char, g_pr.qcondensed, " ",p_prg CLIPPED,
   			COLUMN h_col[1], " ** ", g_comp CLIPPED, " **",
  		 	COLUMN h_col[2],    "  ", DATE, " ",TIME,
                              PAGENO USING " Page: <<<"
	END IF
    PRINT
	PRINT	COLUMN h_col[3], p_rephdr CLIPPED
	PRINT

	LET	pr_season_desc = NULL
	SELECT	season_desc
	INTO	pr_season_desc
	FROM	season
	WHERE	season = g_style.season

	LET	pr_class_desc = NULL
	SELECT	class_desc
	INTO	pr_class_desc
	FROM	class
	WHERE	class = g_style.class

	LET	pr_category_name = NULL
	SELECT	category_name
	INTO	pr_category_name
	FROM	category
	WHERE	category = g_style.category

	PRINT "SEASON:   ", pr_style.season, COLUMN 15, pr_season_desc
	PRINT "CLASS:    ", pr_style.class USING "<<<", COLUMN 15, pr_class_desc
	PRINT "CATEGORY: ", pr_style.category USING "<<<", COLUMN 15, pr_category_name
	PRINT p_line
   	PRINT   COLUMN  r_col[5], "<- TYPE ->"
   	PRINT   COLUMN  r_col[1], "STYLE",
            COLUMN  r_col[2], "SHORT DESCRIPTION",
            COLUMN  r_col[3], "SUPPLIER",
            COLUMN  r_col[4], "SUP. STYLE",
            COLUMN  r_col[5], "FABRIC",
            COLUMN  r_col[6]+1,  "STYLE",
            COLUMN  r_col[7]+1,  "UNIT COST",
            COLUMN  r_col[8]+1, "UNIT SELL",
            COLUMN  r_col[9], "STORY",
            COLUMN  r_col[10], "LAST CHANGED",
            COLUMN  r_col[11], "STATUS"
	PRINT p_line

	BEFORE GROUP OF pr_style.class
		SKIP TO TOP OF PAGE

	ON EVERY ROW
	 	PRINT   COLUMN  r_col[1], pr_style.style,
	 			COLUMN  r_col[2], pr_style.short_desc,
	 			COLUMN  r_col[3], pr_style.supplier USING "<<<<",
	 			COLUMN  r_col[4], pr_style.sup_sty,
	 			COLUMN  r_col[5], pr_style.fabric_type USING "<<<",
	 			COLUMN  r_col[6], pr_style.style_type,
	 			COLUMN  r_col[7]+2, pr_style.unit_cost USING "----&.&&",
	 			COLUMN  r_col[8]+2, pr_style.unit_sell USING "----&.&&",
	 			COLUMN  r_col[9], pr_style.story USING "<<<",
	 			COLUMN  r_col[10], pr_style.lchg_dte,
	 			COLUMN  r_col[11], pr_style.del_flg
		#rxx >>
	 	PRINT	 COLUMN  r_col[1], "Category: ",
	 	     	 COLUMN  r_col[2], pr_style.cat1 CLIPPED," ",
								   pr_style.cat2 CLIPPED, " ",
								   pr_style.cat3 CLIPPED, " ",
								   pr_style.cat4 CLIPPED, " ",
								   pr_style.cat5 CLIPPED, " "
	 	PRINT	 COLUMN  r_col[1], "Description: ",
	 	         COLUMN  r_col[2], pr_style.web_desc1 CLIPPED," ",
								   pr_style.web_desc2 CLIPPED, " ",
								   pr_style.web_desc3 CLIPPED, " "
	 	PRINT	 COLUMN  r_col[1], "Keyword: ",
	 	     	 COLUMN  r_col[2], pr_style.web_keyword1 CLIPPED," ",
								   pr_style.web_keyword2 CLIPPED, " ",
								   pr_style.web_keyword3 CLIPPED, " "
	 	PRINT	 COLUMN  r_col[1], "Assortment: ",
	 	       COLUMN  r_col[2], pr_style.assort1 CLIPPED," ",
								   pr_style.assort2 CLIPPED, " ",
								   pr_style.assort3 CLIPPED

		INITIALIZE pr_stylecol.* TO NULL
		DECLARE c_2 CURSOR FOR
			SELECT	*
			FROM	style_colour
			WHERE	style = pr_style.style
			ORDER BY colour
		FOREACH c_2 INTO pr_stylecol.*
			LET pr_colour_name  = NULL
			SELECT	colour_name
			INTO	pr_colour_name
			FROM	colour
			WHERE	colour = pr_stylecol.colour

	 		PRINT	 COLUMN  r_col[1], "Colour: ", pr_stylecol.colour USING "<<<", " ", pr_colour_name CLIPPED
	 	 	PRINT	COLUMN r_col[2], "Upper Assortment: ",pr_stylecol.upper CLIPPED
	 	    PRINT   COLUMN r_col[2], "Trend: ", pr_stylecol.trend1 CLIPPED," ", pr_stylecol.trend2 CLIPPED
		END FOREACH
		CLOSE c_2
		#rxx <<
		
	ON LAST ROW
		SKIP 3 LINES
		PRINT	COLUMN t_col[2], COUNT (*) USING "######&", " RECORDS PRINTED."
END REPORT
################################################################################
#@@@@@@@@@@@@@@@@@ sty_entP @@@@@@@@@@@@@@@@@@@@
################################################################################
