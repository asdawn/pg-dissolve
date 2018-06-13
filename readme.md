Dissolve for PostGIS

-----
PostGIS is good at dealing with fundamental operations, but lacks high-level functions. Import spatial data into Postgres is a very efficient way, **except when the required function do not exist**. 

Now I need a dissolve function, which exists in QGIS, ArcMap and other desktop GIS. I did not find any implementation from Bing(*yes we can not access google here*) and Github. I have to do it myself.

+ I do not care the efficiency very much, automatically running is good enough. 
+ I do not want to implement a toolbox, just one function this time for the work by hand.
+ If there's such work, please tell me, thanks.
