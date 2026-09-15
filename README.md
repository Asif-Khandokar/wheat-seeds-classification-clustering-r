# Wheat Seed Classification & Clustering in R

A machine learning project in **R** comparing supervised classification and unsupervised clustering techniques using the **UCI Seeds Dataset**.

The project evaluates **Decision Trees** and **K-Nearest Neighbours (KNN)** for classification, alongside **Hierarchical Clustering** and **K-Means** for discovering natural groupings within wheat kernel measurements.

The complete workflow covers data acquisition, preprocessing, feature standardisation, model training, decision-tree pruning, model comparison, clustering and performance evaluation.

---

## Project Overview

The objective of this project is to investigate how effectively different machine learning techniques can identify and group three varieties of wheat using physical measurements of their kernels.

The project is divided into two sections:

### Part A — Classification

Supervised machine learning algorithms are trained using known wheat class labels.

Models evaluated:

- Decision Tree
- Pruned Decision Trees
- K-Nearest Neighbours (KNN)

### Part B — Clustering

Unsupervised learning methods are used to identify natural groupings without using the class labels during clustering.

Methods evaluated:

- Hierarchical Clustering
  - Average Linkage
  - Single Linkage
  - Complete Linkage
- K-Means Clustering

The resulting clusters are compared with the known wheat varieties using **Cohen's Kappa**.

---

## Dataset

This project uses the **Seeds Dataset** from the UCI Machine Learning Repository.

The dataset contains:

- **210 wheat kernel observations**
- **7 numerical features**
- **3 wheat varieties**

The three wheat varieties are:

1. Kama
2. Rosa
3. Canadian

### Features

| Feature | Description |
|---|---|
| Area | Area of the wheat kernel |
| Perimeter | Perimeter of the kernel |
| Compactness | Compactness measurement |
| Kernel Length | Length of the kernel |
| Kernel Width | Width of the kernel |
| Asymmetry Coefficient | Degree of kernel asymmetry |
| Groove Length | Length of the kernel groove |

### Automatic Data Loading

No manual dataset download is required.

When the script is run for the first time, it automatically downloads the Seeds dataset from the UCI Machine Learning Repository and saves a local copy as:

```text
seeds.csv
```

On later runs, the script uses the local copy if it is available.

The generated `seeds.csv` file is excluded from version control using `.gitignore`.

---

## Technologies & Techniques

### Programming

- R

### R Packages

- `class`
- `rpart`
- `rpart.plot`

### Machine Learning

- K-Nearest Neighbours
- Decision Trees
- Decision Tree Pruning
- K-Means Clustering
- Hierarchical Clustering

### Data Science Techniques

- Train-test splitting
- Feature standardisation
- Model evaluation
- Confusion matrices
- Hyperparameter comparison
- Cross-validation
- Euclidean distance
- Cluster evaluation
- Cohen's Kappa
- Reproducible analysis

---

## Project Workflow

```text
UCI Seeds Dataset
        |
        v
Data Validation
        |
        v
Data Preparation
        |
        +------------------------+
        |                        |
        v                        v
 Classification              Clustering
        |                        |
        v                        v
 Decision Tree          Standardise Features
        |                        |
        v                        +-------------------+
 Tree Pruning                   |                   |
        |                       v                   v
        +-----> KNN      Hierarchical          K-Means
        |                 Clustering            Clustering
        v                       |                   |
Model Comparison                +---------+---------+
                                          |
                                          v
                                  Cluster Evaluation
                                          |
                                          v
                                     Final Results
```

---

# Part A — Classification

## Train-Test Split

The dataset is randomly shuffled before being divided into:

- **150 training observations**
- **60 testing observations**

A fixed random seed is used to make the analysis reproducible.

```r
set.seed(2026)
```

The training data is used to build the models, while the test data remains separate for final performance evaluation.

---

## Decision Tree

A classification decision tree is trained using all seven wheat kernel measurements.

The analysis includes:

- training an initial decision tree
- generating predictions on unseen test data
- calculating test accuracy
- producing a confusion matrix
- analysing the complexity parameter
- pruning the tree
- selecting the pruning parameter using cross-validation

### Decision Tree Performance

| Model | Test Accuracy |
|---|---:|
| Unpruned Decision Tree | **88.33%** |
| Best Pruned Decision Tree | **88.33%** |

The pruning analysis allows different levels of tree complexity to be compared while investigating whether reducing model complexity improves generalisation.

---

## K-Nearest Neighbours

KNN was evaluated using multiple odd values of `k`:

```text
1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21
```

Odd values help reduce the possibility of tied neighbour votes.

### Feature Standardisation

KNN relies on distances between observations, so features with larger numerical ranges could otherwise dominate the model.

The training features are therefore standardised.

Importantly, the test set is transformed using the **mean and standard deviation calculated from the training data only**, helping prevent data leakage.

### Best KNN Performance

| Metric | Result |
|---|---:|
| Best `k` | **5** |
| Test Accuracy | **93.33%** |

Several values of `k` produced strong results, with the best-performing KNN model exceeding the decision-tree test accuracy.

---

## Classification Comparison

| Model | Test Accuracy |
|---|---:|
| KNN (`k = 5`) | **93.33%** |
| KNN (`k = 7`) | **93.33%** |
| KNN (`k = 19`) | **93.33%** |
| KNN (`k = 21`) | **93.33%** |
| KNN (`k = 3`) | 91.67% |
| KNN (`k = 9`) | 91.67% |
| Decision Tree | 88.33% |

### Classification Finding

For this train-test split, **KNN achieved the highest classification accuracy**.

The best KNN model achieved:

```text
93.33% test accuracy
```

compared with:

```text
88.33% test accuracy
```

for the decision-tree model.

---

# Part B — Clustering

## Data Preprocessing

The seven numerical features are standardised before clustering.

Standardisation is particularly important for distance-based clustering because the variables have different numerical scales.

Euclidean distance is then used for hierarchical clustering.

---

## Hierarchical Clustering

Three linkage strategies are investigated:

### Average Linkage

Average linkage considers the average distance between observations belonging to different clusters.

### Single Linkage

Single linkage uses the minimum distance between observations belonging to different clusters.

For `k = 3`, single linkage produced highly unbalanced cluster sizes:

```text
206, 3, 1
```

This demonstrates the well-known **chaining effect** of single-linkage clustering.

### Complete Linkage

Complete linkage considers the maximum distance between observations belonging to different clusters and produced substantially stronger agreement with the known wheat classes than single linkage.

---

## K-Means Clustering

K-Means clustering was evaluated using:

```text
k = 5
k = 7
k = 3
```

To reduce dependence on a single random initialisation, the algorithm uses:

```r
nstart = 25
```

This runs K-Means from multiple starting configurations and keeps the best solution found.

### K-Means with Three Clusters

When `k = 3`, K-Means produced the following cluster sizes:

```text
67, 71, 72
```

This created three relatively balanced clusters across the 210 observations.

---

## Cluster Evaluation

The dataset contains three actual wheat varieties.

For a like-for-like comparison, all clustering methods are therefore evaluated using:

```text
k = 3
```

Cluster numbers themselves do not represent wheat classes, so each cluster is mapped to its dominant known class before agreement is calculated.

The clustering solutions are then evaluated using **Cohen's Kappa**.

---

## Clustering Results

| Clustering Method | Cohen's Kappa |
|---|---:|
| K-Means | **0.879** |
| Average Linkage | 0.821 |
| Complete Linkage | 0.814 |
| Single Linkage | 0.021 |

### Clustering Finding

For the `k = 3` comparison, **K-Means produced the strongest agreement with the known wheat varieties**, achieving:

```text
Cohen's Kappa = 0.879
```

Average and complete linkage also produced relatively strong agreement.

Single linkage performed poorly because its chaining behaviour resulted in one cluster containing almost the entire dataset.

---

# Final Results

## Classification

| Model | Result |
|---|---:|
| Unpruned Decision Tree | 88.33% accuracy |
| Best Pruned Decision Tree | 88.33% accuracy |
| Best KNN (`k = 5`) | **93.33% accuracy** |

## Clustering — All Methods with `k = 3`

| Method | Cohen's Kappa |
|---|---:|
| Average Linkage | 0.821 |
| Single Linkage | 0.021 |
| Complete Linkage | 0.814 |
| K-Means | **0.879** |

---

## Key Insights

- KNN achieved the highest classification accuracy in the experiment.
- Feature standardisation is important for distance-based machine learning algorithms.
- Using training-set statistics to scale test data helps avoid data leakage.
- Decision-tree pruning provides a way to investigate the relationship between complexity and generalisation.
- K-Means produced the strongest clustering agreement with the known wheat varieties.
- Single-linkage hierarchical clustering showed a strong chaining effect.
- Comparing clustering methods using the same number of clusters provides a more meaningful comparison.
- Multiple K-Means initialisations improve the robustness of the clustering solution.
- A fixed random seed improves reproducibility.

---

## Visualisations Generated by the Script

Running the R script generates several plots interactively, including:

- Decision Tree
- Decision Tree complexity parameter plot
- Pruned Decision Trees
- Decision Tree classification scatter plot
- KNN accuracy across values of `k`
- Pruned-tree accuracy comparison
- Hierarchical clustering dendrograms
- Hierarchical clustering pair plots
- K-Means pair plots
- Kappa comparison plots
- Final clustering comparison bar chart

The plots are generated when the analysis is executed and are not stored as screenshots in this repository.

---

## Repository Structure

```text
wheat-seeds-classification-clustering-r/
│
├── README.md
├── wheat_seeds_project.R
└── .gitignore
```

The dataset does not need to be included because the R script automatically downloads it when required.

---

## How to Run the Project

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/wheat-seeds-classification-clustering-r.git
```

### 2. Open the Project

Open:

```text
wheat_seeds_project.R
```

using **RStudio**.

### 3. Run the Script

Run the complete script.

On the first run, the script will:

1. check whether the dataset exists locally
2. download the UCI Seeds dataset if necessary
3. save a local copy as `seeds.csv`
4. validate the dataset
5. prepare the classification and clustering data
6. train the Decision Tree
7. evaluate different pruning parameters
8. train and compare KNN models
9. perform hierarchical clustering
10. perform K-Means clustering
11. calculate clustering agreement
12. generate visualisations
13. print the final results

No manual dataset download is required.

---

## Required R Packages

The analysis uses:

```r
library(class)
library(rpart)
library(rpart.plot)
```

If `rpart.plot` is not installed, the script attempts to install it automatically.

Alternatively, it can be installed manually using:

```r
install.packages("rpart.plot")
```

---

## Reproducibility

A fixed random seed is used:

```r
set.seed(2026)
```

This helps ensure that the random train-test split and K-Means initialisation can be reproduced.

---

## Possible Future Improvements

Potential extensions to the project include:

- repeated cross-validation
- automated KNN hyperparameter tuning
- Random Forest classification
- Support Vector Machines
- Logistic Regression
- Principal Component Analysis
- silhouette-score analysis
- elbow-method analysis
- automated cluster-number selection
- DBSCAN clustering
- confusion-matrix visualisation
- additional model evaluation metrics
- interactive visualisation using Shiny

---

## Skills Demonstrated

This project demonstrates practical experience with:

- R Programming
- Machine Learning
- Supervised Learning
- Unsupervised Learning
- Classification
- Clustering
- Data Preprocessing
- Feature Standardisation
- Train-Test Splitting
- Decision Trees
- Decision Tree Pruning
- K-Nearest Neighbours
- K-Means Clustering
- Hierarchical Clustering
- Cross-Validation
- Model Evaluation
- Confusion Matrices
- Cohen's Kappa
- Euclidean Distance
- Data Visualisation
- Reproducible Analysis

---

## Data Source

**UCI Machine Learning Repository — Seeds Dataset**

The dataset contains geometric measurements of wheat kernels belonging to three different wheat varieties.

Dataset source:

https://archive.ics.uci.edu/dataset/236/seeds

---

## Author

**Asif Khandokar**

MSc Data Science & Analytics  
Brunel University London

GitHub:  https://github.com/Asif-Khandokar

LinkedIn: https://www.linkedin.com/in/asif-khandokar/

---

## Project Purpose

This project was developed for educational and portfolio purposes to demonstrate practical application of classification, clustering, preprocessing, model evaluation and data analysis techniques using R.
