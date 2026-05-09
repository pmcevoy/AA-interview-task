using Dapper;
using SmrScheduler.Models;

namespace SmrScheduler.Data;

public class ServiceTypeRepository : IServiceTypeRepository
{
    private readonly IDbConnectionFactory _factory;

    public ServiceTypeRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<ServiceType>> GetAllAsync()
    {
        using var conn = _factory.Create();
        return await conn.QueryAsync<ServiceType>(
            "SELECT Id, Name, DurationMinutes FROM ServiceType ORDER BY Name");
    }
}
