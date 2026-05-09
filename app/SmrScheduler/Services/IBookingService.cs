namespace SmrScheduler.Services;

public record BookingResult(bool Success, string? ReferenceNumber = null, string? Error = null);

public interface IBookingService
{
    Task<BookingResult> BookAsync(
        int slotId,
        string customerName,
        string customerPhone,
        string vehicleReg,
        int serviceTypeId,
        string? notes);
}
