/*********** View linked servers. ************/

  SELECT name, data_source, modify_date, provider, product FROM sys.servers WHERE is_linked = 1;