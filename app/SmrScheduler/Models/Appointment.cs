namespace SmrScheduler.Models;

public class Appointment
{
    public int Id { get; set; }
    public int SlotId { get; set; }
    public string ReferenceNumber { get; set; } = "";
    public string CustomerName { get; set; } = "";
    public string CustomerPhone { get; set; } = "";
    public string VehicleReg { get; set; } = "";
    public int ServiceTypeId { get; set; }
    public string? Notes { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }

    // Populated by join queries
    public string ServiceTypeName { get; set; } = "";
    public string MechanicName { get; set; } = "";
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}
