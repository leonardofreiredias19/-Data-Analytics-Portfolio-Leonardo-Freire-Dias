# Bank Customer Churn Intelligence

> **Quem sai, quanto custa e quem não podemos perder**
> · 10.000 clientes · 12 variáveis · 3 países

---

## 🧩 Problema de Negócio

Identificar o perfil de clientes com maior risco de saída, quantificar o retorno não obtido e definir estratégia de retenção baseada em dados.

---

## 🛠️ Ferramentas

![SQL](https://img.shields.io/badge/SQL-CTEs%20%7C%20Window%20Functions-4479A1?style=flat-square&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-DAX%20%7C%20HTML%20%7C%20Formatação%20Condicional-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![Kaggle](https://img.shields.io/badge/Dataset-Kaggle-20BEFF?style=flat-square&logo=kaggle&logoColor=white)

- **SQL** — CTEs encadeados, window functions
- **Power BI** — DAX, formatação condicional, visual HTML
- **Dataset** — Kaggle (10.000 registros, 12 variáveis)

---

## 💡 Principais Insights

| # | Insight | Impacto |
|---|---|---|
| 1 | **Faixa 46–55 anos** concentra **50.6% do churn** | Maior LTV potencial e maior risco simultâneo |
| 2 | **2 produtos = 8% de churn · 3 produtos = 83%** | O paradoxo dos produtos: mais nem sempre é melhor |
| 3 | **3.547 clientes inativos** ainda na base | Risco silencioso de 35.5% — antes de saírem, já foram |
| 4 | **1.191 clientes ideais identificados** · 79% saíram | Sem o equilíbrio certo de produtos, o melhor perfil vai embora |

---

## 🔬 Metodologia

### LTV Proxy Score

Score composto por 4 componentes ponderados para estimar o valor do cliente ao longo do tempo:

| Componente | Peso |
|---|---|
| Balance (saldo) | 40% |
| Products (número de produtos) | 25% |
| Tenure (tempo de relacionamento) | 20% |
| Salary (salário estimado) | 15% |

### Arquitetura SQL

CTE encadeado em **4 camadas** com window functions para benchmark por perfil:

```
base_clientes
    └── perfil_churn         (segmentação e scoring)
            └── benchmark    (window functions por grupo)
                    └── output_final (ranking e flags estratégicos)
```

---

## 📁 Estrutura do Projeto

```
finance/Bank Customer Churn Intelligence/
├── churn_intelligence.sql   — query completa com 4 CTEs
└── README.md                — documentação
```

---

## 🎯 Conclusão Estratégica

> **Oferecer o segundo produto certo, para o perfil certo — antes que o cliente decida sair.**

Foco em clientes com:
- Faixa etária **36–55 anos**
- Saldo acima de **$100.000**
- Localizados na **Alemanha** ou **França**

Esses clientes representam o maior LTV potencial da base e, ao mesmo tempo, o maior risco de churn — tornando a intervenção proativa o único movimento com ROI positivo garantido.

---

<sub>Dataset: Kaggle — Bank Customer Churn | Análise: Leonardo Freire Dias</sub>
