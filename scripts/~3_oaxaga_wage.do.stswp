*==============================================================*
* OAXACA_ingreso_PEAv1.do  (ln ingreso mensual, PEA ocupada)   *
*==============================================================*
***************************************************

* 0) Carga (usa ${full} si existe; si no, el archivo local)
capture confirm file "${full}/ENAHO_oax_wage.dta"
if !_rc {
    use "${full}/ENAHO_oax_wage.dta", clear
}
else {
    use "ENAHO_oax_wage.dta", clear
}

* Asegurar tipos numéricos
cap confirm numeric variable conglome
if _rc destring conglome, replace
cap confirm numeric variable mes
if _rc destring mes, replace

* 1) Diseño muestral
svyset conglome [pweight=fac500a], strata(estrato) vce(linearized) singleunit(centered)

* 2) Muestra: asalariados 18–65 con ingreso y horas válidas
keep if inlist(p507,3,4)
keep if inrange(edad,18,65)
drop if missing(ingreso_m, horas_sem)
drop if ingreso_m<=0 | horas_sem<=0

* Dependiente
gen lnym = ln(ingreso_m)
drop if !inrange(lnym, ln(50), ln(1e7))

* Sectores (si faltan, crearlos desde ind_sec)
cap confirm variable s_agri
if _rc gen byte s_agri = ind_sec==1
cap confirm variable s_mine
if _rc gen byte s_mine = ind_sec==2
cap confirm variable s_manu
if _rc gen byte s_manu = ind_sec==3
cap confirm variable s_com
if _rc gen byte s_com  = ind_sec==7

* Variables categóricas: asegurar numéricas
cap confirm numeric variable area
if _rc destring area, replace
cap confirm numeric variable tam_emp
if _rc destring tam_emp, replace

* Grupo (sexo) robusto
cap confirm numeric variable p207
if _rc {
    encode p207, gen(p207_g)
    local grpvar p207_g
}
else local grpvar p207

* 3) Brecha bruta (encuesta)
svy: regress lnym i.`grpvar', nocons
lincom 1.`grpvar' - 2.`grpvar'
di as res "Brecha bruta (%): " 100*(exp(r(estimate))-1)

* 4) Oaxaca
cap which oaxaca
if _rc ssc install oaxaca

xi: oaxaca lnym edad edad2 horas_sem s_agri s_mine s_manu s_com ///
    i.p301a i.area i.tam_emp i.p209 [pw=fac500a], ///
    by(`grpvar') pooled relax detail vce(cluster conglome)
estimates store OX_pooled

xi: oaxaca lnym edad edad2 horas_sem s_agri s_mine s_manu s_com ///
    i.p301a i.area i.tam_emp i.p209 [pw=fac500a], ///
    by(`grpvar') weight(0.5) relax detail vce(cluster conglome)
estimates store OX_reimers

* 5) Extraer brechas 
estimates restore OX_pooled
matrix b = e(b)
local cndiff = colnumb(b,"difference")
if `cndiff'==0 local cndiff = colnumb(b,"gap")
local cnexp  = colnumb(b,"explained")
local cnunx  = colnumb(b,"unexplained")
if `cnunx'==0 local cnunx = colnumb(b,"residual")
scalar diff = b[1,`cndiff']
scalar expl = b[1,`cnexp']
scalar unex = b[1,`cnunx']
di as res "Pooled  | total: " 100*(exp(diff)-1) "%  | expl: " 100*(exp(expl)-1) "%  | unex: " 100*(exp(unex)-1) "%"

estimates restore OX_reimers
matrix b = e(b)
local cndiff = colnumb(b,"difference")
if `cndiff'==0 local cndiff = colnumb(b,"gap")
local cnexp  = colnumb(b,"explained")
local cnunx  = colnumb(b,"unexplained")
if `cnunx'==0 local cnunx = colnumb(b,"residual")
scalar diff = b[1,`cndiff']
scalar expl = b[1,`cnexp']
scalar unex = b[1,`cnunx']
di as res "Reimers | total: " 100*(exp(diff)-1) "%  | expl: " 100*(exp(expl)-1) "%  | unex: " 100*(exp(unex)-1) "%"

* 6) tabulados de presencia por sexo
tab s_agri `grpvar', m
tab s_mine `grpvar', m
tab s_manu `grpvar', m
tab s_com  `grpvar', m
