begin transaction ;
select * from books where id=1 for update;
update books set updated_by=current_setting('yugabyte.session_name') where id=1;
commit;

select * from books where id = 1;
