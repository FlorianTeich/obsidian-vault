```python
from sklearn.datasets import load_wine
import pandas as pd
import pygwalker as pyg

data = load_wine(as_frame=True).frame
walker = pyg.walk(data)
walker
