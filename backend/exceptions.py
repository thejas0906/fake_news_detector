from fastapi import HTTPException
from enum import Enum
class CustomHttpException(HTTPException):
    def __init__(self, status_code: int, detail: str,error_level=None):
        super().__init__(status_code=status_code, detail=detail)

class ErrorLevel(str, Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    ERROR_LEVEL_2=2