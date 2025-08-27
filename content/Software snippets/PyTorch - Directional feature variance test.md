```python
import torch

class SimpleModel(torch.nn.Module):
	def __init__(self):
		super(SimpleModel, self).__init__()
		self.linear = torch.nn.Linear(10, 1)

	def forward(self, x):
		return self.linear(x)

def test_model_output_change():
	# Create a simple model
	model = SimpleModel()
	
	# Generate random input data
	input_data = torch.randn(1, 10)
	
	# Get the initial output
	initial_output = model(input_data)
	
	# Modify the input data slightly
	modified_input_data = input_data.clone()
	modified_input_data[0, 0] += 0.1 # Change one feature

	# Get the modified output
	modified_output = model(modified_input_data)
	
	# Check if the outputs are different
	assert not torch.allclose(initial_output, modified_output), "Output did not change with input modification"
```