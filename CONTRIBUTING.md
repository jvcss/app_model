# Análise Completa: Sistema Centralizado de Logging e Observabilidade

Excelente visão! Vou fazer uma análise profunda ("sindicância") da sua aplicação e propor uma arquitetura centralizada de logging, exceções e observabilidade em nível sênior/enterprise.

## 🔍 Análise dos Artefatos Atuais

### 1. **Pontos de Notificação Identificados**

```
Frontend (Flutter):
├── NotificationsProvider (providers/notifications_provider.dart)
│   ├── success() - Notificações de sucesso
│   ├── error() - Notificações de erro
│   ├── warning() - Avisos
│   └── info() - Informações gerais
│
└── Uso espalhado em:
    ├── LoginPage (login/logout)
    ├── ForgotPasswordPage (fluxo de reset)
    ├── PasswordResetProvider (verificação OTP)
    └── AuthProvider (autenticação)

Backend (FastAPI):
├── HTTPException - Erros HTTP não tratados centralmente
├── Celery Tasks - Sem logging estruturado
├── Auth endpoints - Rate limiting sem logs
└── Database operations - Sem auditoria
```

### 2. **Gaps Críticos Detectados**

```
❌ Ausências Críticas:
- Nenhum sistema centralizado de logging
- Exceções não rastreadas end-to-end
- Sem correlação request_id entre frontend/backend
- Rate limiting sem observabilidade
- Operações de banco sem auditoria
- Celery tasks sem tracing
- Sem métricas de performance
- Sem alertas proativos
```

---

## 🏗️ Arquitetura Proposta: Sistema Centralizado de Observabilidade

### **Princípios de Design**

1. **Single Point of Truth**: Todos os logs fluem para um ponto central
2. **Correlation ID**: Rastreamento end-to-end de requests
3. **Structured Logging**: JSON estruturado para parsing automatizado
4. **Context Enrichment**: Metadados automáticos (user_id, ip, endpoint)
5. **Graceful Degradation**: Sistema continua funcionando se logging falhar

---

## 📦 Implementação Backend (FastAPI)

### **1. Core: Logging Centralizado**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">python</parameter>
<parameter name="title">app/core/logger.py - Sistema Centralizado de Logging</parameter>
<parameter name="id">centralized_logger</parameter>
<parameter name="content">"""
Sistema Centralizado de Logging e Observabilidade

Features:
- Logging estruturado em JSON
- Correlation IDs automáticos
- Integração nativa com Sentry
- Context enrichment (user, ip, endpoint)
- Performance tracking
- Auditoria automática de operações sensíveis
"""
import logging
import json
import time
import traceback
from contextvars import ContextVar
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from functools import wraps
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from sentry_sdk.integrations.celery import CeleryIntegration
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.config import settings
from app.helpers.getters import isDebugMode

# ==================== Context Vars para Request Tracking ====================
request_id_ctx: ContextVar[Optional[str]] = ContextVar('request_id', default=None)
user_id_ctx: ContextVar[Optional[int]] = ContextVar('user_id', default=None)
endpoint_ctx: ContextVar[Optional[str]] = ContextVar('endpoint', default=None)


# ==================== Inicialização do Sentry ====================
def init_sentry():
    """Inicializa Sentry para tracking de exceções em produção"""
    if not isDebugMode() and hasattr(settings, 'SENTRY_DSN'):
        sentry_sdk.init(
            dsn=settings.SENTRY_DSN,
            environment=settings.MODE,
            traces_sample_rate=1.0 if isDebugMode() else 0.2,  # 100% dev, 20% prod
            profiles_sample_rate=1.0 if isDebugMode() else 0.1,
            integrations=[
                FastApiIntegration(transaction_style="endpoint"),
                SqlalchemyIntegration(),
                CeleryIntegration()
            ],
            # Captura informações sensíveis apenas em dev
            send_default_pii=isDebugMode(),
            # Ignora erros esperados
            ignore_errors=[
                KeyboardInterrupt,
                "HTTPException"  # Erros de negócio não são bugs
            ]
        )


# ==================== Custom JSON Formatter ====================
class StructuredFormatter(logging.Formatter):
    """Formatter que gera logs estruturados em JSON"""
    
    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'request_id': request_id_ctx.get(),
            'user_id': user_id_ctx.get(),
            'endpoint': endpoint_ctx.get(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        
        # Adiciona exceção se existir
        if record.exc_info:
            log_data['exception'] = {
                'type': record.exc_info[0].__name__,
                'message': str(record.exc_info[1]),
                'traceback': traceback.format_exception(*record.exc_info)
            }
        
        # Adiciona campos extras
        if hasattr(record, 'extra_fields'):
            log_data.update(record.extra_fields)
        
        return json.dumps(log_data, ensure_ascii=False)


# ==================== Logger Factory ====================
def get_logger(name: str) -> logging.Logger:
    """
    Factory para criar loggers padronizados
    
    Usage:
        logger = get_logger(__name__)
        logger.info("Operação realizada", extra={'extra_fields': {'user_id': 123}})
    """
    logger = logging.getLogger(name)
    
    if not logger.handlers:
        handler = logging.StreamHandler()
        
        if isDebugMode():
            # Dev: logs legíveis
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
        else:
            # Prod: JSON estruturado
            formatter = StructuredFormatter()
        
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    
    return logger


# ==================== Middleware de Request Tracking ====================
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware que:
    - Gera request_id único
    - Enriquece contexto de logging
    - Mede performance
    - Loga todas as requisições HTTP
    """
    
    async def dispatch(self, request: Request, call_next):
        # Gera ou extrai request_id
        request_id = request.headers.get('x-request-id') or self._generate_request_id()
        request_id_ctx.set(request_id)
        
        # Extrai endpoint
        endpoint_ctx.set(f"{request.method} {request.url.path}")
        
        # Performance tracking
        start_time = time.time()
        
        logger = get_logger('api.request')
        
        # Log de entrada
        logger.info(
            f"Request started",
            extra={'extra_fields': {
                'method': request.method,
                'path': request.url.path,
                'client_ip': request.client.host,
                'user_agent': request.headers.get('user-agent'),
            }}
        )
        
        # Processa request
        try:
            response: Response = await call_next(request)
            duration = time.time() - start_time
            
            # Log de saída com métricas
            logger.info(
                f"Request completed",
                extra={'extra_fields': {
                    'status_code': response.status_code,
                    'duration_ms': round(duration * 1000, 2),
                }}
            )
            
            # Adiciona headers úteis
            response.headers['X-Request-ID'] = request_id
            response.headers['X-Process-Time'] = str(duration)
            
            return response
            
        except Exception as e:
            duration = time.time() - start_time
            
            # Log de erro com stack trace
            logger.exception(
                f"Request failed",
                extra={'extra_fields': {
                    'duration_ms': round(duration * 1000, 2),
                    'error_type': type(e).__name__,
                }}
            )
            
            # Envia para Sentry se configurado
            if not isDebugMode():
                sentry_sdk.capture_exception(e)
            
            raise
    
    @staticmethod
    def _generate_request_id() -> str:
        import uuid
        return str(uuid.uuid4())


# ==================== Exception Handler Centralizado ====================
class CentralizedExceptionHandler:
    """Handler global para capturar e processar todas as exceções"""
    
    @staticmethod
    def handle_exception(request: Request, exc: Exception):
        logger = get_logger('exception.handler')
        
        # Enriquece contexto
        context = {
            'request_id': request_id_ctx.get(),
            'user_id': user_id_ctx.get(),
            'endpoint': endpoint_ctx.get(),
            'exception_type': type(exc).__name__,
            'exception_message': str(exc),
            'client_ip': request.client.host,
        }
        
        # Log estruturado
        logger.exception(
            f"Unhandled exception: {type(exc).__name__}",
            extra={'extra_fields': context}
        )
        
        # Envia para Sentry (já com contexto automático)
        if not isDebugMode():
            sentry_sdk.capture_exception(exc)
        
        # Retorna resposta genérica (não expõe detalhes internos)
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=500,
            content={
                'detail': 'Internal server error',
                'request_id': request_id_ctx.get(),
                'timestamp': datetime.now(timezone.utc).isoformat()
            }
        )


# ==================== Decorators para Auditoria ====================
def audit_operation(operation_type: str, sensitive: bool = False):
    """
    Decorator para auditar operações críticas
    
    Usage:
        @audit_operation("password_reset", sensitive=True)
        async def reset_password(...):
            ...
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            logger = get_logger('audit')
            
            start = time.time()
            audit_data = {
                'operation': operation_type,
                'sensitive': sensitive,
                'user_id': user_id_ctx.get(),
                'request_id': request_id_ctx.get(),
            }
            
            try:
                result = await func(*args, **kwargs)
                duration = time.time() - start
                
                audit_data.update({
                    'status': 'success',
                    'duration_ms': round(duration * 1000, 2)
                })
                
                logger.info(
                    f"Audit: {operation_type} completed",
                    extra={'extra_fields': audit_data}
                )
                
                return result
                
            except Exception as e:
                duration = time.time() - start
                
                audit_data.update({
                    'status': 'failed',
                    'error': str(e),
                    'duration_ms': round(duration * 1000, 2)
                })
                
                logger.error(
                    f"Audit: {operation_type} failed",
                    extra={'extra_fields': audit_data},
                    exc_info=True
                )
                
                raise
        
        return wrapper
    return decorator


# ==================== Performance Tracking ====================
def track_performance(threshold_ms: float = 1000):
    """
    Decorator para alertar sobre operações lentas
    
    Usage:
        @track_performance(threshold_ms=500)
        async def slow_operation(...):
            ...
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start = time.time()
            result = await func(*args, **kwargs)
            duration = (time.time() - start) * 1000
            
            if duration > threshold_ms:
                logger = get_logger('performance')
                logger.warning(
                    f"Slow operation detected: {func.__name__}",
                    extra={'extra_fields': {
                        'function': func.__name__,
                        'duration_ms': round(duration, 2),
                        'threshold_ms': threshold_ms,
                    }}
                )
            
            return result
        return wrapper
    return decorator


# ==================== Rate Limit Logging ====================
def log_rate_limit_hit(prefix: str, email: str, ip: str):
    """Loga tentativas bloqueadas por rate limiting"""
    logger = get_logger('security.rate_limit')
    logger.warning(
        f"Rate limit exceeded",
        extra={'extra_fields': {
            'prefix': prefix,
            'email': email,
            'ip': ip,
            'action': 'blocked'
        }}
    )
    
    # Alerta no Sentry se muitas tentativas
    if not isDebugMode():
        sentry_sdk.capture_message(
            f"Rate limit hit: {prefix} - {email}",
            level="warning"
        )


# ==================== Database Query Logging ====================
class QueryLogger:
    """Logger para operações de banco de dados"""
    
    @staticmethod
    def log_query(operation: str, table: str, duration_ms: float):
        logger = get_logger('database.query')
        logger.info(
            f"Database operation: {operation}",
            extra={'extra_fields': {
                'operation': operation,
                'table': table,
                'duration_ms': round(duration_ms, 2)
            }}
        )


# ==================== Health Check com Status de Dependências ====================
class HealthCheck:
    """Sistema de health check com logging"""
    
    @staticmethod
    async def check_dependencies() -> Dict[str, Any]:
        """Verifica status de todas as dependências"""
        logger = get_logger('health')
        
        status = {
            'status': 'healthy',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'services': {}
        }
        
        # Check Redis
        try:
            from app.api.dependencies import get_redis
            async for redis in get_redis():
                await redis.ping()
                status['services']['redis'] = 'up'
        except Exception as e:
            status['services']['redis'] = 'down'
            status['status'] = 'degraded'
            logger.error(f"Redis health check failed: {e}")
        
        # Check Database
        try:
            from app.api.dependencies import get_db
            async for db in get_db():
                await db.execute("SELECT 1")
                status['services']['database'] = 'up'
        except Exception as e:
            status['services']['database'] = 'down'
            status['status'] = 'unhealthy'
            logger.error(f"Database health check failed: {e}")
        
        return status
</parameter>
</invoke>

### **2. Integração com Endpoints Existentes**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">python</parameter>
<parameter name="title">app/api/endpoints/auth.py - Integrado com Logging</parameter>
<parameter name="id">auth_with_logging</parameter>
<parameter name="content">"""
Authentication Endpoints com Logging Centralizado
"""
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Header, Request, status
from jose import JWTError, jwt
import pyotp
from redis import Redis
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.logger import (
    get_logger,
    audit_operation,
    track_performance,
    log_rate_limit_hit,
    user_id_ctx
)
from app.helpers.getters import isDebugMode
from app.helpers.qrcode_generator import generate_qr_code_base64
from app.schemas.user import UserCreate
from app.schemas.auth import (
    Token, Login, ForgotPasswordStartIn, ForgotPasswordVerifyIn,
    ForgotPasswordVerifyOut, ForgotPasswordConfirmIn, TwoFASetupOut
)

from app.models.team import Team as TeamModel
from app.api.dependencies import get_current_user, get_db, get_redis
from app.models.user import User
from app.models.password_reset import PasswordReset

from app.core.security import (
    generate_otp, hash_otp, verify_otp, create_reset_session_token,
    verify_password, verify_totp, generate_totp_secret, create_access_token,
    get_password_hash, SECRET_KEY, ALGORITHM
)
from app.helpers.rate_limit import allow
from app.mycelery.worker import send_password_otp_local

router = APIRouter()
logger = get_logger(__name__)


@router.post("/login", response_model=Token)
@track_performance(threshold_ms=500)
@audit_operation("user_login", sensitive=False)
async def login(login_data: Login, request: Request, db: AsyncSession = Depends(get_db)):
    """Login com auditoria completa"""
    client_ip = request.headers.get("x-forwarded-for", request.client.host)
    
    logger.info(
        "Login attempt",
        extra={'extra_fields': {
            'email': login_data.email,
            'ip': client_ip
        }}
    )
    
    result = await db.execute(select(User).filter(User.email == login_data.email))
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(login_data.password, user.password):
        logger.warning(
            "Login failed: Invalid credentials",
            extra={'extra_fields': {
                'email': login_data.email,
                'ip': client_ip,
                'reason': 'invalid_credentials'
            }}
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciais inválidas"
        )
    
    # Define contexto do usuário para logs subsequentes
    user_id_ctx.set(user.id)
    
    access_token = create_access_token(
        data={"sub": str(user.id)},
        token_version=user.token_version
    )
    
    logger.info(
        "Login successful",
        extra={'extra_fields': {
            'user_id': user.id,
            'email': user.email,
            'ip': client_ip
        }}
    )
    
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/logout")
@audit_operation("user_logout", sensitive=False)
async def logout(
    authorization: str = Header(...),
    current_user: User = Depends(get_current_user),
    redis: Redis = Depends(get_redis)
):
    """Logout com invalidação de token"""
    if isDebugMode():
        logger.info(f"Logout (dev mode): user_id={current_user.id}")
        return {"message": "Logout successful"}
    
    token = authorization.replace("Bearer ", "")
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        exp = payload["exp"]
        ttl = exp - int(datetime.now(timezone.utc).timestamp())
        
        # Adiciona à blacklist
        await redis.setex(f"blacklist:{token}", ttl, "revoked")
        
        logger.info(
            "Token blacklisted",
            extra={'extra_fields': {
                'user_id': current_user.id,
                'token_ttl': ttl
            }}
        )
        
        return {"message": "Logout successful"}
        
    except Exception as e:
        logger.error(
            "Logout failed",
            extra={'extra_fields': {'user_id': current_user.id}},
            exc_info=True
        )
        raise


@router.post("/forgot-password/start", status_code=status.HTTP_202_ACCEPTED)
@track_performance(threshold_ms=2000)
async def forgot_password_start(
    payload: ForgotPasswordStartIn,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """Inicia recuperação de senha com rate limiting e auditoria"""
    client_ip = request.headers.get("x-forwarded-for", request.client.host)
    
    # Rate limiting com log
    if not allow("fp:start", payload.email, client_ip, max_attempts=5, window_sec=900):
        log_rate_limit_hit("fp:start", payload.email, client_ip)
        raise HTTPException(status_code=429, detail="Too many requests")
    
    logger.info(
        "Password reset requested",
        extra={'extra_fields': {
            'email': payload.email,
            'ip': client_ip
        }}
    )
    
    result = await db.execute(select(User).filter(User.email == payload.email))
    user = result.scalar_one_or_none()
    
    if user:
        otp = generate_otp()
        pr = PasswordReset(
            user_id=user.id,
            email=payload.email,
            otp_hash=hash_otp(otp),
            otp_expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
            require_totp=user.two_factor_enabled
        )
        db.add(pr)
        await db.commit()
        
        # Envia OTP
        send_password_otp_local.delay(payload.email, otp)
        
        logger.info(
            "OTP generated and sent",
            extra={'extra_fields': {
                'user_id': user.id,
                'email': payload.email,
                'require_totp': user.two_factor_enabled
            }}
        )
    else:
        # Anti-enumeration: não revela se email existe
        logger.info(
            "Password reset requested for non-existent email",
            extra={'extra_fields': {'email': payload.email}}
        )
    
    return {"message": "If the email exists, a verification code has been sent."}


@router.post("/forgot-password/verify", response_model=ForgotPasswordVerifyOut)
@track_performance(threshold_ms=1000)
async def forgot_password_verify(
    payload: ForgotPasswordVerifyIn,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """Verifica OTP com auditoria de tentativas"""
    client_ip = request.headers.get("x-forwarded-for", request.client.host)
    
    if not allow("fp:verify", payload.email, client_ip, max_attempts=10, window_sec=900):
        log_rate_limit_hit("fp:verify", payload.email, client_ip)
        raise HTTPException(status_code=429, detail="Too many attempts")
    
    result = await db.execute(
        select(PasswordReset)
        .filter(
            PasswordReset.email == payload.email,
            PasswordReset.consumed_at.is_(None)
        )
        .order_by(PasswordReset.id.desc())
    )
    pr = result.scalar_one_or_none()
    
    if not pr or not pr.otp_hash or not pr.otp_expires_at:
        logger.warning(
            "OTP verification failed: No valid reset request",
            extra={'extra_fields': {'email': payload.email}}
        )
        raise HTTPException(status_code=400, detail="Invalid or expired code")
    
    if pr.otp_expires_at < datetime.now(pr.otp_expires_at.tzinfo):
        logger.warning(
            "OTP verification failed: Expired",
            extra={'extra_fields': {
                'email': payload.email,
                'expired_at': pr.otp_expires_at.isoformat()
            }}
        )
        raise HTTPException(status_code=400, detail="Invalid or expired code")
    
    # Verifica OTP
    if not payload.otp or not verify_otp(payload.otp, pr.otp_hash):
        pr.attempts += 1
        await db.commit()
        
        logger.warning(
            "OTP verification failed: Invalid code",
            extra={'extra_fields': {
                'email': payload.email,
                'attempts': pr.attempts
            }}
        )
        raise HTTPException(status_code=400, detail="Invalid or expired code")
    
    pr.otp_verified = True
    
    # Verifica TOTP se necessário
    user = None
    if pr.user_id:
        result = await db.execute(select(User).filter(User.id == pr.user_id))
        user = result.scalar_one_or_none()
    
    if pr.require_totp:
        if not user or not user.two_factor_secret or not payload.totp:
            pr.attempts += 1
            await db.commit()
            
            logger.warning(
                "TOTP verification failed: Missing or invalid",
                extra={'extra_fields': {'email': payload.email}}
            )
            raise HTTPException(
                status_code=400,
                detail="Invalid or missing authenticator code"
            )
        
        if not verify_totp(user.two_factor_secret, payload.totp):
            pr.attempts += 1
            await db.commit()
            
            logger.warning(
                "TOTP verification failed: Invalid code",
                extra={'extra_fields': {'email': payload.email}}
            )
            raise HTTPException(
                status_code=400,
                detail="Invalid or missing authenticator code"
            )
        
        pr.totp_verified = True
    
    pr.reset_session_issued_at = datetime.now(timezone.utc)
    await db.commit()
    
    rst = create_reset_session_token(
        user_id=user.id,
        token_version=user.token_version
    )
    
    logger.info(
        "Password reset verification successful",
        extra={'extra_fields': {
            'user_id': user.id,
            'email': payload.email,
            'totp_required': pr.require_totp
        }}
    )
    
    return ForgotPasswordVerifyOut(reset_session_token=rst)


@router.post("/forgot-password/confirm", status_code=status.HTTP_204_NO_CONTENT)
@audit_operation("password_reset_confirm", sensitive=True)
async def forgot_password_confirm(
    payload: ForgotPasswordConfirmIn,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """Confirma nova senha com auditoria completa"""
    auth_header = request.headers.get("authorization", "")
    if not auth_header.lower().startswith("bearer "):
        logger.warning("Password reset confirm: Missing token")
        raise HTTPException(status_code=401, detail="Missing reset session")
    
    token = auth_header.split(" ", 1)[1]
    
    try:
        claims = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as e:
        logger.warning(f"Password reset confirm: Invalid token - {e}")
        raise HTTPException(status_code=401, detail="Invalid reset session")
    
    if claims.get("scope") != "pwd_reset":
        logger.warning("Password reset confirm: Invalid scope")
        raise HTTPException(status_code=401, detail="Invalid reset session")
    
    user_id = int(claims["sub"])
    result = await db.execute(select(User).filter(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        logger.warning(f"Password reset confirm: User not found - {user_id}")
        raise HTTPException(status_code=401, detail="Invalid reset session")
    
    # Atualiza senha e token version
    old_token_version = user.token_version
    user.password = get_password_hash(payload.new_password)
    user.token_version = (user.token_version or 1) + 1
    await db.commit()
    
    # Marca reset como consumido
    result = await db.execute(
        select(PasswordReset)
        .filter(
            PasswordReset.user_id == user_id,
            PasswordReset.consumed_at.is_(None)
        )
        .order_by(PasswordReset.id.desc())
    )
    pr = result.scalar_one_or_none()
    
    if pr:
        pr.consumed_at = datetime.now(timezone.utc)
        await db.commit()
    
    logger.info(
        "Password reset completed",
        extra={'extra_fields': {
            'user_id': user_id,
            'email': user.email,
            'old_token_version': old_token_version,
            'new_token_version': user.token_version
        }}
    )
    
    return


@router.post("/2fa/setup", response_model=TwoFASetupOut)
@audit_operation("2fa_setup", sensitive=True)
async def twofa_setup(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Configura 2FA com logging"""
    secret = generate_totp_secret()
    issuer = "Application"
    label = f"{issuer}:{current_user.email}"
    url = pyotp.totp.TOTP(secret).provisioning_uri(
        name=label,
        issuer_name=issuer
    )
    
    try:
        qr_code_base64 = generate_qr_code_base64(url)
    except ValueError as e:
        logger.error(
            "QR Code generation failed",
            extra={'extra_fields': {'user_id': current_user.id}},
            exc_info=True
        )
        raise HTTPException(status_code=500, detail="Erro ao gerar QR Code")
    
    current_user.two_factor_secret = secret
    current_user.two_factor_enabled = False
    await db.commit()
    
    logger.info(
        "2FA setup initiated",
        extra={'extra_fields': {'user_id':current_user.id}}
    )
    
    return TwoFASetupOut(secret=secret, otpauth_url=url, qr_code=qr_code_base64)


@router.post("/2fa/verify", status_code=204)
@audit_operation("2fa_verify", sensitive=True)
async def twofa_verify(
    code: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Verifica e ativa 2FA com auditoria"""
    if not current_user.two_factor_secret:
        logger.warning(
            "2FA verification failed: No secret configured",
            extra={'extra_fields': {'user_id': current_user.id}}
        )
        raise HTTPException(status_code=400, detail="2FA not configured")
    
    if not verify_totp(current_user.two_factor_secret, code):
        logger.warning(
            "2FA verification failed: Invalid code",
            extra={'extra_fields': {'user_id': current_user.id}}
        )
        raise HTTPException(status_code=400, detail="Invalid code")
    
    current_user.two_factor_enabled = True
    await db.commit()
    
    logger.info(
        "2FA enabled successfully",
        extra={'extra_fields': {'user_id': current_user.id}}
    )
    
    return
</parameter>
</invoke>

### **3. Atualização do main.py com Middleware**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">python</parameter>
<parameter name="title">app/main.py - Integrado com Sistema de Logging</parameter>
<parameter name="id">main_with_logging</parameter>
<parameter name="content">from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.endpoints import auth, teams
from app.db.session import engine_internal_sync
from app.db.base import Base
from app.core.logger import (
    init_sentry,
    RequestLoggingMiddleware,
    CentralizedExceptionHandler,
    get_logger,
    HealthCheck
)

# Inicializa Sentry
init_sentry()

# Cria aplicação
app = FastAPI(
    title="API Applicativo",
    description="API com Observabilidade Centralizada",
    version="1.0.0"
)

# Logger principal
logger = get_logger(__name__)

# Cria tabelas
Base.metadata.create_all(bind=engine_internal_sync)

# CORS
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware de Logging Centralizado
app.add_middleware(RequestLoggingMiddleware)


# Exception Handler Global
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handler global que captura TODAS as exceções não tratadas"""
    return CentralizedExceptionHandler.handle_exception(request, exc)


# Routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(teams.router, prefix="/api/teams", tags=["teams"])


# Health Check Endpoint
@app.get("/health")
async def health_check():
    """
    Endpoint de health check com status de dependências
    
    Returns:
        - status: healthy, degraded, unhealthy
        - services: status de cada dependência
        - timestamp: momento da verificação
    """
    return await HealthCheck.check_dependencies()


@app.get("/")
def root():
    logger.info("Root endpoint accessed")
    return {
        "message": "Bem-vindo à API do Applicativo",
        "docs": "/docs",
        "health": "/health",
        "version": "1.0.0"
    }


# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info("Application starting up")
    logger.info(f"Environment: {from app.core.config import settings; settings.MODE}")


# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Application shutting down")
</parameter>
</invoke>

### **4. Atualização do Rate Limiting com Logging**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">python</parameter>
<parameter name="title">app/helpers/rate_limit.py - Com Logging</parameter>
<parameter name="id">rate_limit_logging</parameter>
<parameter name="content">import redis
from app.core.config import settings
from app.helpers.getters import isDebugMode

# Importa logger após definir o módulo
from app.core.logger import get_logger

logger = get_logger(__name__)

d = True if isDebugMode() else False
r = redis.from_url(
    settings.CELERY_BROKER_URL if not d else settings.CELERY_BROKER_URL_EXTERNAL
)

def _key(prefix: str, email: str, ip: str) -> str:
    return f"{prefix}:{email.lower()}:{ip}"


def allow(prefix: str, email: str, ip: str, max_attempts: int, window_sec: int) -> bool:
    """
    Rate limiting com logging de tentativas
    
    Args:
        prefix: Prefixo da operação (ex: "fp:start")
        email: Email do usuário
        ip: IP do cliente
        max_attempts: Número máximo de tentativas
        window_sec: Janela de tempo em segundos
    
    Returns:
        True se permitido, False se bloqueado
    """
    k = _key(prefix, email, ip)
    
    with r.pipeline() as p:
        p.incr(k)
        p.expire(k, window_sec)
        count, _ = p.execute()
    
    current_count = int(count)
    is_allowed = current_count <= max_attempts
    
    # Log de tentativa
    if current_count == 1:
        logger.debug(
            f"Rate limit check: First attempt",
            extra={'extra_fields': {
                'prefix': prefix,
                'email': email,
                'ip': ip,
                'count': current_count,
                'max': max_attempts
            }}
        )
    
    # Log de bloqueio
    if not is_allowed:
        logger.warning(
            f"Rate limit exceeded",
            extra={'extra_fields': {
                'prefix': prefix,
                'email': email,
                'ip': ip,
                'count': current_count,
                'max': max_attempts,
                'window_sec': window_sec
            }}
        )
    
    # Log de aproximação do limite
    elif current_count >= max_attempts * 0.8:
        logger.info(
            f"Rate limit approaching threshold",
            extra={'extra_fields': {
                'prefix': prefix,
                'email': email,
                'ip': ip,
                'count': current_count,
                'max': max_attempts
            }}
        )
    
    return is_allowed


def get_remaining_attempts(prefix: str, email: str, ip: str, max_attempts: int) -> int:
    """Retorna número de tentativas restantes"""
    k = _key(prefix, email, ip)
    count = r.get(k)
    
    if count is None:
        return max_attempts
    
    return max(0, max_attempts - int(count))


def reset_rate_limit(prefix: str, email: str, ip: str):
    """Reseta o rate limit para um usuário (admin only)"""
    k = _key(prefix, email, ip)
    r.delete(k)
    
    logger.info(
        f"Rate limit reset",
        extra={'extra_fields': {
            'prefix': prefix,
            'email': email,
            'ip': ip
        }}
    )
</parameter>
</invoke>

### **5. Celery Tasks com Logging**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">python</parameter>
<parameter name="title">app/mycelery/worker.py - Com Logging Estruturado</parameter>
<parameter name="id">celery_with_logging</parameter>
<parameter name="content">import os
import smtplib
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.mycelery.app import celery_app
from app.core.logger import get_logger

logger = get_logger(__name__)


@celery_app.task(name="create_task", bind=True)
def create_task(self, task_type):
    """Task genérica com logging de progresso"""
    task_id = self.request.id
    
    logger.info(
        f"Task started",
        extra={'extra_fields': {
            'task_id': task_id,
            'task_type': task_type,
            'task_name': 'create_task'
        }}
    )
    
    try:
        duration = int(task_type) * 10
        time.sleep(duration)
        
        logger.info(
            f"Task completed",
            extra={'extra_fields': {
                'task_id': task_id,
                'duration_sec': duration
            }}
        )
        
        return True
        
    except Exception as e:
        logger.exception(
            f"Task failed",
            extra={'extra_fields': {
                'task_id': task_id,
                'task_type': task_type
            }}
        )
        raise


@celery_app.task(name="send_password_otp", bind=True)
def send_password_otp(self, email: str, otp: str):
    """Envia OTP por email usando Gmail SMTP com logging completo"""
    task_id = self.request.id
    
    logger.info(
        f"Email task started",
        extra={'extra_fields': {
            'task_id': task_id,
            'recipient': email,
            'type': 'password_otp'
        }}
    )
    
    try:
        # Configurações SMTP
        smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
        smtp_port = int(os.getenv("SMTP_PORT", "587"))
        smtp_username = os.getenv("SMTP_USERNAME")
        smtp_password = os.getenv("SMTP_PASSWORD")
        from_email = os.getenv("SMTP_FROM_EMAIL", smtp_username)
        from_name = os.getenv("SMTP_FROM_NAME", "Sistema de Sindicância")

        if not smtp_username or not smtp_password:
            logger.error(
                "SMTP credentials not configured",
                extra={'extra_fields': {'task_id': task_id}}
            )
            raise ValueError("SMTP credentials not configured")

        # Criar mensagem
        msg = MIMEMultipart()
        msg['From'] = f"{from_name} <{from_email}>"
        msg['To'] = email
        msg['Subject'] = "Código de Verificação - Sistema de Sindicância Applicativo"

        # Corpo do email
        body = f"""
        <html>
            <body>
                <h2>Código de Verificação</h2>
                <p>Você solicitou a recuperação de senha.</p>
                <p>Seu código de verificação é: <strong>{otp}</strong></p>
                <p>Este código expira em 10 minutos.</p>
                <p>Se você não solicitou esta recuperação, ignore este email.</p>
                <hr>
                <p><small>Sistema de Sindicância Applicativo - Não responda este email</small></p>
            </body>
        </html>
        """

        msg.attach(MIMEText(body, 'html'))

        # Conectar e enviar
        start_time = time.time()
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_username, smtp_password)
        text = msg.as_string()
        server.sendmail(from_email, email, text)
        server.quit()
        
        duration = time.time() - start_time

        logger.info(
            f"Email sent successfully",
            extra={'extra_fields': {
                'task_id': task_id,
                'recipient': email,
                'smtp_server': smtp_server,
                'duration_ms': round(duration * 1000, 2)
            }}
        )

        return {"sent": True, "email": email}

    except smtplib.SMTPException as e:
        logger.error(
            f"SMTP error sending email",
            extra={'extra_fields': {
                'task_id': task_id,
                'recipient': email,
                'error_type': type(e).__name__,
                'error': str(e)
            }},
            exc_info=True
        )
        return {"sent": False, "error": str(e)}
    
    except Exception as e:
        logger.exception(
            f"Unexpected error sending email",
            extra={'extra_fields': {
                'task_id': task_id,
                'recipient': email
            }}
        )
        return {"sent": False, "error": str(e)}


@celery_app.task(name="send_password_otp_local", bind=True)
def send_password_otp_local(self, email: str, otp: str):
    """Simula envio de OTP localmente (para desenvolvimento) com logging"""
    task_id = self.request.id
    
    logger.info(
        f"Email simulation (dev mode)",
        extra={'extra_fields': {
            'task_id': task_id,
            'recipient': email,
            'otp': otp,
            'type': 'password_otp_local'
        }}
    )
    
    print(f"=== EMAIL SIMULADO (Task ID: {task_id}) ===")
    print(f"Para: {email}")
    print(f"Assunto: Código de Verificação - Sistema de Sindicância Applicativo")
    print(f"Código: {otp}")
    print(f"====================")
    
    return {"sent": True, "task_id": task_id}


# Celery Signal Handlers para Logging Avançado
from celery.signals import (
    task_prerun,
    task_postrun,
    task_failure,
    task_retry,
    task_revoked
)


@task_prerun.connect
def task_prerun_handler(sender=None, task_id=None, task=None, args=None, kwargs=None, **extra):
    """Log quando task inicia"""
    logger.debug(
        f"Task starting",
        extra={'extra_fields': {
            'task_id': task_id,
            'task_name': task.name,
            'args': str(args)[:200],  # Limita tamanho
            'kwargs': str(kwargs)[:200]
        }}
    )


@task_postrun.connect
def task_postrun_handler(sender=None, task_id=None, task=None, retval=None, **extra):
    """Log quando task completa"""
    logger.debug(
        f"Task completed",
        extra={'extra_fields': {
            'task_id': task_id,
            'task_name': task.name,
            'result': str(retval)[:200]
        }}
    )


@task_failure.connect
def task_failure_handler(sender=None, task_id=None, exception=None, traceback=None, **extra):
    """Log quando task falha"""
    logger.error(
        f"Task failed",
        extra={'extra_fields': {
            'task_id': task_id,
            'task_name': sender.name,
            'exception': str(exception),
            'traceback': str(traceback)[:500]
        }}
    )


@task_retry.connect
def task_retry_handler(sender=None, task_id=None, reason=None, **extra):
    """Log quando task é reexecutada"""
    logger.warning(
        f"Task retrying",
        extra={'extra_fields': {
            'task_id': task_id,
            'task_name': sender.name,
            'reason': str(reason)
        }}
    )


@task_revoked.connect
def task_revoked_handler(sender=None, request=None, terminated=None, **extra):
    """Log quando task é revogada"""
    logger.warning(
        f"Task revoked",
        extra={'extra_fields': {
            'task_id': request.id,
            'task_name': sender.name,
            'terminated': terminated
        }}
    )
</parameter>
</invoke>

---

## 📋 Configuração do requirements.txt

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">text</parameter>
<parameter name="title">requirements.txt - Atualizado com Sentry</parameter>
<parameter name="id">requirements_updated</parameter>
<parameter name="content">fastapi[all]
pydantic[email]
sqlalchemy
uvicorn
redis
bcrypt
python-dotenv
alembic
aiohttp
python-jose
starlette
aiomysql
pymysql
celery[redis]
flower
cryptography
pyotp
qrcode[pil]

# Observabilidade e Logging
sentry-sdk[fastapi,sqlalchemy,celery]>=1.40.0
python-json-logger>=2.0.7  # Para logging estruturado alternativo
</parameter>
</invoke>

---

## 🔧 Configuração do .env

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">bash</parameter>
<parameter name="title">.env.example - Com Sentry</parameter>
<parameter name="id">env_with_sentry</parameter>
<parameter name="content">MODE=development
APP_NAME=app_backend_backend

KEY=abc

# Database URLs
MYSQL_INTERNAL_URL_SYNC=mysql+pymysql://root:password@mysql_app_backend:3306/dbname
MYSQL_INTERNAL_URL=mysql+aiomysql://root:password@mysql_app_backend:3306/dbname

MYSQL_EXTERNAL_URL_SYNC=mysql+pymysql://root:password@localhost:3385/dbname
MYSQL_EXTERNAL_URL=mysql+aiomysql://root:password@localhost:3385/dbname

# Celery/Redis
CELERY_BROKER_URL_EXTERNAL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://redis_app_backend:6379/0
CELERY_RESULT_BACKEND=redis://redis_app_backend:6379/0

# Sentry (Observabilidade)
# Obtenha seu DSN em: https://sentry.io/settings/projects/
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
# Deixe vazio em desenvolvimento para desabilitar

# SMTP (Email)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=your-email@gmail.com
SMTP_FROM_NAME=Sistema de Sindicância
</parameter>
</invoke>

---

## 📊 Dashboard: Queries Úteis para Análise de Logs

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">python</parameter>
<parameter name="title">scripts/log_analyzer.py - Analisador de Logs</parameter>
<parameter name="id">log_analyzer</parameter>
<parameter name="content">"""
Script para análise de logs em produção

Usage:
    python scripts/log_analyzer.py --operation login --last 24h
    python scripts/log_analyzer.py --user-id 123 --last 7d
    python scripts/log_analyzer.py --errors-only --last 1h
"""
import json
import sys
from datetime import datetime, timedelta
from collections import Counter
from typing import List, Dict

def parse_log_line(line: str) -> Dict:
    """Parse de linha de log JSON"""
    try:
        return json.loads(line)
    except:
        return None


def filter_logs(logs: List[Dict], **filters) -> List[Dict]:
    """Filtra logs baseado em critérios"""
    filtered = logs
    
    if 'level' in filters:
        filtered = [l for l in filtered if l.get('level') == filters['level']]
    
    if 'operation' in filters:
        filtered = [l for l in filtered if filters['operation'] in l.get('message', '')]
    
    if 'user_id' in filters:
        filtered = [l for l in filtered if l.get('user_id') == filters['user_id']]
    
    if 'last_hours' in filters:
        cutoff = datetime.now() - timedelta(hours=filters['last_hours'])
        filtered = [l for l in filtered if datetime.fromisoformat(l['timestamp']) > cutoff]
    
    return filtered


def analyze_performance(logs: List[Dict]):
    """Analisa métricas de performance"""
    durations = [
        l.get('extra_fields', {}).get('duration_ms', 0)
        for l in logs
        if 'duration_ms' in l.get('extra_fields', {})
    ]
    
    if not durations:
        print("Nenhuma métrica de performance encontrada")
        return
    
    print("\n=== Análise de Performance ===")
    print(f"Total de operações: {len(durations)}")
    print(f"Média: {sum(durations)/len(durations):.2f}ms")
    print(f"Mínimo: {min(durations):.2f}ms")
    print(f"Máximo: {max(durations):.2f}ms")
    print(f"P95: {sorted(durations)[int(len(durations)*0.95)]:.2f}ms")
    print(f"P99: {sorted(durations)[int(len(durations)*0.99)]:.2f}ms")


def analyze_errors(logs: List[Dict]):
    """Analisa erros mais comuns"""
    error_logs = [l for l in logs if l.get('level') in ['ERROR', 'CRITICAL']]
    
    if not error_logs:
        print("\nNenhum erro encontrado!")
        return
    
    print(f"\n=== Análise de Erros ({len(error_logs)} total) ===")
    
    # Erros por tipo
    error_types = Counter([
        l.get('exception', {}).get('type', 'Unknown')
        for l in error_logs
    ])
    
    print("\nTop 5 Tipos de Erro:")
    for error_type, count in error_types.most_common(5):
        print(f"  {error_type}: {count}")
    
    # Endpoints com mais erros
    endpoints = Counter([
        l.get('endpoint', 'Unknown')
        for l in error_logs
    ])
    
    print("\nTop 5 Endpoints com Erros:")
    for endpoint, count in endpoints.most_common(5):
        print(f"  {endpoint}: {count}")


def analyze_security(logs: List[Dict]):
    """Analisa eventos de segurança"""
    security_logs = [
        l for l in logs
        if any(keyword in l.get('message', '').lower()
               for keyword in ['failed', 'invalid', 'unauthorized', 'rate limit'])
    ]
    
    if not security_logs:
        print("\nNenhum evento de segurança encontrado")
        return
    
    print(f"\n=== Análise de Segurança ({len(security_logs)} eventos) ===")
    
    # Falhas de login
    login_failures = [l for l in security_logs if 'login failed' in l.get('message', '').lower()]
    print(f"\nFalhas de Login: {len(login_failures)}")
    
    # Rate limit hits
    rate_limit_hits = [l for l in security_logs if 'rate limit' in l.get('message', '').lower()]
    print(f"Rate Limit Atingido: {len(rate_limit_hits)}")
    
    # IPs suspeitos (múltiplas falhas)
    suspicious_ips = Counter([
        l.get('extra_fields', {}).get('ip', 'Unknown')
        for l in login_failures
    ])
    
    if suspicious_ips:
        print("\nTop 5 IPs com Falhas:")
        for ip, count in suspicious_ips.most_common(5):
            if count > 3:
                print(f"  {ip}: {count} falhas")


def main():
    """Script principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Analisa logs da aplicação')
    parser.add_argument('--file', default='logs/app.log', help='Arquivo de log')
    parser.add_argument('--operation', help='Filtrar por operação')
    parser.add_argument('--user-id', type=int, help='Filtrar por user_id')
    parser.add_argument('--last', help='Últimas N horas (ex: 24h, 7d)')
    parser.add_argument('--errors-only', action='store_true', help='Apenas erros')
    parser.add_argument('--security', action='store_true', help='Análise de segurança')
    parser.add_argument('--performance', action='store_true', help='Análise de performance')
    
    args = parser.parse_args()
    
    # Lê logs
    try:
        with open(args.file, 'r') as f:
            logs = [parse_log_line(line) for line in f if line.strip()]
            logs = [l for l in logs if l is not None]
    except FileNotFoundError:
        print(f"Arquivo não encontrado: {args.file}")
        sys.exit(1)
    
    print(f"Total de logs carregados: {len(logs)}")
    
    # Aplica filtros
    filters = {}
    
    if args.operation:
        filters['operation'] = args.operation
    
    if args.user_id:
        filters['user_id'] = args.user_id
    
    if args.last:
        if args.last.endswith('h'):
            filters['last_hours'] = int(args.last[:-1])
        elif args.last.endswith('d'):
            filters['last_hours'] = int(args.last[:-1]) * 24
    
    if args.errors_only:
        filters['level'] = 'ERROR'
    
    filtered_logs = filter_logs(logs, **filters)
    print(f"Logs após filtros: {len(filtered_logs)}")
    
    # Análises
    if args.performance:
        analyze_performance(filtered_logs)
    
    if args.security:
        analyze_security(filtered_logs)
    
    if args.errors_only or not (args.performance or args.security):
        analyze_errors(filtered_logs)


if __name__ == '__main__':
    main()
</parameter>
</invoke>

---

## 🎯 Próximos Passos e Recomendações

### **1. Configuração Inicial**

```bash
# 1. Adicionar sentry-sdk ao requirements.txt
pip install sentry-sdk[fastapi,sqlalchemy,celery]

# 2. Criar conta no Sentry (gratuito até 5k events/mês)
# https://sentry.io/signup/

# 3. Obter DSN do projeto e adicionar ao .env
SENTRY_DSN=https://your-key@sentry.io/project-id

# 4. Testar logging
python -c "from app.core.logger import get_logger; logger = get_logger('test'); logger.info('Test log')"
```

### **2. Estrutura de Diretórios para Logs**

```bash
mkdir -p logs
touch logs/.gitkeep
echo "logs/*.log" >> .gitignore
```

### **3. Monitoramento Recomendado**

#### **Dashboard no Sentry**
- **Alertas**: Configure para >100 errors/hora
- **Performance**: P95 > 2s em endpoints críticos
- **Rate Limiting**: >50 blocks/hora indica ataque

#### **Queries Úteis**
```python
# Top 10 endpoints mais lentos
SELECT endpoint, AVG(duration_ms) FROM logs 
WHERE level='INFO' AND duration_ms IS NOT NULL
GROUP BY endpoint ORDER BY AVG(duration_ms) DESC LIMIT 10;

# Usuários com mais falhas de login
SELECT email, COUNT(*) FROM logs
WHERE message LIKE '%login failed%'
GROUP BY email HAVING COUNT(*) > 5;

# Rate limit por IP
SELECT ip, COUNT(*) FROM logs
WHERE message LIKE '%rate limit%'
GROUP BY ip ORDER BY COUNT(*) DESC;
```

---

## 📈 Benefícios Obtidos

### **✅ Implementado**

1. **Rastreamento End-to-End**: Cada request tem um `request_id` único
2. **Logs Estruturados**: JSON parseável por ferramentas (Elasticsearch, Datadog)
3. **Context Enrichment**: Automático (user_id, ip, endpoint)
4. **Performance Tracking**: Métricas de duração em todas operações
5. **Auditoria**: Operações sensíveis registradas (login, password reset, 2FA)
6. **Rate Limiting Observável**: Logs de bloqueios e tentativas
7. **Exception Tracking**: Sentry captura automaticamente
8. **Celery Monitoring**: Tasks rastreadas com sucesso/falha
9. **Health Checks**: Status de dependências em tempo real

### **🎯 Próximas Melhorias**

1. **Frontend Correlation**: Enviar `x-request-id` do Flutter
2. **APM (Application Performance Monitoring)**: Integrar Sentry Performance
3. **Log Aggregation**: Elasticsearch + Kibana ou Datadog
4. **Alerting**: PagerDuty/Opsgenie para críticos
5. **Metrics**: Prometheus + Grafana para métricas customizadas

---

## 🚀 Como Usar

### **No Backend**

```python
from app.core.logger import get_logger, audit_operation, track_performance

logger = get_logger(__name__)

@audit_operation("sensitive_op", sensitive=True)
@track_performance(threshold_ms=500)
async def my_endpoint():
    logger.info("Operação iniciada", extra={'extra_fields': {'custom': 'data'}})
    # ... código
    logger.info("Operação completa")
```

### **Visualizando Logs**

```bash
# Desenvolvimento (legível)
tail -f logs/app.log

# Produção (JSON)
tail -f logs/app.log | jq '.'

# Filtrar erros
tail -f logs/app.log | jq 'select(.level=="ERROR")'

# Monitorar performance
tail -f logs/app.log | jq 'select(.extra_fields.duration_ms > 1000)'
```

---

Esta implementação fornece um sistema de observabilidade **enterprise-grade** pronto para
```python
# escalabilidade e integração com provedores externos como Sentry, Datadog, etc.
```

---

## 🔄 Integração Frontend (Flutter) com Sistema de Logging

Agora vamos conectar o Flutter ao sistema centralizado de logging para rastreamento completo end-to-end.

### **1. Interceptor HTTP com Request ID**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">dart</parameter>
<parameter name="title">lib/services/api_interceptor.dart - Request ID Tracking</parameter>
<parameter name="id">api_interceptor</parameter>
<parameter name="content">import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Interceptor customizado para adicionar headers de rastreamento
class ApiInterceptor extends http.BaseClient {
  final http.Client _inner;
  static const _uuid = Uuid();

  ApiInterceptor(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Gera request_id único para rastreamento end-to-end
    final requestId = _uuid.v4();
    request.headers['x-request-id'] = requestId;
    
    // Adiciona timestamp
    request.headers['x-client-timestamp'] = DateTime.now().toIso8601String();
    
    // User agent customizado
    request.headers['user-agent'] = 'Flutter-App/1.0.0';
    
    // Log de saída (opcional em dev)
    _logRequest(request, requestId);
    
    final startTime = DateTime.now();
    
    try {
      final response = await _inner.send(request);
      
      final duration = DateTime.now().difference(startTime);
      _logResponse(response, requestId, duration);
      
      return response;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _logError(request, requestId, duration, e);
      rethrow;
    }
  }

  void _logRequest(http.BaseRequest request, String requestId) {
    print('🚀 [REQUEST] ${request.method} ${request.url}');
    print('   Request-ID: $requestId');
  }

  void _logResponse(
    http.StreamedResponse response,
    String requestId,
    Duration duration,
  ) {
    final emoji = response.statusCode < 400 ? '✅' : '❌';
    print('$emoji [RESPONSE] ${response.statusCode} - ${duration.inMilliseconds}ms');
    print('   Request-ID: $requestId');
    
    // Extrai process time do backend
    final processTime = response.headers['x-process-time'];
    if (processTime != null) {
      print('   Backend Time: ${processTime}ms');
    }
  }

  void _logError(
    http.BaseRequest request,
    String requestId,
    Duration duration,
    Object error,
  ) {
    print('💥 [ERROR] ${request.method} ${request.url}');
    print('   Request-ID: $requestId');
    print('   Duration: ${duration.inMilliseconds}ms');
    print('   Error: $error');
  }
}
</parameter>
</invoke>

### **2. Atualização do ApiService com Interceptor**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">dart</parameter>
<parameter name="title">lib/services/api_service_web.dart - Com Logging</parameter>
<parameter name="id">api_service_web_logging</parameter>
<parameter name="content">import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'api_interceptor.dart';

class ApiService {
  static const baseUrl = kDebugMode
      ? 'http://localhost:8000/api'
      : 'https://apisindicancia.growthsolutions.com.br/api';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Cliente HTTP com interceptor
  static final _client = ApiInterceptor(http.Client());

  static void clearToken() {
    _headers.remove('Authorization');
  }

  static Future<ApiResponse> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await _client.get(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      rethrow;
    }
  }

  static Future<ApiResponse> post(String endpoint, dynamic data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final body = json.encode(data);

    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: body,
      );

      // Se a resposta não for 2xx, lança erro com contexto
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final requestId = response.headers['x-request-id'] ?? 'unknown';
        
        debugPrint('❌ POST Error: ${response.statusCode} - ${response.body}');
        debugPrint('   Request-ID: $requestId');
        
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to POST data',
          requestId: requestId,
          body: response.body,
        );
      }

      return _processResponse(response);
    } catch (e) {
      debugPrint('❌ POST Exception: $e');
      rethrow;
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    dynamic parsedData;
    try {
      parsedData = json.decode(response.body);
    } catch (_) {
      parsedData = response.body;
    }

    return ApiResponse(
      statusCode: response.statusCode,
      data: parsedData,
      headers: response.headers,
    );
  }

  static void setToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  static String? get token {
    return _headers['Authorization']?.replaceFirst('Bearer ', '');
  }
}

/// Exception customizada com contexto de logging
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String requestId;
  final String? body;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.requestId,
    this.body,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message [Request-ID: $requestId]';
  }
}
</parameter>
</invoke>

### **3. Logger Centralizado Flutter**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">dart</parameter>
<parameter name="title">lib/services/app_logger.dart - Sistema de Logging Flutter</parameter>
<parameter name="id">flutter_logger</parameter>
<parameter name="content">import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Sistema centralizado de logging para Flutter
/// 
/// Features:
/// - Logs estruturados
/// - Níveis de severidade
/// - Context enrichment
/// - Performance tracking
/// - Integration com crash reporting (Firebase, Sentry)
class AppLogger {
  final String name;
  
  AppLogger(this.name);

  /// Factory para criar loggers
  factory AppLogger.create(String name) => AppLogger(name);

  // Níveis de log
  void debug(String message, {Map<String, dynamic>? extra}) {
    _log('DEBUG', message, extra: extra);
  }

  void info(String message, {Map<String, dynamic>? extra}) {
    _log('INFO', message, extra: extra);
  }

  void warning(String message, {Map<String, dynamic>? extra}) {
    _log('WARNING', message, extra: extra);
  }

  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace, extra: extra);
  }

  void critical(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    _log('CRITICAL', message, error: error, stackTrace: stackTrace, extra: extra);
  }

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'logger': name,
      'message': message,
      'platform': 'flutter',
      if (extra != null) 'extra': extra,
    };

    if (error != null) {
      logData['error'] = {
        'type': error.runtimeType.toString(),
        'message': error.toString(),
      };
    }

    if (stackTrace != null) {
      logData['stackTrace'] = stackTrace.toString().split('\n').take(10).toList();
    }

    // Em desenvolvimento: log legível
    if (kDebugMode) {
      final emoji = _getEmoji(level);
      debugPrint('$emoji [$level] $name: $message');
      if (extra != null) {
        debugPrint('   Extra: $extra');
      }
      if (error != null) {
        debugPrint('   Error: $error');
      }
    } 
    // Em produção: JSON estruturado
    else {
      developer.log(
        json.encode(logData),
        name: name,
        level: _getLogLevel(level),
      );
    }

    // TODO: Enviar para backend/crash reporting em produção
    // if (kReleaseMode && level == 'ERROR' || level == 'CRITICAL') {
    //   _sendToBackend(logData);
    // }
  }

  String _getEmoji(String level) {
    switch (level) {
      case 'DEBUG':
        return '🐛';
      case 'INFO':
        return 'ℹ️';
      case 'WARNING':
        return '⚠️';
      case 'ERROR':
        return '❌';
      case 'CRITICAL':
        return '🔥';
      default:
        return '📝';
    }
  }

  int _getLogLevel(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      case 'CRITICAL':
        return 1200;
      default:
        return 800;
    }
  }

  // Future<void> _sendToBackend(Map<String, dynamic> logData) async {
  //   // Implementar envio para backend ou serviço de crash reporting
  //   // Exemplo: Firebase Crashlytics, Sentry, etc.
  // }
}

/// Performance tracking helper
class PerformanceTracker {
  final String operation;
  final AppLogger _logger;
  final DateTime _startTime;
  final Map<String, dynamic>? _extra;

  PerformanceTracker(this.operation, this._logger, {Map<String, dynamic>? extra})
      : _startTime = DateTime.now(),
        _extra = extra;

  void complete({String? message}) {
    final duration = DateTime.now().difference(_startTime);
    final durationMs = duration.inMilliseconds;

    final emoji = durationMs < 100 ? '⚡' : durationMs < 500 ? '🚀' : '🐌';
    
    _logger.info(
      message ?? 'Operation completed: $operation',
      extra: {
        'operation': operation,
        'duration_ms': durationMs,
        if (_extra != null) ..._extra!,
      },
    );

    if (durationMs > 1000) {
      _logger.warning(
        'Slow operation detected: $operation',
        extra: {
          'operation': operation,
          'duration_ms': durationMs,
          'threshold_ms': 1000,
        },
      );
    }
  }

  void fail(Object error, [StackTrace? stackTrace]) {
    final duration = DateTime.now().difference(_startTime);
    
    _logger.error(
      'Operation failed: $operation',
      error: error,
      stackTrace: stackTrace,
      extra: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        if (_extra != null) ..._extra!,
      },
    );
  }
}

/// Extension para facilitar tracking
extension LoggerExtensions on AppLogger {
  PerformanceTracker trackPerformance(String operation, {Map<String, dynamic>? extra}) {
    return PerformanceTracker(operation, this, extra: extra);
  }
}

/// Logger global para uso rápido
final appLogger = AppLogger.create('app');
</parameter>
</invoke>

### **4. Integração com AuthProvider (Exemplo)**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">dart</parameter>
<parameter name="title">lib/providers/auth_provider.dart - Com Logging</parameter>
<parameter name="id">auth_provider_logging</parameter>
<parameter name="content">import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../services/app_logger.dart';
import 'notifications_provider.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Logger específico para autenticação
final _logger = AppLogger.create('auth');

class AuthState {
  final bool isAuthenticated;
  final String? token;

  AuthState({required this.isAuthenticated, this.token});

  factory AuthState.unauthenticated() => AuthState(isAuthenticated: false);

  AuthState copyWith({bool? isAuthenticated, String? token}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    _logger.info('AuthNotifier initialized');
    return AuthState.unauthenticated();
  }

  Future<void> login(String email, String password) async {
    final tracker = _logger.trackPerformance('user_login', extra: {
      'email': email,
    });

    state = const AsyncLoading();
    
    try {
      _logger.info('Login attempt', extra: {'email': email});
      
      final authRepository = AuthRepository();
      final token = await authRepository.login(
        kDebugMode ? "jvcs.mecatronica@gmail.com" : email,
        kDebugMode ? "jvcs.mecatronica@gmail.com" : password,
      );
      
      state = AsyncData(AuthState(isAuthenticated: true, token: token));
      
      _logger.info('Login successful', extra: {
        'email': email,
        'token_length': token.length,
      });
      
      tracker.complete(message: 'Login completed successfully');
      
    } catch (e, st) {
      _logger.error(
        'Login failed',
        error: e,
        stackTrace: st,
        extra: {'email': email},
      );
      
      tracker.fail(e, st);
      
      ref.read(notificationsProvider.notifier).error(
        'Erro de Login',
        'Não foi possível realizar o login. Verifique suas credenciais.',
      );
      
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    final tracker = _logger.trackPerformance('user_logout');
    
    try {
      _logger.info('Logout initiated');
      
      state = AsyncData(AuthState.unauthenticated());
      
      final authRepository = AuthRepository();
      await authRepository.logout();
      
      _logger.info('Logout completed');
      tracker.complete();
      
    } catch (e, st) {
      _logger.error('Logout failed', error: e, stackTrace: st);
      tracker.fail(e, st);
    }
  }

  Future<void> register(String email, String password, String releaseKey) async {
    final tracker = _logger.trackPerformance('user_registration', extra: {
      'email': email,
    });

    state = const AsyncLoading();
    
    try {
      if (releaseKey != 'jvcs.mecatronica@gmail.com') {
        _logger.warning('Registration failed: Invalid release key', extra: {
          'email': email,
        });
        
        tracker.fail(Exception('Invalid release key'));
        return;
      }
      
      _logger.info('Registration attempt', extra: {'email': email});
      
      final authRepository = AuthRepository();
      final token = await authRepository.register(email, password);
      
      state = AsyncData(AuthState(isAuthenticated: true, token: token));
      
      _logger.info('Registration successful', extra: {'email': email});
      tracker.complete(message: 'Registration completed successfully');
      
    } catch (e, st) {
      _logger.error(
        'Registration failed',
        error: e,
        stackTrace: st,
        extra: {'email': email},
      );
      
      tracker.fail(e, st);
      state = AsyncError(e, st);
    }
  }
}
</parameter>
</invoke>

### **5. Atualização do pubspec.yaml**

<invoke name="artifacts">
<parameter name="type">application/vnd.ant.code</parameter>
<parameter name="language">yaml</parameter>
<parameter name="title">pubspec.yaml - Com UUID</parameter>
<parameter name="id">pubspec_uuid</parameter>
<parameter name="content">name: app_model
description: "A Base for Flutter project."
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: ^3.9.2
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^16.0.0
  pluto_grid: ^8.0.0 # DataGrid
  fl_chart: ^1.1.0 # Charts
  url_launcher: ^6.3.2
  http: ^1.2.1
  shared_preferences: ^2.5.3
  package_info_plus: ^9.0.0
  uuid: ^4.5.1  # Para gerar request IDs

dependency_overrides:
  intl: 0.19.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/locales/pt_BR.json
</parameter>
</invoke>

---

## 📊 Dashboard de Métricas Recomendadas

### **1. Queries para Sentry/Datadog**

```sql
# === PERFORMANCE MONITORING FOR BUSINESS STRATEGY ===
# Endpoints mais lentos (P95)
SELECT 
  endpoint, 
  PERCENTILE(duration_ms, 95) as p95
FROM logs
WHERE level = 'INFO'
GROUP BY endpoint
ORDER BY p95 DESC
LIMIT 10;

# Taxa de erro por endpoint
SELECT 
  endpoint,
  COUNT(CASE WHEN level = 'ERROR' THEN 1 END) * 100.0 / COUNT(*) as error_rate
FROM logs
GROUP BY endpoint
HAVING error_rate > 1
ORDER BY error_rate DESC;

# === SEGURANÇA ===
# IPs com múltiplas falhas de login
SELECT 
  extra_fields->>'ip' as ip,
  COUNT(*) as failed_attempts
FROM logs
WHERE message LIKE '%login failed%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY ip
HAVING COUNT(*) > 5
ORDER BY failed_attempts DESC;

# Rate limit por endpoint
SELECT 
  extra_fields->>'prefix' as operation,
  COUNT(*) as blocks
FROM logs
WHERE message LIKE '%rate limit exceeded%'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY operation
ORDER BY blocks DESC;

# === OPERAÇÕES ===
# Auditoria de operações sensíveis
SELECT 
  timestamp,
  user_id,
  extra_fields->>'operation' as operation,
  extra_fields->>'status' as status
FROM logs
WHERE extra_fields->>'sensitive' = 'true'
ORDER BY timestamp DESC
LIMIT 100;

# === CELERY TASKS ===
# Tasks falhando consistentemente
SELECT 
  extra_fields->>'task_name' as task,
  COUNT(*) as failures
FROM logs
WHERE logger = 'exception.handler'
  AND message LIKE '%Task failed%'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY task
ORDER BY failures DESC;

# Tempo médio de execução de tasks
SELECT 
  extra_fields->>'task_name' as task,
  AVG((extra_fields->>'duration_ms')::float) as avg_duration_ms
FROM logs
WHERE logger LIKE '%celery%'
  AND extra_fields->>'duration_ms' IS NOT NULL
GROUP BY task
ORDER BY avg_duration_ms DESC;
```

### **2. Alertas Recomendados (Sentry)**

```yaml
# sentry-alerts.yaml (exemplo de configuração)

# Alerta: Taxa de erro alta
- name: "High Error Rate"
  condition: "error_count > 100 in 5 minutes"
  severity: critical
  channels:
    - email
    - slack
  actions:
    - create_incident
    - notify_oncall

# Alerta: Performance degradada
- name: "Slow Endpoints"
  condition: "p95_latency > 2000ms for 10 minutes"
  severity: warning
  channels:
    - slack
  endpoints:
    - "/api/auth/login"
    - "/api/auth/forgot-password/*"

# Alerta: Múltiplas falhas de login
- name: "Brute Force Detected"
  condition: "login_failures > 20 from same IP in 5 minutes"
  severity: critical
  channels:
    - security_team
  actions:
    - block_ip
    - notify_security

# Alerta: Celery worker down
- name: "Worker Health Check Failed"
  condition: "no heartbeat in 5 minutes"
  severity: critical
  channels:
    - pagerduty
    - email

# Alerta: Database connection issues
- name: "Database Unhealthy"
  condition: "database health check failed"
  severity: critical
  channels:
    - pagerduty
    - slack
  actions:
    - restart_workers
    - notify_devops
```

---

## 🎯 Checklist de Implementação

### **Backend**

- [ ] Adicionar `sentry-sdk` ao `requirements.txt`
- [ ] Criar conta no Sentry e obter DSN
- [ ] Atualizar `.env` com `SENTRY_DSN`
- [ ] Substituir `app/core/logger.py`
- [ ] Atualizar `app/api/endpoints/auth.py` com logging
- [ ] Atualizar `app/main.py` com middleware
- [ ] Atualizar `app/helpers/rate_limit.py`
- [ ] Atualizar `app/mycelery/worker.py`
- [ ] Testar: `python -c "from app.core.logger import get_logger; logger = get_logger('test'); logger.info('Test')"`
- [ ] Deploy e verificar logs no Sentry

### **Frontend (Flutter)**

- [ ] Adicionar `uuid: ^4.5.1` ao `pubspec.yaml`
- [ ] Criar `lib/services/api_interceptor.dart`
- [ ] Criar `lib/services/app_logger.dart`
- [ ] Atualizar `lib/services/api_service_web.dart`
- [ ] Atualizar `lib/providers/auth_provider.dart` com logging
- [ ] Testar request IDs no DevTools
- [ ] Verificar correlação com backend (request_id matching)

### **Monitoramento**

- [ ] Configurar dashboard no Sentry
- [ ] Configurar alertas críticos
- [ ] Documentar runbook de incidentes
- [ ] Treinar equipe em análise de logs

---

## 📖 Documentação Adicional

### **Estrutura de Log Padronizada**

```json
{
  "timestamp": "2025-10-07T14:30:00.123Z",
  "level": "INFO",
  "logger": "api.auth",
  "message": "Login successful",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 123,
  "endpoint": "POST /api/auth/login",
  "module": "auth",
  "function": "login",
  "line": 45,
  "extra_fields": {
    "email": "user@example.com",
    "duration_ms": 234.56,
    "ip": "192.168.1.1"
  }
}
```

### **Níveis de Severidade**

| Nível | Quando Usar | Exemplos |
|-------|-------------|----------|
| **DEBUG** | Informações detalhadas para debugging | Valores de variáveis, estados internos |
| **INFO** | Eventos normais do sistema | Login bem-sucedido, operação completada |
| **WARNING** | Situações incomuns mas não críticas | Rate limit atingido, operação lenta |
| **ERROR** | Erros que precisam atenção | Falha em operação, exceção capturada |
| **CRITICAL** | Falhas que impedem funcionamento | Database down, serviço indisponível |

### **Runbook de Incidentes**

```markdown
# 🚨 Runbook: High Error Rate

## Sintomas
- Sentry alerta: >100 erros/5min
- Usuários reportando erros 500
- Dashboard mostra spike de erros

## Diagnóstico
1. Verificar Sentry dashboard
2. Identificar endpoint com mais erros
3. Checar logs recentes:
   ```bash
   tail -f logs/app.log | jq 'select(.level=="ERROR")'
   ```
4. Verificar health check: `curl https://api.example.com/health`

## Resolução
1. Se database down: Reiniciar container MySQL
2. Se Redis down: Reiniciar container Redis
3. Se Celery down: Reiniciar workers
4. Se erro de código: Rollback último deploy

## Escalação
- >5min sem resolução: Notificar tech lead
- >15min: Escalar para CTO
- >30min: Comunicar clientes

## Postmortem
- Documentar causa raiz
- Criar task para prevenir recorrência
- Atualizar monitoramento se necessário
```

---

## 🎓 Melhores Práticas

### **✅ FAÇA**

1. **Use request_id em todas as requisições**
2. **Log operações sensíveis (audit trail)**
3. **Inclua contexto relevante (user_id, ip)**
4. **Meça performance de operações críticas**
5. **Configure alertas proativos**
6. **Revise logs regularmente**
7. **Documente padrões de erro comuns**

### **❌ NÃO FAÇA**

1. **Não logue senhas ou dados sensíveis**
2. **Não logue PII sem necessidade**
3. **Não ignore warnings consistentes**
4. **Não deixe logs crescerem indefinidamente**
5. **Não confie apenas em logs para debug**
6. **Não exponha stack traces para usuários**

---

## 🚀 Resultado Final

Com esta implementação, você terá:

✅ **Rastreamento end-to-end** de todas as requisições  
✅ **Logs estruturados** parseáveis por ferramentas modernas  
✅ **Auditoria completa** de operações sensíveis  
✅ **Monitoramento proativo** com alertas automáticos  
✅ **Performance tracking** em tempo real  
✅ **Integração com Sentry** para crash reporting  
✅ **Compatibilidade com Datadog, Elasticsearch, etc.**  
✅ **Sistema escalável** para ambientes enterprise  

**Seu sistema agora tem observabilidade de nível sênior/staff engineer! 🎉**