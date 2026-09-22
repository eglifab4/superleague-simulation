# =============================================================
#  Super League Monte-Carlo: 10'000 Saisons
#  Output: Durchschnittspunkte + Positions-Wahrscheinlichkeiten
# =============================================================

# ---- 1) Team-Statistiken ------------------------------------
teams         <- c("YB", "Basel", "Servette", "Lugano", "St_Gallen",
                   "Luzern", "Lausanne", "Zuerich", "GCZ", "Winterthur",
                   "Sion", "Thun")
tore_erzielt  <- c(181, 164, 162, 159, 163, 166, 142, 133, 110, 122, 132, 171)
tore_kassiert <- c(134, 128, 138, 129, 127, 158, 149, 146, 156, 203, 151, 153)
n_teams       <- length(teams)

avg_tore      <- tore_erzielt  / 99
avg_gegentore <- tore_kassiert / 99

# ---- 2) Spielplan einmalig generieren -----------------------
build_spielplan <- function() {
  heim <- integer(0)
  ausw <- integer(0)
  for (durchgang in 1:4) {
    if (durchgang %% 2 == 1) {
      for (i in 1:(n_teams - 1)) {
        for (j in (i + 1):n_teams) {
          heim <- c(heim, i); ausw <- c(ausw, j)
        }
      }
    } else {
      for (i in n_teams:2) {
        for (j in (i - 1):1) {
          heim <- c(heim, i); ausw <- c(ausw, j)
        }
      }
    }
  }
  list(heim = heim, ausw = ausw)
}

sp       <- build_spielplan()
heim_idx <- sp$heim
ausw_idx <- sp$ausw
n_spiele <- length(heim_idx)
cat("Spielplan:", n_spiele, "Spiele,", n_spiele * 2 / n_teams, "pro Team\n\n")


# ---- 3) Eine Saison simulieren ------------------------------
# Gibt nur Punkte + Rang zurück
simuliere_saison <- function() {
  
  punkte     <- integer(n_teams)
  tordiff    <- integer(n_teams)   # nur intern für Tiebreaker
  tore_plus  <- integer(n_teams)   # nur intern für Tiebreaker
  letzte5    <- matrix(0L, nrow = n_teams, ncol = 5)
  l5_count   <- integer(n_teams)
  
  # Zufallszahlen vorab vektorisiert
  rk_h   <- rpois(n_spiele, 0.159)
  rk_a   <- rpois(n_spiele, 0.159)
  tf_h   <- runif(n_spiele, 0.9, 1.3)
  tf_a   <- runif(n_spiele, 0.8, 1.2)
  roh    <- rnorm(n_spiele, 1, 0.0667)
  wetter <- 1 - abs(round(roh / 0.05) * 0.05 - 1)
  
  for (k in seq_len(n_spiele)) {
    h <- heim_idx[k]; a <- ausw_idx[k]
    
    if (l5_count[h] >= 5 && l5_count[a] >= 5) {
      form_h <- 0.85 + (sum(letzte5[h, ]) / 15) * 0.30
      form_a <- 0.85 + (sum(letzte5[a, ]) / 15) * 0.30
    } else {
      form_h <- 1; form_a <- 1
    }
    
    lam_h <- (avg_tore[h] + avg_gegentore[a]) / 2 *
      0.9^rk_h[k] * form_h * wetter[k] * tf_h[k]
    lam_a <- (avg_tore[a] + avg_gegentore[h]) / 2 *
      0.9^rk_a[k] * form_a * wetter[k] * tf_a[k]
    
    th <- rpois(1, lam_h)
    ta <- rpois(1, lam_a)
    
    if (th > ta) {
      pkt_h <- 3L; pkt_a <- 0L
    } else if (th < ta) {
      pkt_h <- 0L; pkt_a <- 3L
    } else {
      pkt_h <- 1L; pkt_a <- 1L
    }
    
    punkte[h]    <- punkte[h]    + pkt_h
    punkte[a]    <- punkte[a]    + pkt_a
    tordiff[h]   <- tordiff[h]   + (th - ta)
    tordiff[a]   <- tordiff[a]   + (ta - th)
    tore_plus[h] <- tore_plus[h] + th
    tore_plus[a] <- tore_plus[a] + ta
    
    pos_h <- (l5_count[h] %% 5) + 1L
    pos_a <- (l5_count[a] %% 5) + 1L
    letzte5[h, pos_h] <- pkt_h
    letzte5[a, pos_a] <- pkt_a
    l5_count[h] <- l5_count[h] + 1L
    l5_count[a] <- l5_count[a] + 1L
  }
  
  o <- order(-punkte, -tordiff, -tore_plus)
  rang <- integer(n_teams)
  rang[o] <- seq_len(n_teams)
  
  list(punkte = punkte, rang = rang)
}

# ---- 4) Monte-Carlo: N Saisons ------------------------------
set.seed(123)   # gleicher Seed wie in der Präsentation -> reproduzierbar
N <- 10000

rang_matrix   <- matrix(0L, nrow = N, ncol = n_teams,
                        dimnames = list(NULL, teams))
punkte_matrix <- matrix(0L, nrow = N, ncol = n_teams,
                        dimnames = list(NULL, teams))

t0 <- Sys.time()
for (s in 1:N) {
  res <- simuliere_saison()
  punkte_matrix[s, ] <- res$punkte
  rang_matrix[s, ]   <- res$rang
  if (s %% 1000 == 0) {
    cat("Saison", s, "/", N,
        "  Zeit bisher:", round(difftime(Sys.time(), t0, units = "secs"), 1),
        "s\n")
  }
}
cat("\nGesamtzeit:", round(difftime(Sys.time(), t0, units = "secs"), 1), "Sekunden\n\n")

# ---- 5) Durchschnitts-Tabelle -------------------------------
avg_punkte <- colMeans(punkte_matrix)
avg_rang   <- colMeans(rang_matrix)

durchschnitt <- data.frame(
  team       = teams,
  avg_punkte = round(avg_punkte, 2),
  avg_rang   = round(avg_rang, 2)
)
durchschnitt <- durchschnitt[order(-durchschnitt$avg_punkte), ]
rownames(durchschnitt) <- NULL
durchschnitt$pos <- seq_len(n_teams)
durchschnitt <- durchschnitt[, c("pos", "team", "avg_punkte", "avg_rang")]

cat("=== Durchschnittstabelle (10'000 Saisons) ===\n")
print(durchschnitt)

# ---- 6) Positions-Wahrscheinlichkeits-Matrix ----------------
# Zeile = Team, Spalte = Tabellenposition (1..12)
# Zelle = P(Team landet auf dieser Position) in %
pos_wkt <- matrix(0, nrow = n_teams, ncol = n_teams,
                  dimnames = list(teams, paste0("Pos_", 1:n_teams)))

for (i in seq_len(n_teams)) {
  for (p in seq_len(n_teams)) {
    pos_wkt[i, p] <- mean(rang_matrix[, i] == p) * 100
  }
}

pos_wkt_df <- as.data.frame(round(pos_wkt, 2))
pos_wkt_df$team <- rownames(pos_wkt_df)
pos_wkt_df <- pos_wkt_df[, c("team", paste0("Pos_", 1:n_teams))]
# Nach durchschnittlichem Rang sortieren
pos_wkt_df <- pos_wkt_df[order(avg_rang), ]
rownames(pos_wkt_df) <- NULL

cat("\n=== Wahrscheinlichkeit pro Tabellenposition (in %) ===\n")
print(pos_wkt_df)

# Plausibilitätscheck: jede Zeile muss zu 100% summieren
cat("\nPlausibilitätscheck (Zeilensummen, sollten alle 100 sein):\n")
print(rowSums(pos_wkt))

# ---- 7) Optional als CSV exportieren ------------------------
write.csv(durchschnitt,
          "durchschnittstabelle.csv", row.names = FALSE)
write.csv(pos_wkt_df,
          "positions_wahrscheinlichkeiten.csv", row.names = FALSE)
cat("\nCSV-Dateien gespeichert.\n")
