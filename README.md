# tpch-datagen-as-hive-query
This are set of UDFs and queries that you can use with Hive to use TPCH datagen in parrellel on hadoop cluster. You can deploy to azure using :
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdharmeshkakadia%2Ftpch-datagen-as-hive-query%2Fmaster%2Fazure%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


## How to use with Hive CLI
1. Clone this repo.

    ```shell
    git clone https://github.com/cruizen/tpch-hdinsight.git && cd tpch-hdinsight
    ```
2. Run TPCHDataGen.hql with settings.hql file and set the required config variables.
    ```shell
    hive -i settings.hql -f TPCHDataGen.hql -hiveconf SCALE=10 -hiveconf PARTS=10 -hiveconf LOCATION=/HiveTPCH/ -hiveconf TPCHBIN=resources 
    ```
    Here, `SCALE` is a scale factor for TPCH, 
    `PARTS` is a number of task to use for datagen (parrellelization), 
    `LOCATION` is the directory where the data will be stored on HDFS, 
    `TPCHBIN` is where the resources are found. You can specify specific settings in settings.hql file.

3. Now you can create tables on the generated data.
    ```shell
    hive -i settings.hql -f ddl/createAllExternalTables.hql -hiveconf LOCATION=/HiveTPCH/ -hiveconf DBNAME=tpch
    ```
    For HDI 4.0, allow permissions to other users on the storage by running 
    ```shell
    hdfs dfs -chmod -R 777 /HiveTPCH
    ```
    
    Generate ORC tables and analyze
    ```shell
    hive -i settings.hql -f ddl/createAllORCTables.hql -hiveconf ORCDBNAME=tpch_orc -hiveconf SOURCE=tpch 
    hive -i settings.hql -f ddl/analyze.hql -hiveconf ORCDBNAME=tpch_orc 
    ```

4. Run the queries !
    ```shell
    hive -database tpch_orc -i settings.hql -f queries/tpch_query1.hql 
    ```

## How to use with Beeline CLI
1. Clone this repo.

    ```shell
    git clone https://github.com/cruizen/tpch-hdinsight.git && cd tpch-hdinsight
    ```
2. Upload the resources to DFS.
    ```shell
    hdfs dfs -copyFromLocal resources /tmp
    ```

3. Run TPCHDataGen.hql with settings.hql file and set the required config variables.
    ```shell
   beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f TPCHDataGen.hql -hiveconf SCALE=10 -hiveconf PARTS=10 -hiveconf LOCATION=/HiveTPCH/ -hiveconf TPCHBIN=`grep -A 1 "fs.defaultFS" /etc/hadoop/conf/core-site.xml | grep -o "wasb[^<]*"`/tmp/resources 
    ```
    Here, `SCALE` is a scale factor for TPCH, 
    `PARTS` is a number of task to use for datagen (parrellelization), 
    `LOCATION` is the directory where the data will be stored on HDFS, 
    `TPCHBIN` is where the resources are uploaded on step 2. You can specify specific settings in settings.hql file.
    When ADLS is used as the storage instead of Azure blob storage, replace wasb in the URL for fs.defaultFS with abfs since ADLS uses the abfs:// storage scheme.

4. Now you can create tables on the generated data.
    ```shell
    beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f ddl/createAllExternalTables.hql -hiveconf LOCATION=/HiveTPCH/ -hiveconf DBNAME=tpch
    ```
    For HDI 4.0, allow permissions to other users on the storage by running 
    ```shell
    hdfs dfs -chmod -R 777 /HiveTPCH
    ```
    Generate ORC tables and analyze
    ```shell
    beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f ddl/createAllORCTables.hql -hiveconf ORCDBNAME=tpch_orc -hiveconf SOURCE=tpch 
    beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f ddl/analyze.hql -hiveconf ORCDBNAME=tpch_orc 
    ```

5. Run the queries !
    ```shell
    beeline -u "jdbc:hive2://`hostname -f`:10001/tpch_orc;transportMode=http" -n "" -p "" -i settings.hql -f queries/tpch_query1.hql 
    ```

If you want to run all the queries 10 times and measure the times it takes, you can use the following command
   
    echo "Query,run,start_time,end_time,duration" >> times_orc.csv;
    for f in queries/*.sql; do for i in {1..10} ; do STARTTIME="`date +%s`";  beeline -u "jdbc:hive2://`hostname -f`:10001/tpch_orc;transportMode=http" -i settings.hql -f $f  > $f.run_$i.out 2>&1 ; ENDTIME="`date +%s`"; echo "$f,$i,$STARTTIME,$ENDTIME,$(($ENDTIME-$STARTTIME))" >> times_orc.csv; done; done;


## FAQ

1. Does it work with scale factor 1?

    No. The parrellel data generation assumes that scale > 1. If you are just starting out, I would suggest you start with 10 and then move to standard higher scale factors (100, 1000, 10000,..)

2. Do I have to specify PARTS=SCALE ?

    Yes.

3. How do I avoid my session getting killed due to network errors while long running benchmark?
    
   Use byobu. Type byobu which will start a new session and then run the command. It will be there when you come back even if your network connection is broken. 
