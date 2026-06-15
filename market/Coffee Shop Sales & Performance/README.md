# Coffee Shop Sales & Performance

> **Specialization Intelligence**
> · 3 stores · Jan–Jun 2023 · Maven Analytics Dataset

---

## 🖼️ Dashboard Preview

[📄 Ver Dashboard em PDF](./coffee_shop_dashboard.pdf)

---

## 🧩 Problema de Negócio

Identificar o padrão de especialização de cada loja por turno (manhã, tarde, noite) e definir estratégia de estoque e operação baseada em volume de tráfego — não em ticket médio.

---

## 🛠️ Ferramentas

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![DAX](https://img.shields.io/badge/DAX-Measures%20%7C%20Time%20Intelligence-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![Maven](https://img.shields.io/badge/Dataset-Maven%20Analytics-6C3483?style=flat-square)

- **Power BI** — dashboard interativo com visual HTML customizado
- **DAX** — measures de volume, participação por turno e ranking de produtos
- **Dataset** — Maven Analytics (Jan–Jun 2023)

---

## 💡 Principais Insights

| # | Insight | Impacto |
|---|---|---|
| 1 | **Ticket médio uniforme** entre todas as lojas e turnos | Spread máximo de **$0.36** — preço não é diferencial |
| 2 | A vantagem competitiva é **volume de tráfego**, não preço | Foco operacional deve mudar de margem para capacidade |
| 3 | **Lower Manhattan** domina a manhã com **29.455 transações** | 7.1x seu próprio volume noturno — especialização clara |
| 4 | **Astoria** lidera tarde e noite | Distribuição mais equilibrada das três lojas |
| 5 | **Hell's Kitchen** com performance consistente nos três turnos | Sem liderança clara — maior flexibilidade operacional |

---

## 🎯 Estratégia

> **Especialização por turno — cada loja dobra a aposta no turno que já vence, em vez de tentar corrigir turnos fracos.**

| Loja | Turno de Pico | Ação |
|---|---|---|
| Lower Manhattan | Manhã | Máximo estoque e equipe antes das 10h |
| Astoria | Tarde / Noite | Cardápio e promoções voltados ao fim do dia |
| Hell's Kitchen | Distribuído | Operação flexível com foco no horário de maior margem |

---

## 📁 Estrutura do Projeto

```
market/Coffee Shop Sales & Performance/
├── coffee_shop_performance.pbix   — dashboard Power BI
├── coffee_shop_dashboard.pdf      — preview do dashboard
└── README.md                      — documentação
```

---

<sub>Dataset: Maven Analytics — Coffee Shop Sales | Análise: Leonardo Freire Dias</sub>
