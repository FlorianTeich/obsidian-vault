```python
import torch

class SimpleModel(torch.nn.Module):
	def __init__(self):
		super(SimpleModel, self).__init__()
		self.linear = torch.nn.Linear(10, 1)

	def forward(self, x):
		return self.linear(x)

def test_model_output_permutation():
	# Create a simple model
	model = SimpleModel()
	# Generate random input data
	input_data = torch.randn(2, 10)
	# Get the output for the first order
	output_first_order = model(input_data)
	# Get the output for the second order (permuted)
	permuted_input_data = input_data[1:2, :]
	permuted_input_data = torch.cat((input_data[0:1, :], permuted_input_data), dim=0)
	output_second_order = model(permuted_input_data)
	# Check if the outputs are equal
	assert torch.allclose(output_first_order, output_second_order), "Output changed with input permutation"
```
