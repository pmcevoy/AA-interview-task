namespace SmrScheduler.Models;

public class WorkNote
{
    public int Id { get; set; }
    public int AppointmentId { get; set; }
    public string NoteText { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}
