```python
from __future__ import annotations

import functools
import logging
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any, Callable

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


@dataclass
class Event:
    """Payload delivered to every handler."""
    name: str
    function: str
    args: tuple = field(default_factory=tuple)
    kwargs: dict = field(default_factory=dict)
    result: Any = None


class EventBus:
    """Simple synchronous event bus."""

    def __init__(self) -> None:
        self._subscribers: dict[str, list[Callable[[Event], Any]]] = defaultdict(list)

    def subscribe(self, event: str, handler: Callable[[Event], Any]) -> None:
        """Register *handler* to be called whenever *event* is published."""
        self._subscribers[event].append(handler)

    def unsubscribe(self, event: str, handler: Callable[[Event], Any]) -> None:
        """Remove a previously registered *handler* for *event*."""
        self._subscribers[event].remove(handler)

    def publish(self, event: Event) -> None:
        """Dispatch *event* to all registered handlers."""
        for handler in list(self._subscribers[event.name]):
            handler(event)

    def on(self, event: str) -> Callable:
        """Decorator — subscribe the decorated function as a handler for *event*."""
        def decorator(fn: Callable[[Event], Any]) -> Callable[[Event], Any]:
            self.subscribe(event, fn)
            return fn
        return decorator

    def emit(self, event: str | None = None, *, before: bool = False) -> Callable:
        """Decorator — publish an event whenever the decorated function is called.

        Args:
            event:  Event name.  Defaults to ``"<module>.<qualname>"``.
            before: When ``True``, also publish ``"<event>.before"`` before the
                    call with the original arguments (result will be ``None``).
        """
        def decorator(fn: Callable) -> Callable:
            resolved_event = event or f"{fn.__module__}.{fn.__qualname__}"

            @functools.wraps(fn)
            def wrapper(*args: Any, **kwargs: Any) -> Any:
                if before:
                    self.publish(Event(
                        name=f"{resolved_event}.before",
                        function=fn.__qualname__,
                        args=args,
                        kwargs=kwargs,
                    ))
                result = fn(*args, **kwargs)
                self.publish(Event(
                    name=resolved_event,
                    function=fn.__qualname__,
                    args=args,
                    kwargs=kwargs,
                    result=result,
                ))
                return result

            return wrapper
        return decorator


# ---------------------------------------------------------------------------
# Module-level default bus — import and use directly, or create your own.
# ---------------------------------------------------------------------------
bus = EventBus()


# ---------------------------------------------------------------------------
# Example usage
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    logger = logging.getLogger("demo")

    # Validate *before* the call
    @bus.on("order.placed.before")
    def validate_order(event: Event) -> None:
        order_id, item = event.args
        logger.info("Validating  — id=%s  item=%s", order_id, item)

    # Log *after* the call (result is available)
    @bus.on("order.placed")
    def log_order(event: Event) -> None:
        logger.info("Order placed — result=%s", event.result)

    # Attach events to the function
    @bus.emit("order.placed", before=True)
    def place_order(order_id: int, item: str) -> dict:
        return {"order_id": order_id, "item": item, "status": "confirmed"}

    result = place_order(42, "keyboard")
    print(result)
```

## Alternative:
```python
from __future__ import annotations

import functools
import logging
from abc import ABC, abstractmethod
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any, Callable

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


@dataclass
class Event:
    """Payload delivered to every handler."""
    name: str
    function: str
    args: tuple = field(default_factory=tuple)
    kwargs: dict = field(default_factory=dict)
    result: Any = None


class EventBus:
    """Simple synchronous event bus."""

    def __init__(self) -> None:
        self._subscribers: dict[str, list[Callable[[Event], Any]]] = defaultdict(list)

    def subscribe(self, event: str, handler: Callable[[Event], Any]) -> None:
        """Register *handler* to be called whenever *event* is published."""
        self._subscribers[event].append(handler)

    def unsubscribe(self, event: str, handler: Callable[[Event], Any]) -> None:
        """Remove a previously registered *handler* for *event*."""
        self._subscribers[event].remove(handler)

    def publish(self, event: Event) -> None:
        """Dispatch *event* to all registered handlers."""
        for handler in list(self._subscribers[event.name]):
            handler(event)

    def on(self, event: str) -> Callable:
        """Decorator — subscribe the decorated function as a handler for *event*."""
        def decorator(fn: Callable[[Event], Any]) -> Callable[[Event], Any]:
            self.subscribe(event, fn)
            return fn
        return decorator

    def emit(self, event: str | None = None, *, before: bool = False) -> Callable:
        """Decorator — publish an event whenever the decorated function is called.

        Args:
            event:  Event name.  Defaults to ``"<module>.<qualname>"``.
            before: When ``True``, also publish ``"<event>.before"`` before the
                    call with the original arguments (result will be ``None``).
        """
        def decorator(fn: Callable) -> Callable:
            resolved_event = event or f"{fn.__module__}.{fn.__qualname__}"

            @functools.wraps(fn)
            def wrapper(*args: Any, **kwargs: Any) -> Any:
                if before:
                    self.publish(Event(
                        name=f"{resolved_event}.before",
                        function=fn.__qualname__,
                        args=args,
                        kwargs=kwargs,
                    ))
                result = fn(*args, **kwargs)
                self.publish(Event(
                    name=resolved_event,
                    function=fn.__qualname__,
                    args=args,
                    kwargs=kwargs,
                    result=result,
                ))
                return result

            return wrapper
        return decorator


class Consumer(ABC):
    """Base class for structured event consumers.

    Subclass and implement :meth:`handle`, then call :meth:`register` to
    attach the consumer to one or more events on a bus.
    """

    @abstractmethod
    def handle(self, event: Event) -> None:
        """Process a published event."""

    def register(self, bus: EventBus, *events: str) -> Consumer:
        """Subscribe this consumer to *events* on *bus*. Returns *self* for chaining."""
        for ev in events:
            bus.subscribe(ev, self.handle)
        return self


# ---------------------------------------------------------------------------
# Module-level default bus — import and use directly, or create your own.
# ---------------------------------------------------------------------------
bus = EventBus()


# ---------------------------------------------------------------------------
# Example usage
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    logger = logging.getLogger("demo")

    class LoggingConsumer(Consumer):
        """Logs every before/after event it is subscribed to."""

        def __init__(self, log: logging.Logger) -> None:
            self._log = log

        def handle(self, event: Event) -> None:
            if event.name.endswith(".before"):
                self._log.info(
                    "[before] %s  args=%s  kwargs=%s",
                    event.function, event.args, event.kwargs,
                )
            else:
                self._log.info(
                    "[after]  %s  result=%s",
                    event.function, event.result,
                )

    class TracingConsumer(Consumer):
        """Records a minimal trace span for every subscribed before/after event pair."""

        def __init__(self) -> None:
            self._open_spans: dict[str, dict] = {}

        def handle(self, event: Event) -> None:
            base = event.name.removesuffix(".before")
            if event.name.endswith(".before"):
                self._open_spans[base] = {"function": event.function, "args": event.args}
                print(f"[trace] SPAN START  {event.function}  args={event.args}")
            else:
                span = self._open_spans.pop(base, {})
                print(
                    f"[trace] SPAN END    {event.function}"
                    f"  result={event.result!r}"
                    f"  input_args={span.get('args')}"
                )

    # Wire up consumers
    logging_consumer = LoggingConsumer(logger)
    tracing_consumer = TracingConsumer()

    logging_consumer.register(bus, "order.placed.before", "order.placed")
    tracing_consumer.register(bus, "order.placed.before", "order.placed")

    @bus.emit("order.placed", before=True)
    def place_order(order_id: int, item: str) -> dict:
        return {"order_id": order_id, "item": item, "status": "confirmed"}

    result = place_order(42, "keyboard")
    print(result)
```
