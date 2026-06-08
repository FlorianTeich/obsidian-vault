```python
import sys
import inspect
import functools
from opentelemetry import trace, context as otel_context
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

provider = TracerProvider(
    resource=Resource.create({
        "service.name": "my-python-app"
    })
)

provider.add_span_processor(
    BatchSpanProcessor(
        OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
    )
)

trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)


def auto_trace(func):
    """Decorator that creates a span for the function and every Python function it calls."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        _tracer = trace.get_tracer(func.__module__)
        frame_spans: dict = {}

        def _trace(frame, event, arg):
            if frame.f_globals.get("__name__", "").startswith("opentelemetry"):
                return
            if event == "call":
                name = getattr(frame.f_code, "co_qualname", frame.f_code.co_name)
                span = _tracer.start_span(name)
                for key, val in frame.f_locals.items():
                    try:
                        span.set_attribute(f"arg.{key}", str(val))
                    except Exception:
                        pass
                token = otel_context.attach(trace.set_span_in_context(span))
                frame_spans[id(frame)] = (span, token)
                return _trace
            elif event == "return":
                entry = frame_spans.pop(id(frame), None)
                if entry:
                    span, token = entry
                    try:
                        span.set_attribute("return_value", str(arg))
                    except Exception:
                        pass
                    span.end()
                    otel_context.detach(token)
            elif event == "exception":
                entry = frame_spans.get(id(frame))
                if entry:
                    _, exc_val, _ = arg
                    span, _ = entry
                    if exc_val is not None:
                        span.record_exception(exc_val)
                        span.set_status(trace.StatusCode.ERROR)

        with _tracer.start_as_current_span(func.__qualname__) as outer_span:
            try:
                bound = inspect.signature(func).bind(*args, **kwargs)
                bound.apply_defaults()
                for key, val in bound.arguments.items():
                    try:
                        outer_span.set_attribute(f"arg.{key}", str(val))
                    except Exception:
                        pass
            except Exception:
                pass
            old_trace = sys.gettrace()
            sys.settrace(_trace)
            try:
                result = func(*args, **kwargs)
                try:
                    outer_span.set_attribute("return_value", str(result))
                except Exception:
                    pass
            finally:
                sys.settrace(old_trace)
                for span, token in frame_spans.values():
                    span.end()
                    otel_context.detach(token)
                frame_spans.clear()
        return result

    return wrapper


def some_function():
    return "Hello"

@auto_trace
def do_work(arg1, arg2):
    some_var = some_function()
    return str(arg1) + str(arg2) + some_var

do_work(1, 2)
```

## docker-compose.yaml
```yaml
services:
  otel-collector:
    image: otel/opentelemetry-collector
    volumes:
      - ./otel-collector-config.yaml:/etc/otelcol/config.yaml
    ports:
      - 1888:1888 # pprof extension
      - 8888:8888 # Prometheus metrics exposed by the Collector
      - 8889:8889 # Prometheus exporter metrics
      - 13133:13133 # health_check extension
      - 4317:4317 # OTLP gRPC receiver
      - 4318:4318 # OTLP http receiver
      - 55679:55679 # zpages extension

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
```

## otel-collector-config.yaml (Config file)
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  debug:
    verbosity: detailed
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [debug, otlp/jaeger]
    metrics:
      receivers: [otlp]
      exporters: [debug]
    logs:
      receivers: [otlp]
      exporters: [debug]
```
