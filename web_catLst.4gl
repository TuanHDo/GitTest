DATABASE seed
{@@@
Company         : Witchery Fashions Co. Pty. Ltd.
System          : Ramis - Retail Management Information System
Program Name    : rp_slsrnk1.4ge
Main Program    : (Yes - if main program)
                  (If main program list all modules in 
				  Compilation Specifications)
Module Name     : printerg.4gl
Function        : This program display printers
Module Files    : The following modules are called by this module
Compilation    
Specifications  : Sources
Other Sources			- NONE 
Forms           : printerList.per
Form Sources 			
Modification Log: Date	Reason for Modification        Programmer

R00	18apr05 td	  Initial Release in Genero version
				  Mod. Campaign - convert to Genero                      
@@@}
##	R01	12mar09	td		Change the method of copying filess to the local
##						C:\ drive

## To Get the Printer Name, and Printer Description
##
GLOBALS
    "r_globprt.4gl"
FUNCTION web_catLst(p_cat)
	DEFINE	p_cat			LIKE web_cat1.web_cat
	DEFINE lsi_j			SMALLINT 
	DEFINE lsi_sw			SMALLINT 
	define lsi_prt			SMALLINT 
	define lsi_count		SMALLINT
	define lsi_currow		SMALLINT 
	define lc_null			CHAR(1)
	define lr_catrec  		RECORD  LIKE web_cat.*

	define la_array		    ARRAY[500] of record
	   lineno				SMALLINT,
	   cat1					SMALLINT,
	   cat1_name			LIKE web_cat1.web_cat_name,
	   cat2					SMALLINT,
	   cat2_name			LIKE web_cat1.web_cat_name,
	   cat3					INTEGER,
	   cat3_name			LIKE web_cat1.web_cat_name
			END RECORD ,
		fa					STRING,
		p_status			CHAR(20),
	    p_bindir            CHAR(80),
        p_run               CHAR(80),
        p_runner            CHAR(80),
		s               	CHAR(10)

	let int_flag = false
	let quit_flag = false
	let lsi_sw = false
	let lsi_prt = 0
	let lsi_count = 0
	let lsi_currow = 0
	let lc_null = null
	INITIALIZE lr_catrec.* TO NULL

	FOR lsi_j = 1 to 500
		INITIALIZE la_array[lsi_j].* TO NULL
	END FOR

	OPTIONS INSERT KEY CONTROL-N,
        	DELETE KEY CONTROL-Z

	OPEN WINDOW cat_scrn1 
	WITH FORM "web_catLst"
 	ATTRIBUTES(STYLE="naked")

	SET ISOLATION TO DIRTY READ

	DECLARE c_1 CURSOR FOR  
		SELECT 	*
	  	FROM 	web_cat
		WHERE	web_cat1 = p_cat
	  	ORDER BY 1
	FOREACH c_1 INTO lr_catrec.*
		LET lsi_count = lsi_count + 1
		LET la_array[lsi_count].cat1 = lr_catrec.web_cat1
		LET la_array[lsi_count].cat2 = lr_catrec.web_cat2
		LET la_array[lsi_count].cat3 = lr_catrec.web_cat3

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat1_name 
		FROM	web_cat1
		WHERE	web_cat = lr_catrec.web_cat1

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat2_name 
		FROM	web_cat2
		WHERE	web_cat = lr_catrec.web_cat2

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat3_name 
		FROM	web_cat3
		WHERE	web_cat = lr_catrec.web_cat3
	END FOREACH

	CALL set_count(lsi_count)
	DISPLAY ARRAY la_array TO sc_catlst.*
--#	ATTRIBUTE(NORMAL)


		ON ACTION accept
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY

        ON ACTION cancel
	   		LET lsi_sw = TRUE
            EXIT DISPLAY

		AFTER DISPLAY
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY
    END DISPLAY

	CLOSE WINDOW cat_scrn1 

	IF lsi_sw = true
	THEn
		RETURN "","","","",""
	ELSE
		RETURN la_array[lsi_currow].cat1, la_array[lsi_currow].cat2, la_array[lsi_currow].cat2_name,
										  la_array[lsi_currow].cat3, la_array[lsi_currow].cat3_name
	END IF
END FUNCTION --- GetPrinter() ---
FUNCTION web_dwcatLst(p_cat)
	DEFINE	p_cat			LIKE web_cat1.web_cat
	DEFINE lsi_j			SMALLINT 
	DEFINE lsi_sw			SMALLINT 
	define lsi_prt			SMALLINT 
	define lsi_count		SMALLINT
	define lsi_currow		SMALLINT 
	define lc_null			CHAR(1)
	define lr_catrec  		RECORD  LIKE dw_web_cat.*

	define la_array		    ARRAY[500] of record
	   lineno				SMALLINT,
	   cat1					CHAR(10),
	   cat1_name			LIKE web_cat1.web_cat_name,
	   cat2					CHAR(10),
	   cat2_name			LIKE web_cat1.web_cat_name,
	   cat3					CHAR(10),
	   cat3_name			LIKE web_cat1.web_cat_name,
	   cat4					CHAR(10),
	   cat4_name			LIKE web_cat1.web_cat_name
				END RECORD,
		fa					STRING,
		p_status			CHAR(20),
	    p_bindir            CHAR(80),
        p_run               CHAR(80),
        p_runner            CHAR(80),
		s               	CHAR(10)

	let int_flag = false
	let quit_flag = false
	let lsi_sw = false
	let lsi_prt = 0
	let lsi_count = 0
	let lsi_currow = 0
	let lc_null = null
	INITIALIZE lr_catrec.* TO NULL

	FOR lsi_j = 1 to 500
		INITIALIZE la_array[lsi_j].* TO NULL
	END FOR

	OPTIONS INSERT KEY CONTROL-N,
        	DELETE KEY CONTROL-Z

	OPEN WINDOW cat_scrn1 
	WITH FORM "web_dwcatLst"
 	ATTRIBUTES(STYLE="naked")

	SET ISOLATION TO DIRTY READ

	DECLARE c_1x CURSOR FOR  
		SELECT 	*
	  	FROM 	dw_web_cat
		WHERE	web_cat1 = p_cat
	  	ORDER BY 1
	FOREACH c_1x INTO lr_catrec.*
		LET lsi_count = lsi_count + 1
		LET la_array[lsi_count].cat1 = lr_catrec.web_cat1
		LET la_array[lsi_count].cat2 = lr_catrec.web_cat2
		LET la_array[lsi_count].cat3 = lr_catrec.web_cat3
		LET la_array[lsi_count].cat4 = lr_catrec.web_cat4

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat1_name 
		FROM	dw_web_cat1
		WHERE	web_cat = lr_catrec.web_cat1

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat2_name 
		FROM	dw_web_cat2
		WHERE	web_cat = lr_catrec.web_cat2

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat3_name 
		FROM	dw_web_cat3
		WHERE	web_cat = lr_catrec.web_cat3

		SELECT	web_cat_name
		INTO	la_array[lsi_count].cat4_name 
		FROM	dw_web_cat4
		WHERE	web_cat = lr_catrec.web_cat4
	END FOREACH

	CALL set_count(lsi_count)
	DISPLAY ARRAY la_array TO sc_catlst.*
--#	ATTRIBUTE(NORMAL)


		ON ACTION accept
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY

        ON ACTION cancel
	   		LET lsi_sw = TRUE
            EXIT DISPLAY

		AFTER DISPLAY
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY
    END DISPLAY

	CLOSE WINDOW cat_scrn1 

	IF lsi_sw = true
	THEn
		RETURN "","","","","","",""
	ELSE
		RETURN la_array[lsi_currow].cat1, la_array[lsi_currow].cat2, la_array[lsi_currow].cat2_name,
										  la_array[lsi_currow].cat3, la_array[lsi_currow].cat3_name,
										  la_array[lsi_currow].cat4, la_array[lsi_currow].cat4_name
	END IF
END FUNCTION --- GetPrinter() ---
