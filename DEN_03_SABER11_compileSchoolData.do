     /////////////////////////////////////////////////////
    // This file merges school data with municipality  //
   // data into a single file: dengueSchoolLevel.dta  //
  // which is ready for the analysis                 //
 //  21/07/2015                                     //
/////////////////////////////////////////////////////
clear all
set matsize 10000

glo mainFolder="D:\Mis Documentos\git\DengueBehavioural"

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
// School level data
use "$mainFolder/Icfes_data/dengueCol.dta", clear

replace propmu=propmu*100   
label var propmu "\% of women test-takers"

replace sisben12=sisben12*100
label var sisben12  "\% of SISBEN 1/2 of test-takers"

rename codigocolegio cod_dane

drop if cod_dane==.

		* For a balanced panel... this is not the reason of the post. math
		*bys cod_dane: egen Perio=count(year)
		*drop if Perio<6


* Esta parte es importante for balancing the panel
xtset cod_dane year
xtdescribe
tsfill, full
xtset cod_dane year
xtdescribe

rename codigomunicipio cmun
bys cod_dane: egen codigomunicipio=max(cmun)

*/

gen logest=ln(Nmath)
gen miss=logest==.

merge n:1 codigomunicipio year using "$mainFolder/mainData/municipalityDengue.dta" , gen(mergeSABER11) keep(master match)

		* It does not matter really
		*keep if avgmathR!=. // Schools for we know sth before the epidemic (in 2007 OR 2008)


*drop if year==2007 // !!!!!!!!!!!!! NUMBERS ARE SUPER ODD FOR THAT YEAR *******************************

xtset cod_dane year


label var dnat_1 "Private managment"
label var dnat_2 "Public managment"
label var djor_1 "Full-day shift"
label var djor_2 "Morning shift"
label var djor_3 "Afternoon shift"
label var dgen_1 "Female-only"
label var dgen_2 "Male-only"
label var dgen_3 "Mix gender"
label var Ingresohogar "Average Income of the Families "
label var Nmath "Number of test-takers"

saveold "$mainFolder\mainData\dengueSchoolLevel.dta", replace


