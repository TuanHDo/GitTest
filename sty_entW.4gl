###############################################################################o
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entA - Store sisters maintenance           #
#  																			   #
# 	R00	09may00	td		initial release								           #
# 	R01	25sep15	td		add demandware hero images                             #
#   R02 08nov15 td		Add DW images
#   R03 02oct16 td		Add HK & SG images
#   R04 07may17 td      when AUS Web Publish is ticked  , it will automatically 
#						tick AUS Hero Image, NZ Hero Image, NZ Publish DW AU Her Image
#						DW NZ Hero Image
#	R05 18mar18 td		use https:// link to show images
#	R06	25may18 td		Add video url page	         						   #
#																	           #
################################################################################
DATABASE seed

GLOBALS 
	"sty_entG.4gl"
#static variables
	DEFINE
			#ssa_stycollns	ARRAY[50] OF RECORD
			#R06 >>
			ssa_styvlns	ARRAY[100] OF RECORD
				video_colour				SMALLINT,
				video_colour_name			LIKE colour.colour_name,
				video_url					VARCHAR(200) 
					END RECORD,
			#R06 <<
			ssa_stycollns	ARRAY[100] OF RECORD
				colour				SMALLINT,
				colour_name			LIKE colour.colour_name,
				upper				LIKE style_colour.upper,
				assort_desc			LIKE i_assortl.assort_ldesc,
				trend1				LIKE style_colour.trend1,
				trend1_desc			LIKE web_trend.web_desc,
				trend2				LIKE style_colour.trend2,
				trend2_desc			LIKE web_trend.web_desc,

				key_look			INTEGER,
				hero_image			INTEGER,
				release_date		DATE,
				publish				INTEGER,
				ebay_publish		INTEGER,

				hk_key_look			INTEGER,
				hk_hero_image		INTEGER,
				hk_release_date		DATE,
				hk_publish			INTEGER,
				#R03 >>
				sin_key_look		INTEGER,
				sin_hero_image		INTEGER,
				sin_release_date	DATE,
				sin_publish			INTEGER,
				#R03 <<
				#R03 >>
				nz_key_look		INTEGER,
				nz_hero_image		INTEGER,
				nz_release_date	DATE,
				nz_publish			INTEGER,
				dw_auhero_img		INTEGER,
				dw_nzhero_img		INTEGER,
				dw_hkhero_img		INTEGER,
				dw_sghero_img		INTEGER
				#R03 <<
						END RECORD,
			##ssa_imglns1	ARRAY[50] OF RECORD
			#R03 ssa_imglns1	ARRAY[100] OF RECORD
				#R03 mod_flg				CHAR(1)
						#R03 END RECORD,
			#R02 >>
			##ssa_dwimglns1	ARRAY[50] OF RECORD
			ssa_dwimglns1	ARRAY[100] OF RECORD
				dwmod_flg				CHAR(1)
						END RECORD,
			#R02 <<
			##ssa_imglns	ARRAY[50] OF RECORD
			#R03 ssa_imglns	ARRAY[100] OF RECORD
				#R03 colour				SMALLINT,
				#R03 colour_namex		LIKE colour.colour_name,
				#R03 ilabel1				STRING,
				#R03 image1				STRING,
				#R03 ilabel2				STRING,
				#R03#R03  image2				STRING,
				#R03 ilabel3				STRING,
				#R03 image3				STRING,
				#R03 ilabel4				STRING,
				#R03 image4				STRING,
				#R03#R03  ilabel5				STRING,
				#R03 image5				STRING
						#R03 END RECORD,
			#R02 >>
			##ssa_dwimglns	ARRAY[50] OF RECORD
			ssa_dwimglns	ARRAY[100] OF RECORD
				dwcolour				SMALLINT,
				dwcolour_namex		LIKE colour.colour_name,
				dwilabel1				STRING,
				dwimage1				STRING,
				dwilabel2				STRING,
				dwimage2				STRING,
				dwilabel3				STRING,
				dwimage3				STRING,
				dwilabel4				STRING,
				dwimage4				STRING,
				dwilabel5				STRING,
				dwimage5				STRING
						END RECORD,
			#R02 <<
			#R03 >>
			ssa_hkimglns	ARRAY[100] OF RECORD
				hkcolour				SMALLINT,
				hkcolour_namex		LIKE colour.colour_name,
				hkilabel1				STRING,
				hkimage1				STRING,
				hkilabel2				STRING,
				hkimage2				STRING,
				hkilabel3				STRING,
				hkimage3				STRING,
				hkilabel4				STRING,
				hkimage4				STRING,
				hkilabel5				STRING,
				hkimage5				STRING
						END RECORD,
			ssa_sgimglns	ARRAY[100] OF RECORD
				sgcolour				SMALLINT,
				sgcolour_namex		LIKE colour.colour_name,
				sgilabel1				STRING,
				sgimage1				STRING,
				sgilabel2				STRING,
				sgimage2				STRING,
				sgilabel3				STRING,
				sgimage3				STRING,
				sgilabel4				STRING,
				sgimage4				STRING,
				sgilabel5				STRING,
				sgimage5				STRING
						END RECORD,
			ssa_hkimglns1	ARRAY[100] OF RECORD
				hkmod_flg				CHAR(1)
						END RECORD,
			ssa_sgimglns1	ARRAY[100] OF RECORD
				sgmod_flg				CHAR(1)
						END RECORD,
			#R03 <<
			s_stylev	RECORD LIKE style_video_url.*,			#R06
			s_stylecol	RECORD LIKE style_colour.*,
			s_stylecol1	RECORD LIKE style_colour.*,
			s_maxidx	INTEGER

################################################################################
FUNCTION sty_entW(p_state)
	DEFINE	p_state					CHAR(10),
			p_video_url				VARCHAR(200),		#R06
			lstate					CHAR(10),			#R06
			cmd						STRING,
			p_auimage1				LIKE style_colour.ilabel1,			#R05
			p_auimage2				LIKE style_colour.ilabel1,			#R05
			p_auimage3				LIKE style_colour.ilabel1,			#R05
			p_auimage4				LIKE style_colour.ilabel1,			#R05
			p_auimage5				LIKE style_colour.ilabel1,			#R05
			p_hkimage1				LIKE style_colour.ilabel1,			#R05
			p_hkimage2				LIKE style_colour.ilabel1,			#R05
			p_hkimage3				LIKE style_colour.ilabel1,			#R05
			p_hkimage4				LIKE style_colour.ilabel1,			#R05
			p_hkimage5				LIKE style_colour.ilabel1,			#R05
			p_sgimage1				LIKE style_colour.ilabel1,			#R05
			p_sgimage2				LIKE style_colour.ilabel1,			#R05
			p_sgimage3				LIKE style_colour.ilabel1,			#R05
			p_sgimage4				LIKE style_colour.ilabel1,			#R05
			p_sgimage5				LIKE style_colour.ilabel1,			#R05
			p_url_label				STRING,								#R05
			p_url_auimage1			STRING,								#R05
			p_url_auimage2			STRING,								#R05
			p_url_auimage3			STRING,								#R05
			p_url_auimage4			STRING,								#R05
			p_url_auimage5			STRING,								#R05
			p_url_hkimage1			STRING,								#R05
			p_url_hkimage2			STRING,								#R05
			p_url_hkimage3			STRING,								#R05
			p_url_hkimage4			STRING,								#R05
			p_url_hkimage5			STRING,								#R05
			p_url_sgimage1			STRING,								#R05
			p_url_sgimage2			STRING,								#R05
			p_url_sgimage3			STRING,								#R05
			p_url_sgimage4			STRING,								#R05
			p_url_sgimage5			STRING,								#R05
			p_image2				LIKE style_colour.ilabel1,			#R05
			p_url_image2			STRING,								#R05
			p_image3				LIKE style_colour.ilabel1,			#R05
			p_url_image3			STRING,								#R05
			p_image4				LIKE style_colour.ilabel1,			#R05
			p_url_image4			STRING,								#R05
			p_image5				LIKE style_colour.ilabel1,			#R05
			p_url_image5			STRING,								#R05
			ok						INTEGER,
			p_label					string,
			p_prev_ilabel1,
			p_prev_ilabel2,
			p_prev_ilabel3,
			p_prev_ilabel4,
			p_prev_ilabel5			STRING,
			p_label1x				CHAR(30),
			p_label2x				CHAR(30),
			p_label3x				CHAR(30),
			p_label4x				CHAR(30),
			p_label5x				CHAR(30),
			p_label1				string,
			p_label2				string,
			p_label3				string,
			p_label4				string,
			p_label5				string,
			#R02 >>
			p_dwlabel					string,
			p_prev_dwilabel1,
			p_prev_dwilabel2,
			p_prev_dwilabel3,
			p_prev_dwilabel4,
			p_prev_dwilabel5			STRING,
			p_dwlabel1x				CHAR(30),
			p_dwlabel2x				CHAR(30),
			p_dwlabel3x				CHAR(30),
			p_dwlabel4x				CHAR(30),
			p_dwlabel5x				CHAR(30),
			p_dwlabel1				string,
			p_dwlabel2				string,
			p_dwlabel3				string,
			p_dwlabel4				string,
			p_dwlabel5				string,
			#R02 >>
			#R03 >>
			p_hklabel					string,
			p_prev_hkilabel1,
			p_prev_hkilabel2,
			p_prev_hkilabel3,
			p_prev_hkilabel4,
			p_prev_hkilabel5			STRING,
			p_hklabel1x				CHAR(30),
			p_hklabel2x				CHAR(30),
			p_hklabel3x				CHAR(30),
			p_hklabel4x				CHAR(30),
			p_hklabel5x				CHAR(30),
			p_hklabel1				string,
			p_hklabel2				string,
			p_hklabel3				string,
			p_hklabel4				string,
			p_hklabel5				string,

			p_sglabel					string,
			p_prev_sgilabel1,
			p_prev_sgilabel2,
			p_prev_sgilabel3,
			p_prev_sgilabel4,
			p_prev_sgilabel5			STRING,
			p_sglabel1x				CHAR(30),
			p_sglabel2x				CHAR(30),
			p_sglabel3x				CHAR(30),
			p_sglabel4x				CHAR(30),
			p_sglabel5x				CHAR(30),
			p_sglabel1				string,
			p_sglabel2				string,
			p_sglabel3				string,
			p_sglabel4				string,
			p_sglabel5				string,
			#R03 >>

			f ui.Form,
p_image		char(1),
            p_assort				LIKE style_colour.upper,
			w ui.Window,
			fa						STRING,
			p_assort_desc			LIKE i_assortl.assort_ldesc,
            p_trend1,
            p_trend2				LIKE style_colour.trend1,
			p_trend1_desc,
			p_trend2_desc			LIKE web_trend.web_desc,
			p_display				STRING,
			p_lineno				SMALLINT,
		 	p_store					LIKE store.store,
			p_storename				LIKE store.store_name,
			p_option				CHAR(80),
			p_text					CHAR(80),
			p_retstat				INTEGER,
			p_f10					INTEGER,
			p_maxrow				INTEGER,
			idx,sidx				INTEGER,
			jdx,kdx,ldx   			INTEGER,
			p_lkref1				CHAR(20),
			p_query					CHAR(921)

CASE
WHEN p_state = "INIT"
	FOR idx = 1 TO g_arrsize
		INITIALIZE ssa_stycollns[idx].* TO NULL
		INITIALIZE ssa_styvlns[idx].* TO NULL				#rxx
		#R03 INITIALIZE ssa_imglns[idx].* TO NULL
		#R03 INITIALIZE ssa_imglns1[idx].* TO NULL
	END FOR
	INITIALIZE s_stylev.* TO NULL			#rxx
	INITIALIZE s_stylecol.* TO NULL
	INITIALIZE s_stylecol1.* TO NULL
	LET s_maxidx = 0
	LET p_retstat = TRUE

WHEN p_state = "UPDATE"
	CALL sty_entW("DELETE") RETURNING p_retstat
	IF p_retstat = TRUE THEN
		CALL sty_entW("INSERT") RETURNING p_retstat
	END IF
	
WHEN p_state = "DELETE"
	DELETE FROM style_colour
	WHERE  style = g_style.style
	IF status = NOTFOUND OR status = 0 THEN
		LET p_retstat = TRUE
	ELSE
		LET p_retstat = FALSE
	END IF

WHEN p_state = "INSERT"
	LET p_retstat = TRUE
display "insert: ",s_maxidx
	DECLARE c_ins CURSOR FOR
		INSERT INTO style_colour VALUES ( s_stylecol.* )
		OPEN c_ins
		LET s_stylecol.style = g_style.style
		LET s_stylecol.lockdtime = CURRENT
		FOR idx = 1 TO s_maxidx
			LET s_stylecol.colour = ssa_stycollns[idx].colour
			LET s_stylecol.upper = ssa_stycollns[idx].upper
			LET s_stylecol.trend1 = ssa_stycollns[idx].trend1
			LET s_stylecol.trend2 = ssa_stycollns[idx].trend2
			LET s_stylecol.publish = ssa_stycollns[idx].publish
			LET s_stylecol.ebay_publish = ssa_stycollns[idx].ebay_publish
			LET s_stylecol.key_look = ssa_stycollns[idx].key_look
			LET s_stylecol.release_date = ssa_stycollns[idx].release_date
			#hongkong
			LET s_stylecol.hk_publish = ssa_stycollns[idx].hk_publish
			LET s_stylecol.hk_key_look = ssa_stycollns[idx].hk_key_look
			LET s_stylecol.hero_image = ssa_stycollns[idx].hero_image
			LET s_stylecol.hk_hero_image = ssa_stycollns[idx].hk_hero_image
			LET s_stylecol.hk_release_date = ssa_stycollns[idx].hk_release_date
			#singapore
			LET s_stylecol.sin_publish = ssa_stycollns[idx].sin_publish
			LET s_stylecol.sin_key_look = ssa_stycollns[idx].sin_key_look
			LET s_stylecol.hero_image = ssa_stycollns[idx].hero_image
			LET s_stylecol.sin_hero_image = ssa_stycollns[idx].sin_hero_image
			LET s_stylecol.sin_release_date = ssa_stycollns[idx].sin_release_date
			#NZ
			LET s_stylecol.nz_publish = ssa_stycollns[idx].nz_publish
			LET s_stylecol.nz_key_look = ssa_stycollns[idx].nz_key_look
			LET s_stylecol.hero_image = ssa_stycollns[idx].hero_image
			LET s_stylecol.nz_hero_image = ssa_stycollns[idx].nz_hero_image
			LET s_stylecol.nz_release_date = ssa_stycollns[idx].nz_release_date
			#>> R01 DW
			LET s_stylecol.dw_auhero_img = ssa_stycollns[idx].dw_auhero_img
			LET s_stylecol.dw_nzhero_img = ssa_stycollns[idx].dw_nzhero_img
			LET s_stylecol.dw_hkhero_img = ssa_stycollns[idx].dw_hkhero_img
			LET s_stylecol.dw_sghero_img = ssa_stycollns[idx].dw_sghero_img
			#R01 <<
			#images
			#R03 LET s_stylecol.ilabel1 = ssa_imglns[idx].ilabel1
			#R03 IF s_stylecol.ilabel1[4,100] IS NOT NULL  
			#R03 OR s_stylecol.ilabel1[4,100] != " " THEN
			--OR s_stylecol.ilabel1 = " " THEN
				##IF ssa_stycollns[idx].publish = "1" 				#R021
				##OR ssa_stycollns[idx].hk_publish = "1" THEN				#R021
					#R03 LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel1[4,100] CLIPPED," X:\\Now\""
#R03 display "here ", cmd
					#R03 CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
					#R02 >> copy to s:\ramisimages
					#R02 LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel1[4,100] CLIPPED," S:\\ramisimages\""
#R03 display "here ", cmd
					#R02 CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
					#R02 <<
			#R03 END IF 

			#R03 LET s_stylecol.ilabel2 = ssa_imglns[idx].ilabel2
			--IF s_stylecol.ilabel2 IS NOT NULL  THEN
			--OR s_stylecol.ilabel2 = " " THEN
			#R03 IF s_stylecol.ilabel2[4,100] IS NOT NULL  
			#R03 OR s_stylecol.ilabel2[4,100] != " " THEN
				#R03 LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel2[4,100] CLIPPED," X:\\Now\""
				#R03 CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
#R03 ##display "here: ",cmd
				#R02 >> copy to s:\ramisimages
				##LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel2[4,100] CLIPPED," S:\\ramisimages\""
				##CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 <<
			#R03 END IF

			#R03 LET s_stylecol.ilabel3 = ssa_imglns[idx].ilabel3
			--IF s_stylecol.ilabel3 IS NOT NULL THEN
			--OR s_stylecol.ilabel3 = " " THEN
			#R03 IF s_stylecol.ilabel3[4,100] IS NOT NULL  
			#R03 OR s_stylecol.ilabel3[4,100] != " " THEN
				#R03 LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel3[4,100] CLIPPED," X:\\Now\""
#R03 display "here: ",cmd
				#R03 CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 >> copy to s:\ramisimages
				##LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel3[4,100] CLIPPED," S:\\ramisimages\""
				##CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 <<
			#R03 END IF

			#R03 LET s_stylecol.ilabel4 = ssa_imglns[idx].ilabel4
			--IF s_stylecol.ilabel4 IS NOT NULL THEN
			--OR s_stylecol.ilabel4 = " " THEN
			#R03 IF s_stylecol.ilabel4[4,100] IS NOT NULL  
			#R03 OR s_stylecol.ilabel4[4,100] != " " THEN
				#R03 LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel4[4,100] CLIPPED," X:\\Now\""
#R03 display "here: ",cmd
				#R03 CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 >> copy to s:\ramisimages
				##LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel4[4,100] CLIPPED," S:\\ramisimages\""
				##CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 <<
			#R03 END IF

			#R03 LET s_stylecol.ilabel5 = ssa_imglns[idx].ilabel5
			--IF s_stylecol.ilabel5 IS NOT NULL THEN
			--OR s_stylecol.ilabel5 = " " THEN
			#R03 IF s_stylecol.ilabel5[4,100] IS NOT NULL  
			#R03 OR s_stylecol.ilabel5[4,100] != " " THEN
				#R03 LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel5[4,100] CLIPPED," X:\\Now\""
#R03 display "COPY X here: ",cmd
				#R03 CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 >> copy to s:\ramisimages
				##LET cmd = "cmd.exe /C \ copy X:", """\\""",s_stylecol.ilabel5[4,100] CLIPPED," S:\\ramisimages\""
				##CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
				#R02 <<
			#R03 END IF
			#dw images R02 >>
			#dw images
			LET s_stylecol.dwilabel1 = ssa_dwimglns[idx].dwilabel1
			IF s_stylecol.dwilabel1[4,100] IS NOT NULL  
			OR s_stylecol.dwilabel1[4,100] != " " THEN
					LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.dwilabel1[4,100] CLIPPED," Y:\\Flow\""
display "COPY Y here ", cmd
					CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF 

			LET s_stylecol.dwilabel2 = ssa_dwimglns[idx].dwilabel2
			IF s_stylecol.dwilabel2[4,100] IS NOT NULL  
			OR s_stylecol.dwilabel2[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.dwilabel2[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.dwilabel3 = ssa_dwimglns[idx].dwilabel3
			IF s_stylecol.dwilabel3[4,100] IS NOT NULL  
			OR s_stylecol.dwilabel3[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.dwilabel3[4,100] CLIPPED," Y:\\Flow\""
display "here: ",cmd
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.dwilabel4 = ssa_dwimglns[idx].dwilabel4
			IF s_stylecol.dwilabel4[4,100] IS NOT NULL  
			OR s_stylecol.dwilabel4[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.dwilabel4[4,100] CLIPPED," Y:\\Flow\""
display "here: ",cmd
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.dwilabel5 = ssa_dwimglns[idx].dwilabel5
			IF s_stylecol.dwilabel5[4,100] IS NOT NULL  
			OR s_stylecol.dwilabel5[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.dwilabel5[4,100] CLIPPED," Y:\\Flow\""
display "here: ",cmd
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF
			LET s_stylecol.dwmod_flg = ssa_dwimglns1[idx].dwmod_flg
			#R02 <<
			#HK images R03 >>
			LET s_stylecol.hkilabel1 = ssa_hkimglns[idx].hkilabel1
			IF s_stylecol.hkilabel1[4,100] IS NOT NULL  
			OR s_stylecol.hkilabel1[4,100] != " " THEN
					LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.hkilabel1[4,100] CLIPPED," Y:\\Flow\""
					CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF 

			LET s_stylecol.hkilabel2 = ssa_hkimglns[idx].hkilabel2
			IF s_stylecol.hkilabel2[4,100] IS NOT NULL  
			OR s_stylecol.hkilabel2[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.hkilabel2[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.hkilabel3 = ssa_hkimglns[idx].hkilabel3
			IF s_stylecol.hkilabel3[4,100] IS NOT NULL  
			OR s_stylecol.hkilabel3[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.hkilabel3[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.hkilabel4 = ssa_hkimglns[idx].hkilabel4
			IF s_stylecol.hkilabel4[4,100] IS NOT NULL  
			OR s_stylecol.hkilabel4[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.hkilabel4[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.hkilabel5 = ssa_hkimglns[idx].hkilabel5
			IF s_stylecol.hkilabel5[4,100] IS NOT NULL  
			OR s_stylecol.hkilabel5[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.hkilabel5[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF
			LET s_stylecol.hkmod_flg = ssa_hkimglns1[idx].hkmod_flg
			#SG images R03 >>
			LET s_stylecol.sgilabel1 = ssa_sgimglns[idx].sgilabel1
			IF s_stylecol.sgilabel1[4,100] IS NOT NULL  
			OR s_stylecol.sgilabel1[4,100] != " " THEN
					LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.sgilabel1[4,100] CLIPPED," Y:\\Flow\""
					CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF 

			LET s_stylecol.sgilabel2 = ssa_sgimglns[idx].sgilabel2
			IF s_stylecol.sgilabel2[4,100] IS NOT NULL  
			OR s_stylecol.sgilabel2[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.sgilabel2[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.sgilabel3 = ssa_sgimglns[idx].sgilabel3
			IF s_stylecol.sgilabel3[4,100] IS NOT NULL  
			OR s_stylecol.sgilabel3[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.sgilabel3[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.sgilabel4 = ssa_sgimglns[idx].sgilabel4
			IF s_stylecol.sgilabel4[4,100] IS NOT NULL  
			OR s_stylecol.sgilabel4[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.sgilabel4[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF

			LET s_stylecol.sgilabel5 = ssa_sgimglns[idx].sgilabel5
			IF s_stylecol.sgilabel5[4,100] IS NOT NULL  
			OR s_stylecol.sgilabel5[4,100] != " " THEN
				LET cmd = "cmd.exe /C \ copy Y:", """\\""",s_stylecol.sgilabel5[4,100] CLIPPED," Y:\\Flow\""
				CALL ui.Interface.FrontCall("standard","shellexec", [cmd], [ok])
			END IF
			LET s_stylecol.sgmod_flg = ssa_sgimglns1[idx].sgmod_flg
			#R03 <<

			#R03 LET s_stylecol.mod_flg = ssa_imglns1[idx].mod_flg


			IF s_stylecol.colour IS NOT NULL THEN
				PUT c_ins
				IF status != 0 THEN
					LET p_retstat = FALSE
				END IF
			END IF
		END FOR
		CLOSE c_ins

#R06 >>
WHEN p_state = "UPDATEV"
	CALL sty_entW("DELETEV") RETURNING p_retstat
	IF p_retstat = TRUE THEN
		CALL sty_entW("INSERTV") RETURNING p_retstat
	END IF
	
WHEN p_state = "DELETEV"
	DELETE FROM style_video_url
	WHERE  style = g_style.style
	IF status = NOTFOUND OR status = 0 THEN
		LET p_retstat = TRUE
	ELSE
		LET p_retstat = FALSE
	END IF

WHEN p_state = "INSERTV"
	LET p_retstat = TRUE
display "insert video: ",s_maxidx
	DECLARE c_insv CURSOR FOR
		INSERT INTO style_video_url VALUES ( s_stylev.* )
		OPEN c_insv
		LET s_stylev.style = g_style.style
		LET s_stylev.lockdtime = CURRENT
		LET s_stylev.who = g_user
		FOR idx = 1 TO s_maxidx
			LET s_stylev.colour = ssa_styvlns[idx].video_colour
			LET s_stylev.url = ssa_styvlns[idx].video_url
			IF s_stylev.colour IS NOT NULL THEN
				PUT c_insv
				IF status != 0 THEN
					LET p_retstat = FALSE
				END IF
			END IF
		END FOR
		CLOSE c_insv
#R06 <<

	WHEN p_state = "SELECT"

		DECLARE c_sel CURSOR FOR 
			SELECT	* 
			FROM	style_colour
			WHERE	style = g_style.style
			ORDER	BY colour

		LET idx = 1
		FOREACH c_sel INTO s_stylecol.* 
			LET ssa_stycollns[idx].colour = s_stylecol.colour

			SELECT	colour_name
			INTO 	ssa_stycollns[idx].colour_name
			FROM	colour 
			WHERE	colour =  s_stylecol.colour

			#R06 >>
			LET ssa_styvlns[idx].video_colour = s_stylecol.colour
			LET ssa_styvlns[idx].video_colour_name = ssa_stycollns[idx].colour_name

			LET	ssa_styvlns[idx].video_url = NULL
			SELECT	url
			INTO	ssa_styvlns[idx].video_url
			FROM	style_video_url
			WHERE	style = s_stylecol.style
			AND		colour = s_stylecol.colour
			#R06 <<

			SELECT	assort_ldesc
			INTO    ssa_stycollns[idx].assort_desc
			FROM	i_assortl
			WHERE	assort_lcode = s_stylecol.upper
			AND		assort_id = 1

			LET ssa_stycollns[idx].upper = s_stylecol.upper

			LET ssa_stycollns[idx].trend1 = s_stylecol.trend1
			LET ssa_stycollns[idx].trend2 = s_stylecol.trend2

			LET ssa_stycollns[idx].publish = s_stylecol.publish
			LET ssa_stycollns[idx].ebay_publish = s_stylecol.ebay_publish
			LET ssa_stycollns[idx].hero_image = s_stylecol.hero_image
			LET ssa_stycollns[idx].release_date = s_stylecol.release_date
			LET ssa_stycollns[idx].key_look = s_stylecol.key_look

			#hongkong
			LET ssa_stycollns[idx].hk_publish = s_stylecol.hk_publish
			LET ssa_stycollns[idx].hk_hero_image = s_stylecol.hk_hero_image
			LET ssa_stycollns[idx].hk_release_date = s_stylecol.hk_release_date
			LET ssa_stycollns[idx].hk_key_look = s_stylecol.hk_key_look
			#singapore
			LET ssa_stycollns[idx].sin_publish = s_stylecol.sin_publish
			LET ssa_stycollns[idx].sin_hero_image = s_stylecol.sin_hero_image
			LET ssa_stycollns[idx].sin_release_date = s_stylecol.sin_release_date
			LET ssa_stycollns[idx].sin_key_look = s_stylecol.sin_key_look
			#nz
			LET ssa_stycollns[idx].nz_publish = s_stylecol.nz_publish
			LET ssa_stycollns[idx].nz_hero_image = s_stylecol.nz_hero_image
			LET ssa_stycollns[idx].nz_release_date = s_stylecol.nz_release_date
			LET ssa_stycollns[idx].nz_key_look = s_stylecol.nz_key_look
			#R02 >> R01
			LET ssa_stycollns[idx].dw_auhero_img = s_stylecol.dw_auhero_img
			LET ssa_stycollns[idx].dw_nzhero_img = s_stylecol.dw_nzhero_img
			LET ssa_stycollns[idx].dw_hkhero_img = s_stylecol.dw_hkhero_img
			LET ssa_stycollns[idx].dw_sghero_img = s_stylecol.dw_sghero_img
			#R01 <<
##display "select image 1xxx: ",idx, " ", s_stylecol.colour

			LET idx = idx + 1
		END FOREACH
		LET s_maxidx = idx - 1
##display "1xxx ",s_maxidx
		IF idx <= g_arrsize THEN
			INITIALIZE ssa_stycollns[idx].* TO NULL
			FOR jdx = idx TO g_arrsize
				LET ssa_stycollns[jdx].* = ssa_stycollns[idx].* 
			END FOR
		END IF
	WHEN p_state = "SELECTX"

		DECLARE c_selx CURSOR FOR 
			SELECT	* 
			FROM	style_colour
			WHERE	style = g_style.style
			ORDER	BY colour

		LET idx = 1
		FOREACH c_selx INTO s_stylecol1.* 
			#R03 LET ssa_imglns[idx].colour = s_stylecol1.colour

			#R03 SELECT	colour_name
			#R03 INTO 	ssa_imglns[idx].colour_namex
			#R03 FROM	colour 
			#R03 WHERE	colour =  s_stylecol1.colour

			#R03 LET ssa_imglns[idx].ilabel1 = s_stylecol1.ilabel1
			#R03 LET ssa_imglns[idx].ilabel2 = s_stylecol1.ilabel2
			#R03 LET ssa_imglns[idx].ilabel3 = s_stylecol1.ilabel3
			#R03 LET ssa_imglns[idx].ilabel4 = s_stylecol1.ilabel4
			#R03 LET ssa_imglns[idx].ilabel5 = s_stylecol1.ilabel5
			#images

			#R03 LET p_label1 = ssa_imglns[idx].ilabel1
			#R03 LET ssa_imglns[idx].image1 =  p_label1 CLIPPED
			#R03 LET p_label2 = ssa_imglns[idx].ilabel2
			#R03 LET ssa_imglns[idx].image2 =  p_label2 CLIPPED
			#R03 LET p_label3 = ssa_imglns[idx].ilabel3
			#R03 LET ssa_imglns[idx].image3 =  p_label3 CLIPPED
			#R03 LET p_label4 = ssa_imglns[idx].ilabel4
			#R03 LET ssa_imglns[idx].image4 =  p_label4 CLIPPED
			#R03 LET p_label5 = ssa_imglns[idx].ilabel5
			#R03 LET ssa_imglns[idx].image5 =  p_label5 CLIPPED

			#R02 >> DW iamges
			LET ssa_dwimglns[idx].dwcolour = s_stylecol1.colour

			SELECT	colour_name
			INTO 	ssa_dwimglns[idx].dwcolour_namex
			FROM	colour 
			WHERE	colour =  s_stylecol1.colour

			LET ssa_dwimglns[idx].dwilabel1 = s_stylecol1.dwilabel1
			LET ssa_dwimglns[idx].dwilabel2 = s_stylecol1.dwilabel2
			LET ssa_dwimglns[idx].dwilabel3 = s_stylecol1.dwilabel3
			LET ssa_dwimglns[idx].dwilabel4 = s_stylecol1.dwilabel4
			LET ssa_dwimglns[idx].dwilabel5 = s_stylecol1.dwilabel5
			#images
			#R05 >>
			#########################################################################
			# rxx - Get image files from the URL: https://mail.brandbank.com.au/flowsd
			#########################################################################
			LET p_auimage1 = ssa_dwimglns[idx].dwilabel1								
			LET p_url_auimage1 = "https://mail.brandbank.com.au/flowsd/",p_auimage1[4,100]
			LET p_dwlabel1 = p_url_auimage1												
			#R05 LET p_dwlabel1 = ssa_dwimglns[idx].dwilabel1							
			LET ssa_dwimglns[idx].dwimage1 =  p_dwlabel1 CLIPPED
#display "au label 1",p_dwlabel1

			LET p_auimage2 = ssa_dwimglns[idx].dwilabel2								
			LET p_url_auimage2 = "https://mail.brandbank.com.au/flowsd/",p_auimage2[4,100]
			LET p_dwlabel2 = p_url_auimage2												
			#R05 LET p_dwlabel2 = ssa_dwimglns[idx].dwilabel2
			LET ssa_dwimglns[idx].dwimage2 =  p_dwlabel2 CLIPPED

			LET p_auimage3 = ssa_dwimglns[idx].dwilabel3								
			LET p_url_auimage3 = "https://mail.brandbank.com.au/flowsd/",p_auimage3[4,100]
			LET p_dwlabel3 = p_url_auimage3												
			#R05 LET p_dwlabel3 = ssa_dwimglns[idx].dwilabel3
			LET ssa_dwimglns[idx].dwimage3 =  p_dwlabel3 CLIPPED

			LET p_auimage4 = ssa_dwimglns[idx].dwilabel4								
			LET p_url_auimage4 = "https://mail.brandbank.com.au/flowsd/",p_auimage4[4,100]
			LET p_dwlabel4 = p_url_auimage4												
			#R05 LET p_dwlabel4 = ssa_dwimglns[idx].dwilabel4
			LET ssa_dwimglns[idx].dwimage4 =  p_dwlabel4 CLIPPED

			LET p_auimage5 = ssa_dwimglns[idx].dwilabel5								
			LET p_url_auimage5 = "https://mail.brandbank.com.au/flowsd/",p_auimage5[4,100]
			LET p_dwlabel5 = p_url_auimage5												
			#R05 LET p_dwlabel5 = ssa_dwimglns[idx].dwilabel5
			LET ssa_dwimglns[idx].dwimage5 =  p_dwlabel5 CLIPPED
			#R05 <<

			#R03 >> HK images
			LET ssa_hkimglns[idx].hkcolour = s_stylecol1.colour

			SELECT	colour_name
			INTO 	ssa_hkimglns[idx].hkcolour_namex
			FROM	colour 
			WHERE	colour =  s_stylecol1.colour

			LET ssa_hkimglns[idx].hkilabel1 = s_stylecol1.hkilabel1
			LET ssa_hkimglns[idx].hkilabel2 = s_stylecol1.hkilabel2
			LET ssa_hkimglns[idx].hkilabel3 = s_stylecol1.hkilabel3
			LET ssa_hkimglns[idx].hkilabel4 = s_stylecol1.hkilabel4
			LET ssa_hkimglns[idx].hkilabel5 = s_stylecol1.hkilabel5
			#images

			#R05 >>
			LET p_hkimage1 = ssa_hkimglns[idx].hkilabel1								
			LET p_url_hkimage1 = "https://mail.brandbank.com.au/flowsd/",p_hkimage1[4,100]
			LET p_hklabel1 = p_url_hkimage1												
			#R05 LET p_hklabel1 = ssa_hkimglns[idx].hkilabel1
			LET ssa_hkimglns[idx].hkimage1 =  p_hklabel1 CLIPPED

			LET p_hkimage2 = ssa_hkimglns[idx].hkilabel2								
#display "SELECT HK img 2 ", p_hkimage2 ," ", ssa_hkimglns[idx].hkilabel2								
			LET p_url_hkimage2 = "https://mail.brandbank.com.au/flowsd/",p_hkimage2[4,100]
			LET p_hklabel2 = p_url_hkimage2												
			#R05 LET p_hklabel2 = ssa_hkimglns[idx].hkilabel2
			LET ssa_hkimglns[idx].hkimage2 =  p_hklabel2 CLIPPED
			#display "SELECT SK IMG 2x: ", ssa_hkimglns[idx].hkimage2 ," ",  p_hklabel2 

			LET p_hkimage3 = ssa_hkimglns[idx].hkilabel3								
			LET p_url_hkimage3 = "https://mail.brandbank.com.au/flowsd/",p_hkimage3[4,100]
			LET p_hklabel3 = p_url_hkimage3												
			#R05 LET p_hklabel3 = ssa_hkimglns[idx].hkilabel3
			LET ssa_hkimglns[idx].hkimage3 =  p_hklabel3 CLIPPED

			LET p_hkimage4 = ssa_hkimglns[idx].hkilabel4								
			LET p_url_hkimage4 = "https://mail.brandbank.com.au/flowsd/",p_hkimage4[4,100]
			LET p_hklabel4 = p_url_hkimage4												
			#R05  LET p_hklabel4 = ssa_hkimglns[idx].hkilabel4
			LET ssa_hkimglns[idx].hkimage4 =  p_hklabel4 CLIPPED

			LET p_hkimage5 = ssa_hkimglns[idx].hkilabel5								
			LET p_url_hkimage5 = "https://mail.brandbank.com.au/flowsd/",p_hkimage5[4,100]
			LET p_hklabel5 = p_url_hkimage5												
			#R05  LET p_hklabel5 = ssa_hkimglns[idx].hkilabel5
			LET ssa_hkimglns[idx].hkimage5 =  p_hklabel5 CLIPPED
			#R05 <<

			#R03 >> SG images
			LET ssa_sgimglns[idx].sgcolour = s_stylecol1.colour

			SELECT	colour_name
			INTO 	ssa_sgimglns[idx].sgcolour_namex
			FROM	colour 
			WHERE	colour =  s_stylecol1.colour

			LET ssa_sgimglns[idx].sgilabel1 = s_stylecol1.sgilabel1
			LET ssa_sgimglns[idx].sgilabel2 = s_stylecol1.sgilabel2
			LET ssa_sgimglns[idx].sgilabel3 = s_stylecol1.sgilabel3
			LET ssa_sgimglns[idx].sgilabel4 = s_stylecol1.sgilabel4
			LET ssa_sgimglns[idx].sgilabel5 = s_stylecol1.sgilabel5
			#images

			#R05 >>
			LET p_sgimage1 = ssa_sgimglns[idx].sgilabel1								
			LET p_url_sgimage1 = "https://mail.brandbank.com.au/flowsd/",p_sgimage1[4,100]
			LET p_sglabel1 = p_url_sgimage1												
			#R05  LET p_sglabel1 = ssa_sgimglns[idx].sgilabel1
			LET ssa_sgimglns[idx].sgimage1 =  p_sglabel1 CLIPPED

			LET p_sgimage2 = ssa_sgimglns[idx].sgilabel2								
#display "SELECT SG img 2: ",p_sgimage2
			LET p_url_sgimage2 = "https://mail.brandbank.com.au/flowsd/",p_sgimage2[4,100]
			LET p_sglabel2 = p_url_sgimage2												
			#R05 LET p_sglabel2 = ssa_sgimglns[idx].sgilabel2
			LET ssa_sgimglns[idx].sgimage2 =  p_sglabel2 CLIPPED
#display "SELECT SG 2: ",p_sglabel2

			LET p_sgimage3 = ssa_sgimglns[idx].sgilabel3								
			LET p_url_sgimage3 = "https://mail.brandbank.com.au/flowsd/",p_sgimage3[4,100]
			LET p_sglabel3 = p_url_sgimage3												
			#R05 LET p_sglabel3 = ssa_sgimglns[idx].sgilabel3
			LET ssa_sgimglns[idx].sgimage3 =  p_sglabel3 CLIPPED

			LET p_sgimage4 = ssa_sgimglns[idx].sgilabel4								
			LET p_url_sgimage4 = "https://mail.brandbank.com.au/flowsd/",p_sgimage4[4,100]
			LET p_sglabel4 = p_url_sgimage4												
			#R05 LET p_sglabel4 = ssa_sgimglns[idx].sgilabel4
			LET ssa_sgimglns[idx].sgimage4 =  p_sglabel4 CLIPPED

			LET p_sgimage5 = ssa_sgimglns[idx].sgilabel5								
			LET p_url_sgimage5 = "https://mail.brandbank.com.au/flowsd/",p_sgimage5[4,100]
			LET p_sglabel5 = p_url_sgimage5												
			#R05 LET p_sglabel5 = ssa_sgimglns[idx].sgilabel5
			LET ssa_sgimglns[idx].sgimage5 =  p_sglabel5 CLIPPED
			#R05 <<

##display "select image 1: ",p_label1
##display "select image 2: ",p_label2
##display "select image 2: ",idx, " ", s_stylecol1.colour
			LET idx = idx + 1
		END FOREACH
##display "2 ",s_maxidx
		LET s_maxidx = idx - 1
		IF idx <= g_arrsize THEN
			#R03 INITIALIZE ssa_imglns[idx].* TO NULL
			INITIALIZE ssa_dwimglns[idx].* TO NULL				#R02
			INITIALIZE ssa_hkimglns[idx].* TO NULL				#R03
			INITIALIZE ssa_sgimglns[idx].* TO NULL				#R03
			FOR jdx = idx TO g_arrsize
				#R03 LET ssa_imglns[jdx].* = ssa_imglns[idx].* 
				LET ssa_dwimglns[jdx].* = ssa_dwimglns[idx].* 		#R02
				LET ssa_hkimglns[jdx].* = ssa_hkimglns[idx].* 		#R03
				LET ssa_sgimglns[jdx].* = ssa_sgimglns[idx].* 		#R03
			END FOR
		END IF
		
WHEN p_state = "INPUT"
		LET g_image = TRUE
	 #R02 WHILE TRUE
		#R02 CALL SET_COUNT(s_maxidx)
	 DIALOG ATTRIBUTES(UNBUFFERED)
		#R02 LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_stycollns
    	#R02 WITHOUT DEFAULTS 
    	FROM sc_stycollns.*
		ATTRIBUTE(WITHOUT DEFAULTS=TRUE, APPEND ROW=FALSE, INSERT ROW=FALSE, DELETE ROW=FALSE,COUNT=s_maxidx)
		
			BEFORE ROW
				#R02 LET idx = ARR_CURR()
				#R02 LET sidx = SCR_LINE()
				#R02 LET s_maxidx = ARR_COUNT()

			#R02 AFTER ROW
				#R02 LET idx = ARR_CURR()
				#R02 LET sidx = SCR_LINE()
	
    		#R02 AFTER DELETE
				#R02 MESSAGE ""
				#R02 LET kdx = ARR_COUNT() + 1
				#R02 INITIALIZE ssa_stycollns[kdx].* TO NULL
				#R02 LET s_maxidx = s_maxidx - 1

			#R02 BEFORE INSERT
				#R02 LET s_maxidx = ARR_COUNT()

			#R02 AFTER INSERT
				#R02 LET s_maxidx = s_maxidx + 1

			#R02 >>
			ON ACTION zoom9
				LET p_lkref1= 1
                CALL gp_lookup("assort",p_lkref1)
                RETURNING p_assort,p_assort_desc
                IF p_assort IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_stycollns")
					LET ssa_stycollns[idx].upper = p_assort
					DISPLAY ssa_stycollns[idx].upper
					TO sc_stycollns[sidx].upper
					ATTRIBUTE (NORMAL)
					LET ssa_stycollns[idx].assort_desc= p_assort_desc
					DISPLAY ssa_stycollns[idx].assort_desc
					TO sc_stycollns[sidx].assort_desc
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom10
				LET p_lkref1= g_style.season
                CALL gp_lookup("trend",p_lkref1)
                RETURNING p_trend1,p_trend1_desc
                IF p_trend1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_stycollns")
					LET ssa_stycollns[idx].trend1 = p_trend1
					DISPLAY ssa_stycollns[idx].trend1
					TO sc_stycollns[sidx].trend1
					ATTRIBUTE (NORMAL)
					LET ssa_stycollns[idx].trend1_desc = p_trend1_desc
					DISPLAY ssa_stycollns[idx].trend1_desc
					TO sc_stycollns[sidx].trend1_desc
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom11
				LET p_lkref1= g_style.season
                CALL gp_lookup("trend",p_lkref1)
                RETURNING p_trend2,p_trend2_desc
                IF p_trend2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_stycollns")
					LET ssa_stycollns[idx].trend2 = p_trend2
					DISPLAY ssa_stycollns[idx].trend2
					TO sc_stycollns[sidx].trend2
					ATTRIBUTE (NORMAL)
					LET ssa_stycollns[idx].trend2_desc = p_trend2_desc
					DISPLAY ssa_stycollns[idx].trend2_desc
					TO sc_stycollns[sidx].trend2_desc
					ATTRIBUTE (NORMAL)
				END IF
{
			AFTER FIELD upper
				IF	ssa_stycollns[idx].upper  IS NOT  NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_stycollns")
					SELECT	assort_ldesc
					INTO 	ssa_stycollns[idx].assort_desc
					FROM	i_assortl
					WHERE	assort_lcode = ssa_stycollns[idx].upper 
					AND		assort_id = 1

					IF status = NOTFOUND THEN
 						LET p_display = "invalid upper assortment "
						CALL messagebox(p_display,1)  		
						NEXT FIELD upper
					END IF
					DISPLAY ssa_stycollns[idx].assort_desc
					TO sc_stycollns[sidx].assort_desc
					ATTRIBUTE (NORMAL)
				#ELSE
 				#	LET p_display = "upper assortment must not blank "
				#	CALL messagebox(p_display,1)  		
				#	NEXT FIELD upper
				END IF
}

			AFTER FIELD trend1
				IF	ssa_stycollns[idx].trend1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_stycollns")
					SELECT	web_desc
					INTO	 ssa_stycollns[idx].trend1_desc 
					FROM	web_trend
					WHERE	web_id = ssa_stycollns[idx].trend1 
					AND		web_season = g_style.season

					IF status = NOTFOUND THEN
 						LET p_display = "invalid trend "
						CALL messagebox(p_display,1)  		
						NEXT FIELD trend1
					END IF
				END IF

			AFTER FIELD trend2
				IF	ssa_stycollns[idx].trend2  IS NOT  NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_stycollns")
					SELECT	web_desc
					INTO	 ssa_stycollns[idx].trend2_desc 
					FROM	web_trend
					WHERE	web_id = ssa_stycollns[idx].trend2
					AND		web_season = g_style.season

					IF status = NOTFOUND THEN
 						LET p_display = "invalid trend "
						CALL messagebox(p_display,1)  		
						NEXT FIELD trend2
					END IF
				END IF

			##AFTER ROW
{
			AFTER FIELD hero_image
##let p_image = ssa_stycollns[idx].hero_image
display "AU idx: ",idx, " ",p_image
				#R02 >>
                LET idx = arr_curr()
                LET sidx = scr_line()
				##LET ssa_stycollns[idx].dw_auhero_img =  ssa_stycollns[idx].hero_image		#R03
				#R02 <<
                 IF arr_curr() = arr_count() THEN
                    IF fgl_lastkey() = fgl_keyval("DOWN") OR
                    fgl_lastkey() = fgl_keyval("TAB") OR
                    fgl_lastkey() = fgl_keyval("RIGHT") OR
                    fgl_lastkey() = fgl_keyval("RETURN") THEN
                        ERROR "no more color line"
##display "afer row code", g_pack_code, g_pack_type, " ",idx
                        #R01 NEXT FIELD upper
                        #R03 NEXT FIELD  dw_auhero_img			#R01
                        NEXT FIELD  nz_hero_image			#R03
                    END IF
                END IF
}

			#R03 >>
{
			AFTER FIELD nz_hero_image
                LET idx = arr_curr()
                LET sidx = scr_line()
				##LET ssa_stycollns[idx].dw_nzhero_img =  ssa_stycollns[idx].nz_hero_image
                IF arr_curr() = arr_count() THEN
                    IF fgl_lastkey() = fgl_keyval("DOWN") OR
                    fgl_lastkey() = fgl_keyval("TAB") OR
                    fgl_lastkey() = fgl_keyval("RIGHT") OR
                    fgl_lastkey() = fgl_keyval("RETURN") THEN
                        ERROR "no more color line"
##display "afer row code", g_pack_code, g_pack_type, " ",idx
                        NEXT FIELD  dw_auhero_img			
                    END IF
                END IF
}
			#R03 <<
##display "NZ idx: ",idx

			#R01 >> DW
{
			AFTER FIELD dw_auhero_img
                 IF arr_curr() = arr_count() THEN
                    IF fgl_lastkey() = fgl_keyval("DOWN") OR
                    fgl_lastkey() = fgl_keyval("TAB") OR
                    fgl_lastkey() = fgl_keyval("RIGHT") OR
                    fgl_lastkey() = fgl_keyval("RETURN") THEN
                        ERROR "no more color line"
##display "afer row code", g_pack_code, g_pack_type, " ",idx
                        NEXT FIELD dw_nzhero_img
                    END IF
                END IF
                LET idx = arr_curr()
                LET sidx = scr_line()

			AFTER FIELD dw_nzhero_img
                 IF arr_curr() = arr_count() THEN
                    IF fgl_lastkey() = fgl_keyval("DOWN") OR
                    fgl_lastkey() = fgl_keyval("TAB") OR
                    fgl_lastkey() = fgl_keyval("RIGHT") OR
                    fgl_lastkey() = fgl_keyval("RETURN") THEN
                        ERROR "no more color line"
##display "afer row code", g_pack_code, g_pack_type, " ",idx
                        NEXT FIELD upper
                    END IF
                END IF
                LET idx = arr_curr()
                LET sidx = scr_line()
		#R01 <<
}

			#R04 >>
			ON CHANGE  publish
				LET idx = DIALOG.getCurrentRow("sc_stycollns")
				LET ssa_stycollns[idx].hero_image = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].nz_hero_image = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].nz_publish = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].dw_auhero_img = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].dw_nzhero_img = ssa_stycollns[idx].publish 
				DISPLAY ssa_stycollns[idx].* TO sc_stycollns[idx].*
				ATTRIBUTE(NORMAL)

			AFTER FIELD publish
				LET idx = DIALOG.getCurrentRow("sc_stycollns")
				LET ssa_stycollns[idx].hero_image = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].nz_hero_image = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].nz_publish = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].dw_auhero_img = ssa_stycollns[idx].publish 
				LET ssa_stycollns[idx].dw_nzhero_img = ssa_stycollns[idx].publish 
				DISPLAY ssa_stycollns[idx].* TO sc_stycollns[idx].*
				ATTRIBUTE(NORMAL)
			#R04 <<

			#r03 >>
			AFTER FIELD dw_sghero_img
                 IF arr_curr() = arr_count() THEN
                    IF fgl_lastkey() = fgl_keyval("DOWN") OR
                    fgl_lastkey() = fgl_keyval("TAB") OR
                    fgl_lastkey() = fgl_keyval("RIGHT") OR
                    fgl_lastkey() = fgl_keyval("RETURN") THEN
                        ERROR "no more color line"
##display "afer row code", g_pack_code, g_pack_type, " ",idx
                        NEXT FIELD upper
                    END IF
                END IF
                LET idx = arr_curr()
                LET sidx = scr_line()
			#r03 <<

			AFTER FIELD colour
				LET idx = DIALOG.getCurrentRow("sc_stycollns")
				SELECT	colour_name
				INTO	ssa_stycollns[idx].colour_name
				FROM	colour
				WHERE	colour = ssa_stycollns[idx].colour
				DISPLAY ssa_stycollns[idx].* TO sc_stycollns[idx].*
				ATTRIBUTE(NORMAL)

   	       ON ACTION cancel
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG 

   	       ON KEY (F10)
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG 
			
			#AFTER INPUT
			ON ACTION accept
				MESSAGE ""
				##LET s_maxidx = ARR_COUNT()
##display "accept ",s_maxidx
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				FOR idx = 1 TO s_maxidx
					##IF ssa_stycollns[idx].upper IS NULL THEN
						##LET p_text = " assortment must be entered"
						##MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						##LET p_retstat = FALSE
						##EXIT FOR
					##END IF
					IF ssa_stycollns[idx].publish IS NULL THEN
						LET p_text = " publish must be entered"
						MESSAGE "ERROR line ",idx USING "<&",p_text CLIPPED
						LET p_retstat = FALSE
						EXIT FOR
					END IF
				END FOR			
				EXIT DIALOG
			END INPUT

	        #R02 IF p_retstat OR p_f10 THEN
	          	#R02 EXIT WHILE
	       	#R02 END IF
		#R02 END WHILE
		##MESSAGE ""
		##LET g_void = sty_entW("BROWSE")
   	 	#R03 INPUT ARRAY ssa_imglns
    	#R02 WITHOUT DEFAULTS 
    	#R03 FROM sc_imglns.*
		#R03 ATTRIBUTE(WITHOUT DEFAULTS=TRUE, APPEND ROW=FALSE, INSERT ROW=FALSE, DELETE ROW=FALSE)
		
{
			BEFORE ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
				LET s_maxidx = ARR_COUNT()
				LET ssa_imglns[1].label1 = "BONANZA_GREY-SUEDE_TOP"
				LET p_label = "BONANZA_GREY-SUEDE_TOP"
				LET ssa_imglns[1].image1 =  p_label

				LET ssa_imglns[1].label2 = "BONANZA_GREY-SUEDE_TOP"
				LET p_label = "BONANZA_GREY-SUEDE_TOP"
				LET ssa_imglns[1].image2 =  p_label

				LET ssa_imglns[1].label3 = "BONANZA_GREY-SUEDE_TOP"
				LET p_label = "BONANZA_GREY-SUEDE_TOP"
				LET ssa_imglns[1].image3 =  p_label

				LET ssa_imglns[1].label4 = "BONANZA_GREY-SUEDE_TOP"
				LET p_label = "BONANZA_GREY-SUEDE_TOP"
				LET ssa_imglns[1].image4 =  p_label

				LET ssa_imglns[1].label5 = "BONANZA_GREY-SUEDE_TOP"
				LET p_label = "BONANZA_GREY-SUEDE_TOP"
				LET ssa_imglns[1].image5 =  p_label
			AFTER ROW
				LET idx = ARR_CURR()
				LET sidx = SCR_LINE()
}
		
			#R03 ON ACTION zoom12
				#R03 LET p_label1 = openwindowbox()
				#R03 IF p_label1 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET ssa_imglns[idx].ilabel1 =  p_label1 CLIPPED
					#R03 LET ssa_imglns[idx].image1 =  p_label1 CLIPPED
					#R03 DISPLAY ssa_imglns[idx].image1
					#R03 TO sc_imglns[sidx].image1
					#R03 ATTRIBUTE (NORMAL)
					#R03 DISPLAY ssa_imglns[idx].ilabel1
					#R03 TO sc_imglns[sidx].ilabel1
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF

			#R03 ON ACTION zoom13
				#R03 LET p_label2 = openwindowbox()
				#R03 IF p_label2 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET ssa_imglns[idx].ilabel2 =  p_label2 CLIPPED
					#R03 LET ssa_imglns[idx].image2 =  p_label2 CLIPPED
					#R03 DISPLAY ssa_imglns[idx].image2
					#R03 TO sc_imglns[sidx].image2
					#R03 ATTRIBUTE (NORMAL)
					#R03 DISPLAY ssa_imglns[idx].ilabel2
					#R03 TO sc_imglns[sidx].ilabel2
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF

			#R03 ON ACTION zoom14
				#R03 LET p_label3 = openwindowbox()
				#R03 IF p_label3 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET ssa_imglns[idx].ilabel3 =  p_label3 CLIPPED
					#R03 LET ssa_imglns[idx].image3 =  p_label3 CLIPPED
					#R03 DISPLAY ssa_imglns[idx].image3
					#R03 TO sc_imglns[sidx].image3
					#R03 ATTRIBUTE (NORMAL)
					#R03 DISPLAY ssa_imglns[idx].ilabel3
					#R03 TO sc_imglns[sidx].ilabel3
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
#R03 
			#R03 ON ACTION zoom15
				#R03 LET p_label4 = openwindowbox()
				#R03 IF p_label4 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET ssa_imglns[idx].ilabel4 =  p_label4 CLIPPED
					#R03 LET ssa_imglns[idx].image4 =  p_label4 CLIPPED
					#R03 DISPLAY ssa_imglns[idx].image4
					#R03 TO sc_imglns[sidx].image4
					#R03 ATTRIBUTE (NORMAL)
					#R03 DISPLAY ssa_imglns[idx].ilabel4
					#R03 TO sc_imglns[sidx].ilabel4
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
#R03 
			#R03 ON ACTION zoom16
				#R03 LET p_label5 = openwindowbox()
				#R03 IF p_label5 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET ssa_imglns[idx].ilabel5 =  p_label5 CLIPPED
					#R03 LET ssa_imglns[idx].image5 =  p_label5 CLIPPED
					#R03 DISPLAY ssa_imglns[idx].image5
					#R03 TO sc_imglns[sidx].image5
					#R03 ATTRIBUTE (NORMAL)
					#R03 DISPLAY ssa_imglns[idx].ilabel5
					#R03 TO sc_imglns[sidx].ilabel5
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
#R03 
			#R03 BEFORE FIELD ilabel1	
				#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
				#R03 LET p_prev_ilabel1 =  ssa_imglns[idx].ilabel1
				#R03 IF p_prev_ilabel1 IS NULL THEN
					#R03 LET p_prev_ilabel1 = " "
				#R03 END IF
			#R03 BEFORE FIELD ilabel2
				#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
				#R03 LET p_prev_ilabel2 =  ssa_imglns[idx].ilabel2
				#R03 IF p_prev_ilabel2 IS NULL THEN
					#R03 LET p_prev_ilabel2 = " "
				#R03 END IF
			#R03 BEFORE FIELD ilabel3	
				#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
				#R03 LET p_prev_ilabel3 =  ssa_imglns[idx].ilabel3
				#R03 IF p_prev_ilabel3 IS NULL THEN
					#R03 LET p_prev_ilabel3 = " "
				#R03 END IF
			#R03 BEFORE FIELD ilabel4	
				#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
				#R03 LET p_prev_ilabel4 =  ssa_imglns[idx].ilabel4
				#R03 IF p_prev_ilabel4 IS NULL THEN
					#R03 LET p_prev_ilabel4 = " "
				#R03 END IF
			#R03 BEFORE FIELD ilabel5	
				#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
				#R03 LET p_prev_ilabel5 =  ssa_imglns[idx].ilabel5
				#R03 IF p_prev_ilabel5 IS NULL THEN
					#R03 LET p_prev_ilabel5 = " "
				#R03 END IF
#R03 
#R03 
			#R03 AFTER FIELD ilabel1	
				 #R03 IF ssa_imglns[idx].ilabel1 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET p_label1 = ssa_imglns[idx].ilabel1
					#R03 LET p_label1x = ssa_imglns[idx].ilabel1
				 	#R03 IF  p_label1x[1,23] != g_path THEN
 						#R03 LET p_display = "invalid label path "
						#R03 CALL messagebox(p_display,1)  		
						#R03 NEXT FIELD ilabel1
					#R03 END IF
					#R03 LET ssa_imglns[idx].image1 =  p_label1 CLIPPED
					#R03 IF p_label1 != p_prev_ilabel1 THEN
						#R03 LET ssa_imglns1[idx].mod_flg = "Y" 
					#R03 END IF
					#R03 DISPLAY ssa_imglns[idx].image1
					#R03 TO sc_imglns[sidx].image1
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF

			#R03 AFTER FIELD ilabel2
				 #R03 IF ssa_imglns[idx].ilabel2 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET p_label2x = ssa_imglns[idx].ilabel2
				 	#R03 IF  p_label2x[1,23] != g_path THEN
 						#R03 LET p_display = "invalid label path "
						#R03 CALL messagebox(p_display,1)  		
						#R03 NEXT FIELD ilabel2
					#R03 END IF
					#R03 LET p_label2 = ssa_imglns[idx].ilabel2
					#R03 LET ssa_imglns[idx].image2 =  p_label2 CLIPPED
					#R03 IF p_label2 != p_prev_ilabel2 THEN
						#R03 LET ssa_imglns1[idx].mod_flg = "Y" 
					#R03 END IF
					#R03 DISPLAY ssa_imglns[idx].image2
					#R03 TO sc_imglns[sidx].image2
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
#R03 
			#R03 AFTER FIELD ilabel3
				 #R03 IF ssa_imglns[idx].ilabel3 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET p_label3x = ssa_imglns[idx].ilabel3
				 	#R03 IF  p_label3x[1,23] != g_path THEN
 						#R03 LET p_display = "invalid label path "
						#R03 CALL messagebox(p_display,1)  		
						#R03 NEXT FIELD ilabel3
					#R03 END IF
					#R03 LET p_label3 = ssa_imglns[idx].ilabel3
					#R03 LET ssa_imglns[idx].image3 =  p_label3 CLIPPED
					#R03 IF p_label3 != p_prev_ilabel3 THEN
						#R03 LET ssa_imglns1[idx].mod_flg = "Y" 
					#R03 END IF
					#R03 DISPLAY ssa_imglns[idx].image3
					#R03 TO sc_imglns[sidx].image3
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
			#R03 AFTER FIELD ilabel4
				 #R03 IF ssa_imglns[idx].ilabel4 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET p_label4x = ssa_imglns[idx].ilabel4
				 	#R03 IF  p_label4x[1,23] != g_path THEN
 						#R03 LET p_display = "invalid label path "
						#R03 CALL messagebox(p_display,1)  		
						#R03 NEXT FIELD ilabel4
					#R03 END IF
					#R03 LET p_label4 = ssa_imglns[idx].ilabel4
					#R03 LET ssa_imglns[idx].image4 =  p_label4 CLIPPED
					#R03 IF p_label4 != p_prev_ilabel4 THEN
						#R03 LET ssa_imglns1[idx].mod_flg = "Y" 
					#R03 END IF
					#R03 DISPLAY ssa_imglns[idx].image4
					#R03 TO sc_imglns[sidx].image4
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
			#R03 AFTER FIELD ilabel5	
				 #R03 IF ssa_imglns[idx].ilabel5 IS NOT NULL THEN
					#R03 LET idx = DIALOG.getCurrentRow("sc_imglns")
					#R03 LET p_label5x = ssa_imglns[idx].ilabel5
				 	#R03 IF  p_label5x[1,23] != g_path THEN
 						#R03 LET p_display = "invalid label path "
						#R03 CALL messagebox(p_display,1)  		
						#R03 NEXT FIELD ilabel5
					#R03 END IF
					#R03 LET p_label5 = ssa_imglns[idx].ilabel5
					#R03 LET ssa_imglns[idx].image5 =  p_label5 CLIPPED
					#R03 IF p_label5 != p_prev_ilabel5 THEN
						#R03 LET ssa_imglns1[idx].mod_flg = "Y" 
					#R03 END IF
					#R03 DISPLAY ssa_imglns[idx].image5
					#R03 TO sc_imglns[sidx].image5
					#R03 ATTRIBUTE (NORMAL)
				#R03 END IF
#R03 
#R03 
   	       #R03 ON ACTION cancel
				#R03 ##LET s_maxidx= ARR_COUNT()
				#R03 LET g_void = sty_entW("INIT")
				#R03 LET g_void = sty_entW("SELECT")
				#R03 LET g_void = sty_entW("SELECTX")
				#R03#R03  LET p_f10 = TRUE
				#R03 LET p_retstat = FALSE
				#R03 EXIT DIALOG
#R03 
   	       #R03 ON KEY (F10)
				#R03 ##LET s_maxidx= ARR_COUNT()
				#R03 LET g_void = sty_entW("INIT")
				#R03 LET g_void = sty_entW("SELECT")
				#R03 LET g_void = sty_entW("SELECTX")
				#R03 LET p_f10 = TRUE
				#R03 LET p_retstat = FALSE
				#R03 EXIT DIALOG
		#R03 	
			#R03 ##AFTER INPUT
			#R03 ON ACTION accept
				#R03 MESSAGE ""
				#R03 ##LET s_maxidx = ARR_COUNT()
#R03 display "accept 1",s_maxidx
				#R03 LET p_retstat = TRUE
				#R03 IF s_maxidx = 0 THEN
					#R03 ERROR	"must have at least one report line"
					#R03 LET p_retstat = FALSE
				#R03 END IF
				#R03 #FOR idx = 1 TO s_maxidx
				#R03 #END FOR			
				#R03 EXIT DIALOG
			#R03 END INPUT
	        #R03 #R02 IF p_retstat OR p_f10 THEN
	          	#R03 #R02 EXIT WHILE
	       	#R03 #R02 END IF
		#R03 #R02 END WHILE
			#R03 #R02 >> DW images
		# R02 >>
   	 	INPUT ARRAY ssa_dwimglns
    	FROM sc_dwimglns.*
		ATTRIBUTE(WITHOUT DEFAULTS=TRUE, APPEND ROW=FALSE, INSERT ROW=FALSE, DELETE ROW=FALSE)
		
			BEFORE INPUT			#R05
			    LET p_url_label = "https://mail.brandbank.com.au/flowsd/"		#R05

			ON ACTION zoom20
				LET p_dwlabel1 = dwopenwindowbox()
				IF p_dwlabel1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_auimage1 = p_dwlabel1			
					LET p_auimage1 = p_url_label CLIPPED,p_auimage1[4,100]
#display "au url 1",p_dwlabel1," image ",p_auimage1
					#R05 <<
					LET ssa_dwimglns[idx].dwilabel1 =  p_dwlabel1 CLIPPED
					#R05 LET ssa_dwimglns[idx].dwimage1 =  p_dwlabel1 CLIPPED
					LET ssa_dwimglns[idx].dwimage1 =   p_auimage1 CLIPPED				#R05

					DISPLAY ssa_dwimglns[idx].dwimage1
					TO sc_dwimglns[sidx].dwimage1
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_dwimglns[idx].dwilabel1
					TO sc_dwimglns[sidx].dwilabel1
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom21
				LET p_dwlabel2 = dwopenwindowbox()
				IF p_dwlabel2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					#R05 >>
					LET p_auimage2 = p_dwlabel2			
					LET p_auimage2 = p_url_label CLIPPED,p_auimage2[4,100]
#display "au url 2",p_dwlabel2," image ",p_auimage2
					#R05 <<
					LET ssa_dwimglns[idx].dwilabel2 =  p_dwlabel2 CLIPPED
					#R05 LET ssa_dwimglns[idx].dwimage2 =  p_dwlabel2 CLIPPED
					LET ssa_dwimglns[idx].dwimage2 =   p_auimage2 CLIPPED				#R05
					DISPLAY ssa_dwimglns[idx].dwimage2
					TO sc_dwimglns[sidx].dwimage2
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_dwimglns[idx].dwilabel2
					TO sc_dwimglns[sidx].dwilabel2
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom22
				LET p_dwlabel3 = dwopenwindowbox()
				IF p_dwlabel3 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					#R05 >>
					LET p_auimage3 = p_dwlabel3			
					LET p_auimage3 = p_url_label CLIPPED,p_auimage3[4,100]
#display "au url 3",p_dwlabel3," image ",p_auimage3
					#R02 <<
					LET ssa_dwimglns[idx].dwilabel3 =  p_dwlabel3 CLIPPED
					#R05 LET ssa_dwimglns[idx].dwimage3 =  p_dwlabel3 CLIPPED
					LET ssa_dwimglns[idx].dwimage3 =   p_auimage3 CLIPPED				#R05
					DISPLAY ssa_dwimglns[idx].dwimage3
					TO sc_dwimglns[sidx].dwimage3
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_dwimglns[idx].dwilabel3
					TO sc_dwimglns[sidx].dwilabel3
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom23
				LET p_dwlabel4 = dwopenwindowbox()
				IF p_dwlabel4 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					#R05 >>
					LET p_auimage4 = p_dwlabel4			
					LET p_auimage4 = p_url_label CLIPPED,p_auimage4[4,100]
#display "au url 4",p_dwlabel4," image ",p_auimage4
					#R05 <<
					LET ssa_dwimglns[idx].dwilabel4 =  p_dwlabel4 CLIPPED
					#R05 LET ssa_dwimglns[idx].dwimage4 =  p_dwlabel4 CLIPPED
					LET ssa_dwimglns[idx].dwimage4 =   p_auimage4 CLIPPED				#R05

					DISPLAY ssa_dwimglns[idx].dwimage4
					TO sc_dwimglns[sidx].dwimage4
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_dwimglns[idx].dwilabel4
					TO sc_dwimglns[sidx].dwilabel4
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom24
				LET p_dwlabel5 = dwopenwindowbox()
				IF p_dwlabel5 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					#R05 >>
					LET p_auimage5 = p_dwlabel5			
					LET p_auimage5 = p_url_label CLIPPED,p_auimage5[4,100]
#display "au url 5",p_dwlabel5," image ",p_auimage5
					#R05 <<
					LET ssa_dwimglns[idx].dwilabel5 =  p_dwlabel5 CLIPPED
					#R05 LET ssa_dwimglns[idx].dwimage5 =  p_dwlabel5 CLIPPED
					LET ssa_dwimglns[idx].dwimage5 =   p_auimage5 CLIPPED				#R05

					DISPLAY ssa_dwimglns[idx].dwimage5
					TO sc_dwimglns[sidx].dwimage5
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_dwimglns[idx].dwilabel5
					TO sc_dwimglns[sidx].dwilabel5
					ATTRIBUTE (NORMAL)
				END IF

			BEFORE FIELD dwilabel1	
				LET idx = DIALOG.getCurrentRow("sc_dwimglns")
				LET p_prev_dwilabel1 =  ssa_dwimglns[idx].dwilabel1
				IF p_prev_dwilabel1 IS NULL THEN
					LET p_prev_dwilabel1 = " "
				END IF
				LET p_auimage1 =  ssa_dwimglns[idx].dwimage1			#R05

			BEFORE FIELD dwilabel2
				LET idx = DIALOG.getCurrentRow("sc_dwimglns")
				LET p_prev_dwilabel2 =  ssa_dwimglns[idx].dwilabel2
				IF p_prev_dwilabel2 IS NULL THEN
					LET p_prev_dwilabel2 = " "
				END IF
				LET p_auimage2 =  ssa_dwimglns[idx].dwimage2			#R05

			BEFORE FIELD dwilabel3	
				LET idx = DIALOG.getCurrentRow("sc_dwimglns")
				LET p_prev_dwilabel3 =  ssa_dwimglns[idx].dwilabel3
				IF p_prev_dwilabel3 IS NULL THEN
					LET p_prev_dwilabel3 = " "
				END IF
				LET p_auimage3 =  ssa_dwimglns[idx].dwimage3			#R05

			BEFORE FIELD dwilabel4	
				LET idx = DIALOG.getCurrentRow("sc_dwimglns")
				LET p_prev_dwilabel4 =  ssa_dwimglns[idx].dwilabel4
				IF p_prev_dwilabel4 IS NULL THEN
					LET p_prev_dwilabel4 = " "
				END IF
				LET p_auimage4 =  ssa_dwimglns[idx].dwimage4			#R05

			BEFORE FIELD dwilabel5	
				LET idx = DIALOG.getCurrentRow("sc_dwimglns")
				LET p_prev_dwilabel5 =  ssa_dwimglns[idx].dwilabel5
				IF p_prev_dwilabel5 IS NULL THEN
					LET p_prev_dwilabel5 = " "
				END IF
				LET p_auimage5 =  ssa_dwimglns[idx].dwimage5			#R05


			AFTER FIELD dwilabel1	
				 IF ssa_dwimglns[idx].dwilabel1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					LET p_dwlabel1 = ssa_dwimglns[idx].dwilabel1
					LET p_dwlabel1x = ssa_dwimglns[idx].dwilabel1
				 	IF  p_dwlabel1x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel1
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
#display "AFTER FIELD AU image 1: ", p_auimage1[38,100] ," ", p_dwlabel1x[4,30] 
					IF p_auimage1[38,100] != p_dwlabel1x[4,30] THEN			
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of AU image1, but",
							            "\nthe actual AU image1 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid AU image1 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel1
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_dwimglns[idx].dwimage1 =  p_auimage1 CLIPPED				#R05
					#R05 LET ssa_dwimglns[idx].dwimage1 =  p_dwlabel1 CLIPPED
					IF p_dwlabel1 != p_prev_dwilabel1 THEN
						LET ssa_dwimglns1[idx].dwmod_flg = "Y" 
					END IF
					DISPLAY ssa_dwimglns[idx].dwimage1
					TO sc_dwimglns[sidx].dwimage1
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD dwilabel2
				 IF ssa_dwimglns[idx].dwilabel2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					LET p_dwlabel2x = ssa_dwimglns[idx].dwilabel2
				 	IF  p_dwlabel2x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel2
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
#display "HERE 1: ",p_auimage2," ",p_label2x
					IF p_auimage2[38,100] != p_dwlabel2x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of AU image2, but",
							            "\nthe actual AU image2 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid AU image2 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel2
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_dwimglns[idx].dwimage2 =  p_auimage2 CLIPPED				#R05
					#R05 LET ssa_dwimglns[idx].dwimage2 =  p_dwlabel2 CLIPPED
					LET p_dwlabel2 = ssa_dwimglns[idx].dwilabel2
					IF p_dwlabel2 != p_prev_dwilabel2 THEN
						LET ssa_dwimglns1[idx].dwmod_flg = "Y" 
					END IF
					DISPLAY ssa_dwimglns[idx].dwimage2
					TO sc_dwimglns[sidx].dwimage2
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD dwilabel3
				 IF ssa_dwimglns[idx].dwilabel3 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					LET p_dwlabel3x = ssa_dwimglns[idx].dwilabel3
				 	IF  p_dwlabel3x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel3
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_auimage3[38,100] != p_dwlabel3x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of AU image3, but",
							            "\nthe actual AU image3 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid AU image3 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel3
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_dwimglns[idx].dwimage3 =  p_auimage3 CLIPPED				#R05
					#R05 LET ssa_dwimglns[idx].dwimage3 =  p_dwlabel3 CLIPPED
					LET p_dwlabel3 = ssa_dwimglns[idx].dwilabel3
					IF p_dwlabel3 != p_prev_dwilabel3 THEN
						LET ssa_dwimglns1[idx].dwmod_flg = "Y" 
					END IF
					DISPLAY ssa_dwimglns[idx].dwimage3
					TO sc_dwimglns[sidx].dwimage3
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD dwilabel4
				 IF ssa_dwimglns[idx].dwilabel4 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					LET p_dwlabel4x = ssa_dwimglns[idx].dwilabel4
				 	IF  p_dwlabel4x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel4
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_auimage4[38,100] != p_dwlabel4x[4,30] THEN				#rxx
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of AU image4, but",
							            "\nthe actual AU image4 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid AU image4 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel4
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_dwimglns[idx].dwimage4 =  p_auimage4 CLIPPED				#R05
					#R05 LET ssa_dwimglns[idx].dwimage4 =  p_dwlabel4 CLIPPED
					LET p_dwlabel4 = ssa_dwimglns[idx].dwilabel4
					IF p_dwlabel4 != p_prev_dwilabel4 THEN
						LET ssa_dwimglns1[idx].dwmod_flg = "Y" 
					END IF
					DISPLAY ssa_dwimglns[idx].dwimage4
					TO sc_dwimglns[sidx].dwimage4
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD dwilabel5	
				 IF ssa_dwimglns[idx].dwilabel5 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_dwimglns")
					LET p_dwlabel5x = ssa_dwimglns[idx].dwilabel5
				 	IF  p_dwlabel5x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel5
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_auimage5[38,100] != p_dwlabel5x[4,30] THEN			
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of AU image5, but",
							            "\nthe actual AU image5 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid AU image5 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD dwilabel5
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_dwimglns[idx].dwimage5 =  p_auimage5 CLIPPED				#R05
					#R05 LET ssa_dwimglns[idx].dwimage5 =  p_dwlabel5 CLIPPED
					LET p_dwlabel5 = ssa_dwimglns[idx].dwilabel5
					IF p_dwlabel5 != p_prev_dwilabel5 THEN
						LET ssa_dwimglns1[idx].dwmod_flg = "Y" 
					END IF
					DISPLAY ssa_dwimglns[idx].dwimage5
					TO sc_dwimglns[sidx].dwimage5
					ATTRIBUTE (NORMAL)
				END IF


   	       ON ACTION cancel
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG

   	       ON KEY (F10)
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG
			
			##AFTER INPUT
			ON ACTION accept
				MESSAGE ""
				##LET s_maxidx = ARR_COUNT()
#display "accept 1",s_maxidx
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				#FOR idx = 1 TO s_maxidx
				#END FOR			
				EXIT DIALOG
			END INPUT
		# R03 >>
   	 	INPUT ARRAY ssa_hkimglns
    	FROM sc_hkimglns.*
		ATTRIBUTE(WITHOUT DEFAULTS=TRUE, APPEND ROW=FALSE, INSERT ROW=FALSE, DELETE ROW=FALSE)

			BEFORE INPUT			#R05
			    LET p_url_label = "https://mail.brandbank.com.au/flowsd/"				#R05
		
			ON ACTION zoom  INFIELD hkilabel1
				LET p_hklabel1 = dwopenwindowbox()
				IF p_hklabel1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_hkimage1 = p_hklabel1			
					LET p_hkimage1 = p_url_label CLIPPED,p_hkimage1[4,100]
##display "hk url 1",p_hklabel1," image ",p_hkimage1
					#R05 <<
					LET ssa_hkimglns[idx].hkilabel1 =  p_hklabel1 CLIPPED
					LET ssa_hkimglns[idx].hkimage1 =   p_hkimage1 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage1 =  p_hklabel1 CLIPPED

					DISPLAY ssa_hkimglns[idx].hkimage1
					TO sc_hkimglns[sidx].hkimage1
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_hkimglns[idx].hkilabel1
					TO sc_hkimglns[sidx].hkilabel1
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD hkilabel2
				LET p_hklabel2 = dwopenwindowbox()
				IF p_hklabel2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_hkimage2 = p_hklabel2			
					LET p_hkimage2 = p_url_label CLIPPED,p_hkimage2[4,100]
##display "hk url 2",p_hklabel1, "2 image ",p_hkimage2
					#R02 <<
					LET ssa_hkimglns[idx].hkilabel2 =  p_hklabel2 CLIPPED
					LET ssa_hkimglns[idx].hkimage2 =   p_hkimage2 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage2 =  p_hklabel2 CLIPPED

					DISPLAY ssa_hkimglns[idx].hkimage2
					TO sc_hkimglns[sidx].hkimage2
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_hkimglns[idx].hkilabel2
					TO sc_hkimglns[sidx].hkilabel2
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD hkilabel3
				LET p_hklabel3 = dwopenwindowbox()
				IF p_hklabel3 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_hkimage3 = p_hklabel3			
					LET p_hkimage3 = p_url_label CLIPPED,p_hkimage3[4,100]
##display "hk url 3",p_hklabel3," image ",p_hkimage3
					#R05 <<
					LET ssa_hkimglns[idx].hkilabel3 =  p_hklabel3 CLIPPED
					LET ssa_hkimglns[idx].hkimage3 =   p_hkimage3 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage3 =  p_hklabel3 CLIPPED

					DISPLAY ssa_hkimglns[idx].hkimage3
					TO sc_hkimglns[sidx].hkimage3
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_hkimglns[idx].hkilabel3
					TO sc_hkimglns[sidx].hkilabel3
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD hkilabel4
				LET p_hklabel4 = dwopenwindowbox()
				IF p_hklabel4 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_hkimage4 = p_hklabel4			
					LET p_hkimage4 = p_url_label CLIPPED,p_hkimage4[4,100]
#display "hk url 4",p_hklabel4," image ",p_hkimage4
					#R05 <<
					LET ssa_hkimglns[idx].hkilabel4 =  p_hklabel4 CLIPPED
					LET ssa_hkimglns[idx].hkimage4 =   p_hkimage4 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage4 =  p_hklabel4 CLIPPED
					DISPLAY ssa_hkimglns[idx].hkimage4
					TO sc_hkimglns[sidx].hkimage4
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_hkimglns[idx].hkilabel4
					TO sc_hkimglns[sidx].hkilabel4
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD hkilabel5
				LET p_hklabel5 = dwopenwindowbox()
				IF p_hklabel5 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_hkimage5 = p_hklabel5			
					LET p_hkimage5 = p_url_label CLIPPED,p_hkimage5[4,100]
##display "hk url 5",p_hklabel5," image ",p_hkimage5
					#R05 <<
					LET ssa_hkimglns[idx].hkilabel5 =  p_hklabel5 CLIPPED
					LET ssa_hkimglns[idx].hkimage5 =   p_hkimage5 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage5 =  p_hklabel5 CLIPPED

					DISPLAY ssa_hkimglns[idx].hkimage5
					TO sc_hkimglns[sidx].hkimage5
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_hkimglns[idx].hkilabel5
					TO sc_hkimglns[sidx].hkilabel5
					ATTRIBUTE (NORMAL)
				END IF

			BEFORE FIELD hkilabel1	
				LET idx = DIALOG.getCurrentRow("sc_hkimglns")
				LET p_prev_hkilabel1 =  ssa_hkimglns[idx].hkilabel1
				IF p_prev_hkilabel1 IS NULL THEN
					LET p_prev_hkilabel1 = " "
				END IF
				LET p_hkimage1 =  ssa_hkimglns[idx].hkimage1			#R05

			BEFORE FIELD hkilabel2
				LET idx = DIALOG.getCurrentRow("sc_hkimglns")
				LET p_prev_hkilabel2 =  ssa_hkimglns[idx].hkilabel2
				IF p_prev_hkilabel2 IS NULL THEN
					LET p_prev_hkilabel2 = " "
				END IF
				LET p_hkimage2 =  ssa_hkimglns[idx].hkimage2			#R05
				##display "BEFORE FIELD hk 2: ", p_hkimage2 ," ",  ssa_hkimglns[idx].hkimage2			#R05


			BEFORE FIELD hkilabel3	
				LET idx = DIALOG.getCurrentRow("sc_hkimglns")
				LET p_prev_hkilabel3 =  ssa_hkimglns[idx].hkilabel3
				IF p_prev_hkilabel3 IS NULL THEN
					LET p_prev_hkilabel3 = " "
				END IF
				LET p_hkimage3 =  ssa_hkimglns[idx].hkimage3			#R05

			BEFORE FIELD hkilabel4	
				LET idx = DIALOG.getCurrentRow("sc_hkimglns")
				LET p_prev_hkilabel4 =  ssa_hkimglns[idx].hkilabel4
				IF p_prev_hkilabel4 IS NULL THEN
					LET p_prev_hkilabel4 = " "
				END IF
				LET p_hkimage4 =  ssa_hkimglns[idx].hkimage4			#R05

			BEFORE FIELD hkilabel5	
				LET idx = DIALOG.getCurrentRow("sc_hkimglns")
				LET p_prev_hkilabel5 =  ssa_hkimglns[idx].hkilabel5
				IF p_prev_hkilabel5 IS NULL THEN
					LET p_prev_hkilabel5 = " "
				END IF
				LET p_hkimage5 =  ssa_hkimglns[idx].hkimage5			#R05


			AFTER FIELD hkilabel1	
				 IF ssa_hkimglns[idx].hkilabel1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					LET p_hklabel1 = ssa_hkimglns[idx].hkilabel1
					LET p_hklabel1x = ssa_hkimglns[idx].hkilabel1
				 	IF  p_hklabel1x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel1
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_hkimage1[38,100] != p_hklabel1x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of HK image1, but",
							            "\nthe actual HK image1 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid HK image1 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel1
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_hkimglns[idx].hkimage1 =  p_hkimage1 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage1 =  p_hklabel1 CLIPPED
					IF p_hklabel1 != p_prev_hkilabel1 THEN
						LET ssa_hkimglns1[idx].hkmod_flg = "Y" 
					END IF
					DISPLAY ssa_hkimglns[idx].hkimage1
					TO sc_hkimglns[sidx].hkimage1
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD hkilabel2
				 IF ssa_hkimglns[idx].hkilabel2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					LET p_hklabel2x = ssa_hkimglns[idx].hkilabel2
				 	IF  p_hklabel2x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel2
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_hkimage2[38,100] != p_hklabel2x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of HK image2, but",
							            "\nthe actual HK image2 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid HK image2 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel2
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_hkimglns[idx].hkimage2 =  p_hkimage2 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage2 =  p_hklabel2 CLIPPED
					LET p_hklabel2 = ssa_hkimglns[idx].hkilabel2
					IF p_hklabel2 != p_prev_hkilabel2 THEN
						LET ssa_hkimglns1[idx].hkmod_flg = "Y" 
					END IF
					DISPLAY ssa_hkimglns[idx].hkimage2
					TO sc_hkimglns[sidx].hkimage2
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD hkilabel3
				 IF ssa_hkimglns[idx].hkilabel3 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					LET p_hklabel3x = ssa_hkimglns[idx].hkilabel3
				 	IF  p_hklabel3x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel3
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_hkimage3[38,100] != p_hklabel3x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of HK image3, but",
							            "\nthe actual HK image3 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid HK image3 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel3
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_hkimglns[idx].hkimage3 =  p_hkimage3 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage3 =  p_hklabel3 CLIPPED
					LET p_hklabel3 = ssa_hkimglns[idx].hkilabel3
					IF p_hklabel3 != p_prev_hkilabel3 THEN
						LET ssa_hkimglns1[idx].hkmod_flg = "Y" 
					END IF
					DISPLAY ssa_hkimglns[idx].hkimage3
					TO sc_hkimglns[sidx].hkimage3
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD hkilabel4
				 IF ssa_hkimglns[idx].hkilabel4 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					LET p_hklabel4x = ssa_hkimglns[idx].hkilabel4
				 	IF  p_hklabel4x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel4
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_hkimage4[38,100] != p_hklabel4x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of HK image4, but",
							            "\nthe actual HK image4 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid HK image4 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel4
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_hkimglns[idx].hkimage4 =  p_hkimage4 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage4 =  p_hklabel4 CLIPPED
					LET p_hklabel4 = ssa_hkimglns[idx].hkilabel4
					IF p_hklabel4 != p_prev_hkilabel4 THEN
						LET ssa_hkimglns1[idx].hkmod_flg = "Y" 
					END IF
					DISPLAY ssa_hkimglns[idx].hkimage4
					TO sc_hkimglns[sidx].hkimage4
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD hkilabel5	
				 IF ssa_hkimglns[idx].hkilabel5 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_hkimglns")
					LET p_hklabel5x = ssa_hkimglns[idx].hkilabel5
				 	IF  p_hklabel5x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel5
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_hkimage5[38,100] != p_hklabel5x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of HK image5, but",
							            "\nthe actual HK image5 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid HK image5 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD hkilabel5
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_hkimglns[idx].hkimage5 =  p_hkimage5 CLIPPED				#R05
					#R05 LET ssa_hkimglns[idx].hkimage5 =  p_hklabel5 CLIPPED
					LET p_hklabel5 = ssa_hkimglns[idx].hkilabel5
					IF p_hklabel5 != p_prev_hkilabel5 THEN
						LET ssa_hkimglns1[idx].hkmod_flg = "Y" 
					END IF
					DISPLAY ssa_hkimglns[idx].hkimage5
					TO sc_hkimglns[sidx].hkimage5
					ATTRIBUTE (NORMAL)
				END IF


   	       ON ACTION cancel
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG

   	       ON KEY (F10)
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG
			
			##AFTER INPUT
			ON ACTION accept
				MESSAGE ""
				##LET s_maxidx = ARR_COUNT()
##display "accept 1",s_maxidx
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				#FOR idx = 1 TO s_maxidx
				#END FOR			
				EXIT DIALOG
			END INPUT
		# R03 >>
   	 	INPUT ARRAY ssa_sgimglns
    	FROM sc_sgimglns.*
		ATTRIBUTE(WITHOUT DEFAULTS=TRUE, APPEND ROW=FALSE, INSERT ROW=FALSE, DELETE ROW=FALSE)
		
			BEFORE INPUT			#R05 
			    LET p_url_label = "https://mail.brandbank.com.au/flowsd/"   #R05

			ON ACTION zoom  INFIELD sgilabel1
				LET p_sglabel1 = dwopenwindowbox()
				IF p_sglabel1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_sgimage1 = p_sglabel1			
					LET p_sgimage1 = p_url_label CLIPPED,p_sgimage1[4,100]
##display "sg url 1",p_sglabel1," image ",p_sgimage1
					#R05 <<
					LET ssa_sgimglns[idx].sgimage1 =   p_sgimage1 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage1 =  p_sglabel1 CLIPPED
					LET ssa_sgimglns[idx].sgilabel1 =  p_sglabel1 CLIPPED
					DISPLAY ssa_sgimglns[idx].sgimage1
					TO sc_sgimglns[sidx].sgimage1
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_sgimglns[idx].sgilabel1
					TO sc_sgimglns[sidx].sgilabel1
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD sgilabel2
				LET p_sglabel2 = dwopenwindowbox()
				IF p_sglabel2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_sgimage2 = p_sglabel2			
					LET p_sgimage2 = p_url_label CLIPPED,p_sgimage2[4,100]
display "sg url 2",p_sglabel2," image ",p_sgimage2
					#R05 <<
					LET ssa_sgimglns[idx].sgimage2 =   p_sgimage2 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage2 =  p_sglabel2 CLIPPED
					LET ssa_sgimglns[idx].sgilabel2 =  p_sglabel2 CLIPPED
					DISPLAY ssa_sgimglns[idx].sgimage2
					TO sc_sgimglns[sidx].sgimage2
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_sgimglns[idx].sgilabel2
					TO sc_sgimglns[sidx].sgilabel2
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD sgilabel3
				LET p_sglabel3 = dwopenwindowbox()
				IF p_sglabel3 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_sgimage3 = p_sglabel3			
					LET p_sgimage3 = p_url_label CLIPPED,p_sgimage3[4,100]
display "sg url 3",p_sglabel1," image ",p_sgimage3
					#R05 <<
					LET ssa_sgimglns[idx].sgimage3 =   p_sgimage3 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage3 =  p_sglabel3 CLIPPED
					LET ssa_sgimglns[idx].sgilabel3 =  p_sglabel3 CLIPPED
					DISPLAY ssa_sgimglns[idx].sgimage3
					TO sc_sgimglns[sidx].sgimage3
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_sgimglns[idx].sgilabel3
					TO sc_sgimglns[sidx].sgilabel3
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD sgilabel4
				LET p_sglabel4 = dwopenwindowbox()
				IF p_sglabel4 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_sgimage4 = p_sglabel4			
					LET p_sgimage4 = p_url_label CLIPPED,p_sgimage4[4,100]
display "sg url 4",p_sglabel4," image ",p_sgimage4
					#R05 <<
					LET ssa_sgimglns[idx].sgimage4 =   p_sgimage4 CLIPPED				#R02
					#R05 LET ssa_sgimglns[idx].sgimage4 =  p_sglabel4 CLIPPED
					LET ssa_sgimglns[idx].sgilabel4 =  p_sglabel4 CLIPPED
					DISPLAY ssa_sgimglns[idx].sgimage4
					TO sc_sgimglns[sidx].sgimage4
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_sgimglns[idx].sgilabel4
					TO sc_sgimglns[sidx].sgilabel4
					ATTRIBUTE (NORMAL)
				END IF

			ON ACTION zoom  INFIELD sgilabel5
				LET p_sglabel5 = dwopenwindowbox()
				IF p_sglabel5 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					#R05 >>
					##############################################
					# Must use this lookup to get images
					# Y:/519044-wh-v2-zm.jpg
					# p_url_image  = "http://mail.brandband.com.au/flowsd/",p_label[4,100]
					##############################################
					LET p_sgimage5 = p_sglabel5			
					LET p_sgimage5 = p_url_label CLIPPED,p_sgimage5[4,100]
display "sg url 5",p_sglabel5," image ",p_sgimage5
					#R05 <<
					LET ssa_sgimglns[idx].sgimage5 =   p_sgimage5 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage5 =  p_sglabel5 CLIPPED
					LET ssa_sgimglns[idx].sgilabel5 =  p_sglabel5 CLIPPED
					DISPLAY ssa_sgimglns[idx].sgimage5
					TO sc_sgimglns[sidx].sgimage5
					ATTRIBUTE (NORMAL)
					DISPLAY ssa_sgimglns[idx].sgilabel5
					TO sc_sgimglns[sidx].sgilabel5
					ATTRIBUTE (NORMAL)
				END IF

			BEFORE FIELD sgilabel1	
				LET idx = DIALOG.getCurrentRow("sc_sgimglns")
				LET p_prev_sgilabel1 =  ssa_sgimglns[idx].sgilabel1
				IF p_prev_sgilabel1 IS NULL THEN
					LET p_prev_sgilabel1 = " "
				END IF
				LET p_sgimage1 =  ssa_sgimglns[idx].sgimage1			#R05

			BEFORE FIELD sgilabel2
				LET idx = DIALOG.getCurrentRow("sc_sgimglns")
				LET p_prev_sgilabel2 =  ssa_sgimglns[idx].sgilabel2
				IF p_prev_sgilabel2 IS NULL THEN
					LET p_prev_sgilabel2 = " "
				END IF
				LET p_sgimage2 =  ssa_sgimglns[idx].sgimage2			#R05
display "BEFORE FIELD SG 2: ", p_sgimage2 ," ",  ssa_sgimglns[idx].sgimage2			#R05

			BEFORE FIELD sgilabel3	
				LET idx = DIALOG.getCurrentRow("sc_sgimglns")
				LET p_prev_sgilabel3 =  ssa_sgimglns[idx].sgilabel3
				IF p_prev_sgilabel3 IS NULL THEN
					LET p_prev_sgilabel3 = " "
				END IF
				LET p_sgimage3 =  ssa_sgimglns[idx].sgimage3			#R05

			BEFORE FIELD sgilabel4	
				LET idx = DIALOG.getCurrentRow("sc_sgimglns")
				LET p_prev_sgilabel4 =  ssa_sgimglns[idx].sgilabel4
				IF p_prev_sgilabel4 IS NULL THEN
					LET p_prev_sgilabel4 = " "
				END IF
				LET p_sgimage4 =  ssa_sgimglns[idx].sgimage4			#R05

			BEFORE FIELD sgilabel5	
				LET idx = DIALOG.getCurrentRow("sc_sgimglns")
				LET p_prev_sgilabel5 =  ssa_sgimglns[idx].sgilabel5
				IF p_prev_sgilabel5 IS NULL THEN
					LET p_prev_sgilabel5 = " "
				END IF
				LET p_sgimage5 =  ssa_sgimglns[idx].sgimage5			#R05


			AFTER FIELD sgilabel1	
				 IF ssa_sgimglns[idx].sgilabel1 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					LET p_sglabel1 = ssa_sgimglns[idx].sgilabel1
					LET p_sglabel1x = ssa_sgimglns[idx].sgilabel1
				 	IF  p_sglabel1x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel1
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_sgimage1[38,100] != p_sglabel1x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of SG image1, but",
							            "\nthe actual SG image1 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid SG image1 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel1
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_sgimglns[idx].sgimage1 =  p_sgimage1 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage1 =  p_sglabel1 CLIPPED
					IF p_sglabel1 != p_prev_sgilabel1 THEN
						LET ssa_sgimglns1[idx].sgmod_flg = "Y" 
					END IF
					DISPLAY ssa_sgimglns[idx].sgimage1
					TO sc_sgimglns[sidx].sgimage1
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD sgilabel2
				 IF ssa_sgimglns[idx].sgilabel2 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					LET p_sglabel2x = ssa_sgimglns[idx].sgilabel2
				 	IF  p_sglabel2x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel2
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					display "SG image 2: ", p_sgimage2[38,100] ," ", p_sglabel2x[4,30] 
					IF p_sgimage2[38,100] != p_sglabel2x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of SG image2, but",
							            "\nthe actual SG image2 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid SG image2 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel2
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_sgimglns[idx].sgimage2 =  p_sgimage2 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage2 =  p_sglabel2 CLIPPED
					LET p_sglabel2 = ssa_sgimglns[idx].sgilabel2
					IF p_sglabel2 != p_prev_sgilabel2 THEN
						LET ssa_sgimglns1[idx].sgmod_flg = "Y" 
					END IF
					DISPLAY ssa_sgimglns[idx].sgimage2
					TO sc_sgimglns[sidx].sgimage2
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD sgilabel3
				 IF ssa_sgimglns[idx].sgilabel3 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					LET p_sglabel3x = ssa_sgimglns[idx].sgilabel3
				 	IF  p_sglabel3x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel3
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_sgimage3[38,100] != p_sglabel3x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of SG image3, but",
							            "\nthe actual SG image3 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid SG image3 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel3
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_sgimglns[idx].sgimage3 =  p_sgimage3 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage3 =  p_sglabel3 CLIPPED
					LET p_sglabel3 = ssa_sgimglns[idx].sgilabel3
					IF p_sglabel3 != p_prev_sgilabel3 THEN
						LET ssa_sgimglns1[idx].sgmod_flg = "Y" 
					END IF
					DISPLAY ssa_sgimglns[idx].sgimage3
					TO sc_sgimglns[sidx].sgimage3
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD sgilabel4
				 IF ssa_sgimglns[idx].sgilabel4 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					LET p_sglabel4x = ssa_sgimglns[idx].sgilabel4
				 	IF  p_sglabel4x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel4
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_sgimage4[38,100] != p_sglabel4x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of SG image4, but",
							            "\nthe actual SG image4 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid SG image4 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel4
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_sgimglns[idx].sgimage4 =  p_sgimage4 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage4 =  p_sglabel4 CLIPPED
					LET p_sglabel4 = ssa_sgimglns[idx].sgilabel4
					IF p_sglabel4 != p_prev_sgilabel4 THEN
						LET ssa_sgimglns1[idx].sgmod_flg = "Y" 
					END IF
					DISPLAY ssa_sgimglns[idx].sgimage4
					TO sc_sgimglns[sidx].sgimage4
					ATTRIBUTE (NORMAL)
				END IF

			AFTER FIELD sgilabel5	
				 IF ssa_sgimglns[idx].sgilabel5 IS NOT NULL THEN
					LET idx = DIALOG.getCurrentRow("sc_sgimglns")
					LET p_sglabel5x = ssa_sgimglns[idx].sgilabel5
				 	IF  p_sglabel5x[1,23] != g_path THEN
 						LET p_display = "invalid label path "
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel5
					END IF
					####################################################
					# R05 >> - Must use the lookup table to select images
					####################################################
					#images
					IF p_sgimage5[38,100] != p_sglabel5x[4,30] THEN				
						LET p_display = "\nProgram detects that you have ",
							            "\nchanged the name of SG image5, but",
							            "\nthe actual SG image5 has not been changed ",
							            "\nPlease click on the binocular lookup ",
							            "\nbutton to select the valid SG image5 again"
						CALL messagebox(p_display,1)  		
						NEXT FIELD sgilabel5
					END IF
					#########################################################
					#R05 <<
					#########################################################
					LET ssa_sgimglns[idx].sgimage5 =  p_sgimage5 CLIPPED				#R05
					#R05 LET ssa_sgimglns[idx].sgimage5 =  p_sglabel5 CLIPPED
					LET p_sglabel5 = ssa_sgimglns[idx].sgilabel5
					IF p_sglabel5 != p_prev_sgilabel5 THEN
						LET ssa_sgimglns1[idx].sgmod_flg = "Y" 
					END IF
					DISPLAY ssa_sgimglns[idx].sgimage5
					TO sc_sgimglns[sidx].sgimage5
					ATTRIBUTE (NORMAL)
				END IF


   	       ON ACTION cancel
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG

   	       ON KEY (F10)
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET g_void = sty_entW("SELECTX")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG
			
			##AFTER INPUT
			ON ACTION accept
				MESSAGE ""
				##LET s_maxidx = ARR_COUNT()
display "accept 1",s_maxidx
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
				END IF
				#FOR idx = 1 TO s_maxidx
				#END FOR			
				EXIT DIALOG
			END INPUT
		END DIALOG
		MESSAGE ""
		#R03 LET g_void = sty_entW("BROWSE")
		#R03 LET g_void = sty_entW("BROWSEX")
		LET g_void = sty_entW("DWBROWSEX")			#R02
		LET g_void = sty_entW("HKBROWSEX")			#R03
		LET g_void = sty_entW("SGBROWSEX")			#R03

WHEN p_state = "BROWSE"
		##CALL sty_entW("SELECT") RETURNING p_retstat
		CALL SET_COUNT(s_maxidx)
		DISPLAY ARRAY ssa_stycollns TO sc_stycollns.* ATTRIBUTE (NORMAL)
			before display
				exit display
		END DISPLAY
		CALL sty_entW("DISPLAY") RETURNING p_retstat
		CALL sty_entX()
		LET p_retstat = TRUE

WHEN p_state = "DISPLAY"
	FOR idx = 1 TO g_dspsize
		SELECT	colour_name
		INTO	ssa_stycollns[idx].colour_name
		FROM	colour
		WHERE	colour = ssa_stycollns[idx].colour

		DISPLAY ssa_stycollns[idx].* TO sc_stycollns[idx].* 
		ATTRIBUTE(NORMAL)
	END FOR
	LET p_retstat = TRUE

#rxx >>
WHEN p_state = "BROWSEV"
		CALL SET_COUNT(s_maxidx)
		DISPLAY ARRAY ssa_styvlns TO sc_styvlns.* ATTRIBUTE (NORMAL)
			before display
				exit display
		END DISPLAY
		CALL sty_entW("DISPLAYV") RETURNING p_retstat
		CALL sty_entX()
		LET p_retstat = TRUE
#R06 >>
WHEN p_state = "DISPLAYV"
	FOR idx = 1 TO g_dspsize
		SELECT	colour_name
		INTO	ssa_styvlns[idx].video_colour_name
		FROM	colour
		WHERE	colour = ssa_styvlns[idx].video_colour

		DISPLAY ssa_styvlns[idx].* TO sc_styvlns[idx].* 
		ATTRIBUTE(NORMAL)
	END FOR
	LET p_retstat = TRUE
#R06 <<

#R03 WHEN p_state = "BROWSEX"
		#R03 LET p_option = "OPTION:  F10=QUIT  F5=FORWARD  F6=REVERSE "
		#R03 DISPLAY p_option AT 23,1
		#R03 ATTRIBUTE(NORMAL)
#R03 
		#R03 CALL SET_COUNT(s_maxidx)
		#R03 DISPLAY ARRAY ssa_imglns TO sc_imglns.* ATTRIBUTE (NORMAL)
			#R03 before display
				#R03 exit display
		#R03 END DISPLAY
		#R03 CALL sty_entW("DISPLAYX") RETURNING p_retstat
		#R03 CALL sty_entX()
		#R03 LET p_retstat = TRUE

#R03 WHEN p_state = "DISPLAYX"
	#R03 FOR idx = 1 TO g_dspsize
		#R03 SELECT	colour_name
		#R03 INTO	ssa_imglns[idx].colour_namex
		#R03 FROM	colour
		#R03 WHERE	colour = ssa_imglns[idx].colour
#R03 
		#R03 DISPLAY ssa_imglns[idx].* TO sc_imglns[idx].* 
		#R03 ATTRIBUTE(NORMAL)
		#R03 DISPLAY ssa_imglns[idx].image1
		#R03 TO sc_imglns[sidx].image1
		#R03 ATTRIBUTE (NORMAL)
	#R03 END FOR
	#R03 LET p_retstat = TRUE
	#R02 >>
	WHEN p_state = "DWBROWSEX"
		CALL SET_COUNT(s_maxidx)
		DISPLAY ARRAY ssa_dwimglns TO sc_dwimglns.* ATTRIBUTE (NORMAL)
			before display
				exit display
		END DISPLAY
		CALL sty_entW("DWDISPLAYX") RETURNING p_retstat
		CALL sty_entX()
		LET p_retstat = TRUE

	WHEN p_state = "DWDISPLAYX"
		FOR idx = 1 TO g_dspsize
			SELECT	colour_name
			INTO	ssa_dwimglns[idx].dwcolour_namex
			FROM	colour
			WHERE	colour = ssa_dwimglns[idx].dwcolour

			DISPLAY ssa_dwimglns[idx].* TO sc_dwimglns[idx].* 
			ATTRIBUTE(NORMAL)
			DISPLAY ssa_dwimglns[idx].dwimage1
			TO sc_dwimglns[sidx].dwimage1
			ATTRIBUTE (NORMAL)
		END FOR
		LET p_retstat = TRUE
	#R02 <<
	#R03 >>
	WHEN p_state = "HKBROWSEX"
		CALL SET_COUNT(s_maxidx)
		DISPLAY ARRAY ssa_hkimglns TO sc_hkimglns.* ATTRIBUTE (NORMAL)
			before display
				exit display
		END DISPLAY
		CALL sty_entW("HKDISPLAYX") RETURNING p_retstat
		CALL sty_entX()
		LET p_retstat = TRUE

	WHEN p_state = "HKDISPLAYX"
		FOR idx = 1 TO g_dspsize
			SELECT	colour_name
			INTO	ssa_hkimglns[idx].hkcolour_namex
			FROM	colour
			WHERE	colour = ssa_hkimglns[idx].hkcolour

			DISPLAY ssa_hkimglns[idx].* TO sc_hkimglns[idx].* 
			ATTRIBUTE(NORMAL)
			DISPLAY ssa_hkimglns[idx].hkimage1
			TO sc_hkimglns[sidx].hkimage1
			ATTRIBUTE (NORMAL)
		END FOR
		LET p_retstat = TRUE
	#R03 >>
	WHEN p_state = "SGBROWSEX"
		CALL SET_COUNT(s_maxidx)
		DISPLAY ARRAY ssa_sgimglns TO sc_sgimglns.* ATTRIBUTE (NORMAL)
			before display
				exit display
		END DISPLAY
		CALL sty_entW("SGDISPLAYX") RETURNING p_retstat
		CALL sty_entX()
		LET p_retstat = TRUE

	WHEN p_state = "SGDISPLAYX"
		FOR idx = 1 TO g_dspsize
			SELECT	colour_name
			INTO	ssa_sgimglns[idx].sgcolour_namex
			FROM	colour
			WHERE	colour = ssa_sgimglns[idx].sgcolour

			DISPLAY ssa_sgimglns[idx].* TO sc_sgimglns[idx].* 
			ATTRIBUTE(NORMAL)
			DISPLAY ssa_sgimglns[idx].sgimage1
			TO sc_sgimglns[sidx].sgimage1
			ATTRIBUTE (NORMAL)
		END FOR
		LET p_retstat = TRUE
	#R03 <<
	#R03 <<
WHEN p_state = "CLEAR"
	INITIALIZE ssa_stycollns[1].* TO NULL
	FOR idx = 2 TO g_dspsize
		LET ssa_stycollns[idx].* = ssa_stycollns[1].*
	END FOR
	CALL sty_entW("DISPLAY") RETURNING p_retstat
#R06 >>
WHEN p_state = "INPUT1"
	DIALOG ATTRIBUTES(UNBUFFERED)
		#R02 LET p_f10 = FALSE
   	 	INPUT ARRAY ssa_styvlns
    	#R02 WITHOUT DEFAULTS 
    	FROM sc_styvlns.*
		ATTRIBUTE(WITHOUT DEFAULTS=TRUE, APPEND ROW=FALSE, INSERT ROW=FALSE, DELETE ROW=FALSE,COUNT=s_maxidx)
		
			ON ACTION play infield video_url
				LET idx = DIALOG.getCurrentRow("sc_styvlns")
				LET p_video_url = ssa_styvlns[idx].video_url 
display "on action ",idx," ", p_video_url
            	 DISPLAY SFMT("%1?autoplay=1", p_video_url) TO wc

   	       ON ACTION cancel
				##LET s_maxidx= ARR_COUNT()
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				LET g_video = FALSE
				EXIT DIALOG

   	       ON KEY (F10)
				##LET s_maxidx= ARR_COUNT()
				LET g_video = FALSE
				LET g_void = sty_entW("INIT")
				LET g_void = sty_entW("SELECT")
				LET p_f10 = TRUE
				LET p_retstat = FALSE
				EXIT DIALOG
			
			##AFTER INPUT
			ON ACTION accept
				MESSAGE ""
				##LET s_maxidx = ARR_COUNT()
display "accept 1",s_maxidx
				LET p_retstat = TRUE
				IF s_maxidx = 0 THEN
					ERROR	"must have at least one report line"
					LET p_retstat = FALSE
					LET g_video = FALSE
				ELSE
					LET g_video = TRUE
				END IF
				EXIT DIALOG
			END INPUT
		END DIALOG
#R06 <<
END CASE
RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@ (sty_entA) @@@@@@@@@@@@@@@@@
################################################################################
FUNCTION openwindowbox()
	
	DEFINE path,name,filetype,caption, filename STRING

##	LET path = "C:\\\\temp"
	LET path = "X:\\\\"
display path
	LET name = "Image files"
	LET filetype="*.jpg"
	LET caption = "Select an JPG file"
	CALL ui.Interface.frontCall("standard","openfile",[path,name,filetype,caption],filename)
	display filename
	RETURN filename
END FUNCTION
FUNCTION dwopenwindowbox()
	
	DEFINE path,name,filetype,caption, filename STRING

	LET path = "Y:\\\\"
display path
	LET name = "Image files"
	LET filetype="*.jpg"
	LET caption = "Select an JPG file"
	CALL ui.Interface.frontCall("standard","openfile",[path,name,filetype,caption],filename)
	display filename
	RETURN filename
END FUNCTION
