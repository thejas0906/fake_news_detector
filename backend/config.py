from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: str
    MAIL_PORT: int
    MAIL_SERVER: str
    MAIL_FROM_NAME: str
    MAIL_STARTTLS: bool
    MAIL_SSL_TLS: bool
    USE_CREDENTIALS: bool

    # AUTH SETTINGS
    secret_key: str
    algorithm: str
    access_token_expire_minutes: int

    # DATABASE
    db_url: str

    # PASSWORD RESET
    reset_token_expire_minutes: int
    password_reset_secret_key: str
    app_host: str
    forget_password_url: str

    OTP_EXPIRY_MINUTES: int = 10 

    class Config:
        env_file = ".env"


settings = Settings()