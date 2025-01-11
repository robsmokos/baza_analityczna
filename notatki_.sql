BACKUP DATABASE [BikeStores]
TO DISK = 'C:\DATA\ROB\7SEM\BAZY\BikeStores_New.bak'
WITH FORMAT, INIT, NAME = 'Full Backup of BikeStores';


BACKUP DATABASE [BikeStores]
TO DISK = 'C:\DATA\ROB\7SEM\BAZY\BikeStores_Analytics_New.bak'
WITH FORMAT, INIT, NAME = 'Full Backup of BikeStores_Analytics';