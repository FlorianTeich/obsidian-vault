```python
import logging
import logging.config
import sys

def setup_logger(log_file: str):
    log_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "detailed": {
                "format": "%(asctime)s.%(msecs)03d | %(levelname)-8s | %(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S"
            }
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "level": "DEBUG",
                "formatter": "detailed",
                "stream": sys.stdout
            },
            "file": {
                "class": "logging.FileHandler",
                "level": "DEBUG",
                "formatter": "detailed",
                "filename": log_file,
                "mode": "a",
                "encoding": "utf-8"
            }
        },
        "root": {
            "level": "DEBUG",
            "handlers": ["console", "file"]
        }
    }

    logging.config.dictConfig(log_config)
    return logging.getLogger()  # root logger

# Example usage
if __name__ == "__main__":
    log = setup_logger("app.log")
```