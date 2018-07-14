DATABASE seed
GLOBALS
	DEFINE
		s_maxidx				INTEGER,
		s_dspsize				INTEGER,
		s_arrsize				INTEGER,
		g_ref 	RECORD 
	   				#key_ref      CHAR(15),
	   				key_ref      CHAR(20),
	   				key_desc     CHAR(50)
		            END RECORD,
	 	ssa_ref ARRAY[10000] OF RECORD
	   				##key_ref            char(15),
	   				key_ref            char(20),
	   				key_desc           char(50)
		            END RECORD
END GLOBALS

FUNCTION gp_lookup1(p_refid,p_lkref1)

	DEFINE 
		    #gxx >>
            p_scrnhdr           CHAR(80),
            #gxx <<
			p_select			CHAR(100),
			p_lookup			RECORD LIKE gp_lookup.*,
			p_refid				CHAR(20),
			p_lkref1			CHAR(80),
			p_lkref2			CHAR(80),
			p_lkref3			CHAR(80),
			p_desc				CHAR(30),
			p_query				CHAR(1000),
			p_title				CHAR(80),
    		p_msglns 			CHAR(80),
			p_row,p_col,
			idx,sidx			INTEGER,
			p_retstat			INTEGER

	
	LET s_dspsize = 10
	LET s_arrsize = 10000
	LET p_row = 2
	LET p_col = 10
	LET p_query =
		" SELECT 	* ",
		" FROM 		seedhk:gp_lookup ",
		" WHERE 	gp_refid = ? "

	PREPARE s_1 FROM p_query
	DECLARE c_1 CURSOR FOR s_1
	OPEN c_1 USING p_refid
	WHILE TRUE
		FETCH c_1 INTO p_lookup.*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
	END WHILE

	LET p_query = p_lookup.gp_select1 CLIPPED,	
	              " ", p_lookup.gp_select2 CLIPPED,	
	               " ",p_lookup.gp_select3 CLIPPED,	
	               " ",p_lookup.gp_select4 CLIPPED,	
	               " ",p_lookup.gp_select5 CLIPPED,	
	               " ",p_lookup.gp_select6 CLIPPED,
				   " ",p_lookup.gp_orderby CLIPPED
	LET p_query = p_query CLIPPED
display p_query
	PREPARE s_2 FROM p_query
	DECLARE c_2 CURSOR FOR s_2

	INITIALIZE g_ref.* TO NULL

	FOR idx = 1 TO s_arrsize
		INITIALIZE ssa_ref[idx].* TO NULL
	END FOR

	#gxx >>
    LET p_scrnhdr = "List of ", p_refid CLIPPED
    #gxx >>
    OPEN WINDOW w_lookup at p_row,p_col
    WITH FORM "gp_lookup"
	ATTRIBUTE(TEXT=p_scrnhdr,STYLE="naked")
	#gxx <<

	IF p_lkref1 IS NOT NULL THEN
		OPEN c_2 USING p_lkref1
	END IF

	LET idx = 1
	FOREACH c_2 INTO g_ref.*
		LET ssa_ref[idx].* = g_ref.*
		LET idx = idx + 1
		IF idx > s_arrsize THEN
			ERROR "only first ",s_arrsize, " displayed"
			SLEEP 2
			EXIT FOREACH
		END IF
	END FOREACH
	LET s_maxidx = idx - 1
	CALL SET_COUNT(s_maxidx)
	DISPLAY ARRAY ssa_ref TO sc_lookup.*
	ATTRIBUTE(NORMAL)

		ON KEY (F1)
			MESSAGE ""
			LET idx = ARR_CURR()
			LET sidx = SCR_LINE()
			LET p_retstat = TRUE
			EXIT DISPLAY

		ON KEY (F10)
	   		LET p_retstat = FALSE

		#R01 >>
		ON ACTION action_f1
			MESSAGE ""
			LET idx = ARR_CURR()
			LET sidx = SCR_LINE()
			LET p_retstat = TRUE
			EXIT DISPLAY


		ON ACTION action_f3					#pgup

		ON ACTION action_f4					#pgdown

		ON ACTION action_f10
	   		LET p_retstat = FALSE
	   		EXIT DISPLAY

		AFTER DISPLAY
			MESSAGE ""
			LET idx = ARR_CURR()
			LET sidx = SCR_LINE()
			LET p_retstat = TRUE
			EXIT DISPLAY
		#R01 <<
	   	EXIT DISPLAY

	END DISPLAY
	CALL gp_dsplookup1()
	CLOSE WINDOW w_lookup
	IF p_retstat THEN
		RETURN ssa_ref[idx].key_ref, ssa_ref[idx].key_desc
	ELSE
		RETURN "",""
	END IF
END FUNCTION 
##########
FUNCTION gp_dsplookup1()
	DEFINE
            idx         INTEGER

    FOR idx = 1 TO s_dspsize 
        DISPLAY ssa_ref[idx].* TO sc_lookup[idx].*
        ATTRIBUTE(NORMAL)
    END FOR
    INITIALIZE g_ref.* TO NULL
    DISPLAY BY NAME g_ref.key_ref,
                    g_ref.key_desc
    ATTRIBUTE(NORMAL)
END FUNCTION
