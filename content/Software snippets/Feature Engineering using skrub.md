```python
from skrub import TableVectorizer
from skrub.datasets import fetch_employee_salaries

dataset = fetch_employee_salaries()
employees, salaries = dataset.X, dataset.y
vectorizer = TableVectorizer()
vectorized_employees = vectorizer.fit_transform(employees)
vectorized_employees
```