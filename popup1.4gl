DATABASE seed
{@@@

Company         : Witchery Fashions Co. Pty. Ltd.

System          : Ramis - Retail Management InFORMATion System

Program Name    : 

Main Program    :
                
			

Module Name     : 

Function        : 

Module Files    :



Compilation    
Specifications  : Sources
						
					
				
		  Other Sources			- NONE 

		  Forms
			

		  Form Sources 			
							
				 
Modification Log: Date	Reason FOR Modification        Programmer
R1                270400 change test for lock method   IM
			    
@@@}
## To list AND get required store number
##
FUNCTION PopUpStore()
DEFINE lsi_j			SMALLINT 
DEFINE lsi_sw			SMALLINT 
DEFINE lsi_count		SMALLINT
DEFINE lsi_currow		SMALLINT 
DEFINE lr_store      	RECORD 
	   store	        SMALLINT,
	   store_name       CHAR(20)
		                END RECORD 
DEFINE la_ARRAY		    ARRAY[500] OF RECORD
	   store	        SMALLINT,
	   store_name       CHAR(20)
		                END RECORD 

LET int_flag = FALSE
LET quit_flag = FALSE
LET lsi_sw = FALSE
LET lsi_count = 0
LET lsi_currow = 0
INITIALIZE lr_store.* TO NULL

FOR lsi_j = 1 TO 500
	INITIALIZE la_ARRAY[lsi_j].* TO NULL
END FOR

OPTIONS ACCEPT KEY ESCAPE

OPEN WINDOW scrn_store at 2,45
     WITH 22 rows, 34 columns
	 ATTRIBUTES(Border,BLACK,REVERSE, Form Line 1)
OPEN FORM FORm_store FROM "StoreLst"
DISPLAY FORM FORm_store

SET ISOLATION TO DIRTY READ
DECLARE csel_store CURSOR FOR  
	Select UNIQUE store, store_name
	  FROM store 
	  WHERE store_name[1,6] != "CLOSED"
	  ORDER BY 1

FOREACH csel_store INTO lr_store.*
	LET lsi_count = lsi_count + 1
	LET la_ARRAY[lsi_count].* = lr_store.*
END FOREACH

CALL set_count(lsi_count)

DISPLAY ARRAY la_ARRAY TO scrn_store.*

	ON KEY (F10, CONTROL-C)  
	   LET lsi_sw = TRUE
	   EXIT DISPLAY

END DISPLAY

LET lsi_currow = ARR_CURR()

IF int_flag = TRUE THEN
	LET int_flag = FALSE
   	LET lsi_sw = TRUE
END IF 

IF quit_flag = TRUE THEN
	LET quit_flag = FALSE
   	LET lsi_sw = TRUE
END IF 

CLOSE WINDOW scrn_store
CLOSE FORM FORm_store 
free csel_store

IF lsi_sw = TRUE
THEN
	RETURN 0
ELSE
	RETURN la_ARRAY[lsi_currow].store
END IF 

END FUNCTION --- PopUpStore ---


## To list AND get required store number included IN the stocktake
##
FUNCTION PopUpStore1(li_stkno)
DEFINE li_stkno			INTEGER
DEFINE lsi_j			SMALLINT 
DEFINE lsi_sw			SMALLINT 
DEFINE lsi_count		SMALLINT
DEFINE lsi_currow		SMALLINT 
DEFINE lr_store      		RECORD 
	   store	        SMALLINT,
	   store_name       	CHAR(20)
		                END RECORD 
DEFINE la_ARRAY		    	ARRAY[500] OF RECORD
	   store	        SMALLINT,
	   store_name       	CHAR(20)
		                END RECORD 

LET int_flag = FALSE
LET quit_flag = FALSE
LET lsi_sw = FALSE
LET lsi_count = 0
LET lsi_currow = 0
INITIALIZE lr_store.* TO NULL

FOR lsi_j = 1 TO 500
	INITIALIZE la_ARRAY[lsi_j].* TO NULL
END FOR

OPTIONS ACCEPT KEY ESCAPE

OPEN WINDOW scrn_store1 at 2,45
     WITH 22 rows, 34 columns
	 ATTRIBUTES(Border,BLACK,REVERSE, Form Line 1)
OPEN FORM FORm_store1 FROM "StoreLst"
DISPLAY FORM FORm_store1

SET ISOLATION TO DIRTY READ
DECLARE csel_store1 CURSOR FOR  
	Select UNIQUE a.stkstr_store, b.store_name
	  FROM stktk_stores a, store b
	  WHERE stkstr_number = li_stkno
	  AND a.stkstr_store = b.store

FOREACH csel_store1 INTO lr_store.*
	LET lsi_count = lsi_count + 1
	LET la_ARRAY[lsi_count].* = lr_store.*
END FOREACH

CALL set_count(lsi_count)

DISPLAY ARRAY la_ARRAY TO scrn_store.*

	ON KEY (F10, CONTROL-C)  
	   LET lsi_sw = TRUE
	   EXIT DISPLAY

END DISPLAY

LET lsi_currow = ARR_CURR()

IF int_flag = TRUE THEN
	LET int_flag = FALSE
   	LET lsi_sw = TRUE
END IF 

IF quit_flag = TRUE THEN
	LET quit_flag = FALSE
   	LET lsi_sw = TRUE
END IF 

CLOSE WINDOW scrn_store1
CLOSE FORM FORm_store1
free csel_store1

IF lsi_sw = TRUE
THEN
	RETURN 0
ELSE
	RETURN la_ARRAY[lsi_currow].store
END IF 

END FUNCTION --- PopUpStore1 ---


## Confirm Yes Or No
## 
FUNCTION ConfirmYorN(lc_message)
DEFINE lc_message		CHAR(40)
DEFINE lc_ans_yorn		CHAR(1)

LET lc_ans_yorn = NULL

OPEN WINDOW scrn_confirm AT 11,19
		WITH 5 rows, 42 columns
		ATTRIBUTE(Border,BLACK,REVERSE, Form Line 1, Message Line 5)
OPEN FORM frm_confirm FROM "Confirm"
DISPLAY FORM frm_confirm

DISPLAY lc_MESSAGE TO scrn_conf_disp
			        ATTRIBUTE(BLUE)

INPUT lc_ans_yorn
      WITHOUT DEFAULTS
FROM  scrn_ans_yorn
--#		ATTRIBUTE(NORMAL)
		
	  AFTER FIELD scrn_ans_yorn
		 IF lc_ans_yorn IS NULL
		 THEN
			MESSAGE "This field cannot be NULL !!"
			SLEEP 2
			NEXT FIELD scrn_ans_yorn
		 END IF

END INPUT

CLOSE WINDOW scrn_confirm
CLOSE FORM frm_confirm

RETURN lc_ans_yorn

END FUNCTION --- ConfirmYorN ---


## To list AND get required valid stock number
##
FUNCTION GetValidStkNo()
DEFINE li_stkno      	INTEGER 
DEFINE lsi_j			SMALLINT 
DEFINE lsi_sw			SMALLINT 
DEFINE lsi_count		SMALLINT
DEFINE lsi_currow		SMALLINT 
DEFINE la_stkno		    ARRAY[20000] OF INTEGER

LET int_flag = FALSE
LET quit_flag = FALSE
LET lsi_sw = FALSE
LET lsi_count = 0
LET lsi_currow = 0
LET li_stkno = 0   

FOR lsi_j = 1 TO 20000
	LET la_stkno[lsi_j] = 0   
END FOR

OPTIONS ACCEPT KEY ESCAPE

OPEN WINDOW scrn_stkno at 2,51
     WITH 22 rows, 27 columns
	 ATTRIBUTES(Border,BLACK,REVERSE, Form Line 1)
OPEN FORM FORm_stkno FROM "StkTake02"
DISPLAY FORM FORm_stkno

SET ISOLATION TO DIRTY READ
DECLARE csel_stkno CURSOR FOR  
	Select UNIQUE stktk_number
	  FROM stktk_register 
	  ORDER BY 1 desc

FOREACH csel_stkno INTO li_stkno
	LET lsi_count = lsi_count + 1
	LET la_stkno[lsi_count] = li_stkno
END FOREACH

CALL set_count(lsi_count)

DISPLAY ARRAY la_stkno TO scrn_stktk.*

	ON KEY (F10, CONTROL-C)  
	   LET lsi_sw = TRUE
	   EXIT DISPLAY

	IF int_flag = TRUE THEN
		LET int_flag = FALSE
   		LET lsi_sw = TRUE
	    EXIT DISPLAY
	END IF 

	IF quit_flag = TRUE THEN
		LET quit_flag = FALSE
   		LET lsi_sw = TRUE
	    EXIT DISPLAY
	END IF 

END DISPLAY

LET lsi_currow = ARR_CURR()

CLOSE WINDOW scrn_stkno
CLOSE FORM FORm_stkno 
free csel_stkno

IF lsi_sw = TRUE
THEN
	RETURN 0
ELSE
	RETURN la_stkno[lsi_currow]
END IF 

END FUNCTION --- GetValidStkNo ---


## Check Valid Stock Number
##
FUNCTION ValidStkNo(li_stkno)
DEFINE li_stkno		INTEGER

SELECT stktk_number
FROM stktk_register
WHERE stktk_number = li_stkno

IF STATUS = NOTFOUND THEN
	RETURN FALSE
END IF

RETURN TRUE

END FUNCTION --- ValidStkNo ---


## Check Valid Store
##
FUNCTION ValidStore(lsi_store)
DEFINE lsi_store		SMALLINT

SELECT store
    FROM store
    WHERE store = lsi_store

IF STATUS = NOTFOUND THEN
	RETURN FALSE
END IF

RETURN TRUE

END FUNCTION --- ValidStore ---


## Check Valid Store Included In StockTake
##
FUNCTION ValidStkStr(li_stkno,lsi_store)
DEFINE li_stkno		INTEGER
DEFINE lsi_store	SMALLINT

SELECT stkstr_store 
  FROM stktk_stores
  WHERE stkstr_number = li_stkno
  AND   stkstr_store = lsi_store

IF STATUS = NOTFOUND THEN
	RETURN FALSE
END IF

RETURN TRUE

END FUNCTION --- ValidStkStr ---


## Check Valid Sku
##
FUNCTION ValidSku(li_sku)
#DEFINE li_sku		INTEGER 
DEFINE li_sku		LIKE sku.sku

SELECT sku
    FROM sku
    WHERE sku = li_sku

IF STATUS = NOTFOUND THEN
	RETURN FALSE
END IF

RETURN TRUE

END FUNCTION --- ValidSku ---


## Check FOR Stock Take Status
##
FUNCTION Stk_Updated(li_stkno)
DEFINE li_stkno		INTEGER
DEFINE lc_status	CHAR(1)

LET lc_status = NULL

SELECT stktk_status
  INTO lc_status
  FROM stktk_register
  WHERE stktk_number = li_stkno

IF lc_status = "U"
THEN
    RETURN TRUE
ELSE
    RETURN FALSE
END IF

END FUNCTION ---Stk_Updated ---

FUNCTION lock_status(li_stkno)
DEFINE li_stkno		INTEGER
DEFINE lc_status	CHAR(1)

LET lc_status = NULL

SELECT stktk_status
INTO lc_status
FROM stktk_register
WHERE stktk_number = li_stkno

RETURN lc_status

END FUNCTION
