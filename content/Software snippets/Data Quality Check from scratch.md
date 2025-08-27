```python
import pandas as pd

data = {
	'Feature': [1, 2, 1, 4],
	'Label': [1, 2, 1, 2]
}

df = pd.DataFrame(data)

def test_dataframe_unique_rows(df):
	# Check if all rows are unique
	assert df.duplicated().sum() == 0, "Dataframe contains duplicate rows"
```