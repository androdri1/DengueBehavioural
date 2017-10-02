     //////////////////////////////////////////////////////////////////////////////////
    // This file compile into a single file all the data which is at municipality 	//
   // level: municipalityDengue.dta												   //
  // Authors: Kai Barron, Luis F. Gamboa, Paul Rodriguez-Lesmes					  //
 // Date: July, 2015															 //
//////////////////////////////////////////////////////////////////////////////////

clear all

glo mainFolder="C:\Dropbox\Dengue"
glo mainFolder="C:\Users\PaulAndrés\Dropbox\Dengue"
glo mainFolder="C:\Users\PaulAndrés\Dropbox\Salud Colombia\Dengue"

do "$mainFolder/do/0.Programs.do"

glo genOpts="  graphregion(color(white) lwidth(medium)) "
//////////////////////////////////////////////////////////////////////////////////////////////
// Prepare municipality year data

use "$mainFolder\Municipality_Data\controles_municipios.dta", clear
keep if year==2009
keep agua aptitud   discap dismer roads roadsm road_densi rainfall M_code //altitud clima  (incomplete data)
tempfile temporal
save `temporal'

******************
use "$mainFolder\HealthSystem\infrastructure.dta", clear

collapse (sum) cantidad (max) nivel, by( departamento municipio ao concepto)
rename ao year
encode concepto, gen(concept)
drop concepto
numlabel, add
tab concept

reshape wide cantidad  , i(departamento municipio year) j(concept)

rename cantidad1 camasHosp
rename cantidad2 camasObse
rename cantidad3 consuOutp
rename cantidad4 consuUrge
rename cantidad5 mesasPart
rename cantidad6 odontUnit
rename cantidad7 surgeUnit

tempfile healthSys
save `healthSys'

******************
cd "$mainFolder\INS_Data"
use "DegueCompiled", clear

merge n:1 codigomunicipio year using DegueCompiledAugust, gen(mergeAug)
merge n:1 codigomunicipio year using DegueHemoCompiled, gen(mergeHemo)
merge n:1 codigomunicipio year using DegueHemoCompiledAugust, gen(mergeHemoAug)
merge n:1 codigomunicipio year using ESICompiled, gen(mergeESI)

merge n:1 codigomunicipio using "$mainFolder/Municipality_Data/poblacionTotalDane2005.dta", gen(mergePop05) keepusing(municipio reaoficialkm2 rango)

merge n:1 codigomunicipio year using "$mainFolder/Municipality_Data/poblacionTotalDaneProyecciones.dta", gen(mergePop)
destring poblacintotal, replace

gen logpop=log(poblacintotal)
label var logpop "Log-population"

rename codigomunicipio M_code
merge n:1 M_code using `temporal' , gen(mergeContMun)
rename M_code codigomunicipio


merge m:1  codigomunicipio using "$mainFolder/WeatherData/colw_uniqueMun.dta", gen(mergeWeatherLR)
merge 1:1  codigomunicipio year using "$mainFolder/WeatherData/colw_weatherYearlyAug.dta", gen(mergeWeatherAug)
replace altitud=0 if altitud==-9999


merge m:1  codigodepartamento using "$mainFolder/Ola Invernal/wikipediaDepartamental.dta", gen(mergeOLAINV)
replace afect=0 if afect==.

merge m:1  codigomunicipio year using "$mainFolder/Ola Invernal/emergenciasYear.dta", gen(mergeEMERGEN)

merge 1:1  codigomunicipio year using "$mainFolder/Municipality_Data/mortalidad/mortalidad_infantil.dta", gen(mergeMORTINF)

merge n:1  departamento municipio year using `healthSys', gen(mergeHEALTHSER) keep(match master)

merge 1:1  codigomunicipio year using "$mainFolder/Municipality_Data\datos salud municipal.dta", gen(mergeHEALTHfinan) keep(match master)
merge 1:1  codigomunicipio year using "$mainFolder/Municipality_Data\fiscal_and_spending.dta", gen(mergeFinan) keep(match master)
merge n:1  codigomunicipio  using "$mainFolder/Municipality_Data\certificacionSalud.dta", gen(mergeCertif) keep(match master) force
merge n:1  codigomunicipio  using "$mainFolder/Municipality_Data\nbi2010.dta", gen(mergeNBI) keep(match master) force
merge n:1  codigomunicipio  using "$mainFolder/Municipality_Data\coberturaTotalAcueducto2011.dta", gen(mergeAcu) keep(match master) force
merge n:1  codigomunicipio  using "$mainFolder/Municipality_Data\coberturaTotalAlcantarillado2011.dta", gen(mergeAlcan) keep(match master) force


label var NBI "Poverty Index based on quality of life (NBI)"

gen ingresospc=ingresostotales/poblacintotal
label var ingresospc "Total Municipality Income per capita"
gen logingresospc=log(ingresospc)


gen subsidp= afiliadosregimensubsidiados /poblacintotal
label var subsidp "Subsidized Health Care / Population"
 
label var dependenciadelastransferencias "Municipality dependence on central Gov. transfers"
rename dependenciadelastransferencias deptransf

merge 1:1  codigomunicipio year using "$mainFolder/Icfes_data\dengueColMun.dta", gen(mergeSABER11mun) keep(match master)

merge 1:1  codigomunicipio year using "$mainFolder/Matriculas\matriculaPrimaria.dta", gen(mergeMatriculaPri) keep(match master)
merge 1:1  codigomunicipio year using "$mainFolder/Matriculas\matriculaSecundaria.dta", gen(mergeMatriculaSec) keep(match master)
xtset codigomunicipio year
foreach varDep in  personasAfect viviendaAfect vias hectareas {
	replace `varDep'=0 if `varDep'==.
}

drop if year<2007 | year==2014
drop if codigomunicipio==.
drop if codigodepartamento==.
/////////////////////////////////////////////////////////////////////////////////
// Construct variables

foreach varDep in camasHosp camasObse consuOutp consuUrge mesasPart odontUnit surgeUnit {
	gen  `varDep'10000h=`varDep'/(poblacintotal/10000)
}

label var camasHosp10000h "Inpatient Beds per 10.000h"
label var consuUrge10000h "A\&E positions per 10.000h" 

* Calendar year rates *********************************************************
replace clasico=0 if clasico==.
gen clasp1000h= clasico/ (poblacintotal/1000)
label var clasp1000h "Classic Dengue per 1000h, Cal Y"

replace hemo=0 if hemo==.
gen hemop10000h= hemo/ (poblacintotal/10000)
label var hemop10000h "Hemorrhagic Dengue per 10.000h, Cal Y"

replace ESI=0 if ESI==. & year>2007
gen ESIp1000h= ESI/ (poblacintotal/1000)
label var ESIp1000h "Influeza-like per 1000h, Cal Y"

* August year rates, with different time windows *******************************
foreach t in 1 2 3 4 8 12 {
	replace clasico`t'M=0 if clasico`t'M==.
	gen clas`t'Mp1000h= clasico`t'M/ (poblacintotal/1000)
	label var clas`t'Mp1000h "Classic Dengue per 1.000h, `t'M  August"
	
	gen stdclas`t'Mp1000h = clas`t'Mp1000h/`t'
	label var stdclas`t'Mp1000h "Avg. Monthly Incidence C. Dengue, `t'M  August"	
	
	replace hemo`t'M=0 if hemo`t'M==.
	gen hemo`t'Mp10000h= hemo`t'M/ (poblacintotal/10000)
	label var hemo`t'Mp10000h "Severe Dengue per 10.000h, `t'M  August"	
	
	gen stdhemo`t'Mp10000h = hemo`t'Mp10000h/`t'
	label var stdhemo`t'Mp10000h "Avg. Monthly Incidence S. Dengue, `t'M  August"		
}	

* For the robustness checks		
replace hemo2t4M=0 if hemo2t4M==.
gen hemo2t4Mp10000h= hemo2t4M/ (poblacintotal/10000)
label var hemo2t4Mp10000h "Severe Dengue per 10.000h, 5-8 months from August"	
gen stdhemo2t4Mp10000h = hemo2t4Mp10000h/3
label var stdhemo2t4Mp10000h "Avg. Monthly Incidence S. Dengue, 5-8 months from August"	

replace hemo5t8M=0 if hemo5t8M==.
gen hemo5t8Mp10000h= hemo5t8M/ (poblacintotal/10000)
label var hemo5t8Mp10000h "Severe Dengue per 10.000h, 5-8 months from August"	

replace hemo9t12M=0 if hemo9t12M==.
gen hemo9t12Mp10000h= hemo9t12M/ (poblacintotal/10000)
label var hemo9t12Mp10000h "Severe Dengue per 10.000h, 9-12 months from August"	


xtset codigomunicipio year

* ******************************************************************************
* These are the main rates to be used in the regressions. Robustness checks
* section will present results with alternative windows

gen L0den=clas4Mp1000h
gen L1den=L1.clas4Mp1000h
gen L2den=L2.clas4Mp1000h

label var L0den "C. Dengue 1000h (4M)"
label var L1den "C. Dengue 1000h (4M), 1 year ago"
label var L2den "C. Dengue 1000h (4M), 2 years ago"

gen L0sev=hemo4Mp10000h
gen L1sev=L1.hemo4Mp10000h
gen L2sev=L2.hemo4Mp10000h

label var L0sev "S. Dengue 10000h (4M)"
label var L1sev "S. Dengue 10000h (4M), 1 year ago"
label var L2sev "S. Dengue 10000h (4M), 2 years ago"

gen esi0=ESIp1000h
gen esi1=L1.ESIp1000h
gen esi2=L2.ESIp1000h

label var esi0 "Influenza-alike cases x1000h, same year"
label var esi1 "Influenza-alike cases x1000h, last year"
label var esi2 "Influenza-alike cases x1000h, 2 years ago"
		
tab year , gen( dyear_)

foreach vari in personasAfect viviendaAfect vias hectareas  {
	qui sum `vari' , d
	local mean=r(mean)
	local sd=r(sd)
	gen `vari'_STD= (`vari'-`mean')/`sd'
}

label var personasAfect_STD "Std. people affected by emergencies produced by natural events"
label var viviendaAfect_STD "Std. dwellings affected by emergencies produced by natural events"
label var vias_STD "Std. roads affected by emergencies produced by natural events"
label var hectareas_STD "Std. hects of farm land affected by emergencies produced by natural events"


* Lags of some of the variables ************************************************

gen Lmath_mun=L.math_mun
gen Llang_mun=L.lang_mun
gen Lsisben12_mun=L.sisben12_mun
gen LIngresohogar_mun=L.Ingresohogar_mun

label var Lmath_mun          "Year before SABER11 Mun. Avg. Math Score"
label var Llang_mun          "Year before SABER11 Mun. Avg. Lang Score"
label var Lsisben12_mun      "Year before SABER11 Mun. Avg. SISBEN 1-2 test-takers"
label var LIngresohogar_mun  "Year before SABER11 Mun. Avg. Income index"
   
********************************************************************************

gen capital=discap==0 // Distance to the capital of Dept...
label var capital "Capital of Department"

gen poblacintotalm=poblacintotal/1000
label var poblacintotalm "Total population (1000s)"

gen pob100 = poblacintotal/100000
gen logest =ln(poblacintotal)
gen urbanrat = pobl_urb/poblacintotal
label var urbanrat "Urban-total population"
label var logest "LOG(Total population)"
label var pob100 "Population in 100.000"

label var discap "Distance to Department's capital"
gen aguam=agua/1000000
label var aguam   "Availability of water index"
label var aptitu  "Quality of soil index"
label var dismer  "Distance to the closest main market (4)"
label var altitud "Altitude (meters above sea level)"
label var mortinf "Infant Mortality Rate"

label var personasAfect "Total individuals"
label var viviendaAfect "Total dwellings"
label var vias          "Total roads"  
label var hectareas     "Total hectares"


gen     altiC=1 if altitud<500
replace altiC=2 if altitud>= 500 & altitud<1000
replace altiC=3 if altitud>=1000 & altitud<1500
replace altiC=4 if altitud>=1500 & altitud<2000
replace altiC=5 if altitud> 2000 & altitud!=.

label define altiCl 1 "Less than 500m" 2 "500m to less than 1000m" 3 "1000m to less than 1500m" ///
                    4 "1500m to less than 2000m" 5 "2000m and above"
label values altiC altiCl
label var altiC "Altitude above sea level (categories)"

drop departamento municipality


replace rainfall=rainfall/1000 // Precipitat Still not very good... 
label var rainfall "Avg. precipitation in mm/1000"

save "$mainFolder/mainData/municipalityDengue.dta", replace

* In order to give divipola codes to additional data...
/*
reclink2 departamento municipio using "$mainFolder\HealthSystem\nomMunip.dta", ///
	gen(myscore) idm(codigomunicipio) idu(idu)  ///
	minscore(0.7) ///
	npairs(10) manytoone // These are the details added by Nada Wasi to reclink
  	*/

	
*rename municipality municipio
