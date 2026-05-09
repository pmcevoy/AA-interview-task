# AA-interview-task

Implementation of the coding task required for AA Interview.  See AA_SMR_Task_Reference.md for reference.

Before running, please ensure to set the following environment variables:

- `AA_TASK_MSSQL_SA_PASSWORD`: this is the password set to the `sa` user when Sql Server container starts
- `AA_TASK_APP_PASSWORD`: this is the password for the app SQL user

With docker running locally, you can run the app by:
```
docker compose pull
docker compose up --build
```

Then visit `http://localhost:8080/`

