# codigos
estados_tbl <- read_csv("../datos/df_mxstate.csv")
# marco nal
marco <- read_csv("../datos/LISTADO_CASILLAS_2018.csv") %>%
  mutate(CLAVE_CASILLA = paste0(str_sub(ID, 2, 3), str_sub(ID, 6, -1))) %>%
  rename(LISTA_NOMINAL_CASILLA = LISTA_NOMINAL) %>%
  mutate(estrato = ID_ESTRATO_F) %>%
  mutate(tipo_seccion = factor(TIPO_SECCION))
marco_ext <- read_csv("../datos/marco_ext.csv")

# datos en shapes de INEGI
inegi <- list.files("../datos/shapefiles/inegi_vivienda_2010",
                    full.names = TRUE, pattern = ".dbf", recursive = TRUE) %>%
  map_df(~foreign::read.dbf(., as.is = TRUE))
# unios INEGI a marco
#marco_inegi <- marco %>%
#  left_join(select(inegi, -MUNICIPIO), by = c("SECCION", "iD_ESTADO" = "ENTIDAD"))
# write_csv(marco_inegi, file = "../datos/marco_ext.csv")
# muestra seleccionada
muestra_selec <- read_csv("../datos/4-ConteoRapido18MUESTRA-ELECCION-PRESIDENCIAL.csv") %>%
  mutate(CLAVE_CASILLA = paste0(str_sub(ID, 2, 3), str_sub(ID, 6, -1)))
nrow(muestra_selec)

### Conteos
encabezado <- read_lines("../datos/presidencia.csv", skip = 6, n_max = 1) %>%
  str_replace("\\|\\|", "") %>%
  str_split_fixed("\\|", n = 42)

conteo <- read_delim("../datos/presidencia.csv", delim = "|",
                     col_names = encabezado,
                     skip = 7,
                     quote = "'", na = c("", "NA", "-")) %>%
  mutate(AMLO_1 = MORENA + PT + `ENCUENTRO SOCIAL` + PT_MORENA +
           MORENA_PES + PT_PES + PT_MORENA_PES,
         RAC_1 = PAN + PRD + `MOVIMIENTO CIUDADANO` + PAN_PRD + PAN_MC +
           PRD_MC + PAN_PRD_MC,
         JAMK_1 = PRI + PVEM + `NUEVA ALIANZA` + PRI_PVEM + PRI_NA +
           PVEM_NA + PRI_PVEM_NA) %>%
  left_join(estados_tbl %>%
              rename(ID_ESTADO = region) %>%
              mutate(ID_ESTADO = as.numeric(ID_ESTADO)),
            by = "ID_ESTADO") %>%
  filter(TIPO_CASILLA != "M") %>%
  mutate(tipo_casilla = factor(TIPO_CASILLA, levels= c("B", "C", "E", "S"))) %>%
  mutate(lista_nominal_log = log(1 + LISTA_NOMINAL_CASILLA)) %>%
  ungroup %>%
  mutate(media_ln_log = mean(lista_nominal_log, na.rm = TRUE)) %>%
  mutate(ln_log_c = lista_nominal_log - media_ln_log) %>%
  mutate(huso = case_when(state_abbr %in% c("BC", "SON") ~ 2,
                          state_abbr %in% c("CHIH", "BCS", "NAY", "SIN") ~ 1,
                          TRUE ~ 0)) %>%
  left_join(marco_ext %>%
              select(CLAVE_CASILLA, estrato, tipo_seccion, TIPO_CASILLA, TVIVHAB:VPH_SNBIEN),
            by = c("CLAVE_CASILLA")) %>%
  filter(TOTAL_VOTOS_CALCULADOS != 0) %>% # alrededor de 200 casillas no entregadas
  filter(!is.na(tipo_seccion)) # casillas

# recuperar conteos de muestra completa
datos_muestra <- muestra_selec %>%
  left_join(conteo %>%
              select(CLAVE_CASILLA, LISTA_NOMINAL_CASILLA, AMLO_1:JAMK_1,
                     TOTAL_VOTOS_CALCULADOS, lista_nominal_log, ln_log_c,
                     huso, tipo_casilla,
                     estrato, tipo_seccion, TVIVHAB:VPH_SNBIEN) %>%
              rename(LISTA_NOMINAL = LISTA_NOMINAL_CASILLA),
            by = c("CLAVE_CASILLA", "LISTA_NOMINAL"))

# casillas de la muestra con faltantes:
datos_muestra %>% group_by(is.na(TOTAL_VOTOS_CALCULADOS)) %>%
  count() ## 33 casillas
datos_muestra <- datos_muestra %>%
  filter(!is.na(TOTAL_VOTOS_CALCULADOS)) %>%
  left_join(estados_tbl %>% mutate(iD_ESTADO = region)) %>%
  mutate(huso = case_when(state_abbr %in% c("BC", "SON") ~ 2,
                          state_abbr %in% c("CHIH", "BCS", "NAY", "SIN") ~ 1,
                          TRUE ~ 0))

## asignación muestra_selec
estratos_nal <- conteo %>%
  group_by(state_abbr, estrato) %>% count() %>%
  ungroup %>% select(-state_abbr)


# muestra obtenida por hora de llegada, calcular huso
# Clave casilla: ID_ESTADO-SECCION-TIPO_CASILLA-ID_CASILLA-EXT_CONTIGUA
remesas <- read_delim("../datos/remesas_nal/remesas_nal/REMESAS0100020000.txt",
                      delim = "|", skip = 1) %>%
  mutate(timestamp = ymd_hms(paste(ANIO, MES, DIA, HORA, MINUTOS, SEGUNDOS, sep = "-"),
                             tz = "America/Mexico_City")) %>%
  mutate(ID_ESTADO = str_pad(iD_ESTADO, 2, pad = "0"),
         SECCION = str_pad(SECCION,4, pad = "0"),
         TIPO_CASILLA = ifelse(TIPO_CASILLA == "MEC", "M", TIPO_CASILLA),
         ID_CASILLA = str_pad(ID_CASILLA, 2, pad = "0"),
         EXT_CONTIGUA = str_pad(EXT_CONTIGUA, 2, pad = "0")) %>%
  mutate(CLAVE_CASILLA = paste0(ID_ESTADO, SECCION, TIPO_CASILLA, ID_CASILLA, EXT_CONTIGUA))

muestra_tot <-
  left_join(
    datos_muestra %>% select(CLAVE_CASILLA, LISTA_NOMINAL, TIPO_SECCION,
                             ID_ESTRATO_F, ID_AREA_RESPONSABILIDAD, state_abbr,
                             TOTAL_VOTOS_CALCULADOS, tipo_casilla, lista_nominal_log,
                             ln_log_c,
                             tipo_seccion, LISTA_NOMINAL, huso, AMLO_1:JAMK_1, TVIVHAB:VPH_SNBIEN),
    remesas %>% select(-TIPO_SECCION, - TIPO_CASILLA),
    by = c("CLAVE_CASILLA", "LISTA_NOMINAL")) %>%
  mutate(llegada = ifelse(is.na(TOTAL), 0, 1)) # llegó antes de las 12:00 ?


# Construir datos de llegadas
llegadas_tbl <- muestra_tot %>%
  select(timestamp, huso, llegada, state_abbr, tipo_casilla,
         tipo_seccion,TVIVHAB, VPH_INTER,
         RAC_1, JAMK_1, AMLO_1,
         lista_nominal_log, ln_log_c,
         TOTAL_VOTOS_CALCULADOS,
         LISTA_NOMINAL, ID_ESTRATO_F.x, ID_AREA_RESPONSABILIDAD.x,
         TOTAL, ID_ESTADO) %>%
  mutate(timestamp = if_else(is.na(timestamp),
                             ymd_hms("2018-07-01 23:59:59", tz = "America/Mexico_City"), timestamp)) %>%
  mutate(timestamp = with_tz(timestamp, "America/Mexico_City")) %>%
  mutate(tiempo = difftime(timestamp,
                           ymd_hms("2018-07-01 18:30:00", tz ="America/Mexico_City"),
                           units = "hours")) %>%
  mutate(cae = paste0(ID_ESTRATO_F.x, ID_AREA_RESPONSABILIDAD.x)) %>%
  group_by(cae) %>%
  mutate(n_reporte = rank(timestamp)) %>%
  ungroup %>%
  group_by(state_abbr) %>%
  mutate(status = llegada)

# Tabla para ajustar modelos
llegadas_tbl_2 <- llegadas_tbl %>% filter(state_abbr %in% estados) %>%
  ungroup %>%
  mutate(tiempo_huso = ifelse(tiempo - huso > 0, tiempo - huso, 0.001))

