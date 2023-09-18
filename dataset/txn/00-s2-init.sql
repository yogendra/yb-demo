SET SESSION "yugabyte.session_name" = 's2';
select inet_server_addr(), current_setting('yugabyte.session_name');
