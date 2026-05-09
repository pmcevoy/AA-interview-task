using SmrScheduler.Models;

namespace SmrScheduler.Data;

public interface ISlotRepository
{
    Task<IEnumerable<AppointmentSlot>> GetAvailableAsync(int? branchId, int? serviceTypeId);
}
