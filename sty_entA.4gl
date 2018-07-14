################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entA - Store sisters maintenance           #
#  																			   #
# 	R00	30apr13	td		initial release								           #
# 	R01	20Feb18	dh	 Add NZD and SGD pricing.								           #
#																	           #
################################################################################
DATABASE seed

GLOBALS 
	"sty_entG.4gl"
#static variables
	DEFINE
			ssa_skulns DYNAMIC ARRAY OF RECORD
				sku				LIKE sku.sku,
				colour			LIKE colour.colour,
				colour_name		LIKE colour.colour_name,
				sizes			LIKE sizes.sizes,
				au_unit_cost	LIKE sku.unit_cost,
				au_unit_sell	LIKE sku.unit_sell,
				hk_unit_cost	LIKE sku.unit_cost,
				hk_unit_sell	LIKE sku.unit_sell,
				nz_unit_cost	LIKE sku.unit_cost,     #R01
				nz_unit_sell	LIKE sku.unit_sell,
				sg_unit_cost	LIKE sku.unit_cost,
				sg_unit_sell	LIKE sku.unit_sell
						END RECORD,
			s_maxidx				SMALLINT,
			s_sku					RECORD LIKE sku.*

################################################################################
FUNCTION sty_entA1(p_state)
	DEFINE	p_state					CHAR(10),
			w 						ui.Window,					
			cmd						STRING,
			ok						INTEGER,
			p_retstat				INTEGER,
			p_f10					INTEGER,
			p_maxrow				INTEGER,
			idx,sidx				INTEGER,
			jdx,kdx,ldx   			INTEGER,
			p_lkref1				CHAR(20),
			p_query					CHAR(921)

	CASE
	WHEN p_state = "INIT"
		LET w = ui.Window.forName("w_1")
        IF w IS NULL THEN
		   	OPEN WINDOW w_1 WITH FORM "sku_listx"
			ATTRIBUTE(TEXT="Style SKu",STYLE="naked")
		ELSE
			CURRENT WINDOW IS w_1
       	END IF

		FOR idx = 1 TO 100
			INITIALIZE ssa_skulns[idx].* TO NULL
		END FOR
		INITIALIZE s_sku.* TO NULL
		LET s_maxidx = 0
		LET p_retstat = TRUE

	WHEN p_state = "SELECT"

		DECLARE c_sel CURSOR FOR 
			SELECT	* 
			FROM	sku
			WHERE	style = g_style.style
			ORDER	BY colour

		LET idx = 1
		FOREACH c_sel INTO s_sku.* 

			SELECT	colour_name
			INTO 	ssa_skulns[idx].colour_name
			FROM	colour 
			WHERE	colour =  s_sku.colour

			LET ssa_skulns[idx].sku = s_sku.sku
			LET ssa_skulns[idx].colour = s_sku.colour
			LET ssa_skulns[idx].sizes = s_sku.sizes
			LET ssa_skulns[idx].au_unit_cost = s_sku.unit_cost
			LET ssa_skulns[idx].au_unit_sell = s_sku.unit_sell
			
			SELECT	unit_cost,unit_sell
			INTO	ssa_skulns[idx].hk_unit_cost , ssa_skulns[idx].hk_unit_sell
			FROM	seedhk:sku
			WHERE	style = g_style.style
			AND		sku = s_sku.sku

			SELECT	unit_cost,unit_sell
			INTO	ssa_skulns[idx].nz_unit_cost , ssa_skulns[idx].nz_unit_sell
			FROM	seednz:sku
			WHERE	style = g_style.style
			AND		sku = s_sku.sku

			SELECT	unit_cost,unit_sell
			INTO	ssa_skulns[idx].sg_unit_cost , ssa_skulns[idx].sg_unit_sell
			FROM	seedsin:sku
			WHERE	style = g_style.style
			AND		sku = s_sku.sku

			LET idx = idx + 1
		END FOREACH
		LET s_maxidx = idx - 1
##display "1xxx ",s_maxidx
		IF idx <= g_arrsize THEN
			INITIALIZE ssa_skulns[idx].* TO NULL
			FOR jdx = idx TO g_arrsize
				LET ssa_skulns[jdx].* = ssa_skulns[idx].* 
			END FOR
		END IF

	WHEN p_state = "DISPLAY"
		FOR idx = 1 TO g_dspsize
		DISPLAY ssa_skulns[idx].* TO sc_skulns[idx].* 
		ATTRIBUTE(NORMAL)
	END FOR
	LET p_retstat = TRUE
	CLOSE WINDOW  w_1

	WHEN p_state = "BROWSE"
		CALL SET_COUNT(s_maxidx)
		DISPLAY ARRAY ssa_skulns TO sc_skulns.* ATTRIBUTE (NORMAL)
			ON ACTION exit
				EXIT DISPLAY
		END DISPLAY
		CALL sty_entA1("DISPLAY") RETURNING p_retstat
		LET p_retstat = TRUE

	END CASE
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@ (sty_entA) @@@@@@@@@@@@@@@@@
################################################################################
