FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy shared project first
COPY ["Shared.Events/Shared.Events.csproj", "Shared.Events/"]

# Copy service project
COPY ["MessagingService/MessagingService.csproj", "MessagingService/"]

# Restore dependencies
RUN dotnet restore "MessagingService/MessagingService.csproj"

# Copy all source files
COPY ["Shared.Events/", "Shared.Events/"]
COPY ["MessagingService/", "MessagingService/"]

# Build
WORKDIR /src/MessagingService
RUN dotnet build "MessagingService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MessagingService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MessagingService.dll"]
