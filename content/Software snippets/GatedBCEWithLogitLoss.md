```python
from typing import Optional
from torch import Tensor
from torch.nn.functional import binary_cross_entropy_with_logits
from torch.nn.modules.loss import BCEWithLogitsLoss


class GatedBCEWithLogitsLoss(BCEWithLogitsLoss):
    """Gated Binary Cross Entropy with Logits Loss for ignoring specific indices."""

    def __init__(
        self,
        weight: Optional[Tensor] = None,
        size_average: Optional[bool] = None,
        reduce: Optional[bool] = None,
        reduction: str = "mean",
        pos_weight: Optional[Tensor] = None,
        ignore_index: int = -100,
    ):
        super().__init__(weight, size_average, reduce, reduction, pos_weight)
        self.register_buffer("weight", weight)
        self.register_buffer("pos_weight", pos_weight)
        self.weight: Optional[Tensor]
        self.pos_weight: Optional[Tensor]
        self.ignore_index = ignore_index

    def forward(self, input: Tensor, target: Tensor) -> Tensor:
        mask = target != self.ignore_index
        results_per_sample = binary_cross_entropy_with_logits(
            input, target, self.weight, pos_weight=self.pos_weight, reduction="none"
        )
        if self.reduction == "mean":
            return results_per_sample[mask].mean()
        if self.reduction == "sum":
            return results_per_sample[mask].sum()
        raise ValueError(f"Unknown reduction: {self.reduction}")
