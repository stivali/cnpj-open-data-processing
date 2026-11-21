###########################################################################################
#
# Processamento dos dados públicos do CNPJ
# https://dados.gov.br/dados/conjuntos-dados/cadastro-nacional-da-pessoa-juridica---cnpj
#
# V1:           13/06/2024 - Matheus Stivali e Yohan Rocha
# Versão atual: 21/11/2026 - Matheus Stivali
#
#
# ATENÇÃO:
# Este programa lê diretamente os arquivos compactados (.zip) disponibilizados
# pela Receita Federal. Durante a leitura, o R/vroom pode descompactar os arquivos
# em diretórios temporários, consumindo uma quantidade significativa de espaço
# em disco.
#
# Em algumas situações, esses arquivos temporários não são removidos
# automaticamente após o processamento ou o encerramento da sessão do R.
#
# É recomendável verificar o espaço disponível antes da execução e, após
# o processamento, conferir e remover manualmente os arquivos temporários
# remanescentes que não estejam sendo utilizados por outros processos.
#
# No R, o diretório temporário da sessão pode ser identificado com tempdir().
#
# TRATAMENTO DE VALORES AUSENTES:
# Os arquivos originais da Receita Federal podem utilizar "00000000" para
# representar datas ausentes. Na leitura com vroom(), esse valor é tratado
# como NA para evitar problemas na conversão das variáveis para Date.
#
# A opção na = c("", "00000000") é aplicada a todas as colunas.
#
#
# Ver arquivo "Layout CNPJ - Dicionário de Variáveis.pdf" para a estrutura
# dos arquivos originais.
#
###########################################################################################

library("vroom")
library("tidyverse")
library("arrow")
library("haven")

###################################
## Arquivos e diretórios
###################################

# Diretório principal dos dados
diretorio_dados <- "D:/Data/CNPJ"

# Competência dos arquivos da Receita Federal
competencia <- "2026-11"

# Diretórios de entrada e saída
diretorio_zip <- file.path(diretorio_dados, "zip", competencia)
diretorio_parquet <- file.path(diretorio_dados, "parquet", competencia)
diretorio_stata <- file.path(diretorio_dados, "stata", competencia)

# Arquivos originais
empresas <- dir(diretorio_zip,
                pattern = "^Empresas[0-9]+\\.zip$",
                full.names = TRUE)

estabelecimentos <- dir(diretorio_zip,
                        pattern = "^Estabelecimentos[0-9]+\\.zip$",
                        full.names = TRUE)

socios <- dir(diretorio_zip,
              pattern = "^Socios[0-9]+\\.zip$",
              full.names = TRUE)

simples <- file.path(diretorio_zip, "Simples.zip")

# Criação dos diretórios de saída
dir.create(file.path(diretorio_parquet, "empresas"),
           recursive = TRUE, showWarnings = FALSE)

dir.create(file.path(diretorio_parquet, "estabelecimentos"),
           recursive = TRUE, showWarnings = FALSE)

dir.create(file.path(diretorio_parquet, "socios"),
           recursive = TRUE, showWarnings = FALSE)

dir.create(diretorio_stata,
           recursive = TRUE, showWarnings = FALSE)

###################################
## Variáveis
###################################

# Cria "vetores de variáveis" para: empresas, estabelecimentos, socios e simples

vars_empresas <- c("cnpj_basico",
                   "razao_social",
                   "nat_jur",
                   "qualif_responsavel",
                   "capital_social",
                   "porte",
                   "ente_fed")


vars_estabelecimentos <- c("cnpj_basico",
                           "cnpj_ordem",
                           "cnpj_dv",
                           "matriz_filial",
                           "nome_fantasia",
                           "situacao_cadastral",
                           "data_situ_cadastral",
                           "motivo_situ_cadastral",
                           "nome_cidade_exterior",
                           "pais",
                           "data_inicio",
                           "cnae_fiscal_principal",
                           "cnae_fiscal_secundaria",
                           "tipo_logradouro",
                           "logradouro",
                           "numero_estab",
                           "complemento",
                           "bairro",
                           "cep",
                           "uf",
                           "municipio",
                           "ddd_1",
                           "telefone_1",
                           "ddd_2",
                           "telefone_2",
                           "ddd_fax",
                           "fax",
                           "correio_eletronico",
                           "situacao_especial",
                           "data_situ_especial")


vars_socios <- c("cnpj_basico",
                 "id_socio",
                 "nome_ou_razao",
                 "cnpj_cpf",
                 "qualificacao_socio",
                 "data_entrada_sociedade",
                 "pais",
                 "representante_legal",
                 "nome_representante",
                 "qualificacao_representante",
                 "faixa_etaria")


vars_simples <- c("cnpj_basico",
                  "opcao_simples",
                  "data_opcao_simples",
                  "data_exclusao_simples",
                  "opcao_mei",
                  "data_opcao_mei",
                  "data_exclusao_mei")



###################################
## Leitura e salvamento das empresas
###################################

for (i in seq_along(empresas)) {
  
  vroom(
    empresas[i],
    delim = ";",
    col_names = vars_empresas,
    col_types = cols(
      cnpj_basico        = col_character(),
      razao_social       = col_character(),
      nat_jur            = col_integer(),
      qualif_responsavel = col_integer(),
      capital_social     = col_double(),
      porte              = col_integer(),
      ente_fed           = col_character()
    ),
    show_col_types = FALSE,
    locale = locale(
      encoding = "latin1",
      decimal_mark = ","
    )
  ) %>%
    # Extrai possível CPF ao final da razão social
    mutate(
      CPF_MEI = stringr::str_extract(
        razao_social,
        "(?<!\\d)\\d{11}$"
      )
    ) %>%
    # Ordena para melhorar a compressão
    arrange(nat_jur, qualif_responsavel,
            capital_social, porte) %>%
    write_parquet(
      sink = file.path(
        diretorio_parquet,
        "empresas",
        sprintf("empresas_%03d.parquet", i - 1)
      ),
      compression = "gzip",
      compression_level = 9
    )
}

###################################
## Verificação de um arquivo
###################################

empresas_teste <- read_parquet(
  file.path(diretorio_parquet,
            "empresas",
            "empresas_001.parquet")
)

glimpse(empresas_teste)


###################################
## Leitura e salvamento dos estabelecimentos
###################################

for (i in seq_along(estabelecimentos)) {
  
  vroom(
    estabelecimentos[i],
    delim = ";",
    col_names = vars_estabelecimentos,
    col_types = cols(
      cnpj_basico            = col_character(),
      cnpj_ordem             = col_character(),
      cnpj_dv                = col_character(),
      matriz_filial          = col_integer(),
      nome_fantasia          = col_character(),
      situacao_cadastral     = col_integer(),
      data_situ_cadastral    = col_date(format = "%Y%m%d"),
      motivo_situ_cadastral  = col_integer(),
      nome_cidade_exterior   = col_character(),
      pais                   = col_character(),
      data_inicio            = col_date(format = "%Y%m%d"),
      cnae_fiscal_principal  = col_integer(),
      cnae_fiscal_secundaria = col_character(),
      tipo_logradouro        = col_character(),
      logradouro             = col_character(),
      numero_estab           = col_character(),
      complemento            = col_character(),
      bairro                 = col_character(),
      cep                    = col_character(),
      uf                     = col_character(),
      municipio              = col_character(),
      ddd_1                  = col_character(),
      telefone_1             = col_character(),
      ddd_2                  = col_character(),
      telefone_2             = col_character(),
      ddd_fax                = col_character(),
      fax                    = col_character(),
      correio_eletronico     = col_character(),
      situacao_especial      = col_character(),
      data_situ_especial     = col_date(format = "%Y%m%d")
    ),
    na = c("", "00000000"),
    show_col_types = FALSE,
    locale = locale(encoding = "latin1")
  ) %>%
    
    # Ordena para favorecer a compressão
    arrange(cep, uf, municipio) %>%
    
    write_parquet(
      sink = file.path(
        diretorio_parquet,
        "estabelecimentos",
        sprintf("estabelecimentos_%03d.parquet", i - 1)
      ),
      compression = "gzip",
      compression_level = 9
    )
}

###################################
## Verificação de um arquivo
###################################

estab_teste <- read_parquet(
  file.path(
    diretorio_parquet,
    "estabelecimentos",
    "estabelecimentos_000.parquet"
  )
)

glimpse(estab_teste)


###################################
## Leitura e salvamento dos sócios
###################################

for (i in seq_along(socios)) {
  
  vroom(
    socios[i],
    delim = ";",
    col_names = vars_socios,
    col_types = cols(
      cnpj_basico                = col_character(),
      id_socio                   = col_integer(),
      nome_ou_razao              = col_character(),
      cnpj_cpf                   = col_character(),
      qualificacao_socio         = col_integer(),
      data_entrada_sociedade     = col_date(format = "%Y%m%d"),
      pais                       = col_character(),
      representante_legal        = col_character(),
      nome_representante         = col_character(),
      qualificacao_representante = col_integer(),
      faixa_etaria               = col_integer()
    ),
    na = c("", "00000000"),
    show_col_types = FALSE,
    locale = locale(encoding = "latin1")
  ) %>%
    
    # Ordena para melhorar a compressão
    arrange(id_socio, data_entrada_sociedade) %>%
    
    write_parquet(
      sink = file.path(
        diretorio_parquet,
        "socios",
        sprintf("socios_%03d.parquet", i - 1)
      ),
      compression = "gzip",
      compression_level = 9
    )
}

###################################
## Verificação de um arquivo
###################################

socios_teste <- read_parquet(
  file.path(
    diretorio_parquet,
    "socios",
    "socios_000.parquet"
  )
)

glimpse(socios_teste)


###################################
## Leitura e salvamento do Simples
###################################

simples_lido <- vroom(
  simples,
  delim = ";",
  col_names = vars_simples,
  col_types = cols(
    cnpj_basico          = col_character(),
    opcao_simples        = col_character(),
    data_opcao_simples   = col_date(format = "%Y%m%d"),
    data_exclusao_simples = col_date(format = "%Y%m%d"),
    opcao_mei            = col_character(),
    data_opcao_mei       = col_date(format = "%Y%m%d"),
    data_exclusao_mei    = col_date(format = "%Y%m%d")
  ),
  na = c("", "00000000"),
  show_col_types = FALSE,
  locale = locale(encoding = "latin1")
)

# Ordena para favorecer a compressão
simples_lido %>%
  arrange(data_opcao_simples, data_opcao_mei) %>%
  write_parquet(
    sink = file.path(diretorio_parquet, "simples.parquet"),
    compression = "gzip",
    compression_level = 9
  )
  
rm(simples_lido)
gc()  

###################################
## Verificação do arquivo
###################################

simples_teste <- read_parquet(
  file.path(diretorio_parquet, "simples.parquet")
)

glimpse(simples_teste)



############################################################
## Exportação dos arquivos Parquet para Stata (.dta)
############################################################
#
# ETAPA OPCIONAL
#
# Este bloco foi desenvolvido porque versões anteriores do
# Stata não permitiam importar diretamente arquivos Parquet.
#
# A conversão para .dta foi mantida para compatibilidade
# com versões anteriores do Stata e como formato alternativo
# de disponibilização dos dados processados.
#
# As bases de Empresas, Estabelecimentos e Sócios são
# exportadas em arquivos separados, correspondentes aos
# arquivos Parquet, para reduzir o consumo de memória.
#
# ATENÇÃO:
# Cada arquivo Parquet é carregado integralmente na memória
# antes de ser exportado. Portanto, cada arquivo individual
# ainda precisa caber na memória RAM disponível.
#
############################################################

##################################
## Função de exportação
##################################

exportar_stata <- function(base) {
  
  origem <- file.path(diretorio_parquet, base)
  destino <- file.path(diretorio_stata, base)
  
  arquivos <- list.files(
    origem,
    pattern = "\\.parquet$",
    full.names = TRUE
  )
  
  if (length(arquivos) == 0) {
    stop("Nenhum arquivo Parquet encontrado em: ", origem)
  }
  
  dir.create(destino, recursive = TRUE,
             showWarnings = FALSE)
  
  for (arquivo in arquivos) {
    
    nome <- tools::file_path_sans_ext(basename(arquivo))
    
    message("Exportando: ", nome)
    
    dados <- arrow::read_parquet(arquivo)
    
    haven::write_dta(
      dados,
      file.path(destino, paste0(nome, ".dta")),
      version = 14
    )
    
    rm(dados)
    gc()
  }
}

##################################
## Exportação das três bases
##################################

exportar_stata("empresas")
exportar_stata("estabelecimentos")
exportar_stata("socios")

##################################
## Simples
##################################

simples_st <- arrow::read_parquet(
  file.path(diretorio_parquet, "simples.parquet")
)

haven::write_dta(
  simples_st,
  file.path(diretorio_stata, "simples.dta"),
  version = 14
)

rm(simples_st)
gc()