# Super League Monte-Carlo-Simulation

Stochastische Simulation der Schweizer Super League in R: 10'000 komplette
Saisons werden simuliert, um für jedes Team die Wahrscheinlichkeit für
Meistertitel, Abstieg und jede einzelne Tabellenposition zu schätzen.

Semesterarbeit im Modul **Wahrscheinlichkeitsrechnen**, ZHAW (BSc Data Science).

**Autoren:** Fabian Egli, Noa Medved, Andreas Minder

## Modell

| Komponente | Umsetzung |
|---|---|
| Datenbasis | Tore erzielt / kassiert der 12 Teams aus den letzten 3 Saisons (je 33 Spieltage = 99 Spiele) |
| Tore pro Spiel | Poisson-verteilt, λ = Mittel aus eigener Angriffs- und gegnerischer Abwehrstärke |
| Rote Karten | Poisson (λ = 0.159) pro Team und Spiel, jede Karte senkt λ um 10 % |
| Tagesform / Heimvorteil | Gleichverteilt: Heim U[0.9, 1.3], Auswärts U[0.8, 1.2] |
| Formfaktor | Punkte der letzten 5 Spiele → Faktor 0.85 – 1.15 |
| Wetter | Normalverteilter Störfaktor, in 5 %-Schritten gerundet |
| Spielplan | 4 Durchgänge → 264 Spiele, 44 pro Team (22 Heim / 22 Auswärts) |
| Tabelle | Punkte → Tordifferenz → erzielte Tore |

## Ergebnisse (10'000 Saisons, `set.seed(123)`)

| Pos | Team | Ø Punkte | P(Meister) | P(Platz 12) |
|---:|---|---:|---:|---:|
| 1 | YB | 68.2 | 19.9 % | 0.9 % |
| 2 | St. Gallen | 66.4 | 15.2 % | 1.1 % |
| 3 | Basel | 66.4 | 14.5 % | 1.6 % |
| 4 | Lugano | 65.2 | 12.5 % | 1.6 % |
| 5 | Servette | 64.2 | 10.7 % | 2.1 % |
| 6 | Thun | 62.9 | 9.3 % | 3.3 % |
| 7 | Luzern | 62.1 | 7.7 % | 3.7 % |
| 8 | Lausanne | 59.1 | 3.9 % | 6.1 % |
| 9 | Zürich | 57.7 | 2.9 % | 7.9 % |
| 10 | Sion | 56.6 | 2.4 % | 9.8 % |
| 11 | GC | 52.1 | 0.7 % | 20.1 % |
| 12 | Winterthur | 47.1 | 0.2 % | 41.8 % |

Auffällig: Selbst der Favorit YB wird nur in rund jeder fünften Saison Meister.
Das Mittelfeld liegt so eng beisammen, dass der Zufall einen grossen Teil der
Tabelle bestimmt. Beim Abstieg ist das Bild deutlich klarer.

## Dateien

| Datei | Inhalt |
|---|---|
| `superleague_simulation.R` | Komplette Simulation, gibt Tabellen aus und exportiert sie als CSV |
| `praesentation.qmd` | Quarto-Präsentation (revealjs) mit Grafiken: Punkteverlauf, Endtabelle, Meister- und Abstiegswahrscheinlichkeiten |

## Ausführen

```r
Rscript superleague_simulation.R
```

Präsentation rendern (benötigt [Quarto](https://quarto.org) sowie `ggplot2` und `reshape2`):

```bash
quarto render praesentation.qmd
```

## Limitationen & mögliche Erweiterungen

- 44 statt 38 Spiele (symmetrischer Spielplan statt Liga-Teilung nach 33 Runden)
- Keine Verletzungen, rote Karten wirken nur im aktuellen Spiel
- Erweiterungen: korrekter 38-Spiele-Modus, Sperren über mehrere Spiele, Verletzungen
