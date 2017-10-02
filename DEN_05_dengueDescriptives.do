     ///////////////////////////////////////////////////////////////////
    // This file produce tables and graphs for Descriptive &         //
   // Data sections                                                 //
  // Authors: Kai Barron, Luis F. Gamboa, Paul Rodriguez-Lesmes    //
 // Date: July, 2015                                              //
///////////////////////////////////////////////////////////////////

clear all

glo mainFolder="C:\Dropbox\Dengue"
*glo mainFolder="C:\Users\PaulAndrés\Dropbox\Dengue"
glo mainFolder="C:\Users\androdri\Dropbox\Dengue"

glo datosDHS="C:\data\DHS"
*glo datosDHS="C:\Datos\DHS"

do "$mainFolder/do/0.Programs.do"

glo genOpts="  graphregion(color(white) lwidth(medium)) "

**********************************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////
// Rates graph (municipality monthly data)
if 1==0 {

	* *******************************
	cd "$mainFolder\INS_Data"
	use "DegueHemoCompiledMonth", clear

	drop if codigomunicipio==548
	drop if codigomunicipio==.

	tempfile hemo
	save `hemo'

	* *******************************
	use "DegueCompiledMonth", clear

	drop if codigomunicipio==548
	drop if codigomunicipio==.

	merge n:1 codigomunicipio year month using `hemo', gen(mergeHemo)

	
	merge n:1 codigomunicipio year using "$mainFolder/Municipality_Data/poblacionTotalDaneProyecciones.dta", gen(mergePop05) keep(master match)
	destring poblacintotal, replace

	replace clasico=0 if clasico==.
	gen clasp1000h= clasico/ (poblacintotal/1000)
	label var clasp1000h "Classic Dengue per 1000h"

	replace hemo=0 if hemo==.
	gen hemop10000h= hemo/ (poblacintotal/10000)
	label var hemop10000h "Severe Dengue per 10.000h"

	xtset codigomunicipio dm

	* REMEMBER: DO NOT USE LOGS!! We have 0s in 20% of the municipalities! That simply kills them!


	drop if year>2012
	collapse (sum) clasico hemo (mean) clasicoM=clasp1000h hemoM=hemop10000h , by(dm month) 
	tsset dm

	*twoway (tsline clasico) (tsline hemo, yaxis(2)), ytitle(N Classic Dengue Cases) ytitle(N Severe Dengue Cases, axis(2)) xtitle(Month) xline(572 584 596 608 620 632, lpattern(vshortdash)) legend(order(1 "Classic" 2 "Severe")) scheme(s2mono) name(den1, replace) $genOpts
	*twoway (tsline clasicoM) (tsline hemoM, yaxis(2)), ytitle(Classic Dengue Cases x 1.000 h) ytitle(Severe Dengue Cases x 10.000 h, axis(2)) xtitle(Month) xline(572 584 596 608 620 632, lpattern(vshortdash)) legend(order(1 "Classic" 2 "Severe")) scheme(s2mono) name(den2, replace) $genOpts
	*grc1leg den1 den2, subtitle("Impact of 1 Dengue case x1000h (2 months)")  caption("Source: Own calculations using SIVIGILA data and" "2005 Census population numbers")  $genOpts

	
	gen t4ml=0
	gen t4mu=0
	replace t4mu=0.5 if month>=6 & month<=9
		
	
	twoway (rbar t4ml t4mu dm, fcolor(gs12) lcolor(gs12) lwidth(none)) (tsline clasicoM) (tsline hemoM), ytitle(Cases x 1.000 h [Clas] / 10.000h [Sev]) xtitle(Month)  /// // xline(572 584 596 608 620 632, lpattern(vshortdash))
		legend(order(2 "Classic" 3 "Severe")) scheme(s2mono) name(den2, replace) $genOpts ///
		caption("Source: Own calculations using SIVIGILA data and 2005 Census population" "numbers. Vertical lines correspond to the 4 months prior to SABER 11 exam.")
	graph export "$mainFolder/output/images/descrip_rates.pdf", as(pdf) replace
}
**********************************************************************************************

********************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////
// Municipality yearly data

use "$mainFolder/mainData/municipalityDengue.dta", clear

cd "$mainFolder/output/tablas"

//////////////////////////////////////////////////////////////////////////////////////////////
// Rates Statistics per Year (descriptive_rates)
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==0 {


glo nL=2        // Number of varlists
glo nQ=7 		// Number of Cols apaprt from the var names
glo wT="8cm" 	// Table width
glo nQ1=$nQ+1

texdoc init descriptive_rates , replace force
tex {
tex \scriptsize
tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}

	tex \begin{table}[H]
	tex \scriptsize
	tex \centering
	tex \caption{Dengue Incidence Rates 4 months before September SABER 11 test \label{descriptive_rates}}		
	tex \begin{tabular}{l*{$nQ1}{c}}			
	tex \toprule
	tex \textbf{Statistic} & \textbf{2007} & \textbf{2008}  & \textbf{2009}  & \textbf{2010} & \textbf{2011} & \textbf{2012}\\
	tex \midrule

glo statTmean="Mean"
glo statTsd  ="Stand. Dev"
glo statTmin ="Minimum"
glo statTp5  ="Percentile 5"
glo statTp50 ="Median"
glo statTp75 ="Percentile 75"
glo statTp95 ="Percentile 95"
glo statTmax ="Maximum"

foreach varDep in L0den L0sev {

	local lname : variable label `varDep' // Label of the variables
	tex \multicolumn{$nQ1}{l}{\textbf{`lname'}} \\

	* Quite inefficient, but easy to write!
	local cont=0
	foreach stat in mean sd min p50 p75 p95 max {
		if mod(`cont',2)==1  tex \rowcolor{Gray}
		tex \quad ${statT`stat'}
		forval ye=2007(1)2012 {
			qui sum `varDep' if year==`ye', d			
			local stati : disp %5.2g r(`stat')
			tex & `stati'
		}
		tex \\
		tex \addlinespace[1pt]
		local ++cont
	}
	* Variation ****
	cap gen D`varDep'=`varDep'-L.`varDep'
	if mod(`cont',2)==1  tex \rowcolor{Gray}
	tex \quad 1 year variation
	forval ye=2007(1)2012 {
		qui sum D`varDep' if year==`ye', d			
		local stati : disp %5.2g r(mean)
		tex & `stati'
	}
	tex \\
	tex \addlinespace[1pt]

	
	tex \addlinespace[2pt]
	tex \midrule
}

* Close the table file *************************************

	tex \bottomrule
	tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{Source: Own calculations based on SIVIGILA data and DANE national census 2005 population numbers.}} \\
	tex \end{tabular}
	tex \end{table}
	tex }

texdoc close	



}


//////////////////////////////////////////////////////////////////////////////////////////////
// Dengue Intensity and variation (intesityIdea.png)
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==0 {
	gen zero= L2.hemop10000h ==0 & L3.hemop10000h==0
	label var zero "Municipalities with 0 cases of S. Dengue in 2007 & 2006"

	gen Xhemop10000h= hemop10000h/L.hemop10000h
	label var Xhemop10000h "S. Dengue incidence 2009 over incidence 2010"


	lpoly  zero hemop10000h if year==2010 & hemop10000h<10, nosca ci legend( off) name(a1, replace) title("New cases")
	lpoly  Xhemop10000h hemop10000h if year==2010 & hemop10000h<10, nosca ci legend( off) name(a2, replace) title("Variation Intensity")
	graph combine a1 a2

	keep if year==2010
	*gen SDE_dv_m_1=string(codigomunicipio,"%05.0f")
	export delimited using "$mainFolder\maps\DengueMuni2010.csv", replace nolabel
}
//////////////////////////////////////////////////////////////////////////////////////////////
// Reading the rates (municipalities with rates above 10)
//////////////////////////////////////////////////////////////////////////////////////////////
gen alfa= clasp1000h>=10 if year==2010
bys alfa: egen num=total( poblacintotal)
sum num if alfa==1

gen alfa2= hemop10000h>=10 if year==2010
list codigodepartamento codigomunicipio if alfa2==1


//////////////////////////////////////////////////////////////////////////////////////////////
// Histogram Dengue Outbreak 2010
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==0 {
	label def trun 4 "4 or more"

	clonevar trunclasp1000h=clasp1000h
	replace trunclasp1000h=4 if trunclasp1000h>4 & trunclasp1000h!=.
	label values  trunclasp1000h trun

	clonevar trunhemop10000h=hemop10000h
	replace trunhemop10000h=4 if trunhemop10000h>4 & trunhemop10000h!=.
	label values  trunhemop10000h trun


	gen     clasC=0 	if clasp1000h==0
	replace clasC=1 	if clasp1000h>0   & clasp1000h<=0.5
	replace clasC=2 	if clasp1000h>0.5 & clasp1000h<=1
	replace clasC=3 	if clasp1000h>1   & clasp1000h<=1.5
	replace clasC=4 	if clasp1000h>1.5 & clasp1000h<=2
	replace clasC=5 	if clasp1000h>2   & clasp1000h<=2.5
	replace clasC=6 	if clasp1000h>2.5 & clasp1000h<=3
	replace clasC=7 	if clasp1000h>3   & clasp1000h<=3.5
	replace clasC=8 	if clasp1000h>3.5 & clasp1000h<=4
	replace clasC=9 	if clasp1000h>4   & clasp1000h!=.

	label def Val 0 "0 cases" 1 "(0,0.5]" 2 "(0.5,1]" 3 "(1,1.5]" 4 "(1.5,2]" 5 "(2,2.5]" 6 "(2.5,3]" 7 "(3,3.5]" 8 "(3.5,4]" 9 "Above 4", replace
	label values  clasC Val

	gen     hemoC=0 	if hemop10000h==0
	replace hemoC=1 	if hemop10000h>0   & hemop10000h<=0.5
	replace hemoC=2 	if hemop10000h>0.5 & hemop10000h<=1
	replace hemoC=3 	if hemop10000h>1   & hemop10000h<=1.5
	replace hemoC=4 	if hemop10000h>1.5 & hemop10000h<=2
	replace hemoC=5 	if hemop10000h>2   & hemop10000h<=2.5
	replace hemoC=6 	if hemop10000h>2.5 & hemop10000h<=3
	replace hemoC=7 	if hemop10000h>3   & hemop10000h<=3.5
	replace hemoC=8 	if hemop10000h>3.5 & hemop10000h<=4
	replace hemoC=9 	if hemop10000h>4   & hemop10000h!=.
	label values  hemoC Val


	tw (hist clasC if year==2009 , percent width(1) xlabel(, angle(forty_five) valuelabel) ) (hist clasC if year==2010 , percent width(1) fcolor(none) lcolor(black) lwidth(thick) xlabel(, angle(forty_five) valuelabel) ) , name(a1, replace) title(Classic) xtitle(Cases per 1.000h calendar year) caption(Truncated at 4) legend( order(1 "2009" 2 "2010") cols(2) pos(6)) scheme(lean2)
	tw (hist hemoC if year==2009 , percent width(1) xlabel(, angle(forty_five) valuelabel) ) (hist hemoC if year==2010 , percent width(1) fcolor(none) lcolor(black) lwidth(thick) xlabel(, angle(forty_five) valuelabel) ),  name(a2, replace) title(Severe) xtitle(Cases per 10.000h calendar year) caption(Truncated at 4)  legend( order(1 "2009" 2 "2010") cols(2) pos(6)) scheme(lean2)
	grc1leg a1 a2, ycommon scheme(lean2)
	graph export "$mainFolder/output/images/descrip_histo.pdf", as(pdf) replace
}
//////////////////////////////////////////////////////////////////////////////////////////////
// Determinants Severe Dengue Outbreak 2010
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==1 {

xtset codigomunicipio year


gen pobEscol = (TotalPrimary + TotalSecondary)/poblacintotal

gen pobEscol2010=pobEscol*(year==2010)
label var pobEscol2010 "Enrolment/Population x (year=2010)"
gen alt2010=altitud*(year==2010)
label var alt2010 "Altitude x (year=2010)"
gen NBI2010=NBI*(year==2010)
label var NBI2010 "NBI Poverty Index x (year=2010)"
gen logpop2010=logpop*(year==2010)
label var logpop2010 "Log(Population) x (year=2010)"
gen certificacionSalud2010=certificacionSalud*(year==2010)
label var certificacionSalud2010 "Certified x (year=2010)"
gen urbanrat2010=urbanrat*(year==2010)
label var urbanrat2010 "% Urban population x (year=2010)"


label var dyear_3 "Year = 2009"
label var dyear_4 "Year = 2010" 
label var dyear_5 "Year = 2011"
label var dyear_6 "Year = 2012"

xtreg hemop10000h alt2010 t2m12M tp12M                                                       ESIp1000h dyear_3 dyear_4 dyear_5 dyear_6            if altitud<2000, fe cluster(codigomunicipio)
est store r1

xtreg hemop10000h alt2010 t2m12M tp12M  NBI2010 certificacionSalud2010 ESIp1000h dyear_3 dyear_4 dyear_5 dyear_6            if altitud<2000 , fe cluster(codigomunicipio)
est store r2

xtreg hemop10000h alt2010 t2m12M tp12M  NBI2010 certificacionSalud2010 ESIp1000h dyear_3 dyear_4 dyear_5 dyear_6 clasp1000h if altitud<2000 , fe cluster(codigomunicipio)
est store r3

xtreg hemop10000h alt2010 t2m12M tp12M  NBI2010  certificacionSalud2010 ESIp1000h dyear_3 dyear_4 dyear_5 dyear_6            if altitud<1000 , fe cluster(codigomunicipio)
est store r4

xtreg hemop10000h alt2010 t2m12M tp12M  NBI2010 certificacionSalud2010 ESIp1000h dyear_3 dyear_4 dyear_5 dyear_6            if altitud>1000 & altitud<2000 , fe cluster(codigomunicipio)
est store r5

cd  "$mainFolder/output/tablas"
// Latex table: Change titles of scalars by hand!
	qui {
	
		local setRegs = "r1 r2 r3 r4 r5"
		local cols = wordcount("`setRegs'")+2
		local cwidth="18cm"
	
		texdoc init determinantsSevere , replace force
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \scriptsize
		tex \centering
		tex \caption{Determinants of Severe Dengue Incidence (cases per 10.000h in the 2010 calendar year) \label{determinantsSevere}}		
		tex \begin{tabular}{l*{`cols'}{c}}			
		tex \toprule
		tex &             & \multicolumn{3}{c}{Below 2000 masl } & \multicolumn{1}{c}{Below 1000 masl } & \multicolumn{1}{c}{1000-2000 masl } \\
		tex \cmidrule(lr){3-5} \cmidrule(lr){6-6} \cmidrule(lr){7-7}
		tex & $ \bar{X} $ & (1) & (2) & (3) & (4) & (5) \\
		tex \midrule
									
		foreach varDep in alt2010 t2m12M tp12M NBI2010 certificacionSalud2010 dyear_3 dyear_4 dyear_5 dyear_6 clasp1000h {

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
			sum `varDep'
			local meano: di %7.3f r(mean)
			
			local line1="\parbox[c]{6cm}{\raggedright `lname' } & `meano' "
			local line2=" & "
			local count=1
			foreach regi in `setRegs' {
			
				est restore `regi'
				myCoeff2 `count' `fac' "`varDep'"
				
				local line1="`line1' & $ ${coef`count'} ${star`count'} $ "
				local line2="`line2' & $ ${se`count'} $ "

				local count=`count'+1
			}
			
			*tex \rowcolor{Gray}
			
			tex `line1' \\
			tex `line2' \\
			tex \addlinespace[1pt]	
		}
		tex \addlinespace[2pt]
		tex \midrule
		* Statistics **********************************
		glo titleN       = "N Observations"
		glo titleN_clust = "N Clusters (Departments)"
		glo titler2_a    = " Adjusted $ R^2 $ "
		glo titler2_p    = "Pseudo-$ R^2 $"
		
		local count=1
		foreach stat in N N_clust r2_a  {
			
			local line1= " \parbox[c]{6cm}{${title`stat'}} & "
			foreach regi in `setRegs' {	
				est restore `regi'
				if "`stat'"=="N" | "`stat'"=="N_clust"{
					local statis: di %7.0f  e(`stat')
				}
				else {
					local statis: di %7.3f  e(`stat')			
				}
				if `statis'==. local statis=""
				
				local line1= "`line1' & `statis' "
			}
			*if mod(`count',2)==1 tex \rowcolor{Gray}
			tex `line1' \\
			
			local count=`count'+1
		}

		tex \bottomrule
		tex \multicolumn{`cols'}{l}{\parbox[l]{`cwidth'}{$ \dagger$ Linear panel fixed effects regression at municipality level with Severe Dengue Incidence (10.000 cases per hab., calendar year) as a dependent. }} \\
		tex \multicolumn{`cols'}{l}{\parbox[l]{`cwidth'}{  Certified municipalities are those who are able to determine how they spend part of their education and/or certain health care resources according to previous performance assessments by Central Government. For those non-certified, such expenses are controlled directly by the departmental authorities. This classification depends on population size and on some administrative quality indicators. The NBI is a government multidimensional poverty index which considers quality of life and access to public goods. A summary of the variables included in this table is presented in Table \ref{tab:descriptives}. }} \\
		tex \multicolumn{`cols'}{l}{\parbox[l]{`cwidth'}{Robust standard errors in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. }} \\


		tex \end{tabular}
		tex \end{table}
		tex }
	}
		
}

//////////////////////////////////////////////////////////////////////////////////////////////
// Altitude and Dengue
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==0 {

	tw (lpoly clasp1000h altitud if year==2010, lwidth(thick) ) (lpoly clasp1000h altitud if year==2008) (lpoly clasp1000h altitud if year==2009, lwidth(thick)) (lpoly clasp1000h altitud if year==2011) if altitud<3000, ///
		ytitle(Classic Dengue Cases x 1.000 h) xline(1800) xtitle(Meters above sea level) $genOpts scheme(s2mono) ///
		legend(order(1 "2010" 2 "2008" 3 "2009" 4 "2011") cols(3)) 
	graph export "$mainFolder/output/images/descrip_altitude.pdf", as(pdf) replace

	tw (lpoly hemop10000h altitud if year==2010, lwidth(thick) ) (lpoly hemop10000h altitud if year==2008) (lpoly hemop10000h altitud if year==2009, lwidth(thick)) (lpoly hemop10000h altitud if year==2011) if altitud<3000, ///
		ytitle(Severe Dengue Cases x 10.000 h) xline(1800) xtitle(Meters above sea level) $genOpts scheme(s2mono) ///
		legend(order(1 "2010" 2 "2008" 3 "2009" 4 "2011") cols(3)) caption("Source: Own calculations using SIVIGILA data and 2005 Census population" "numbers. Incidence rates are per calendar year.")
	graph export "$mainFolder/output/images/descrip_altitudeSevere.pdf", as(pdf) replace

}
//////////////////////////////////////////////////////////////////////////////////////////////
// Descriptives Municipality Level (descriptive_muni)
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==1 {

gen grado11=(TotalGrado11+TotalGrado12+TotalGrado13)
label var grado11 "Last year of secondary school"

gen matPri=TotalPrimary/1000
label var matPri "Enrolment Primary (1000s)"

gen matSec=TotalSecondary/1000
label var matSec "Enrolment Secondary (1000s)"

cap gen pobEscol = (TotalPrimary + TotalSecondary)/poblacintotal
label var pobEscol "Enrolment/Population"

label var Nschools "Number of schools which participate in SABER 11"
label var Nmath_mun "Number of SABER 11 test takers"

label var logingresospc "Log income per capita"

label var consuUrge10000h "A\&E positions per 10.000h"

glo nL=2        // Number of varlists
glo nQ=3 		// Number of Cols apaprt from the var names
glo wT="10cm" 	// Table width
glo nQ1=$nQ+1
qui {
	texdoc init descriptives , replace force
	tex {
	tex \scriptsize
	tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
	
	tex \begin{table}[H]
	tex \scriptsize
	tex \centering
	tex \caption{Descriptive Statistics for year 2010 \label{tab:descriptives}}
	tex \begin{tabular}{l*{$nQ1}{c}}			
	tex \toprule
	tex \textbf{Variable} & \textbf{Mean} &  \textbf{SD} & \textbf{Obs}\\
	tex \midrule		

}	
* ******************************************************************************
local cont=1


glo varis1 poblacintotalm altitud t2m8M tp8M NBI2010 subsidp logingresospc deptransf  logpop camasHosp10000h consuUrge10000h certificacionSalud2010
glo titul1="Municipality: general characteristics (CEDE, DNP, SIHO, ERA-Interim ECMWF)"

glo varis2 ESIp1000h 
glo titul2="Municipality: other infectious diseases (SIVIGILA)"

glo varis3 personasAfect viviendaAfect vias hectareas
glo titul3="Municiipality: emergencies due to natural events (SNIGRD)"

forval i=1(1)3 {
	tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{\textbf{${titul`i'}}}} \\
	foreach varDep in ${varis`i'}   {

		*if mod(`cont',2)==1  tex \rowcolor{Gray}
		local lname : variable label `varDep' // Label of the variables
		sum `varDep' if year==2010
		local mean : disp %15.2g r(mean)
		local sd   : disp %15.2g r(sd)
		local ene  : disp %15.2g r(N)
		
		tex \quad `lname' & `mean' & `sd'  & `ene' \\

		local ++cont
	}
	tex \addlinespace[2pt]
	tex \midrule
}

}

********************************************************************************
//////////////////////////////////////////////////////////////////////////////////////////////
// Google Trends and rates (weekly)
if 1==0 {
	use "$mainFolder\GoogleTrends\weeklyColombia.dta", clear

	twoway (tsline dengue), tlabel(, angle(forty_five)) caption("Weekly Google trends data for the term 'Dengue' in Colombia ") scheme(lean2)
	graph export "$mainFolder/output/images/googleTrends.pdf", as(pdf) replace
}


********************************************************************************
////////////////////////////////////////////////////////////////////////////////
use "$mainFolder\mainData\dengueSchoolLevel.dta", clear


//////////////////////////////////////////////////////////////////////////////////////////////
// Descriptives School Level (2010) (descriptives, 2nd part)
//////////////////////////////////////////////////////////////////////////////////////////////
if 1==1 {

* ******************************************************************************
local cont=1

glo varis1 dnat_1 dnat_2 djor_1 djor_2 djor_3 dgen_1 dgen_2 dgen_3 propmu sisben12 Ingresohogar Nmath
glo titul1="School characteristics"


*glo basic   niña i.edad sisben12 Ingresohogar i.edup i.edum
*glo school = "" // Nothing at this level!

forval i=1(1)1 {
tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{\textbf{${titul`i'}}}} \\
foreach varDep in ${varis`i'}   {

	*if mod(`cont',2)==1  tex \rowcolor{Gray}
	local lname : variable label `varDep' // Label of the variables
	sum `varDep' if year==2010
	local mean : disp %15.2g r(mean)
	local sd   : disp %15.2g r(sd)
	local ene  : disp %15.2g r(N)
	
	tex \quad `lname' & `mean' & `sd' & `ene' \\
	local ++cont
}
tex \addlinespace[2pt]

}
* Close the table file *********************************************************
qui {
	tex \bottomrule
	tex \multicolumn{$nQ1}{l}{\parbox[c]{$wT}{  ///
		Source: Own calculations based on ICFES data, \textit{Sistema Nacional de Informacion y Gestion del Riesgo} (SNIGRD), \textit{Sistema de Informacion de Hospitales Publicos} (SIHO), \textit{Departamento Nacional de Planeacion} (DNP), \textit{Sistema de Vigilancia en Salud Publica} (SIVIGILA), CEDE municipality dataset, and ERA-Interim (ECMWF) weather and altitude data. ///
		Certified municipalities are those who are able to determine how they spend part of their education and/or certain health care resources according to previous performance assessments by Central Government. For those non-certified, such expenses are controlled directly by the departmental authorities. This classification depends on population size and on some administrative quality indicators. The NBI is a government multidimensional poverty index which considers quality of life and access to public goods. ///
	}} \\
	tex \end{tabular}
	tex \end{table}
	tex }
	texdoc close	
}

}

