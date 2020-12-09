
simular_weibull <- function(id, datos, reg, horas_censura = 5){
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
  gg <- ggsurvplot(survfit(Surv(tiempo, status) ~ state_abbr, sims_tbl), data = sims_tbl)
  gg <- gg$data.survplot %>% mutate(id = id)
  gg
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
  gg <- ggsurvplot(survfit(Surv(tiempo, status) ~ state_abbr, sims_tbl), data = sims_tbl)
  gg <- gg$data.survplot %>% mutate(id = id)
  if(solo_tiempos){
    salida <- sims_tbl
  } else {
    salida <- gg
  }
  salida
}
