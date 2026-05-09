namespace SmrScheduler.Models;

public class AppointmentSlot
{
    public int Id { get; set; }
    public int BranchId { get; set; }
    public int MechanicId { get; set; }
    public int ServiceTypeId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public bool IsAvailable { get; set; }

    // Populated by join queries
    public string MechanicName { get; set; } = "";
    public string ServiceTypeName { get; set; } = "";
    public string BranchName { get; set; } = "";
}
