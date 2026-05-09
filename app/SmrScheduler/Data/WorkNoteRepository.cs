using Dapper;
using SmrScheduler.Models;

namespace SmrScheduler.Data;

public class WorkNoteRepository : IWorkNoteRepository
{
    private readonly IDbConnectionFactory _factory;

    public WorkNoteRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<WorkNote>> GetByAppointmentAsync(int appointmentId)
    {
        using var conn = _factory.Create();
        return await conn.QueryAsync<WorkNote>(
            "SELECT Id, AppointmentId, NoteText, CreatedAt FROM WorkNote WHERE AppointmentId = @AppointmentId ORDER BY CreatedAt ASC",
            new { AppointmentId = appointmentId });
    }

    public async Task AddAsync(int appointmentId, string noteText)
    {
        using var conn = _factory.Create();
        await conn.ExecuteAsync(
            "INSERT INTO WorkNote (AppointmentId, NoteText, CreatedAt) VALUES (@AppointmentId, @NoteText, GETUTCDATE())",
            new { AppointmentId = appointmentId, NoteText = noteText });
    }
}
