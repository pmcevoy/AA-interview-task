using Dapper;
using SmrScheduler.Models;

namespace SmrScheduler.Data;

public class SlotRepository : ISlotRepository
{
    private readonly IDbConnectionFactory _factory;

    public SlotRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<AppointmentSlot>> GetAvailableAsync(int? branchId, int? serviceTypeId)
    {
        const string sql = """
            SELECT
                s.Id, s.BranchId, s.MechanicId, s.ServiceTypeId,
                s.StartTime, s.EndTime, s.IsAvailable,
                m.Name AS MechanicName,
                st.Name AS ServiceTypeName,
                b.Name AS BranchName
            FROM AppointmentSlot s
            INNER JOIN Mechanic m ON m.Id = s.MechanicId
            INNER JOIN ServiceType st ON st.Id = s.ServiceTypeId
            INNER JOIN Branch b ON b.Id = s.BranchId
            WHERE s.IsAvailable = 1
                AND s.StartTime >= GETDATE()
                AND s.StartTime < DATEADD(DAY, 7, GETDATE())
                AND (@BranchId IS NULL OR s.BranchId = @BranchId)
                AND (@ServiceTypeId IS NULL OR s.ServiceTypeId = @ServiceTypeId)
            ORDER BY s.StartTime
            """;

        using var conn = _factory.Create();
        return await conn.QueryAsync<AppointmentSlot>(sql, new { BranchId = branchId, ServiceTypeId = serviceTypeId });
    }
}
