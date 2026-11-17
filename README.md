# Previsão meteorológica de 7 dias em R

Projeto em **R** para consultar e resumir a previsão do tempo dos próximos sete dias, **incluindo o dia da consulta**, em cidades de diferentes países. A aplicação usa a [Open-Meteo](https://open-meteo.com/) para localizar a cidade, obter dados meteorológicos e exportar uma tabela em CSV.

## Funcionalidades

- Consulta automática das coordenadas de uma cidade pela **Geocoding API**.
- Previsão de sete dias pela **Forecast API**, no fuso horário da localidade.
- Temperaturas mínima e máxima diárias (°C).
- Umidade relativa média diária (%), calculada pela média dos valores horários previstos.
- Precipitação diária prevista (mm).
- Maior probabilidade **horária** de precipitação de cada dia (%).
- Velocidade máxima diária do vento a 10 m (km/h).
- Resumo no Console do R e exportação de resultados para CSV, utilizável no Excel.

## Requisitos

- R instalado (RStudio é opcional, mas recomendado).
- Acesso à internet.
- Pacotes `httr` e `jsonlite`: o script tenta instalá-los automaticamente se necessário.

Não é preciso configurar uma chave de API para o uso gratuito não comercial permitido pela Open-Meteo; consulte as condições de uso do serviço.

## Como utilizar

1. Baixe ou clone este repositório.
2. Abra o arquivo `previsao_7_dias.R` no RStudio.
3. Altere o nome da cidade na seção **1. ALTERE SOMENTE O NOME DA CIDADE**:

   ```r
   cidade <- "Alegre"
   ```

4. Opcionalmente, informe a sigla ISO do país para reduzir ambiguidades:

   ```r
   pais <- "BR"
   ```

5. Execute o arquivo pelo botão **Source** no RStudio ou pelo Console:

   ```r
   source("previsao_7_dias.R", encoding = "UTF-8")
   ```

6. Confira a mensagem **Cidade identificada:**, que informa nome, estado/província e país da localidade selecionada.
7. Veja a previsão no Console. O arquivo `previsao_7_dias.csv` será gerado na pasta atual, indicada pelo comando `getwd()`.

Para visualizar a tabela no RStudio após a execução:

```r
View(tabela)
```

### Exemplos de cidades

```r
cidade <- "Ipatinga"
pais <- "BR"
```

```r
cidade <- "Toronto"
pais <- "CA"
```

```r
cidade <- "Lisboa"
pais <- "PT"
```

**Atenção:** o código seleciona automaticamente o **primeiro resultado** de geocodificação. Em cidades homônimas, definir o país não garante a identificação do estado/província correto. Sempre confira a localização apresentada no Console antes de utilizar os dados.

## Arquivos

```text
previsao-meteorologica-7-dias-r/
├── previsao_7_dias.R   # Consulta, processamento e exportação
├── README.md           # Documentação
└── .gitignore          # Arquivos locais ignorados
```

## Interpretação e limitações

- As informações são **previsões de modelos**, não observações meteorológicas; podem mudar de uma consulta para outra.
- A probabilidade de precipitação apresentada é o **maior valor horário** de cada dia, **não** a probabilidade de chover em algum momento do dia inteiro.
- A umidade relativa média é calculada a partir de valores horários previstos.
- Os sete dias incluem a data da consulta, segundo o fuso horário identificado.
- A qualidade da previsão pode variar conforme localidade, horizonte temporal e variáveis.
- A busca automática pode selecionar outra cidade homônima; confira o local identificado.
- Este projeto não inclui validação estatística da acurácia das previsões.

## Fontes de dados

- [Open-Meteo — Forecast API](https://open-meteo.com/en/docs)
- [Open-Meteo — Geocoding API](https://open-meteo.com/en/docs/geocoding-api)
- [Open-Meteo — Termos de uso](https://open-meteo.com/en/terms)

## Validação

Foi realizada uma execução no RStudio com a cidade de **Alegre, Espírito Santo, Brasil**, exibindo resultados para sete dias e gerando CSV. A publicação desta versão não inclui uma suíte de testes automatizados nem validação independente contra observações meteorológicas.
