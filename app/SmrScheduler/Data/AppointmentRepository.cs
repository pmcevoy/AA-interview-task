using Dapper;
using SmrScheduler.Models;

namespace SmrScheduler.Data;

public class AppointmentRepository : IAppointmentRepository
{
    private readonly IDbConnectionFactory _factory;

    public AppointmentRepository(IDbConnectionFactory factory) => _factory = factory;

    private const string SelectCols = """
        a.Id, a.SlotId, a.ReferenceNumber, a.CustomerName, a.CustomerPhone, a.VehicleReg,
        a.ServiceTypeId, a.Notes, a.Status, a.CreatedAt,
        st.Name AS ServiceTypeName,
        m.Name AS MechanicName,
        s.StartTime, s.EndTime
        """;

    private const string Joins = """
        INNER JOIN AppointmentSlot s ON s.Id = a.SlotId
        INNER JOIN Mechanic m ON m.Id = s.MechanicId
        INNER JOIN ServiceType st ON st.Id = a.ServiceTypeId
        """;

    public async Task<IEnumerable<Appointment>> GetTodayAllAsync()
    {
        var sql = $"""
            SELECT {SelectCols}
            FROM Appointment a
            {Joins}
            WHERE CAST(s.StartTime AS DATE) = CAST(GETDATE() AS DATE)
            ORDER BY m.Name, s.StartTime
            """;

        using var conn = _factory.Create();
        return await conn.QueryAsync<Appointment>(sql);
    }

    public async Task<IEnumerable<Appointment>> GetByMechanicAndDateAsync(int mechanicId, DateTime date)
    {
        var sql = $"""
            SELECT {SelectCols}
            FROM Appointment a
            {Joins}
            WHERE s.MechanicId = @MechanicId
                AND CAST(s.StartTime AS DATE) = @Date
            ORDER BY s.StartTime
            """;

        using var conn = _factory.Create();
        return await conn.QueryAsync<Appointment>(sql, new { MechanicId = mechanicId, Date = date.Date });
    }

    public async Task<Appointment?> GetByIdAsync(int id)
    {
        var sql = $"""
            SELECT {SelectCols}
            FROM Appointment a
            {Joins}
            WHERE a.Id = @Id
            """;

        using var conn = _factory.Create();
        return await conn.QuerySingleOrDefaultAsync<Appointment>(sql, new { Id = id });
    }

    public async Task UpdateStatusAsync(int id, string status)
    {
        using var conn = _factory.Create();
        await conn.ExecuteAsync(
            "UPDATE Appointment SET Status = @Status WHERE Id = @Id",
            new { Id = id, Status = status });
    }
}
