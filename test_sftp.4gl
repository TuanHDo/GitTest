MAIN
	DEFINE
			p_cmd					STRING
	
			LET p_run = "/opt/brandbank/seed/fastpos/image.sh "
			display "ftp here ", p_run
			RUN p_run WITH NO WAITONG
			display "ok"
END MAIN  
