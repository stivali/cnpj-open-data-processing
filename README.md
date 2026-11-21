# Processing Brazil's Public CNPJ Data in R

**R scripts for converting publicly available CNPJ records to Parquet, with optional export to Stata (`.dta`).**

This repository contains code to process the public **Cadastro Nacional da Pessoa Jurídica (CNPJ)** datasets released by the Brazilian Federal Revenue Service (*Receita Federal do Brasil*). It reads the original compressed ZIP files, defines variable types, converts selected date fields, and writes the results in Apache Parquet format. An optional final step exports the Parquet files to Stata format.

The scripts were originally developed in June 2024 by **Matheus Stivali and Yohan Rocha** and revised by **Matheus Stivali** in November 2026. An earlier Stata processing program by André Gambier Campos is acknowledged in the project history.

## Repository contents

```text
.
├── README.md
├── .gitignore
├── code/
│   ├── leitura_CNPJ_dados_abertos.R
│   └── limpeza_arquivos_temporarios.R
└── docs/
    └── cnpj-metadados.pdf
```

- **`code/leitura_CNPJ_dados_abertos.R`** — imports and converts the four main CNPJ datasets (Companies, Establishments, Partners, and Simples/MEI); optionally exports the resulting Parquet files to Stata.
- **`code/limpeza_arquivos_temporarios.R`** — a separate, Windows-oriented utility for inspecting disk space consumed by temporary R files and manually cleaning up old session directories. Deletion commands are commented out by default.
- **`docs/cnpj-metadados.pdf`** — *Novo Layout para os Dados Abertos do CNPJ*, the original field-layout documentation distributed with the public data by Receita Federal. Consult this document when interpreting column definitions, codes, and data layouts. It is reproduced for reference, not authored by this repository's maintainers.

**Neither the source ZIP files nor the generated Parquet and Stata datasets are included.**

## Data source

The input files are available from the Brazilian government's open data portal:

[Cadastro Nacional da Pessoa Jurídica — CNPJ (dados abertos)](https://dados.gov.br/dados/conjuntos-dados/cadastro-nacional-da-pessoa-juridica---cnpj)

The script processes these four datasets:

| Input files | Contents | Parquet output |
| --- | --- | --- |
| `Empresas0.zip` … `Empresas9.zip` | Company-level information | `empresas/empresas_000.parquet` … `empresas_009.parquet` |
| `Estabelecimentos0.zip` … `Estabelecimentos9.zip` | Establishment-level information | `estabelecimentos/estabelecimentos_000.parquet` … `estabelecimentos_009.parquet` |
| `Socios0.zip` … `Socios9.zip` | Partner/shareholder information | `socios/socios_000.parquet` … `socios_009.parquet` |
| `Simples.zip` | Simples Nacional and MEI status | `simples.parquet` |

The example configuration is for the **November 2026 (`2026-11`)** data release. Other releases may have different file counts or layouts. Auxiliary source files such as CNAE, municipalities, countries, legal natures, reasons, and qualifications are documented in the PDF but **are not processed by the current script**.

## Requirements

- R with the packages **`vroom`**, **`tidyverse`**, **`arrow`**, and **`haven`**. The current script also loads `foreign` in its initialization, although its Stata export uses `haven`.
- Enough free disk space for the downloaded ZIP files, temporary extracted data, and outputs.
- Enough RAM to process each ZIP and, if Stata export is enabled, to load each individual Parquet file into memory.
- A suitable local filesystem. The example paths and temporary-file utility are intended for **Windows**.

Install the relevant packages in R if needed:

```r
install.packages(c("vroom", "tidyverse", "arrow", "haven", "foreign"))
```

## Setup and execution

Keep the large source datasets **outside the Git repository**. At the beginning of `code/leitura_CNPJ_dados_abertos.R`, edit:

```r
diretorio_dados <- "D:/Data/CNPJ"
competencia <- "2026-11"
```

The script constructs the source and output paths with `file.path()`:

```text
D:/Data/CNPJ/
├── zip/
│   └── 2026-11/
│       ├── Empresas0.zip ... Empresas9.zip
│       ├── Estabelecimentos0.zip ... Estabelecimentos9.zip
│       ├── Socios0.zip ... Socios9.zip
│       └── Simples.zip
├── parquet/
│   └── 2026-11/
│       ├── empresas/
│       ├── estabelecimentos/
│       ├── socios/
│       └── simples.parquet
└── stata/
    └── 2026-11/
        ├── empresas/
        ├── estabelecimentos/
        ├── socios/
        └── simples.dta
```

The script creates the output directories as needed. Run the import sections in order from the R script. The Stata export section at the end is **optional** and can be skipped if only Parquet output is required. It writes one `.dta` file per Parquet partition for Companies, Establishments, and Partners; users needing a consolidated dataset can combine the files in Stata if their system has sufficient memory.

The outputs retain CNPJ basic identifiers as strings, including leading zeros. Dates are parsed using the `YYYYMMDD` layout; in the relevant imports, both empty strings and `00000000` are interpreted as missing (`NA`). The missing-value setting applies to all imported columns in those calls, not only date fields. The code also extracts a possible 11-digit CPF from the end of company names into `CPF_MEI`; this is a **text-pattern extraction, not CPF validation or verification of MEI status**.

## Important: temporary disk usage

**Reading ZIP files with `vroom` may create very large temporary extracted files.** During processing of the November 2026 release, temporary disk use was observed in the tens of gigabytes. These files may not be fully removed while R is running, and some can remain after the session ends.

Before running the import, check free disk space. After processing, close unused R sessions and inspect the Windows temporary directory if disk space has not been released. The independent script `code/limpeza_arquivos_temporarios.R` provides commands to inspect `tempdir()` and `%TEMP%` and identify the largest temporary folders. **Do not delete an active R session's temporary directory or folders in use by other processes.**

## Data quality and limitations

- The conversion has been run on the November 2026 data files, but the repository is not a comprehensive audit of the underlying administrative records.
- One `embedded null` parsing warning was observed in a text address field of `Estabelecimentos0.zip`; investigate source-data anomalies if exact record-level fidelity is critical.
- Each ZIP is processed separately and the resulting Parquet files are sorted **within**, not across, partitions. The numeric suffixes identify the input-file processing order, not a range of CNPJ values.
- The optional Stata export uses `haven::write_dta(..., version = 14)`. Each partition is read fully into RAM for export; the single `simples.parquet` file is also loaded in full.
- CNPJ data releases can change over time. Confirm the files and layout of the specific release before reusing the script.

## Privacy and reuse

The repository contains **code and source-layout documentation only**. Generated datasets can include names, contact information, and fields associated with individuals. Treat the data according to applicable privacy, access, and reuse rules. Do not commit source or generated datasets to this repository.

The included layout PDF originates from Receita Federal; attribution to the original public-sector source is retained. No additional license or redistribution rights are asserted here for that document or the source data.
