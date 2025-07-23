```python
from torch.utils.tensorboard import SummaryWriter
import torch
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split

X, y = make_classification(n_samples=100, n_features=4, random_state=31)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Define a simple neural network
class SimpleNN(torch.nn.Module):
	def __init__(self):
		super(SimpleNN, self).__init__()
		self.fc1 = torch.nn.Linear(4, 8)
		self.fc2 = torch.nn.Linear(8, 2)
		self.counter = 0
	def forward(self, x, iteration: int = 0, **kwargs):
		x = torch.relu(self.fc1(x))
		x = self.fc2(x)
		return x

model = SimpleNN()

criterion = torch.nn.CrossEntropyLoss()

optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

def train(iteration_number: int=0):
	optimizer.zero_grad()
	output = model(torch.tensor(X_train).float(), iteration=iteration_number)
	loss = criterion(output, torch.tensor(y_train))
	loss.backward()
	optimizer.step()
	
summary_writer = SummaryWriter(log_dir="tb_logs")

# add hooks to model to get activations and gradients
def get_activation(name, iteration):
	def hook(mdl, input, output):
		summary_writer.add_histogram(f"activations_{name}", output.detach().numpy(), iteration)
	return hook

def get_gradient(name, iteration):
	def hook(mdl, grad_input, grad_output):
		if name == "fc1":
			model.counter += 1
		summary_writer.add_histogram(f"gradients_{name}", grad_output[0].detach().numpy(), iteration)
	return hook

for i in range(10):
	# Plot weights of each layer
	for layer, weights in model.named_parameters():
		summary_writer.add_histogram(f"weights_{layer}", weights.detach().numpy(), i)
	handles = []
	for layername, module in model.named_children():
		handles.append(dict(model.named_children())[layername].register_forward_hook(get_activation(layername, i), with_kwargs=False))
		handles.append(dict(model.named_children())[layername].register_forward_hook(get_gradient(layername, i), with_kwargs=False))

	train(i)

	for handle in handles:
		handle.remove()
	summary_writer.flush()

# Check for NaNs in weights
for layer, weights in model.named_parameters():
	if torch.isnan(weights).any():
		print(f"NaNs detected in {layer}")
```