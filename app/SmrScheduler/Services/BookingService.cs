using Dapper;
using Microsoft.Data.SqlClient;
using SmrScheduler.Data;

namespace SmrScheduler.Services;

public class BookingService : IBookingService
{
    private readonly IDbConnectionFactory _factory;

    public BookingService(IDbConnectionFactory factory) => _factory = factory;

    public async Task<BookingResult> BookAsync(
        int slotId,
        string customerName,
        string customerPhone,
        string vehicleReg,
        int serviceTypeId,
        string? notes)
    {
        using var conn = _factory.Create();
        await conn.OpenAsync();

        var isAvailable = await conn.ExecuteScalarAsync<bool>(
            "SELECT IsAvailable FROM AppointmentSlot WHERE Id = @Id",
            new { Id = slotId });

        if (!isAvailable)
            return new BookingResult(false, Error: "This slot is no longer available.");

        using var tx = await conn.BeginTransactionAsync();
        try
        {
            var refNumber = GenerateReferenceNumber();

            await conn.ExecuteAsync(
                """
                INSERT INTO Appointment
                    (SlotId, ReferenceNumber, CustomerName, CustomerPhone, VehicleReg, ServiceTypeId, Notes, Status, CreatedAt)
                VALUES
                    (@SlotId, @ReferenceNumber, @CustomerName, @CustomerPhone, @VehicleReg, @ServiceTypeId, @Notes, 'Scheduled', GETUTCDATE())
                """,
                new
                {
                    SlotId = slotId,
                    ReferenceNumber = refNumber,
                    CustomerName = customerName,
                    CustomerPhone = customerPhone,
                    VehicleReg = vehicleReg,
                    ServiceTypeId = serviceTypeId,
                    Notes = notes
                },
                transaction: tx);

            await conn.ExecuteAsync(
                "UPDATE AppointmentSlot SET IsAvailable = 0 WHERE Id = @Id",
                new { Id = slotId },
                transaction: tx);

            await tx.CommitAsync();
            return new BookingResult(true, ReferenceNumber: refNumber);
        }
        catch (SqlException ex) when (ex.Number is 2627 or 2601)
        {
            await tx.RollbackAsync();
            return new BookingResult(false, Error: "This slot was just taken. Please choose another.");
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    private static string GenerateReferenceNumber()
    {
        var seq = Random.Shared.Next(1, 10000);
        return $"SMR-{DateTime.UtcNow:yyyyMMdd}-{seq:D4}";
    }
}
