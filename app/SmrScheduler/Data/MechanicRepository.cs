using Dapper;
using SmrScheduler.Models;

namespace SmrScheduler.Data;

public class MechanicRepository : IMechanicRepository
{
    private readonly IDbConnectionFactory _factory;

    public MechanicRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<Mechanic>> GetAllAsync()
    {
        using var conn = _factory.Create();
        return await conn.QueryAsync<Mechanic>(
            "SELECT Id, Name, BranchId FROM Mechanic ORDER BY Name");
    }

    public async Task<Mechanic?> GetByIdAsync(int id)
    {
        using var conn = _factory.Create();
        return await conn.QuerySingleOrDefaultAsync<Mechanic>(
            "SELECT Id, Name, BranchId FROM Mechanic WHERE Id = @Id",
            new { Id = id });
    }
}
