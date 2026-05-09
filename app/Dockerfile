FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["SmrScheduler/SmrScheduler.csproj", "SmrScheduler/"]
RUN dotnet restore "SmrScheduler/SmrScheduler.csproj"
COPY . .
WORKDIR "/src/SmrScheduler"
RUN dotnet build "SmrScheduler.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SmrScheduler.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SmrScheduler.dll"]
