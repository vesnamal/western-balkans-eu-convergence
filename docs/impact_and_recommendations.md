# Impact Estimation & Recommendations

*Western Balkans → EU Convergence. All figures query-verified against the project marts (`wb_fct_gap_to_eu`, `wb_fct_years_to_close`, `wb_fct_governance`), 2024 reference year.*

---

## Impact estimation: what closing the productivity gap would take?

This is a best-case *ceiling*, not a forecast. Holding each country's current productivity gap fixed, I recomputed its years-to-close as if productivity were converging at the same pace that country's **income** actually did over 2014–2024. It borrows income's own observed speed and asks what that speed would buy productivity, nothing more.

The scenario reduces to one line, `scenario_years = productivity_gap × income_years ÷ income_gap`, using raw indicator codes (`SL.GDP.PCAP.EM.KD` for productivity, `NY.GDP.PCAP.PP.KD` for income). No new regression is introduced. Results were verified two ways: SQL and hand-calculation.

| Country | Current (years) | Best-case scenario (years) |
|---|---|---|
| Serbia | 146.1 | 42.8 |
| Albania | 144.9 | 54.7 |
| Montenegro | 127.9 | 91.8 |
| Bosnia and Herzegovina | 106.1 | 86 |

The result is sobering rather than encouraging. Even borrowing income's own best pace, three of the four stay 54–92 years out; only Serbia reaches something within a working lifetime, and only because its income has closed unusually fast. Productivity is therefore not a marginal problem that faster income growth will eventually pull along. It is a deep, separate constraint. Income convergence, which looks like the success story on the headline chart, cannot on its own carry these economies to EU productivity levels.

*Montenegro's figure is approximate: its productivity series carries a flagged 2021 artifact; excluding 2021 lengthens the current timeline toward ~150 years, which does not change the conclusion.*

---

## Finding 1 / Economy: income is converging, productivity and jobs are not

All six candidates closed income gaps over 2014–2024 (+4.8 to +11 pts). But productivity is flat or near-flat and is what carries the century-plus timelines, and unemployment is the only one of the four convergence dimensions still **worsening** -- dispersion across the six bottomed in 2023 and rebounded in 2024 (coefficient of variation 0.167 → 0.190), meaning the countries are diverging again on jobs. Income flatters the picture; the two axes underneath it do not move with it.

## Finding 2 / Governance: not a bloc problem

Candidate governance scrambles the expected ranking. Montenegro out-scores Bulgaria, an existing EU member, on rule of law every year in the panel, and Kosovo, after a decade below Bulgaria, overtakes it for the first time in 2024. Yet Serbia, one of the fastest income convergers, has the weakest control-of-corruption score of all ten countries analyzed (36.5, just below Bosnia's 37.5). Governance quality and economic convergence are not tightly coupled; a candidate can lead on governance while diverging on jobs, or race ahead economically while lagging on corruption. Treatment has to be country-specific, not regional.

---

## Recommendations

Descriptive study — these identify what the data says to prioritize and watch, not policy prescriptions, which would require causal analysis this project does not contain. Grouped by country, because the shared finding (productivity is the binding constraint) is already stated above; what follows is what is *different* about each.

- **Serbia**: income is closing fast, so the risk is not growth but that the weakest control-of-corruption score of all ten (36.5) goes unaddressed while the headline looks healthy. Prioritize governance, not convergence pace.
- **North Macedonia**: the only candidate stuck on *both* axes: slowest income convergence (+4.82 pts) and productivity so flat (slope 0.009) that no closing timeline can be estimated at all. This is not a long timeline like the others; it is the absence of one. Structural reform, not a tune-up.
- **Montenegro**: leads the region on rule of law but has the worst jobs trajectory of the six. The decade-long divergence, however, reverses after 2020 (the gap narrows every year 2020-2024), so the priority is to protect and monitor that recovery rather than treat unemployment as a lost cause.
- **Albania**: the strongest income gain (+11.06) masks a stalled labour market and a 145-year productivity timeline. Do not let the income headline set the agenda; the binding constraints here are jobs and productivity.
- **Kosovo**: the data gap *is* the finding: productivity is unmeasurable (null on `SL.GDP.PCAP.EM.KD`). The first recommendation is measurement: get the productivity series reported, because a convergence that cannot be seen cannot be managed. Governance is the bright spot (2024 rule-of-law overtake of Bulgaria).
- **Bosnia and Herzegovina**: the least-bad productivity timeline of the four (106 years) but still century-plus, alongside the second-weakest control-of-corruption of the ten. Two constraints, both real.

---

## For researchers and accession analysts

The reusable contribution is the framework, not just the findings: a gap-to-EU index, sigma-convergence (dispersion over time), and slope-based years-to-close, benchmarked against the four most recent EU entrants (Bulgaria, Romania, Croatia & Slovenia) rather than an abstract EU average. That "compare candidates to the countries recently in their position" framing is transferable to other candidate sets (Ukraine, Moldova, Georgia). The project also documents a clean negative result worth building on: shared ex-Yugoslav starting conditions do **not** predict convergence trajectories. The anomalies surfaced here: Montenegro's unemployment reversal, Kosovo's missing productivity data, and Serbia's fast-growth/weak-governance paradox, each warrant dedicated study.