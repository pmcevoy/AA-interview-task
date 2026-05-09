FROM mcr.microsoft.com/mssql-tools

COPY run-migrations.sh /run-migrations.sh
RUN chmod +x /run-migrations.sh

CMD ["/run-migrations.sh"]
