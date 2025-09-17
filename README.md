# Equal Pay: Brechas Salariales de Género en Perú (ENAHO)

Este proyecto estima la brecha salarial entre **hombres y mujeres** en Perú usando microdatos de **ENAHO 2024** y descomposición **Oaxaca-Blinder**. Se construyen datasets “slim” desde módulos individuales, hogar, empleo y educación, y se ejecutan modelos para la PEA ocupada y para asalariados.

## 📂 Estructura del repositorio

```
├── scripts/
│   ├── master.do                 # Orquestador del proyecto (paths + ejecución)
│   ├── 1_Merge_ENAHO.do          # Integración de módulos y derivadas
│   ├── 2_oaxaca_pea_total.do     # Oaxaca-Blinder PEA (ingreso total)
│   └── 3_oaxaca_wage.do          # Oaxaca-Blinder asalariados (ingreso principal)
├── data/
│   ├── ENAHO_modules/            # *.dta originales (input)
│   └── ENAHO_full/               # bases slim generadas (output intermedio)
├── output/                       # tablas/figuras/logs que se generen
├── README.md
└── .gitignore
```

> Los nombres de carpetas se corresponden con los `globals` usados por Stata:
> - `${input} = data/ENAHO_modules`
> - `${full}  = data/ENAHO_full`
> - `${out}   = output`
> - `${code_dir} = scripts`

## 👩‍💻 Requisitos

- **Stata:** 18 (o superior recomendado)
- **Paquete adicional:**  
  ```stata
  ssc install oaxaca
  ```
- **Datos ENAHO** en formato `.dta` dentro de `data/ENAHO_modules/`:
  - `ENAHO_individuals.dta`
  - `ENAHO_household.dta`
  - `ENAHO_employment.dta`
  - `ENAHO_education.dta`

## ⚙️ Configuración de rutas (master.do)

En `scripts/master.do` se detecta el usuario de Stata y se ajusta `root`. Edita/duplica los bloques `if "`c(username)'" == "USUARIO"` para tu máquina, por ejemplo:

```stata
* Descubre tu usuario: di c(username)
if "`c(username)'" == "TU_USUARIO" {
    global root "C:/Users/TU_USUARIO/Documents/equal_pay"
    local os "windows"
}

global input "${root}/data/ENAHO_modules"
global full  "${root}/data/ENAHO_full"
global out   "${root}/output"
global code_dir "${root}/scripts"
cap mkdir "${full}"
cap mkdir "${out}"
```

> Alternativa: define un solo `root` “portátil” (e.g., usando una variable de entorno o un solo bloque).

## ▶️ Ejecución

### Opción A — **Todo con el master**
1. Ajusta las rutas en `master.do` (ver arriba).
2. Desde Stata:
   ```stata
   do scripts/master.do
   ```
   El *master* ejecuta en orden:
   1. `1_Merge_ENAHO.do` → crea `ENAHO_oax_pea.dta` y `ENAHO_oax_wage.dta` en `data/ENAHO_full/`.
   2. `2_oaxaca_pea_total.do` → Oaxaca/PEA.
   3. `3_oaxaca_wage.do` → Oaxaca/asalariados.

### Opción B — **Paso a paso**
```stata
do scripts/1_Merge_ENAHO.do
do scripts/2_oaxaca_pea_total.do
do scripts/3_oaxaca_wage.do
```

## 🧪 Qué hace cada script

### `1_Merge_ENAHO.do` (preparación de datos)
- **Llaves:** persona `mes conglome vivienda hogar codperso`; hogar `mes conglome vivienda hogar`.
- Construye derivadas: condición laboral, horas preferidas (`p520`→`i520`→`p513t`), **ingreso_m** (asalariados), **ganancia_m** (independientes), **ingreso_m_total**, edad², CNO/CIIU agregados (incluye `ind_sec` y dummies sectoriales), área urbano/rural y tamaño de empresa.
- **Salidas “slim”:**
  - `ENAHO_oax_wage.dta` (asalariados).
  - `ENAHO_oax_pea.dta` (PEA ocupada).

### `2_oaxaca_pea_total.do` (Oaxaca PEA)
- Declara diseño muestral: `svyset conglome [pweight=fac500a], strata(estrato)`.
- Muestra: PEA 18–65 años, categorías `p507 ∈ {1,2,3,4}`, ingresos/horas válidos.
- Brecha bruta (regresión `svy` con dummies de sexo).
- **Oaxaca-Blinder** (pooled y Reimers 0.5) con controles: edad, edad², horas, sector, educación, área, tamaño, estado civil.  
- Reporta **total / explicado / no explicado** (%).

### `3_oaxaca_wage.do` (Oaxaca asalariados)
- Igual a PEA pero restringe `p507 ∈ {3,4}` y usa **ingreso_m** (ocupación principal).

## 🧮 Diseño muestral y pesos

- Encuesta declarada con PSU `conglome`, estrato `estrato` y peso **`fac500a`** (empleo/ingresos).  
- En la preparación se incluye también `facpob07` (población). Documenta en tu informe **cuándo** usar cada uno (por ejemplo, módulos de empleo vs. totales poblacionales).  
- Varianza: `vce(linearized)` y `singleunit(centered)`.

## 📈 Resultados esperados

- **Brecha bruta**: diferencia porcentual promedio en log-ingresos entre sexos.  
- **Oaxaca-Blinder**:
  - **Explicado**: composición (educación, experiencia prox. por edad, horas, sector, tamaño, área, estado civil, etc.).
  - **No explicado**: diferenciales manteniendo composición constante (posibles retornos diferenciales/discriminación, no-observables).

## 🧯 Troubleshooting

- **“file not found”**: verifica que los `.dta` estén en `data/ENAHO_modules/` y que `global root` apunte bien.  
- **`oaxaca` no instalado**:  
  ```stata
  ssc install oaxaca
  ```
- **Tipos string/num**: los scripts ya destringuean si es necesario (`conglome`, `mes`, `area`, `tam_emp`). Si aparecen warnings, revisa etiquetas/valores atípicos en esos campos.

## 👥 Autores

- [**María José Mesías**](https://www.linkedin.com/in/majomesias/)
- [**Julián López Céspedes**](https://www.linkedin.com/in/juli%C3%A1n-l%C3%B3pez-c%C3%A9spedes-07a043244/)


---
