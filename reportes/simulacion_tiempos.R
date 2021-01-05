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
    select(state_abbr, tipo_casilla, lista_nominal_log, ln_log_c, tipo_seccion,
           TOTAL_VOTOS_CALCULADOS, RAC_1, AMLO_1, JAMK_1, huso, TVIVHAB:VPH_SNBIEN) %>%
    sample_frac(prop)
  conteo_tbl
}

seleccionar_muestra_est <- function(conteo, prop = 0.07, estado){
  conteo_tbl <- conteo %>%
    filter(!is.na(TOTAL_VOTOS_CALCULADOS)) %>%
    filter(state_abbr == estado) %>%
    select(state_abbr, tipo_casilla, lista_nominal_log, ln_log_c, tipo_seccion,
           TOTAL_VOTOS_CALCULADOS, RAC_1, AMLO_1, JAMK_1, huso, estrato, TVIVHAB:VPH_SNBIEN)

  muestra <- select_sample_prop(conteo_tbl, stratum = estrato, frac = prop)
  muestra
}

select_sample_prop <- function(sampling_frame, stratum = stratum, frac,
                               seed = NA, replace = FALSE){
  if (!is.na(seed)) set.seed(seed)
  if (missing(stratum)) {
    sample <- dplyr::sample_frac(sampling_frame, size = frac,
                                 replace = replace)
  } else {
    stratum <- dplyr::enquo(stratum)
    sample <- sampling_frame %>%
      dplyr::group_by(!!stratum) %>%
      dplyr::sample_frac(size = frac, replace = replace) %>%
      dplyr::ungroup()
  }
  return(sample)
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

simular_cortes <-  function(rep, cortes = cortes, prop_muestra = 0.3, estado_sim){
  # seleccionar una muestra y simular tiempos de llegadas
  # estratificada proporcional
  # para MAS reemplazar la variable estrato en tabla conteo
  muestra_tbl <- seleccionar_muestra_est(conteo, prop = prop_muestra, estado = estado_sim)
  tiempos_sim <- simular_cuantiles(1, muestra_tbl, reg_2, solo_tiempos = TRUE)
  datos <- bind_cols(tiempos_sim, muestra_tbl %>% select(-state_abbr)) %>%
    arrange(tiempo) %>%
    pivot_longer(cols = all_of(c("AMLO_1", "RAC_1", "JAMK_1")),
                 names_to = "candidato", values_to ="num_votos") %>%
    group_by(candidato, estrato) %>%
    mutate(acumulado_cand = cumsum(num_votos),
           acumulado_tot = cumsum(TOTAL_VOTOS_CALCULADOS),
           num_casillas = row_number())
  evaluacion_tbl <- map(cortes, function(corte) {
    # calcular props para cada corte
    # tomar ultimos datos
    props_corte <- datos %>% filter(tiempo <= corte) %>%
      select(candidato, acumulado_cand, tiempo, acumulado_tot, num_casillas, estrato) %>%
      slice(n()) %>% rename(hora_salida = tiempo) %>%
      #mutate(prop_cand = acumulado_cand / acumulado_tot) %>%
      mutate(corte = corte, prop_muestra = prop_muestra)
    # calcular porporciones
    props_corte_w <- props_corte %>% left_join(estratos_nal, by = "estrato") %>%
      mutate(acum_cand_w = acumulado_cand * n / num_casillas,
             acum_total_w = acumulado_tot * n / num_casillas) %>%
      ungroup %>%
      group_by(candidato, corte, prop_muestra) %>%
      summarise(prop_cand = sum(acum_cand_w) / sum(acum_total_w),
                prop_casillas_muestra = (sum(num_casillas) / sum(n)) / prop_muestra, .groups = "drop")
    props_corte_w
  }) %>%
    bind_rows %>% # unir todos los cortes
    mutate(rep = rep)
}
