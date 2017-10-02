// Main Regressions at school level
// Authors: Kai Barron, Luis F. Gamboa, Paul Rodriguez
// Date: 2017.09

clear all
set scheme lean1
glo mainFolder="D:\Mis Documentos\git\DengueBehavioural"


do "$mainFolder/0.Programs.do"
cd "$mainFolder/output/tablas/"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
use "$mainFolder\mainData\dengueSchoolLevel.dta", clear

glo cont personasAfect_STD viviendaAfect_STD vias_STD hectareas_STD /// SNIGRD
		 camasHosp10000h consuUrge10000h /// // SIHO data
		 subsidp logingresospc deptransf  ESIp1000h logpop /// // DNP fiscal data
		 t2m8M tp8M // ERA-Interim (ECMWF)
		 
glo controlsTit ="On top of the fixed effects by school and by year, these controls for Inpatient beds and AE positions per 10.000h, Subsidized Health Care registry as a percentage of Population, municipality dependence on central government transfers, municipality per capita income, the incidence rate of influenza-like cases per 1.000h in the municipality during the calendar year, avg. temperature and rainfall for the last 8 months, log-population and the standardized number of people, houses and roads affected by natural disasters. See Table \ref{tab:descriptives} for further details."
glo methodTit   ="Linear fixed effects panel regression at school level (see Equation \ref{eq:feSaberStu}). S. Dengue is the reported incidence of Severe Dengue in the last 4 months (4M) at municipality level and C. Dengue is the incidence of Classic Dengue at the same level. L.S. Dengue and L.C. Dengue are the lag of Severe and Classic Dengue, respectively."
	
/////////////////////////////////////////////////////////////////////////////////
// Number of Test-takers and number of schools (main results)
/////////////////////////////////////////////////////////////////////////////////
if 1==0 {

qui {
	* Classic
	xtreg logest L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r11
	* Severe
	xtreg logest L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r1b1
	* Classic Lags
	xtreg logest L0den L.L0den L2.L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r31
	* Severe Lags
	xtreg logest L0sev L.L0sev L2.L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r3b1
	}
	
	preserve
	drop if Nmath==0 | Nmath==. // drop schools without students in that year
	collapse (count) nscho=cod_dane (mean) L0den L0sev $cont , by(codigomunicipio year)
	xtset codigomunicipio year
	qui { // 60% of the municipalities have at most 3 schools with SABER 11 test-takers!
		* Classic
		xtreg nscho L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
			est store r11sc
		* Severe
		xtreg nscho L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
			est store r1b1sc
		* Classic Lags
		xtreg nscho L0den L.L0den L2.L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
			est store r31sc
		* Severe Lags
		xtreg nscho L0sev L.L0sev L2.L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
			est store r3b1sc

	}
	
	restore

cd  "$mainFolder/output/tablas"
// Latex table: number of test takers *******************
	qui {
		texdoc init tableSchool_main , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Number of test takers per school and Dengue Incidence \label{tableSchool_main}}
		tex \begin{tabular}{l*{9}{c}}			
		tex \toprule
		tex & \multicolumn{4}{l}{ LOG(Number of students who presented the test) } & \multicolumn{4}{l}{\parbox[c]{5cm}{ LOG(Number of schools per municipality with at least 1 SABER 11 test taker) }} \\
		tex \cmidrule(l){2-5}  \cmidrule(l){6-9}
		
		esttab r1b1 r11 r3b1 r31  r1b1sc r11sc r3b1sc r31sc  using tableSchool_main, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  ///
			stats(N N_g N_clust r2_a,fmt(%6.0f %6.0f %6.0f %6.5f ) label("Observations" "Schools/Municipalities" "Municipalities" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{9}{l}{\parbox[l]{15cm}{$methodTit $controlsTit}} \\		
		tex \multicolumn{9}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
	}

		disp in red "Dependent variable: number of test takers"
		est replay r1b1 
		est replay r11 
		est replay r3b1 
		est replay r31

	

}

	
/////////////////////////////////////////////////////////////////////////////////
// Test Scores, and full-table for the online appendix
/////////////////////////////////////////////////////////////////////////////////
if 1==0 {

*label var L0den  "C. Dengue 1000h"
*label var L0sev "S. Dengue 10000h"
*label var math "Avg. Math"
*label var lang "Avg. Lang"

* Classic
qui {
	xtreg logest L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r11
	xtreg math   L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r12
	xtreg lang   L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r13
}
esttab r11 r12 r13 , keep(L0den  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe
qui {
	xtreg logest L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r1b1
	xtreg math   L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r1b2
	xtreg lang   L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r1b3
}
esttab r1b1 r1b2 r1b3 , keep(L0sev  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)


* Classic Lags
qui {
	xtreg logest L0den L.L0den L2.L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r31
	xtreg math   L0den L.L0den L2.L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r32
	xtreg lang   L0den L.L0den L2.L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r33
}
esttab r31 r32 r33 , keep(L0den L.L0den L2.L0den ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe Lags
qui {
	xtreg logest L0sev L.L0sev L2.L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		est store r3b1
	xtreg math   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r3b2
	xtreg lang   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		est store r3b3
}
esttab r3b1 r3b2 r3b3 , keep(L0sev L.L0sev L2.L0sev ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

cd  "$mainFolder/output/tablas"

	
	// Latex table: test scores *******************
	qui {
		texdoc init tableSchool_testScores , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Avg Test Scores per school and Dengue Incidence \label{tableSchool_testScores}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & Maths & Maths & Lang & Lang \\
		tex \midrule
		
		esttab r3b2 r32 r3b3 r33  using tableSchool_testScores, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 ///
			stats(N N_g g_avg N_clust r2_a,fmt(%6.0f %6.0f %4.2f %6.0f %6.2f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "$ \bar{Y}$" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{5}{l}{\parbox[l]{10cm}{$methodTit $controlsTit}} \\		
		tex \multicolumn{5}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
	}	
	

	
	// Latex table: full-table for the online appendix .........................
	qui {
		texdoc init tableSchool_large , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Main results full-table \label{tableSchool_large}}
		tex \begin{tabular}{l*{7}{c}}			
		tex \toprule
		tex & LogEST & LogEST & Maths & Maths & Lang & Lang \\
		tex \midrule
		
		esttab r1b1 r3b1 r3b2 r32 r3b3 r33  using tableSchool_large, order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 nogap ///
			stats(N N_g g_avg N_clust r2_a,fmt(%6.0f %6.0f %4.2f %6.0f %6.2f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "$ \bar{Y}$" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{7}{l}{\parbox[l]{18cm}{$methodTit $controlsTit}} \\		
		tex \multicolumn{7}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
	}	
	
	
		
	

}

/////////////////////////////////////////////////////////////////////////////////
// Non-linear results
/////////////////////////////////////////////////////////////////////////////////
if 1==0 {
eststo clear
* Test-takers ****************************************
cap drop at* lb ub b1 V1	
eststo: xtreg logest c.L0sev   c.L0sev#c.L0sev c.L0sev#c.L0sev#c.L0sev ///  //c.L0sev#c.L0sev#c.L0sev#c.L0sev ///
			  $cont i.year if year>2007 , cluster(codigomunicipio) fe
test c.L0sev#c.L0sev c.L0sev#c.L0sev#c.L0sev //c.L0sev#c.L0sev#c.L0sev#c.L0sev			 
	local Fval : disp %4.2f r(F)
	local pval : disp %4.2f r(p)				 
margins , dydx(L0sev) at(L0sev =(0(.1)5.1 )) post
marginsPlotPrepare // Generate variables for the plot
lincom (_b[1._at] - _b[52._at])
tw (rarea lb ub at21 ) (line b1 at21) , yline(0) title("4th order polynomial ") legend( off) name(polyN, replace) ///
	caption("Interaction terms are jointly significant at 5%" "level: F `Fval', p-val `pval'") ytitle(" {&part}{Y}/{&part}D ") ///
	xtitle("S. Dengue 10.000h (4 months)")
				
graph combine polyN, title("1 additional case per 10.000h") ycommon ///
	xsize(7) ysize(4) ///
	caption("SE clustered at municipality level for 90% confidence intervals. Incidence defined over the last 4 months before" "SABER 11 test. Incidence restricted to 5 cases per 10.000 h for easiness of exposition") 
graph export "$mainFolder/output/images/nonlin_testTakers.pdf", as(pdf) replace	


* Test scores *********************************************************	
	cap drop at* lb ub b1 V1
eststo: xtreg  math c.L0sev   c.L0sev#c.L0sev c.L0sev#c.L0sev#c.L0sev /// // c.L0sev#c.L0sev#c.L0sev#c.L0sev ///
				  $cont i.year if year>2007 , cluster(codigomunicipio) fe
	test c.L0sev#c.L0sev c.L0sev#c.L0sev#c.L0sev // c.L0sev#c.L0sev#c.L0sev#c.L0sev			 
		local Fval : disp %4.2f r(F)
		local pval : disp %4.2f r(p)				 
	margins , dydx(L0sev) at(L0sev =(0(.1)5.1 )) post
	marginsPlotPrepare // Generate variables for the plot
	lincom (_b[1._at] - _b[52._at])
	tw (rarea lb ub at21 ) (line b1 at21) , yline(0) title("(a) Mathematics test") legend( off) name(polyN_math, replace) ///
		caption("Interaction terms joint significance test:" "F `Fval', p-val `pval'") ytitle(" {&part}{Y}/{&part}D ") ///
		xtitle("S. Dengue 10.000h (4 months)")

	cap drop at* lb ub b1 V1
eststo: xtreg  lang c.L0sev   c.L0sev#c.L0sev c.L0sev#c.L0sev#c.L0sev /// // c.L0sev#c.L0sev#c.L0sev#c.L0sev ///
				  $cont i.year if year>2007 , cluster(codigomunicipio) fe
	test c.L0sev#c.L0sev c.L0sev#c.L0sev#c.L0sev // c.L0sev#c.L0sev#c.L0sev#c.L0sev			 
		local Fval : disp %4.2f r(F)
		local pval : disp %4.2f r(p)				 
	margins , dydx(L0sev) at(L0sev =(0(.1)5.1 )) post
	marginsPlotPrepare // Generate variables for the plot
	lincom (_b[1._at] - _b[52._at])
	tw (rarea lb ub at21 ) (line b1 at21) , yline(0) title("(b) Language test") legend( off) name(polyN_lang, replace) ///
		caption("Interaction terms joint significance test:" "F `Fval', p-val `pval'") ytitle(" {&part}{Y}/{&part}D ") ///
		xtitle("S. Dengue 10.000h (4 months)")
	
				
graph combine polyN_math polyN_lang, title("1 additional case per 10.000h") ycommon ///
	xsize(7) ysize(4) ///
	caption("Marginal effects from a specification with a 4th order polynomial on S Dengue incidence" "SE clustered at municipality level for 90% confidence intervals. Incidence defined over the last 4 months before" "SABER 11 test. Incidence restricted to 5 cases per 10.000 h for easiness of exposition") 
	graph export "$mainFolder/output/images/nonlin_testScores.pdf", as(pdf) replace

	
	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* Table for the online appendix
	qui {
		texdoc init tableSchool_nonlin , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Non-linear Impact at School Level of Dengue Incidence 4th order polynomial \label{tableSchool_nonlin}}
		tex \begin{tabular}{l*{4}{c}}			
		tex \toprule
		tex & LOG(EST) & MATH & LANG  \\
		tex \midrule
		
		esttab est1 est2 est3  using tableSchool_nonlin, star(* 0.10 ** 0.05 *** 0.01) ///
		se fragment  margin booktabs  label append nomtitles b(%9.5f) sfmt(%9.5f) nogap  ///
		stats(N N_g N_clust r2_a,fmt(%6.0f %6.0f %6.0f %6.5f ) label("Observations" "Schools/Municipalities" "Municipalities" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{4}{l}{\parbox[l]{17cm}{$methodTit $controlsTit}} \\		
		tex \multicolumn{4}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
		texdoc close
	}
	
}

/////////////////////////////////////////////////////////////////////////////////
// Prior intensity (cases vs. no cases in 2008, and non-linearilties)
/////////////////////////////////////////////////////////////////////////////////	
if 1==0 {	
		
	xtset cod_dane year
	* -----------------------------------------------------------------------------
	* By Incidence of Severe Dengue in the past

	gen _pastS=.
	replace _pastS=1 if L.hemop10000h==0 & L2.hemop10000h==0 & year==2009
	replace _pastS=2 if (L.hemop10000h>0 | L2.hemop10000h>0) & year==2009

	bys cod_dane: egen pastS=max(_pastS) if year>=2009 & year<=2012
	drop _pastS
	
	gen L0sevpastS1=L0sev*(pastS==1)
	gen L0sevpastS2=L0sev*(pastS==2)
	
	label var L0sevpastS1 "S. Dengue x No Cases 2007, 2008"
	label var L0sevpastS2 "S. Dengue x At least 1 Case 2007, 2008"
	
	gen zero= pastS==1
	label var zero "No Cases 2007, 2008"
	
	
	qui {
		xtreg logest L0sevpastS1 L0sevpastS2  $cont i.year , cluster(codigomunicipio) fe	
		sum L1sev if e(sample)==1 & year==2009
		estadd scalar avgIn=r(mean)
		qui tab codigomunicipio if e(sample)==1 & year==2010
		estadd scalar nMun=r(r)
		test  L0sevpastS1-L0sevpastS2=0
		estadd scalar sameImp=r(p)
		est store r`i'
		
		xtreg math L0sevpastS1 L0sevpastS2    $cont i.year , cluster(codigomunicipio) fe
		sum L1sev if e(sample)==1 & year==2009
		estadd scalar avgIn=r(mean)
		qui tab codigomunicipio if e(sample)==1 & year==2010
		estadd scalar nMun=r(r)	
		test  L0sevpastS1-L0sevpastS2=0
		estadd scalar sameImp=r(p)		
		est store rM`i'
		
		xtreg lang L0sevpastS1 L0sevpastS2   $cont i.year , cluster(codigomunicipio) fe
		sum L1sev if e(sample)==1 & year==2009
		estadd scalar avgIn=r(mean)
		qui tab codigomunicipio if e(sample)==1 & year==2010
		estadd scalar nMun=r(r)	
		test  L0sevpastS1-L0sevpastS2=0
		estadd scalar sameImp=r(p)		
		est store rL`i'
	}	

	* No Dengue before is not significant if no top restriction is considered
	esttab r  rM rL  , keep(L0sevpastS1 L0sevpastS2) star(* 0.10 ** 0.05 *** 0.01) label stats(N N_g nMun g_avg sameImp, label("Obs" "N Schools" "N Municip." "Avg. periods" "H0: impact is the same"))
	
	
cd  "$mainFolder/output/tablas"	
// Latex table: test scores *******************
	qui {
		texdoc init tableSchool_PriorIntensity , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{S. Dengue Impact by Prior Intensity \label{tableSchool_PriorIntensity}}
		tex \begin{tabular}{l*{4}{c}}			
		tex \toprule
		tex & LOG(Takers) & Maths & Lang  \\
		tex \midrule
		
		esttab r  rM rL  using tableSchool_PriorIntensity, keep(L0sevpastS1 L0sevpastS2) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 ///
			stats(N N_g g_avg N_clust r2_a sameImp ,fmt(%6.0f %6.0f %4.2f %6.0f %6.2f %6.4f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "Adj. R squared" "H0: impact is the same"))

		tex \bottomrule
		tex \multicolumn{4}{l}{\parbox[l]{10cm}{$methodTit $controlsTit}} \\
		tex \multicolumn{4}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
	}		
	
* Non linearlities ************************************************************
xtset cod_dane year

gen sev09=	hemop10000h*(year==2008)
bys cod_dane: egen Sev09=max(sev09)
drop sev09
	
xtset cod_dane year	
* -----------------------------------------------------------------------------
* Using polynomials		
xtreg logest c.L0sev c.L0sev#i.zero c.L0sev#c.Sev09 ///
			  $cont i.year if year>2008 , cluster(codigomunicipio) fe
test c.L0sev#c.Sev09
	local Fval : disp %4.2f r(F)
	local pval : disp %4.2f r(p)	
margins , dydx(L0sev) at(Sev09 =(0(0.5)5 )) post
		marginsPlotPrepare Sev09 // Generate variables for the plot
		tw (rarea lb ub at21 ) (line b1 at21) ///
			, yline(0) legend( off) name(polyN, replace) ///
			ytitle(" {&part}Y/{&part}D ")	xtitle("S. Dengue Incidence (1 x 10.000h) in 2008 (Calendar Year)")

	graph combine polyN, title("1 additional case per 10.000h") ycommon ///
	xsize(7) ysize(4) ///
	caption("Linear interaction term between outbreak (2010) and pre-outbreak (2008) incidence was not different" ///
			"from 0 (p-val: `pval'). SE clustered at municipality level for 90% confidence intervals. Incidence " ///
	        "of the vertical axis is defined over the last 4 months before SABER 11 test. Incidence restricted " ///
			"to 5 cases per 10.000 h for easiness of exposition") 
	
graph export "$mainFolder/output/images/margins_Sev09.pdf", as(pdf) replace		

	
}		 



/////////////////////////////////////////////////////////////////////////////////
// Heterogenous effects
/////////////////////////////////////////////////////////////////////////////////
if 1==0 {

qui sum Ingresohogar, d
gen depRelInc=(Ingresohogar-Ingresohogar_mun)/r(sd)
label var depRelInc "Std Relative Wealth-Index"

clonevar z1=camasHosp10000h
clonevar z2=consuUrge10000h
clonevar z3=depRelInc //Ingresohogar
clonevar z4=sisben12



eststo clear
foreach varDep in logest math lang {
	eststo: xtreg `varDep' c.L0sev ///
		/// // Health System Characteristics
				 c.L0sev#c.z1 c.L0sev#c.z1#c.z1  ///
				 c.z1 c.z1#c.z1  ///
		/// // Income		
				 c.L0sev#c.z3 c.L0sev#c.z3#c.z3  ///
				 c.z3 c.z3#c.z3  ///	
				 c.L0sev#c.logpop c.L0sev#c.logpop#c.logpop  ///
				 c.logpop c.logpop#c.logpop ///
				 personasAfect_STD viviendaAfect_STD vias_STD hectareas_STD subsidp logingresospc deptransf  ESIp1000h ///							   
				  i.year , cluster(codigomunicipio) fe
				  
	test c.L0sev#c.z1 c.L0sev#c.z1#c.z1 
		local Fvalz1 : disp %4.2f r(F)
		local pvalz1 : disp %4.2f r(p)
	test c.L0sev#c.z3 c.L0sev#c.z3#c.z3
		local Fvalz3 : disp %4.2f r(F)
		local pvalz3 : disp %4.2f r(p)			  
	test c.L0sev#c.logpop c.L0sev#c.logpop#c.logpop 		 
		local Fvallogpop : disp %4.2f r(F)
		local pvallogpop : disp %4.2f r(p)				
		
	margins , dydx(L0sev) at(z1 =(1(1)15 ))
	marginsplot, yline(0) name(a1, replace) recastci(rarea) ciopts( fcolor(gs13) ) xtitle("") title("Inpatient beds per 10.000h") caption("Joint significance of the interaction terms:" "F `Fvalz1', p-val `pvalz1'")
		
	*margins , dydx(L0sev) at(z3 =(0(0.25)3 ))
	margins , dydx(L0sev) at(z3 =(-0.75(0.25)1.62 ))
	marginsplot, name(a3, replace) yline(0) recastci(rarea) ciopts( fcolor(gs13) ) xtitle("") title("Std Relative HH-to-Municipality School Avg Income") caption("Joint significance of the interaction terms:" "F `Fvalz3', p-val `pvalz3'")

	margins , dydx(L0sev) at(logpop =( 9.3(.5)12.9 )) 
	marginsplot, name(a5, replace) yline(0) recastci(rarea) ciopts( fcolor(gs13) ) xtitle("") title("Log municipality population") caption("Joint significance of the interaction terms:" "F `Fvallogpop', p-val `pvallogpop'")

	graph combine a1 a3 a5, title("Avg Marginal Effects of S. Dengue incidence with 95% CIs", size(2)) caption("Domain of Z: 5%-95%. Polynomial of order 3 on Z." "Std Relative HH-to-Municipality School Avg Income refers to the standard deviations of the average HH" "income index of a school from the value of the municipality ", size(2)) ycommon ///
		xsize(10) ysize(12) iscale(0.5)
	graph export "$mainFolder/output/images/margins_`varDep'.pdf", as(pdf) replace
}		
	
	
	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* Table for the online appendix
	qui {
		texdoc init tableSchool_hetero , replace force
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Heterogeneous Impact at School Level of Dengue Incidence 2nd order polynomial \label{tableSchool_hetero}}
		tex \begin{tabular}{l*{4}{c}}			
		tex \toprule
		tex & LOG(EST) & MATH & LANG  \\
		tex \midrule
		
		esttab est1 est2 est3  using tableSchool_hetero, star(* 0.10 ** 0.05 *** 0.01) ///
		se fragment  margin booktabs  label append nomtitles b(%9.5f) sfmt(%9.5f) nogap  ///
		stats(N N_g N_clust r2_a,fmt(%6.0f %6.0f %6.0f %6.5f ) label("Observations" "Schools/Municipalities" "Municipalities" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{4}{l}{\parbox[l]{17cm}{$methodTit $controlsTit}} \\		
		tex \multicolumn{4}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
		texdoc close
	}	
	
}

/////////////////////////////////////////////////////////////////////////////////
// Impact by Years  (online appendix)
/////////////////////////////////////////////////////////////////////////////////
if 1==1 {
	gen DL0sev=L0sev-L.L0sev

* -----------------------------------------------------------------------------
* Only on severe Dengue, restricting the sample to certain years
qui {

	xtreg logest L0sev $cont i.year  , cluster(codigomunicipio) fe
		sum DL0sev if e(sample)==1
		estadd scalar meanInc=r(mean)
		est store rAll

	forval y=2008(1)2011 {
		local y1=`y'+1
		xtreg logest L0sev $cont i.year  if (year==`y' | year==`y1') , cluster(codigomunicipio) fe
			sum DL0sev if e(sample)==1 & year==`y1'
			estadd scalar meanInc=r(mean)
			est store rjj`y'		
	}
}	

* How to avoid the "2011" effect? Basically by not including the effect after it.
xtreg logest L0sev $cont i.year if year<=2010 , cluster(codigomunicipio) fe
sum DL0sev if e(sample)==1 & ( year==2009 | year==2010)
estadd scalar meanInc=r(mean)
est store rUp2010		

esttab rAll rjj2008 rjj2009 rjj2010 rjj2011 rUp2010 , keep(L0sev) star(* 0.10 ** 0.05 *** 0.01) label stats(N N_g g_avg N_clust meanInc, label("Observations" "Schools" "Avg. periods per school" "Municipalities" "E[D_t - D_{t-1}]")) ///
	mtitle(rAll 2008-09 2009-10 2010-11 2011-12 2008-10)

	
cd  "$mainFolder/output/tablas"
// Latex table: number of test takers (severe) *******************
	qui {
		texdoc init tableSchool_byYears , replace force
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \footnotesize
		tex \centering
		tex \caption{Number of test takers per school and Dengue Incidence by Years \label{tableSchool_byYears}}
		tex \begin{tabular}{l*{7}{c}}
		tex \toprule
		tex & All & 2008/09 & 2009/10 & 2010/11 & 2011/12 & 2008/10 \\
		tex \midrule
				
		esttab rAll rjj2008 rjj2009 rjj2010 rjj2011 rUp2010 using tableSchool_byYears, keep(L0sev) star(* 0.10 ** 0.05 *** 0.01) label stats(N N_g g_avg N_clust meanInc, label("Observations" "Schools" "Avg. periods per school" "Municipalities" "E[D_t - D_{t-1}]")) ///
			se fragment  margin booktabs  append nomtitles
			
		tex \bottomrule
		tex \addlinespace
		tex \multicolumn{7}{l}{\parbox[l]{15cm}{$methodTit $controlsTit}} \\	
		tex \multicolumn{7}{l}{\parbox[l]{15cm}{Column 1 reproduces the main specification, columns 2 to 6 restrict the sample to the years specified in the title.}} \\
		tex \multicolumn{7}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\
		
		tex \end{tabular}
		tex \end{table}
		tex }
		texdoc close
	}	
	
		
	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* Exercise with year specific effects... not used, it is not based on
	* year-to-year variations
	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if 1==0 {

		foreach varDep in L0den L0sev { 
			foreach yearo in 2008 2009 2010 2011 2012 2013 {
				gen `varDep'`yearo'=`varDep'*(year==`yearo')
			}
		}

		* Severe
		qui {
			xtreg logest L0sev2009 L0sev2010 L0sev2011 L0sev2012  $cont i.year , cluster(codigomunicipio) fe
				est store r1b1
			xtreg math   L0sev2009 L0sev2010 L0sev2011 L0sev2012  $cont i.year , cluster(codigomunicipio) fe
				est store r1b2
			xtreg lang   L0sev2009 L0sev2010 L0sev2011 L0sev2012  $cont i.year , cluster(codigomunicipio) fe
				est store r1b3
		}
		esttab r1b1 r1b2 r1b3 , keep(L0sev2009 L0sev2010 L0sev2011 L0sev2012  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

	}
	
	

}


/////////////////////////////////////////////////////////////////////////////////
// Other characteristics (online appendix)
/////////////////////////////////////////////////////////////////////////////////
if 1==0 {

label var Ingresohogar "Avg HH Income Index"

* Classic
qui {
	xtreg propmu L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		estadd ysumm
		est store r11
	xtreg sisben12   L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r12
	xtreg Ingresohogar   L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r13
}
esttab r11 r12 r13 , keep(L0den  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe
qui {
	xtreg propmu L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r1b1
	xtreg sisben12   L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r1b2
	xtreg Ingresohogar   L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r1b3
}
esttab r1b1 r1b2 r1b3 , keep(L0sev  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)


* Classic Lags
qui {
	xtreg propmu L0den L.L0den L2.L0den   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r31
	xtreg sisben12   L0den L.L0den L2.L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm	
		est store r32
	xtreg Ingresohogar   L0den L.L0den L2.L0den   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm
		est store r33
}
esttab r31 r32 r33 , keep(L0den L.L0den L2.L0den ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe Lags
qui {
	xtreg propmu L0sev L.L0sev L2.L0sev   $cont i.year if year>2007     , cluster(codigomunicipio) fe
		estadd ysumm
		est store r3b1
	xtreg sisben12   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm
		est store r3b2
	xtreg Ingresohogar   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 , cluster(codigomunicipio) fe
		estadd ysumm
		est store r3b3
}
esttab r3b1 r3b2 r3b3 , keep(L0sev L.L0sev L2.L0sev ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)



cd  "$mainFolder/output/tablas"

// Latex table: other outcomes *******************
	qui {
		texdoc init tableSchool_othersSev , replace force
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{School Characteristics and Dengue Incidence \label{tableSchool_othersSev}}
		tex \begin{tabular}{l*{4}{c}}			
		tex \toprule
		tex & Female & SISBEN12 & INCOME \\
		tex \midrule
		tex \multicolumn{4}{l}{\textbf{Panel A: Severe Dengue} } \\					
		esttab r1b1 r1b2 r1b3  using tableSchool_othersSev, keep(L0sev) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 ///
			stats(N N_g g_avg N_clust ymean r2_a,fmt(%6.0f %6.0f %4.2f %6.0f %6.2f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "$ \bar{Y}$" "Adj. R squared"))

		tex \midrule
		tex \multicolumn{4}{l}{\textbf{Panel B: Classic Dengue} } \\			
			
		esttab r11 r12 r13  using tableSchool_othersSev, keep(L0den ) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 ///
			stats(N N_g g_avg N_clust ymean r2_a,fmt(%6.0f %6.0f %4.2f %6.0f %6.2f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "$ \bar{Y}$" "Adj. R squared"))
			
			
		tex \bottomrule
		tex \multicolumn{4}{l}{\parbox[l]{8cm}{$methodTit $controlsTit}} \\
		tex \multicolumn{4}{l}{Clustered at municipality level SD in parenthesis.} \\
		tex \multicolumn{4}{l}{Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
		texdoc close
	}	
	

}

/////////////////////////////////////////////////////////////////////////////////
// Municipality level (online appendix)
/////////////////////////////////////////////////////////////////////////////////
if 1==0 {

	preserve
	drop if Nmath==0 | Nmath==. // drop schools without students in that year
	collapse (count) nscho=cod_dane (sum) Nmath  (mean) math lang , by($cont L0den L0sev codigomunicipio year)
	xtset codigomunicipio year
	gen logest=ln(Nmath)
	
	qui {
		* Classic
		xtreg logest L0den   $cont i.year , cluster(codigomunicipio) fe
			est store r11
		* Severe
		xtreg logest L0sev   $cont i.year , cluster(codigomunicipio) fe
			est store r1b1
		* Math: Severe
		xtreg math L0sev   $cont i.year , cluster(codigomunicipio) fe
			est store rmath
		* Lang: Severe
		xtreg lang L0sev   $cont i.year , cluster(codigomunicipio) fe
			est store rlang

	}
	
	restore

	
	cd  "$mainFolder/output/tablas"
	// Latex table: number of test takers *******************
	qui {
		texdoc init tableMuni_main , replace force
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Number of test takers and average test scores per municipality and Dengue Incidence \label{tableMuni_main}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & \multicolumn{2}{l}{ LOG(Number of students who presented the test) } & MATH & LANG \\
		tex \cmidrule(l){2-3}  \cmidrule(l){4-5}
		
		esttab r11 r1b1 rmath rlang  using tableMuni_main, keep(L0den L0sev) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  ///
			stats(N N_g N_clust r2_a,fmt(%6.0f %6.0f %6.0f %6.5f ) label("Observations" "Municipalities" "Municipalities" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{5}{l}{\parbox[l]{15cm}{$methodTit $controlsTit}} \\		
		tex \multicolumn{5}{l}{Clustered at municipality level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
		texdoc close
	}

}
/////////////////////////////////////////////////////////////////////////////////
