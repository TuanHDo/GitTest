IMPORT os 
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
##	R01	12mar09	td		Change the method of copying filess to the local ##						C:\ drive

## To Get the Printer Name, and Printer Description
#	19jan18		td		use CUPS
##
GLOBALS
    "r_globprt.4gl"
FUNCTION printer_G()
	DEFINE lsi_j			SMALLINT 
	DEFINE lsi_sw			SMALLINT 
	define lsi_prt			SMALLINT 
	define lsi_count		SMALLINT
	define lsi_currow		SMALLINT 
	define lc_null			CHAR(1)
	define lr_prtrec  RECORD 
	   printer_code     	CHAR(20),
	   printer_desc     	CHAR(20),
	   sortseq				SMALLINT
			END RECORD 

	define la_array		    ARRAY[100] of record
	   printer_code     	CHAR(20),
	   printer_desc     	CHAR(20)
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
	INITIALIZE lr_prtrec.* TO NULL

	FOR lsi_j = 1 to 100
		INITIALIZE la_array[lsi_j].* TO NULL
	END FOR

	OPTIONS INSERT KEY CONTROL-N,
        	DELETE KEY CONTROL-Z

	#CLOSE WINDOW SCREEN
	OPEN WINDOW prt_scrn1 
	WITH FORM "printerLst"
 	#ATTRIBUTES(STYLE="printer",BORDER)
 	ATTRIBUTES(STYLE="naked")
	#OPEN WINDOW prt_scrn1 at 30,185
     	#WITH 22 rows, 41 columns
 	#ATTRIBUTES(STYLE="printer")
	#OPEN FORM frm_prt1 from "printerLst"
	#DISPLAY FORM frm_prt1

	LET fa = "printer"
    DISPLAY fa TO image
	SET ISOLATION TO DIRTY READ
	DECLARE csel_printer CURSOR FOR  
		SELECT queprt, quename, sortseq
	  	FROM 	queprt 
	  	ORDER BY 3
	FOREACH csel_printer INTO lr_prtrec.*
		LET lsi_count = lsi_count + 1
		LET la_array[lsi_count].printer_code = lr_prtrec.printer_code
		LET la_array[lsi_count].printer_desc = lr_prtrec.printer_desc
	END FOREACH

	CALL set_count(lsi_count)
	DISPLAY ARRAY la_array TO scrn_printer.*
--#	ATTRIBUTE(NORMAL)

		BEFORE ROW
			LET lsi_currow = ARR_CURR()
			DISPLAY la_array[lsi_currow].printer_code  TO s

		ON KEY (F10)
	   		LET lsi_sw = TRUE
			EXIT DISPLAY

		ON ACTION action_f1
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY

		ON ACTION action_preview
			LET lsi_currow = ARR_CURR()
    		LET la_array[lsi_currow].printer_code = "preview"
	   		LET lsi_sw = FALSE
            EXIT DISPLAY

        ON ACTION action_f3                 #pgup

        ON ACTION action_f4                 #pgdown

        ON ACTION cancel					#cancel
	   		LET lsi_sw = TRUE
            EXIT DISPLAY

        ON ACTION action_f10
	   		LET lsi_sw = TRUE
            EXIT DISPLAY

		AFTER DISPLAY
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY
    END DISPLAY

	#CLOSE FORM frm_prt1 
	##CLOSE WINDOW SCREEN
	CLOSE WINDOW prt_scrn1

	IF lsi_sw = true
	THEn
		RETURN lc_null
	ELSE
    	IF la_array[lsi_currow].printer_code = "preview" THEN
			RETURN "preview"
		ELSE
    		CALL getprinterinfo_g(la_array[lsi_currow].printer_code)
			RETURN la_array[lsi_currow].printer_code
		END IF
	END IF
END FUNCTION --- GetPrinter() ---

FUNCTION getprinterinfo_g(prtname)
DEFINE prtname LIKE queprt.queprt

display prtname
    SELECT qnormal,
           qelongated,
           qcondensed,
           qmemo,
           q8lpi,
           q6lpi

    INTO p_ctrl_char.qnormal,
         p_ctrl_char.qelongated,
         p_ctrl_char.qcondensed,
         p_ctrl_char.qmemo,
         p_ctrl_char.q8lpi,
         p_ctrl_char.q6lpi

    FROM queprt
    WHERE queprt = prtname

END FUNCTION
---------------------------------------
--{#030907 commented out as this function existed in printer.4gl
FUNCTION time_stamp()
-- trim the colons from the time string, returning a
-- time based identifier for reports to add to their
-- output file name

DEFINE timestamp CHAR(8)
DEFINE file_suffix CHAR(6)
LET timestamp = TIME

LET file_suffix = timestamp[1,2],
                 timestamp[4,5],
                 timestamp[7,8]

RETURN file_suffix
END FUNCTION
--}
---------------------------------------

FUNCTION handle_output(destination,file_name)
-- print file name to destination or view it with more utility
-- put Q to quit msg at start and end of output for advice to user on more

	DEFINE destination  CHAR(20),
		   file_name    STRING,
		   p_filename   CHAR(50),
		   p_excel_file   CHAR(50),
		   file_name2   CHAR(40),
		   folder   	CHAR(40),
		   cmd 		    CHAR(128),
		   file_name1	CHAR(80),
		   p_bindir		CHAR(80),
           p_run        CHAR(80)

display "des: ", destination
	CASE
	WHEN destination = "preview" 

   		LET p_bindir = fgl_getenv("BINDIR")
       IF LENGTH(p_bindir) > 0
       THEN
           LET p_bindir = p_bindir CLIPPED, "/"
       END IF
		LET cmd = p_bindir CLIPPED, "htpg ",file_name CLIPPED
		display "run: ",cmd
		RUN cmd
		LET p_filename = file_name CLIPPED,".html"			#R01
		call fgl_putfile(p_filename CLIPPED, "c:/temp/report.html")  #R01
		call ui.interface.frontCall("standard", "shellexec",  ["c:/temp/report.html"], [])   #R01

		--CALL html_view(file_name)

	WHEN destination = "excel" 
{
        LET p_bindir = fgl_getenv("BINDIR")
        IF LENGTH(p_bindir) > 0
        THEN
             LET p_bindir = p_bindir CLIPPED, "/"
        END IF
        LET p_run = p_bindir CLIPPED, "excelpg ",file_name CLIPPED
        #R01 RUN p_run
		LET p_filename = file_name CLIPPED,".csv"			#R01
display "destination excel ",file_name CLIPPED," ",p_filename
		call fgl_putfile(p_filename CLIPPED, "c:/temp/report.csv")  #R01
		call ui.interface.frontCall("standard", "shellexec",  ["c:/temp/report.csv"], []) #R01
}
		LET p_filename = file_name CLIPPED,".csv"			#R01
	    LET p_excel_file = "c:/temp/",p_filename CLIPPED
		##call fgl_putfile(file_name CLIPPED, "c:/temp/report.csv")  #R01
		##call ui.interface.frontCall("standard", "shellexec",  ["c:/temp/report.csv"], []) #R01
		call fgl_putfile(file_name CLIPPED, p_excel_file CLIPPED)
		call ui.interface.frontCall("standard", "shellexec",  [p_excel_file], [])

	OTHERWISE
		#R01 	LET	cmd = "lp -d",destination CLIPPED," ",file_name
		#use ASCCI 12 to tell CUPS to skip to a new page
		##LET cmd = "lp -dcannon  -o portrait  -o cpi=19  -o lpi=8  -o page-left=30 -o page-top=50 -o page-bottom=20 ",file_name #R01
		#LET cmd = "lp -dplanning  -o portrait  -o cpi=19  -o lpi=8  -o page-left=30 -o page-top=50 -o page-bottom=20 ",file_name #R01
#display cmd
#		RUN cmd
	END CASE

END FUNCTION

---------------------------------------
FUNCTION get_ctrl_char(p_queprt)
	DEFINE p_queprt	LIKE queprt.queprt

	SELECT qnormal,
		   qelongated,
		   qcondensed,
		   qmemo,
		   q8lpi,
		   q6lpi             

	INTO p_ctrl_char.qnormal,
		 p_ctrl_char.qelongated,
		 p_ctrl_char.qcondensed,
		 p_ctrl_char.qmemo,
		 p_ctrl_char.q8lpi,
		 p_ctrl_char.q6lpi             

	FROM queprt
	WHERE queprt = p_queprt

	IF status = NOTFOUND THEN
		DISPLAY "Escape Characters do not exist for Printer ",p_queprt
	END IF
END FUNCTION

FUNCTION printer_M(p_state)
	DEFINE lsi_j			SMALLINT 
	DEFINE lsi_sw			SMALLINT 
	define lsi_prt			SMALLINT 
	define lsi_count		SMALLINT
	define lsi_currow		SMALLINT 
	define lc_null			CHAR(1)
	define lr_prtrec  RECORD 
	   printer_code     	CHAR(20),
	   printer_desc     	CHAR(20),
	   sortseq				SMALLINT
			END RECORD 

	define la_array		    ARRAY[100] of record
	   printer_code     	CHAR(20),
	   printer_desc     	CHAR(20)
			END RECORD ,
		fa					STRING,
		p_status			CHAR(20),
	    p_bindir            CHAR(80),
        p_run               CHAR(80),
        p_runner            CHAR(80),
		p_state				CHAR(3),
		s               	CHAR(10)

	let int_flag = false
	let quit_flag = false
	let lsi_sw = false
	let lsi_prt = 0
	let lsi_count = 0
	let lsi_currow = 0
	let lc_null = null
	INITIALIZE lr_prtrec.* TO NULL

	FOR lsi_j = 1 to 100
		INITIALIZE la_array[lsi_j].* TO NULL
	END FOR

	OPTIONS INSERT KEY CONTROL-N,
        	DELETE KEY CONTROL-Z

	OPEN WINDOW prt_scrn1 
	WITH FORM "printerLst"
 	ATTRIBUTES(STYLE="naked")

	LET fa = "printer"
    DISPLAY fa TO image
	SET ISOLATION TO DIRTY READ
	DECLARE csel_printer1 CURSOR FOR  
		SELECT queprt, quename, ""
	  	FROM 	queprt1 
		WHERE	state = p_state
	  	ORDER BY 2
	FOREACH csel_printer1 INTO lr_prtrec.*
		LET lsi_count = lsi_count + 1
		LET la_array[lsi_count].printer_code = lr_prtrec.printer_code
		LET la_array[lsi_count].printer_desc = lr_prtrec.printer_desc
	END FOREACH

	CALL set_count(lsi_count)
	DISPLAY ARRAY la_array TO scrn_printer.*
--#	ATTRIBUTE(NORMAL)

		BEFORE ROW
			LET lsi_currow = ARR_CURR()
			DISPLAY la_array[lsi_currow].printer_code  TO s

		ON KEY (F10)
	   		LET lsi_sw = TRUE
			EXIT DISPLAY

		ON ACTION action_f1
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY

		ON ACTION action_preview
			LET lsi_currow = ARR_CURR()
    		LET la_array[lsi_currow].printer_code = "preview"
	   		LET lsi_sw = FALSE
            EXIT DISPLAY

        ON ACTION action_f3                 #pgup

        ON ACTION action_f4                 #pgdown

        ON ACTION cancel					#cancel
	   		LET lsi_sw = TRUE
            EXIT DISPLAY

        ON ACTION action_f10
	   		LET lsi_sw = TRUE
            EXIT DISPLAY

		AFTER DISPLAY
			LET lsi_currow = ARR_CURR()
	   		LET lsi_sw = FALSE
            EXIT DISPLAY
    END DISPLAY

	#CLOSE FORM frm_prt1 
	##CLOSE WINDOW SCREEN
	CLOSE WINDOW prt_scrn1

	IF lsi_sw = true
	THEn
		RETURN lc_null
	ELSE
    	IF la_array[lsi_currow].printer_code = "preview" THEN
			RETURN "preview"
		ELSE
    		CALL getprinterinfo(la_array[lsi_currow].printer_code)
			RETURN la_array[lsi_currow].printer_code
		END IF
	END IF
END FUNCTION --- GetPrinter() ---
FUNCTION getprinterinfo(prtname)
DEFINE prtname LIKE queprt.queprt

display prtname
    SELECT qnormal,
           qelongated,
           qcondensed,
           qmemo,
           q8lpi,
           q6lpi

    INTO p_ctrl_char.qnormal,
         p_ctrl_char.qelongated,
         p_ctrl_char.qcondensed,
         p_ctrl_char.qmemo,
         p_ctrl_char.q8lpi,
         p_ctrl_char.q6lpi

    FROM queprt
    WHERE queprt = prtname

END FUNCTION

FUNCTION html_view(l_ascii_file)
	DEFINE 	l_ascii_file	CHAR(100), 
			file_name1		CHAR(8),
			file_name2  	CHAR(6),
			l_rlogin  		CHAR(10),
			l_html_file 	CHAR(100),
			l_view_file 	CHAR(100),
			l_pdfdrive 		CHAR(1),
			l_cmd 			CHAR(100),
			ch_in 			base.Channel,
			i,
			l_status,
			l_io_error		SMALLINT,
			reprecord RECORD
				buff1		STRING
			END RECORD
			
	LET l_cmd = "test -s ",l_ascii_file
	RUN l_cmd RETURNING l_io_error 
	IF  l_io_error <> 0 THEN
		RETURN
	END IF

	LET file_name1 = TIME
	LET file_name2 = file_name1[1,2], file_name1[4,5], file_name1[7,8]
	LET l_rlogin = get_rlogin()

	SELECT pdfdrive
	INTO l_pdfdrive
	FROM company
						
	LET l_html_file = "/",l_rlogin CLIPPED, "/fastpos/report/QPhtm",file_name2 CLIPPED, ".htm" 
	CALL ERRORLOG(l_html_file)

	LET l_view_file = l_pdfdrive, ":\\report\\QPhtm",file_name2 CLIPPED, ".htm" 
	CALL ERRORLOG(l_view_file)

	LET  ch_in  = base.Channel.create()
	CALL ch_in.setDelimiter( "%")
	CALL ch_in.openFile ( [l_ascii_file], "r")

	START REPORT html_export TO l_html_file
	LET i = 0
	WHILE ch_in.read(reprecord.buff1)
		IF int_flag THEN
			EXIT WHILE
		END IF
		--ERROR reprecord.buff1
		OUTPUT TO REPORT html_export(reprecord.*)
		LET i = i + 1
	END WHILE
	CALL ch_in.close()
	FINISH REPORT html_export

	IF i > 0 THEN
		CALL ui.Interface.frontCall("standard", "shellexec", [l_view_file], [l_status]) 
	END IF
	SLEEP 2
	LET l_cmd = "rm ", l_html_file
	RUN l_cmd

END FUNCTION 

REPORT html_export(reprec)
	DEFINE reprec RECORD
		buff1		STRING
	END RECORD


	OUTPUT
		TOP MARGIN 0
		BOTTOM MARGIN 0
		LEFT MARGIN 0
		RIGHT MARGIN 255
		PAGE LENGTH 66

	FORMAT
		FIRST PAGE HEADER
			PRINT '<HTML>'
			PRINT '<HEAD>'
			PRINT '<TITLE>Seed HTML Report Viewer</TITLE>'
			PRINT '</HEAD>'

			PRINT '<BODY>'
			PRINT '<PRE>'
			PRINT '<FONT SIZE=1 FACE="Courier New,Courier">'

		ON EVERY ROW
			PRINT reprec.buff1

		ON LAST ROW
			PRINT '</FONT>'
			PRINT '</PRE>'

			PRINT '</BODY>'
			PRINT '</HTML>'

END REPORT

FUNCTION get_rlogin()

	RETURN "seed"

END FUNCTION
FUNCTION handle_output2(destination,file_name)
-- print file name to destination or view it with more utility
-- put Q to quit msg at start and end of output for advice to user on more

    DEFINE destination  CHAR(20),
           file_name    CHAR(50),
           p_filename   CHAR(50),
           p_pdf_file   CHAR(50),
           p_excel_file   CHAR(50),
           file_name2   CHAR(40),
           folder       CHAR(40),
           cmd          CHAR(128),
           file_name1   CHAR(80),
           p_bindir     CHAR(80),
           p_run        CHAR(80),
           url          STRING, #RWEB
           os_info      STRING,  #RWEB
           os_temp_dir  STRING

display "des: ", destination
    CASE
    WHEN destination = "preview" 
   
        LET p_filename = SFMT("/opt/apache/htdocs/reports/%1.html",file_name CLIPPED)
        LET p_filename = p_filename CLIPPED
        RUN("echo '<html><head><title>FRENCH REPORT PREVIEW</title><head><body><pre>
<FONT SIZE=1 FACE=\"Courier New,Courier\">' >> " || p_filename)
        RUN("cat " || file_name || " >> " || p_filename)
        RUN("echo '</font></pre></body></html>' >> " || p_filename)
        LET url = SFMT("https://ramis.brandbank.com.au/reports/%1",os.Path.basename(p_filename))
        LET url = url.trim()
        CALL ui.interface.frontCall("standard", "launchurl",  [url], [])   #R01
        DISPLAY url


    WHEN destination = "excel" 
        CALL ui.interface.frontCall("standard","feinfo",["ostype"],[os_info]) 
        IF os_info = "Windows" THEN
           LET p_filename = file_name CLIPPED,".csv"            #R01
           LET p_excel_file = "c:/temp/",p_filename CLIPPED
           call fgl_putfile(file_name CLIPPED, p_excel_file CLIPPED)
           call ui.interface.frontCall("standard", "shellexec",  [p_excel_file], [])
        ELSE
           CALL ui.interface.frontCall("standard","feinfo",["datadirectory"],[os_temp_dir]) 
           LET p_excel_file = SFMT("%1/%2",os_temp_dir,p_filename CLIPPED) 
           DISPLAY p_excel_file
           CALL fgl_putfile(file_name CLIPPED, p_excel_file)
           call ui.interface.frontCall("standard", "shellexec",  [p_excel_file], [])
		END IF
    WHEN destination = "pdf" 
           CALL ui.interface.frontCall("standard","feinfo",["datadirectory"],[os_temp_dir]) 
           LET p_pdf_file = SFMT("%1/%2",os_temp_dir,p_filename CLIPPED) 
           DISPLAY p_pdf_file
           CALL fgl_putfile(file_name CLIPPED, p_pdf_file)
           call ui.interface.frontCall("standard", "shellexec",  [p_pdf_file], [])
    OTHERWISE
        LET cmd = "lp -d",destination CLIPPED," ",file_name
        RUN cmd
    END CASE

END FUNCTION
