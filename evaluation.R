library(tidyverse)

############## Evaluation for cross-validation ##############

preproc_cv <- function(f = here::here('demo_data', 'cross-validation', 'leave_period_1', 'result.csv'), i=1) {
  d <- read_csv(f) %>% 
    mutate(
      sigma_baseline = n_hits - n_misses - n_false_alarms_inside,
      precision_baseline = n_hits / (n_hits + n_false_alarms_inside),
      precision_baseline_all = n_hits / (n_hits + n_false_alarms_inside + n_false_alarms_outside),
      recall_baseline = n_hits / (n_hits + n_misses),
      precision_recall_avg_baseline = (precision_baseline + recall_baseline) / 2
    )
  
  ans1 <- d %>% 
    filter(precision_baseline_all >= 0.2) %>% 
    slice(which.max(recall_baseline)) %>% 
    select(duration, radius, range, timeframe) %>% 
    mutate(maximization = 'conditional') %>% 
    mutate(fold = i)
  
  ans2 <- d %>% 
    slice(which.max(recall_baseline)) %>% 
    select(duration, radius, range, timeframe) %>% 
    mutate(maximization = 'absolute') %>% 
    mutate(fold = i)
  
  ans <- rbind(ans1, ans2)
  
  return(ans)
}

out <- map2_dfr(paste('./demo_data/cross-validation/leave_period_', 1:5, '/result.csv', sep=''), 1:5, preproc_cv)

out

out %>% 
  write_csv('demo_data/cross-validation/cv_results.csv')

############## Evaluation on full training set ##############

d <- read_csv(here::here('demo_data', 'parameter_sweep_full_v1.csv')) %>% 
  

d %>% 
  slice(which.max(sigma_baseline))

d %>% 
  slice(which.max(precision_baseline))

d %>% 
  slice(which.max(recall_baseline))

d %>% 
  slice(which.max(precision_recall_avg_baseline))

m <- lm(precision_recall_avg_baseline ~ scale(duration) + scale(radius) + scale(range), d) 
summary(m)
sjPlot::tab_model(m)

m <- lm(sigma_baseline ~ scale(duration) + scale(radius) + scale(range), d) 
summary(m)
sjPlot::tab_model(m)

axx <- list(
  title = "Duration"
)
axy <- list(
  title = "Radius"
)
axz <- list(
  title = "Range"
)
plotly::plot_ly(data=d, x=~duration,y=~radius,z=~range, marker=list(color=~precision_recall_avg_baseline,
                                                                                   colorscale="Viridis",
                                                                                   showscale=TRUE,
                                                                                   size=4,
                                                                                   line=list(width=2,color='DarkSlateGrey'),
                                                                                   colorbar=list(
                                                                                     title='mean(sens+recall)'
                                                                                   ))) %>% 
  plotly::add_markers() %>% 
  plotly::layout(
    scene = list(xaxis=axx,yaxis=axy,zaxis=axz),
    annotations = list(
      x = 1.06,
      y = 1.03,
      text = 'factor',
      xref = 'paper',
      yref = 'paper',
      showarrow = FALSE
    ))

plotly::plot_ly(data=d, x=~duration,y=~radius,z=~range, marker=list(color=~precision_baseline,
                                                                    colorscale="Viridis",
                                                                    showscale=TRUE,
                                                                    size=4,
                                                                    line=list(width=2,color='DarkSlateGrey'),
                                                                    colorbar=list(
                                                                      title='sens'
                                                                    ))) %>% 
  plotly::add_markers() %>% 
  plotly::layout(
    scene = list(xaxis=axx,yaxis=axy,zaxis=axz),
    annotations = list(
      x = 1.06,
      y = 1.03,
      text = 'factor',
      xref = 'paper',
      yref = 'paper',
      showarrow = FALSE
    ))


plotly::plot_ly(data=d, x=~duration,y=~radius,z=~range, marker=list(color=~recall_baseline,
                                                                    colorscale="Viridis",
                                                                    showscale=TRUE,
                                                                    size=4,
                                                                    line=list(width=2,color='DarkSlateGrey'),
                                                                    colorbar=list(
                                                                      title='recall'
                                                                    ))) %>% 
  plotly::add_markers() %>% 
  plotly::layout(
    scene = list(xaxis=axx,yaxis=axy,zaxis=axz),
    annotations = list(
      x = 1.06,
      y = 1.03,
      text = 'factor',
      xref = 'paper',
      yref = 'paper',
      showarrow = FALSE
    ))

# TODO: Calculate ROC curve

plot(d$precision_baseline, d$recall_baseline)

plot(d$precision_baseline_all, d$recall_baseline)
abline(a=.6, b=-1)

number_ticks <- function(n) {function(limits) pretty(limits, n)}
ggplot(d, aes(precision_baseline_all, recall_baseline)) + 
  geom_point() + 
  theme_bw() + 
  labs(x = "Precision (Inside + Outside)", y = "Recall", title = "Teacher Stop Detection") + 
  geom_abline(intercept=.5, slope=-1) + 
  scale_y_continuous(breaks=number_ticks(10)) + 
  theme(text = element_text(size=20))

ggsave('pre-rec.pdf', width = 6, height = 6)

# theoretical bounds: slope is such that you get more recall for sacrificing less precision (all)

# Bound 1: Largest recall

# duration = 6
# radius = 1800
# range = 1900
d %>% 
  slice(which.max(recall_baseline)) %>% 
  select(duration, radius, range, recall_baseline, precision_baseline_all)

# Bound 2: Precision at least 0.2

# duration = 21
# radius = 600
# range = 700

d %>% 
  filter(precision_baseline_all >= 0.2) %>% 
  slice(which.max(recall_baseline)) %>% 
  select(duration, radius, range, recall_baseline, precision_baseline_all)

# TODO: Add statistical power x sample size justification for how we select bounds?
# TODO: -. could add other considerations in workshop paper, e.g., theoretical grounds
# TODO: Add robustness checks if we want for AIED

# d %>% 
#   filter(precision_baseline_all >= 0.25) %>% 
#   slice(which.max(recall_baseline)) %>% 
#   select(duration, radius, range, recall_baseline, precision_baseline_all)

d %>% 
  mutate(
    min_dur = min(duration),
    max_dur = max(duration),
    min_rad = min(radius),
    max_rad = max(radius),
    min_ran = min(range),
    max_ran = max(range)
  ) %>% 
  select(matches('min|max')) %>% 
  head(1)
