using Microsoft.Data.SqlClient;

namespace SmrScheduler.Data;

public interface IDbConnectionFactory
{
    SqlConnection Create();
}
