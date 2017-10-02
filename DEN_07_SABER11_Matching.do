// Matching exercise
clear all
set matsize 10000
set scheme lean1
set niceness 0
set min_memory 1.5g


glo dropbox="C:/Dropbox"
*glo dropbox="C:\Users\PaulAndrés\Dropbox"

glo mainFolder="$dropbox/Dengue"

do "$mainFolder/do/0.Programs.do"

* Let's split schools in:

* 1. Get a dataset free of severe Dengue cases
* 2. For each municipality with Severe Dengue, get a synthetic control
* 3. Do all exercises with the transformed dataset

////////////////////////////////////////////////////////////////////////////////

glo cont personasAfect_STD viviendaAfect_STD vias_STD hectareas_STD /// 
		 camasHosp10000h consuUrge10000h ///
		 subsidp logingresospc deptransf  ESIp1000h logpop  ///
		 t2m8M tp8M 

glo controlmatch L0den ///
				 pob100 road_densi discap  altitud rainfall subsidpY2009 ingresospcY2009 deptransfY2009 ///
				 propmuY2007 propmuY2008 propmuY2009 ///
				              sisben12Y2009 sisben12Y2008 ///
				              IngresohogarY2009 IngresohogarY2008 ///
				 mathY2009  mathY2007 mathY2008 ///
				 langY2009  langY2007 langY2008 ///
				 NmathY2009  NmathY2007 NmathY2008 ///

use "$mainFolder\mainData\municipalityDengue.dta" if altitud<2000 , clear


rename *_mun *

label var propmu "\% of female test-takes"
label var sisben12 "\% of SISBEN 12 test-takers"
label var math "Avg. Maths Score"
label var lang "Avg. Language Score"
label var Nmath "Avg. N test takers"
label var Ingresohogar "Avg. Family Income Index"

*********************************************************************************
/////////////////////////////////////////////////////////////////////////////////
// Do the matching at municipality level
/////////////////////////////////////////////////////////////////////////////////

* Get trend values prior to 2010
foreach varDep in propmu sisben12 Ingresohogar math lang Nmath subsidp ingresospc deptransf {
	forval y=2007(1)2009 {
		qui{
			local labelo : variable label `varDep'
			gen `varDep'y`y'=`varDep'*(year==`y')
			bys codigomunicipio: egen `varDep'Y`y' = max(`varDep'y`y')
			drop `varDep'y`y'
			label var `varDep'Y`y' "`labelo': `y'"
		}
	}
}

***************
* Who had Severe cases in 2010? At any moment prior to 2010?
gen evSev= L0sev>0 if year<=2010
gen sev2010= L0sev*(year==2010) if year==2010
bys codigomunicipio: egen severeEver = max(evSev)   // Any case between 2007-2010
bys codigomunicipio: egen severe2010 = max(sev2010) // Exact rate at 2010

glo Cat =3
gen     catG=0 if severe2010==0
replace catG=1 if severe2010>0 & severe2010<=0.7
replace catG=2 if severe2010>0.7 & severe2010<=1.8
replace catG=$Cat if severe2010>1.8 & severe2010!=.
tab catG if year==2010


* Our "treatment" is to be affected by severe Dengue any year
qui tab codigomunicipio if evSev==1 & year==2010, matrow(treatedSchools)

forval sch=1(1)$Cat {
	psmatch2 evSev $controlmatch if year==2010 & (catG==0 | catG==`sch') , kernel out(math) common
	egen wei_`sch'=max(_weight) , by( codigomunicipio)
	rename _pscore pscore_`sch'
}

* Get wages using weighting from all groups
egen tW=rowtotal(wei_*)
replace tW=. if tW==0

*********************************************************************************
/////////////////////////////////////////////////////////////////////////////////
// BALANCE TABLE
/////////////////////////////////////////////////////////////////////////////////
cd "$mainFolder/output/tablas"
glo numC= 2*$Cat+2
glo cat2= 2*$Cat
qui {
	texdoc init MATCH_balance , replace
	tex {
	tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
	tex \begin{table}[H]
	tex \centering
	tex \scriptsize		
	tex \caption{Matching: Balance Table \label{MATCH_balance}}
	tex \begin{tabular}{l*{$numC}{c}}			
	tex \toprule
		* Group titles
		tex  & \multicolumn{$cat2}{c}{Municipality average} \\
		tex  & 	
		forval sch=1(1)$Cat {
			tex & \multicolumn{2}{c}{Group `sch'}		
		}
		tex \\	
			 		
		* Small titles
		tex Variable & C 	
		forval sch=1(1)$Cat {
			tex & T & MC		
		}
		tex \\
	
		* Lines
		tex \cmidrule(l){2-2}
		local i=3
		forval sch=1(1)$Cat {
			local i1=`i'+1
			tex \cmidrule(l){`i'-`i1'}		
			local i=`i1'+1
		}	
}

* Balance table
foreach v in $controlmatch {
	local labelo : variable label `v'

	qui sum `v' if catG==0 & year==2010
	scalar m0u = r(mean)
	scalar v0u = r(Var)
	local m0u : di %7.2f m0u

	glo linBa = "`labelo' & `m0u'"
	forval sch=1(1)$Cat {
	
		qui sum `v' if catG==`sch' & year==2010
		scalar m`sch'u = r(mean)
		scalar v`sch'u = r(Var)
		local m`sch'u : di %7.2f m`sch'u

		* Before matching *****************************************************		
		* standardised % bias before matching
		local bias`sch' = 100*(m`sch'u - m0u)/sqrt((v`sch'u + v0u)/2)
		local bias`sch' : di %7.2f `bias`sch''	
		
		* t-tests before matching
		qui regress `v' evSev if year==2010 & (catG==0 | catG==`sch'), cluster(codigomunicipio)
		local tbef = _b[evSev]/_se[evSev]
		local tbef : di %7.2f `tbef'
		local pbef = 2*ttail(e(df_r),abs(`tbef'))		
		
		local star`sch'u = ""
		if ((`pbef' < 0.1) )  local star`sch'u = "^{*}" 
		if ((`pbef' < 0.05) ) local star`sch'u = "^{**}" 
		if ((`pbef' < 0.01) ) local star`sch'u = "^{***}" 		
		
		* After matching *****************************************************
		qui sum `v' [aw=wei_`sch'] if catG==0 & year==2010
		scalar m`sch'm = r(mean)
		scalar v`sch'm = r(Var)
		local m`sch'm : di %7.2f m`sch'm

		* standardised % bias after matching
		local bias`sch'm = 100*(m`sch'u - m`sch'm)/sqrt((v`sch'u + v`sch'm)/2)
		local bias`sch'm : di %7.2f `bias`sch'm'			
		
		* t-tests after matching
		qui regress `v' evSev if year==2010 & (catG==0 | catG==`sch') [aw=wei_`sch'], cluster(codigomunicipio)
		local tbef = _b[evSev]/_se[evSev]
		local tbef : di %7.2f `tbef'
		local pbef = 2*ttail(e(df_r),abs(`tbef'))		
		
		local star`sch'm = ""
		if ((`pbef' < 0.1) )  local star`sch'm = "^{*}" 
		if ((`pbef' < 0.05) ) local star`sch'm = "^{**}" 
		if ((`pbef' < 0.01) ) local star`sch'm = "^{***}" 
		
		glo linBa = "$linBa & $ `m`sch'u'`star`sch'u' $ & $ `m`sch'm'`star`sch'm' $ "		
	}
				
	disp "$linBa \\"
	tex $linBa  \\
}

* Some stats
	* Lines
	local i=3
	tex \cmidrule(l){2-2}
	forval sch=1(1)$Cat {
		local i1=`i'+1
		tex \cmidrule(l){`i'-`i1'}		
		local i=`i1'+1
	}			
	
	* Incidence
	tex  S. Dengue Incidence & 	
	forval sch=1(1)$Cat {
		sum severe2010 if catG==`sch'
		local mini : disp %4.2f r(min)
		local maxi : disp %4.2f r(max)
		tex & \multicolumn{2}{c}{`mini' to `maxi'}		
	}
	tex \\		

	* Number of Munici
	sum severe2010 if catG==0 & year==2010
	local conto : disp %4.0f r(N)	
	tex  No. Municipalities & `conto' 	
	forval sch=1(1)$Cat {
		sum severe2010 if catG==`sch' & year==2010
		local conto : disp %4.0f r(N)
		tex & \multicolumn{2}{c}{`conto'}		
	}
	tex \\		
	
	* Number of Munici included
	sum severe2010 if catG==0 & year==2010 & tW!=. & tW>0
	local conto : disp %4.0f r(N)		
	tex  No. Municipalities Common S & `conto'	
	forval sch=1(1)$Cat {
		sum severe2010 if catG==`sch' & year==2010 & wei_`sch'!=.
		local conto : disp %4.0f r(N)
		tex & \multicolumn{2}{c}{`conto'}		
	}
	tex \\		
		
qui{
	tex \bottomrule
	tex \multicolumn{$numC}{l}{\parbox[l]{16cm}{Municipalities were matched using Kernel Propensity Score matching (bandwidth for the kernel: 0.06). ///
								T: municipalities with positive Severe Dengue incidence in 2010. C: municipalities with ///
								zero Severe Dengue incidence in 2010. MC: re-weighted average of group C. The stars show ///
								the significance of a t-test of difference of means: In column T the test is between groups T and C, ///
								and in column MC, between groups T and C but after matching. ///
							}} \\	
	tex \multicolumn{$numC}{l}{Significance: * 10\%, ** 5\%, *** 1\%.  } \\
	tex \end{tabular}
	tex \end{table}
	tex }
}

*tw (kdensity pscore_1 if catG==1) (kdensity pscore_1 if catG==0) (kdensity pscore_1 if catG==0 [aw=wei_1])
*tw (kdensity pscore_2 if catG==2) (kdensity pscore_2 if catG==0) (kdensity pscore_2 if catG==0 [aw=wei_2])
*tw (kdensity pscore_3 if catG==3) (kdensity pscore_3 if catG==0) (kdensity pscore_3 if catG==0 [aw=wei_3])
*tw (kdensity pscore_4 if catG==4) (kdensity pscore_4 if catG==0) (kdensity pscore_4 if catG==0 [aw=wei_4])

keep codigomunicipio year tW

tempfile matchSamp
save `matchSamp'


*********************************************************************************
/////////////////////////////////////////////////////////////////////////////////
// RUN THE EXERCISES
/////////////////////////////////////////////////////////////////////////////////

use "$mainFolder\mainData\dengueSchoolLevel.dta" if altitud<2000 , clear

merge n:1  codigomunicipio year using `matchSamp', keep(master match)

glo textMatch = "Schools are weighted so municipalities ared matched on fix and pre-outbreak characteristics"
		 
/////////////////////////////////////////////////////////////////////////////////
// Number of Test-takers (main results)
/////////////////////////////////////////////////////////////////////////////////
if 1==1 {
xtset cod_dane year

* Classic
qui {
	xtreg logest L0den   $cont i.year if year>2007    [aw=tW] , cluster(cod_dane) fe
		est store r11
	xtreg math   L0den   $cont i.year if year>2007    [aw=tW] , cluster(cod_dane) fe
		est store r12
	xtreg lang   L0den   $cont i.year if year>2007    [aw=tW] , cluster(cod_dane) fe
		est store r13
}
esttab r11 r12 r13 , keep(L0den  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe
qui {
	xtreg logest L0sev   $cont i.year if year>2007    [aw=tW] , cluster(cod_dane) fe
		est store r1b1
	xtreg math   L0sev   $cont i.year if year>2007    [aw=tW] , cluster(cod_dane) fe
		est store r1b2
	xtreg lang   L0sev   $cont i.year if year>2007    [aw=tW] , cluster(cod_dane) fe
		est store r1b3
}
esttab r1b1 r1b2 r1b3 , keep(L0sev  ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Classic Lags
qui {
	xtreg logest L0den L.L0den L2.L0den   $cont i.year if year>2007 [aw=tW], cluster(cod_dane) fe
		est store r31
	xtreg math   L0den L.L0den L2.L0den   $cont i.year if year>2007 [aw=tW], cluster(cod_dane) fe
		est store r32
	xtreg lang   L0den L.L0den L2.L0den   $cont i.year if year>2007 [aw=tW], cluster(cod_dane) fe
		est store r33
}
esttab r31 r32 r33 , keep(L0den L.L0den L2.L0den ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)

* Severe Lags
qui {
	xtreg logest L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 [aw=tW], cluster(cod_dane) fe
		est store r3b1
	xtreg math   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 [aw=tW], cluster(cod_dane) fe
		est store r3b2
	xtreg lang   L0sev L.L0sev L2.L0sev   $cont i.year if year>2007 [aw=tW], cluster(cod_dane) fe
		est store r3b3
}
esttab r3b1 r3b2 r3b3 , keep(L0sev L.L0sev L2.L0sev ) star(* 0.10 ** 0.05 *** 0.01) label scalars(N_g)


cd  "$mainFolder/output/tablas"
// Latex table: number of test takers *******************
	qui {
		texdoc init MATCH_tableSchool_testTakers , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Matching: Number of test takers per school and Dengue Incidence \label{MATCH_tableSchool_testTakers}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & \multicolumn{4}{l}{ LOG(Number of students who presented the test) } \\
		tex \midrule
		
		esttab r1b1 r11 r3b1 r31  using MATCH_tableSchool_testTakers, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 scalar(N_g)

		tex \bottomrule
		tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\
		tex \multicolumn{5}{l}{$textMatch } \\
		tex \end{tabular}
		tex \end{table}
		tex }
	}
	
// Latex table: test scores *******************
	qui {
		texdoc init MATCH_tableSchool_testScores , replace
		tex {
		tex \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}		
		tex \begin{table}[H]
		tex \centering
		tex \scriptsize		
		tex \caption{Matching: Avg Test Scores per school and Dengue Incidence \label{MATCH_tableSchool_testScores}}
		tex \begin{tabular}{l*{5}{c}}			
		tex \toprule
		tex & Maths & Maths & Lang & Lang \\
		tex \midrule
		
		esttab r3b2 r32 r3b3 r33  using MATCH_tableSchool_testScores, keep(L0den L.L0den L2.L0den L0sev L.L0sev L2.L0sev) order(L0sev L.L0sev L2.L0sev L0den L.L0den L2.L0den) star(* 0.10 ** 0.05 *** 0.01) ///
			se fragment  margin booktabs  label append nomtitles b(%9.3f) sfmt(%9.0f)  r2 ar2 scalar(N_g)

		tex \bottomrule
		tex \multicolumn{5}{l}{Clustered at school level SD in parenthesis. Significance: * 10\%, ** 5\%, *** 1\%. } \\
		tex \multicolumn{5}{l}{$textMatch } \\
		tex \end{tabular}
		tex \end{table}
		tex }
	}	
	

}
	

/////////////////////////////////////////////////////////////////////////////////
// Non-linear results
/////////////////////////////////////////////////////////////////////////////////
if 1==1 {
cap ssc install postrcspline
* http://maartenbuis.nl/presentations/bonn09.pdf

* Spline Severe Dengue ***************************************************************

gen seve1=L0sev>0 if L0sev!=.
cap drop spliCu*
mkspline2 spliCu = L0sev if seve1==1 , displayknots cubic nknots(3)
	mat Nodos = r(knots)
	glo nodo1 : disp %4.1f Nodos[1,1]
	glo nodo2 : disp %4.1f Nodos[1,2]
	glo nodo3 : disp %4.1f Nodos[1,3]
replace spliCu1=0 if seve1==0
replace spliCu2=0 if seve1==0

cap drop v1 v2 v3
xtreg logest seve1 spliCu* L0den $cont i.year if year>2007   [aw=tW]  , cluster(cod_dane) fe
mfxrcspline, title(Marginal effects) name(b, replace) level(90) link(identity) showknots  generate(v1 v2 v3)
tw  (rarea v2 v3 L0sev ) (line v1 L0sev , xline($nodo1 $nodo2 $nodo3) yline(0) ) if L0sev <5 ///
	, name(splineN, replace) title("1 additional case per 10.000h") ytitle(" {&part}{&beta}/{&part}D ") ///
	legend(off) caption("Marginal effects from a linear fixed effects panel estimator" "SE clustered at school level" "90% confidence intervals. Cubic spline knots (vertical lines) at: $nodo1 $nodo2 $nodo3" "Dengue incidence restricted to 5 cases per 10.000 h for easiness of exposition")
graph export "$mainFolder/output/images/MATCH_spline_testTakers.png", as(png) replace
	
cap drop v1 v2 v3
xtreg math seve1 spliCu* L0den $cont i.year if year>2007   [aw=tW]  , cluster(cod_dane) fe
mfxrcspline, title(Marginal effects) name(b, replace) level(90) link(identity) showknots  generate(v1 v2 v3)
tw  (rarea v2 v3 L0sev ) (line v1 L0sev , xline($nodo1 $nodo2 $nodo3) yline(0) ) if L0sev <5 ///
	, name(splineM, replace) title("Mathematics") ytitle(" {&part}{&beta}/{&part}D ") ///
	legend(off) 

cap drop v1 v2 v3
xtreg lang seve1 spliCu* L0den $cont i.year if year>2007   [aw=tW]  , cluster(cod_dane) fe
mfxrcspline, title(Marginal effects) name(b, replace) level(90) link(identity) showknots  generate(v1 v2 v3)
tw  (rarea v2 v3 L0sev ) (line v1 L0sev , xline($nodo1 $nodo2 $nodo3) yline(0) ) if L0sev <5 ///
	, name(splineL, replace) title("Language") ytitle(" {&part}{&beta}/{&part}D ") ///
	legend(off) 

	graph combine splineM splineL, title("1 additional case per 10.000h" ) caption("Marginal effects from a linear fixed effects panel estimator" "SE clustered at school level" "90% confidence intervals. Cubic spline knots (vertical lines) at: $nodo1 $nodo2 $nodo3" "Dengue incidence restricted to 5 cases per 10.000 h for easiness of exposition")
	graph export "$mainFolder/output/images/MATCH_spline_testScores.png", as(png) replace
		
}
	
