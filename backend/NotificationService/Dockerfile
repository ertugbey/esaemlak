FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy shared project first
COPY ["Shared.Events/Shared.Events.csproj", "Shared.Events/"]

# Copy service project
COPY ["NotificationService/NotificationService.csproj", "NotificationService/"]

# Restore dependencies
RUN dotnet restore "NotificationService/NotificationService.csproj"

# Copy all source files
COPY ["Shared.Events/", "Shared.Events/"]
COPY ["NotificationService/", "NotificationService/"]

# Build
WORKDIR /src/NotificationService
RUN dotnet build "NotificationService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "NotificationService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "NotificationService.dll"]
