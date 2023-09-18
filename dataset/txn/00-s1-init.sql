SET SESSION "yugabyte.session_name" = 's1';
select inet_server_addr(), current_setting('yugabyte.session_name');
