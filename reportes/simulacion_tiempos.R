#### Simulacion de tiempos de llegada

simular_cuantiles <- function(id, datos, reg, horas_censura = 5, solo_tiempos = FALSE){
  mat_cuantiles <- predict(reg, newdata = datos,
                           type = "quantile", p = seq(0.001, 0.999, by = 0.001))
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
seleccionar_muestra <- function(conteo, prop = 0.07, estado){
  conteo_tbl <- conteo %>%
    filter(!is.na(TOTAL_VOTOS_CALCULADOS)) %>%
    filter(state_abbr == estado) %>%
    select(state_abbr, tipo_casilla, lista_nominal_log,tipo_seccion,
           TOTAL_VOTOS_CALCULADOS, RAC_1, AMLO_1, JAMK_1, huso) %>%
    sample_frac(prop) %>%
    mutate(ln_log_c = lista_nominal_log - media_ln_log)
  conteo_tbl
}

select_sample_str <- function(sampling_frame, allocation,
          sample_size = sample_size, stratum = stratum, is_frac = FALSE, seed = NA,
          replace = FALSE){
  if (!is.na(seed)) set.seed(seed)

  sample_size <- dplyr::enquo(sample_size)
  sample_size_name <- dplyr::quo_name(sample_size)

  stratum_var_string <- deparse(substitute(stratum))
  stratum <- dplyr::enquo(stratum)

  if (is_frac) {
    sample <- sampling_frame %>%
      dplyr::left_join(allocation, by = stratum_var_string) %>%
      split(.[stratum_var_string]) %>%
      purrr::map_df(~dplyr::sample_frac(.,
                                        size = dplyr::pull(., sample_size_name)[1],
                                        replace = replace)) %>%
      dplyr::select(dplyr::one_of(colnames(sampling_frame)))
  } else {
    # if sample size not integer we round it
    allocation <- allocation %>%
      dplyr::mutate(!!sample_size_name := round(!!sample_size))

    sample <- sampling_frame %>%
      dplyr::left_join(allocation, by = stratum_var_string) %>%
      split(.[stratum_var_string]) %>%
      purrr::map_df(~dplyr::sample_n(.,
                                     size = dplyr::pull(., sample_size_name)[1],
                                     replace = replace)) %>%
      dplyr::select(dplyr::one_of(colnames(sampling_frame)))
  }
  return(sample)
}
