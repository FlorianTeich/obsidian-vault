```python
from yfiles_jupyter_graphs import GraphWidget

w = GraphWidget()
w.nodes = [
    {"id": 0, "properties": {"firstName": "Alpha", "label": "Person A"}},
    {"id": "one", "properties": {"firstName": "Bravo", "label": "Person B"}},
    {"id": 2.0, "properties": {"firstName": "Charlie", "label": "Person C", "has_hat": False}},
    {"id": True, "properties": {"firstName": "Delta", "label": "Person D", "likes_pizza": True}}
]
w.edges = [
    {"id": "zero", "start": 0, "end": "one", "properties": {"since": "1992", "label": "knows"}},
    {"id": 1, "start": "one", "end": True, "properties": {"label": "knows", "since": "1992"}},
    {"id": 2.0, "start": 2.0, "end": True, "properties": {"label": "knows", "since": "1992"}},
    {"id": False, "start": 0, "end": 2.0, "properties": {"label": "knows", "since": 234}}
]
w.directed = True

display(w)
```