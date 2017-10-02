clear all

glo dropbox="/data/uctppar/Dengue" //HPC
*glo dropbox="P:\Dengue"
	

glo mainFolder="$dropbox" //HPC

do "$mainFolder/do/0.Programs.do"
//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

use "$dropbox/miFolder/Base_IndivDengue2007-2012.dta", clear
*sample 5, by(edad codigocolegio semestre)
*save "$dropbox\miFolder\Base_IndivDengue2007-2012Sample5.dta", replace

foreach vari in TEMA_MATEMATICA TEMA_LENGUAJE  {
	replace  `vari'=. if  `vari'<20
	gen `vari'_STD=.
	foreach yi in 20071 20072 20081 20082 20091 20092 20101 20102 20111 20112 20121 20122 {
		sum `vari' if semestre==`yi', d
		local mean=r(mean)
		local sd=r(sd)
		replace `vari'_STD= (`vari'-`mean')/`sd'  if semestre==`yi'
	}
}

drop if semestre==20071 |  semestre==20081 | semestre==20091  | semestre==20101  | semestre==20111  | semestre==20121
	*keep if semestre==20071 |  semestre==20081 | semestre==20091  | semestre==20101  | semestre==20111  | semestre==20121 // For Rob. Checks
keep if COLE_CALENDARIO_COLEGIO=="A"
keep if COLE_INST_JORNADA=="C" | COLE_INST_JORNADA=="COMPLETA U ORDINARIA" | COLE_INST_JORNADA=="M" | COLE_INST_JORNADA=="MAÑANA" | COLE_INST_JORNADA=="T" | COLE_INST_JORNADA=="TARDE"

 


tab COLE_GENERO_POBLACION, gen(dgen_)
tab COLE_NATURALEZA, gen(dnat_)

replace COLE_INST_JORNADA="M" if COLE_INST_JORNADA=="MAÑANA"
replace COLE_INST_JORNADA="T" if COLE_INST_JORNADA=="TARDE"
replace COLE_INST_JORNADA="C" if COLE_INST_JORNADA=="COMPLETA U ORDINARIA"

tab COLE_INST_JORNADA, gen(djor_)

recode FAMI_COD_EDUCA_PADRE (0=1) (9 10=2) (11=3) (12=4) (13 14 15 16 17 = 5) (99 = 6), gen(edup)
recode FAMI_COD_EDUCA_MADRE (0=1) (9 10=2) (11=3) (12=4) (13 14 15 16 17 = 5) (99 = 6), gen(edum)
tab FAMI_COD_EDUCA_PADRE , nolabel
tab edup , gen(edup_)
tab FAMI_COD_EDUCA_MADRE , nolabel
tab edum , gen(edum_)

label var edup_1 "Father Educ: None"
label var edup_2 "Father Educ: At most Primary"
label var edup_3 "Father Educ: Incomplete Secondary"
label var edup_4 "Father Educ: Complete Secondary"
label var edup_5 "Father Educ: Above Secondary"
label var edup_6 "Father Educ: Don't Know"
label var edum_1 "Mother Educ: None"
label var edum_2 "Mother Educ: At most Primary"
label var edum_3 "Mother Educ: Incomplete Secondary"
label var edum_4 "Mother Educ: Complete Secondary"
label var edum_5 "Mother Educ: Above Secondary"
label var edum_6 "Mother Educ: Don't Know"


bys codigocolegio: egen avgmath=mean(TEMA_MATEMATICA_STD) if year<2009
bys codigocolegio: egen avglang=mean(TEMA_LENGUAJE_STD) if year<2009

bys codigocolegio: egen avgmathR=max(avgmath)
bys codigocolegio: egen avglangR=max(avglang)

rename TEMA_MATEMATICA_STD math
rename TEMA_LENGUAJE_STD   lang

//////////////////////////////////////////////////////////////////////
* If you keep the other exam (semester 1)
*	collapse (mean) math lang dnat_* djor_* dgen_* avgmathR avglangR sisben12 Ingresohogar propmu=niña (sd) mathSD=math langSD=lang (count) Nmath=math Nleng=lang, by( year codigocolegio  codigomunicipio)
*	save "$dropbox/miFolder/dengueCol_Sem1.dta", replace


/* For School level analysis
preserve
	collapse (mean) math lang dnat_* djor_* dgen_* avgmathR avglangR sisben12 Ingresohogar propmu=niña (sd) mathSD=math langSD=lang (count) Nmath=math Nleng=lang, by( year codigocolegio  codigomunicipio)
	save "$dropbox/miFolder/dengueCol.dta", replace
	collapse (count) Nschools=Nmath, by( year  codigomunicipio)
	tempfile muniN
	save `muniN'
restore
	
* For Municipality level analysis
* Notice that this is a loop, this file gen "dengueColMun" and DEN_02 use it, and then generates "municipalityDengue".
	collapse (mean) math_mun=math lang_mun=lang sisben12_mun=sisben12 Ingresohogar_mun=Ingresohogar propmu=niña  (sd) mathSD_mun=math langSD_mun=lang (count) Nmath_mun=math Nleng_mun=lang, by( year  codigomunicipio)
	merge 1:1 year  codigomunicipio using `muniN', nogen
	save "$dropbox/miFolder/dengueColMun.dta", replace
	
	
	exit
*/
//////////////////////////////////////////////////////////////////////
// Add Dengue Data

rename codigocolegio cod_dane
merge n:1 codigomunicipio year using "$mainFolder/mainData/municipalityDengue.dta" , gen(mergeSABER11) keep(master match)
rename cod_dane codigocolegio


set matsize 10000

//////////////////////////////////////////////////////////////////////
// Define controls

glo basic   niña i.edad sisben12 Ingresohogar i.edup i.edum
glo school = "" // Nothing at this level!
glo munici personasAfect_STD viviendaAfect_STD vias_STD hectareas_STD /// 
		 camasHosp10000h consuUrge10000h ///
		 subsidp logingresospc deptransf  ESIp1000h logpop ///
		 t2m8M tp8M
glo natura  personasAfect L1personasAfect L2personasAfect viviendaAfect L1viviendaAfect L2viviendaAfect vias L1vias L2vias hectareas L1hectareas L2hectareas


//////////////////////////////////////////////////////////////////////
// Regressions: national sample

areg math                   L0sev L1sev L2sev $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store re1
areg math L0den L1den L2den                   $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store re2
areg lang                   L0sev L1sev L2sev $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store re3
areg lang L0den L1den L2den                   $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store re4

esttab re1 re2 re3 re4, keep(L0den L1den L2den L0sev L1sev L2sev niña sisben12 ) order(L0sev L1sev L2sev L0den L1den L2den niña sisben12 ) star(* .1 ** .05 *** .01) r2

* By gender?
areg math                   L0sev L1sev L2sev c.L0sev#i.niña c.L1sev#i.niña c.L2sev#i.niña $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store reFe1
areg math L0den L1den L2den c.L0den#i.niña c.L1den#i.niña c.L2den#i.niña                   $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store reFe2
areg lang                   L0sev L1sev L2sev c.L0sev#i.niña c.L1sev#i.niña c.L2sev#i.niña $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store reFe3
areg lang L0den L1den L2den c.L0den#i.niña c.L1den#i.niña c.L2den#i.niña                   $basic $school $munici $natura i.year , cluster(codigocolegio) absorb(codigocolegio)
est store reFe4





//////////////////////////////////////////////////////////////////////
// Latex tables: National
//////////////////////////////////////////////////////////////////////

label var niña  "=1 if student is a girl"
label var sisben12  "=1 if SISBEN level 1 or 2"

cd "$mainFolder/output/tablas"

glo nQ=4 // number of columns
glo wT="12cm"

glo nQ1=$nQ+1

	texdoc init tableStudent , replace
	tex {
	tex \scriptsize
	tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
	
	
	tex \begin{table}[H]
	tex \scriptsize
	tex \centering
	tex \caption{Student Level Analysis \label{tableStudent}}
	tex \begin{tabular}{l*{$nQ1}{c}}			
	tex \toprule
	tex \textbf{Specification} & \textbf{Math}  & \textbf{Math} & \textbf{Lang} & \textbf{Lang}\\
	tex \midrule		
		
* Coefficients LAGS **********************************
foreach varDep in L0sev L1sev L2sev L0den L1den L2den niña sisben12 {

	loca fac=1
	if ("`varDep'"=="L0den" | "`varDep'"=="L1den" | "`varDep'"=="L2den") loca fac=10

	* Dummies or continuous vars?
	cap tab `varDep'
	local fac=1
	if (_rc==0 & r(r)==2 ) local fac=1
	local unit=""
	if `fac'==100 local unit="\%"

	local lname : variable label `varDep' // Label of the variables
	local lname=  subinstr("`lname'","£","",.)
	local lname=  subinstr("`lname'","%","\%",.)
	
	* ********************************************

	est restore re1
	myCoeff2 1 `fac' "`varDep'"

	est restore re2
	myCoeff2 2 `fac' "`varDep'"

	est restore re3
	myCoeff2 3 `fac' "`varDep'"	
	
	est restore re4
	myCoeff2 4 `fac' "`varDep'"	
	
	*tex \rowcolor{Gray}
	tex \parbox[c]{6cm}{\raggedright `lname' } &  $ ${coef1} ${star1} $ & $ ${coef2} ${star2} $ & $ ${coef3} ${star3} $ & $ ${coef4} ${star4} $ \\
	tex                                               &             $ ${se1} $ &            $ ${se2} $ &            $ ${se3} $  &           $ ${se4} $ \\
	tex \addlinespace[1pt]	
}
tex \addlinespace[2pt]
tex \midrule
* Statistics **********************************

	forval i=1(1)4 {
		est restore re`i'
		local stat1`i'=e(N)
		local stat2`i'=e(N_clust)
		local stat3`i': di %7.2f  e(r2)
	}
	
	tex \rowcolor{Gray}
	tex \parbox[c]{6cm}{N Observations } &  `stat11' & `stat12' & `stat13' & `stat14' \\
	tex \parbox[c]{6cm}{N Clusters }     &  `stat21' & `stat22' & `stat23' & `stat24' \\
	tex \rowcolor{Gray}
	tex \parbox[c]{6cm}{$ R^2$ }         &  `stat31' & `stat32' & `stat33' & `stat34' \\
	tex \addlinespace[1pt]	


* Close the table file *************************************
qui {
	tex \bottomrule
	tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{SE clustered at school level. Significance: * 10\%, ** 5\%, *** 1\%}} \\
	tex \end{tabular}
	tex \end{table}
	tex }
	texdoc close	
}


//////////////////////////////////////////////////////////////////////
// Latex tables: Descriptives
//////////////////////////////////////////////////////////////////////




glo nL=2        // Number of varlists
glo nQ=7 		// Number of Cols apaprt from the var names
glo wT="8cm" 	// Table width
glo nQ1=$nQ+1
qui {
	texdoc init descriptive_SABER11 , replace force
	tex {
	tex \scriptsize
	tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
	
	tex \begin{table}[H]
	tex \scriptsize
	tex \centering
	tex \caption{Descriptive Statistics for year 2010: student level data \label{descriptive_SABER11}}\\
	tex \begin{tabular}{l*{$nQ1}{c}}			
	tex \toprule
	tex \textbf{Variable} & \textbf{Mean (SD)} & \textbf{Obs}\\
	tex \midrule	
}	
* ******************************************************************************
local cont=1

glo varis1 niña edad sisben12 Ingresohogar edup_* edum_*
glo titul1="SABER 11"

forval i=1(1)1 {
tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{\textbf{${titul`i'}}}} \\
foreach varDep of varlist ${varis`i'}   {

	if mod(`cont',2)==1  tex \rowcolor{Gray}
	local lname : variable label `varDep' // Label of the variables
	sum `varDep' if year==2010
	local mean : disp %15.2g r(mean)
	local sd   : disp %15.2g r(sd)
	local ene  : disp %15.2g r(N)
	
	tex \quad `lname' & `mean'(`sd')  & `ene' \\
	tex \addlinespace[1pt]
	local ++cont
}
tex \addlinespace[2pt]
tex \midrule
}
* Close the table file *********************************************************
qui {
	tex \bottomrule
	tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{}} \\
	tex \end{tabular}
	tex \end{table}
	tex }
	texdoc close	
}





