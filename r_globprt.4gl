
{@@@

Retail Management Information System - RAMIS
Copyright (C) Voyager Distributing Co. Pty. Ltd., 1989 - 1996
All Rights Reserved.
Licensed Material-Property of Voyager Distributing Co. Pty. Ltd.
This software is made available solely pursuant to the
terms of a VDC license agreement which governs its use.
 
Company         : Voyager Distributing Co. Pty. Ltd.

System          : Ramis - Retail Management Information System

Program Name    :

Main Program    : (Yes - if main program)
                  (If main program list all modules in 
				  Compilation Specifications)

Module Name     :

Function        : This program

Module Files    : The following modules are called by this module

Compilation    
Specifications  : Sources       -

		  Other Sources -
				 
Modification Log: Date	Reason for Modification        Programmer


@@@}
DATABASE seed 
				 
				
GLOBALS

	DEFINE
		p_quereq	RECORD	LIKE quereq.*,
		p_po_qry_ord_nbr	LIKE po_hdr.ord_nbr,
		p_alloc_nbr			LIKE po_hdr.alloc_nbr,
		p_aquereq	ARRAY[15] OF RECORD
			queprt		LIKE queprt.queprt,
			quename		LIKE queprt.quename
		END RECORD,
		print_option	CHAR(1),
		label_pos		CHAR(1),
		quereq_cnt, 
		retry_stat SMALLINT,

		p_ctrl_char	RECORD
			qnormal		LIKE queprt.qnormal,
			qelongated	LIKE queprt.qelongated,
			qcondensed	LIKE queprt.qcondensed,
			qmemo		LIKE queprt.qmemo,
			q8lpi		LIKE queprt.q8lpi,
			q6lpi      	LIKE queprt.q6lpi
		END RECORD,
	
		p_copies 	RECORD
			req_nbr		SMALLINT
		END RECORD

END GLOBALS

