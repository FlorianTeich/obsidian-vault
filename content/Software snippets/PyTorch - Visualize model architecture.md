![](resources/model_graph.svg)

```python
import torch
from transformers import AutoTokenizer, utils
from transformers import AutoModelForSequenceClassification, AutoTokenizer
from torchview import draw_graph
import matplotlib.pyplot as plt
from PIL import Image

model_name = "roberta-base"

tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name)

batch = tokenizer.batch_encode_plus(["test"], max_length = 512, truncation=True, padding='max_length')
batch["input_ids"] = torch.tensor(batch["input_ids"])
batch["attention_mask"] = torch.tensor(batch["attention_mask"])
batch["token_type_ids"] = torch.zeros_like(batch["attention_mask"])

model_graph = draw_graph(model, input_data=batch)

img = model_graph.visual_graph

# Graphviz object to png:
img.save("model_graph.gvz")
img.render("model_graph", format="png", cleanup=True)
img.render("model_graph", format="svg", cleanup=True)

img = Image.open("model_graph.png")
plt.imshow(img)
plt.axis('off')  # Hide axes
plt.show()
```