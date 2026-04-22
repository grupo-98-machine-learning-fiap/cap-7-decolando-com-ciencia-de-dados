# =============================================================================
#  ANÁLISE EXPLORATÓRIA – SÉRIE HISTÓRICA ALGODÃO EM CAROÇO (2010–2017)
#  Fonte: CONAB – Portal de Informações Agropecuárias
#
#  Questão 3 → Variável quantitativa: Área Plantada (mil ha)
#  Questão 4 → Variável qualitativa:  Classificação da Produtividade
# =============================================================================

# ── Pacotes necessários ────────────────────────────────────────────────────────
# install.packages(c("readxl", "ggplot2", "dplyr", "scales", "patchwork", "e1071"))
library(readxl)
library(ggplot2)
library(dplyr)
library(scales)
library(patchwork)   # combinar gráficos
library(e1071)       # assimetria e curtose

# Ajustar diretório de trabalho se executado de dentro de 'src'
if (basename(getwd()) == "src") {
  setwd("..")
}

dir.create("assets", showWarnings = FALSE)

# ── 1. Importação e preparo dos dados ─────────────────────────────────────────
dados <- read_excel(
  "assets/CONAB_SerieHistorica_Algodao_2010_2017.xlsx",
  sheet = "Dados CONAB",
  skip  = 3            # ignora título, linha de tipos e linha de cabeçalho extra
)

# Renomear colunas
colnames(dados) <- c("id", "ano", "uf", "area_mil_ha",
                     "producao_mil_t", "class_produtividade")

# Remover linha de totais (não é observação)
dados <- dados |>
  filter(!is.na(id), id != "TOTAIS / MÉDIAS") |>
  mutate(
    id             = as.integer(id),
    ano            = as.integer(ano),
    uf             = as.factor(uf),
    area_mil_ha    = as.numeric(area_mil_ha),
    producao_mil_t = as.numeric(producao_mil_t),
    class_produtividade = factor(
      class_produtividade,
      levels  = c("Baixa", "Regular", "Boa", "Excelente"),
      ordered = TRUE
    )
  )

cat("Dimensões:", nrow(dados), "linhas ×", ncol(dados), "colunas\n")
print(head(dados, 5))


# =============================================================================
#  QUESTÃO 3 – ANÁLISE EXPLORATÓRIA: Área Plantada (mil ha)
# =============================================================================

x <- dados$area_mil_ha

# ── 3.1 Medidas de Tendência Central ──────────────────────────────────────────
media   <- mean(x,   na.rm = TRUE)
mediana <- median(x, na.rm = TRUE)

# Moda: valor(es) com maior frequência (arredondado ao inteiro para variável contínua)
tabela_freq <- table(round(x, 0))
moda_val    <- as.numeric(names(tabela_freq[tabela_freq == max(tabela_freq)]))

cat("\n──────────────────────────────────────────\n")
cat("  MEDIDAS DE TENDÊNCIA CENTRAL\n")
cat("──────────────────────────────────────────\n")
cat(sprintf("  Média    : %.2f mil ha\n", media))
cat(sprintf("  Mediana  : %.2f mil ha\n", mediana))
cat(sprintf("  Moda*    : %.0f mil ha  (* arredondado ao inteiro)\n", moda_val[1]))

# ── 3.2 Medidas de Dispersão ──────────────────────────────────────────────────
variancia  <- var(x,  na.rm = TRUE)
desvpad    <- sd(x,   na.rm = TRUE)
cv         <- (desvpad / media) * 100
amplitude  <- max(x, na.rm = TRUE) - min(x, na.rm = TRUE)
amp_iq     <- IQR(x,  na.rm = TRUE)
assimetria <- skewness(x,  na.rm = TRUE)
curtose_v  <- kurtosis(x,  na.rm = TRUE)

cat("\n──────────────────────────────────────────\n")
cat("  MEDIDAS DE DISPERSÃO\n")
cat("──────────────────────────────────────────\n")
cat(sprintf("  Variância             : %.4f\n",  variancia))
cat(sprintf("  Desvio Padrão         : %.4f mil ha\n", desvpad))
cat(sprintf("  Coef. de Variação     : %.2f%%\n", cv))
cat(sprintf("  Amplitude Total       : %.2f mil ha\n", amplitude))
cat(sprintf("  Amplitude Interquart. : %.2f mil ha\n", amp_iq))
cat(sprintf("  Assimetria (skewness) : %.4f\n",  assimetria))
cat(sprintf("  Curtose               : %.4f\n",  curtose_v))

# ── 3.3 Medidas Separatrizes ──────────────────────────────────────────────────
quartis   <- quantile(x, probs = c(0.25, 0.50, 0.75), na.rm = TRUE)
percentis <- quantile(x, probs = c(0.10, 0.25, 0.50, 0.75, 0.90), na.rm = TRUE)
decis     <- quantile(x, probs = seq(0.10, 0.90, by = 0.10), na.rm = TRUE)

cat("\n──────────────────────────────────────────\n")
cat("  MEDIDAS SEPARATRIZES\n")
cat("──────────────────────────────────────────\n")

cat("\n  Quartis:\n")
cat(sprintf("    Q1 (25%%)  : %.2f mil ha\n", quartis["25%"]))
cat(sprintf("    Q2 (50%%)  : %.2f mil ha  ← mediana\n", quartis["50%"]))
cat(sprintf("    Q3 (75%%)  : %.2f mil ha\n", quartis["75%"]))

cat("\n  Percentis selecionados:\n")
for (nm in names(percentis)) {
  cat(sprintf("    %-6s : %.2f mil ha\n", nm, percentis[nm]))
}

cat("\n  Décis (D1 a D9):\n")
for (i in seq_along(decis)) {
  cat(sprintf("    D%d (%-4s): %.2f mil ha\n", i, names(decis)[i], decis[i]))
}

# ── 3.4 Análise Gráfica ───────────────────────────────────────────────────────
# Cores padronizadas
c1 <- "#1D6FA4"; c2 <- "#E05A2B"; c3 <- "#2DA668"; c4 <- "#F5A623"

## (a) Histograma com curva de densidade e linhas de média/mediana
p_hist <- ggplot(dados, aes(x = area_mil_ha)) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 12, fill = c1, color = "white", alpha = 0.85) +
  geom_density(color = c2, linewidth = 1.2, linetype = "solid") +
  geom_vline(xintercept = media,   color = c3, linewidth = 1,
             linetype = "dashed") +
  geom_vline(xintercept = mediana, color = c4, linewidth = 1,
             linetype = "dotted") +
  annotate("label", x = media   + 40, y = 0.0046,
           label = paste0("Média\n", round(media, 1)),
           color = c3, fill = "white", size = 3, label.size = 0.3) +
  annotate("label", x = mediana - 40, y = 0.0046,
           label = paste0("Mediana\n", round(mediana, 1)),
           color = c4, fill = "white", size = 3, label.size = 0.3,
           hjust = 1) +
  labs(
    title    = "Histograma com Curva de Densidade",
    subtitle = "Área Plantada (mil ha) – 2010 a 2017",
    x = "Área Plantada (mil ha)", y = "Densidade"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

## (b) Boxplot geral com anotações dos quartis
p_box <- ggplot(dados, aes(y = area_mil_ha)) +
  geom_boxplot(fill = c1, color = "gray20", alpha = 0.8,
               width = 0.4, outlier.colour = c2,
               outlier.shape = 21, outlier.fill = c2, outlier.size = 3) +
  geom_hline(yintercept = quartis["25%"], linetype = "dashed",
             color = c4, linewidth = 0.6) +
  geom_hline(yintercept = quartis["75%"], linetype = "dashed",
             color = c4, linewidth = 0.6) +
  annotate("label", x = 0.55, y = quartis["25%"],
           label = paste0("Q1 = ", round(quartis["25%"], 1)),
           color = c4, fill = "white", size = 3.2, label.size = 0.2) +
  annotate("label", x = 0.55, y = quartis["75%"],
           label = paste0("Q3 = ", round(quartis["75%"], 1)),
           color = c4, fill = "white", size = 3.2, label.size = 0.2) +
  labs(
    title    = "Boxplot – Dispersão e Outliers",
    subtitle = "Área Plantada (mil ha)",
    y = "Área Plantada (mil ha)", x = ""
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title    = element_text(face = "bold"),
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank())

## (c) Evolução da área total por ano (série temporal)
area_ano <- dados |>
  group_by(ano) |>
  summarise(total = sum(area_mil_ha, na.rm = TRUE))

p_serie <- ggplot(area_ano, aes(x = ano, y = total)) +
  geom_area(fill = c1, alpha = 0.2) +
  geom_line(color = c1, linewidth = 1.4) +
  geom_point(color = c2, size = 4, shape = 21,
             fill = "white", stroke = 2) +
  geom_text(aes(label = round(total, 0)),
            vjust = -1, size = 3.2, color = "gray30") +
  scale_x_continuous(breaks = 2010:2017) +
  labs(
    title    = "Evolução da Área Total Plantada por Safra",
    subtitle = "Soma de todos os estados (mil ha)",
    x = "Ano da Safra", y = "Área Total (mil ha)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

## (d) QQ-Plot para avaliar aderência à normalidade
dados_qq <- data.frame(
  sample = sort(x),
  teorico = qnorm(ppoints(length(x)))
)

p_qq <- ggplot(dados_qq, aes(x = teorico, y = sample)) +
  geom_point(color = c1, alpha = 0.75, size = 2.5) +
  geom_smooth(method = "lm", se = FALSE,
              color = c2, linewidth = 1.2, linetype = "solid") +
  labs(
    title    = "QQ-Plot – Aderência à Normalidade",
    subtitle = "Área Plantada (mil ha)",
    x = "Quantis Teóricos (Normal)", y = "Quantis Observados"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

## Montar e salvar painel 2×2
painel_q3 <- (p_hist | p_box) / (p_serie | p_qq) +
  plot_annotation(
    title   = "Questão 3 – Análise Exploratória: Área Plantada de Algodão (mil ha)",
    subtitle = "CONAB | Série Histórica 2010–2017",
    theme = theme(
      plot.title    = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(color = "gray50", size = 11)
    )
  )

ggsave("assets/painel_q3_area_plantada.png", painel_q3,
       width = 14, height = 10, dpi = 150)
cat("\n[✓] Painel Q3 salvo: assets/painel_q3_area_plantada.png\n")


# =============================================================================
#  QUESTÃO 4 – ANÁLISE GRÁFICA: Classificação da Produtividade (Qualitativa Ordinal)
# =============================================================================

# Paleta fixa por categoria
cores_ord <- c(
  "Baixa"     = "#E05A2B",
  "Regular"   = "#F5A623",
  "Boa"       = "#1D6FA4",
  "Excelente" = "#2DA668"
)

# Tabela de frequências
freq_abs <- dados |>
  count(class_produtividade, name = "n") |>
  mutate(pct = n / sum(n) * 100,
         label_bar  = as.character(n),
         label_pie  = paste0(class_produtividade, "\n", round(pct, 1), "%"))

## (a) Gráfico de barras – frequência absoluta
g_barras <- ggplot(freq_abs,
                   aes(x = class_produtividade, y = n,
                       fill = class_produtividade)) +
  geom_col(width = 0.6, color = "white", alpha = 0.9) +
  geom_text(aes(label = n), vjust = -0.5,
            fontface = "bold", size = 5) +
  scale_fill_manual(values = cores_ord) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title    = "Frequência Absoluta por Classificação",
    subtitle = "Total de registros (safras/estado) por categoria",
    x = "Classificação da Produtividade",
    y = "Número de Registros"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold"),
    plot.subtitle   = element_text(color = "gray50")
  )

## (b) Gráfico de setores – frequência relativa
g_pizza <- ggplot(freq_abs,
                  aes(x = "", y = pct, fill = class_produtividade)) +
  geom_col(width = 1, color = "white", linewidth = 0.8) +
  coord_polar(theta = "y", start = 0) +
  geom_text(aes(label = label_pie),
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 4.2) +
  scale_fill_manual(values = cores_ord) +
  labs(
    title    = "Frequência Relativa por Classificação",
    subtitle = "Participação percentual de cada categoria"
  ) +
  theme_void(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold",  hjust = 0.5),
    plot.subtitle   = element_text(color = "gray50", hjust = 0.5)
  )

## (c) Barras empilhadas 100% por ano – evolução da composição
g_empilhado <- dados |>
  count(ano, class_produtividade) |>
  group_by(ano) |>
  mutate(pct = n / sum(n) * 100) |>
  ggplot(aes(x = factor(ano), y = pct,
             fill = class_produtividade)) +
  geom_col(position = "fill", color = "white",
           linewidth = 0.5, alpha = 0.9) +
  geom_text(aes(label = ifelse(pct > 8,
                               paste0(round(pct, 0), "%"), "")),
            position = position_fill(vjust = 0.5),
            color = "white", fontface = "bold", size = 3.5) +
  scale_fill_manual(values = cores_ord, name = "Classificação") +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title    = "Composição da Produtividade por Ano de Safra",
    subtitle = "Proporção (%) de cada classificação",
    x = "Ano da Safra", y = "Proporção (%)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title      = element_text(face = "bold"),
    plot.subtitle   = element_text(color = "gray50"),
    legend.position = "bottom"
  )

## Montar e salvar painel Q4
painel_q4 <- (g_barras | g_pizza) / g_empilhado +
  plot_annotation(
    title    = "Questão 4 – Análise Gráfica: Classificação da Produtividade",
    subtitle = "Variável Qualitativa Ordinal | CONAB 2010–2017",
    theme = theme(
      plot.title    = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(color = "gray50", size = 11)
    )
  )

ggsave("assets/painel_q4_produtividade.png", painel_q4,
       width = 14, height = 11, dpi = 150)
cat("[✓] Painel Q4 salvo: assets/painel_q4_produtividade.png\n")

cat("\n══════════════════════════════════════════\n")
cat("  ANÁLISE CONCLUÍDA COM SUCESSO!\n")
cat("══════════════════════════════════════════\n")
