############################################################
#  Diagnóstico e limpeza de arquivos temporários do R
#  Windows
# 
#  Versão 1: 21/11/2026 - Matheus Stivali
############################################################

library(tidyverse)

# 1. Identificar os diretórios temporários
tempdir()
Sys.getenv("TEMP")

# 2. Função para calcular o tamanho de uma pasta em GB
tamanho_pasta <- function(caminho) {
  
  arquivos <- list.files(
    caminho,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  
  info <- file.info(arquivos)
  
  sum(info$size[!is.na(info$isdir) & !info$isdir], na.rm = TRUE) / 1024^3
}

# 3. Verificar o espaço ocupado
tamanho_pasta(tempdir())
tamanho_pasta(Sys.getenv("TEMP"))

# 4. Identificar as maiores pastas temporárias
pastas <- list.dirs(
  Sys.getenv("TEMP"),
  recursive = FALSE,
  full.names = TRUE
)

tibble(
  pasta = basename(pastas),
  tamanho_GB = sapply(pastas, tamanho_pasta)
) %>%
  arrange(desc(tamanho_GB)) %>%
  print(n = 30)

# 5. Identificar a pasta da sessão atual
basename(tempdir())

# 6. Limpeza MANUAL de uma pasta Rtmp antiga
# Substituir pelo nome da pasta identificada acima.
# Executar somente após verificar que não está em uso.
#
# pasta_apagar <- file.path(Sys.getenv("TEMP"), "Rtmpu0REhA")
#
# if (normalizePath(pasta_apagar, mustWork = FALSE) !=
#     normalizePath(tempdir(), mustWork = FALSE)) {
#   unlink(pasta_apagar, recursive = TRUE)
# }

# 7. Conferir o espaço após a limpeza
tamanho_pasta(Sys.getenv("TEMP"))