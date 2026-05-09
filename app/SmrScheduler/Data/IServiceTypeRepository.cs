using SmrScheduler.Models;

namespace SmrScheduler.Data;

public interface IServiceTypeRepository
{
    Task<IEnumerable<ServiceType>> GetAllAsync();
}
