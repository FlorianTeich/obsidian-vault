```python
import erdantic as erd
from erdantic.examples.pydantic import Party

# Easy one-liner
erd.draw(Party, out="diagram.png")

# Or create a diagram object that you can inspect and do stuff with
diagram = erd.create(Party)
diagram.draw("diagram.png")
```