IMPORT os 
DATABASE seed
###############################################################################
#
#	(c) Copyright Century Software Pty. Ltd. Australia, 1986-2011
#	http://www.CenturySoftware.com.au
#   License granted to Brandbank for internal use.
#   This code cannot be distributed in binary or source format.
#	R01	wc	15feb15		Check for program already running
#	R02	13sep15 td				Mod Campaign - clone from epa 
#                               Applied the "on idle" to timed out of the      #
#                               process having no activity.                    #
#
############################################################################

##SCHEMA acct80
	##display "schema ", g_DbName 
##SCHEMA g_DbName 
SCHEMA seed

GLOBALS
DEFINE
    g_pgm   CHAR(20),
    g_user  CHAR(20),
    g_dbname	CHAR(20),    
    g_os    STRING,    
    g_cfidx INTEGER
    ##g_cflist DYNAMIC ARRAY OF RECORD
        ##cf_key          LIKE ut_config.cf_key,
        ##cf_value        LIKE ut_config.cf_value
    ##END RECORD

DEFINE  
     s_init       INTEGER,
     s_errpath       CHAR(200),
     s_separator     CHAR(2),
     s_errdestin     CHAR(256)

#
	DEFINE
		la_array            ARRAY[100] OF RECORD
                printer_code     char(10),
                printer_desc     char(20)
                       END RECORD,
		lr_prtrec        RECORD
                printer_code     char(10),
                printer_desc     char(20)
                        END RECORD ,
		s_custpa                  RECORD LIKE bnk_password.*,
		s_bsrpa                  RECORD LIKE bnk_password.*,			#rxx
		g_version				CHAR(40),
		s_dspsize				INTEGER,
		s_arrsize				INTEGER,
		s_pulldown 	RECORD 
	   				pulldown     CHAR(20)
		            END RECORD,
	 	ssa_pulldown ARRAY[4] OF RECORD
	   				pulldown     CHAR(20)
		            END RECORD,
		  g_idle_time         INTEGER         #rxx
END GLOBALS

DEFINE
		s_cursoropen			INTEGER

FUNCTION gp_Init(p_revision)

	DEFINE
		p_revision	CHAR(4),
		p_module	CHAR(2),
		p_helpfile	CHAR(12),

		p_temp		CHAR(20),
		p_errlog	CHAR(40),
		p_message	CHAR(200),
		p_status	INTEGER


	OPTIONS
			INPUT WRAP,
			ACCEPT KEY F1,
			#ACCEPT KEY CONTROL-V,
--#			MESSAGE LINE 23,
--#			ERROR LINE 23,
			COMMENT LINE 2,
			FORM LINE 4,
			INSERT KEY F3,
			DELETE KEY F2,
			PREVIOUS KEY F6,
			NEXT KEY F5,
			#NEXT KEY CONTROL-P,
			#HELP KEY F10,
			DISPLAY ATTRIBUTE(UNDERLINE)

	OPTIONS INPUT ATTRIBUTE(REVERSE)

	### Start Error Log ###
	#LET p_errlog = "/tmp"
	#LET p_errlog = "/witchbin/tdwrk/witchery"
	LET p_errlog = p_errlog CLIPPED,"/ERRLOG"
	#CALL STARTLOG(p_errlog)
	##CLOSE WINDOW SCREEN
END FUNCTION
#
#
FUNCTION errwait(p_data)
	DEFINE
		p_data		CHAR(77),		
		p_resp		CHAR(40)

	OPEN WINDOW w_errwait AT 1,1 WITH 1 ROWS, 78 COLUMNS				
		ATTRIBUTE(DIM, PROMPT LINE 1)									

	CASE
	WHEN LENGTH (p_data) < 61 
		LET p_data = p_data CLIPPED, " Press F1=PROCEED"
	WHEN LENGTH (p_data) < 72
		LET p_data = p_data CLIPPED, " F1=OK"
	OTHERWISE
		LET p_data = p_data[1,72], "F1=OK"
	END CASE

	OPTIONS ACCEPT KEY ESC 
	WHILE TRUE
		PROMPT p_data CLIPPED FOR p_resp 

			ON KEY(F1)
				EXIT WHILE
		END PROMPT
		MESSAGE ""
		ERROR "invalid: try F1"
	END WHILE
	OPTIONS ACCEPT KEY F1 
			
	CLOSE WINDOW w_errwait											

	RETURN 

END FUNCTION
################################################################################
################################################################################
# also check for negative sign. (-)
FUNCTION gp_isnum(p_string)

	DEFINE	
		p_string		CHAR(100),
		p_len			INTEGER,
		idx				INTEGER,
		p_startlen		INTEGER,
		p_char			CHAR(1),
		p_retstat		INTEGER

	IF p_string IS NULL 
	OR p_string = " " THEN
		LET p_retstat = FALSE
	ELSE
		LET p_len = LENGTH(p_string)
		LET p_retstat = TRUE
 		FOR idx = 1 TO p_len
			LET p_char = p_string[idx,idx]
			IF p_char != " " THEN
				LET p_startlen = idx
				EXIT FOR
			END IF
		END FOR
			
		FOR idx = p_startlen TO p_len
			LET p_char = p_string[idx,idx]
			IF p_char = '-' THEN
				CONTINUE FOR
			END IF
			IF	p_char NOT MATCHES "[0-9]" OR p_char = " "
			THEN
				LET p_retstat = FALSE
				EXIT FOR
			END IF
		END FOR
	END IF

	RETURN p_retstat

END FUNCTION
################################################################################
FUNCTION gp_getco(p_company)

	DEFINE	
				p_company				INTEGER,
				p_company_name			CHAR(30)


	SELECT	company_name
	INTO	p_company_name
	FROM	company
	WHERE	company = p_company

	IF p_company_name IS NULL THEN
		LET p_company_name = "No company setup"
	END IF

	RETURN p_company_name
END FUNCTION
#####
FUNCTION gp_pulldown(p_title,p_msg1,p_msg2,p_msg3,p_msg4,p_row,p_col)
	DEFINE 
			p_msg1,
			p_msg2,
			p_msg3,
			p_msg4				CHAR(80),
			p_maxidx			INTEGER,
			p_title				CHAR(80),
			p_row,p_col,
			idx,sidx			INTEGER,
			p_retstat			INTEGER

	#OPTIONS
	#	ACCEPT KEY RETURN

LABEL redisplay:
	LET p_retstat = TRUE
	LET s_dspsize = 4
	LET s_arrsize = 4
	OPEN WINDOW w_11
	AT p_row,p_col
	WITH FORM "gp_puldown"
	ATTRIBUTE(TEXT=p_title,STYLE="naked")
	#gxx <<

	INITIALIZE s_pulldown.* TO NULL

	FOR idx = 1 TO s_arrsize
		INITIALIZE ssa_pulldown[idx].* TO NULL
	END FOR

	LET ssa_pulldown[1].pulldown = p_msg1 CLIPPED
	LET ssa_pulldown[2].pulldown = p_msg2 CLIPPED
	LET ssa_pulldown[3].pulldown = p_msg3 CLIPPED
	LET ssa_pulldown[4].pulldown = p_msg4 CLIPPED
	LET p_title = p_title CLIPPED
#gxx    DISPLAY BY NAME p_title 
#gxx--#    ATTRIBUTE (REVERSE,BLUE)
#gxx--# MESSAGE "RETURN=ACCEPT" ATTRIBUTE(BLUE,REVERSE)

	LET p_maxidx = 0
	FOR idx = 1 TO 4
		IF ssa_pulldown[idx].pulldown != " " THEN
			LET p_maxidx = p_maxidx + 1
		END IF
	END FOR
		
	#LET p_maxidx = 4
	CALL SET_COUNT(p_maxidx)
	DISPLAY ARRAY ssa_pulldown TO sc_pulldown.*
##	ATTRIBUTE(UNDERLINE)
##--#	ATTRIBUTE(REVERSE, CURRENT ROW DISPLAY="REVERSE")
		ON KEY (RETURN)
			LET idx = ARR_CURR()
	   		EXIT DISPLAY
		ON KEY (F1)
			LET p_retstat = FALSE
		#Gxx >>
        ON ACTION action_return
            LET idx = ARR_CURR()
            LET int_flag = FALSE
            EXIT DISPLAY

        ON ACTION action_exit
            LET int_flag = TRUE
            EXIT DISPLAY

        AFTER DISPLAY
            LET idx = ARR_CURR()
            LET int_flag = FALSE
            EXIT DISPLAY
        #Gxx <<
	END DISPLAY
	IF NOT p_retstat THEN
		CLOSE WINDOW w_11
		goto redisplay
	END IF
	CALL gp_dsppulldown()
	CLOSE WINDOW w_11
	#OPTIONS
	#ACCEPT KEY F1
	RETURN ssa_pulldown[idx].pulldown
END FUNCTION 
##########
FUNCTION gp_dsppulldown()
	DEFINE
            idx         INTEGER

    FOR idx = 1 TO s_dspsize
        DISPLAY ssa_pulldown[idx].* TO sc_pulldown[idx].*
        ATTRIBUTE(NORMAL,UNDERLINE)
    END FOR
    INITIALIZE s_pulldown.* TO NULL
    DISPLAY BY NAME s_pulldown.pulldown
    ATTRIBUTE(NORMAL)
END FUNCTION

FUNCTION gp_autonum(p_type, p_fmt)

	DEFINE	p_type			LIKE autonum.type,
			p_mode			CHAR(1),
			p_fmt			CHAR(20),
			p_retnumb		CHAR(20),
			p_auto			RECORD LIKE autonum.*,
			p_status		INTEGER

	UPDATE autonum 
	SET autonum = autonum + 1
	WHERE type = p_type

	SELECT	* 
	INTO	p_auto.*
	FROM	autonum
	WHERE	type = p_type

	LET p_retnumb = p_auto.autonum USING p_fmt

	RETURN p_retnumb

END FUNCTION
################################################################################
############################@@@@@( gp_getnumb )@@@@@##############################
################################################################################
################################################################################
FUNCTION seccheck(p_program,p_user,p_mode)

	DEFINE		
			p_perm			RECORD LIKE permission.*,
			p_program		CHAR(80),
			p_user			CHAR(20),
			p_mode			CHAR(1)

display p_program,p_user

	DECLARE c_perm CURSOR FOR
		SELECT	*
		INTO	p_perm.*
		FROM	permission
		WHERE	who = p_user
		AND		program = p_program

	OPEN c_perm
	FETCH c_perm
	IF status = NOTFOUND THEN
		RETURN FALSE
	ELSE
		CASE
		WHEN p_mode = "A"
			IF p_perm.per_add = "Y" THEN
				RETURN TRUE
			ELSE
				RETURN FALSE
			END IF
		WHEN p_mode = "U"
			IF p_perm.per_update = "Y" THEN
				RETURN TRUE
			ELSE
				RETURN FALSE
			END IF
		WHEN p_mode = "D"
			IF p_perm.per_delete = "Y" THEN
				RETURN TRUE
			ELSE
				RETURN FALSE
			END IF
		WHEN p_mode = "R"
			IF p_perm.per_print = "Y" THEN
				RETURN TRUE
			ELSE
				RETURN FALSE
			END IF
		WHEN p_mode = "V"
			IF p_perm.per_delete = "Y" THEN
				RETURN TRUE
			ELSE
				RETURN FALSE
			END IF
		END CASE
	END IF
END FUNCTION
#######
FUNCTION open_window(p_type,p_system)
	DEFINE	p_type		CHAR(2),
			p_system	CHAR(10),
			p_comp 		CHAR(80),						#gxx
    		p_scrnhdr 	CHAR(80),						#gxx
			w 			ui.Window						#gxx

	#gxx >>
	LET p_comp = gp_getco(1)                                #get company name
    LET p_scrnhdr = "** ",p_comp CLIPPED," **"
	#gxx <<
	CASE
	WHEN p_system = "COST"
		CASE
		WHEN p_type = "m"
			LET p_comp = gp_getco(1)							#get company name
			LET p_scrnhdr = "** ",p_comp CLIPPED," **"
			LET p_scrnhdr[30,60] = "- Costing Sheet Entry- "
			LET p_scrnhdr[65,80] = DATE
			LET w = ui.Window.forName("w_cost")
        	IF w IS NULL THEN
				OPEN WINDOW w_cost WITH FORM "cost_sheet"
   				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_cost
        	END IF
		END CASE
	WHEN p_system = "MOVE"
		#gxx >>
		LET p_comp = gp_getco(1)								#get company name
		LET p_scrnhdr = "** ",p_comp CLIPPED," **"
		LET p_scrnhdr[30,60] = "- STOCK MOVEMENTS - "
		LET p_scrnhdr[65,80] = DATE
		CASE
		WHEN p_type = "m"
			LET w = ui.Window.forName("w_1")
        	IF w IS NULL THEN
				OPEN WINDOW w_1 WITH FORM "StkMove"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_1
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_2")
        	IF w IS NULL THEN
				OPEN WINDOW w_2 WITH FORM "StkMove1" 
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")				#gxx
			ELSE
				CURRENT WINDOW IS w_2
        	END IF
		END CASE
	WHEN p_system = "CLBUDG" 
		#gxx >>
		LET p_comp = gp_getco(1)								#get company name
		LET p_scrnhdr = "** ",p_comp CLIPPED," **"
		LET p_scrnhdr[30,60] = "- Class Sales Analysis - "
		LET p_scrnhdr[65,80] = DATE
		#gxx <<
		CASE
		WHEN p_type = "1"
			#gxx >>
			OPEN WINDOW w_1 WITH FORM "cl_budg_f2"
			ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			#gxx <<
		WHEN p_type = "2"
			#gxx >>
			OPEN WINDOW w_2 WITH FORM "cl_budg_f3"
			ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			#gxx <<
		WHEN p_type = "3"
			OPEN WINDOW w_3 WITH FORM "cl_budg_f4"
			ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			#gxx <<
		END CASE
	WHEN p_system = "BSR" 
		LET p_comp = gp_getco(1)								#get company name
		LET p_scrnhdr = "** ",p_comp CLIPPED," **"
		LET p_scrnhdr[30,60] = "- Replenishments Model Entry - "
		LET p_scrnhdr[65,80] = DATE
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_model")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_model WITH FORM "bsr_model"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_model
        	END IF
		END CASE
	WHEN p_system = "ORDER" 
        LET p_scrnhdr[30,60] = "- Purchase Order- "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_po_ord")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_po_ord WITH FORM "po_style1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_po_ord					#gxx
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_1")				#gxx
        	IF w IS NULL THEN
				OPEN WINDOW w_1 
				WITH FORM "po_ord"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_1						#gxx
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_2")
        	IF w IS NULL THEN
				OPEN WINDOW w_2 
				WITH FORM "po_size"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_2
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("w_3")
        	IF w IS NULL THEN
				OPEN WINDOW w_3 
				WITH FORM "po_remarks"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_3
        	END IF
		WHEN p_type = "4"
			LET w = ui.Window.forName("w_4")
        	IF w IS NULL THEN
				OPEN WINDOW w_4 
				WITH FORM "po_inst"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_4
        	END IF
		WHEN p_type = "5"
			LET w = ui.Window.forName("w_5")
        	IF w IS NULL THEN
				OPEN WINDOW w_5 WITH FORM "po_pack"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_5
        	END IF
		WHEN p_type = "6"
			LET w = ui.Window.forName("w_6")
        	IF w IS NULL THEN
				OPEN WINDOW w_6 WITH FORM "po_pack1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_6
        	END IF
		WHEN p_type = "7"
			OPEN WINDOW w_7 AT 8,10
			WITH 11 ROWS,60 COLUMNS
    		ATTRIBUTE (BORDER,PROMPT LINE LAST, BLACK,
    		MESSAGE LINE LAST, COMMENT LINE LAST, FORM LINE FIRST)
        WHEN p_type = "8"
			LET w = ui.Window.forName("w_8")
            IF w IS NULL THEN
				OPEN WINDOW w_8 WITH FORM "po_packHK"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_8
            END IF
        WHEN p_type = "9"
			LET w = ui.Window.forName("w_9")
            IF w IS NULL THEN
				OPEN WINDOW w_9 WITH FORM "po_packHK1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_9
            END IF
        WHEN p_type = "10"
			LET w = ui.Window.forName("w_9")
            IF w IS NULL THEN
				OPEN WINDOW w_9 WITH FORM "po_ax"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_9
            END IF
		WHEN p_type = "h"
			LET w = ui.Window.forName("w_h")
        	IF w IS NULL THEN
				OPEN WINDOW w_h 
				WITH FORM "po_hdr"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_h
        	END IF
		WHEN p_type = "v"
			LET w = ui.Window.forName("w_v")
        	IF w IS NULL THEN
				OPEN WINDOW w_v AT 4,1
				WITH FORM "po_vhdr"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_v
        	END IF
		WHEN p_type = "p"
			LET w = ui.Window.forName("w_p")
        	IF w IS NULL THEN
				OPEN WINDOW w_p WITH FORM "po_vpack"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_p
        	END IF
		WHEN p_type = "q"
			LET w = ui.Window.forName("w_q")
        	IF w IS NULL THEN
				OPEN WINDOW w_q WITH FORM "po_vpack1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_q
        	END IF
		END CASE
	WHEN p_system = "LIMAALLOC" 
        LET p_scrnhdr[30,60] = "- LIST OF LIMA ORDERS PREALLOCATED - "		
        LET p_scrnhdr[65,80] = DATE					
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_limaprealloc")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_limaprealloc WITH FORM "lima_prealloc"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		
			ELSE
				CURRENT WINDOW IS w_limaprealloc					
        	END IF
		END CASE
	WHEN p_system = "LIMASCAN" 
        LET p_scrnhdr[30,60] = "- LIST OF LIMA ORDERS SCANPACKED - "		
        LET p_scrnhdr[65,80] = DATE					
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_limascan")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_limascan WITH FORM "lima_scanpack"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		
			ELSE
				CURRENT WINDOW IS w_limascan					
        	END IF
		END CASE
	WHEN p_system = "DMCOALLOC" 
        LET p_scrnhdr[30,60] = "- LIST OF DAMCO ORDERS PREALLOCATED - "		
        LET p_scrnhdr[65,80] = DATE					
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_dmcoprealloc")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_dmcoprealloc WITH FORM "dmco_prealloc"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		
			ELSE
				CURRENT WINDOW IS w_dmcoprealloc					
        	END IF
		END CASE
	WHEN p_system = "PREALLOC" 
        LET p_scrnhdr[30,60] = "- LIST OF ORDERS PREALLOCATED - "		
        LET p_scrnhdr[65,80] = DATE					
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_prealloc")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_prealloc WITH FORM "po_prealloc"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		
			ELSE
				CURRENT WINDOW IS w_prealloc					
        	END IF
		WHEN p_type="1"
			LET w = ui.Window.forName("w_pregroup")
        	IF w IS NULL THEN
				OPEN WINDOW w_pregroup WITH FORM "po_groupx"
            	ATTRIBUTES(STYLE="naked")
				#ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_pregroup
        	END IF
		END CASE
	WHEN p_system = "PREPACK" 
        LET p_scrnhdr[30,60] = "- SELECT AN ITEM TO PACK "
        LET p_scrnhdr[65,80] = DATE					
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_prepack")
        	IF w IS NULL THEN
		    	##OPEN WINDOW w_prepack WITH FORM "po_desp"
		    	OPEN WINDOW w_prepack WITH FORM "po_prepack"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		
			ELSE
				CURRENT WINDOW IS w_prepack					
        	END IF
		END CASE
	WHEN p_system = "WHDIST1" 
		LET p_comp = gp_getco(1)								#get company name
		LET p_scrnhdr = "** ",p_comp CLIPPED," **"
		LET p_scrnhdr[23,60] = "- WH Replenishment Stock Distribution - "
		LET p_scrnhdr[65,80] = DATE
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_wh_style")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_style WITH FORM "po_style"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_style
			END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_wh_dist")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_dist WITH FORM "po_dist1"			
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_dist
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_wh_method")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method WITH FORM "po_whmethodx"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("w_wh_alloc1")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc1 WITH FORM "po_whalloc1x"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_alloc1
        	END IF
		WHEN p_type = "6"
			LET w = ui.Window.forName("w_wh_method1")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method1 WITH FORM "po_whmethod1x"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method1
        	END IF
		WHEN p_type = "7"
			LET w = ui.Window.forName("w_wh_alloc2")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc2 AT 5,1
				WITH FORM "po_whalloc2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc2
        	END IF
		WHEN p_type = "8"
			LET w = ui.Window.forName("w_wh_method2")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method2 WITH FORM "po_whmethod2"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method2
        	END IF
		WHEN p_type = "12"
			LET w = ui.Window.forName("w_wh_alloc3")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc3 AT 5,1
				WITH FORM "po_whalloc3"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc3
        	END IF
		WHEN p_type = "13"
			LET w = ui.Window.forName("w_wh_alloc4")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc4 AT 5,1
				WITH FORM "po_whalloc4"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc4
        	END IF
		END CASE 

	WHEN p_system = "WHDIST2" 
		LET p_comp = gp_getco(1)								#get company name
		LET p_scrnhdr = "** ",p_comp CLIPPED," **"
		LET p_scrnhdr[30,60] = "- Candy Warehouse Distribution - "
		LET p_scrnhdr[65,80] = DATE

		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_wh_style")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_style WITH FORM "po_style"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_style
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_wh_dist")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_dist WITH FORM "po_dist"			
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_dist
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_wh_method")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method WITH FORM "po_whmethod"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("w_wh_alloc1")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc1 WITH FORM "po_whalloc1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_alloc1
        	END IF
		WHEN p_type = "6"
			LET w = ui.Window.forName("w_wh_method1")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method1 WITH FORM "po_whmethod1"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method1
        	END IF
			
		WHEN p_type = "7"
			LET w = ui.Window.forName("w_wh_alloc2")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc2 AT 5,1
				WITH FORM "po_whalloc2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc2
        	END IF
		WHEN p_type = "8"
			LET w = ui.Window.forName("w_wh_method2")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method2 WITH FORM "po_whmethod2"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method2
        	END IF
		WHEN p_type = "12"
			LET w = ui.Window.forName("w_wh_alloc3")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc3 AT 5,1
				WITH FORM "po_whalloc3"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc3
        	END IF
		WHEN p_type = "13"
			LET w = ui.Window.forName("w_wh_alloc4")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc4 AT 5,1
				WITH FORM "po_whalloc4"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc4
        	END IF
		END CASE
	WHEN p_system = "WHDIST" 
		LET p_comp = gp_getco(1)								#get company name
		LET p_scrnhdr = "** ",p_comp CLIPPED," **"
		LET p_scrnhdr[30,60] = "- Warehouse Distribution - "
		LET p_scrnhdr[65,80] = DATE

		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_wh_style")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_style WITH FORM "po_style"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_style
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_wh_dist")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_dist WITH FORM "po_dist"			
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_dist
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_wh_method")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method WITH FORM "po_whmethod"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("w_wh_alloc1")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc1 WITH FORM "po_whalloc1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_alloc1
        	END IF
		WHEN p_type = "6"
			LET w = ui.Window.forName("w_wh_method1")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method1 WITH FORM "po_whmethod1"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method1
        	END IF
			
		WHEN p_type = "7"
			LET w = ui.Window.forName("w_wh_alloc2")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc2 AT 5,1
				WITH FORM "po_whalloc2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc2
        	END IF
		WHEN p_type = "8"
			LET w = ui.Window.forName("w_wh_method2")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_wh_method2 WITH FORM "po_whmethod2"		#gxx
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_wh_method2
        	END IF
		WHEN p_type = "12"
			LET w = ui.Window.forName("w_wh_alloc3")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc3 AT 5,1
				WITH FORM "po_whalloc3"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc3
        	END IF
		WHEN p_type = "13"
			LET w = ui.Window.forName("w_wh_alloc4")
        	IF w IS NULL THEN
				OPEN WINDOW w_wh_alloc4 AT 5,1
				WITH FORM "po_whalloc4"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_wh_alloc4
        	END IF
		END CASE
	WHEN p_system = "DIST" 
        LET p_scrnhdr[30,60] = "- Distribution - "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_po_dist")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_po_dist WITH FORM "po_style"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_po_dist
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_1")
        	IF w IS NULL THEN
				OPEN WINDOW w_1 
				WITH FORM "po_dist"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_1
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_2")
        	IF w IS NULL THEN
				OPEN WINDOW w_2 
				WITH FORM "po_method"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_2
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("w_3")
	       	IF w IS NULL THEN
				OPEN WINDOW w_3 WITH FORM "po_alloc1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_3
       	END IF
		WHEN p_type = "4"
			LET w = ui.Window.forName("w_4")
	       	IF w IS NULL THEN
		 		OPEN WINDOW w_4
            	WITH FORM "win_wait"
            	ATTRIBUTES(STYLE="naked")
			ELSE
				CURRENT WINDOW IS w_4
			END IF
		WHEN p_type = "5"
			LET w = ui.Window.forName("w_5")
        	IF w IS NULL THEN
				OPEN WINDOW w_5 WITH FORM "po_group"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_5
        	END IF
		WHEN p_type = "6"
			LET w = ui.Window.forName("w_6")
        	IF w IS NULL THEN
				OPEN WINDOW w_6 
				WITH FORM "po_method1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_6
        	END IF
		WHEN p_type = "7"
			LET w = ui.Window.forName("w_7")
        	IF w IS NULL THEN
				OPEN WINDOW w_7 
				WITH FORM "po_alloc2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_7
        	END IF
		WHEN p_type = "8"
			LET w = ui.Window.forName("w_8")
        	IF w IS NULL THEN
				OPEN WINDOW w_8 WITH FORM "po_vord"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_8
        	END IF
		WHEN p_type = "9"
			LET w = ui.Window.forName("w_9")
        	IF w IS NULL THEN
		 		OPEN WINDOW w_9 
				WITH FORM "po_ratio"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="clone")
			ELSE
				CURRENT WINDOW IS w_9
        	END IF
		WHEN p_type = "10"
			LET w = ui.Window.forName("w_10")
        	IF w IS NULL THEN
				OPEN WINDOW w_10 WITH FORM "po_ratio1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_10
        	END IF
		END CASE
	WHEN p_system = "DIST1" 
        LET p_comp = gp_getco(1)                                #get company name
        LET p_scrnhdr = "** ",p_comp CLIPPED," **"
        LET p_scrnhdr[30,60] = "- New Distribution - "
        LET p_scrnhdr[65,80] = DATE
        CASE
        WHEN p_type="m"
            LET w = ui.Window.forName("w_po_style")
            IF w IS NULL THEN
                OPEN WINDOW w_po_style WITH FORM "po_style"
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_po_style
            END IF
        WHEN p_type = "1"
            LET w = ui.Window.forName("w_po_sdist")
            IF w IS NULL THEN
display "here"
                OPEN WINDOW w_po_sdist WITH FORM "po_sdist"
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
display "current"
                CURRENT WINDOW IS w_po_sdist
            END IF
        WHEN p_type = "2"
			  LET w = ui.Window.forName("w_po_method")
            IF w IS NULL THEN
                OPEN WINDOW w_po_method WITH FORM "po_smethod"      #gxx
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_po_method
            END IF
        WHEN p_type = "3"
            LET w = ui.Window.forName("w_3")
            IF w IS NULL THEN
                OPEN WINDOW w_3 WITH FORM "po_salloc1"
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_3
            END IF
        WHEN p_type = "4"
            LET w = ui.Window.forName("w_4")
            IF w IS NULL THEN
                OPEN WINDOW w_4
                WITH FORM "win_wait"
                ATTRIBUTES(STYLE="naked")
			ELSE
                CURRENT WINDOW IS w_4
            END IF
        WHEN p_type = "5"
            LET w = ui.Window.forName("w_5")
            IF w IS NULL THEN
                OPEN WINDOW w_5 WITH FORM "po_group"
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
            ELSE
                CURRENT WINDOW IS w_5
            END IF
        WHEN p_type = "6"
            LET w = ui.Window.forName("w_po_method1")
            IF w IS NULL THEN
                OPEN WINDOW w_po_method1 WITH FORM "po_smethod1"        #gxx
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
            ELSE
                CURRENT WINDOW IS w_po_method1
            END IF

        WHEN p_type = "7"
            LET w = ui.Window.forName("w_7")
            IF w IS NULL THEN
			  OPEN WINDOW w_7 AT 5,1
                WITH FORM "po_salloc2"
                ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
            ELSE
                CURRENT WINDOW IS w_7
            END IF
		END CASE

	WHEN p_system = "EMAIL" 
        LET p_scrnhdr[30,60] = "- Mail - "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_e_mail")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_e_mail WITH FORM "e_mailM"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_e_mail
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_1")
        	IF w IS NULL THEN
				OPEN WINDOW w_1 
				WITH FORM "e_mailA"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_1
        	END IF
		WHEN p_type = "h"
			LET w = ui.Window.forName("w_2")
        	IF w IS NULL THEN
				OPEN WINDOW w_2 WITH FORM "e_mailH"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_2
        	END IF
		WHEN p_type = "v"
			LET w = ui.Window.forName("w_3")
        	IF w IS NULL THEN
				OPEN WINDOW w_3 
				WITH FORM "e_mailV"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_3
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_4")
        	IF w IS NULL THEN
				OPEN WINDOW w_4 WITH FORM "e_mailL"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_4
        	END IF
		WHEN p_type = "3"
			OPEN WINDOW w_5 at 11,25
     		WITH 3 rows, 28 columns
--#     		ATTRIBUTES(BORDER,BLACK,REVERSE)
		END CASE
	WHEN p_system = "SOH" 
        LET p_scrnhdr[30,60] = "- Sales&SOH-Sty/Clr/Sz each Str - "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
		CASE
		WHEN p_type="1"
			LET w = ui.Window.forName("w_soh")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_soh WITH FORM "soh_sls1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_soh
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("w_soh1")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_soh1 WITH FORM "soh_sls2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_soh1
        	END IF
		WHEN p_type = "4"
			LET w = ui.Window.forName("w_4")
        	IF w IS NULL THEN
		 		OPEN WINDOW w_4
            	WITH FORM "win_wait"
            	ATTRIBUTES(STYLE="naked")
            	##ATTRIBUTES(STYLE="printer")
			ELSE
				CURRENT WINDOW IS w_4
        	END IF
		WHEN p_type = "5"
			LET w = ui.Window.forName("w_5")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_5 WITH FORM "v_sohper"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_5
        	END IF
		WHEN p_type = "6"
			LET w = ui.Window.forName("w_6")
        	IF w IS NULL THEN
            	OPEN WINDOW w_6
            	WITH FORM "win_upd"
--#  	       ATTRIBUTE(STYLE="naked")                #gxx
			ELSE
				CURRENT WINDOW IS w_6
			END IF
		END CASE
	WHEN p_system = "SOH2"        #060312 added
		 LET p_comp = gp_getco(1)                                #get company name
        LET p_scrnhdr = "** ",p_comp CLIPPED," **"
        LET p_scrnhdr[30,60] = "- SOH/SALES by Sty/Clr/Sz in Store"
        LET p_scrnhdr[65,80] = DATE
		CASE
		WHEN p_type="1"
			LET w = ui.Window.forName("pf_soh2")
        	IF w IS NULL THEN
			    OPEN WINDOW pf_soh2 WITH FORM "v_sohsls2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")				
			ELSE
				CURRENT WINDOW IS pf_soh2
        	END IF
		END CASE
	WHEN p_system = "LAYBY" 
        LET p_scrnhdr[30,60] = "- LayBy Enquiry - "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
		CASE
		WHEN p_type="1"
			LET w = ui.Window.forName("w_layby")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_layby WITH FORM "lby_enq1"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_layby
        	END IF
		WHEN p_type = "2"
			LET w = ui.Window.forName("l_1")
        	IF w IS NULL THEN
				OPEN WINDOW l_1 WITH FORM "lby_enq"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS l_1
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("l_2")
        	IF w IS NULL THEN
				OPEN WINDOW l_2 WITH FORM "lby_enq2"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS l_2
        	END IF
		WHEN p_type = "4"
			OPEN WINDOW l_4 at 11,25
     		WITH 3 rows, 28 columns
     		ATTRIBUTES(BORDER,BLACK)
		END CASE
	WHEN p_system = "GV"
        LET p_scrnhdr[30,60] = "- Gift Voucher - "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
        CASE
        WHEN p_type="1"
			LET w = ui.Window.forName("w_gv")
        	IF w IS NULL THEN
				OPEN WINDOW w_gv WITH FORM "gv_sel"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_gv
        	END IF
        WHEN p_type = "2"
			LET w = ui.Window.forName("g_1")
        	IF w IS NULL THEN
				OPEN WINDOW g_1 WITH FORM "gv_lns"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS g_1
        	END IF
		WHEN p_type = "3"
			LET w = ui.Window.forName("w_1")
        	IF w IS NULL THEN
				OPEN WINDOW w_1  WITH FORM "gv_encode"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")
			ELSE
				CURRENT WINDOW IS w_1
        	END IF
        END CASE
	WHEN p_system = "FLASH" 
        LET p_scrnhdr[30,60] = "- FlashSales - "		#Gxx
        LET p_scrnhdr[65,80] = DATE						#Gxx
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_flash")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_flash WITH FORM "flash_sel"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_flash					#gxx
        	END IF
		WHEN p_type="1"
			LET w = ui.Window.forName("w_flash1")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_flash1 WITH FORM "flash_sls"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_flash1					#gxx
        	END IF
		END CASE
	WHEN p_system = "POLL" 
		CASE
		WHEN p_type="m"
		    OPEN FORM pf_poll FROM "poll_eod"
   		 	DISPLAY FORM pf_poll ATTRIBUTE(BLACK)
		END CASE
	WHEN p_system = "ACTUAL" 
		LET p_comp = gp_getco(1)                                #get company name
        LET p_scrnhdr = "** ",p_comp CLIPPED," **"
        LET p_scrnhdr[30,60] = "- Actual Wages - "
        LET p_scrnhdr[65,80] = DATE
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_actual")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_actual WITH FORM "wg_aent"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_actual					#gxx
        	END IF
		END CASE
	WHEN p_system = "SALES" 
		LET p_comp = gp_getco(1)                            #get company name
        LET p_scrnhdr = "** ",p_comp CLIPPED," **"
        LET p_scrnhdr[30,60] = "- Season Sales Budget - "
        LET p_scrnhdr[65,80] = DATE
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_budget")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_budget WITH FORM "wg_cent"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_budget					#gxx
        	END IF
		END CASE
	WHEN p_system = "WBUDGET" 
		LET p_comp = gp_getco(1)                                #get company name
        LET p_scrnhdr = "** ",p_comp CLIPPED," **"
        LET p_scrnhdr[30,60] = "- Budget Wages - "
        LET p_scrnhdr[65,80] = DATE	
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_budg_date")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_budg_date WITH FORM "wg_date"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_budg_date					#gxx
        	END IF
		WHEN p_type = "1"
			LET w = ui.Window.forName("w_budg_ent")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_budg_ent WITH FORM "wg_bent"
				ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		#gxx
			ELSE
				CURRENT WINDOW IS w_budg_ent					#gxx
        	END IF
		END CASE
	WHEN p_system = "BUDGET" 
		CASE
		WHEN p_type="m"
		    OPEN FORM pf_budg_date FROM "budg_date"
--#   		 	DISPLAY FORM pf_budg_date ATTRIBUTE(BLACK)
		WHEN p_type="d"
		    OPEN FORM pf_budg_del FROM "budg_del"
--#   		 	DISPLAY FORM pf_budg_del ATTRIBUTE(BLACK)
		WHEN p_type = "1"
		    OPEN FORM pf_budg_month FROM "budg_month"
--#   		 	DISPLAY FORM pf_budg_month ATTRIBUTE(BLACK)
		WHEN p_type = "2"
			#OPEN WINDOW w_2 AT 4,1
			#WITH FORM "budg_week"
    		#ATTRIBUTE (DIM,PROMPT LINE LAST,
    		#MESSAGE LINE LAST, COMMENT LINE LAST, FORM LINE FIRST)
		    OPEN FORM pf_budg_week FROM "budg_week"
--#   		 	DISPLAY FORM pf_budg_week ATTRIBUTE(BLACK)
		WHEN p_type = "3"
			OPEN FORM w_3 FROM "budg_day"
			DISPLAY FORM w_3
--#			ATTRIBUTE(BLACK)
		WHEN p_type = "4"
			OPEN FORM w_4 FROM "budg_store"
			DISPLAY FORM w_4
--#			ATTRIBUTE(BLACK)
		END CASE
	WHEN p_system = "REPRINT" 
        LET p_scrnhdr[30,60] = "- SELECT AN ITEM TO REPRINT "
        LET p_scrnhdr[65,80] = DATE					
		CASE
		WHEN p_type="m"
			LET w = ui.Window.forName("w_prepack")
        	IF w IS NULL THEN
		    	OPEN WINDOW w_prepack WITH FORM "rptn_fin_prall"
					ATTRIBUTE(TEXT=p_scrnhdr,STYLE="po")		
			ELSE
				CURRENT WINDOW IS w_prepack					
        	END IF
		END CASE
	END CASE
END FUNCTION
#########
FUNCTION close_window(p_type,p_system)
	DEFINE	p_type		CHAR(2),
			p_system 	CHAR(10)

	CASE
	WHEN p_system = "PREALLOC" 
		CASE
		WHEN p_type = "1"
			CLOSE WINDOW w_pregroup
		END CASE
	WHEN p_system = "CLBUDG" 
		CASE
		WHEN p_type = "1"
			CLOSE FORM w_1
		WHEN p_type = "2"
			CLOSE FORM w_2
		WHEN p_type = "3"
			CLOSE FORM w_3
		END CASE
	WHEN p_system = "POLL" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_poll
		END CASE
	WHEN p_system = "FLASH" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_flash
		WHEN p_type = "1"
    		CLOSE FORM pf_flash_dsp
		END CASE
	WHEN p_system = "SALES" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_budget
		END CASE
	WHEN p_system = "ACTUAL" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_actual
		END CASE
	WHEN p_system = "WBUDGET" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_budg_date
		WHEN p_type = "1"
    		CLOSE FORM pf_budg_ent
		END CASE
	WHEN p_system = "BUDGET" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_budg_date
		WHEN p_type = "1"
			#CLOSE WINDOW w_1
    		CLOSE FORM pf_budg_month
		WHEN p_type = "2"
			#CLOSE WINDOW w_2
    		CLOSE FORM pf_budg_week
		WHEN p_type = "3"
			CLOSE FORM w_3
		WHEN p_type = "4"
			CLOSE FORM w_4
		END CASE
	WHEN p_system = "ORDER" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_po_ord 
		WHEN p_type = "1"
			CLOSE WINDOW w_1
		WHEN p_type = "2"
			CLOSE WINDOW w_2
		WHEN p_type = "3"
			CLOSE WINDOW w_3
		WHEN p_type = "4"
			CLOSE WINDOW w_4
		WHEN p_type = "5"
			CLOSE FORM w_5
		WHEN p_type = "6"
			CLOSE FORM w_6
		WHEN p_type = "7"
			CLOSE WINDOW w_7
		WHEN p_type = "h"
			CLOSE WINDOW w_h
		WHEN p_type = "v"
			CLOSE WINDOW w_v
		WHEN p_type = "p"
			CLOSE FORM w_p
		WHEN p_type = "q"
			CLOSE FORM w_q
		END CASE
	WHEN p_system = "DIST" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_po_dist
		WHEN p_type = "1"
			CLOSE WINDOW w_1
		WHEN p_type = "2"
			CLOSE WINDOW w_2
		WHEN p_type = "3"
			CLOSE WINDOW w_3
		WHEN p_type = "4"
			#--CLOSE WINDOW w_4  #--tantest
		WHEN p_type = "5"
			CLOSE FORM w_5
		WHEN p_type = "6"
			CLOSE WINDOW w_6
		WHEN p_type = "7"
			CLOSE WINDOW w_7
		WHEN p_type = "8"
			CLOSE FORM w_8
		WHEN p_type = "9"
			CLOSE WINDOW w_9
		WHEN p_type = "10"
			CLOSE FORM w_10
		END CASE
	WHEN p_system = "EMAIL" 
		CASE
		WHEN p_type ="m"
    		CLOSE FORM pf_e_mail
		WHEN p_type = "1"
			CLOSE WINDOW w_1
		WHEN p_type = "h"
			#CLOSE WINDOW w_2
			CLOSE FORM w_2
		WHEN p_type = "v"
			CLOSE WINDOW w_3
		WHEN p_type = "2"
			CLOSE FORM w_4
		WHEN p_type = "3"
			CLOSE WINDOW w_5 
		END CASE
	WHEN p_system = "SOH" 
		CASE
		WHEN p_type ="1"
    		CLOSE FORM pf_soh
		WHEN p_type = "2"
			CLOSE FORM s_1
		WHEN p_type = "4"
			CLOSE WINDOW w_4
		WHEN p_type = "5"
			CLOSE WINDOW w_5
		WHEN p_type = "6"
			CLOSE WINDOW w_6
		END CASE
	WHEN p_system = "LAYBY" 
		CASE
		WHEN p_type ="1"
    		CLOSE FORM pf_layby
		WHEN p_type = "2"
			CLOSE FORM l_1
		WHEN p_type = "3"
			CLOSE FORM l_2
		WHEN p_type = "4"
			CLOSE WINDOW l_4
		END CASE
	WHEN p_system = "GV" 
		CASE
		WHEN p_type ="1"
    		CLOSE FORM pf_gv
		WHEN p_type = "2"
			CLOSE FORM g_1
		WHEN p_type = "3"
			CLOSE WINDOW w_1
		END CASE
	END CASE
END FUNCTION
FUNCTION colour_lookup()
    DEFINE 
			initial_flag            INTEGER,
			where_part 		CHAR(200),
			idx1			INTEGER,
			p_retstat		INTEGER,
            query_text 		CHAR(250),
		    colour_cnt, idx SMALLINT,
		   	p_acolour ARRAY[50] OF RECORD
				colour 		LIKE colour.colour,
				colour_name LIKE colour.colour_name
				END RECORD

    OPEN WINDOW colour_win AT 10,20
    #WITH FORM "colour_qry1"
    WITH FORM "po_colour"
	ATTRIBUTE(BORDER,BLACk,REVERSE, FORM LINE 2)

	DISPLAY "Enter criteria for selection" AT 1,1 ATTRIBUTE(UNDERLINE)
	LET initial_flag = FALSE
    CONSTRUCT BY NAME where_part ON
			colour.colour_name,
			colour.colour_type
	ATTRIBUTE(UNDERLINE)
		
        ON KEY (F10,INTERRUPT)
            LET initial_flag = TRUE
            EXIT CONSTRUCT
        END CONSTRUCT

    IF initial_flag THEN
        CLOSE WINDOW colour_win
        RETURN " "," "
    END IF


    LET query_text = "select * from colour where ",
					 where_part CLIPPED,
					 " order by colour"

    PREPARE colour_st FROM query_text
    DECLARE c_colour CURSOR FOR colour_st
	LET colour_cnt = 1
	FOREACH c_colour INTO p_acolour[colour_cnt].*
		LET colour_cnt = colour_cnt + 1
		IF colour_cnt > 50 THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET colour_cnt = colour_cnt - 1  

	LET idx = 1  
	IF colour_cnt < 1 THEN
    	CLOSE WINDOW colour_win
		INITIALIZE p_acolour[idx].* TO NULL
		ERROR "No selection satifies criteria" 
											ATTRIBUTE(RED, REVERSE)
		RETURN p_acolour[idx].colour, p_acolour[idx].colour_name
	END IF
	CLOSE WINDOW colour_win
    OPEN WINDOW w_colour AT 12,15
    WITH FORM "colour_li1" ATTRIBUTE (BORDER,BLACK,REVERSE,FORM LINE 1)
	CALL set_count(colour_cnt)
	DISPLAY ARRAY p_acolour TO sc_colour_li.* 
	ATTRIBUTE(UNDERLINE)

	  ON KEY (F1)
            MESSAGE ""
            LET idx = ARR_CURR()
            LET p_retstat = TRUE
            EXIT DISPLAY

        ON KEY (F10)
            LET p_retstat = FALSE
		#gxx >>
	  	ON ACTION accept
            MESSAGE ""
            LET idx = ARR_CURR()
            LET p_retstat = TRUE
            EXIT DISPLAY

        ON ACTION exit
            LET p_retstat = FALSE
		#gxx <<

        EXIT DISPLAY

    END DISPLAY
	FOR idx1=1 to 10
		display p_acolour[idx1].* to sc_colour_li[idx1].*
		ATTRIBUTE(UNDERLINE)
	END FOR
  	CLOSE WINDOW w_colour
	IF p_retstat THEN
        RETURN p_acolour[idx].colour, p_acolour[idx].colour_name
    ELSE
        RETURN "",""
    END IF
END FUNCTION

FUNCTION supplier_lookup(p_style)
    DEFINE 
            initial_flag 			INTEGER,
			p_retstat				INTEGER,
			where_part 				CHAR(200),
           	query_text 				CHAR(300),
		   	supplier_cnt, 
			idx ,idx1				INTEGER,
			p_style					LIKE style.style,
		   	p_asupplier ARRAY[25] OF RECORD
				supplier			LIKE supplier.supplier,
				supplier_name		LIKE supplier.supplier_name,
				no_back_order_flg	LIKE supplier.no_back_order_flg,
				terms				LIKE supplier.terms
		END RECORD

    OPEN WINDOW suppl_win AT 10,20
        WITH FORM "po_supp1"
		ATTRIBUTE(BORDER,BLACK,REVERSE, FORM LINE 2)

    CLEAR FORM
	DISPLAY "Enter criteria for selection" AT 1,1 
	ATTRIBUTE(UNDERLINE)
	LET initial_flag = FALSE
    CONSTRUCT BY NAME where_part ON
				supplier.supplier_name,
				supplier.city,
				supplier.state
	ATTRIBUTE(NORMAL)

		ON KEY (F10,INTERRUPT)
            LET initial_flag = TRUE
            EXIT CONSTRUCT
    	END CONSTRUCT

    IF initial_flag THEN
    	CLOSE WINDOW suppl_win
        RETURN " "," "," "," "
    END IF

	LET idx = 1 
	IF where_part = " 1=1" THEN
    	CLOSE WINDOW suppl_win
		INITIALIZE p_asupplier[idx].* TO NULL
        ERROR "You must specify criteria for selection"
				ATTRIBUTE(RED,UNDERLINE)
		RETURN  p_asupplier[idx].supplier,
				p_asupplier[idx].supplier_name,
				p_asupplier[idx].no_back_order_flg,
				p_asupplier[idx].terms
	END IF


    LET query_text = 
			" SELECT	supplier.supplier,supplier_name,no_back_order_flg,",
			" 			terms ",
			" FROM 		supplier , style b ",
			" WHERE ", where_part CLIPPED,
			" AND 		supplier.supplier = b.supplier ",
			" AND		b.style = ",p_style
    PREPARE supplier_st FROM query_text
    DECLARE c_supplier CURSOR FOR supplier_st

	LET supplier_cnt = 1

	FOREACH c_supplier INTO p_asupplier[supplier_cnt].*
		LET supplier_cnt = supplier_cnt + 1
		IF supplier_cnt > 25 THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET supplier_cnt = supplier_cnt - 1  

	LET idx = 1 

	IF supplier_cnt < 1 THEN
    	CLOSE WINDOW suppl_win
		ERROR "No criteria satisfies query"  ATTRIBUTE(RED, REVERSE)
		INITIALIZE p_asupplier[idx].* TO NULL
		RETURN  p_asupplier[idx].supplier,
				p_asupplier[idx].supplier_name,
				p_asupplier[idx].no_back_order_flg,
				p_asupplier[idx].terms
	END IF

    OPEN WINDOW w_supplier AT 12,15
    WITH FORM "po_suppl2"
	ATTRIBUTE (BORDER,BLACK,REVERSE, FORM LINE 1)

	CALL set_count(supplier_cnt)
	DISPLAY ARRAY p_asupplier TO sc_supplier_li.* 
	ATTRIBUTE(NORMAL)

	  ON KEY (F1)
            MESSAGE ""
            LET idx = ARR_CURR()
            LET p_retstat = TRUE
            EXIT DISPLAY

        ON KEY (F10)
            LET p_retstat = FALSE
        EXIT DISPLAY

    END DISPLAY
{
	FOR idx1=1 to 10
		DISPLAY p_asupplier[idx1].* to sc_supplier_li[idx1].*
		ATTRIBUTE(UNDERLINE)
	END FOR
}
    CLOSE WINDOW w_supplier
    CLOSE WINDOW suppl_win
	IF p_retstat THEN
		RETURN p_asupplier[idx].supplier, p_asupplier[idx].supplier_name,
			   p_asupplier[idx].no_back_order_flg,
			   p_asupplier[idx].terms
	ELSE
		RETURN " "," "," "," "
	END IF
END FUNCTION

FUNCTION gp_create_po(p_type,p_fmt)
	DEFINE
			p_auto			RECORD LIKE autonum.*,
			p_min			INTEGER,
			p_max			INTEGER,
			p_type			CHAR(20),
			p_fmt			CHAR(20),
			p_query			CHAR(200),
			p_status		INTEGER,
			p_retstring		CHAR(20)

	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT
	IF NOT s_cursoropen THEN
		LET p_query=
			" SELECT	* ",
			" FROM	 	autonum ",
			" WHERE		type = ? ",
			" AND		autonum = ? ",
			" FOR UPDATE "
		PREPARE s_min FROM p_query
		DECLARE c_min CURSOR WITH HOLD FOR s_min
		LET s_cursoropen=TRUE
	END IF

	WHILE TRUE
		SELECT	MIN(autonum)
		INTO	p_min
		FROM	autonum
		WHERE	type=p_type
		
		OPEN c_min USING p_type,p_min
		FETCH c_min INTO p_auto.*
		LET p_status=status
		IF p_status != NOTFOUND THEN
			#CLOSE c_min
			EXIT WHILE
		END IF
	END WHILE
	SELECT	MAX(autonum)
	INTO	p_max
	FROM	autonum
	WHERE	type=p_type
	IF p_min=p_max THEN
		UPDATE	autonum
		SET		autonum = autonum + 1
		WHERE 	type=p_type
		AND		autonum=p_min
	ELSE
		DELETE FROM autonum 
		WHERE 	type=p_type
		AND		autonum=p_min
	END IF
	CLOSE c_min
	LET p_retstring = p_auto.autonum USING p_fmt
	SET LOCK MODE TO WAIT 
	WHENEVER ERROR STOP
	RETURN p_retstring
END FUNCTION
################################################################################
#	cat_setpasswd - set up password											   #
################################################################################
#R01 >>
FUNCTION cat_setpasswd()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("cust") THEN
		CALL cat_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "cust"
			CALL cat_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = cat_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL cat_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT cat_validpw("cust",p_passwd) THEN		#not found
				CALL cat_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT cat_validpw("cust",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (cat_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
FUNCTION no_password(p_user)

	DEFINE
			p_user			LIKE bnk_password.bnkpa_user

	SELECT	*
	INTO	s_custpa.*
	FROM	bnk_password
	WHERE	bnkpa_user = p_user
	
	IF status = NOTFOUND THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_password) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION cat_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	cat_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION cat_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
			 #gxx >>
        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (cat_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION cat_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER
	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
#R01 <<
FUNCTION r_printer()

	DEFINE	idx				INTEGER,
			p_dummy			INTEGER,
			p_dest			CHAR(20),			
			sidx			INTEGER,
			p_row			INTEGER,
			p_col			INTEGER,
			p_title			CHAR(80),
			p_msglns		CHAR(80),
		    lsi_j			SMALLINT, 
		    lsi_sw			SMALLINT, 
		    lsi_prt			SMALLINT, 
		    lsi_idx			SMALLINT,
		    lsi_currow		SMALLINT,
			p_retstat		INTEGER,
		    lc_null			CHAR(1),
			p_state			LIKE state.state,
			p_query			CHAR(200)

	LET int_flag = false
	LET quit_flag = false
	LET lsi_sw = false
	LET lsi_idx = 0
	LET lc_null = null
	INITIALIZE lr_prtrec.* TO NULL

	FOR lsi_idx = 1 to 100
		INITIALIZE la_array[lsi_idx].* TO NULL
	END FOR

	LET p_title = "          LIST OF PRINTERS"
	LET p_msglns = "OPTIONS: F1=ACCEPT F10=EXIT"
	OPEN WINDOW w_printer AT 5,45
   	WITH FORM "r_printer"
--#	ATTRIBUTES(Border,REVERSE, Form Line 1,BLACK,
    PROMPT LINE LAST, MESSAGE LINE LAST,COMMENT LINE LAST)

	DISPLAY BY NAME p_title
--#	ATTRIBUTE (BLUE)
	DISPLAY BY NAME p_msglns
--#	ATTRIBUTE (BLUE)

	SET ISOLATION TO DIRTY READ
    LET p_query =
    	" SELECT  queprt, quename,sortseq ",
        " FROM    queprt ",
        " ORDER BY sortseq "

	LET lsi_idx = 0
    PREPARE s_1 FROM p_query
    DECLARE c_1 CURSOR FOR  s_1
	FOREACH c_1 INTO lr_prtrec.*,p_dummy
		LET lsi_idx = lsi_idx + 1
		LET la_array[lsi_idx].* = lr_prtrec.*
	END FOREACH

	CALL SET_COUNT(lsi_idx)
	DISPLAY ARRAY la_array TO scrn_printer.*
	ATTRIBUTE (NORMAL,UNDERLINE, CURRENT ROW DISPLAY = "REVERSE")
	
		ON KEY(F1)
			MESSAGE ""
			LET idx = ARR_CURR()
			LET sidx = SCR_LINE()
			LET p_retstat = TRUE
			EXIT DISPLAY

		ON KEY(F10,INTERRUPT)
			LET p_retstat = FALSE
			EXIT DISPLAY

		END DISPLAY

		CALL r_dspprinter() 
	CLOSE WINDOW w_printer
	IF p_retstat THEN
		RETURN la_array[idx].printer_code
	ELSE
		RETURN ""
	END IF
END FUNCTION --- GetPrinter() ---

FUNCTION r_dspprinter()
	DEFINE
			idx			INTEGER

	LET s_dspsize = 10
	FOR idx = 1 TO s_dspsize #15
		DISPLAY la_array[idx].* TO scrn_printer[idx].* 
		ATTRIBUTE (NORMAL,UNDERLINE)
	END FOR
#	INITIALIZE lr_prtrec.* TO NULL    	 
#	DISPLAY BY NAME lr_prtrec.printer_code,
#				    lr_prtrec.printer_desc
#	ATTRIBUTE(NORMAL,UNDERLINE)
END FUNCTION
FUNCTION r_getprinterinfo(prtname)
	DEFINE
    		prtname				LIKE queprt.queprt,
    		p_qcondensed		LIKE queprt.qcondensed

    SELECT qcondensed
    INTO   p_qcondensed
    FROM queprt
    WHERE queprt = prtname

	RETURN p_qcondensed
END FUNCTION
######################################################################################
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(MainRtn)@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
######################################################################################
FUNCTION dump_to_pr(file_name, printer_name)
	DEFINE file_name CHAR(80), 
		   printer_name LIKE quereq.quereq,
		   n_of_copies SMALLINT,
		   cmd CHAR(150)
	
	LET cmd = "chmod 666" CLIPPED," ", file_name
	LET cmd = cmd CLIPPED
	RUN cmd

	LET file_name = file_name CLIPPED

	LET cmd = "lp", " -d", printer_name CLIPPED, 
			  " ", file_name
	LET cmd = cmd CLIPPED
	RUN cmd
END FUNCTION
######################################################################################
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(MainRtn)@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
######################################################################################
FUNCTION dump_to_pr_n_copies(file_name, printer_name, n_of_copies)
	DEFINE file_name CHAR(80), 
		   printer_name LIKE quereq.quereq,
		   n_of_copies SMALLINT,
		   cmd CHAR(150)
	
	LET cmd = "chmod 666" CLIPPED," ", file_name
	LET cmd = cmd CLIPPED
	RUN cmd

	IF n_of_copies < 1 THEN
		LET n_of_copies = 1
	END IF
	LET file_name = file_name CLIPPED

	LET cmd = "lp", " -d", printer_name CLIPPED, 
					" -n", n_of_copies USING "<<<<<<", 
			  " ", file_name
	LET cmd = cmd CLIPPED
	RUN cmd

END FUNCTION
--#
FUNCTION get_printfilename()
	DEFINE
			file_name			CHAR(80),
			file_name1			CHAR(80),
			file_name2			CHAR(80)


	LET file_name = TIME
            { This is to drop out the colons from filename variable}
    LET file_name2 = file_name[1], file_name[2],
                     file_name[4], file_name[5],
                     file_name[7], file_name[8]

    LET file_name1 = "QPreport", file_name2 CLIPPED

	RETURN file_name1
END FUNCTION
---# Genero 
FUNCTION messagebox(m,i)
  DEFINE m STRING
  DEFINE i INTEGER
  DEFINE im STRING
  LET im="info"
  CASE i
    WHEN 1 LET im="information"
    WHEN 2 LET im="stop"
    WHEN 3 LET im="exclamation"
  END CASE
  MENU "Message" ATTRIBUTE(STYLE="dialog",COMMENT=m,IMAGE=im)
    COMMAND "ok" EXIT MENU
  END MENU
END FUNCTION
FUNCTION sys_setup()
    SET ISOLATION TO DIRTY READ
END FUNCTION
###############################################################################
FUNCTION show_error_statusbar(p_error,p_type)
	DEFINE	
			p_type		SMALLINT,
			p_error		STRING
	
	IF p_type = 1 THEN
		ERROR p_error 
		ATTRIBUTE(RED)
	ELSE
		MESSAGE p_error 
		ATTRIBUTE(RED)
	END IF
	CALL ui.Interface.refresh()
END FUNCTION

FUNCTION fgx_FindNode(d_parent, p_class, p_attrib, p_value)

	DEFINE
		d_parent	om.DomNode,
		p_class		STRING,
		p_attrib	STRING,
		p_value		STRING,

		d_child		om.DomNode,
		p_nodeTag	CHAR(40),
		p_nodeValue	CHAR(80)


	### Default node is great ancestor ###
	IF d_parent IS NULL
	THEN
		LET d_parent = ui.Interface.GetRootNode()
	END IF

	### Check if matching class, attribute matches value ###
	### %%% BUG - MATCHES on STRING causes MemFault ###
	LET p_nodeValue = d_parent.getAttribute(p_attrib)
	LET p_nodeTag = d_parent.getTagName()
	IF p_nodeTag MATCHES p_class
		AND p_nodeValue MATCHES p_value
	THEN
		RETURN d_parent
	END IF

	### OK, then check the kids ###
	LET d_parent = d_parent.getFirstChild()
	WHILE d_parent IS NOT NULL

		LET d_child = fgx_FindNode(d_parent, p_class, p_attrib, p_value)
		IF d_child IS NOT NULL
		THEN
			RETURN d_child
		END IF

		LET d_parent = d_parent.GetNext()
	END WHILE

	RETURN NULL

END FUNCTION
# see mrkdwn1.per
#where p_colname = formonly.curr
#      p_attrib = "text"
#      p_value = "CURR"
FUNCTION fgx_SetTableColumn(p_colname, p_attrib, p_value)

	DEFINE
		p_colname	STRING,
		p_attrib	STRING,
		p_value		STRING,
		d_window	ui.Window,
		d_parent	om.DomNode,
		d_node		om.DomNode,
		d_node2		om.DomNode

	CALL ui.Window.getCurrent()
	RETURNING d_window
	IF d_window IS NOT NULL THEN
		CALL d_window.getNode()
		RETURNING d_parent
		CALL fgx_FindNode(d_parent,"TableColumn","colName",p_colname)
		RETURNING d_node
		IF d_node IS NOT NULL THEN
			CASE
			WHEN p_attrib = "hidden"
				# need to set the hidden attribute of the TableColumn to 
				# hide / unhide the column
				CALL d_node.setAttribute("hidden", p_value)
			WHEN p_attrib = "text"
				IF p_value IS NULL THEN
					LET p_value = " "
				END IF
				CALL d_node.setAttribute("text",p_value)
				RETURN
			END CASE
			CALL d_node.getFirstChild()
			RETURNING d_node2
			IF d_node2 IS NOT NULL THEN
				CALL d_node2.setAttribute(p_attrib,p_value)
			END IF
		END IF
	END IF
END FUNCTION

FUNCTION is_lock()
	DEFINE
		p_display			STRING

	IF status < 0 THEN
		IF status = -246 OR 
			status = -244 THEN
			LET p_display =  "Cannot read record that is locked by another user "
			CALL messagebox(p_display,2)				#gxx
		ELSE
			CALL err_print(status)
		END IF
	END IF
	RETURN
END FUNCTION
#rxx >>
################################################################################
#	stktake_setpasswd - set up password											   #
################################################################################
FUNCTION stktake_setpasswd()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("stocktake") THEN
		CALL stktake_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "stocktake"
			CALL stktake_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = stktake_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL stktake_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT stktake_validpw("stocktake",p_passwd) THEN		#not found
				CALL stktake_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT stktake_validpw("stocktake",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (stktake_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION stktake_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	stktake_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION stktake_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
			 #gxx >>
        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (stktake_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION stktake_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION data_setpasswd()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("data") THEN
		CALL data_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "data"
			CALL data_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = data_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL data_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT data_validpw("data",p_passwd) THEN		#not found
				CALL data_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT data_validpw("data",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (data_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION data_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	data_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION data_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
			 #gxx >>
        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (data_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION data_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION data_setpasswd2()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("data2") THEN
		CALL data_getpasswd2("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "data2"
			CALL data_getpasswd2("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = data_updpasswd2("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL data_getpasswd2("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT data_validpw2("data2",p_passwd) THEN		#not found
				CALL data_getpasswd2("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT data_validpw2("data2",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (data_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION data_updpasswd2(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	data_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION data_getpasswd2(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
			 #gxx >>
        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (data_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION data_validpw2(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION gp_version()
	DEFINE
			p_option	CHAR(20),
			p_msg		CHAR(150)

	LET p_msg = "\nVersion and revision id for",
				"\nthis program is - ||",
				g_version CLIPPED,"|"
	CALL messagebox(p_msg,1)				

END FUNCTION
FUNCTION data_setpasswd3()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("data3") THEN
		CALL data_getpasswd3("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "data3"
			CALL data_getpasswd3("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = data_updpasswd3("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL data_getpasswd3("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT data_validpw3("data3",p_passwd) THEN		#not found
				CALL data_getpasswd3("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT data_validpw3("data3",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (data_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION data_updpasswd3(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	data_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION data_getpasswd3(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
			 #gxx >>
        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (data_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION data_validpw3(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION recv_setpasswd()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("recv") THEN
		CALL recv_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "recv"
			CALL recv_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = recv_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL recv_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT recv_validpw("recv",p_passwd) THEN		#not found
				CALL recv_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT recv_validpw("recv",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (recv_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION recv_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	recv_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION recv_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT

        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (recv_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION recv_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bsr_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION bsr_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT

        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT

		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bsr_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION bsr_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_bsrpassword(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		display "password: ", s_bsrpa.bnkpa_password ," ", p_passwd 
		IF s_bsrpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
FUNCTION bsr_setpasswd()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_bsrpassword("bsr") THEN
		CALL bsr_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_bsrpa.bnkpa_password = p_passwd
			LET s_bsrpa.bnkpa_user = "bsr"
			CALL bsr_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_bsrpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = bsr_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL bsr_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT bsr_validpw("bsr",p_passwd) THEN		#not found
				CALL bsr_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT bsr_validpw("bsr",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
FUNCTION bsr_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_bsrpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
#	no_password - validate entered password                                    #
################################################################################
FUNCTION no_bsrpassword(p_user)

	DEFINE
			p_user			LIKE bnk_password.bnkpa_user

	SELECT	*
	INTO	s_bsrpa.*
	FROM	bnk_password
	WHERE	bnkpa_user = p_user
	
	IF status = NOTFOUND THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_password) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sku_setpasswd()
	DEFINE
			p_option		STRING,
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password("sku") THEN
		CALL sku_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_custpa.bnkpa_password = p_passwd
			LET s_custpa.bnkpa_user = "sku"
			CALL sku_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_custpa.bnkpa_password THEN
					LET p_option =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_option,1)				
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = sku_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL sku_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT sku_validpw("sku",p_passwd) THEN		#not found
				CALL sku_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT sku_validpw("sku",p_passwd) THEN		#not found
						LET p_option =
							"\nInvalid password",
							"\nSee Sysytem Administrator"
						CALL messagebox(p_option,1)				
						LET p_retstat = FALSE
					ELSE
						LET p_retstat =TRUE
					END IF
				ELSE
					LET p_retstat = FALSE
				END IF
			ELSE
				LET p_retstat = TRUE
			END IF
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sku_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
################################################################################
#	bnk_updpasswd - save entered password                                      #
################################################################################
FUNCTION sku_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_custpa.*)
		LET p_status = status
	END CASE

	IF p_status = 0 THEN
		COMMIT WORK
		LET p_retstat = TRUE
	ELSE
		ROLLBACK WORK
		LET p_retstat = FALSE
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	sku_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION sku_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	 ATTRIBUTE(TEXT="Password",STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (UNDERLINE)

	LET p_passwd = "" 
	OPTIONS INPUT NO WRAP 
	INPUT BY NAME p_passwd WITHOUT DEFAULTS
		ATTRIBUTE(INVISIBLE)
	
		AFTER INPUT
			IF p_passwd IS NULL
			THEN
				LET p_status = FALSE
				ERROR "no password entered"
			ELSE
				LET p_status = TRUE
			END IF	 

		ON KEY (F10, INTERRUPT)
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
			 #gxx >>
        ON ACTION exit
            ERROR "no password entered"
            LET p_status = FALSE
            EXIT INPUT
        #gxx <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (sku_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	bnk_validpw - check for old password                                       #
################################################################################
FUNCTION sku_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_password(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_custpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (bnk_validpw) @@@@@@@@@@@@@@@@
################################################################################
#Check for program running
FUNCTION close_if_process_running(p_param,p_prog)
	DEFINE 		p_param 			STRING,
				p_string			STRING,
				p_pts				STRING,
				p_prog				STRING
	DEFINE 		ret_val INTEGER 

	RUN SFMT('[ $(ps -f -u $(id -u) | grep -i "%1" | grep -v grep | wc -l) -gt 1 ] && { exit 0; }  || { exit 1; } ',p_param)
	RETURNING ret_val

	#RUN SFMT('python /seed/fastpos/ps-hostname.py -v %1',p_param)
	#RUN SFMT('/seed/fastpos/ps-hostname.py -v %1',p_param)
    #RETURNING ret_val

display "param: ",p_param, " ",ret_val, " ",p_pts

	DISPLAY SFMT("Is this process running? %1 RETVAL: %2 ",p_param,ret_val)
	IF ret_val == 0 THEN
	##IF ret_val == 256 THEN
		# running
		#R01 CALL messagebox(SFMT("This program (%1) can only be running once. ",p_param),3)
		CALL messagebox(SFMT("This program (%1) can only be running once. ",p_prog),3)
		EXIT PROGRAM
	END IF 
END FUNCTION
FUNCTION close_if_process_runningx(p_param,p_prog,p_pts)
	DEFINE 		p_param 			STRING,
				p_string			STRING,
				p_pts				STRING,
				p_prog				STRING
	DEFINE 		ret_val INTEGER 

	#RUN SFMT('[ $(ps -f -u $(id -u) | grep -i "%1" | grep -v grep | wc -l) -gt 1 ] && { exit 0; }  || { exit 1; } ',p_param)
	LET p_string = SFMT('[ $(ps -f -u $(id -u) | grep -i "%1" | grep -i "%2" | grep -v grep | wc -l) -gt 1 ] && { exit 0; }  || { exit 1; } ',p_param,p_pts)
display p_string
	##RUN SFMT('[ $(ps -f -u $(id -u) | grep -i "%1" | grep $p_pts | grep -v grep | wc -l) -gt 1 ] && { exit 0; }  || { exit 1; } ',p_param)
	RUN SFMT('[ $(ps -f -u $(id -u) | grep -i "%1" | grep -i "%2" | grep -v grep | wc -l) -gt 1 ] && { exit 0; }  || { exit 1; } ',p_param,p_pts)
	RETURNING ret_val

	#RUN SFMT('python /seed/fastpos/ps-hostname.py -v %1',p_param)
	#RUN SFMT('/seed/fastpos/ps-hostname.py -v %1',p_param)
    #RETURNING ret_val

display "param: ",p_param, " ",ret_val, " ",p_pts

	#DISPLAY SFMT("Is this process running? %1 RETVAL: %2 ",p_param,ret_val)
	DISPLAY SFMT("Is this process running? %1 RETVAL: %2 %3 ",p_param,ret_val, p_pts)
	IF ret_val == 0 THEN
	##IF ret_val == 256 THEN
		# running
		#R01 CALL messagebox(SFMT("This program (%1) can only be running once. ",p_param),3)
		CALL messagebox(SFMT("This program (%1) can only be running once. ",p_prog),3)
		EXIT PROGRAM
	END IF 
END FUNCTION
FUNCTION get_check_digit(p_frmstore,p_tostore,p_trans_id)
	DEFINE
			p_frmstore				CHAR(3),
			p_tostore				CHAR(3),
			p_trans_id				CHAR(6),
			p_string				CHAR(12),
			p_string1				CHAR(80),
			p_result				CHAR(2),
			p_result1				INTEGER,
			p_result2				INTEGER,
			p_result3				INTEGER,
			p_digit					INTEGER,
			p_retdigit				CHAR(1),
			p_multiply				CHAR(2),
			idx,jdx					INTEGER

	#weighting factor, ie 1,2
	LET p_multiply[1] = "1"
	LET p_multiply[2] = "2"
	LET p_string1 = " "
	LET p_string = p_frmstore,p_tostore,p_trans_id
	LET jdx = 0
	FOR idx = 1 TO LENGTH(p_string)
		LET jdx = jdx + 1
		IF jdx > 2 THEN
			LET jdx = 1
		END IF
		LET p_result =  p_string[idx] * p_multiply[jdx]
		LET p_string1 = p_string1 CLIPPED,p_result CLIPPED
	END FOR
	LET p_string1 = p_string1 CLIPPED
	LET p_result1 = 0
	FOR idx = 1 TO LENGTH(p_string1)
		LET p_result1 = p_result1 + p_string1[idx] 
	END FOR
	#next highest multiple of 10
	LET p_result2 = p_result1 / 10
	LET p_result3 = (p_result2+1) * 10
	LET p_digit = p_result3 - p_result1
	IF p_digit >= 10 THEN
		LET p_digit = 0
	END IF
	LET p_retdigit = p_digit USING "&"
	RETURN p_retdigit
END FUNCTION
#R02 >>
FUNCTION func_timed_out()

    DEFINE l_message        CHAR(200)

    IF g_idle_time <> 0 THEN

        ## rollback uncomitted transactions, if no transaction ignore the error
        WHENEVER ERROR CONTINUE
                ROLLBACK WORK
        WHENEVER ERROR STOP

        EXIT PROGRAM

    END IF

    RETURN

END FUNCTION {func_timed_out}

FUNCTION gp_create_so(p_type,p_fmt)
	DEFINE
			p_auto			RECORD LIKE autonum.*,
			p_min			INTEGER,
			p_max			INTEGER,
			p_type			CHAR(20),
			p_fmt			CHAR(20),
			p_query			CHAR(200),
			p_status		INTEGER,
			p_retstring		CHAR(20)

	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT
	IF NOT s_cursoropen THEN
		LET p_query=
			" SELECT	* ",
			" FROM	 	autonum ",
			" WHERE		type = ? ",
			" AND		autonum = ? ",
			" FOR UPDATE "
		PREPARE s_min1 FROM p_query
		DECLARE c_min1 CURSOR WITH HOLD FOR s_min1
		LET s_cursoropen=TRUE
	END IF

	WHILE TRUE
		SELECT	MIN(autonum)
		INTO	p_min
		FROM	autonum
		WHERE	type=p_type
		
		OPEN c_min1 USING p_type,p_min
		FETCH c_min1 INTO p_auto.*
		LET p_status=status
		IF p_status != NOTFOUND THEN
			#CLOSE c_min
			EXIT WHILE
		END IF
	END WHILE
	SELECT	MAX(autonum)
	INTO	p_max
	FROM	autonum
	WHERE	type=p_type
	IF p_min=p_max THEN
		UPDATE	autonum
		SET		autonum = autonum + 1
		WHERE 	type=p_type
		AND		autonum=p_min
	ELSE
		DELETE FROM autonum 
		WHERE 	type=p_type
		AND		autonum=p_min
	END IF
	CLOSE c_min1
	LET p_retstring = p_auto.autonum USING p_fmt
	SET LOCK MODE TO WAIT 
	WHENEVER ERROR STOP
	RETURN p_retstring
END FUNCTION
################################################
{
IMPORT os

SCHEMA seed

GLOBALS
DEFINE
    g_pgm   CHAR(20),
    g_user  CHAR(20),
    g_dbname	CHAR(20),    
    g_os    STRING,    
    g_cfidx INTEGER,
    g_cflist DYNAMIC ARRAY OF RECORD
        cf_key          LIKE ut_config.cf_key,
        cf_value        LIKE ut_config.cf_value
    END RECORD

END GLOBALS

DEFINE  
     s_init       INTEGER,
     s_errpath       CHAR(200),
     s_separator     CHAR(2),
     s_errdestin     CHAR(256)

################################################################################    
FUNCTION gp_InitEnv()

END FUNCTION
################################################################################    
FUNCTION getconfig (p_option)

        DEFINE
                p_cf            RECORD LIKE ut_config.*,
                p_option        LIKE ut_config.cf_key,
                p_value         LIKE ut_config.cf_value,
                p_key           STRING,
                p_stat          INTEGER,
                p_ovrok         INTEGER,        # Override of config allowed
                p_source        CHAR,           # Config source C, U, or E  
                idx                     INTEGER



        INITIALIZE p_source TO NULL

    IF FGL_GETENV("UTCACHECONFIGS") MATCHES "[Yy]*" THEN
        LET p_stat = TRUE
            FOR idx = 1 to g_cflist.getLength()
                IF g_cflist[idx].cf_key = p_option THEN
                LET p_value = g_cflist[idx].cf_value
                        LET p_stat = FALSE
                END IF
            END FOR

        IF p_stat = FALSE THEN
            RETURN p_value
        END IF
    END IF

        # Check for the configuration value in the environment
        LET p_value = fgl_getenv(p_option)
                IF p_value IS NOT NULL
                THEN
                        LET p_source = "E"
                        LET p_value = p_value CLIPPED
                END IF


	display "lib db: ", g_DbName 

        IF p_source IS NULL
        THEN
                SELECT  *
                INTO    p_cf.*
                FROM    ut_config
                WHERE   cf_key = p_option

                IF status = NOTFOUND THEN
                        LET p_value = "!", p_option
                ELSE
                        LET p_value = p_cf.cf_value
                END IF

                LET p_source = "C"
                LET p_value = p_value CLIPPED
        END IF

        LET p_value = gp_gdSubstitution(p_value)
        # Add second call to work around if config contains 2 variables
        # eg. ACCT and DB
        LET p_value = gp_gdSubstitution(p_value)
    # only check through array if we are not cached configs
    # as if they are cached we are already done this step
        LET p_stat = TRUE
    IF FGL_GETENV("UTCACHECONFIGS") MATCHES "[Nn]*"
        OR FGL_GETENV("UTCACHECONFIGS") IS NULL THEN
        FOR idx = 1 to g_cflist.getLength()
                IF g_cflist[idx].cf_key = p_option THEN
                LET p_value = g_cflist[idx].cf_value
                        LET p_stat = FALSE
                END IF
        END FOR
    END IF

        IF p_stat THEN
                LET g_cfidx = g_cfidx + 1
                LET g_cflist[g_cfidx].cf_key = p_option
                IF p_source = "C"
                THEN
                        LET g_cflist[g_cfidx].cf_value = p_value
                ELSE
                        IF p_source = "E"
                        THEN
                                LET g_cflist[g_cfidx].cf_value = "(ENV) ",p_value CLIPPED
                        ELSE
                                LET g_cflist[g_cfidx].cf_value = "(USER) ",p_value CLIPPED
                        END IF
                END IF
        END IF

        RETURN p_value

END FUNCTION
################################################################################
#
#   gp_AbortPrompt  Prompt user for confirmation to abort
#
################################################################################

################################################################################
#
#   gp_Terminate    Perform cleanup when TERMINATE signal received
#
FUNCTION gp_Terminate()
    CALL gp_CleanUp("TERMINAT")

END FUNCTION
################################################################################
#
#   gp_CleanUp  Preform program cleanup before abnormal exit 
#   (exit signal or window close)
#

FUNCTION gp_CleanUp(p_mode)
    DEFINE
        p_err       CHAR(80),
        p_mode      CHAR(8)


    CASE
    WHEN p_mode = "CLOSE"
        LET p_err = g_pgm CLIPPED, ":User ", g_user CLIPPED,
                    " aborted this program - ", p_mode CLIPPED
    WHEN p_mode = "TERMINAT"
        LET p_err = g_pgm CLIPPED,
                ":Process has received TERMINATE signal - shutting down..."
    END CASE

    CALL err_log(p_err)

    WHENEVER ERROR CONTINUE
    ROLLBACK WORK
    EXIT PROGRAM(-1)

END FUNCTION
################################################################################
#
#   stridx  - returns the index of a string
#
################################################################################
FUNCTION    stridx( p_str, p_token)

    DEFINE
        p_str       CHAR(2000),
        p_token     CHAR(50),
        p_strsize   INTEGER,
        p_toksize   INTEGER,
        idx         INTEGER

    LET idx = 1
    LET p_toksize = LENGTH(p_token) - 1
    CASE
    WHEN LENGTH(p_token) = 0
        LET p_toksize = 0
    WHEN p_toksize < 0
        LET p_toksize = 1
    END CASE
    LET p_strsize = LENGTH(p_str)

    FOR idx = 1 TO p_strsize
        IF p_token = p_str[idx,(idx+p_toksize)] THEN
            RETURN idx
        END IF
    END FOR
    RETURN 0

END FUNCTION
################################################################################
#############################################################################
#
#!  gp_GetOS()          Gets the OS. If g_OS is NULL then call gp_SetOS()
#
#############################################################################
FUNCTION gp_GetOS()

    IF g_OS IS NULL THEN
        CALL gp_SetOS()
    END IF

    RETURN g_OS

END FUNCTION
#############################################################################
#
#!      gp_SetOS()                      Sets the OS for the current OS
#
#############################################################################
FUNCTION gp_SetOS()

    LET g_OS = FGL_GETENV("UTOS")

    IF g_OS IS NULL OR g_OS = ""
    THEN
        LET g_OS = "UNIX"
    END IF

END FUNCTION
#############################################################################
#
#!      gp_ListSep                      Returns (path) List Separator for current environment
#
#############################################################################
FUNCTION gp_ListSep()

        CASE
        WHEN gp_GetOS() = "W2K"
                RETURN ";"
        OTHERWISE
                RETURN ":"
        END CASE

END FUNCTION
#############################################################################
FUNCTION gp_GetKey()

        RETURN gpx_KeyChar(fgl_getkey())

END FUNCTION




FUNCTION gp_PromptKey()

        RETURN gpx_KeyChar(fgl_getkey())

END FUNCTION




FUNCTION gpx_KeyChar(p_key)

        DEFINE
                p_key           INTEGER,
                p_char          CHAR(12)

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
#############################################################################
#############################################################################
#
#!      gp_PathFind                     Find full path of a file by searching through
#                                               a list of paths
#
#       CALL gp_PathFind(p_paths, p_file)
#
#       Where:
#               p_pathList              List of PATHS or an environment variable
#                                               containing a list of PATHS separated by the
#                                               OS path separator (: Unix, ; Windows)
#               p_file                  File name to find
#
#       Returns:
#               p_filePath              Path of file if found, otherwise NULL
#
#############################################################################
FUNCTION gp_PathFind(p_pathList, p_file)

        DEFINE
                p_pathList      STRING,
                p_file          STRING,

                o_tok           base.StringTokenizer,
                p_filePath      STRING,
                p_listSep       STRING,
                p_pathSep       STRING,
                p_cmd           STRING,
                p_status        INTEGER


        LET p_listSep = gp_listSep()
        LET p_pathSep = gp_pathSep()

        ### Is it an envar or path list? ###
        CASE
        WHEN p_pathList IS NULL OR p_pathList MATCHES "*[./\\]*"
                EXIT CASE
        OTHERWISE
                LET p_pathList = fgl_getenv(p_pathList)
        END CASE
        IF p_pathList IS NULL
        THEN
                LET p_pathList = "."
        END IF



        #
        # Code below to be used with later Genero version
        #

        ### OK now hunt for the first file that matches ###
        LET o_tok = base.StringTokenizer.create(p_pathList,  p_listSep)
        WHILE o_tok.hasMoreTokens()
                LET p_filePath = o_tok.nextToken() || p_pathSep || p_file
                IF os.Path.readable(p_filePath)
                THEN
                        EXIT WHILE
                END IF

                LET p_filePath = NULL
        END WHILE


        ### cleanup and return ###
        RETURN p_filePath

END FUNCTION
#############################################################################
#
#!      gp_PathSep  Returns the Path Separator for current environment
#
#############################################################################
FUNCTION gp_PathSep()

        CASE
        WHEN gp_GetOS() = "W2K"
                RETURN "\\"
        WHEN gp_GetOS() = "MAC"
                RETURN ":"
        OTHERWISE
                RETURN "/"
        END CASE

END FUNCTION
#############################################################################
#
#       parse     common parse routine shares by brun and crun
#       
################################################################################
FUNCTION parse (p_reqcmd)

DEFINE
        p_reqcmd        STRING

        RETURN p_reqcmd

END FUNCTION
################################################################################
#
#       brun    - backgroud crun request
#
#
################################################################################
FUNCTION brun(p_reqcmd)

    DEFINE
        p_reqcmd STRING

        RUN parse(p_reqcmd) WITHOUT WAITING
        
END FUNCTION
################################################################################
#
#       crun    - run program in foreground
#
#
################################################################################
FUNCTION crun(p_reqcmd)

    DEFINE
        p_reqcmd STRING,
        p_retstat INTEGER

        RUN parse(p_reqcmd) RETURNING p_retstat
        RETURN p_retstat
        
END FUNCTION
################################################################################
################################################################################
#
#       popen   - Open a pipe to/from command
#
#       CALL popen(p_reqcmd, p_stdin, p_mode) 
#               RETURNING p_retstat, p_stdout
#
#       The parameter p_stdin contains the data to be piped to the command. Only
#       valid for mode flags of w or u.
#
#       The mode flags can be one of:
#               r : For Read Only. 
#               w : For Write Only. 
#               u : For Read and Write.
#
#       Note: The u mode does not appear to work. Not sure if this is due to 
#       buffered io or a 4Js bug. So u mode is currently not supported.
#
################################################################################
FUNCTION popen(p_reqcmd, p_stdin, p_mode)

DEFINE
        p_reqcmd        CHAR(500),                                                                  
        p_stdin         STRING,
        p_mode          CHAR,
        p_retstat       INTEGER,
        p_runcmd        CHAR(500),
        p_stdout        STRING,
        p_scratch       STRING,
        p_pipe          base.Channel

        LET p_runcmd = p_reqcmd

        LET p_pipe = base.Channel.create()
        CALL p_pipe.setDelimiter("")

        CALL p_pipe.openPipe(p_runcmd,p_mode)

        IF p_mode = "w"
        OR p_mode = "u"
        THEN
            CALL p_pipe.write([p_stdin])
        END IF

        IF p_mode = "r"
        OR p_mode = "u"
        THEN
                WHILE p_pipe.read([p_scratch])
                        LET p_stdout = p_stdout.append(p_scratch)
                        LET p_stdout = p_stdout.append("\n")
                END WHILE
        END IF

        RETURN p_stdout

END FUNCTION
################################################################################
#
#       basename        - strip the leading directory path
#
################################################################################
FUNCTION basename(p_name)

DEFINE
        p_name          CHAR(100),
        p_newname       CHAR(100),
        x                       INTEGER,
        y                       INTEGER,
        p_len           INTEGER

        LET p_len = LENGTH(p_name)
        LET y = 1
        FOR x = p_len TO 1 STEP - 1
                IF p_name[x,x] = "/" THEN
                        LET y = x + 1
                        EXIT FOR
                END IF
        END FOR
        LET p_newname = p_name[y,p_len]

        RETURN p_newname

END FUNCTION
#############################################################################
#
#       err_log.4gl -   Write to usual Informix error log and also to a personal 
#                                       error log.
#
#       SYNOPSIS:       CALL err_log(p_text) 
#
#       RETURNS:        nothing
#               
##############################################################################
FUNCTION err_log(p_text)

DEFINE  p_text          CHAR(200),
                p_file          CHAR(20),
                p_logLevel      CHAR(30),
                p_errstr        CHAR(200),
                p_errdestin     CHAR(256),
                p_datetime      DATETIME YEAR TO FRACTION(3),
                p_user          CHAR(20),
                p_query         CHAR(256),
                p_session       INTEGER,
                o_sessionlog base.Channel

        # Get the system logging type
        # (NORMAL,USER,USER_SESSION)
        LET p_logLevel = getconfig("UTERRLOGLEVEL")

        # Failsafe - can turn off and return to old style logging
        # if UTERRLOGLEVEL is set to NONE
        IF p_logLevel = "NONE"
        AND NOT s_init THEN
                CALL ERRORLOG(p_text)
                RETURN
        END IF

        IF p_logLevel MATCHES "!*" THEN
                LET p_logLevel = "NORMAL"
        END IF

        IF g_user IS NULL THEN
                LET g_user = fgl_getenv("LOGNAME")
        END IF

        IF g_user IS NULL THEN
                LET g_user = "unknown_user_ID"
        END IF

        LET p_query =
              "SELECT dbinfo('sessionid') FROM systables"

        PREPARE p_getSession FROM p_query
        DECLARE c_getSession CURSOR FOR p_getSession

        OPEN c_getSession
        FETCH c_getSession INTO p_session
        CLOSE c_getSession

        # Get the path seperator
        IF gp_GetOS() = "NT"
        OR gp_GetOS() = "W2K" THEN
                LET s_separator = "\\"
        ELSE
                LET s_separator = "/"
        END IF

        # Get the path for logging
        LET s_errpath = getconfig("UTERRLOGPATH")

        IF s_errpath MATCHES "!*" THEN
                LET s_errpath = s_separator CLIPPED,"tmp",s_separator
        ELSE
                LET s_errpath = s_errpath CLIPPED,s_separator
        END IF

        CASE
        WHEN p_logLevel = "NONE"
               LET p_file = "ERRLOG"
        WHEN p_logLevel = "NORMAL"
                LET p_file = "ERRLOG"
        WHEN p_logLevel = "USER"
                LET p_file = g_user CLIPPED,"ERR.log"
        WHEN p_logLevel = "USER_SESSION"
                LET p_file = g_user CLIPPED,p_session USING "<<<<<<<<<<"
                LET p_file = p_file CLIPPED,"ERR.log"
        END CASE

        LET p_errdestin = s_errpath CLIPPED, p_file

        # Now format the contents of the error log file, open the file
        # write the message and close the file.


        LET p_datetime = CURRENT
        LET p_errstr = p_datetime CLIPPED,"|",g_pgm CLIPPED,"|",g_user CLIPPED,"|",
                                        p_session USING "<<<<<<<<<<","|"
        LET p_text = "|",p_text CLIPPED,"|"

        IF NOT s_init THEN
                LET o_sessionlog = base.Channel.create()
                CALL o_sessionlog.openFile(p_errdestin,"a")
                CALL o_sessionlog.setDelimiter("")
                CALL o_sessionlog.write(p_errstr)
                CALL o_sessionlog.write(p_text)
                CALL o_sessionlog.close()
        ELSE
                LET s_errdestin = p_errdestin
        END IF

        # OK everybody let's call it a wrap...
        RETURN


END FUNCTION
################################################################################
#
#	FUNCTION	gp_gdSubstitution: substition of %VARIABLE% / %VARIABLE 
#				proper value for string
#
################################################################################
FUNCTION gp_gdSubstitution(p_string)
	DEFINE
		p_string	STRING,
		p_sql		STRING,
		p_key		STRING,
		p_value		STRING,
		p_word		STRING,
		p_words		DYNAMIC ARRAY OF STRING,
		p_idx		INTEGER,
		p_jdx		INTEGER,
		p_kdx		INTEGER,
		p_ldx		INTEGER,
		p_mdx		INTEGER,
		p_slash		INTEGER,					# forward / back slash found
		p_start		INTEGER,
		p_end		INTEGER,
		p_wordcount	INTEGER,
		p_offset	INTEGER,
		p_length	INTEGER

	CALL p_words.clear()

	LET p_string = p_string.trim()
	
	LET p_length = p_string.getLength()
	LET p_wordcount = 0
	LET p_start = 1
	FOR p_idx = 1 TO p_length
		IF p_string.getCharAt(p_idx) = " " THEN
			LET p_word = p_string.subString(p_start, p_idx - 1)
			LET p_word = p_word.trim()
			IF p_word NOT MATCHES "* *" THEN
			LET p_wordcount = p_wordcount + 1
			LET p_words[p_wordcount] = p_word
			LET p_start = p_idx + 1
			END IF
		END IF
	END FOR

	# last word
	LET p_wordcount = p_wordcount + 1
	LET p_word = p_string.subString(p_start, p_length)
	LET p_words[p_wordcount] = p_word

	FOR p_idx = 1 TO p_wordcount
		LET p_word = p_words[p_idx]

		LET p_length = p_word.getLength()
		LET p_jdx = p_word.getIndexOf('%', 1)
		IF p_jdx > 0 THEN
			# try to find the token
			LET p_start = p_jdx + 1
			LET p_end = 0
			FOR p_kdx = p_start TO p_length
				IF p_word.getCharAt(p_kdx) = "%" THEN
					CASE
					WHEN (p_kdx - p_start) = 0
						# previous % are a wildcard
						LET p_jdx = p_jdx + 1
						LET p_start = p_kdx + 1
					OTHERWISE
						LET p_end = p_kdx - 1
						# check if we have a parameter to replace
						LET p_key = p_word.subString(p_start, p_end)
						LET p_value = gp_gdSubstituteKey(p_key)

						IF p_value IS NOT NULL THEN
							LET p_offset = 2
							# adjust offset if value has period / : and
							# remaining value of word starts with period / :
							LET p_ldx = p_value.getLength()
							IF (p_value.getCharAt(p_ldx) = "."
							OR p_value.getCharAt(p_ldx) = ":")
							AND (p_word.getCharAt(p_end + p_offset) = "."
							OR p_word.getCharAt(p_end + p_offset) = ":")
							THEN
								LET p_offset = 3
							END IF

							LET p_word = 
								p_word.substring(1, p_jdx - 1),
								p_value.trim(),
								p_word.subString(p_end + p_offset, p_length)
						END IF
					END CASE
				END IF
			END FOR

			IF p_start > 0 AND p_end = 0 THEN
				LET p_slash = FALSE
				LET p_key = p_word.subString(p_start, p_length)
				# key may be separated by period / colon. 
				# If so, only want text up
				# to first period for the key
				IF (p_key.getIndexOf('.', 1) > 0 
				OR p_key.getIndexOf(':', 1) > 0
				OR p_key.getIndexOf('/', 1) > 0
				OR p_key.getIndexOf('\\', 1) > 0)
				THEN
					CASE
					WHEN p_key.getIndexOf(".", 1) > 0 
						LET p_ldx = p_key.getIndexOf(".", 1) 
						EXIT CASE
					WHEN p_key.getIndexOf(":", 1) > 0
						LET p_ldx = p_key.getIndexOf(":", 1) 
						EXIT CASE
					WHEN p_key.getIndexOf("/", 1) > 0
						LET p_slash = TRUE
						LET p_ldx = p_key.getIndexOf("/", 1) 
						EXIT CASE
					WHEN p_key.getIndexOf("\\", 1) > 0
						LET p_slash = TRUE
						LET p_ldx = p_key.getIndexOf("\\", 1) 
						EXIT CASE
					END CASE

					LET p_key = p_key.subString(1, p_ldx - 1)
				ELSE
					LET p_end = p_word.getLength()
				END IF
				LET p_value = gp_gdSubstituteKey(p_key)

				IF p_value IS NOT NULL THEN
					# if forward / back slash found set offset to 1
					IF p_slash THEN
						LET p_offset = 1
					ELSE
						LET p_offset = 2
					END IF

					# adjust offset if value has period / : and
					# remaining value of word starts with period / :
					LET p_mdx = p_value.getLength()
					IF (p_value.getCharAt(p_mdx) = "."
					OR p_value.getCharAt(p_mdx) = ":")
					AND (p_word.getCharAt(p_end + p_offset) = "."
					OR p_word.getCharAt(p_end + p_offset) = ":")
					THEN
						LET p_offset = 3
					END IF

					LET p_word = 
						p_word.substring(1, p_jdx - 1),
						p_value.trim(),
						p_word.substring(p_ldx + p_offset, p_length)
				END IF
			END IF
			LET p_sql = p_sql.trim(), " ", p_word.trim()
		ELSE
			LET p_sql = p_sql.trim(), " " , p_word.trim()
		END IF
	END FOR

	RETURN p_sql.trim()

END FUNCTION
################################################################################
#
#       FUNCTION        gp_gdSubstituteKey: Return value dependant on key
#                               Returned value may be result of function call or
#                               environment variable
#
################################################################################
FUNCTION gp_gdSubstituteKey(p_key)
    DEFINE
        p_key   STRING,
        p_value STRING

    INITIALIZE p_value TO NULL
    LET p_key = UPSHIFT(p_key)

    CASE
    WHEN p_key = "ACCT"
        LET p_value = FGL_GETENV("ACCT")
    WHEN p_key = "DB"
        LET p_value = g_dbname
    END CASE

    RETURN p_value

END FUNCTION
################################################################################
}


        
                

