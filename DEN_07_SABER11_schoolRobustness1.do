// Robustness-Checks at school level
// Authors: Kai Barron, Luis F. Gamboa, Paul Rodriguez
// Date: 2017.09

clear all
set scheme lean1
glo mainFolder="D:\Mis Documentos\git\DengueBehavioural"

do "$mainFolder/0.Programs.do"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
use "$mainFolder\mainData\dengueSchoolLevel.dta", clear


glo cont personasAfect_STD viviendaAfect_STD vias_STD hectareas_STD /// SNIGRD
		 camasHosp10000h consuUrge10000h /// // SIHO data
		 subsidp logingresospc deptransf  ESIp1000h logpop /// // DNP fiscal data
		 t2m8M tp8M // ERA-Interim (ECMWF)

glo controlsTit ="On top of the fixed effects by school and by year, these estimates include as controls: Inpatient beds and AE positions per 10.000h, Subsidized Health Care registry as a percentage of Population, municipality dependence on central government transfers, municipality income per capita, avg. temperature and rainfall for the last 8 months, log-population, std. of the number of people, houses and roads affected by natural disasters, and the incidence rate of influenza-like cases per 1.000h in the municipality during the calendar year. See Table \ref{descriptive_muni} for further details."
glo methodTit   ="Linear fixed effects panel regression at school level (see Equation \ref{eq:feSaberStu}). Main independent variable: Reported incidence of Dengue in the last 4 months (4M) at municipality level."
		 	
	
/////////////////////////////////////////////////////////////////////////////////
// Placebo: run our model into the data 2 years ago
/////////////////////////////////////////////////////////////////////////////////
if 1==1 {

	*glo thre="year<2012"
	glo thre="1==1"

	* Classic
	qui {
		xtreg L2.logest L0den   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r11
		xtreg L2.math   L0den   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r12
		xtreg L2.lang   L0den   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r13
	}
	esttab r11 r12 r13 , keep(L0den  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

	* Severe
	qui {
		xtreg L2.logest L0sev   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r1b1
		xtreg L2.math   L0sev   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r1b2
		xtreg L2.lang   L0sev   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r1b3
	}
	esttab r1b1 r1b2 r1b3 , keep(L0sev  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)
	

	* Classic Lags
	qui {
		xtreg L2.logest L0den L.L0den L2.L0den   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r31
		xtreg L2.math   L0den L.L0den L2.L0den   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r32
		xtreg L2.lang   L0den L.L0den L2.L0den   $cont i.year if $thre , cluster(codigomunicipio) fe
			estadd ysumm
			est store r33
	}
	esttab r31 r32 r33 , keep(L0den L.L0den L2.L0den ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

	* Severe Lags
	qui {
		xtreg L2.logest L0sev L.L0sev L2.L0sev   $cont i.year if $thre  , cluster(codigomunicipio) fe
			estadd ysumm
			est store r3b1
		xtreg L2.math   L0sev L.L0sev L2.L0sev   $cont i.year if $thre  , cluster(codigomunicipio) fe
			estadd ysumm
			est store r3b2
		xtreg L2.lang   L0sev L.L0sev L2.L0sev   $cont i.year if $thre  , cluster(codigomunicipio) fe
			estadd ysumm
			est store r3b3
	}
	esttab r3b1 r3b2 r3b3 , keep(L0sev L.L0sev L2.L0sev ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)


	cd  "$mainFolder/output/tablas"
	// Latex table: number of test takers *******************
		qui {
			texdoc init tableSchool_testTakersPlaceboL2 , replace
			tex {
			tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
			tex \begin{table}[H]
			tex \centering
			tex \scriptsize		
			tex \caption{Placebo: Number of test takers per school two years ago and Dengue Incidence \label{tableSchool_testTakersPlaceboL2}}
			tex \begin{tabular}{l*{5}{c}}			
			tex \toprule
			tex \multicolumn{5}{l}{ LOG(Number of students who presented the test two years ago) } \\
			tex \multicolumn{5}{l}{\parbox[l]{10cm}{Includes variation of incidence rates from 2009 to 2012, and on SABER 11 participation from 2007 to 2010}} \\
			tex \midrule
			
			esttab r1b1 r11 r3b1 r31  using tableSchool_testTakersPlaceboL2, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
				se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 ///
				stats(N N_g g_avg N_clust ymean r2_a,fmt(%6.0f %6.0f %4.2f %6.0f %6.2f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "$ \bar{Y}$" "Adj. R squared"))
											
			tex \bottomrule
			tex \multicolumn{5}{l}{\parbox[l]{10cm}{$methodTit $controlsTit}} \\
			tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\
			tex \end{tabular}
			tex \end{table}
			tex }
		}
		
	// Latex table: test scores *******************
		qui {
			texdoc init tableSchool_testScoresPlaceboL2 , replace
			tex {
			tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
			tex \begin{table}[H]
			tex \centering
			tex \scriptsize		
			tex \caption{Placebo:  Avg Test Scores per school two years ago and Dengue Incidence \label{tableSchool_testScoresPlaceboL2}}
			tex \begin{tabular}{l*{5}{c}}			
			tex \toprule
			tex \multicolumn{5}{l}{\parbox[l]{10cm}{Includes variation of incidence rates from 2009 to 2011, and on SABER 11 participation from 2007 to 2009}} \\
			tex \midrule			
			tex & Maths & Maths & Lang & Lang \\
			tex \midrule
			
			esttab r3b2 r32 r3b3 r33   using tableSchool_testScoresPlaceboL2, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
				se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 scalar(N_g N_clust)

			tex \bottomrule
			tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

			tex \end{tabular}
			tex \end{table}
			tex }
		}	
		
}
/////////////////////////////////////////////////////////////////////////////////
// Different Time Window
/////////////////////////////////////////////////////////////////////////////////
if 1==1 {

* 3 months figure is very important!!! 8 are not that much (as the 1 year number)		
* How can we test that is the 3 months and not the 8 months figures what matters?
* If we put both of them, only the 1 year one is relevant
xtreg logest stdhemo12Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
est store r1
xtreg logest stdhemo8Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
est store r2
xtreg logest stdhemo4Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
est store r3
	xtreg logest stdhemo3Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
	est store r3a
	xtreg logest stdhemo2Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
	est store r3b
	xtreg logest stdhemo1Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
	est store r3c
	
	* Same story if we take other rates
	esttab r1 r2 r3 r3a r3b r3c  , keep(stdhemo1Mp10000h stdhemo2Mp10000h stdhemo3Mp10000h stdhemo4Mp10000h stdhemo8Mp10000h stdhemo12Mp10000h)

xtreg logest hemo4Mp10000h hemo5t8Mp10000h hemo9t12Mp10000h $cont i.year if year>2007, cluster(codigomunicipio) fe
	test hemo4Mp10000h-hemo5t8Mp10000h=0
		local pval : disp %4.2f r(p)
		estadd scalar pval1 = `pval' 	
	test hemo4Mp10000h-hemo9t12Mp10000h=0
		local pval : disp %4.2f r(p)
		estadd scalar pval2 = `pval' 	
est store r4
xtreg logest hemo4Mp10000h hemo5t8Mp10000h hemo9t12Mp10000h $cont i.year if year>2007 & altitud<1800, cluster(codigomunicipio) fe
	test hemo4Mp10000h-hemo5t8Mp10000h=0
		local pval : disp %4.2f r(p)
		estadd scalar pval1 = `pval' 	
	test hemo4Mp10000h-hemo9t12Mp10000h=0
		local pval : disp %4.2f r(p)
		estadd scalar pval2 = `pval' 
est store r5



esttab r1 r2 r3 r4 r5  , keep(hemo4Mp10000h hemo5t8Mp10000h hemo9t12Mp10000h stdhemo4Mp10000h stdhemo8Mp10000h stdhemo12Mp10000h) ///
                        order(hemo4Mp10000h hemo5t8Mp10000h hemo9t12Mp10000h stdhemo4Mp10000h stdhemo8Mp10000h stdhemo12Mp10000h) star(* 0.10 ** 0.05 *** 0.01) ///
	se  margin  label nomtitles b(%9.3f) stats(N N_g g_avg r2_a  pval1 pval2, labels("N Obs" "N schools" "Avg. periods" "Adj. R2" "p-val for Wald test on H0: I04 - I58=0" "p-val for Wald test on H0: I04 - I912=0" ) fmt(%9.0f %9.0f %9.2f) )


* Other exercises ***
	* 4 months seems ok, using just last month is not as powerful as 2 to 4 months... let's keep 4 months
	* This is related to the timing of the outbreak
	xtreg logest stdhemo1Mp10000h $cont i.year if year>2007, cluster(cod_dane) fe	
	xtreg logest stdhemo2t4Mp10000h $cont i.year if year>2007, cluster(cod_dane) fe	
	xtreg logest stdhemo1Mp10000h stdhemo2t4Mp10000h $cont i.year if year>2007, cluster(cod_dane) fe	
		
	

cd  "$mainFolder/output/tablas"
// Latex table: number of test takers *******************
// Add manually the titles to the test of hyphotesis!! And add the "betas" to the var labels there
//  pval from t-test on H0: $\beta_1 - \beta_2 =0 $
//  pval from t-test on H0: $\beta_1 - \beta_3 =0 $
	qui {
		texdoc init robustness_difftimewind , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Number of test takers per school and Severe Dengue: different incidence periods \label{robustness_difftimewind}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & \multicolumn{4}{l}{ LOG(Number of students who presented the test) } \\
		tex \midrule
		tex & \multicolumn{4}{l}{All municipalities} \\ // & \multicolumn{1}{l}{$ <1800masl$ } \\
		tex \cmidrule(r){2-5} // \cmidrule(r){6-6}
		esttab r1 r2 r3 r4  using robustness_difftimewind, keep(hemo4Mp10000h hemo5t8Mp10000h hemo9t12Mp10000h stdhemo4Mp10000h stdhemo8Mp10000h stdhemo12Mp10000h) order(hemo4Mp10000h hemo5t8Mp10000h hemo9t12Mp10000h stdhemo4Mp10000h stdhemo8Mp10000h stdhemo12Mp10000h) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) stats(N N_g g_avg r2_a  pval1 pval2, labels("N Obs" "N schools" "Avg. periods" "Adj. R2" "p-val for Wald test on H0: I04 - I58=0" "p-val for Wald test on H0: I04 - I912=0" ) fmt(%9.0f %9.0f %9.2f) )

		tex \bottomrule
		tex \multicolumn{5}{l}{\parbox[l]{14cm}{ ///
		    Linear fixed effects panel regression at school level (see Equation \ref{eq:feSaberStu}). Main independent variable: Reported incidence of Dengue in the last 4 months (4M), 8 months (8M) and year (12M), or the stated period, at municipality level. /// 
			$controlsTit ///
			Wald tests of hyphotesis were performed in order to asses if the coefficients for incidence of the last 4 months and 5-8 months were the same (H0: I04 - I058 =0). A similar procedure was done for the incidence between 9 to 12 months (H: I04 - I912 =0). Results are presented in the last two rows of the table.}} \\
		tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
		texdoc close
	}

}
////////////////////////////////////////////////////////////////////////////////
// Only positive cases? Ok, it works
////////////////////////////////////////////////////////////////////////////////
if 1==1 {

*label var L0den  "C. Dengue 1000h"
*label var L0sev "S. Dengue 10000h"
*label var math "Avg. Math"
*label var lang "Avg. Lang"

* Classic
qui {
	xtreg logest L0den   $cont i.year if year>2007 & L0den>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r11
	xtreg math   L0den   $cont i.year if year>2007 & L0den>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r12
	xtreg lang   L0den   $cont i.year if year>2007 & L0den>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r13
}
esttab r11 r12 r13 , keep(L0den  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe
qui {
	xtreg logest L0sev   $cont i.year if year>2007 & L0sev>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r1b1
	xtreg math   L0sev   $cont i.year if year>2007 & L0sev>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r1b2
	xtreg lang   L0sev   $cont i.year if year>2007 & L0sev>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r1b3
}
esttab r1b1 r1b2 r1b3 , keep(L0sev  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)



* Classic Lags
qui {
	xtreg logest L0den L.L0den L2.L0den   $cont i.year if year>2007 & L0den>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r31
	xtreg math   L0den L.L0den L2.L0den   $cont i.year if year>2007 & L0den>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r32
	xtreg lang   L0den L.L0den L2.L0den   $cont i.year if year>2007 & L0den>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r33
}
esttab r31 r32 r33 , keep(L0den L.L0den L2.L0den ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe Lags
qui {
	xtreg logest L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 & L0sev>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r3b1
	xtreg math   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 & L0sev>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r3b2
	xtreg lang   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 & L0sev>0, cluster(codigomunicipio) fe
		estadd ysumm
		est store r3b3
}
esttab r3b1 r3b2 r3b3 , keep(L0sev L.L0sev L2.L0sev ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)



cd  "$mainFolder/output/tablas"
// Latex table: number of test takers *******************
	qui {
		texdoc init tableSchool_testTakersPos , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Number of test takers per school and Dengue Incidence \label{tableSchool_testTakersPos}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & \multicolumn{4}{l}{ LOG(Number of students who presented the test) } \\
		tex & \multicolumn{4}{l}{ Only for municipalities with at least 1 case of Dengue } \\
		tex \midrule
		
		esttab r1b1 r11 r3b1 r31  using tableSchool_testTakersPos, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 ///
				stats(N N_g g_avg N_clust r2_a,fmt(%6.0f %6.0f %4.2f %6.0f %6.4f ) label("Observations" "Schools" "Avg. periods per school" "Municipalities" "$ \bar{Y}$" "Adj. R squared"))

		tex \bottomrule
		tex \multicolumn{5}{l}{\parbox[l]{10cm}{$methodTit $controlsTit}} \\
		tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
	}
	
	
// Latex table: test scores *******************
	qui {
		texdoc init tableSchool_testScoresPos , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Avg Test Scores per school and Dengue Incidence \label{tableSchool_testScoresPos}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & \multicolumn{4}{l}{ Only for municipalities with at least 1 case of Dengue } \\			
		tex & Maths & Maths & Lang & Lang \\
		tex \midrule
		
		esttab r3b2 r32 r3b3 r33  using tableSchool_testScoresPos, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 scalar(N_g N_clust)

		tex \bottomrule
		tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\

		tex \end{tabular}
		tex \end{table}
		tex }
	}	
	

}



