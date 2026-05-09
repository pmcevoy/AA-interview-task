using SmrScheduler.Models;

namespace SmrScheduler.Data;

public interface IWorkNoteRepository
{
    Task<IEnumerable<WorkNote>> GetByAppointmentAsync(int appointmentId);
    Task AddAsync(int appointmentId, string noteText);
}
