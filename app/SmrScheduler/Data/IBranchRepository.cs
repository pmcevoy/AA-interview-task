using SmrScheduler.Models;

namespace SmrScheduler.Data;

public interface IBranchRepository
{
    Task<IEnumerable<Branch>> GetAllAsync();
}
