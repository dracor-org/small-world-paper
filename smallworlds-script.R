# import packages
library("purrr")
library("igraph")
library("stringr")
library("jsonlite")

# Get information on package versions
sessionInfo()

set.seed(42)

# set API baseurl to value of the evironment variable defined in the Dockerfile/docker-compose file
baseurl <- Sys.getenv("DRACOR_APIBASE")

# to run the script locally without Docker and use a local VeBiDraCor instance, set the baseurl to the localhost
if (baseurl == '') {
  baseurl = "http://localhost:8088/api/"
}

# set corpusname to the value of the environment variable defined in the Dockerfile/docker-compose file
corpusname <- Sys.getenv("DRACOR_CORPUSNAME")

if (corpusname == '') {
  corpusname = "vebi"
}


list_of_names <- fromJSON(paste0(baseurl, "corpora/", corpusname))
sorted_names <- list_of_names$dramas$name[sort.list(list_of_names$dramas$id)]

get_network_data_per_play <- function(play_name){
  json <- fromJSON(paste0(baseurl, "corpora/", corpusname, "/play/", play_name, "/metrics"))
  nodes_data <- json[["nodes"]]
  nodes_data
}

vb_metrics <- lapply(sorted_names, get_network_data_per_play)

options(timeout=500)
vb_metadata <- read.csv(file=paste0(baseurl, "corpora/", corpusname, "/metadata/csv"), stringsAsFactors = F)
vb_metadata <- vb_metadata[order(vb_metadata$id),]

vb_metadata$nodes <- vb_metrics

randomize_graph <- function(size, numEdges){
  random_graphs=list(1000)
  for (i in 1:1000){
    random_graphs[[i]] <- sample_gnm(size, numEdges, directed = F, loops = F)
  }
  
  CC_1k <- sapply(random_graphs, transitivity)
  APL_1k <- sapply(random_graphs, function(x) mean_distance(x, directed=F))
  results <- list()
  results$CC_rand <- mean(CC_1k)
  results$APL_rand <- mean(APL_1k)
  return(results)
}

metrics_for_rand_graphs <- mapply(randomize_graph, vb_metadata$size, vb_metadata$numEdges)
matrix_metrics <- as.data.frame(t(metrics_for_rand_graphs))

vb_metadata$CC_rand <- unlist(matrix_metrics$CC_rand)
vb_metadata$APL_rand <- unlist(matrix_metrics$APL_rand)

vb_metadata <- transform(vb_metadata, CC_dev = averageClustering / CC_rand )
vb_metadata <- transform(vb_metadata, APL_dev = averagePathLength / APL_rand )


vb_metadata <- transform(vb_metadata, S = CC_dev / APL_dev)

## Analysis 1
vb_metadata$analysis1 <- ifelse(vb_metadata$S>1, TRUE, FALSE)
## Analysis 2
vb_metadata$analysis2 <- ifelse(vb_metadata$S>3, TRUE, FALSE)

## Small-World-Test (swt)
two_criteria <- function(df, analysis){
  if (analysis == 3){
    selected_df <- vb_metadata
    df$selected <- TRUE
  }
  if (analysis == 5){
    selected_df <- vb_metadata[vb_metadata$numOfSegments >= 5, ]
    df$selected <- ifelse(vb_metadata$numOfSegments >= 5, TRUE, FALSE)
  }
  if (analysis == 7){
    selected_df <- vb_metadata[(vb_metadata$numOfSegments >= 5) & (vb_metadata$yearNormalized > 1500), ]
    df$selected <- ifelse((vb_metadata$numOfSegments >= 5) & (vb_metadata$yearNormalized > 1500), TRUE, FALSE)
  }
  if (analysis == 9){
    selected_df <- vb_metadata[grepl("ger", vb_metadata$id, fixed = TRUE), ]
    df$selected <- ifelse(grepl("ger", vb_metadata$id, fixed = TRUE), TRUE, FALSE)
  }
  if (analysis == 11){
    selected_df <- vb_metadata[grepl("rus", vb_metadata$id, fixed = TRUE), ]
    df$selected <- ifelse(grepl("rus", vb_metadata$id, fixed = TRUE), TRUE, FALSE)
  }
  ## Calculating border values
  CC_border <- mean(selected_df$CC_dev, na.rm = TRUE)+2*sd(selected_df$CC_dev, na.rm = TRUE)
  APL_border_min <- mean(selected_df$APL_dev, na.rm = TRUE)-2*sd(selected_df$APL_dev, na.rm = TRUE)
  APL_border_max <- mean(selected_df$APL_dev, na.rm = TRUE)+2*sd(selected_df$APL_dev, na.rm = TRUE)
  
  ## Applying criteria
  df$crit_1 <- ifelse(df$CC_dev>=CC_border, TRUE, FALSE)
  df$crit_2 <- ifelse((df$crit_1 == TRUE) & (df$APL_dev >= APL_border_min) & (df$APL_dev<=APL_border_max) & (df$selected == TRUE), TRUE, FALSE)
  df$crit_2 <- ifelse((df$selected == FALSE), "X", df$crit_2)
  df$crit_1 <- NULL
  df$selected <- NULL
  return(df)
}

## Analysis 3
vb_metadata <- two_criteria(vb_metadata, 3)
colnames(vb_metadata)[colnames(vb_metadata) == 'crit_2'] <- 'analysis3'

## Analysis 5
vb_metadata <- two_criteria(vb_metadata, 5)
colnames(vb_metadata)[colnames(vb_metadata) == 'crit_2'] <- 'analysis5'

## Analysis 7
vb_metadata <- two_criteria(vb_metadata, 7)
colnames(vb_metadata)[colnames(vb_metadata) == 'crit_2'] <- 'analysis7'

## Analysis 9
vb_metadata <- two_criteria(vb_metadata, 9)
colnames(vb_metadata)[colnames(vb_metadata) == 'crit_2'] <- 'analysis9'

## Analysis 11
vb_metadata <- two_criteria(vb_metadata, 11)
colnames(vb_metadata)[colnames(vb_metadata) == 'crit_2'] <- 'analysis11'


extract_degree <- function(x){
  degree_table <- as.data.frame(table(x$degree))
  degree_table
}

num_type <- function(x){
  x$Var1 <- as.numeric(as.character(x$Var1))
  x$Freq <- as.numeric(x$Freq)
  x[x==0] = NA
  names(x) <- c("Node_degree", "Num_of_nodes")
  x
}

## Scale free test (sft)

node_degree_test <- function(df, analysis){
  if (analysis == 4){
    selected_df <- vb_metadata[vb_metadata$analysis3 == TRUE & !is.na(vb_metadata$analysis3), ]
  }
  if (analysis == 6){
    selected_df <- vb_metadata[vb_metadata$analysis5 == TRUE & !is.na(vb_metadata$analysis5), ]
  }
  if (analysis == 8){
    selected_df <- vb_metadata[vb_metadata$analysis7 == TRUE & !is.na(vb_metadata$analysis7), ]
  }
  if (analysis == 10){
    selected_df <- vb_metadata[vb_metadata$analysis9 == TRUE & !is.na(vb_metadata$analysis9), ]
  }
  if (analysis == 12){
    selected_df <- vb_metadata[vb_metadata$analysis11 == TRUE & !is.na(vb_metadata$analysis11), ]
  }
  
  
  number_of_nodes <- lapply(selected_df$nodes, extract_degree)
  distribution <- lapply(number_of_nodes, as.data.frame)
  distribution <- lapply(number_of_nodes, num_type)
  distribution <- lapply(distribution, na.omit)
  
  ## Linear
  fit <- lapply(distribution, function(x) lm(x$Num_of_nodes ~ x$Node_degree))
  selected_df$lin <- sapply (fit, function(x) summary(x)$r.squared)
  
  ## Power law
  fit <- lapply(distribution, function(x) lm(log(x$Num_of_nodes) ~ log(x$Node_degree)))
  selected_df$pl <- sapply (fit, function(x) summary(x)$r.squared)
  
  ## Quadratic
  fit <- lapply(distribution, function(x) lm(x$Num_of_nodes ~ poly(x$Node_degree, 2)))
  selected_df$quad <- sapply (fit, function(x) summary(x)$r.squared)
  
  ## Exponential
  fit <- lapply(distribution, function(x) lm(x$Num_of_nodes ~ exp(x$Node_degree)))
  selected_df$exp <- sapply (fit, function(x) summary(x)$r.squared)
  
  return(selected_df[c("id","lin","pl", "quad", "exp")])
}

res <- node_degree_test(vb_metadata, 4)
vb_metadata <- merge(vb_metadata, res, by.x = "id", by.y = "id", all.x = TRUE)
names(vb_metadata)[names(vb_metadata) == 'lin'] <- 'analysis4_lin'
names(vb_metadata)[names(vb_metadata) == 'pl'] <- 'analysis4_pl'
names(vb_metadata)[names(vb_metadata) == 'quad'] <- 'analysis4_quad'
names(vb_metadata)[names(vb_metadata) == 'exp'] <- 'analysis4_exp'

res <- node_degree_test(vb_metadata, 6)
vb_metadata <- merge(vb_metadata, res, by.x = "id", by.y = "id", all.x = TRUE)
names(vb_metadata)[names(vb_metadata) == 'lin'] <- 'analysis6_lin'
names(vb_metadata)[names(vb_metadata) == 'pl'] <- 'analysis6_pl'
names(vb_metadata)[names(vb_metadata) == 'quad'] <- 'analysis6_quad'
names(vb_metadata)[names(vb_metadata) == 'exp'] <- 'analysis6_exp'

res <- node_degree_test(vb_metadata, 8)
vb_metadata <- merge(vb_metadata, res, by.x = "id", by.y = "id", all.x = TRUE)
names(vb_metadata)[names(vb_metadata) == 'lin'] <- 'analysis8_lin'
names(vb_metadata)[names(vb_metadata) == 'pl'] <- 'analysis8_pl'
names(vb_metadata)[names(vb_metadata) == 'quad'] <- 'analysis8_quad'
names(vb_metadata)[names(vb_metadata) == 'exp'] <- 'analysis8_exp'

res <- node_degree_test(vb_metadata, 10)
vb_metadata <- merge(vb_metadata, res, by.x = "id", by.y = "id", all.x = TRUE)
names(vb_metadata)[names(vb_metadata) == 'lin'] <- 'analysis10_lin'
names(vb_metadata)[names(vb_metadata) == 'pl'] <- 'analysis10_pl'
names(vb_metadata)[names(vb_metadata) == 'quad'] <- 'analysis10_quad'
names(vb_metadata)[names(vb_metadata) == 'exp'] <- 'analysis10_exp'

res <- node_degree_test(vb_metadata, 12)
vb_metadata <- merge(vb_metadata, res, by.x = "id", by.y = "id", all.x = TRUE)
names(vb_metadata)[names(vb_metadata) == 'lin'] <- 'analysis12_lin'
names(vb_metadata)[names(vb_metadata) == 'pl'] <- 'analysis12_pl'
names(vb_metadata)[names(vb_metadata) == 'quad'] <- 'analysis12_quad'
names(vb_metadata)[names(vb_metadata) == 'exp'] <- 'analysis12_exp'

vb_metadata$nodes <- NULL


vb_metadata$SFT_VeBiDraCor <- ifelse((vb_metadata$analysis4_pl > vb_metadata$analysis4_exp) &
                                       (vb_metadata$analysis4_pl > vb_metadata$analysis4_lin) &
                                       (vb_metadata$analysis4_pl > vb_metadata$analysis4_quad), TRUE, FALSE)

vb_metadata$SFT_VeBiDraCor_Struc <- ifelse((vb_metadata$analysis6_pl > vb_metadata$analysis6_exp) &
                                             (vb_metadata$analysis6_pl > vb_metadata$analysis6_lin) &
                                             (vb_metadata$analysis6_pl > vb_metadata$analysis6_quad), TRUE, FALSE)

vb_metadata$SFT_VeBiDraCor_Struc_Hist <- ifelse((vb_metadata$analysis8_pl > vb_metadata$analysis8_exp) &
                                                  (vb_metadata$analysis8_pl > vb_metadata$analysis8_lin) &
                                                  (vb_metadata$analysis8_pl > vb_metadata$analysis8_quad), TRUE, FALSE)

vb_metadata$SFT_GerDraCor <- ifelse((vb_metadata$analysis10_pl > vb_metadata$analysis10_exp) &
                                      (vb_metadata$analysis10_pl > vb_metadata$analysis10_lin) &
                                      (vb_metadata$analysis10_pl > vb_metadata$analysis10_quad), TRUE, FALSE)

vb_metadata$SFT_RusDraCor <- ifelse((vb_metadata$analysis12_pl > vb_metadata$analysis12_exp) &
                                      (vb_metadata$analysis12_pl > vb_metadata$analysis12_lin) &
                                      (vb_metadata$analysis12_pl > vb_metadata$analysis12_quad), TRUE, FALSE)

# store the results to the results folder (will be synchronized to the host machine if using the docker-compose.pre.yml setup)
write.csv(vb_metadata, file = "export/results.csv")

# store the results.csv file inside the RStudio environment (needed if using the docker-compose.post.yml setup)
write.csv(vb_metadata, file = "results.csv")