FROM mcr.microsoft.com/dotnet/sdk:8.0-noble AS build
WORKDIR /src

COPY ["SmrScheduler/SmrScheduler.csproj", "SmrScheduler/"]
RUN dotnet restore "SmrScheduler/SmrScheduler.csproj"

COPY --link . .
RUN dotnet publish "SmrScheduler/SmrScheduler.csproj" --no-restore -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0-noble-chiseled-extra AS final
WORKDIR /app
EXPOSE 8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "SmrScheduler.dll"]
