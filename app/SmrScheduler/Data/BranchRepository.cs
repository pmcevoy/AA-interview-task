using Dapper;
using SmrScheduler.Models;

namespace SmrScheduler.Data;

public class BranchRepository : IBranchRepository
{
    private readonly IDbConnectionFactory _factory;

    public BranchRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<Branch>> GetAllAsync()
    {
        using var conn = _factory.Create();
        return await conn.QueryAsync<Branch>(
            "SELECT Id, Name, Address FROM Branch ORDER BY Name");
    }
}
