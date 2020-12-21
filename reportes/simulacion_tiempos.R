#### Simulacion de tiempos de llegada

simular_cuantiles <- function(id, datos, reg, horas_censura = 5, solo_tiempos = FALSE){
  mat_cuantiles <- predict(reg, newdata = datos,
                           type = "quantile", p = seq(0.01, 0.99, by = 0.01))
  rownames(mat_cuantiles) <- NULL
  sims_sin_censura <- apply(mat_cuantiles, 1, function(cuantiles){
    sample(cuantiles, 1)
  })
  ##
  sims_tbl <- as_tibble(datos) %>%
    mutate(sim_tiempo_sc = sims_sin_censura) %>%
    mutate(max_time = horas_censura + ifelse(huso == 0, 1, 0)) %>%
    mutate(status_sim = ifelse(sim_tiempo_sc > max_time, 0, 1)) %>%
    ungroup %>%
    mutate(tiempo_obs_sim = ifelse(status_sim == 0, max_time, sim_tiempo_sc)) %>%
    select(tiempo_obs_sim, status_sim, state_abbr) %>%
    rename(tiempo = tiempo_obs_sim, status = status_sim)
  sims_tbl <- sims_tbl %>% mutate(id = id)
  ## producir salidas
  if(solo_tiempos){
    salida <- sims_tbl
  } else {
    gg <- ggsurvplot(survfit(Surv(tiempo, status) ~ state_abbr, sims_tbl), data = sims_tbl)
    gg <- gg$data.survplot %>% mutate(id = id)
    salida <- gg
  }
  salida
}

simular_weibull <- function(id, datos, reg, horas_censura = 5, solo_tiempos = FALSE){
  # simulación para regresión weibull
  linear <- predict(reg, newdata = datos, type = "linear")
  lambda <- exp(-linear)
  escalas <- reg$scale[datos$state_abbr]
  ## simular
  sims_sin_censura <- rweibull(length(lambda),
                               shape = 1/escalas,
                               scale = 1/lambda)
  ##
  sims_tbl <- as_tibble(datos) %>%
    mutate(sim_tiempo_sc = sims_sin_censura) %>%
    mutate(max_time = horas_censura + ifelse(huso == 0, 1, 0)) %>%
    mutate(status_sim = ifelse(sim_tiempo_sc > max_time, 0, 1)) %>%
    ungroup %>%
    mutate(tiempo_obs_sim = ifelse(status_sim == 0, max_time, sim_tiempo_sc)) %>%
    select(tiempo_obs_sim, status_sim, state_abbr) %>%
    rename(tiempo = tiempo_obs_sim, status = status_sim)
  sims_tbl <- sims_tbl %>% mutate(id = id)
  ## producir salidas
  if(solo_tiempos){
    salida <- sims_tbl
  } else {
    gg <- ggsurvplot(survfit(Surv(tiempo, status) ~ state_abbr, sims_tbl), data = sims_tbl)
    gg <- gg$data.survplot %>% mutate(id = id)
    salida <- gg
  }
  salida
}

simular_lognormal <- function(id, datos, reg, horas_censura = 5, solo_tiempos = FALSE){
  # simulación para regresión weibull
  linear <- predict(reg, newdata = datos, type = "linear")
  ## simular
  escalas <- reg$scale[datos$state_abbr]
  sims_sin_censura <- rlnorm(length(linear), linear, escalas)
  ##
  sims_tbl <- as_tibble(datos) %>%
    mutate(sim_tiempo_sc = sims_sin_censura) %>%
    mutate(max_time = horas_censura + ifelse(huso == 0, 1, 0)) %>%
    mutate(status_sim = ifelse(sim_tiempo_sc > max_time, 0, 1)) %>%
    ungroup %>%
    mutate(tiempo_obs_sim = ifelse(status_sim == 0, max_time, sim_tiempo_sc)) %>%
    select(tiempo_obs_sim, status_sim, state_abbr) %>%
    rename(tiempo = tiempo_obs_sim, status = status_sim)
  sims_tbl <- sims_tbl %>% mutate(id = id)
  ## producir salidas
  if(solo_tiempos){
    salida <- sims_tbl
  } else {
    gg <- ggsurvplot(survfit(Surv(tiempo, status) ~ state_abbr, sims_tbl), data = sims_tbl)
    gg <- gg$data.survplot %>% mutate(id = id)
    salida <- gg
  }
  salida
}


## Simular muestra
seleccionar_muestra <- function(conteo, prop = 0.07, est = "CHIH"){
  conteo_tbl <- conteo %>%
    filter(TOTAL_VOTOS_CALCULADOS!= 0 & !is.na(TOTAL_VOTOS_CALCULADOS)) %>%
    filter(state_abbr == est) %>%
    select(state_abbr, tipo_casilla, lista_nominal_log,
           TOTAL_VOTOS_CALCULADOS, RAC_1, AMLO_1, JAMK_1, huso) %>%
    sample_frac(prop) %>%
    mutate(ln_log_c = lista_nominal_log - media_ln_log)
  conteo_tbl
}
