################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   							sty_entL - Upload Online Images                #
#  																			   #
# 	R00	05may18  td       initial release				    	               #
################################################################################
IMPORT com
DATABASE seed

GLOBALS
		"sty_entG.4gl"
	DEFINE
			##ssa_estycollns	ARRAY[100] OF RECORD
			ssa_estycollns	DYNAMIC ARRAY OF RECORD
				style				LIKE style.style,
				colour				SMALLINT,
				hero_image			CHAR(1),
				publish				CHAR(1),
				hk_hero_image		CHAR(1),
				hk_publish			CHAR(1),
				sin_hero_image		CHAR(1),
				sin_publish			CHAR(1),
				nz_hero_image		CHAR(1),
				nz_publish			CHAR(1),
				dw_auhero_img		CHAR(1),
				dw_nzhero_img		CHAR(1),
				dw_hkhero_img		CHAR(1),
				dw_sghero_img		CHAR(1),
				dwilabel1			STRING,
				dwilabel2			STRING,
				dwilabel3			STRING,
				dwilabel4			STRING,
				dwilabel5			STRING,
				hkilabel1			STRING,
				hkilabel2			STRING,
				hkilabel3			STRING,
				hkilabel4			STRING,
				hkilabel5			STRING,
				sgilabel1			STRING,
				sgilabel2			STRING,
				sgilabel3			STRING,
				sgilabel4			STRING,
				sgilabel5			STRING
						END RECORD,
			s_bnkpa			RECORD LIKE bnk_password.*,
			s_maxjdx		SMALLINT

################################################################################
#	reqhdrU - enter data													   #
################################################################################
FUNCTION sty_entUpload(p_path)
   DEFINE 
			p_url_image			STRING,
			p_style_row			CHAR(5),
			p_retstat			INTEGER,
			p_run				STRING,
			p_row_data			CHAR(20),
			p_path				STRING,							 #Path of file
   		    r_budget			RECORD LIKE store_wage_budget.*, #Current Budget Record
		    r_image				TYPE_IMAGE,
		    r_image_rec			TYPE_IMAGE_RECORD,
		    p_arr_image  	    DYNAMIC ARRAY OF TYPE_IMAGE,
		    line_no 			INT,							 #Current Line Number
		    row_data			DYNAMIC ARRAY OF STRING,		 #array of strings (delimited by ,)
		    row_raw		    	STRING,
		    p_string			STRING,
		 	p_display			STRING,
		    ch					base.Channel					 #File Reader

	DELETE FROM t_image
	WHERE 1=1;

	DELETE FROM t_upload_image
	WHERE 1=1;

   #0) Read records from file 
##display "PATH: ",path
   LET g_error_string = ""
   LET ch = base.Channel.create()
   CALL ch.setDelimiter(",")
   CALL ch.openFile(p_path,"r")
   LET line_no = 1
   LET p_retstat = TRUE
   WHILE ch.read([ r_image_rec.style,
				   r_image_rec.colour,
				   r_image_rec.au_publish,
				   r_image_rec.au_hero_image,
				   r_image_rec.nz_publish,
				   r_image_rec.nz_hero_image,
				   r_image_rec.hk_publish,
				   r_image_rec.hk_hero_image,
				   r_image_rec.sg_publish,
				   r_image_rec.sg_hero_image,
				   r_image_rec.dw_au_hero_image,
				   r_image_rec.dw_nz_hero_image,
				   r_image_rec.dw_hk_hero_image,
				   r_image_rec.dw_sg_hero_image,
				   r_image_rec.au_image1 	,
				   r_image_rec.au_image2,
				   r_image_rec.au_image3,
				   r_image_rec.au_image4,
				   r_image_rec.au_image5,
				   r_image_rec.hk_image1,
				   r_image_rec.hk_image2,
				   r_image_rec.hk_image3,
				   r_image_rec.hk_image4,
				   r_image_rec.hk_image5,
				   r_image_rec.sg_image1,
				   r_image_rec.sg_image2,
				   r_image_rec.sg_image3,
				   r_image_rec.sg_image4,
				   r_image_rec.sg_image5])

   	   ##		LET row_raw = ch.readLine()
	   		IF ch.isEof() THEN EXIT WHILE END IF
		 	 IF r_image_rec.style = "EOF" THEN 
display "eof"
			 	EXIT WHILE
		  	END IF
	   		##LET row_data = util_string_split(row_raw,",")

			##display "line string: ", row_raw
			##display "line string1: ", r_image_rec.*

	   #1) Parse date  if line 1 else throw error
	   IF line_no = 1 THEN
		   LET p_row_data = row_data[1]
		   LET p_style_row = p_row_data
		   LET p_row_data = p_row_data CLIPPED

		   ##DISPLAY "style :",p_row_data[1,20],"row ",r_image_rec.style
		   IF r_image_rec.style  IS NULL 
		   OR UPSHIFT(r_image_rec.style)  NOT MATCHES  "*STYLE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
   		   	  CALL ch.close()
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nStyle row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
		   	  RETURN FALSE
		   END IF
		   LET p_row_data = row_data[2]
		   ##DISPLAY "colour : ",p_row_data," ",r_image_rec.colour
		   IF r_image_rec.colour IS NULL 
		   OR UPSHIFT(r_image_rec.colour) NOT MATCHES  "*COLOUR*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nColour row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[3]
		   ##DISPLAY "AU Publish : ",p_row_data," ",r_image_rec.au_publish
		   IF r_image_rec.au_publish IS NULL 
		   OR UPSHIFT(r_image_rec.au_publish)  NOT MATCHES  "*AU PUBLISH*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAU Publish row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[4]
		   ##DISPLAY "AU Hero Image : ",p_row_data," ", r_image_rec.au_hero_image
		   IF r_image_rec.au_hero_image IS NULL
		   OR UPSHIFT(r_image_rec.au_hero_image) NOT MATCHES  "*AU HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAu Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[5]
		   ##DISPLAY "NZ Publish : ",p_row_data," ", r_image_rec.nz_publish
		   IF r_image_rec.nz_publish IS NULL 
		   OR UPSHIFT(r_image_rec.nz_publish) NOT MATCHES "*NZ PUBLISH*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nNZ Publish row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[6]
		   ##DISPLAY "NZ Hero Image : ",p_row_data," ", r_image_rec.nz_hero_image
		   IF r_image_rec.nz_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.nz_hero_image) NOT MATCHES "*NZ HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nNZ Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[7]
		   ##DISPLAY "HK Publish : ",p_row_data," ", r_image_rec.hk_publish
		   IF r_image_rec.hk_publish IS NULL 
		   OR UPSHIFT(r_image_rec.hk_publish) NOT MATCHES "*HK PUBLISH*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Publish row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[8]
		   ##DISPLAY "HK Hero Image : ",p_row_data," ", r_image_rec.hk_hero_image
		   IF r_image_rec.hk_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.hk_hero_image) NOT MATCHES  "*HK HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[9]
		   ##DISPLAY "SG Publish : ",p_row_data," ", r_image_rec.sg_publish
		   IF r_image_rec.sg_publish IS NULL 
		   OR UPSHIFT(r_image_rec.sg_publish) != "SG PUBLISH" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Pubish row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[10]
		   ##DISPLAY "SG Hero Image : ",p_row_data," ", r_image_rec.sg_hero_image
		   IF r_image_rec.sg_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.sg_hero_image) NOT MATCHES "*SG HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[11]
		   ##DISPLAY "DW AU Hero Image : ",p_row_data," ", r_image_rec.dw_au_hero_image
		   IF r_image_rec.dw_au_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.dw_au_hero_image) NOT MATCHES "*DW AU HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nDW AU Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[12]
		   ##DISPLAY "DW NZ Hero Image : ",p_row_data," ", r_image_rec.dw_nz_hero_image
		   IF r_image_rec.dw_nz_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.dw_nz_hero_image) NOT MATCHES "*DW NZ HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nDW NZ Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[13]
		   ##DISPLAY "DW HK Hero Image : ",p_row_data," ", r_image_rec.dw_hk_hero_image
		   IF r_image_rec.dw_hk_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.dw_hk_hero_image) NOT MATCHES  "*DW HK HERO IMAGE*" THEN
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nDW HK Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
			  DISPLAY "DEBUG: cancelled upload"
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[14]
		   ##DISPLAY "DW SG Hero Image : ",p_row_data," ", r_image_rec.dw_sg_hero_image
		   IF r_image_rec.dw_sg_hero_image IS NULL 
		   OR UPSHIFT(r_image_rec.dw_sg_hero_image) NOT MATCHES "*DW SG HERO IMAGE*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nDW SG Hero Image row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[15]
		   ##DISPLAY "AU Image1 : ",p_row_data," ", r_image_rec.au_image1 	
		   IF r_image_rec.au_image1 IS NULL 
		   OR UPSHIFT(r_image_rec.au_image1) NOT MATCHES "*AU IMAGE1*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAU Image1 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[16]
		   ##DISPLAY "AU Image2 : ",p_row_data," ", r_image_rec.au_image2	
		   IF r_image_rec.au_image2 IS NULL 
		   OR UPSHIFT(r_image_rec.au_image2) NOT MATCHES "*AU IMAGE2*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAU Image2 row not found"
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[17]
		   ##DISPLAY "AU Image3 : ",p_row_data," ", r_image_rec.au_image3
		   IF r_image_rec.au_image3 IS NULL 
		   OR UPSHIFT(r_image_rec.au_image3) NOT MATCHES "*AU IMAGE3*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAU Image3 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[18]
		   ##DISPLAY "AU Image4 : ",p_row_data," ", r_image_rec.au_image4
		   IF r_image_rec.au_image4 IS NULL 
		   OR UPSHIFT(r_image_rec.au_image4) NOT MATCHES "*AU IMAGE4*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAU Image4 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[19]
		   ##DISPLAY "AU Image5 : ",p_row_data," ", r_image_rec.au_image5
		   IF r_image_rec.au_image5 IS NULL 
		   OR UPSHIFT(r_image_rec.au_image5) NOT MATCHES "*AU IMAGE5*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nAU Image5 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[20]
		   ##DISPLAY "HK Image1 : ",p_row_data," ", r_image_rec.hk_image1 	
		   IF r_image_rec.hk_image1 IS NULL 
		   OR UPSHIFT(r_image_rec.hk_image1) NOT MATCHES "*HK IMAGE1*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Image1 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[21]
		   ##DISPLAY "HK Image2 : ",p_row_data," ", r_image_rec.hk_image2
		   IF r_image_rec.hk_image2 IS NULL 
		   OR UPSHIFT(r_image_rec.hk_image2) NOT MATCHES "*HK IMAGE2*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Image2 row not found"
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[22]
		   ##DISPLAY "HK Image3 : ",p_row_data," ", r_image_rec.hk_image3
		   IF r_image_rec.hk_image3 IS NULL 
		   OR UPSHIFT(r_image_rec.hk_image3) NOT MATCHES "*HK IMAGE3*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Image3 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[23]," ", r_image_rec.hk_image4
		   ##DISPLAY "HK Image4 : ",p_row_data
		   IF r_image_rec.hk_image4 IS NULL 
		   OR UPSHIFT(r_image_rec.hk_image4) NOT MATCHES "*HK IMAGE4*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Image4 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[24]
		   ##DISPLAY "HK Image5 : ",p_row_data," ", r_image_rec.hk_image5
		   IF r_image_rec.hk_image5 IS NULL 
		   OR UPSHIFT(r_image_rec.hk_image5) NOT MATCHES "*HK IMAGE5*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nHK Image5 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[25]
		   ##DISPLAY "SG Image1 : ",p_row_data," ", r_image_rec.sg_image1
		   IF r_image_rec.sg_image1 IS NULL 
		   OR UPSHIFT(r_image_rec.sg_image1) NOT MATCHES "*SG IMAGE1*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Image1 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF
		   LET p_row_data = row_data[26]
		   ##DISPLAY "SG Image2 : ",p_row_data," ",r_image_rec.sg_image2
		   IF r_image_rec.sg_image2 IS NULL 
		   OR UPSHIFT(r_image_rec.sg_image2) NOT MATCHES "*SG IMAGE2*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Image2 row not found"
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[27]
		   ##DISPLAY "SG Image3 : ",p_row_data," ",r_image_rec.sg_image3
		   IF r_image_rec.sg_image3 IS NULL 
		   OR UPSHIFT(r_image_rec.sg_image3) NOT MATCHES "*SG IMAGE3*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Image3 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[28]
		   ##DISPLAY "SG Image4 : ",p_row_data," ",r_image_rec.sg_image4
		   IF r_image_rec.sg_image4 IS NULL 
		   OR UPSHIFT(r_image_rec.sg_image4) NOT MATCHES "*SG IMAGE4*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Image4 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF

		   LET p_row_data = row_data[29]
		   ##DISPLAY "SG Image5 : ",p_row_data," ",r_image_rec.sg_image5
		   IF r_image_rec.sg_image5 IS NULL 
		   OR UPSHIFT(r_image_rec.sg_image5) NOT MATCHES "*SG IMAGE5*" THEN
			  DISPLAY "DEBUG: cancelled upload"
			  LET p_display =  "\nDEBUG: cancelled upload",
			                   "\nSG Image5 row not found"
   	   		  CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
   		   	  CALL ch.close()
		   	  RETURN FALSE
		   END IF
	   ELSE
	   		#2) Extract record
	   		INITIALIZE r_image.* TO NULL
	   		#expecting type like NSW-SD-1234
		   	   LET r_image.line_no = line_no
		   	   #LET r_image.style = row_data[1]
			   #LET r_image.colour = row_data[2]
			   #LET r_image.au_publish = row_data[3]
			   #LET r_image.au_hero_image = row_data[4]
			   #LET r_image.nz_publish = row_data[5]
			   #LET r_image.nz_hero_image = row_data[6]
			   #LET r_image.hk_publish = row_data[7]
			   #LET r_image.hk_hero_image = row_data[8]
			   #LET r_image.sg_publish = row_data[9]
			   #LET r_image.sg_hero_image = row_data[10]
			   #LET r_image.dw_au_hero_image = row_data[11]
			   #LET r_image.dw_nz_hero_image = row_data[12]
			   #LET r_image.dw_hk_hero_image = row_data[13]
			   #LET r_image.dw_sg_hero_image = row_data[14]
			   #LET r_image.au_image1 = row_data[15]
			   #LET r_image.au_image2 = row_data[16]
			   ##LET r_image.au_image3 = row_data[17]
			   #LET r_image.au_image4 = row_data[18]
			   #LET r_image.au_image5 = row_data[19]
			   #LET r_image.hk_image1 = row_data[20]
			   #LET r_image.hk_image2 = row_data[21]
			   #LET r_image.hk_image3 = row_data[22]
			   #LET r_image.hk_image4 = row_data[23]
			   #LET r_image.hk_image5 = row_data[24]
			   ##LET r_image.sg_image1 = row_data[25]
			   #LET r_image.sg_image2 = row_data[26]
			   #LET r_image.sg_image3 = row_data[27]
			   ##LET r_image.sg_image4 = row_data[28]
			   ##LET r_image.sg_image5 = row_data[29]

##display "record: : ",r_image_rec.*
##display "record: : ",r_image_rec.au_publish

		   	   LET r_image.style = r_image_rec.style
			   LET r_image.colour = r_image_rec.colour
			   LET r_image.au_publish = r_image_rec.au_publish
			   LET r_image.au_hero_image = r_image_rec.au_hero_image
			   LET r_image.nz_publish = r_image_rec.nz_publish 
			   LET r_image.nz_hero_image = r_image_rec.nz_hero_image
			   LET r_image.hk_publish = r_image_rec.hk_publish
			   LET r_image.hk_hero_image = r_image_rec.hk_hero_image
			   LET r_image.sg_publish = r_image_rec.sg_publish
			   LET r_image.sg_hero_image = r_image_rec.sg_hero_image 
			   LET r_image.dw_au_hero_image = r_image_rec.dw_au_hero_image 
			   LET r_image.dw_nz_hero_image = r_image_rec.dw_nz_hero_image 
			   LET r_image.dw_hk_hero_image = r_image_rec.dw_hk_hero_image 
			   LET r_image.dw_sg_hero_image = r_image_rec.dw_sg_hero_image


##display "record 1: : ",r_image.*


			   SELECT	*
			   FROM 	style 
			   WHERE 	style = r_image.style

			   ##DISPLAY "style:",r_image.style
			   IF status = NOTFOUND THEN
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: invalid style %2",
					r_image.line_no,r_image.style))
					EXIT WHILE
			   END IF

			   SELECT	*
			   FROM 	colour 
			   WHERE 	colour = r_image.colour

			   ##DISPLAY "colour:",r_image.colour
			   IF status = NOTFOUND THEN
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: invalid colour %2",
					r_image.line_no,r_image.colour))
					EXIT WHILE
			   END IF

			   SELECT	*
			   FROM 	style_colour 
			   WHERE 	colour = r_image.colour
			   AND 	    style  = r_image.style


			   ##DISPLAY "style/colour:",r_image.style," ",r_image.colour
			   IF status = NOTFOUND THEN
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2,%3: invalid style-colour %2",
					r_image.line_no,r_image.style,r_image.colour))
					EXIT WHILE
			   END IF

			   ##DISPLAY "AU publish: ",r_image.au_publish
			   #IF r_image.au_publish MATCHES  " " THEN
			   IF r_image.au_publish IS NULL THEN
			   	   DISPLAY "au publish:",r_image.au_publish
			       LET g_error_string = g_error_string.append(SFMT("\n STYLE[%1]:%2: AU Publish status must not blank %2",
					r_image.style,r_image.au_publish))
					EXIT WHILE
			   END IF

			   IF r_image.au_publish =  "Y"
			   OR r_image.au_publish = "N"
			   THEN
			   ELSE
			   		DISPLAY "au publish:",r_image.au_publish
			   	    ##LET g_error_string = g_error_string.append(SFMT("\n STYLE[%1]:UPLOADED[%2]: AU Publish status must be Y/N",
			   	    LET g_error_string = g_error_string.append(SFMT("\n STYLE[%1]:AU Publish status must be Y/N:UPLOADED[%2]",
					r_image.style,r_image.au_publish))
					##r_image.style,r_image.au_publish))
					EXIT WHILE
			   END IF

			   IF r_image.au_hero_image IS NULL THEN
			   		DISPLAY "au hero image:",r_image.au_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n STYLE[%1]:AU Hero Image status must not be blankUPLOADED[%2]",
					r_image.line_no,r_image.au_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.au_hero_image = "Y"
			   OR r_image.au_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "au hero image:",r_image.au_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n STYLE[%1]:AU Hero Image status must be Y/N:UPLOADED[%2]",
					r_image.line_no,r_image.au_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.nz_publish = "Y"
			   OR r_image.nz_publish = "N"
		       THEN
			   ELSE
			   		DISPLAY "nz publish:",r_image.nz_publish
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: NZ Publish status must be Y or N %2",
					r_image.line_no,r_image.nz_publish))
					EXIT WHILE
			   END IF

			   IF r_image.nz_hero_image = "Y"
			   OR r_image.nz_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "nz hero image:",r_image.nz_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: NZ Hero Image status must be Y or N %2",
					r_image.line_no,r_image.nz_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.hk_publish = "Y"
			   OR r_image.hk_publish = "N"
			   THEN
			   ELSE
			   		DISPLAY "hk publish:",r_image.hk_publish
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: HK Publish status must be Y or N %2",
					r_image.line_no,r_image.hk_publish))
					EXIT WHILE
			   END IF

			   IF r_image.hk_hero_image = "Y"
			   OR r_image.hk_hero_image = "N"
               THEN
			   ELSE
			   		DISPLAY "hk hero image:",r_image.hk_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: HK Hero Image status must be Y or N %2",
					r_image.line_no,r_image.hk_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.sg_publish = "Y"
			   OR r_image.sg_publish = "N"
		       THEN
			   ELSE
			   		DISPLAY "hk publish:",r_image.sg_publish
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: SG Publish status must be Y or N %2",
					r_image.line_no,r_image.sg_publish))
					EXIT WHILE
			   END IF

			   IF r_image.sg_hero_image = "Y"
			   OR r_image.sg_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "sg hero image:",r_image.sg_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: SG Hero Image status must be Y or N %2",
					r_image.line_no,r_image.sg_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.dw_au_hero_image = "Y"
			   OR r_image.dw_au_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "dw au hero image:",r_image.dw_au_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: DW AU Hero Image status must be Y or N %2",
					r_image.line_no,r_image.dw_au_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.dw_nz_hero_image = "Y"
			   OR r_image.dw_nz_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "dw nz hero image:",r_image.dw_nz_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: DW NZ Hero Image status must be Y or N %2",
					r_image.line_no,r_image.dw_nz_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.dw_hk_hero_image = "Y"
			   OR r_image.dw_hk_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "dw hk hero image:",r_image.dw_hk_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: DW HK Hero Image status must be Y or N %2",
					r_image.line_no,r_image.dw_hk_hero_image))
					EXIT WHILE
			   END IF

			   IF r_image.dw_sg_hero_image = "Y"
			   OR r_image.dw_sg_hero_image = "N"
			   THEN
			   ELSE
			   		DISPLAY "dw sg hero image:",r_image.dw_sg_hero_image
			   	    LET g_error_string = g_error_string.append(SFMT("\n LINE[%1]:%2: DW SG Hero Image status must be Y or N %2",
					r_image.line_no,r_image.dw_sg_hero_image))
					EXIT WHILE
			   END IF
			   #validate image file here
			   LET r_image.au_image1 =  r_image_rec.au_image1
			   IF r_image.au_image1 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.au_image1 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"au img1 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.au_image1 =  NULL
					END IF
			   END IF

			   LET r_image.au_image2 = r_image_rec.au_image2
			   IF r_image.au_image2 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.au_image2 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"au img2 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.au_image2 =  NULL
					END IF
			   END IF

			   LET r_image.au_image3 = r_image_rec.au_image3 
			   IF r_image.au_image3 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.au_image3 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"au img3 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.au_image3 =  NULL
					END IF
			   END IF

			   LET r_image.au_image4 = r_image_rec.au_image4 
			   IF r_image.au_image4 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.au_image4 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"au img4 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.au_image4 =  NULL
					END IF
			   END IF

			   LET r_image.au_image5 = r_image_rec.au_image5
			   IF r_image.au_image5 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.au_image5 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"au img5 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.au_image5 =  NULL
					END IF
			   END IF

			   LET r_image.hk_image1 =  r_image_rec.hk_image1
			   IF r_image.hk_image1 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.hk_image1 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"hk img1 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.hk_image1 =  NULL
					END IF
			   END IF

			   LET r_image.hk_image2 = r_image_rec.hk_image2
			   IF r_image.hk_image2 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.hk_image2 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"hk img2 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.hk_image2 =  NULL
					END IF
			   END IF

			   LET r_image.hk_image3 = r_image_rec.hk_image3 
			   IF r_image.hk_image3 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.hk_image3 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"hk img3 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.hk_image3 =  NULL
					END IF
			   END IF

			   LET r_image.hk_image4 = r_image_rec.hk_image4 
			   IF r_image.hk_image4 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.hk_image4 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"hk img4 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.hk_image4 =  NULL
					END IF
			   END IF

			   LET r_image.hk_image5 = r_image_rec.hk_image5
			   IF r_image.hk_image5 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.hk_image5 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"hk img5 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.hk_image5 =  NULL
					END IF
			   END IF

			   LET r_image.sg_image1 =  r_image_rec.sg_image1
			   IF r_image.sg_image1 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.sg_image1 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"sg img1 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.sg_image1 =  NULL
					END IF
			   END IF
			   LET r_image.sg_image2 = r_image_rec.sg_image2
			   IF r_image.sg_image2 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.sg_image2 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"sg img2 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.sg_image2 =  NULL
					END IF
			   END IF

			   LET r_image.sg_image3 = r_image_rec.sg_image3 
			   IF r_image.sg_image3 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.sg_image3 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"sg img3 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.sg_image3 =  NULL
					END IF
			   END IF

			   LET r_image.sg_image4 = r_image_rec.sg_image4 
			   IF r_image.sg_image4 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.sg_image4 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"sg img4 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.sg_image4 =  NULL
					END IF
			   END IF
			   LET r_image.sg_image5 = r_image_rec.sg_image5
			   IF r_image.sg_image5 IS NOT NULL THEN
			   		LET p_url_image = "https://mail.brandbank.com.au/flowsd/",r_image.sg_image5 CLIPPED
			   		IF NOT validate_image(p_url_image) THEN
						#If image is not found then blank out the value of the image field
						#log it
			   			INSERT INTO t_upload_image VALUES (r_image.*,"sg img5 notfound",g_user,CURRENT,g_image_upload)
			   			LET r_image.sg_image5 =  NULL
					END IF
			   END IF

			   LET p_arr_image[p_arr_image.getLength()+1].* = r_image.*
			   INSERT INTO t_image VALUES (r_image.*)
			   #insert into image log table
			   INSERT INTO t_upload_image VALUES (r_image.*,"a",g_user,CURRENT,g_image_upload)
			   ##DISPLAY "r_image: ",r_image.*
		   END IF

	   #3)Stop condition IF arr_records > 0 and line isn't image record
	   ##display "array: ", p_arr_image.getLength()
	   IF p_arr_image.getLength()>0 AND r_image.style IS NULL THEN
	   	   DISPLAY "FINISH"
	   	   EXIT WHILE
	   END IF

	   LET line_no = line_no +1
##display "line no: ",line_no
   END WHILE
     
   IF g_error_string IS NOT NULL THEN
   	   CALL fgl_winmessage("IMPORT ERRORS",g_error_string,"information")
	   RETURN FALSE
   END IF

	##unload to "t" select * from t_image
	##unload to "t1" select * from t_upload_image
	##unload to "t1" select unique style,colour from t_image

	OPEN WINDOW w_1 AT 9,5
    WITH FORM "productimg"
	ATTRIBUTE(TEXT="Upload Product Images List",STYLE="naked")
	IF sty_entLAX("INIT") THEN
		IF create_ftp_file() THEN
			LET p_run = "/opt/brandbank/seed/fastpos/image.sh "
			display "ftp here ", p_run
			RUN p_run WITHOUT WAITING

			#INSERT INTO upload_image 
			#SELECT	*
			#FROM	t_upload_image

 			LET p_display = "uploaded images file sucessfully "
			CALL messagebox(p_display,1)  		#gxx
			LET p_retstat = TRUE
		ELSE	
 			LET p_display = "uploaded images file failed "
			CALL messagebox(p_display,1)  		#gxx
			LET p_retstat = FALSE
		END IF
	END IF
	CLOSE WINDOW w_1
   RETURN p_retstat
END FUNCTION

#+  util_string_split(): 
#+  Splits input string by a delimiter and returns a dynamic array of string
#+  RETURN: Dynamic array of string if valid, NULL if no result
FUNCTION util_string_split(arg_string,arg_delimiter)
	DEFINE
		p_string						String,
	    arg_string                 STRING,
	    arg_delimiter              STRING,
	    tokenizer                  base.StringTokenizer,
	    arr_results                DYNAMIC ARRAY OF STRING,
	    i,previous_i               INT
	IF arg_delimiter IS NULL THEN
	   LET arg_delimiter = ","
	END IF
	IF arg_string IS NULL THEN RETURN NULL END IF
	LET arg_string = arg_string.trim()
	LET i = 1
    INITIALIZE arr_results TO NULL
	LET tokenizer = base.StringTokenizer.create(arg_string,arg_delimiter)
	WHILE tokenizer.hasMoreTokens()
		LET arr_results[i] = tokenizer.nextToken()
		LET i = i + 1
##let p_string = arr_results[i] 
##display p_string
	END WHILE
	RETURN arr_results
END FUNCTION
FUNCTION  create_ftp_file()

	DEFINE
			p_url_image			STRING,
			p_url_auimage5		STRING,
			idx					INT,
		    r_image				TYPE_IMAGE,
			p_retstat			INTEGER,
			p_subject			STRING,
			p_cmd				STRING,
			p_ftp_file			VARCHAR(20),
			p_report_pathname		STRING,
			ch base.Channel 

	LET p_ftp_file = TIME
	LET p_ftp_file = p_ftp_file[1,2]||p_ftp_file[4,5]||p_ftp_file[7,8]
	DISPLAY "FILENAME : ",p_ftp_file
	LET ch = base.Channel.create()
	LET p_report_pathname = "/file_storage/brandbank_tmp/shau/flow/images/QPimage",p_ftp_file
  	CALL ch.openFile(p_report_pathname,"w")
	SLEEP 1

	LET p_retstat = FALSE
	LET idx = 0
	DECLARE c_3 CURSOR FOR
		SELECT	*
		FROM	t_image

	FOREACH c_3 INTO r_image.*
##display "QP idx: ",idx
		IF idx > 120 THEN
			LET p_ftp_file = TIME
			LET p_ftp_file = p_ftp_file[1,2]||p_ftp_file[4,5]||p_ftp_file[7,8]
			DISPLAY "FILENAME1 : ",p_ftp_file
			LET ch = base.Channel.create()
			LET p_report_pathname = "/file_storage/brandbank_tmp/shau/flow/images/QPimage",p_ftp_file
  			CALL ch.openFile(p_report_pathname,"w")
			LET idx = 0 
			SLEEP 1
		END IF
		IF r_image.au_image1 IS NOT NULL THEN
			CALL ch.writeLine(r_image.au_image1 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		#CALL ch.writeLine("")
		IF r_image.au_image2 IS NOT NULL THEN
			CALL ch.writeLine(r_image.au_image2 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.au_image3 IS NOT NULL THEN
			CALL ch.writeLine(r_image.au_image3 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.au_image4 IS NOT NULL THEN
			CALL ch.writeLine(r_image.au_image4 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.au_image5 IS NOT NULL THEN
			CALL ch.writeLine(r_image.au_image5 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.hk_image1 IS NOT NULL THEN
			CALL ch.writeLine(r_image.hk_image1 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		#CALL ch.writeLine("")
		IF r_image.hk_image2 IS NOT NULL THEN
			CALL ch.writeLine(r_image.hk_image2 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.hk_image3 IS NOT NULL THEN
			CALL ch.writeLine(r_image.hk_image3 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.hk_image4 IS NOT NULL THEN
			CALL ch.writeLine(r_image.hk_image4 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.hk_image5 IS NOT NULL THEN
			CALL ch.writeLine(r_image.hk_image5 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.sg_image1 IS NOT NULL THEN
			CALL ch.writeLine(r_image.sg_image1 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		#CALL ch.writeLine("")
		IF r_image.sg_image2 IS NOT NULL THEN
			CALL ch.writeLine(r_image.sg_image2 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.sg_image3 IS NOT NULL THEN
			CALL ch.writeLine(r_image.sg_image3 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.sg_image4 IS NOT NULL THEN
			CALL ch.writeLine(r_image.sg_image4 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
		IF r_image.sg_image5 IS NOT NULL THEN
			CALL ch.writeLine(r_image.sg_image5 CLIPPED)
			LET p_retstat = TRUE
			LET idx = idx + 1
		END IF
	END FOREACH
	RETURN p_retstat
END FUNCTION
################################################################################
#	online_setpasswd - set up password											   #
################################################################################
FUNCTION online_setpasswd()
	DEFINE
			p_display		STRING,						#R03
			p_option		CHAR(100),
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER

	IF no_passwordU("online") THEN
		CALL online_getpasswd("         Enter new password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN
			LET s_bnkpa.bnkpa_password = p_passwd
			LET s_bnkpa.bnkpa_user = "online"
			CALL online_getpasswd("           Confirm password:")
			RETURNING p_retstat, p_passwd
			IF p_retstat THEN
				IF p_passwd != s_bnkpa.bnkpa_password THEN
					LET p_display =
						"\nThe passwords entered",
						"\nin first & second times",
						"\nare not the same.",
						"\nTry again."
					CALL messagebox(p_display,2)				#R03
					LET p_retstat = FALSE
				ELSE
					LET p_retstat = online_updpasswd("INSERT")
				END IF
			END IF
		END IF
	ELSE
		CALL online_getpasswd("             Enter password: ")
		RETURNING p_retstat, p_passwd
		IF p_retstat THEN									#some password
			IF NOT online_validpw("online",p_passwd) THEN		#not found
				CALL online_getpasswd("Invalid password, try again:") #again
				RETURNING p_retstat, p_passwd
				IF p_retstat THEN							#some password
					IF NOT online_validpw("online",p_passwd) THEN		#not found
						LET p_display =
							"\nInvalid password",
							"\nSee Sysytem Administrator."
							CALL messagebox(p_display,2)				#R03
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
# @@@@@@@@@@@@@@@ (online_setpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	no_password - validate entered password                                    #
################################################################################
FUNCTION no_passwordU(p_user)

	DEFINE
			p_user			LIKE bnk_password.bnkpa_user

	SELECT	*
	INTO	s_bnkpa.*
	FROM	bnk_password
	WHERE	bnkpa_user = p_user
	
	IF status = NOTFOUND THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (online_password) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	online_updpasswd - save entered password                                      #
################################################################################
FUNCTION online_updpasswd(p_action)
	DEFINE
			p_action		CHAR(10),
			p_status		INTEGER,
			p_retstat		INTEGER

	WHENEVER ERROR CONTINUE
	BEGIN WORK
	CASE
	WHEN p_action = "INSERT"
		INSERT INTO bnk_password VALUES (s_bnkpa.*)
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
# @@@@@@@@@@@@@@@ (online_updpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	online_getpasswd -  prompt for password                                       #
################################################################################
FUNCTION online_getpasswd(p_msg)
	DEFINE
			p_option		CHAR(80),
			p_status		INTEGER,
	 		p_msg			CHAR(30),
			p_passwd		CHAR(80)

	OPEN WINDOW w_passwd AT 12,18 WITH FORM "bnk_passwd"
	ATTRIBUTE(STYLE="naked")
	DISPLAY BY NAME p_msg
	ATTRIBUTE (NORMAL)

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
		#R03 >>
		ON ACTION exit
			ERROR "no password entered"
			LET p_status = FALSE
			EXIT INPUT
		#R03 <<
		END INPUT
		OPTIONS INPUT WRAP

	CLOSE WINDOW w_passwd
	RETURN p_status, p_passwd
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (online_getpasswd) @@@@@@@@@@@@@@@@
################################################################################
################################################################################
#	online_validpw - check for old password                                       #
################################################################################
FUNCTION online_validpw(p_user,p_passwd)
	DEFINE 
			p_user			LIKE bnk_password.bnkpa_user,
			p_passwd		LIKE bnk_password.bnkpa_password,
			p_retstat		INTEGER
	IF no_passwordU(p_user) THEN							#not found
		LET p_retstat = FALSE
	ELSE
		IF s_bnkpa.bnkpa_password = p_passwd THEN
			LET p_retstat = TRUE
		ELSE
			LET p_retstat = FALSE
		END IF
	END IF
	RETURN p_retstat
END FUNCTION
################################################################################
# @@@@@@@@@@@@@@@ (online_validpw) @@@@@@@@@@@@@@@@
################################################################################
FUNCTION sty_entLAX(p_state)
	DEFINE	p_state					CHAR(10),
		    r_image					TYPE_IMAGE,
			cmd						STRING,
			w ui.Window,
			fa						STRING,
			p_display				STRING,
			p_lineno				SMALLINT,
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
	
	#FOR idx = 1 TO g_arrsize
	LET ssa_estycollns = NULL
	##END FOR
	LET s_maxjdx = 0
	LET p_retstat = TRUE
	LET p_retstat = sty_entLAX("SELECT")			
	LET p_retstat = sty_entLAX("BROWSE")			

WHEN p_state = "SELECT"
	DECLARE c_sel CURSOR FOR 
		SELECT	* 
		FROM	t_image
		ORDER	BY style

	LET idx = 1
	FOREACH c_sel INTO r_image.*
		LET ssa_estycollns[idx].style = r_image.style
		LET ssa_estycollns[idx].colour = r_image.colour
		LET ssa_estycollns[idx].publish = r_image.au_publish
		LET ssa_estycollns[idx].hero_image = r_image.au_hero_image
		#nz
		LET ssa_estycollns[idx].nz_publish = r_image.nz_publish
		LET ssa_estycollns[idx].nz_hero_image = r_image.nz_hero_image
		#hongkong
		LET ssa_estycollns[idx].hk_publish = r_image.hk_publish
		LET ssa_estycollns[idx].hk_hero_image = r_image.hk_hero_image
		#singapore
		LET ssa_estycollns[idx].sin_publish = r_image.sg_publish
		LET ssa_estycollns[idx].sin_hero_image = r_image.sg_hero_image

		LET ssa_estycollns[idx].dw_auhero_img = r_image.dw_au_hero_image
		LET ssa_estycollns[idx].dw_nzhero_img = r_image.dw_nz_hero_image
		LET ssa_estycollns[idx].dw_hkhero_img = r_image.dw_hk_hero_image
		LET ssa_estycollns[idx].dw_sghero_img = r_image.dw_sg_hero_image


		LET ssa_estycollns[idx].dwilabel1 = r_image.au_image1
		LET ssa_estycollns[idx].dwilabel2 = r_image.au_image2
		LET ssa_estycollns[idx].dwilabel3 = r_image.au_image3
		LET ssa_estycollns[idx].dwilabel4 = r_image.au_image4
		LET ssa_estycollns[idx].dwilabel5 = r_image.au_image5

		#hongkong
		LET ssa_estycollns[idx].hkilabel1 = r_image.hk_image1
		LET ssa_estycollns[idx].hkilabel2 = r_image.hk_image2
		LET ssa_estycollns[idx].hkilabel3 = r_image.hk_image3
		LET ssa_estycollns[idx].hkilabel4 = r_image.hk_image4
		LET ssa_estycollns[idx].hkilabel5 = r_image.hk_image5
		#singapore
		LET ssa_estycollns[idx].sgilabel1 = r_image.sg_image1
		LET ssa_estycollns[idx].sgilabel2 = r_image.sg_image2
		LET ssa_estycollns[idx].sgilabel3 = r_image.sg_image3
		LET ssa_estycollns[idx].sgilabel4 = r_image.sg_image4
		LET ssa_estycollns[idx].sgilabel5 = r_image.sg_image5

		LET idx = idx + 1
		END FOREACH
display "idx ",s_maxjdx
		LET s_maxjdx = idx - 1
		IF idx <= g_arrsize THEN
			INITIALIZE ssa_estycollns[idx].* TO NULL
			FOR jdx = idx TO g_arrsize
				LET ssa_estycollns[jdx].* = ssa_estycollns[idx].* 
			END FOR
		END IF

WHEN p_state = "BROWSE"
		LET p_retstat = TRUE
		CALL SET_COUNT(s_maxjdx)
		DISPLAY ARRAY ssa_estycollns TO sc_stycollns.* ATTRIBUTE (NORMAL)
			ON ACTION cancel
				LET p_retstat = FALSE
				LET p_display = "upload aborted"
   	   			CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
				EXIT DISPLAY

			ON ACTION accept
				LET p_display = "\nFinal Warning - The csv file upload will overwite ",
							    "\nall previous products/images in the Style-Colour table",
                            	"\nDo you want to continue?"

				MENU "Dialog"
       			ATTRIBUTE( STYLE="dialog",
                COMMENT= p_display,
                IMAGE="stop")
       			COMMAND "No" 
					display "NO"
					LET p_display = "upload file update aborted"
   	   				CALL fgl_winmessage("IMPORT ERRORS",p_display,"information")
                	LET  p_retstat = FALSE
       			COMMAND "Yes" 
					IF NOT sty_entLW() THEN
 						LET p_display =
             				"upload file update failed "
							CALL messagebox(p_display,1)  		#gxx
						LET p_retstat = FALSE
					ELSE
						LET p_retstat = TRUE
					END IF
					display "YES"
  				END MENU
				EXIT DISPLAY
		END DISPLAY
		##CALL sty_entLAX("DISPLAY") RETURNING p_retstat

WHEN p_state = "DISPLAY"
	FOR idx = 1 TO g_dspsize
		DISPLAY ssa_estycollns[idx].* TO sc_stycollns[idx].* 
		ATTRIBUTE(NORMAL)
	END FOR
	LET p_retstat = TRUE

END CASE
RETURN p_retstat
END FUNCTION
FUNCTION sty_entLW()
	DEFINE
		    r_image					TYPE_IMAGE,
			p_retstat				INTEGER,
			idx						INTEGER,
    		p_au_publish 			INT,
    		p_au_hero_image 		INT,
    		p_hk_publish 			INT,
    		p_hk_hero_image 		INT,
    		p_sg_publish 			INT,
    		p_sg_hero_image 		INT,
    		p_nz_publish 			INT,
    		p_nz_hero_image 		INT,
    		p_dw_au_hero_image		INT,
    		p_dw_hk_hero_image		INT,
    		p_dw_sg_hero_image 		INT,
    		p_dw_nz_hero_image		INT

	LET p_retstat = TRUE
	BEGIN WORK

    DECLARE c_ins1 CURSOR FOR
		SELECT	*
		FROM	t_image
		ORDER BY 1
	FOREACH c_ins1 INTO r_image.*
##display "updating style colour: ",r_image.*

    	IF r_image.au_publish = "Y" THEN
    		LET p_au_publish = 1
		ELSE
    		LET p_au_publish = 0
		END IF

    	IF r_image.au_hero_image  = "Y" THEN
    		LET p_au_hero_image  = 1
		ELSE
    		LET p_au_hero_image  = 0
		END IF

    	IF r_image.hk_publish = "Y" THEN
    		LET p_hk_publish = 1
		ELSE
    		LET p_hk_publish = 0
		END IF

    	IF r_image.hk_hero_image = "Y" THEN
    		LET p_hk_hero_image = 1
		ELSE
    		LET p_hk_hero_image = 0
		END IF

    	IF r_image.sg_publish = "Y" THEN
    		LET p_sg_publish = 1
		ELSE
    		LET p_sg_publish = 0
		END IF
	
    	IF r_image.sg_hero_image = "Y" THEN
    		LET  p_sg_hero_image = 1
		ELSE
    		LET  p_sg_hero_image = 0
		END IF

    	IF r_image.nz_publish = "Y" THEN
    		LET p_nz_publish = 1
		ELSE
    		LET p_nz_publish = 0
		END IF
    	IF r_image.nz_hero_image =  "Y" THEN
    		LET p_nz_hero_image =  1
		ELSE
    		LET p_nz_hero_image =  0
		END IF

    	IF r_image.dw_au_hero_image = "Y" THEN
    		LET p_dw_au_hero_image = 1
		ELSE
    		LET p_dw_au_hero_image = 0
		END IF
    	IF r_image.dw_hk_hero_image = "Y" THEN
    		LET  p_dw_hk_hero_image = 1
		ELSE
    		LET  p_dw_hk_hero_image = 0
		END IF
    	IF r_image.dw_sg_hero_image = "Y" THEN
    		LET p_dw_sg_hero_image = 1
		ELSE
    		LET p_dw_sg_hero_image = 0
		END IF
    	IF r_image.dw_nz_hero_image = "Y" THEN
    		LET p_dw_nz_hero_image = 1
		ELSE
    		LET p_dw_nz_hero_image = 0
		END IF
    	IF r_image.au_image1 IS NOT NULL THEN
    		LET r_image.au_image1 = "Y:/",r_image.au_image1 CLIPPED
		END IF
    	IF r_image.au_image2 IS NOT NULL THEN
    		LET r_image.au_image2 = "Y:/",r_image.au_image2 CLIPPED
		END IF
    	IF r_image.au_image3 IS NOT NULL THEN
    		LET r_image.au_image3 = "Y:/",r_image.au_image3 CLIPPED
		END IF
    	IF r_image.au_image4 IS NOT NULL THEN
    		LET r_image.au_image4 = "Y:/",r_image.au_image4 CLIPPED
		END IF
    	IF r_image.au_image5 IS NOT NULL THEN
    		LET r_image.au_image5 = "Y:/",r_image.au_image5 CLIPPED
		END IF
    	IF r_image.hk_image1 IS NOT NULL THEN
    		LET r_image.hk_image1 = "Y:/",r_image.hk_image1 CLIPPED
		END IF
    	IF r_image.hk_image2 IS NOT NULL THEN
    		LET r_image.hk_image2 = "Y:/",r_image.hk_image2 CLIPPED
		END IF
    	IF r_image.hk_image3 IS NOT NULL THEN
    		LET r_image.hk_image3 = "Y:/",r_image.hk_image3 CLIPPED
		END IF
    	IF r_image.hk_image4 IS NOT NULL THEN
    		LET r_image.hk_image4 = "Y:/",r_image.hk_image4 CLIPPED
		END IF
    	IF r_image.hk_image5 IS NOT NULL THEN
    		LET r_image.hk_image5 = "Y:/",r_image.hk_image5 CLIPPED
		END IF
    	IF r_image.sg_image1 IS NOT NULL THEN
    		LET r_image.sg_image1 = "Y:/",r_image.sg_image1 CLIPPED
		END IF
    	IF r_image.sg_image2 IS NOT NULL THEN
    		LET r_image.sg_image2 = "Y:/",r_image.sg_image2 CLIPPED
		END IF
    	IF r_image.sg_image3 IS NOT NULL THEN
    		LET r_image.sg_image3 = "Y:/",r_image.sg_image3 CLIPPED
		END IF
    	IF r_image.sg_image4 IS NOT NULL THEN
    		LET r_image.sg_image4 = "Y:/",r_image.sg_image4 CLIPPED
		END IF
    	IF r_image.sg_image5 IS NOT NULL THEN
    		LET r_image.sg_image5 = "Y:/",r_image.sg_image5 CLIPPED
		END IF

		UPDATE	style_colour
    	SET		publish = p_au_publish,
    			hero_image = p_au_hero_image ,
    			mod_flg = "Y",
    			hk_publish = p_hk_publish,
    			hk_hero_image = p_hk_hero_image,
    			sin_publish = p_sg_publish ,
    			sin_hero_image = p_sg_hero_image,
    			nz_publish = p_nz_publish,
    			nz_hero_image = p_nz_hero_image,
    			dw_auhero_img = p_dw_au_hero_image,
    			dw_hkhero_img = p_dw_hk_hero_image,
    			dw_sghero_img = p_dw_sg_hero_image,
    			dw_nzhero_img = p_dw_nz_hero_image,
    			dwilabel1 = r_image.au_image1,
    			dwilabel2 = r_image.au_image2,
    			dwilabel3 = r_image.au_image3,
    			dwilabel4 = r_image.au_image4,
    			dwilabel5 = r_image.au_image5,
    			dwmod_flg = "Y",
    			hkilabel1 = r_image.hk_image1,
    			hkilabel2 = r_image.hk_image2,
    			hkilabel3 = r_image.hk_image3,
    			hkilabel4 = r_image.hk_image4,
    			hkilabel5 = r_image.hk_image5,
    			hkmod_flg = "Y",
    			sgilabel1 = r_image.sg_image1,
    			sgilabel2 = r_image.sg_image2,
    			sgilabel3 = r_image.sg_image3,
    			sgilabel4 = r_image.sg_image4,
    			sgilabel5 = r_image.sg_image5,
    			sgmod_flg = "Y"
		WHERE	style = r_image.style
		AND		colour = r_image.colour

		IF status != 0 THEN
			DISPLAY "Update failed"
		 	LET p_retstat = FALSE
			EXIT FOREACH
		END IF	
	END FOREACH
	IF p_retstat THEN
		INSERT INTO upload_image 
		SELECT	*
		FROM	t_upload_image

		IF status != 0 THEN
			DISPLAY "Update Not ok 1"
			ROLLBACK WORK
			LET p_retstat = FALSE
		ELSE
			DISPLAY "Update ok"
			COMMIT WORK
		END IF
	ELSE
		DISPLAY "Update Not ok"
		ROLLBACK WORK
	END IF
	RETURN p_retstat
END FUNCTION
FUNCTION validate_image(p_url_image)
	DEFINE
			p_url_image				STRING
  	DEFINE req com.HTTPRequest
  	DEFINE resp com.HTTPResponse

  TRY
    LET req = com.HTTPRequest.Create(p_url_image)
    CALL req.doRequest()
    LET resp = req.getResponse()

    IF resp.getStatusCode() != 200 THEN
    #	display "ret code not found : ", resp.getStatusCode()
      #DISPLAY "Image not found ",p_url_image
	  RETURN FALSE
    ELSE
      #display "ret code  found : ", resp.getStatusCode()
      #DISPLAY "Image found ",p_url_image
	  RETURN TRUE
    END IF
  CATCH
    DISPLAY "ERROR :",STATUS||" ("||SQLCA.SQLERRM||")"
  END TRY
END FUNCTION
