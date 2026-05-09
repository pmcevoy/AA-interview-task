using Microsoft.Data.SqlClient;

namespace SmrScheduler.Data;

public class SqlConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("SmrScheduler")
            ?? throw new InvalidOperationException("Connection string 'SmrScheduler' is not configured.");
    }

    public SqlConnection Create() => new(_connectionString);
}
