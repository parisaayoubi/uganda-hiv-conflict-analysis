# ==========================================================
# Uganda Conflict Hotspots Analysis
# UCDP Georeferenced Event Dataset (GED)
#
# Author: Parisa Ayoubi, MPH
#
# Purpose:
# To identify and visualize geographic patterns
# of conflict activity across Uganda using
# georeferenced conflict events from the UCDP GED.
#
# The project maps conflict events, summarizes
# conflict-related fatalities by district, and
# uses kernel density estimation to identify
# conflict hotspots across the country.
#
# Data Source:
# Uppsala Conflict Data Program (UCDP)
# Georeferenced Event Dataset (GED) Version 26.1
#
# Outputs:
# - Conflict events by year
# - Conflict fatalities by year
# - Top districts by conflict fatalities
# - Uganda conflict hotspot map
# ==========================================================

# load packages
library(readxl)
library(dplyr)
library(ggplot2)
library(sf)
library(geodata)
library(ggrepel)

# import data
ged <- read_excel("~/Desktop/GEDEvent_v26_1.xlsx")

# filter to uganda
uganda <- ged %>%
  filter(country == "Uganda")

# basic checks
cat("Number of Uganda events:", nrow(uganda), "\n")

range(uganda$year, na.rm = TRUE)

# conflict events by year
events_year <- uganda %>%
  count(year)

ggplot(
  events_year,
  aes(x = year, y = n)
) +
  geom_line() +
  geom_point() +
  labs(
    title = "Conflict Events in Uganda",
    x = "Year",
    y = "Number of Events"
  ) +
  theme_minimal()

# conflict fatalities by year
fatalities_year <- uganda %>%
  group_by(year) %>%
  summarize(
    fatalities = sum(best, na.rm = TRUE)
  )

ggplot(
  fatalities_year,
  aes(x = year, y = fatalities)
) +
  geom_line() +
  geom_point() +
  labs(
    title = "Conflict Fatalities in Uganda",
    x = "Year",
    y = "Fatalities"
  ) +
  theme_minimal()

# top regions by fatalities
fatalities_region <- uganda %>%
  filter(!is.na(adm_1)) %>%
  group_by(adm_1) %>%
  summarize(
    events = n(),
    fatalities = sum(best, na.rm = TRUE)
  ) %>%
  arrange(desc(fatalities))

print(head(fatalities_region, 20))

# download uganda boundary
uganda_boundary <- geodata::gadm(
  country = "UGA",
  level = 0,
  path = tempdir()
)

uganda_boundary <- st_as_sf(uganda_boundary)

# what is NA? we wanna find out what it encapsulates
uganda %>%
  filter(is.na(adm_1)) %>%
  select(
    year,
    where_description,
    latitude,
    longitude,
    best
  ) %>%
  arrange(desc(best))

# clean vague locations
uganda_clean <- uganda %>%
  filter(!is.na(adm_1))

# major cities
cities <- data.frame(
  city = c(
    "Arua",
    "Gulu",
    "Kitgum",
    "Lira",
    "Soroti",
    "Moroto",
    "Mbale",
    "Kampala",
    "Masaka",
    "Fort Portal",
    "Kasese",
    "Mbarara"
  ),
  
  longitude = c(
    30.91,  # Arua
    32.30,  # Gulu
    32.89,  # Kitgum
    32.90,  # Lira
    33.61,  # Soroti
    34.67,  # Moroto
    34.18,  # Mbale
    32.58,  # Kampala
    31.72,  # Masaka
    30.27,  # Fort Portal
    30.10,  # Kasese
    30.65   # Mbarara
  ),
  
  latitude = c(
    3.02,   # Arua
    2.77,   # Gulu
    3.28,   # Kitgum
    2.25,   # Lira
    1.71,   # Soroti
    2.53,   # Moroto
    1.08,   # Mbale
    0.35,   # Kampala
    -0.33,   # Masaka
    0.66,   # Fort Portal
    0.18,   # Kasese
    -0.61    # Mbarara
  )
)

# conflict events map
ggplot() +
  geom_sf(
    data = uganda_boundary,
    fill = "grey95",
    color = "black"
  ) +
  geom_point(
    data = uganda_clean,
    aes(
      x = longitude,
      y = latitude
    ),
    color = "red",
    alpha = 0.3,
    size = 0.5
  ) +
  coord_sf(expand = FALSE) +
  labs(
    title = "Conflict Events in Uganda"
  ) +
  theme_minimal()

# conflict hotspots map
uganda_hotspots <- ggplot() +
  
  geom_sf(
    data = uganda_boundary,
    fill = "white",
    color = "black",
    linewidth = 0.4
  ) +
  
  stat_density_2d(
    data = uganda_clean,
    aes(
      x = longitude,
      y = latitude,
      fill = after_stat(level)
    ),
    geom = "polygon",
    alpha = 0.75
  ) +
  
  scale_fill_gradient(
    low = "#f8ede3",
    high = "#9d3d2d",
    name = "Conflict Density",
    breaks = c(0.2, 0.6),
    labels = c("Lower", "Higher")
  ) +
  
  geom_point(
    data = cities,
    aes(
      x = longitude,
      y = latitude
    ),
    color = "black",
    size = 2
  ) +
  
  geom_text_repel(
    data = cities,
    aes(
      x = longitude,
      y = latitude,
      label = city
    ),
    size = 3,
    box.padding = 0.5,
    point.padding = 0.5,
    max.overlaps = Inf,
    segment.color = "grey50"
  ) +
  
  coord_sf(expand = FALSE) +
  
  labs(
    title = "Conflict Hotspots in Uganda",
    subtitle = "Spatial distribution of conflict events, 1989-2024",
    caption = "Source: UCDP Georeferenced Event Dataset (GED) Version 26.1"
  ) +
  
  theme_minimal() +
  
  theme(
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "right",
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    )
  )

uganda_hotspots

# which region had the most fatalities?
head(fatalities_region, 20)

# save it!
ggsave(
  "~/Desktop/github projects/uganda_conflict_hotspots.png",
  plot = uganda_hotspots,
  width = 10,
  height = 8,
  dpi = 300
)