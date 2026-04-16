@echo off
title Emlaktan Backend Launcher
color 0A

echo ===================================================
echo   Emlaktan Backend Services Launcher
echo ===================================================
echo.
echo NOTE: Make sure MongoDB and RabbitMQ are running!
echo If Docker works: docker-compose up -d rabbitmq seq jaeger elasticsearch
echo.

echo Starting Services...
timeout /t 2 >nul

:: 1. Auth Service
echo Starting AuthService (5001)...
start "AuthService" cmd /k "cd backend\AuthService && dotnet run --urls=http://localhost:5001"

:: 2. Listings Service
echo Starting ListingsService (5002)...
start "ListingsService" cmd /k "cd backend\ListingsService && dotnet run --urls=http://localhost:5002"

:: 3. Notification Service
echo Starting NotificationService (5003)...
start "NotificationService" cmd /k "cd backend\NotificationService && dotnet run --urls=http://localhost:5003"

:: 4. Messaging Service
echo Starting MessagingService (5004)...
start "MessagingService" cmd /k "cd backend\MessagingService && dotnet run --urls=http://localhost:5004"

:: 5. Payment Service
echo Starting PaymentService (5005)...
start "PaymentService" cmd /k "cd backend\PaymentService && dotnet run --urls=http://localhost:5005"

:: 6. API Gateway (Last to ensure others are up)
timeout /t 5 >nul
echo Starting API Gateway (5000)...
start "API Gateway" cmd /k "cd backend\ApiGateway && dotnet run --urls=http://0.0.0.0:5000"

echo.
echo ===================================================
echo   All Services Launched!
echo   API Gateway: http://localhost:5000
echo ===================================================
pause
