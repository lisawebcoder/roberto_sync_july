ALTER SYSTEM SET wal_level = logical;
--ALTER SYSTEM SET max_replication_slots = 8;
-- set this value to the number of tables you want to load into elastic
-- for now we only have one table called product

--may26th2023--comment 1--0940am--
--i ttok this max slots line of code from the other pgsync docker project
--i put it here cuz i dont get why its not here in the 1st place
--ES will nver see the tables if this line is not here right?lets see what happens
--it seems to work i just have 1 api endpoint /airbnb but it works


--may29th2023--comment 1--0940am--
--i ttok this max slots line of code from the other pgsync docker project
--i put it here cuz i dont get why its not here in the 1st place
--ES will nver see the tables if this line is not here right?lets see what happens
--i changed to 8 cuz i added i table letes ee


--june1st2023
--i am using exmples/rental
--so i beleive there is 12 tables in the chema.json so i put 13

--12noon
--nothing works to resote in pgadmin and i dont know why
--so i will run airbnb w/ python db scripts


--june2nd2023--11am
--added 2columns and sync and main index api working
--now trying to add 1 table called room exaclty as i did w/ the host table 
--so i am incresing slots to 8 and testing

--12noon
--i get error airbnb replicate slot doesnt exist 
--and so i comment out slots cux thats how the dev of this repo
-- had it and he had 7 tables w/ the airbnb default run 