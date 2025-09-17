/*------------------------------------------------------------------------------*
| Title: 			Master code													|
| Project: 			Equal Pay                                             		|
| Authors:			María José Mesías, Julián López								|
| 					  									                        |
|																				|
| Description:		This .do sets up relevant file paths and directories 		|
|                                                                               |
| Date created: 15/09/2025			 					                        |										          
|																			    |
| Version: Stata 18                         							 	    |
*-------------------------------------------------------------------------------*/

/*--------------------------*
*           INDEX           *
*---------------------------*

	0. Setup and directory
	I. Define paths

*-------------------------------------------------------------------------------*/

*-----------------------------------*
**#		0. Setup and directory		*
*-----------------------------------*
	clear all
	clear mata
	set more off
	version 18
	
*-----------------------------------*
**#		I. Define paths				*
*-----------------------------------*

* check what your username is in Stata by typing "di c(username)"
	if "`c(username)'" == "julia"  {
		global root "C:/Users/julia/Documents/equal_pay" // file path where the folder is stored
		local os        "windows"
		}

		
* check what your username is in Stata by typing "di c(username)"
	if "`c(username)'" == "PC031"  {
		global root "G:\Mi unidad\equal_pay" // file path where the folder is stored
		local os        "windows"
		}		
		

			global input "${root}/data/ENAHO_modules"
			global full  "${root}/data/ENAHO_full"
			global out   "${root}/output"
			global code_dir "${root}/scripts"
			cap mkdir "${full}"
			cap mkdir "${out}"
			
///////////////////////////////////////////////////////////////////////////

	* Run do files 
	* Switch to 0/1 to not-run/run do-files 
	if (1) do "${code_dir}/1_Merge_ENAHO.do"
	
	if (1) do "${code_dir}/2_oaxaca_pea_total.do"
	
	if (1) do "${code_dir}/3_oaxaca_wage.do"
	
	
	
