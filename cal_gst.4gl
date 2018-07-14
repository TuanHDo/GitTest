################################################################################
#	Witchery Pty Ltd													       #
#   111 Cambridge st														   #
#   Collingwodd Vic 3066													   #
#	Phone: 03 9417 7600														   #
#   																           #
#   						yr_2000 - Year 2000 Compliance 					   #
#  																			   #
# 	R00	26jun00	td			initial release			                           #
#							parameter :									   	   #
#							        p_sales - incl. GST sales                  #
#							RETURN	p_retsales - exc. GST sales                #
#																	           #
################################################################################
FUNCTION cal_gst(p_sales)
	DEFINE		
			p_sales         DECIMAL(15,2),
			p_retsales		DECIMAL(15,2)

	LET p_retsales = (p_sales * 10) / 11
	RETURN p_retsales
#test
#test
#test
END FUNCTION
################################################################################
#@@@@@@@@@@@@@@ (cal_gst) @@@@@@@@@@@
################################################################################
