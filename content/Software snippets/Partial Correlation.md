```python
# Check if any two variables are independent, conditioned on a third variable

# https://math.stackexchange.com/questions/26042/understanding-conditional-independence-of-two-random-variables-given-a-third-one

# Compute partial correlations
import pingouin as pg
from sklearn.datasets import load_wine
import pandas as pd

data = load_wine(as_frame=True).frame
# Compute the partial correlation between feature 0 and feature 1, conditioned on feature 2
partial_corr = pg.partial_corr(
	data=data,
	x="feature_0",
	y="feature_1",
	covar="feature_2",
	method="pearson",
)

partial_corr
```
