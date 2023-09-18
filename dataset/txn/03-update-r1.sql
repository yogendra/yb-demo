update books set updated_by=current_setting('yugabyte.session_name') where id=1;
