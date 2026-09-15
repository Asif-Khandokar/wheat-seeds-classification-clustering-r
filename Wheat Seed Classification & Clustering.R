###############################################################################
#  WHEAT SEEDS PROJECT
#
#  PART A: CLASSIFICATION - Decision Trees vs K-Nearest Neighbours
#  PART B: CLUSTERING     - Hierarchical Clustering vs K-Means
#
#  Data: UCI Machine Learning Repository - Seeds Dataset
#        (210 kernels, 7 measurements, 3 wheat varieties)
#
#  No CSV files or WK_R.r are needed.
#  The data is downloaded on the first run and saved as "seeds.csv",
#  so later runs work without internet access.
#
#  Plotting has been adjusted to use SMALL, SINGLE-PANEL figures to avoid:
#       Error in plot.new(): figure margins too large
###############################################################################


###############################################################################
#  0. SETUP
###############################################################################

# Install rpart.plot if missing
if (!requireNamespace("rpart.plot", quietly = TRUE)) {
  try(install.packages("rpart.plot"), silent = TRUE)
}

hasRpartPlot <- requireNamespace("rpart.plot", quietly = TRUE)

library(class)   # knn()
library(rpart)   # decision trees


# ---------------------------------------------------------------------------
# Kappa setting
# ---------------------------------------------------------------------------
# FALSE = ordinary Cohen's kappa
# TRUE  = linear weighted kappa
#
# If your coursework specifically requires WEIGHTED KAPPA,
# change FALSE to TRUE.

USE_WEIGHTED_KAPPA <- FALSE

kappaName <- if (USE_WEIGHTED_KAPPA) {
  "Weighted kappa"
} else {
  "Cohen's kappa"
}


# Reproducibility
set.seed(2026)


###############################################################################
#  SMALL / SAFE PLOTTING SETTINGS
###############################################################################

# This function resets the plotting window before every graph.
# Keeping one graph at a time prevents "figure margins too large".

smallPlot <- function() {
  
  par(
    mfrow = c(1, 1),       # only ONE figure at a time
    mar = c(3.5, 3.5, 2.5, 1),  # smaller margins
    mgp = c(2, 0.7, 0),    # axis title / labels closer together
    cex = 0.8,              # smaller overall text
    cex.axis = 0.8,
    cex.lab = 0.85,
    cex.main = 0.9
  )
  
}


###############################################################################
#  1. LOAD THE DATA
###############################################################################

localFile <- "seeds.csv"

featureNames <- c(
  "Area",
  "Perimeter",
  "Compactness",
  "KernelLength",
  "KernelWidth",
  "AsymmetryCoefficient",
  "GrooveLength"
)


# Use local copy if it already exists
if (file.exists(localFile)) {
  
  cat(
    "Loading Seeds dataset from local copy:",
    localFile,
    "\n"
  )
  
  seeds_raw <- read.csv(localFile)
  
} else {
  
  cat("Downloading Seeds dataset from UCI...\n")
  
  data_url <- paste0(
    "https://archive.ics.uci.edu/ml/",
    "machine-learning-databases/00236/seeds_dataset.txt"
  )
  
  
  # sep = "" treats spaces and tabs as separators
  seeds_raw <- read.table(
    data_url,
    header = FALSE,
    sep = ""
  )
  
  
  colnames(seeds_raw) <- c(
    featureNames,
    "Class"
  )
  
  
  # Save local copy
  write.csv(
    seeds_raw,
    localFile,
    row.names = FALSE
  )
  
  
  cat(
    "Saved a local copy as",
    localFile,
    "\n"
  )
  
}


###############################################################################
#  CHECK DATA
###############################################################################

if (
  nrow(seeds_raw) != 210 ||
  ncol(seeds_raw) != 8
) {
  
  stop(
    sprintf(
      "Expected 210 rows and 8 columns, but got %d rows and %d columns.",
      nrow(seeds_raw),
      ncol(seeds_raw)
    )
  )
  
}


stopifnot(
  all(
    c(featureNames, "Class") %in%
      names(seeds_raw)
  )
)


cat("\nFirst six rows:\n")
print(head(seeds_raw))


cat("\nClass distribution:\n")
print(table(seeds_raw$Class))



###############################################################################
#  2. PREPARE THE DATA
###############################################################################

# Classification dataset
seeds <- seeds_raw


# Convert class into meaningful factor labels
seeds$Class <- factor(
  
  seeds$Class,
  
  levels = 1:3,
  
  labels = c(
    "Kama",
    "Rosa",
    "Canadian"
  )
  
)


# Feature columns
featureCols <- setdiff(
  names(seeds),
  "Class"
)


# Clustering dataset:
# only numerical features
seeds_data <- seeds_raw[
  ,
  featureCols
]


# Real wheat classes
realLabels <- seeds_raw$Class



###############################################################################
#  3. HELPER FUNCTIONS
###############################################################################


###############################################################################
#  ACCURACY
###############################################################################

getAccuracy <- function(
    predicted,
    actual
) {
  
  mean(
    as.character(predicted) ==
      as.character(actual)
  )
  
}



###############################################################################
#  DECISION TREE PLOTTING
###############################################################################

printTree <- function(
    fit,
    type = 4,
    title = "Decision Tree"
) {
  
  smallPlot()
  
  
  # Handle tree pruned back to only the root node
  if (nrow(fit$frame) == 1) {
    
    plot.new()
    
    title(
      main = title,
      cex.main = 0.9
    )
    
    
    predictedClass <- attr(
      fit,
      "ylevels"
    )[fit$frame$yval[1]]
    
    
    text(
      0.5,
      0.5,
      paste(
        "Root node only\nPredicts class",
        predictedClass
      ),
      cex = 0.9
    )
    
    
  } else if (hasRpartPlot) {
    
    rpart.plot::rpart.plot(
      
      fit,
      
      type = type,
      
      main = title,
      
      extra = 104,
      
      fallen.leaves = TRUE,
      
      tweak = 0.75,
      
      cex = 0.65,
      
      compress = TRUE,
      
      branch = 0.4
      
    )
    
    
  } else {
    
    plot(
      fit,
      uniform = TRUE,
      margin = 0.05,
      main = title
    )
    
    
    text(
      fit,
      use.n = TRUE,
      cex = 0.55
    )
    
  }
  
}



###############################################################################
#  KAPPA FUNCTION
###############################################################################

kappaScore <- function(
    predicted,
    actual,
    weighted = USE_WEIGHTED_KAPPA
) {
  
  predicted <- as.integer(predicted)
  actual <- as.integer(actual)
  
  
  k <- max(
    c(predicted, actual)
  )
  
  
  # Observed table
  O <- as.matrix(
    
    table(
      
      factor(
        actual,
        levels = 1:k
      ),
      
      factor(
        predicted,
        levels = 1:k
      )
      
    )
    
  )
  
  
  n <- sum(O)
  
  
  # Expected frequencies
  E <- outer(
    rowSums(O),
    colSums(O)
  ) / n
  
  
  # Disagreement weights
  if (
    weighted &&
    k > 1
  ) {
    
    W <- abs(
      outer(
        1:k,
        1:k,
        "-"
      )
    ) / (k - 1)
    
  } else {
    
    # ordinary Cohen's kappa
    W <- 1 - diag(k)
    
  }
  
  
  expectedDisagreement <- sum(
    W * E
  ) / n
  
  
  if (
    expectedDisagreement == 0
  ) {
    
    return(
      NA_real_
    )
    
  }
  
  
  1 -
    (
      sum(W * O) / n
    ) /
    expectedDisagreement
  
}



###############################################################################
#  CLUSTER KAPPA
###############################################################################

clusterKappa <- function(
    groups,
    trueLabels
) {
  
  trueLabels <- as.integer(
    as.factor(trueLabels)
  )
  
  
  # Table of cluster vs real class
  tab <- table(
    groups,
    trueLabels
  )
  
  
  # Give each cluster its majority real class
  majorityClass <- as.integer(
    colnames(tab)
  )[
    apply(
      tab,
      1,
      which.max
    )
  ]
  
  
  names(majorityClass) <- rownames(tab)
  
  
  mapped <- majorityClass[
    as.character(groups)
  ]
  
  
  kappaScore(
    as.integer(mapped),
    trueLabels
  )
  
}



###############################################################################
###############################################################################
#
#                        PART A: CLASSIFICATION
#
###############################################################################
###############################################################################

cat("\n==================================================\n")
cat("PART A: CLASSIFICATION\n")
cat("==================================================\n")



###############################################################################
#  A1. SHUFFLE AND SPLIT
###############################################################################

set.seed(2026)


n <- nrow(seeds)


# Shuffle dataset
new_seeds <- seeds[
  sample(n, n),
]


# Training size
nTrain <- 150


# Training set
train <- new_seeds[
  1:nTrain,
]


# Test set
test <- new_seeds[
  (nTrain + 1):n,
]


# Classes
seeds_classTrain <- train$Class
seeds_classTest <- test$Class


# Features
seeds_ValuesTrain <- train[
  ,
  featureCols
]

seeds_ValuesTest <- test[
  ,
  featureCols
]


cat(
  "\nTraining rows:",
  nrow(train),
  "\n"
)


cat(
  "Test rows:",
  nrow(test),
  "\n"
)



###############################################################################
#  A2. DECISION TREE
###############################################################################

fit <- rpart(
  
  Class ~ .,
  
  data = train,
  
  method = "class"
  
)


# Plot tree
printTree(
  fit,
  4,
  "Decision Tree for Wheat Kernels"
)


# Predictions
seedsPrediction <- predict(
  
  fit,
  
  seeds_ValuesTest,
  
  type = "class"
  
)


# Accuracy
treeAccuracy <- getAccuracy(
  
  seedsPrediction,
  
  seeds_classTest
  
)


cat(
  sprintf(
    "\nUnpruned tree accuracy: %.3f (%.2f%%)\n",
    treeAccuracy,
    100 * treeAccuracy
  )
)


cat(
  "\nConfusion matrix - unpruned tree:\n"
)


print(
  
  table(
    
    Actual = seeds_classTest,
    
    Predicted = seedsPrediction
    
  )
  
)



###############################################################################
#  A3. PRUNING
###############################################################################

cat(
  "\nComplexity parameter table:\n"
)


printcp(fit)


# Plot CP
smallPlot()

plotcp(
  fit,
  minline = TRUE
)


###############################################################################
#  GET CP VALUES
###############################################################################

cpArray <- fit$cptable[
  ,
  "CP"
]


nSplits <- fit$cptable[
  ,
  "nsplit"
]


accuracyVector <- numeric(
  length(cpArray)
)



###############################################################################
#  SHOW UNPRUNED TREE FIRST
###############################################################################

printTree(
  fit,
  4,
  "Unpruned Decision Tree"
)



###############################################################################
#  PRUNE EACH TREE
###############################################################################
#
# IMPORTANT:
# Every tree is plotted separately instead of putting several trees
# in the same plotting window.
#
###############################################################################

for (
  i in seq_along(cpArray)
) {
  
  prunedFit <- prune(
    
    fit,
    
    cp = cpArray[i]
    
  )
  
  
  printTree(
    
    prunedFit,
    
    3,
    
    sprintf(
      "Pruned Tree: cp = %.3f, Splits = %d",
      cpArray[i],
      nSplits[i]
    )
    
  )
  
  
  prunedPrediction <- predict(
    
    prunedFit,
    
    seeds_ValuesTest,
    
    type = "class"
    
  )
  
  
  accuracyVector[i] <- getAccuracy(
    
    prunedPrediction,
    
    seeds_classTest
    
  )
  
}



###############################################################################
#  PRUNING RESULTS
###############################################################################

prunedResults <- data.frame(
  
  cp = round(
    cpArray,
    4
  ),
  
  splits = nSplits,
  
  accuracy = round(
    accuracyVector,
    3
  )
  
)


cat(
  "\nPruned tree accuracies:\n"
)


print(
  prunedResults,
  row.names = FALSE
)



###############################################################################
#  BEST TREE USING CROSS-VALIDATION
###############################################################################

bestCp <- fit$cptable[
  
  which.min(
    fit$cptable[, "xerror"]
  ),
  
  "CP"
  
]


bestFit <- prune(
  
  fit,
  
  cp = bestCp
  
)


bestTreePrediction <- predict(
  
  bestFit,
  
  seeds_ValuesTest,
  
  type = "class"
  
)


bestTreeAccuracy <- getAccuracy(
  
  bestTreePrediction,
  
  seeds_classTest
  
)


cat(
  
  sprintf(
    
    "\nCross-validated best cp: %.4f\n",
    
    bestCp
    
  )
  
)


cat(
  
  sprintf(
    
    "Best pruned tree test accuracy: %.3f (%.2f%%)\n",
    
    bestTreeAccuracy,
    
    100 * bestTreeAccuracy
    
  )
  
)


# Show best pruned tree separately
printTree(
  
  bestFit,
  
  4,
  
  sprintf(
    "Best Pruned Tree - Accuracy %.1f%%",
    100 * bestTreeAccuracy
  )
  
)



###############################################################################
#  A4. SCATTERPLOT OF DECISION TREE PREDICTIONS
###############################################################################

smallPlot()


classCols <- c(
  "orange",
  "deepskyblue",
  "darkviolet"
)


classSymbols <- c(
  16,
  17,
  15
)


plot(
  
  seeds_ValuesTest$Area,
  
  seeds_ValuesTest$GrooveLength,
  
  col = classCols[
    as.integer(seedsPrediction)
  ],
  
  pch = classSymbols[
    as.integer(seeds_classTest)
  ],
  
  xlab = "Area",
  
  ylab = "Groove Length",
  
  main = sprintf(
    "Decision Tree Predictions - Accuracy %.1f%%",
    100 * treeAccuracy
  ),
  
  cex = 0.8
  
)


# Misclassified observations
wrong <- seedsPrediction !=
  seeds_classTest


points(
  
  seeds_ValuesTest$Area[
    wrong
  ],
  
  seeds_ValuesTest$GrooveLength[
    wrong
  ],
  
  cex = 1.4,
  
  col = "red"
  
)


legend(
  
  "topleft",
  
  bty = "n",
  
  cex = 0.55,
  
  legend = c(
    
    paste(
      "Predicted",
      levels(seeds_classTest)
    ),
    
    paste(
      "True",
      levels(seeds_classTest)
    ),
    
    "Misclassified"
    
  ),
  
  col = c(
    
    classCols,
    
    rep(
      "black",
      3
    ),
    
    "red"
    
  ),
  
  pch = c(
    
    rep(
      16,
      3
    ),
    
    classSymbols,
    
    1
    
  )
  
)



###############################################################################
#  A5. K-NEAREST NEIGHBOURS
###############################################################################

# Standardise training data
trainScaled <- scale(
  seeds_ValuesTrain
)


# Apply SAME scaling to test data
testScaled <- scale(
  
  seeds_ValuesTest,
  
  center = attr(
    trainScaled,
    "scaled:center"
  ),
  
  scale = attr(
    trainScaled,
    "scaled:scale"
  )
  
)


# Odd values prevent vote ties
Kvector <- seq(
  1,
  21,
  by = 2
)


accuracyKnnVector <- numeric(
  length(Kvector)
)



###############################################################################
#  TEST EACH K
###############################################################################

for (
  i in seq_along(Kvector)
) {
  
  knnPrediction <- knn(
    
    train = trainScaled,
    
    test = testScaled,
    
    cl = seeds_classTrain,
    
    k = Kvector[i]
    
  )
  
  
  accuracyKnnVector[i] <- getAccuracy(
    
    knnPrediction,
    
    seeds_classTest
    
  )
  
}



###############################################################################
#  KNN RESULTS
###############################################################################

knnResults <- data.frame(
  
  k = Kvector,
  
  accuracy = round(
    accuracyKnnVector,
    3
  )
  
)


cat(
  "\nKNN accuracies:\n"
)


print(
  knnResults,
  row.names = FALSE
)



###############################################################################
#  BEST KNN
###############################################################################

bestKIndex <- which.max(
  accuracyKnnVector
)


bestK <- Kvector[
  bestKIndex
]


bestKAccuracy <- accuracyKnnVector[
  bestKIndex
]


cat(
  
  sprintf(
    
    "\nBest KNN: k = %d, accuracy = %.3f (%.2f%%)\n",
    
    bestK,
    
    bestKAccuracy,
    
    100 * bestKAccuracy
    
  )
  
)



###############################################################################
#  A6. KNN ACCURACY GRAPH
###############################################################################

smallPlot()


plot(
  
  Kvector,
  
  accuracyKnnVector,
  
  type = "o",
  
  pch = 19,
  
  cex = 0.7,
  
  ylim = c(
    0,
    1
  ),
  
  xlab = "Number of Neighbours (k)",
  
  ylab = "Test Accuracy",
  
  main = "K-Nearest Neighbours"
  
)


# Decision-tree reference line
abline(
  
  h = treeAccuracy,
  
  lty = 2
  
)


legend(
  
  "bottomright",
  
  bty = "n",
  
  cex = 0.7,
  
  lty = c(
    1,
    2
  ),
  
  legend = c(
    "KNN",
    "Unpruned Tree"
  )
  
)



###############################################################################
#  PRUNED TREE ACCURACY GRAPH
###############################################################################

smallPlot()


plot(
  
  nSplits,
  
  accuracyVector,
  
  type = "o",
  
  pch = 19,
  
  cex = 0.7,
  
  ylim = c(
    0,
    1
  ),
  
  xlab = "Number of Splits",
  
  ylab = "Test Accuracy",
  
  main = "Pruned Decision Trees"
  
)


text(
  
  nSplits,
  
  accuracyVector,
  
  labels = sprintf(
    "cp=%.2f",
    cpArray
  ),
  
  pos = 3,
  
  cex = 0.55
  
)



###############################################################################
#  CLASSIFICATION COMPARISON TABLE
###############################################################################

comparison <- rbind(
  
  data.frame(
    
    Model = sprintf(
      "Tree, cp = %.3f (%d splits)",
      cpArray,
      nSplits
    ),
    
    Accuracy = accuracyVector
    
  ),
  
  
  data.frame(
    
    Model = sprintf(
      "KNN, k = %d",
      Kvector
    ),
    
    Accuracy = accuracyKnnVector
    
  )
  
)


comparison <- comparison[
  
  order(
    -comparison$Accuracy
  ),
  
]


cat(
  "\n==================================================\n"
)


cat(
  "ALL CLASSIFIERS RANKED BY TEST ACCURACY\n"
)


cat(
  "==================================================\n"
)


print(
  
  comparison,
  
  row.names = FALSE,
  
  digits = 3
  
)



###############################################################################
###############################################################################
#
#                          PART B: CLUSTERING
#
###############################################################################
###############################################################################

cat(
  "\n\n==================================================\n"
)


cat(
  "PART B: CLUSTERING\n"
)


cat(
  "==================================================\n"
)



###############################################################################
#  B1. PRE-PROCESS
###############################################################################

stopifnot(
  
  nrow(seeds_data) ==
    length(realLabels)
  
)


# Remove incomplete rows
keep <- complete.cases(
  seeds_data
)


seeds_data <- seeds_data[
  keep,
]


realLabels <- realLabels[
  keep
]


cat(
  
  "\nRows removed for missing values:",
  
  sum(!keep),
  
  "\n"
  
)


# Standardise
seeds_scaled <- scale(
  seeds_data
)


# Euclidean distance
d <- dist(
  
  seeds_scaled,
  
  method = "euclidean"
  
)



###############################################################################
#  B2. HIERARCHICAL CLUSTERING
###############################################################################

runHierarchical <- function(
    d,
    data,
    method,
    k,
    border
) {
  
  hfit <- hclust(
    
    d,
    
    method = method
    
  )
  
  
  groups <- cutree(
    
    hfit,
    
    k = k
    
  )
  
  
  ###########################################################################
  # DENDROGRAM
  ###########################################################################
  
  smallPlot()
  
  
  plot(
    
    hfit,
    
    labels = FALSE,
    
    hang = -1,
    
    xlab = "",
    
    sub = "",
    
    main = sprintf(
      "%s Linkage - k = %d",
      tools::toTitleCase(method),
      k
    ),
    
    cex = 0.6
    
  )
  
  
  rect.hclust(
    
    hfit,
    
    k = k,
    
    border = border
    
  )
  
  
  ###########################################################################
  # PAIRS PLOT
  ###########################################################################
  #
  # Small text and margins are used to reduce plot size problems.
  ###########################################################################
  
  smallPlot()
  
  
  pairs(
    
    data,
    
    col = groups,
    
    pch = 19,
    
    cex = 0.35,
    
    cex.labels = 0.55,
    
    gap = 0.25,
    
    main = sprintf(
      "%s Linkage - k = %d",
      tools::toTitleCase(method),
      k
    )
    
  )
  
  
  cat(
    
    sprintf(
      
      "\n%s linkage, k = %d, cluster sizes:\n",
      
      method,
      
      k
      
    )
    
  )
  
  
  print(
    table(groups)
  )
  
  
  groups
  
}



###############################################################################
#  RUN HIERARCHICAL CLUSTERING
###############################################################################

Hgroups <- runHierarchical(
  
  d,
  
  seeds_scaled,
  
  "average",
  
  5,
  
  "red"
  
)


Hgroups1 <- runHierarchical(
  
  d,
  
  seeds_scaled,
  
  "single",
  
  3,
  
  "green"
  
)


Hgroups2 <- runHierarchical(
  
  d,
  
  seeds_scaled,
  
  "complete",
  
  8,
  
  "blue"
  
)



###############################################################################
#  B3. K-MEANS CLUSTERING
###############################################################################

runKmeans <- function(
    data,
    k
) {
  
  kfit <- kmeans(
    
    data,
    
    centers = k,
    
    nstart = 25
    
  )
  
  
  cat(
    
    sprintf(
      
      "\nK-means, k = %d, cluster means:\n",
      
      k
      
    )
    
  )
  
  
  print(
    
    aggregate(
      
      data,
      
      by = list(
        Cluster = kfit$cluster
      ),
      
      FUN = mean
      
    )
    
  )
  
  
  cat(
    "Cluster sizes:\n"
  )
  
  
  print(
    table(kfit$cluster)
  )
  
  
  
  ###########################################################################
  # K-MEANS PAIRS PLOT
  ###########################################################################
  
  smallPlot()
  
  
  pairs(
    
    data,
    
    col = kfit$cluster,
    
    pch = 19,
    
    cex = 0.35,
    
    cex.labels = 0.55,
    
    gap = 0.25,
    
    main = sprintf(
      "K-Means - k = %d",
      k
    )
    
  )
  
  
  kfit$cluster
  
}



###############################################################################
#  RUN K-MEANS
###############################################################################

set.seed(2026)


Kgroups <- runKmeans(
  
  seeds_scaled,
  
  5
  
)


Kgroups1 <- runKmeans(
  
  seeds_scaled,
  
  7
  
)


Kgroups2 <- runKmeans(
  
  seeds_scaled,
  
  3
  
)



###############################################################################
#  B4. KAPPA AGAINST TRUE LABELS
###############################################################################

cat(
  "\n==================================================\n"
)


cat(
  toupper(kappaName),
  " RESULTS\n",
  sep = ""
)


cat(
  "==================================================\n"
)



###############################################################################
#  HIERARCHICAL KAPPA
###############################################################################

WK_Hc <- c(
  
  "Average k=5" = clusterKappa(
    Hgroups,
    realLabels
  ),
  
  "Single k=3" = clusterKappa(
    Hgroups1,
    realLabels
  ),
  
  "Complete k=8" = clusterKappa(
    Hgroups2,
    realLabels
  )
  
)



###############################################################################
#  K-MEANS KAPPA
###############################################################################

WK_Km <- c(
  
  "K-means k=5" = clusterKappa(
    Kgroups,
    realLabels
  ),
  
  "K-means k=7" = clusterKappa(
    Kgroups1,
    realLabels
  ),
  
  "K-means k=3" = clusterKappa(
    Kgroups2,
    realLabels
  )
  
)


cat(
  "\n",
  kappaName,
  " - Hierarchical clustering:\n",
  sep = ""
)


print(
  round(
    WK_Hc,
    3
  )
)


cat(
  "\n",
  kappaName,
  " - K-means:\n",
  sep = ""
)


print(
  round(
    WK_Km,
    3
  )
)



###############################################################################
#  HIERARCHICAL KAPPA GRAPH
###############################################################################

kappaRange <- range(
  
  c(
    0,
    1,
    WK_Hc,
    WK_Km
  ),
  
  na.rm = TRUE
  
)


smallPlot()


plot(
  
  WK_Hc,
  
  type = "o",
  
  pch = 19,
  
  cex = 0.7,
  
  xaxt = "n",
  
  xlab = "",
  
  ylim = kappaRange,
  
  ylab = kappaName,
  
  main = "Hierarchical Clustering"
  
)


axis(
  
  1,
  
  at = 1:3,
  
  labels = names(WK_Hc),
  
  cex.axis = 0.55
  
)



###############################################################################
#  K-MEANS KAPPA GRAPH
###############################################################################

smallPlot()


plot(
  
  WK_Km,
  
  type = "o",
  
  pch = 19,
  
  cex = 0.7,
  
  xaxt = "n",
  
  xlab = "",
  
  ylim = kappaRange,
  
  ylab = kappaName,
  
  main = "K-Means Clustering"
  
)


axis(
  
  1,
  
  at = 1:3,
  
  labels = names(WK_Km),
  
  cex.axis = 0.55
  
)



###############################################################################
#  B5. FAIR COMPARISON - EVERY METHOD WITH k = 3
###############################################################################

average3 <- cutree(
  
  hclust(
    d,
    method = "average"
  ),
  
  k = 3
  
)


single3 <- cutree(
  
  hclust(
    d,
    method = "single"
  ),
  
  k = 3
  
)


complete3 <- cutree(
  
  hclust(
    d,
    method = "complete"
  ),
  
  k = 3
  
)



fair <- c(
  
  "Average" = clusterKappa(
    average3,
    realLabels
  ),
  
  "Single" = clusterKappa(
    single3,
    realLabels
  ),
  
  "Complete" = clusterKappa(
    complete3,
    realLabels
  ),
  
  "K-means" = clusterKappa(
    Kgroups2,
    realLabels
  )
  
)


cat(
  "\n==================================================\n"
)


cat(
  "FAIR COMPARISON: k = 3 FOR EVERY METHOD\n"
)


cat(
  "==================================================\n"
)


print(
  round(
    fair,
    3
  )
)



###############################################################################
#  FAIR COMPARISON BAR CHART
###############################################################################

smallPlot()


barplot(
  
  fair,
  
  cex.names = 0.7,
  
  ylab = kappaName,
  
  main = "Clustering Methods - k = 3",
  
  ylim = c(
    min(
      0,
      fair,
      na.rm = TRUE
    ),
    1
  )
  
)



###############################################################################
#  FINAL SUMMARY
###############################################################################

cat(
  "\n\n==================================================\n"
)


cat(
  "FINAL SUMMARY\n"
)


cat(
  "==================================================\n"
)


cat(
  
  sprintf(
    
    "\nUnpruned decision tree accuracy: %.2f%%\n",
    
    100 * treeAccuracy
    
  )
  
)


cat(
  
  sprintf(
    
    "Best pruned tree accuracy:       %.2f%%\n",
    
    100 * bestTreeAccuracy
    
  )
  
)


cat(
  
  sprintf(
    
    "Best KNN (k = %d) accuracy:       %.2f%%\n",
    
    bestK,
    
    100 * bestKAccuracy
    
  )
  
)


cat(
  
  "\n",
  
  kappaName,
  
  " for clustering (all k = 3):\n",
  
  sep = ""
  
)


print(
  round(
    fair,
    3
  )
)


cat(
  "\nProject completed successfully.\n"
)

###############################################################################
#  END OF WHEAT SEEDS PROJECT
###############################################################################
