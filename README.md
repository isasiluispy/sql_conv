# SqlConv

It's a tool that will let you load light or huge CSV files into Postgres tables.

In a nutshell, the system will do the next steps in order:

- Read CSV files and get their table structure
- Create the tables based on the strcuture
- Insert all csv data into the correspondant table


SqlConv takes advantage of multi core processors doing most of its tasks in parallel, meaning it takes significantlly less time than
doing the same tasks in a single threaded application.
