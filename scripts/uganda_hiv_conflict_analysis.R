# ==========================================================
# Uganda HIV Burden and Conflict Exposure Analysis
# UCDP GED + Uganda AIDS Commission HIV Estimates (2023)
#
# Author: Parisa Ayoubi, MPH
#
# Purpose:
# To examine the relationship between HIV burden
# and conflict exposure across Ugandan districts
# by integrating district-level HIV estimates with
# conflict event and fatality data from the UCDP
# Georeferenced Event Dataset.
#
# Research Questions:
# - Is HIV prevalence associated with conflict
#   fatalities?
# - Is HIV prevalence associated with conflict
#   event frequency?
# - Does ART coverage vary across districts with
#   differing levels of conflict exposure?
#
# Data Sources:
# Uganda AIDS Commission
# Sub-National HIV Estimates (2023)
#
# Uppsala Conflict Data Program (UCDP)
# Georeferenced Event Dataset (GED) Version 26.1
#
# Outputs:
# - HIV prevalence vs conflict fatalities
# - HIV prevalence vs conflict events
# - ART coverage vs conflict fatalities
# - Top HIV prevalence districts
# - Top conflict fatality districts
# - Merged district-level analysis dataset
# ==========================================================

# load packages
library(readxl)
library(dplyr)
library(ggplot2)

# plot colors
low_color  <- "#f8ede3"
mid_color  <- "#c97c5d"
high_color <- "#9d3d2d"

# load HIV data
hiv <- read_excel(
  "~/Desktop/Sub_National_HIV_Estimates_2023.xlsx",
  skip = 1
)

names(hiv) <- c(
  "district",
  "hiv_prev",
  "plhiv",
  "hiv_infections",
  "art_coverage"
)

hiv <- hiv %>%
  mutate(
    district = trimws(district)
  )

# verify data types
sapply(hiv, class)

# load conflict data
ged <- read_excel(
  "~/Desktop/GEDEvent_v26_1.xlsx"
)

uganda <- ged %>%
  filter(country == "Uganda")

# conflict totals by district
conflict_district <- uganda %>%
  filter(!is.na(adm_1)) %>%
  group_by(adm_1) %>%
  summarize(
    conflict_events = n(),
    fatalities = sum(best, na.rm = TRUE),
    .groups = "drop"
  )

# remove district suffix
conflict_district <- conflict_district %>%
  mutate(
    adm_1 = gsub(
      " district",
      "",
      adm_1,
      ignore.case = TRUE
    )
  )

# harmonize district names
hiv <- hiv %>%
  mutate(
    district_merge = district
  )

hiv$district_merge[hiv$district == "Arua City"] <- "Arua"
hiv$district_merge[hiv$district == "Fort Portal City"] <- "Kabarole"
hiv$district_merge[hiv$district == "Gulu City"] <- "Gulu"
hiv$district_merge[hiv$district == "Jinja City"] <- "Jinja"
hiv$district_merge[hiv$district == "Lira City"] <- "Lira"
hiv$district_merge[hiv$district == "Masaka City"] <- "Masaka"
hiv$district_merge[hiv$district == "Mbale City"] <- "Mbale"
hiv$district_merge[hiv$district == "Mbarara City"] <- "Mbarara"
hiv$district_merge[hiv$district == "Soroti City"] <- "Soroti"

# merge datasets
uganda_analysis <- hiv %>%
  left_join(
    conflict_district,
    by = c(
      "district_merge" = "adm_1"
    )
  )

# merge diagnostics
cat(
  "Matched districts:",
  sum(!is.na(uganda_analysis$fatalities)),
  "\n"
)

cat(
  "Unmatched districts:",
  sum(is.na(uganda_analysis$fatalities)),
  "\n"
)

# top HIV districts
top_hiv <- uganda_analysis %>%
  arrange(desc(hiv_prev)) %>%
  select(
    district,
    hiv_prev,
    plhiv,
    hiv_infections,
    art_coverage
  )

print(head(top_hiv, 20))

# correlations
correlation_fatalities <- cor(
  uganda_analysis$hiv_prev,
  uganda_analysis$fatalities,
  use = "complete.obs"
)

cat(
  "Correlation between HIV prevalence and fatalities:",
  round(correlation_fatalities, 3),
  "\n"
)

correlation_events <- cor(
  uganda_analysis$hiv_prev,
  uganda_analysis$conflict_events,
  use = "complete.obs"
)

cat(
  "Correlation between HIV prevalence and conflict events:",
  round(correlation_events, 3),
  "\n"
)

# conflict level analysis
uganda_analysis <- uganda_analysis %>%
  mutate(
    conflict_level = case_when(
      fatalities >= 500 ~ "High",
      fatalities >= 100 ~ "Medium",
      fatalities > 0 ~ "Low",
      TRUE ~ "None"
    )
  )

uganda_analysis %>%
  group_by(conflict_level) %>%
  summarize(
    districts = n(),
    mean_hiv_prev = mean(
      hiv_prev,
      na.rm = TRUE
    ),
    mean_art_coverage = mean(
      art_coverage,
      na.rm = TRUE
    )
  ) %>%
  print()

# high HIV + high conflict districts
high_risk <- uganda_analysis %>%
  filter(
    hiv_prev >= quantile(
      hiv_prev,
      0.75,
      na.rm = TRUE
    ),
    fatalities >= quantile(
      fatalities,
      0.75,
      na.rm = TRUE
    )
  ) %>%
  arrange(
    desc(fatalities)
  ) %>%
  select(
    district,
    hiv_prev,
    fatalities,
    conflict_events,
    art_coverage
  )

print(high_risk)

# PLOT 1: HIV prevalence vs fatalities
plot_hiv_fatalities <- ggplot(
  uganda_analysis,
  aes(
    x = fatalities,
    y = hiv_prev
  )
) +
  
  geom_point(
    size = 3,
    alpha = 0.7,
    color = high_color
  ) +
  
  geom_smooth(
    method = "lm",
    se = TRUE,
    color = high_color,
    fill = low_color
  ) +
  
  labs(
    title = "HIV Prevalence vs Conflict Fatalities",
    subtitle = "District-level HIV burden and conflict mortality",
    x = "Conflict Fatalities",
    y = "HIV Prevalence (%)"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    panel.grid.minor = element_blank()
  )

plot_hiv_fatalities

# PLOT 2: HIV prevalence vs conflict events
plot_hiv_events <- ggplot(
  uganda_analysis,
  aes(
    x = conflict_events,
    y = hiv_prev
  )
) +
  
  geom_point(
    size = 3,
    alpha = 0.7,
    color = high_color
  ) +
  
  geom_smooth(
    method = "lm",
    se = TRUE,
    color = high_color,
    fill = low_color
  ) +
  
  labs(
    title = "HIV Prevalence vs Conflict Events",
    subtitle = "District-level HIV burden and conflict exposure",
    x = "Conflict Events",
    y = "HIV Prevalence (%)"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    panel.grid.minor = element_blank()
  )

plot_hiv_events

# PLOT 3: ART coverage vs fatalities
plot_art_fatalities <- ggplot(
  uganda_analysis,
  aes(
    x = fatalities,
    y = art_coverage
  )
) +
  
  geom_point(
    size = 3,
    alpha = 0.7,
    color = high_color
  ) +
  
  geom_smooth(
    method = "lm",
    se = TRUE,
    color = high_color,
    fill = low_color
  ) +
  
  labs(
    title = "ART Coverage vs Conflict Fatalities",
    subtitle = "District-level treatment coverage and conflict burden",
    x = "Conflict Fatalities",
    y = "ART Coverage (%)"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    panel.grid.minor = element_blank()
  )

plot_art_fatalities

# top HIV districts
plot_top_hiv <- uganda_analysis %>%
  arrange(desc(hiv_prev)) %>%
  distinct(
    district_merge,
    .keep_all = TRUE
  ) %>%
  slice(1:15) %>%
  ggplot(
    aes(
      x = reorder(
        district_merge,
        hiv_prev
      ),
      y = hiv_prev
    )
  ) +
  
  geom_col(
    fill = high_color
  ) +
  
  coord_flip() +
  
  labs(
    title = "Top 15 Districts by HIV Prevalence",
    subtitle = "Uganda HIV Estimates, 2023",
    x = "",
    y = "HIV Prevalence (%)"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    panel.grid.minor = element_blank()
  )

plot_top_hiv

# top conflict districts
plot_top_conflict <- uganda_analysis %>%
  filter(!is.na(fatalities)) %>%
  arrange(desc(fatalities)) %>%
  distinct(
    district_merge,
    .keep_all = TRUE
  ) %>%
  slice(1:15) %>%
  ggplot(
    aes(
      x = reorder(
        district_merge,
        fatalities
      ),
      y = fatalities
    )
  ) +
  
  geom_col(
    fill = high_color
  ) +
  
  coord_flip() +
  
  labs(
    title = "Top 15 Districts by Conflict Fatalities",
    subtitle = "UCDP GED Events, 1989–2024",
    x = "",
    y = "Fatalities"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    panel.grid.minor = element_blank()
  )

plot_top_conflict

# export final dataset
write.csv(
  uganda_analysis,
  "~/Desktop/uganda_hiv_conflict_analysis.csv",
  row.names = FALSE
)

# save figures
ggsave(
  "~/Desktop/github projects/hiv_prevalence_vs_conflict_fatalities.png",
  plot = plot_hiv_fatalities,
  width = 10,
  height = 8,
  dpi = 300
)

ggsave(
  "~/Desktop/github projects/hiv_prevalence_vs_conflict_events.png",
  plot = plot_hiv_events,
  width = 10,
  height = 8,
  dpi = 300
)

ggsave(
  "~/Desktop/github projects/art_coverage_vs_conflict_fatalities.png",
  plot = plot_art_fatalities,
  width = 10,
  height = 8,
  dpi = 300
)

ggsave(
  "~/Desktop/github projects/top_hiv_prevalence_districts.png",
  plot = plot_top_hiv,
  width = 10,
  height = 8,
  dpi = 300
)

ggsave(
  "~/Desktop/github projects/top_conflict_fatality_districts.png",
  plot = plot_top_conflict,
  width = 10,
  height = 8,
  dpi = 300
)