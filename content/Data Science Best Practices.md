## Problem Understanding Phase:

### Right tool for the task
First look into the problem at hand before locking an ML approach in. Way too often peers decide on their solution (spoiler alert: LLMs) before having understood the problem. This is the wrong causal direction. With a hammer in your hands, every problem looks like a nail.

### Business value function
Early on in your project, try to create the business value function you want to optimize. It will be suboptimal if you only go for accuracy or f1 score or any other metric if the company/customer could provide you with details like:
	* how much does a misclassification cost the company?
	* how much does the company benefit from a correct classification?
	* probabl_ai has many videos on this procedure (https://www.youtube.com/@probabl_ai)

## EDA Phase:

### Put shared code into scripts, not Notebooks
Write essential code in scripts, not in Notebooks. This way you can define functions and classes in your scripts and reference them inside your notebooks

### Thorough EDA
Do thorough EDA. Often times I see projects where basic statistical properties of the input features are checked way too late (e.g. at the time the prediction performance is below expectation). Data Profiling libraries as ydatas pandas_profiling do an excellent job showing stats like: unique values, null values, distributions and data types of variables as well as very rudimentary relations between them (correlations etc).

### Check your data
[[Software snippets/Data Quality Check from scratch.md | Check your data.]] Example for supervised learning: check how many samples have identical features but different labels.

It's unrealistic to expect a supervised ML approach to achieve high performance if the set of identical samples with different labels is highly prevalent.

### Quantify potential drift or leak from the get go

If you work on a classification task, after you created your train and test splits, strip away their labels and set the train labels to 0 and test labels to 1. Then merge these two tables and do CrossValidation. If you can easily predict which samples the test samples are, chances are there might be some heavy drift.

### Synthetic data as support for tests
If you work with sensible data: focus on producing synthetic data early on. There are great libraries for that. This way, you can kill two birds with one stone: model a Directed Acyclic Graph of how you think the data creation process happens and model the individual variable distributions. Then sample from this DAG your artificial data. Important: this artificial data helps identifying edge-cases in your software; it's not meant to train your final classifier on it.

### Big data
If you work with a lot of data and you cannot satisfy the memory requirements of your in-memory dataframe library (pandas/polars), look at pyspark. It has a steep learning curve, but many of its concepts are not tied to pyspark itself but big-data processing, distributed systems and SQL in general.

### Feature Importance Baseline
Create an additional feature that is random and train a model. This might give you a baseline for which features are important (higher importance than the noise feature).

## Training Phase:

### Split by time, not arbitrarily to avoid future leaks
Remember to consider future leaks. Most likely you should split your offline dataset by time, not randomly.

### Avoid train-test skew
Avoid train-test skew: Make sure to use the same preprocessing of your data during training and during inference.

### Don't forget to scale your data
Depending on your algorithm, do not forget to start your preprocessing by normalization. As a rule of thumb:
	* Decision Trees, XGBoost: no scaling
	* SVM, Logistic Regression, Ridge, Lasso, PCA: Z-score standardization
	* ANN, KNN: Min-Max scaling or Z-score standardization

### Model-based feature
Concrete example from Puget, who trained a model to predict the objective house price in order to use this prediction to figure out how much the offer of an advertisement was above or below this market-price.

### Denoising
If your data is very noisy, a denoising autoencoder might help a lot.

### ML specific tests
Write ML-specific test
* anchor sample test: the idea is to find extreme samples or feature engineer such constructed cases where the correct label is very clear since the feature values are stereotypical for this class
* [[Software snippets/PyTorch - Sample-order-invariance-test.md | batch sample-order invariance test ]]
* [[Software snippets/PyTorch - Directional feature variance test.md | feature variance test (directional) ]]
* [[Software snippets/PyTorch - Overfitting on Sample test.md | overfitting on sample test ]]
* overfitting on batch test

## Evaluation Phase:

### Choose your champion wisely
Do not blindly select your champion model by its validation split performance. If you are interested in a generalizing model, also consider the gap between train split performance and validation split performance.

Example:

(Higher performance values are better)

| Model   | Train Performance | Validation Performance |
+---------+-------------------+------------------------+
| Model A | 99.60             | 90.18                  |
| Model B | 91.72             | 90.14                  |

Selecting Model A as your final model would not be advisable here.


### Calibration
Check the calibration of your model on the given data. If needed, recalibrate your model

### Think in upper and lower bounds
Think in upper or lower bounds. If anyone asks you what the minimum performance of your machine learning approach is, write a quick benchmark in three steps:
	1. using a classifier that predicts randomly.
	2. Then, add a probability prior based on the class distributions.
	3. [[Software snippets/automl via pycaret.md | Some AutoML-Estimator (eg. using pycaret) ]]
Quickly you will get a grasp of your performance floor and ceiling

## Deployment Phase:

### Monitoring
Monitor the data, the predictions and their drift. Retrain if necessary.

### Use the pipeline design pattern
Frameworks like Kubeflow Pipelines, Apache Airflow and Kedro exist (and thrive) for a reason. Write pipelines, composed of smaller units/components in order to reuse these smaller units. Make these components hermetic: all used data should be referenced by variables inside the function signature. Otherwise you will have side effects as some global variables may change the flow of your component and you can not identify this dependency by looking at the signature.