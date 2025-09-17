/*------------------------------------------------------------------------------*
| Title: 			Data preparation											|
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


* Helper: tomar la PRIMERA variable que exista en la lista
program define first_existing, rclass
    syntax, candidates(string)
    local chosen ""
    foreach v of local candidates {
        capture confirm variable `v'
        if !_rc {
            local chosen "`v'"
            continue, break
        }
    }
    return local var "`chosen'"
end

*=========================
* 1) INDIVIDUOS (base)
*=========================
use "${input}/ENAHO_individuals.dta", clear
keep mes conglome vivienda hogar codperso ///
     p207 p208a p209 facpob07

* --- Estado civil (etiquetas) ---
capture confirm variable p209
label define estciv 1 "soltero" 2 "conviviente" 3 "casado" 4 "separado" 5 "viudo" 6 "divorciado", replace
capture label values p209 estciv
label var p209 "Estado civil"

tempfile base_ind
save `base_ind', replace

*========================*
* 2) HOGAR (m:1)
*========================*
use "${input}/ENAHO_household.dta", clear
isid mes conglome vivienda hogar
keep mes conglome vivienda hogar dominio estrato ubigeo
label var dominio "Dominio (ámbito/region)"
label var estrato "Estrato muestral"
label var ubigeo  "UBIGEO"

* Área derivada del estrato (urbano=1, rural=2). Rural: 6,7,8
cap drop area
gen byte area = cond(inlist(estrato,6,7,8), 2, 1)
label define lb_area 1 "urbano" 2 "rural", replace
label values area lb_area
label var area "Área (derivada de estrato)"
*tab estrato area, m   // chequeo opcional

tempfile base_hog
save `base_hog', replace

*========================*
* 3) EMPLEO (1:1)
*========================*
use "${input}/ENAHO_employment.dta", clear
isid mes conglome vivienda hogar codperso
keep mes conglome vivienda hogar codperso ///
     fac500a p501 p502 p503 p507 p510 p510a1 p505r4 p506r4 ///
     p520 i520 p513t i524e1 d524e1 i530a d530a p517d1 p517d2
label var fac500a "Peso empleo/ingresos (cap. 500)"
label var p501    "Trabajó semana pasada"
label var p502    "No trabajó pero con empleo asalariado"
label var p503    "No trabajó pero con negocio propio"
label var p507    "Categoría ocupacional (1..4)"
label var p505r4  "CNO-2015, 4 díg"
label var p506r4  "CIIU Rev.4, 4 díg"
label var p520    "Horas normales semana"
label var i520    "Horas normales semana (imput)"
label var p513t   "Horas trabajadas semana pasada"
label var i524e1  "Ingreso líquido ocup. principal (imput, anual)"
label var d524e1  "Ingreso líquido ocup. principal (defl, anual)"
label var i530a   "Ganancia neta independientes (imput, anual)"
label var d530a   "Ganancia neta independientes (defl, anual)"
label var p517d1  "Tamaño empresa (tramos)"
label var p517d2  "N° trabajadores (reporte)"

tempfile base_emp
save `base_emp', replace

*========================*
* 4) EDUCACIÓN (1:1)
*========================*
use "${input}/ENAHO_education.dta", clear
isid mes conglome vivienda hogar codperso
keep mes conglome vivienda hogar codperso p301a p301b p301c
label var p301a "Nivel educativo"
label var p301b "Nivel educativo - año"
label var p301c "Nivel educativo - grado"

tempfile base_edu
save `base_edu', replace

*========================*
* 5) MERGE
*========================*
use `base_ind', clear
merge 1:1 mes conglome vivienda hogar codperso using `base_emp', gen(_m_emp)
drop _m_emp
merge m:1 mes conglome vivienda hogar using `base_hog', gen(_m_hog)
drop _m_hog
merge 1:1 mes conglome vivienda hogar codperso using `base_edu', gen(_m_edu)
drop _m_edu

*========================*
* 6) DERIVADAS BÁSICAS
*========================*
* Empleo/ocupación
gen byte employed = (p501==1 | p502==1 | p503==1)
label var employed "Ocupado (OIT)"

gen byte asalariado = inlist(p507,3,4)
label var asalariado "Asalariado (empleado/obrero)"

* Horas semanales (preferencia p520, luego i520, luego p513t)
gen horas_sem = .
replace horas_sem = p520   if !missing(p520)
replace horas_sem = i520   if missing(horas_sem) & !missing(i520)
replace horas_sem = p513t  if missing(horas_sem) & !missing(p513t)
replace horas_sem = . if horas_sem<=0
label var horas_sem "Horas/semana"

* Ingreso mensual (ocupación principal)
gen ingreso_m = .
replace ingreso_m = i524e1/12 if !missing(i524e1)
replace ingreso_m = d524e1/12 if missing(ingreso_m) & !missing(d524e1)
replace ingreso_m = . if ingreso_m<0
label var ingreso_m "Ingreso mensual (ocup. principal)"

* Ganancia mensual independientes (por si se usa)
gen ganancia_m = .
replace ganancia_m = i530a/12 if !missing(i530a)
replace ganancia_m = d530a/12 if missing(ganancia_m) & !missing(d530a)
replace ganancia_m = . if ganancia_m<0

* Edad
gen edad  = p208a
gen edad2 = edad^2

* CNO/CIIU agregados
foreach v in p505r4 p506r4 {
    cap confirm numeric variable `v'
    if _rc destring `v', replace force
    replace `v' = . if inlist(`v',0,9999)
}
gen occ1 = floor(p505r4/1000) if !missing(p505r4)
label var occ1 "CNO-2015 (1 díg.)"
gen ind2 = floor(p506r4/100)   if !missing(p506r4)
label var ind2 "CIIU4 división (2 díg.)"

gen ind_sec = .
replace ind_sec =  1 if inrange(ind2,  1,  3)    // A Agro/pesca
replace ind_sec =  2 if inrange(ind2,  5,  9)    // B Minería
replace ind_sec =  3 if inrange(ind2, 10, 33)    // C Manufactura
replace ind_sec =  4 if ind2==35                  // D Electricidad/gas
replace ind_sec =  5 if inrange(ind2, 36, 39)    // E Agua/residuos
replace ind_sec =  6 if inrange(ind2, 41, 43)    // F Construcción
replace ind_sec =  7 if inrange(ind2, 45, 47)    // G Comercio
replace ind_sec =  8 if inrange(ind2, 49, 53)    // H Transporte
replace ind_sec =  9 if inrange(ind2, 55, 56)    // I Aloj/comida
replace ind_sec = 10 if inrange(ind2, 58, 63)    // J Información
replace ind_sec = 11 if inrange(ind2, 64, 66)    // K Finanzas
replace ind_sec = 12 if ind2==68                  // L Inmobiliarias
replace ind_sec = 13 if inrange(ind2, 69, 75)    // M Profesionales
replace ind_sec = 14 if inrange(ind2, 77, 82)    // N Apoyo
replace ind_sec = 15 if ind2==84                  // O Adm pública
replace ind_sec = 16 if ind2==85                  // P Educación
replace ind_sec = 17 if inrange(ind2, 86, 88)    // Q Salud
replace ind_sec = 18 if inrange(ind2, 90, 93)    // R Arte
replace ind_sec = 19 if inrange(ind2, 94, 96)    // S Otros
replace ind_sec = 20 if inrange(ind2, 97, 98)    // T Hogares
replace ind_sec = 21 if ind2==99                  // U Extraterritoriales
label var ind_sec "CIIU4 sección (1..21)"

* Dummies de cuatro sectores que usaremos como CONTROLES numéricos
gen byte s_agri = ind_sec==1
gen byte s_mine = ind_sec==2
gen byte s_manu = ind_sec==3
gen byte s_com  = ind_sec==7
label var s_agri "Sección A (agro/pesca)"
label var s_mine "Sección B (minería)"
label var s_manu "Sección C (manufactura)"
label var s_com  "Sección G (comercio)"

* Tamaño de empresa para modelo
rename p517d1 tam_emp
label var tam_emp "Tamaño de empresa (tramos)"

*========================*
* 7) SLIM para OAXACA (ASALARIADOS: ingreso_m)
*========================*
preserve
keep mes conglome vivienda hogar codperso ///
     p207 p209 edad edad2 p301a area tam_emp ///
     horas_sem ingreso_m ///
     occ1 ind2 ind_sec s_agri s_mine s_manu s_com ///
     dominio estrato fac500a p507 ubigeo
compress
save "${full}/ENAHO_oax_wage.dta", replace
restore

*========================*
* 8) SLIM para OAXACA (PEA: ingreso total)
*========================*
gen ingreso_m_total = .
replace ingreso_m_total = ingreso_m  if inlist(p507,3,4) & !missing(ingreso_m)
replace ingreso_m_total = ganancia_m if inlist(p507,1,2) & !missing(ganancia_m)
replace ingreso_m_total = . if ingreso_m_total<=0

preserve
keep mes conglome vivienda hogar codperso ///
     p207 p209 edad edad2 p301a area tam_emp ///
     horas_sem ingreso_m_total ///
     occ1 ind2 ind_sec s_agri s_mine s_manu s_com ///
     dominio estrato fac500a p507 ubigeo
compress
save "${full}/ENAHO_oax_pea.dta", replace
restore

di as res "OK: creados ENAHO_oax_wage.dta y ENAHO_oax_pea.dta en ${full}"