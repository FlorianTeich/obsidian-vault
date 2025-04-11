```python
import numpy as np
import pandas as pd
from ydata_profiling import ProfileReport
from sklearn.datasets import load_wine

data = load_wine(as_frame=True).frame
profile = ProfileReport(data, title="Profiling Report")
profile.to_file("your_report.html")