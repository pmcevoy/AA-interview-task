using SmrScheduler.Models;

namespace SmrScheduler.Data;

public interface IMechanicRepository
{
    Task<IEnumerable<Mechanic>> GetAllAsync();
    Task<Mechanic?> GetByIdAsync(int id);
}
