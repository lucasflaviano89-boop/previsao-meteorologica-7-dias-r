# ==============================================================
# PREVISAO METEOROLOGICA PARA QUALQUER CIDADE - 7 DIAS
# Linguagem: R | Dados: Open-Meteo (https://open-meteo.com/)
# ==============================================================

# 1. ALTERE SOMENTE O NOME DA CIDADE PARA UMA NOVA CONSULTA.
cidade <- "Ipatinga"

# Opcional: use uma sigla de pais para distinguir cidades homonimas.
# Exemplos: "BR" (Brasil), "CA" (Canada), "PT" (Portugal).
# Vazio = buscar em qualquer pais.
pais <- ""

# 2. INSTALACAO AUTOMATICA DAS DEPENDENCIAS.
pacotes <- c("httr", "jsonlite")
nao_instalados <- pacotes[!vapply(pacotes, requireNamespace,
                                  logical(1), quietly = TRUE)]
if (length(nao_instalados) > 0L) {
  install.packages(nao_instalados, repos = "https://cloud.r-project.org")
}
if (!all(vapply(pacotes, requireNamespace, logical(1), quietly = TRUE))) {
  stop("Nao foi possivel instalar os pacotes httr e jsonlite.")
}

# 3. FUNCAO DE CONSULTA COM TRATAMENTO DE ERROS.
consultar_api <- function(url, parametros) {
  resposta <- tryCatch(
    httr::GET(url, query = parametros, httr::timeout(30)),
    error = function(e) stop("Falha de conexao: ", conditionMessage(e),
                             call. = FALSE)
  )

  texto <- httr::content(resposta, as = "text", encoding = "UTF-8")
  if (httr::http_error(resposta)) {
    motivo <- tryCatch(jsonlite::fromJSON(texto)$reason,
                       error = function(e) NULL)
    if (is.null(motivo) || length(motivo) == 0L) {
      motivo <- "Sem detalhes fornecidos pela API"
    }
    stop("Erro na API (HTTP ", httr::status_code(resposta), "): ",
         motivo, call. = FALSE)
  }

  tryCatch(jsonlite::fromJSON(texto), error = function(e) {
    stop("A API retornou um JSON invalido: ", conditionMessage(e),
         call. = FALSE)
  })
}

# 4. LOCALIZACAO AUTOMATICA DA CIDADE.
cidade <- trimws(cidade)
pais <- toupper(trimws(pais))
if (nchar(cidade) < 2L) stop("Informe uma cidade com pelo menos 2 letras.")
if (nzchar(pais) && !grepl("^[A-Z]{2}$", pais)) {
  stop("O pais deve ter uma sigla ISO de 2 letras, como BR.")
}

parametros_geo <- list(name = cidade, count = 10, language = "pt", format = "json")
if (nzchar(pais)) parametros_geo$countryCode <- pais

geo <- consultar_api("https://geocoding-api.open-meteo.com/v1/search",
                     parametros_geo)
if (is.null(geo$results) || nrow(geo$results) == 0L) {
  stop("Cidade nao encontrada: ", cidade,
       ". Confira o nome ou informe a sigla do pais.")
}

# A primeira correspondencia da API e usada automaticamente.
# Para cidades homonimas, defina 'pais' e confira o local exibido.
local <- geo$results[1L, , drop = FALSE]
valor_local <- function(campo) {
  if (!campo %in% names(local)) return("")
  valor <- local[[campo]][1L]
  if (is.na(valor)) "" else as.character(valor)
}
nome_local <- paste(Filter(nzchar, c(valor_local("name"),
                                     valor_local("admin1"),
                                     valor_local("country"))),
                    collapse = ", ")
cat("\nCidade identificada: ", nome_local, "\n", sep = "")

# 5. PREVISAO DE SETE DIAS NO FUSO HORARIO LOCAL.
previsao <- consultar_api(
  "https://api.open-meteo.com/v1/forecast",
  list(
    latitude = as.numeric(local$latitude[1L]),
    longitude = as.numeric(local$longitude[1L]),
    daily = paste(c("weather_code", "temperature_2m_min",
                    "temperature_2m_max", "precipitation_sum",
                    "precipitation_probability_max", "wind_speed_10m_max"),
                  collapse = ","),
    hourly = "relative_humidity_2m",
    timezone = "auto",
    forecast_days = 7,
    temperature_unit = "celsius",
    wind_speed_unit = "kmh",
    precipitation_unit = "mm"
  )
)

if (is.null(previsao$daily$time) || is.null(previsao$hourly$time)) {
  stop("A resposta nao contem as series meteorologicas esperadas.")
}

# 6. CALCULO DA UMIDADE RELATIVA MEDIA DIARIA.
datas <- as.character(previsao$daily$time)
datas_horarias <- substr(as.character(previsao$hourly$time), 1L, 10L)
umidade_horaria <- as.numeric(previsao$hourly$relative_humidity_2m)
if (length(datas_horarias) != length(umidade_horaria)) {
  stop("A serie horaria da umidade esta incompleta.")
}
umidade_media <- vapply(datas, function(dia) {
  valores <- umidade_horaria[datas_horarias == dia]
  if (length(valores) == 0L || all(is.na(valores))) return(NA_real_)
  mean(valores, na.rm = TRUE)
}, numeric(1))

# 7. DESCRICAO DAS CONDICOES METEOROLOGICAS (CODIGOS WMO).
descrever_tempo <- function(codigo) {
  descricoes <- c(
    "0" = "Ceu limpo", "1" = "Predominantemente limpo",
    "2" = "Parcialmente nublado", "3" = "Encoberto",
    "45" = "Nevoeiro", "48" = "Nevoeiro com geada",
    "51" = "Garoa fraca", "53" = "Garoa moderada",
    "55" = "Garoa intensa", "56" = "Garoa congelante fraca",
    "57" = "Garoa congelante forte", "61" = "Chuva fraca",
    "63" = "Chuva moderada", "65" = "Chuva forte",
    "66" = "Chuva congelante fraca", "67" = "Chuva congelante forte",
    "71" = "Neve fraca", "73" = "Neve moderada",
    "75" = "Neve forte", "77" = "Graos de neve",
    "80" = "Pancadas de chuva fracas", "81" = "Pancadas de chuva moderadas",
    "82" = "Pancadas de chuva fortes", "85" = "Pancadas de neve fracas",
    "86" = "Pancadas de neve fortes", "95" = "Trovoadas",
    "96" = "Trovoadas com granizo", "99" = "Trovoadas com granizo forte"
  )
  chave <- as.character(codigo)
  if (is.na(codigo) || !chave %in% names(descricoes)) return("Nao informado")
  unname(descricoes[[chave]])
}

campo_diario <- function(nome) {
  valores <- previsao$daily[[nome]]
  if (is.null(valores) || length(valores) != length(datas)) {
    stop("Campo meteorologico ausente ou incompleto: ", nome)
  }
  as.numeric(valores)
}

# 8. CRIAR A TABELA FINAL.
tabela <- data.frame(
  Data = as.Date(datas),
  Condicao = vapply(campo_diario("weather_code"),
                    descrever_tempo, character(1)),
  Temp_min_C = round(campo_diario("temperature_2m_min"), 1),
  Temp_max_C = round(campo_diario("temperature_2m_max"), 1),
  Umidade_media_pct = round(umidade_media, 0),
  Precipitacao_mm = round(campo_diario("precipitation_sum"), 1),
  Prob_max_horaria_pct = round(campo_diario("precipitation_probability_max"), 0),
  Vento_max_kmh = round(campo_diario("wind_speed_10m_max"), 1),
  check.names = FALSE
)

# 9. EXIBIR UM RESUMO CURTO DE CADA DIA.
cat("\n========= PREVISAO METEOROLOGICA: 7 DIAS =========\n")
cat("Local: ", nome_local, "\n", sep = "")
cat("Fuso horario: ", previsao$timezone, "\n", sep = "")
cat("Periodo: ", format(min(tabela$Data), "%d/%m/%Y"),
    " a ", format(max(tabela$Data), "%d/%m/%Y"), "\n", sep = "")
cat("=================================================\n")

para_texto <- function(x, casas = 0L) {
  if (is.na(x)) return("N/D")
  formatC(x, digits = casas, format = "f", decimal.mark = ",")
}

for (i in seq_len(nrow(tabela))) {
  d <- tabela[i, ]
  cat("\n", format(d$Data, "%d/%m/%Y"), " | ", d$Condicao, "\n", sep = "")
  cat("  Temperatura: ", para_texto(d$Temp_min_C, 1), " a ",
      para_texto(d$Temp_max_C, 1), " graus C\n", sep = "")
  cat("  Umidade media: ", para_texto(d$Umidade_media_pct), "% | ",
      "Chuva: ", para_texto(d$Precipitacao_mm, 1), " mm\n", sep = "")
  cat("  Prob. maxima horaria: ", para_texto(d$Prob_max_horaria_pct),
      "% | Vento max.: ", para_texto(d$Vento_max_kmh, 1),
      " km/h\n", sep = "")
}

soma_segura <- function(x) {
  if (all(is.na(x))) return(NA_real_)
  sum(x, na.rm = TRUE)
}

cat("\nPrecipitacao prevista nos 7 dias: ",
    para_texto(soma_segura(tabela$Precipitacao_mm), 1), " mm\n", sep = "")
cat("Nota: a probabilidade informada e o maior valor HORARIO do dia.\n")

# 10. EXPORTAR RESULTADOS PARA CSV (ABRE NO EXCEL).
arquivo <- file.path(getwd(), "previsao_7_dias.csv")
write.csv2(tabela, arquivo, row.names = FALSE,
           fileEncoding = "UTF-8", na = "")
cat("\nArquivo CSV salvo em: ", normalizePath(arquivo), "\n", sep = "")

# A tabela tambem fica disponivel como objeto 'tabela' no RStudio.
