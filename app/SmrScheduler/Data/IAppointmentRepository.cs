using SmrScheduler.Models;

namespace SmrScheduler.Data;

public interface IAppointmentRepository
{
    Task<IEnumerable<Appointment>> GetTodayAllAsync();
    Task<IEnumerable<Appointment>> GetByMechanicAndDateAsync(int mechanicId, DateTime date);
    Task<Appointment?> GetByIdAsync(int id);
    Task UpdateStatusAsync(int id, string status);
}
