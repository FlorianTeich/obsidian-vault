```python
from pycaret.datasets import get_data
from pycaret.classification import *

data = get_data('diabetes')
s = setup(data, target = 'Class variable', session_id = 123)
best = compare_models()
evaluate_model(best)
```
