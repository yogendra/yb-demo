drop table if exists books;

create table books (id int primary key, name varchar(100) not null, updated_by varchar(10));

insert into books (id, name)
values
(1, 'Book 1 Name'),
(2, 'Book 2 Name'),
(3, 'Book 3 Name');

select * from books;
