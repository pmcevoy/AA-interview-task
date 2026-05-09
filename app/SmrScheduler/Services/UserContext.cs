namespace SmrScheduler.Services;

public class UserContext
{
    public int? MechanicId { get; set; }
    public string? MechanicName { get; set; }
    public bool IsAdmin => MechanicId == null;
}
